import Foundation

struct MealPlanGenerator {
    private static let maximumAttempts = 3
    private let client: OpenAIResponsesClient

    init(client: OpenAIResponsesClient = OpenAIResponsesClient()) {
        self.client = client
    }

    func generate(configuration: MealPlanConfiguration) async throws -> WeeklyMealPlan {
        print("inizio generazione")
        let catalog = try ProductCatalogLoader.load()
        print("catalogo caricato")
        
        let candidates = CatalogCandidateSelector.select(
            from: catalog,
            configuration: configuration
        )
        print("candidati ottenuti: \(candidates.count)")
        guard !candidates.isEmpty else { throw MealPlanGenerationError.noMatchingProducts }

        let catalogJSON = try String(
            decoding: JSONEncoder().encode(candidates.map(ProductPromptItem.init)),
            as: UTF8.self
        )
        let basePrompt = Self.prompt(configuration: configuration, catalogJSON: catalogJSON)
        var correction: String?

        for attempt in 1...Self.maximumAttempts {
            do {
                let input = correction.map {
                    basePrompt + """


                    CORRECTION REQUIRED AFTER A FAILED ATTEMPT:
                    The previous result failed local validation with this error: \($0)
                    Generate the complete plan again from scratch and explicitly correct this issue.
                    """
                } ?? basePrompt
                return try await generateAttempt(
                    configuration: configuration,
                    catalog: candidates,
                    input: input
                )
            } catch {
                guard attempt < Self.maximumAttempts, Self.isRetryable(error) else {
                    throw error
                }
                correction = error.localizedDescription
                print("[MealPrep] Retrying meal plan generation (attempt \(attempt + 1)/\(Self.maximumAttempts)).")
                try await Task.sleep(for: .milliseconds(400 * attempt))
            }
        }

        throw MealPlanGenerationError.missingOutput
    }

    private func generateAttempt(
        configuration: MealPlanConfiguration,
        catalog: [CatalogProduct],
        input: String
    ) async throws -> WeeklyMealPlan {
        let planData = try await client.structuredResponse(
            instructions: Self.instructions,
            input: input,
            schema: Self.schema
        )
        let decodedPlan: WeeklyMealPlan
        do {
            decodedPlan = try JSONDecoder().decode(WeeklyMealPlan.self, from: planData)
        } catch let error as DecodingError {
            let responsePreview = String(decoding: planData.prefix(800), as: UTF8.self)
            throw MealPlanGenerationError.responseDecodingFailed(
                "Meal plan: \(error.mealPrepDiagnosticDescription) Response prefix: \(responsePreview)"
            )
        }
        let catalogNormalizedPlan = MealPlanCatalogNormalizer.normalize(decodedPlan, catalog: catalog)
        let plan = MealPlanPackageNormalizer.normalize(catalogNormalizedPlan, catalog: catalog)
        try MealPlanValidator.validate(plan, configuration: configuration, catalog: catalog)
        return plan
    }

    private static func isRetryable(_ error: Error) -> Bool {
        if error is CancellationError { return false }
        if let urlError = error as? URLError {
            return [
                .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
                .dnsLookupFailed, .notConnectedToInternet, .resourceUnavailable
            ].contains(urlError.code)
        }
        guard let generationError = error as? MealPlanGenerationError else { return false }
        switch generationError {
        case .invalidPlan, .missingOutput, .responseDecodingFailed, .generationIncomplete,
             .invalidResponse:
            return true
        case .api(let message):
            return ["HTTP 429", "HTTP 500", "HTTP 502", "HTTP 503", "HTTP 504"]
                .contains(where: message.contains)
        case .missingOpenAIAPIKey, .invalidOpenAIAPIKeyConfiguration, .catalogNotFound,
             .catalogDecodingFailed, .noMatchingProducts:
            return false
        }
    }

    private static let instructions = """
    You are MealPrep's meal-planning engine. Build practical recipes using only the supplied
    catalog products. Never invent product IDs, product names, package prices, or package sizes.
    Reuse purchased products across the week to minimize waste. Respect every dietary need and
    nutritional goal. The weekly shopping budget is a hard constraint and takes priority over
    the number of meals, variety, portion size, and minimizing waste. Prices are EUR. Return only
    data matching the provided JSON schema.
    """

    private static func prompt(
        configuration: MealPlanConfiguration,
        catalogJSON: String
    ) -> String {
        let diets = configuration.dietaryNeeds.map(\.title).sorted().joined(separator: ", ")
        let goals = configuration.nutritionalGoals.map(\.title).sorted().joined(separator: ", ")
        return """
        Create a seven-day meal plan from Monday through Sunday with at least one meal per day.
        The number of dishes must scale with the available budget. Start with at least one complete
        eating occasion per day, then add Breakfast, Lunch, and Dinner as the budget permits. Once
        those occasions are covered, spend additional budget by adding distinct dishes within the
        same occasion: for example a first course, second course, and side dish for Lunch or Dinner.
        Prefer adding a useful dish over increasing the servings of an existing dish. Every dish
        must have exactly 1 serving because this plan is for one user. With a generous budget,
        produce Breakfast, Lunch, and Dinner every day, with multiple courses where affordable.
        Do not return a minimal low-cost plan when the budget can afford a substantially more
        complete week.
        
        Weekly shopping budget: EUR \(configuration.weeklyBudget).
        Dietary needs: \(diets.isEmpty ? "None" : diets).
        Nutritional goals: \(goals.isEmpty ? "None" : goals).

        BUDGET RULES — these are hard constraints:
        - Each catalog entry describes one purchasable package. Supply is unlimited, but every
          package purchased counts toward the budget at its full catalog packagePrice.
        - Ingredient amounts are totals for the whole recipe, across all its servings.
        - Express each ingredient in a unit compatible with its catalog netContent: use g or kg
          for products sold by mass and ml or l for products sold by volume. Prefer the exact
          netContent unit. Eggs are the only exception and may be expressed as pieces.
        - For each product, sum its ingredient amounts across every meal in the entire week.
          Convert compatible units to the netContent unit, divide that total by netContent.value,
          and round UP to obtain shoppingList.packages. For eggs only, treat one piece as 60 g
          when the catalog netContent is expressed in grams.
        - Set each shopping-list totalPrice to the exact catalog packagePrice multiplied by
          packages. Set weeklyTotalPrice to the sum of all shopping-list totalPrice values.
        - Recalculate the shopping list from scratch after composing all recipes. If the result
          exceeds the weekly budget, reduce quantities, replace expensive products, or remove the
          least important optional meal, then recalculate again. Never exceed the weekly budget.
        - Aim to spend between 90% and 98% of the budget when practical. If the total is below 90%,
          improve the plan by adding useful meals first, then increasing dietary variety and
          ingredient quality, and recalculate all required packages. Do not stop while the plan is
          far below budget if meaningful meals can still be added.
        - Keep a small 2% margin when practical to absorb whole-package rounding. Do not exceed the
          budget in an attempt to reach the target range.
        - Leftovers are acceptable. Reuse them where practical, but never increase spending merely
          to consume an entire package.

        Set mealType to Breakfast, Lunch, or Dinner. Use course to describe the role of each dish.
        Keep dishes belonging to the same mealType adjacent in the day's meals array and order the
        meal types as Breakfast, Lunch, Dinner. Every recipe ingredient must reference a productId
        in shoppingList. A meal's price is the
        estimated cost of the ingredient quantities actually used, not the price of all packages.

        Keep recipe instructions concise and concrete. Do not add commentary outside the schema.
        Make the weekly menu varied: do not repeat the same dish on different days. Alternate
        recipes, main ingredients, cooking methods, and meal styles throughout the week. Reusing
        purchased products to reduce waste is encouraged, but each meal must remain recognizably
        different from the others.

        Allowed catalog products:
        \(catalogJSON)
        """
    }

    private static let schema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "properties": [
            "currency": ["type": "string", "enum": ["EUR"]],
            "weeklyTotalPrice": ["type": "number", "minimum": 0],
            "shoppingList": [
                "type": "array", "minItems": 1,
                "items": object([
                    "productId": ["type": "string"],
                    "name": ["type": "string"],
                    "packages": ["type": "integer", "minimum": 1],
                    "packagePrice": ["type": "number", "minimum": 0],
                    "totalPrice": ["type": "number", "minimum": 0]
                ])
            ],
            "days": [
                "type": "array", "minItems": 7, "maxItems": 7,
                "items": object([
                    "day": [
                        "type": "string",
                        "enum": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                    ],
                    "meals": [
                        "type": "array", "minItems": 1,
                        "items": object([
                            "mealType": ["type": "string", "enum": ["Breakfast", "Lunch", "Dinner"]],
                            "course": [
                                "type": "string",
                                "enum": ["Main dish", "First course", "Second course", "Side dish", "Dessert"]
                            ],
                            "name": ["type": "string"],
                            "preparationMinutes": ["type": "integer", "minimum": 1],
                            "servings": ["type": "integer", "enum": [1]],
                            "price": ["type": "number", "minimum": 0],
                            "ingredients": [
                                "type": "array", "minItems": 1,
                                "items": object([
                                    "productId": ["type": "string"],
                                    "name": ["type": "string"],
                                    "amount": ["type": "number", "minimum": 0.001],
                                    "unit": ["type": "string"]
                                ])
                            ],
                            "steps": [
                                "type": "array", "minItems": 1,
                                "items": ["type": "string"]
                            ]
                        ])
                    ]
                ])
            ]
        ],
        "required": ["currency", "weeklyTotalPrice", "shoppingList", "days"]
    ]

    private static func object(_ properties: [String: Any]) -> [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": properties,
            "required": Array(properties.keys).sorted()
        ]
    }
}

private enum MealPlanCatalogNormalizer {
    static func normalize(
        _ plan: WeeklyMealPlan,
        catalog: [CatalogProduct]
    ) -> WeeklyMealPlan {
        let productsByID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        let productsByName = Dictionary(
            grouping: catalog,
            by: { normalizedName($0.name) }
        )

        func canonicalProduct(id: String, name: String) -> CatalogProduct? {
            if let product = productsByID[id] { return product }
            let matches = productsByName[normalizedName(name), default: []]
            return matches.count == 1 ? matches[0] : nil
        }

        let days = plan.days.map { day in
            MealPlanDay(
                day: day.day,
                meals: day.meals.map { meal in
                    PlannedMeal(
                        mealType: meal.mealType,
                        course: meal.course,
                        name: meal.name,
                        preparationMinutes: meal.preparationMinutes,
                        servings: meal.servings,
                        price: meal.price,
                        ingredients: meal.ingredients.map { ingredient in
                            guard let product = canonicalProduct(
                                id: ingredient.productId,
                                name: ingredient.name
                            ) else { return ingredient }
                            return MealIngredient(
                                productId: product.id,
                                name: product.name,
                                amount: ingredient.amount,
                                unit: ingredient.unit
                            )
                        },
                        steps: meal.steps
                    )
                }
            )
        }

        let shoppingList = plan.shoppingList.map { item in
            guard let product = canonicalProduct(id: item.productId, name: item.name) else {
                return item
            }
            return ShoppingListItem(
                productId: product.id,
                name: product.name,
                packages: item.packages,
                packagePrice: product.price.amount,
                totalPrice: product.price.amount * Double(item.packages)
            )
        }

        return WeeklyMealPlan(
            currency: plan.currency,
            weeklyTotalPrice: plan.weeklyTotalPrice,
            shoppingList: shoppingList,
            days: days
        )
    }

    private static func normalizedName(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum MealPlanPackageNormalizer {
    static func normalize(
        _ plan: WeeklyMealPlan,
        catalog: [CatalogProduct]
    ) -> WeeklyMealPlan {
        let productsByID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        let ingredients = plan.days.flatMap(\.meals).flatMap(\.ingredients)
        let usageByProduct = Dictionary(grouping: ingredients, by: \.productId)
        let declaredByProduct = Dictionary(grouping: plan.shoppingList, by: \.productId)
        let allProductIDs = Set(usageByProduct.keys).union(declaredByProduct.keys)

        let shoppingList = allProductIDs.sorted().compactMap { productID -> ShoppingListItem? in
            guard let product = productsByID[productID] else {
                return declaredByProduct[productID]?.first
            }

            let declaredPackages = declaredByProduct[productID]?
                .reduce(0) { $0 + $1.packages } ?? 0
            let requiredPackages = packagesRequired(
                for: usageByProduct[productID, default: []],
                product: product
            )
            let packages = max(requiredPackages > 0 ? requiredPackages : declaredPackages, 1)
            let totalPrice = product.price.amount * Double(packages)
            return ShoppingListItem(
                productId: product.id,
                name: product.name,
                packages: packages,
                packagePrice: product.price.amount,
                totalPrice: roundedCurrency(totalPrice)
            )
        }

        let pricedDays = plan.days.map { day in
            MealPlanDay(
                day: day.day,
                meals: day.meals.map { meal in
                    PlannedMeal(
                        mealType: meal.mealType,
                        course: meal.course,
                        name: meal.name,
                        preparationMinutes: meal.preparationMinutes,
                        servings: meal.servings,
                        price: mealPrice(meal, productsByID: productsByID),
                        ingredients: meal.ingredients,
                        steps: meal.steps
                    )
                }
            )
        }

        return WeeklyMealPlan(
            currency: "EUR",
            weeklyTotalPrice: roundedCurrency(shoppingList.reduce(0) { $0 + $1.totalPrice }),
            shoppingList: shoppingList,
            days: pricedDays
        )
    }

    private static func mealPrice(
        _ meal: PlannedMeal,
        productsByID: [String: CatalogProduct]
    ) -> Double {
        let total = meal.ingredients.reduce(0.0) { partialResult, ingredient in
            guard let product = productsByID[ingredient.productId] else {
                return partialResult
            }
            guard let netContent = product.netContent,
                  let packageAmount = baseAmount(netContent.value, unit: netContent.unit),
                  let usedAmount = IngredientQuantityConverter.amount(
                    for: ingredient,
                    product: product
                  ),
                  usedAmount.dimension == packageAmount.dimension,
                  packageAmount.value > 0 else {
                // Without a measurable package size, the package price is the safest estimate.
                return partialResult + product.price.amount
            }
            return partialResult + product.price.amount * usedAmount.value / packageAmount.value
        }
        return roundedCurrency(total)
    }

    private static func packagesRequired(
        for ingredients: [MealIngredient],
        product: CatalogProduct
    ) -> Int {
        guard let netContent = product.netContent,
              let packageAmount = baseAmount(netContent.value, unit: netContent.unit) else {
            return 0
        }

        let compatibleUsage = ingredients.compactMap { ingredient in
            IngredientQuantityConverter.amount(for: ingredient, product: product).flatMap { amount in
                amount.dimension == packageAmount.dimension ? amount.value : nil
            }
        }
        guard compatibleUsage.count == ingredients.count else { return 0 }
        return Int(ceil(compatibleUsage.reduce(0, +) / packageAmount.value))
    }

    private static func roundedCurrency(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static func baseAmount(_ amount: Double, unit: String) -> (dimension: String, value: Double)? {
        IngredientQuantityConverter.baseAmount(amount, unit: unit)
    }
}

private struct ProductPromptItem: Encodable {
    let id: String
    let name: String
    let category: String
    let quantity: String
    let netContent: CatalogProduct.NetContent?
    let packagePrice: Double
    let nutrition: CatalogProduct.Nutrition
    let labels: [String]
    let allergens: [String]

    init(_ product: CatalogProduct) {
        id = product.id
        name = product.name
        category = product.category?.name ?? product.department.name
        quantity = product.quantity ?? "Not specified"
        netContent = product.netContent
        packagePrice = product.price.amount
        nutrition = product.nutrition
        labels = product.labels.map(\.name)
        allergens = product.allergens.map(\.name)
    }
}

private enum MealPlanValidator {
    static func validate(
        _ plan: WeeklyMealPlan,
        configuration: MealPlanConfiguration,
        catalog: [CatalogProduct]
    ) throws {
        let expectedDays = Set(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])
        guard plan.days.count == 7,
              Set(plan.days.map(\.day)) == expectedDays,
              plan.days.allSatisfy({ !$0.meals.isEmpty }) else {
            throw MealPlanGenerationError.invalidPlan("The response does not contain one or more meals for all seven days.")
        }

        let productsByID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        var purchasedIDs = Set<String>()
        var verifiedTotal = 0.0

        for item in plan.shoppingList {
            guard let product = productsByID[item.productId], product.name == item.name else {
                throw MealPlanGenerationError.invalidPlan("Unknown catalog product: \(item.productId).")
            }
            guard abs(product.price.amount - item.packagePrice) < 0.01 else {
                throw MealPlanGenerationError.invalidPlan("Incorrect package price for \(item.name).")
            }
            let expectedItemTotal = product.price.amount * Double(item.packages)
            guard abs(expectedItemTotal - item.totalPrice) < 0.02 else {
                throw MealPlanGenerationError.invalidPlan("Incorrect total price for \(item.name).")
            }
            purchasedIDs.insert(item.productId)
            verifiedTotal += expectedItemTotal
        }

        guard verifiedTotal <= Double(configuration.weeklyBudget) + 0.01,
              abs(verifiedTotal - plan.weeklyTotalPrice) < 0.05 else {
            throw MealPlanGenerationError.invalidPlan("The verified shopping total does not respect the weekly budget.")
        }

        let ingredients = plan.days.flatMap(\.meals).flatMap(\.ingredients)
        let usedIDs = Set(ingredients.map(\.productId))
        guard usedIDs.isSubset(of: purchasedIDs) else {
            throw MealPlanGenerationError.invalidPlan("A recipe uses a product missing from the shopping list.")
        }

        let packagesByProduct = Dictionary(grouping: plan.shoppingList, by: \.productId)
            .mapValues { $0.reduce(0) { $0 + $1.packages } }
        let usageByProduct = Dictionary(grouping: ingredients, by: \.productId)

        for (productID, usages) in usageByProduct {
            guard let netContent = productsByID[productID]?.netContent,
                  let packageAmount = baseAmount(netContent.value, unit: netContent.unit) else {
                continue
            }

            let product = productsByID[productID]!
            let usedAmounts = try usages.map { ingredient in
                guard let amount = IngredientQuantityConverter.amount(for: ingredient, product: product),
                      amount.dimension == packageAmount.dimension else {
                    throw MealPlanGenerationError.invalidPlan(
                        "Unit '\(ingredient.unit)' is incompatible with the package size of \(ingredient.name)."
                    )
                }
                return amount.value
            }
            let availableAmount = packageAmount.value * Double(packagesByProduct[productID, default: 0])
            guard usedAmounts.reduce(0, +) <= availableAmount + 0.001 else {
                throw MealPlanGenerationError.invalidPlan(
                    "The shopping list does not buy enough packages of \(usages[0].name)."
                )
            }
        }
    }

    private static func baseAmount(_ amount: Double, unit: String) -> (dimension: String, value: Double)? {
        IngredientQuantityConverter.baseAmount(amount, unit: unit)
    }
}

private enum IngredientQuantityConverter {
    static func amount(
        for ingredient: MealIngredient,
        product: CatalogProduct
    ) -> (dimension: String, value: Double)? {
        guard let amount = baseAmount(ingredient.amount, unit: ingredient.unit) else {
            return nil
        }

        // The catalog records egg packages by weight, while recipes conventionally count eggs.
        if amount.dimension == "count",
           product.name.localizedCaseInsensitiveContains("egg"),
           product.netContent?.unit.lowercased() == "g" {
            return ("mass", amount.value * 60)
        }

        // LLM recipes sometimes express liquids in grams even when their package is measured in
        // millilitres (or vice versa). A 1 g ≈ 1 ml culinary conversion is sufficiently cautious
        // for package rounding and avoids rejecting otherwise valid recipes.
        if let netContent = product.netContent,
           let packageAmount = baseAmount(netContent.value, unit: netContent.unit),
           Set([amount.dimension, packageAmount.dimension]) == Set(["mass", "volume"]) {
            return (packageAmount.dimension, amount.value)
        }
        return amount
    }

    static func baseAmount(_ amount: Double, unit: String) -> (dimension: String, value: Double)? {
        switch unit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "g", "gram", "grams": ("mass", amount)
        case "kg", "kilogram", "kilograms": ("mass", amount * 1_000)
        case "ml", "milliliter", "milliliters": ("volume", amount)
        case "l", "liter", "liters", "litre", "litres": ("volume", amount * 1_000)
        case "piece", "pieces", "unit", "units": ("count", amount)
        default: nil
        }
    }
}

enum MealPlanGenerationError: LocalizedError {
    case missingOpenAIAPIKey
    case invalidOpenAIAPIKeyConfiguration
    case catalogNotFound
    case catalogDecodingFailed(String)
    case noMatchingProducts
    case invalidResponse
    case missingOutput
    case responseDecodingFailed(String)
    case generationIncomplete(reason: String, outputTokens: Int?)
    case api(String)
    case invalidPlan(String)

    var errorDescription: String? {
        switch self {
        case .missingOpenAIAPIKey: "OPENAI_API_KEY is not configured in the Xcode scheme."
        case .invalidOpenAIAPIKeyConfiguration: "The OpenAI API key could not be added to the request."
        case .catalogNotFound: "product_catalog_en.json is missing from the app bundle."
        case .catalogDecodingFailed(let details): "Could not decode product_catalog_en.json: \(details)"
        case .noMatchingProducts: "No catalog products match the selected preferences."
        case .invalidResponse: "The OpenAI API returned an invalid HTTP response."
        case .missingOutput: "The OpenAI response contains no structured output."
        case .responseDecodingFailed(let details): "Could not decode the OpenAI response. \(details)"
        case .generationIncomplete(let reason, let outputTokens):
            "OpenAI stopped before completing the plan (\(reason)). Output tokens: \(outputTokens.map(String.init) ?? "unknown")."
        case .api(let message), .invalidPlan(let message): message
        }
    }
}
