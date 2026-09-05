import SwiftUI

struct PrimaryButton: View {
    let title: String
    let scale: CGFloat
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Promo-SemiBold", size: 16 * scale))
                .foregroundStyle(isEnabled ? .white : Color.mealPrepDisabledText)
                .frame(maxWidth: .infinity, minHeight: 60 * scale)
                .background(
                    isEnabled ? Color.mealPrepGreen : Color.mealPrepDisabledBackground,
                    in: Capsule()
                )
        }
        .buttonStyle(MealPrepButtonStyle())
        .disabled(!isEnabled)
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
