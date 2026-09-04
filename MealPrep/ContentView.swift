import CoreText
import SwiftUI

struct ContentView: View {
    @State private var bagScale: CGFloat = 1
    @State private var foodsVisible = false
    @State private var foodOrbitRotation: Double = 0
    @State private var highlightedFoodIndex: Int?
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            // The Figma frame is 375 pt wide. GeometryReader's height excludes
            // the safe areas, so using it in the scale calculation made every
            // element about 10% smaller on the reference device.
            let scale = proxy.size.width / 375

            ZStack {
                Color.white.ignoresSafeArea()

                Text("MealPrep")
                    .font(.custom("Promo-Bold", size: 34 * scale))
                    .foregroundStyle(.black)
                    .accessibilityAddTraits(.isHeader)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 13 * scale)

                MealPrepHero(
                    bagScale: bagScale,
                    foodsVisible: foodsVisible,
                    orbitRotation: foodOrbitRotation,
                    highlightedFoodIndex: highlightedFoodIndex
                )
                    .frame(width: 246 * scale, height: 290 * scale)
                    .scaleEffect(scale)
                    .offset(y: -5 * scale)

                Button(action: startMealPlan) {
                    Text("Create your meal plan")
                        .font(.custom("Promo-SemiBold", size: 16 * scale))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52 * scale)
                        .background(Color.mealPrepGreen, in: Capsule())
                }
                .buttonStyle(MealPrepButtonStyle())
                .accessibilityHint("Starts the meal plan setup")
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 20 * scale)
                .padding(.bottom, 18 * scale)
            }
            .onAppear {
                playEntranceAnimation()
            }
            .onDisappear {
                animationTask?.cancel()
            }
        }
        .preferredColorScheme(.light)
    }

    private func startMealPlan() {
        // The budget flow will be connected when screen 02 is implemented.
    }

    private func playEntranceAnimation() {
        foodsVisible = false
        bagScale = 1
        foodOrbitRotation = 0
        highlightedFoodIndex = nil
        animationTask?.cancel()

        animationTask = Task { @MainActor in
            // Let the static composition settle briefly before the entrance starts.
            try? await Task.sleep(for: .milliseconds(350))

            withAnimation(.easeInOut(duration: 0.26)) {
                bagScale = 0.76
            }

            try? await Task.sleep(for: .milliseconds(260))

            withAnimation(.spring(response: 0.70, dampingFraction: 0.60)) {
                bagScale = 1
            }

            // Let the foods burst slightly beyond the ring and spring back.
            withAnimation(.spring(response: 0.70, dampingFraction: 0.60)) {
                foodsVisible = true
            }

            // The first spring apex occurs before the foods settle. Start the
            // orbit there, so rotation is already active on their way back.
            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                foodOrbitRotation = 360
            }

            // Static sequence: apple, olive, meat, corn, carrot, cheese, aubergine.
            try? await Task.sleep(for: .milliseconds(420))
            let animDuration = 0.2
            let duration = 1.5
            let pulseOrder = [0, 3, 1, 5, 2, 6, 4]
            while !Task.isCancelled {
                for index in pulseOrder {
                    guard !Task.isCancelled else { return }

                    withAnimation(.linear(duration: animDuration)) {
                        highlightedFoodIndex = index
                    }
                    try? await Task.sleep(for: .seconds(duration))

                    withAnimation(.linear(duration: animDuration)) {
                        highlightedFoodIndex = nil
                    }
                    //try? await Task.sleep(for: .seconds(animDuration))
                }
            }
        }
    }
}

private struct MealPrepHero: View {
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
                        symbol,
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
            // Give the orbit layer an explicit center matching the bag's center.
            // Without this frame SwiftUI sizes the stack like a single emoji,
            // causing the rotation to occur around the wrong anchor point.
            .frame(width: radius * 2 + 40, height: radius * 2 + 40)
            .rotationEffect(.degrees(orbitRotation))

            ShoppingBag()
                // The source PNG has transparent breathing room around the bag.
                // This frame produces the same visible 150 pt-wide subject as Figma.
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

    init(
        _ symbol: String,
        destination: CGPoint,
        isVisible: Bool,
        counterRotation: Double,
        isHighlighted: Bool
    ) {
        self.symbol = symbol
        self.destination = destination
        self.isVisible = isVisible
        self.counterRotation = counterRotation
        self.isHighlighted = isHighlighted
    }

    var body: some View {
        Text(symbol)
            .font(.system(size: 32))
            // Applied before the offset so it only keeps the emoji upright;
            // the parent stack remains free to move it along the orbit.
            .rotationEffect(.degrees(-counterRotation))
            // Scale locally before positioning the emoji on the ring. Applying
            // it after offset would also increase its distance from the center.
            .scaleEffect(isVisible ? (isHighlighted ? 1.7 : 1) : 0.2)
            .offset(
                x: isVisible ? destination.x : 0,
                y: isVisible ? destination.y : 0
            )
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(true)
    }
}

private struct ShoppingBag: View {
    var body: some View {
        Image("MealPrepBag")
            .resizable()
            .scaledToFit()
    }
}

private struct MealPrepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
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

private extension Color {
    static let mealPrepGreen = Color(red: 0.39, green: 0.78, blue: 0.40)
}

#Preview("Lander – iPhone 375 × 812", traits: .fixedLayout(width: 375, height: 812)) {
    ContentView()
}
