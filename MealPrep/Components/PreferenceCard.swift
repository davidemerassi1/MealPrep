import SwiftUI

struct PreferenceCard: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7 * scale) {
                if let icon {
                    Text(icon)
                        .font(.system(size: 27 * scale))
                        .frame(height: 29 * scale)
                }

                Text(title)
                    .font(.custom("Promo-SemiBold", size: 15 * scale))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isSelected ? Color.mealPrepSelectionBackground : Color.mealPrepTrack,
                in: RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
                    .stroke(
                        isSelected ? Color.mealPrepGreen : .clear,
                        lineWidth: 2 * scale
                    )
            }
        }
        .buttonStyle(PreferenceCardButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PreferenceCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
