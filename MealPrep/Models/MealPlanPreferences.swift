import Foundation

enum DietaryNeed: String, CaseIterable, Hashable, Identifiable {
    case none
    case veggie
    case vegan
    case pescatarian
    case glutenFree
    case dairyFree

    var id: Self { self }

    var title: String {
        switch self {
        case .none: "None"
        case .veggie: "Veggie"
        case .vegan: "Vegan"
        case .pescatarian: "Pescatarian"
        case .glutenFree: "Gluten free"
        case .dairyFree: "Dairy free"
        }
    }

    var icon: String? {
        switch self {
        case .none: nil
        case .veggie: "🥕"
        case .vegan: "🌱"
        case .pescatarian: "🐟"
        case .glutenFree: "🌾"
        case .dairyFree: "🥛"
        }
    }
}

enum NutritionalGoal: String, CaseIterable, Hashable, Identifiable {
    case none
    case highProtein
    case lowSugar
    case lowFat
    case lowCarbs
    case lowSalt

    var id: Self { self }

    var title: String {
        switch self {
        case .none: "None"
        case .highProtein: "High protein"
        case .lowSugar: "Low sugar"
        case .lowFat: "Low fat"
        case .lowCarbs: "Low carbs"
        case .lowSalt: "Low salt"
        }
    }

    var icon: String? {
        switch self {
        case .none: nil
        case .highProtein: "🥩"
        case .lowSugar: "🍯"
        case .lowFat: "🫑"
        case .lowCarbs: "🥓"
        case .lowSalt: "🧂"
        }
    }
}
