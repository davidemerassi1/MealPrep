import SwiftUI

struct LanderView: View {
    let onCreateMealPlan: () -> Void

    @State private var bagScale: CGFloat = 1
    @State private var foodsVisible = false
    @State private var foodOrbitRotation: Double = 0
    @State private var highlightedFoodIndex: Int?
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)

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

                PrimaryButton(title: "Create your meal plan", scale: scale, action: onCreateMealPlan)
                    .accessibilityHint("Starts the meal plan setup")
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 20 * scale)
                    .padding(.bottom, 18 * scale)
            }
            .onAppear(perform: playEntranceAnimation)
            .onDisappear { animationTask?.cancel() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func playEntranceAnimation() {
        foodsVisible = false
        bagScale = 1
        foodOrbitRotation = 0
        highlightedFoodIndex = nil
        animationTask?.cancel()

        animationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))

            withAnimation(.easeInOut(duration: 0.26)) { bagScale = 0.76 }
            try? await Task.sleep(for: .milliseconds(260))

            withAnimation(.spring(response: 0.70, dampingFraction: 0.60)) { bagScale = 1 }
            withAnimation(.spring(response: 0.70, dampingFraction: 0.60)) { foodsVisible = true }

            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                foodOrbitRotation = 360
            }
        }
    }
}

#Preview("Lander", traits: .fixedLayout(width: 375, height: 812)) {
    LanderView(onCreateMealPlan: {})
}
