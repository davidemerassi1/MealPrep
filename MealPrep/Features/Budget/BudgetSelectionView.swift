import SwiftUI

struct BudgetSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var budget: Double = 80

    private let budgetRange = 25.0...150.0
    private var selectedBudget: Int {
        Int((budget / 5).rounded() * 5)
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)

            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    FlowProgressHeader(progress: 0.25, scale: scale) {
                        dismiss()
                    }

                    Text("What’s your budget?")
                        .font(.custom("Promo-Bold", size: 27 * scale))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 15 * scale)

                    Spacer()
                }
                .padding(.horizontal, 20 * scale)

                VStack(spacing: 2 * scale) {
                    RollingBudgetValue(value: selectedBudget, scale: scale)

                    Text("per week")
                        .font(.custom("Promo-SemiBold", size: 18 * scale))
                        .foregroundStyle(Color.mealPrepSecondaryText)

                    BudgetSlider(value: $budget, range: budgetRange, scale: scale)
                        .padding(.top, 48 * scale)
                }
                .offset(y: -8 * scale)
                .padding(.horizontal, 24 * scale)

                PrimaryButton(title: "Continue", scale: scale) {
                    // Screen 03 will be connected when dietary needs is implemented.
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.horizontal, 20 * scale)
                .padding(.bottom, 18 * scale)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct BudgetSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let scale: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbSize = 58 * scale
            let travel = max(0, proxy.size.width - thumbSize)
            let thumbX = travel * fraction
            let fillWidth = thumbX + thumbSize / 2

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.mealPrepTrack)
                    .frame(height: 14 * scale)

                Capsule()
                    .fill(Color.mealPrepGreen)
                    .frame(width: fillWidth, height: 14 * scale)
                    .overlay(alignment: .topLeading) {
                        Capsule()
                            .fill(Color.mealPrepGreenHighlight)
                            .frame(
                                width: max(fillWidth - 16 * scale, 0),
                                height: 4 * scale
                            )
                            .padding(.leading, 8 * scale)
                            .padding(.top, 2 * scale)
                    }

                Circle()
                    .fill(Color(red: 0.97, green: 0.96, blue: 0.98))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                    .offset(x: thumbX)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let position = min(max(0, gesture.location.x - thumbSize / 2), travel)
                        let rawValue = range.lowerBound
                            + (position / max(travel, 1)) * (range.upperBound - range.lowerBound)
                        value = rawValue
                    }
            )
            .sensoryFeedback(.selection, trigger: Int((value / 5).rounded()))
            .accessibilityElement()
            .accessibilityLabel("Weekly budget")
            .accessibilityValue("€\(Int((value / 5).rounded() * 5)) per week")
            .accessibilityAdjustableAction { direction in
                let snappedValue = (value / 5).rounded() * 5
                switch direction {
                case .increment:
                    value = min(snappedValue + 5, range.upperBound)
                case .decrement:
                    value = max(snappedValue - 5, range.lowerBound)
                @unknown default:
                    break
                }
            }
        }
        .frame(height: 62 * scale)
    }
}

#Preview("Budget", traits: .fixedLayout(width: 375, height: 812)) {
    NavigationStack {
        BudgetSelectionView()
    }
}
