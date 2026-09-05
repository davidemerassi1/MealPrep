import SwiftUI

struct FlowProgressHeader: View {
    let progress: CGFloat
    let scale: CGFloat
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 9 * scale) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14 * scale, weight: .bold))
                    .foregroundStyle(.black.opacity(0.58))
                    .frame(width: 32 * scale, height: 32 * scale)
                    .background(Color.mealPrepTrack, in: Circle())
            }
            .accessibilityLabel("Back")

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.mealPrepTrack)
                    Capsule()
                        .fill(Color.mealPrepGreen)
                        .frame(width: proxy.size.width * progress)
                        .overlay(alignment: .topLeading) {
                            Capsule()
                                .fill(Color.mealPrepGreenHighlight)
                                .frame(
                                    width: max(proxy.size.width * progress - 16 * scale, 0),
                                    height: 4 * scale
                                )
                                .padding(.leading, 8 * scale)
                                .padding(.top, 2 * scale)
                        }
                }
                .animation(.easeInOut(duration: 0.26), value: progress)
            }
            .frame(height: 18 * scale)
        }
        .frame(height: 32 * scale)
    }
}
