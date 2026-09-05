import SwiftUI

struct MealPrepHero: View {
    let bagScale: CGFloat
    let foodsVisible: Bool
    let orbitRotation: Double
    let highlightedFoodIndex: Int?

    private let foods = ["🍎", "🥩", "🥕", "🫒", "🍆", "🌽", "🧀"]
    private let radius: CGFloat = 150

    var body: some View {
        ZStack {
            ZStack {
                ForEach(Array(foods.enumerated()), id: \.offset) { index, symbol in
                    let angle = Angle.degrees(-90 + Double(index) * 360 / Double(foods.count))
                    FloatingFood(
                        symbol: symbol,
                        destination: CGPoint(
                            x: cos(angle.radians) * radius,
                            y: sin(angle.radians) * radius
                        ),
                        isVisible: foodsVisible,
                        counterRotation: orbitRotation,
                        isHighlighted: highlightedFoodIndex == index
                    )
                }
            }
            .frame(width: radius * 2 + 40, height: radius * 2 + 40)
            .rotationEffect(.degrees(orbitRotation))

            Image("MealPrepBag")
                .resizable()
                .scaledToFit()
                .frame(width: 196, height: 196)
                .scaleEffect(bagScale)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A grocery bag surrounded by fresh ingredients")
    }
}

private struct FloatingFood: View {
    let symbol: String
    let destination: CGPoint
    let isVisible: Bool
    let counterRotation: Double
    let isHighlighted: Bool

    var body: some View {
        Text(symbol)
            .font(.system(size: 32))
            .rotationEffect(.degrees(-counterRotation))
            .scaleEffect(isVisible ? (isHighlighted ? 1.7 : 1) : 0.2)
            .offset(
                x: isVisible ? destination.x : 0,
                y: isVisible ? destination.y : 0
            )
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(true)
    }
}
