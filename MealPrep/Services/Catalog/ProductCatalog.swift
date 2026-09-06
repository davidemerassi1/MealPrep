import Foundation

struct CatalogProduct: Decodable {
    struct NamedValue: Decodable {
        let id: String
        let name: String
    }

    struct Price: Decodable {
        let amount: Double
        let currency: String
    }

    struct Nutrition: Codable {
        let energyKcal100g: Double?
        let fat100g: Double?
        let saturatedFat100g: Double?
        let carbohydrates100g: Double?
        let sugars100g: Double?
        let fiber100g: Double?
        let proteins100g: Double?
        let salt100g: Double?
    }

    struct NetContent: Codable {
        let value: Double
        let unit: String
    }

    let id: String
    let name: String
    let brand: String
    let department: NamedValue
    let category: NamedValue?
    let quantity: String?
    let netContent: NetContent?
    let price: Price
    let nutrition: Nutrition
    let labels: [NamedValue]
    let allergens: [NamedValue]
}

enum ProductCatalogLoader {
    static func load() throws -> [CatalogProduct] {
        let url = Bundle.main.url(
            forResource: "product_catalog_en",
            withExtension: "json",
            subdirectory: "resources"
        ) ?? Bundle.main.url(forResource: "product_catalog_en", withExtension: "json")

        guard let url else { throw MealPlanGenerationError.catalogNotFound }

        do {
            let data = try Data(contentsOf: url)
            let products = try JSONDecoder().decode([CatalogProduct].self, from: data)
            guard !products.isEmpty else {
                throw MealPlanGenerationError.catalogDecodingFailed("The catalog is empty.")
            }
            print("[MealPrep] Loaded \(products.count) products from \(url.lastPathComponent).")
            return products
        } catch let error as MealPlanGenerationError {
            throw error
        } catch let error as DecodingError {
            throw MealPlanGenerationError.catalogDecodingFailed(error.mealPrepDiagnosticDescription)
        } catch {
            throw MealPlanGenerationError.catalogDecodingFailed(error.localizedDescription)
        }
    }
}

enum CatalogCandidateSelector {
    private static let mealDepartments: Set<String> = [
        "Dairy & Eggs", "Pasta, Rice & Sauces", "Bakery & Pastry",
        "Preserves & Canned Goods", "Fish", "Frozen Foods",
        "Fruits & Vegetables", "Organic & Dietetic", "Meat", "Pantry"
    ]

    static func select(
        from products: [CatalogProduct],
        configuration: MealPlanConfiguration
    ) -> [CatalogProduct] {
        products.filter {
            mealDepartments.contains($0.department.name)
                && $0.price.amount > 0
                && $0.price.amount <= Double(configuration.weeklyBudget)
                && matchesDiet($0, needs: configuration.dietaryNeeds)
        }
        .sorted {
            score($0, goals: configuration.nutritionalGoals)
                < score($1, goals: configuration.nutritionalGoals)
        }
    }

    private static func matchesDiet(
        _ product: CatalogProduct,
        needs: Set<DietaryNeed>
    ) -> Bool {
        let allergens = Set(product.allergens.map { $0.name.lowercased() })
        let labels = Set(product.labels.map { $0.name.lowercased() })
        let department = product.department.name

        if needs.contains(.vegan) {
            let animalDepartments: Set<String> = ["Meat", "Fish"]
            let animalAllergens = ["latte", "uova", "pesce", "crostacei", "molluschi"]
            if animalDepartments.contains(department)
                || animalAllergens.contains(where: allergens.contains) {
                return false
            }
        } else if needs.contains(.veggie) {
            if department == "Meat" || department == "Fish" { return false }
        } else if needs.contains(.pescatarian), department == "Meat" {
            return false
        }

        if needs.contains(.glutenFree), allergens.contains("glutine") { return false }
        if needs.contains(.dairyFree), allergens.contains("latte") { return false }
        return true
    }

    private static func score(
        _ product: CatalogProduct,
        goals: Set<NutritionalGoal>
    ) -> Double {
        var result = product.price.amount
        if goals.contains(.highProtein) {
            result -= (product.nutrition.proteins100g ?? 0) * 0.35
        }
        if goals.contains(.lowSugar) {
            result += (product.nutrition.sugars100g ?? 100) * 0.18
        }
        if goals.contains(.lowFat) {
            result += (product.nutrition.fat100g ?? 100) * 0.14
        }
        if goals.contains(.lowCarbs) {
            result += (product.nutrition.carbohydrates100g ?? 100) * 0.08
        }
        if goals.contains(.lowSalt) {
            result += (product.nutrition.salt100g ?? 10) * 0.8
        }
        return result
    }
}
