import SwiftUI

struct MealPlanErrorView: View {
    let message: String
    let scale: CGFloat
    let onRetry: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 18 * scale) {
                Image(systemName: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.system(size: 42 * scale, weight: .semibold))
                    .foregroundStyle(Color.mealPrepGreen)

                Text("We couldn’t create your plan")
                    .font(.custom("Promo-Bold", size: 25 * scale))

                Text(message)
                    .font(.custom("Promo-Normal", size: 14 * scale))
                    .foregroundStyle(Color.mealPrepSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24 * scale)

                PrimaryButton(title: "Try again", scale: scale, action: onRetry)

                Button("Change preferences", action: onBack)
                    .font(.custom("Promo-SemiBold", size: 15 * scale))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 20 * scale)
        }
    }
}
