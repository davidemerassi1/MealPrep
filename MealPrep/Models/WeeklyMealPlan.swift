import Foundation

struct WeeklyMealPlan: Codable {
    let currency: String
    let weeklyTotalPrice: Double
    let shoppingList: [ShoppingListItem]
    let days: [MealPlanDay]
}

struct ShoppingListItem: Codable {
    let productId: String
    let name: String
    let brand: String
    let category: String
    let packages: Int
    let packagePrice: Double
    let totalPrice: Double
}

struct MealPlanDay: Codable {
    let day: String
    let meals: [PlannedMeal]
}

struct PlannedMeal: Codable {
    let mealType: String
    let course: String
    let name: String
    let preparationMinutes: Int
    let servings: Int
    let price: Double
    let ingredients: [MealIngredient]
    let steps: [String]
}

struct MealIngredient: Codable {
    let productId: String
    let name: String
    let amount: Double
    let unit: String
}

struct MealPlanConfiguration {
    let weeklyBudget: Int
    let dietaryNeeds: Set<DietaryNeed>
    let nutritionalGoals: Set<NutritionalGoal>
}
