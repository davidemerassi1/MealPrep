import CoreText
import SwiftUI

enum MealPrepTheme {
    static let referenceWidth: CGFloat = 375

    static func scale(for width: CGFloat) -> CGFloat {
        width / referenceWidth
    }
}

extension Color {
    static let mealPrepGreen = Color(red: 0.39, green: 0.78, blue: 0.40)
    static let mealPrepGreenHighlight = Color(red: 0.45, green: 0.85, blue: 0.50)
    static let mealPrepTrack = Color(red: 0.96, green: 0.95, blue: 0.97)
    static let mealPrepSecondaryText = Color(red: 0.43, green: 0.43, blue: 0.43)
}

enum PromoFonts {
    private static var didRegister = false

    static func register() {
        guard !didRegister else { return }
        didRegister = true

        ["Promo-Normal", "Promo-SemiBold", "Promo-Bold"].forEach { name in
            let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf")
            guard let url else { return }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
