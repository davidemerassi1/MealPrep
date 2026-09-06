import Foundation

enum MealPlanLogger {
    static func log(_ plan: WeeklyMealPlan) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(plan),
              let json = String(data: data, encoding: .utf8) else {
            print("[MealPrep] Could not encode the generated meal plan.")
            return
        }
        print("[MealPrep] Generated weekly meal plan:\n\(json)")
    }

    static func log(error: Error) {
        print("[MealPrep] Meal plan generation failed: \(error.localizedDescription)")
    }
}
