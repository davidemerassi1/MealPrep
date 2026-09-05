import SwiftUI

struct RollingBudgetValue: View {
    let value: Int
    let scale: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerProgress: CGFloat = 0
    @State private var shimmerTask: Task<Void, Never>?

    private var hundreds: Int { value / 100 }
    private var tens: Int { (value / 10) % 10 }
    private var units: Int { value % 10 }

    var body: some View {
        HStack(spacing: 0) {
            Text("€")

            if hundreds > 0 {
                RollingDigit(value: hundreds, transitionValue: value, scale: scale)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            RollingDigit(value: tens, transitionValue: value, scale: scale)
            RollingDigit(value: units, transitionValue: value, scale: scale)
        }
        .font(.custom("Promo-Bold", size: 78 * scale))
        .foregroundStyle(.black)
        .overlay {
            if !reduceMotion {
                GeometryReader { proxy in
                    let shimmerWidth = 350 * scale

                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: Color.mealPrepGreen.opacity(0.10), location: 0.05),
                                    .init(color: Color.mealPrepGreen.opacity(0.58), location: 0.18),
                                    .init(color: Color.mealPrepGreenHighlight.opacity(0.95), location: 0.50),
                                    .init(color: Color.mealPrepGreen.opacity(0.58), location: 0.82),
                                    .init(color: Color.mealPrepGreen.opacity(0.10), location: 0.95),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: shimmerWidth, height: proxy.size.height + 16 * scale)
                        .blur(radius: 3 * scale)
                        .offset(
                            x: -shimmerWidth + shimmerProgress * (proxy.size.width + shimmerWidth),
                            y: -8 * scale
                        )
                }
                .mask {
                    shimmerMask
                        .blur(radius: 1.25 * scale)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: hundreds > 0)
        .onChange(of: value) {
            scheduleShimmer()
        }
        .onAppear {
            scheduleShimmer()
        }
        .onDisappear { shimmerTask?.cancel() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("€\(value)")
    }

    private var shimmerMask: some View {
        HStack(spacing: 0) {
            Text("€")

            if hundreds > 0 {
                Text("\(hundreds)")
                    .frame(minWidth: 39 * scale)
            }

            Text("\(tens)")
                .frame(minWidth: 39 * scale)
            Text("\(units)")
                .frame(minWidth: 39 * scale)
        }
        .font(.custom("Promo-Bold", size: 78 * scale))
    }

    private func scheduleShimmer() {
        shimmerTask?.cancel()
        guard !reduceMotion else { return }

        shimmerTask = Task { @MainActor in
            // Wait until the slider has stopped changing before running once.
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }

            var resetTransaction = Transaction()
            resetTransaction.disablesAnimations = true
            withTransaction(resetTransaction) {
                shimmerProgress = 0
            }

            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 1.0)) {
                shimmerProgress = 1
            }
        }
    }
}

private struct RollingDigit: View {
    let value: Int
    let transitionValue: Int
    let scale: CGFloat

    var body: some View {
        Text("\(value)")
            .contentTransition(.numericText(value: Double(transitionValue)))
            .animation(.snappy(duration: 0.30), value: value)
            .frame(minWidth: 39 * scale)
            .clipped()
    }
}

#Preview("Rolling budget") {
    RollingBudgetValue(value: 82, scale: 1)
}
