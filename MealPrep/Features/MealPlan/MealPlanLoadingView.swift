import SwiftUI

struct MealPlanLoadingView: View {
    let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false
    @State private var dots = 0

    var body: some View {
        ZStack {
            Color.mealPrepGreen.ignoresSafeArea()

            VStack(spacing: 28 * scale) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.20))
                        .frame(width: 190 * scale, height: 190 * scale)
                        .scaleEffect(isPulsing ? 1.08 : 0.92)

                    Image("MealPrepBag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120 * scale, height: 140 * scale)
                        .scaleEffect(isPulsing ? 1.04 : 0.96)
                }

                VStack(spacing: 10 * scale) {
                    Text("Preparing your meal plan\(String(repeating: ".", count: dots))")
                        .font(.custom("Promo-Bold", size: 25 * scale))
                        .foregroundStyle(.white)
                        .frame(height: 34 * scale)

                    Text("Choosing the best ingredients for your budget and preferences")
                        .font(.custom("Promo-SemiBold", size: 15 * scale))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 38 * scale)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(450))
                dots = (dots + 1) % 4
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preparing your meal plan")
    }
}
