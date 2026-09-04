import CoreText
import SwiftUI

struct ContentView: View {
    @State private var hasAppeared = false

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

                MealPrepHero(isVisible: hasAppeared)
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
                withAnimation(.spring(response: 0.75, dampingFraction: 0.72)) {
                    hasAppeared = true
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func startMealPlan() {
        // The budget flow will be connected when screen 02 is implemented.
    }
}

private struct MealPrepHero: View {
    let isVisible: Bool

    var body: some View {
        ZStack {
            FloatingFood("🍎", x: -112, y: -126, delay: 0.10, isVisible: isVisible)
            FloatingFood("🥩", x: 94, y: -137, delay: 0.16, isVisible: isVisible)
            FloatingFood("🧀", x: -139, y: -18, delay: 0.22, isVisible: isVisible)
            FloatingFood("🥕", x: 137, y: -38, delay: 0.28, isVisible: isVisible)
            FloatingFood("🌽", x: -116, y: 119, delay: 0.34, isVisible: isVisible)
            FloatingFood("🍆", x: 67, y: 143, delay: 0.40, isVisible: isVisible)
            FloatingFood("🫒", x: 136, y: 96, delay: 0.46, isVisible: isVisible)

            ShoppingBag()
                // The source PNG has transparent breathing room around the bag.
                // This frame produces the same visible 150 pt-wide subject as Figma.
                .frame(width: 196, height: 196)
                .scaleEffect(isVisible ? 1 : 0.78)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.68), value: isVisible)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A grocery bag surrounded by fresh ingredients")
    }
}

private struct FloatingFood: View {
    let symbol: String
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    let isVisible: Bool

    init(_ symbol: String, x: CGFloat, y: CGFloat, delay: Double, isVisible: Bool) {
        self.symbol = symbol
        self.x = x
        self.y = y
        self.delay = delay
        self.isVisible = isVisible
    }

    var body: some View {
        Text(symbol)
            .font(.system(size: 32))
            .offset(x: x, y: y)
            .scaleEffect(isVisible ? 1 : 0.2)
            .opacity(isVisible ? 1 : 0)
            .rotationEffect(.degrees(isVisible ? 0 : -18))
            .animation(.spring(response: 0.62, dampingFraction: 0.62).delay(delay), value: isVisible)
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
