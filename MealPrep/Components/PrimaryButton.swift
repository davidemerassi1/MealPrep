import SwiftUI

struct PrimaryButton: View {
    let title: String
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Promo-SemiBold", size: 16 * scale))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56 * scale)
                .background(Color.mealPrepGreen, in: Capsule())
        }
        .buttonStyle(MealPrepButtonStyle())
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
