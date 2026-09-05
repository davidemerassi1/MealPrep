import SwiftUI

struct MealSetupFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: SetupStep = .budget
    @State private var budget: Double = 80
    @State private var dietaryNeeds: Set<DietaryNeed> = []
    @State private var nutritionalGoals: Set<NutritionalGoal> = []
    @State private var displayedProgress: CGFloat = SetupStep.budget.progress
    @State private var contentOpacity = 1.0
    @State private var contentOffset: CGFloat = 0
    @State private var isTransitioning = false

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)

            VStack(spacing: 0) {
                FlowProgressHeader(progress: displayedProgress, scale: scale, onBack: goBack)
                    .padding(.top, 20 * scale)

                ZStack {
                    stepContent
                        .id(step)
                        .opacity(contentOpacity)
                        .offset(x: contentOffset * proxy.size.width)
                }
                .padding(.top, 30 * scale)

                PrimaryButton(
                    title: "Continue",
                    scale: scale,
                    isEnabled: canContinue,
                    action: continueFlow
                )
                .allowsHitTesting(!isTransitioning)
                .padding(.top, 16 * scale)
                .padding(.bottom, 18 * scale)
            }
            .padding(.horizontal, 20 * scale)
            .background(Color.white.ignoresSafeArea())
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .budget:
            BudgetSelectionContent(budget: $budget)
        case .dietaryNeeds:
            DietaryNeedsSelectionView(selection: $dietaryNeeds)
        case .nutritionalGoals:
            NutritionalGoalsSelectionView(selection: $nutritionalGoals)
        }
    }

    private var canContinue: Bool {
        switch step {
        case .budget: true
        case .dietaryNeeds: !dietaryNeeds.isEmpty
        case .nutritionalGoals: !nutritionalGoals.isEmpty
        }
    }

    private func continueFlow() {
        guard !isTransitioning, let next = step.next else {
            // Screen 05 will be connected with the weekly meal plan.
            return
        }
        transition(to: next, forward: true)
    }

    private func goBack() {
        guard !isTransitioning else { return }
        guard let previous = step.previous else {
            dismiss()
            return
        }
        transition(to: previous, forward: false)
    }

    private func transition(to destination: SetupStep, forward: Bool) {
        isTransitioning = true

        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.26)) {
                displayedProgress = destination.progress
            }

            withAnimation(.easeIn(duration: 0.12)) {
                contentOpacity = 0.03
                contentOffset = forward ? -0.10 : 0.10
            }

            try? await Task.sleep(for: .milliseconds(120))

            var replacement = Transaction()
            replacement.disablesAnimations = true
            withTransaction(replacement) {
                step = destination
                contentOpacity = 0.03
                contentOffset = forward ? 0.22 : -0.22
            }

            withAnimation(.easeOut(duration: 0.18)) {
                contentOpacity = 1
                contentOffset = 0
            }

            try? await Task.sleep(for: .milliseconds(180))
            isTransitioning = false
        }
    }
}

private enum SetupStep: Int, Hashable {
    case budget
    case dietaryNeeds
    case nutritionalGoals

    var progress: CGFloat {
        switch self {
        case .budget: 0.25
        case .dietaryNeeds: 0.50
        case .nutritionalGoals: 0.75
        }
    }

    var next: Self? { Self(rawValue: rawValue + 1) }
    var previous: Self? { Self(rawValue: rawValue - 1) }
}

#Preview("Meal setup", traits: .fixedLayout(width: 375, height: 812)) {
    MealSetupFlowView()
}
