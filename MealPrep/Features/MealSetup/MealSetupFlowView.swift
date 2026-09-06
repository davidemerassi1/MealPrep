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
    @State private var isGenerating = false
    @State private var generatedPlan: WeeklyMealPlan?
    @State private var generationError: String?

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)

            ZStack {
                if isGenerating {
                    MealPlanLoadingView(scale: scale)
                        .transition(.opacity)
                } else if let generatedPlan {
                    WeeklyMealPlanView(plan: generatedPlan)
                        .transition(.opacity)
                } else if let generationError {
                    MealPlanErrorView(
                        message: generationError,
                        scale: scale,
                        onRetry: generateMealPlan,
                        onBack: { self.generationError = nil }
                    )
                    .transition(.opacity)
                } else {
                    setupContent(proxy: proxy, scale: scale)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isGenerating)
            .animation(.easeInOut(duration: 0.25), value: generatedPlan != nil)
            .animation(.easeInOut(duration: 0.25), value: generationError != nil)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func setupContent(proxy: GeometryProxy, scale: CGFloat) -> some View {
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
        guard !isTransitioning else { return }
        if let next = step.next {
            transition(to: next, forward: true)
        } else {
            generateMealPlan()
        }
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

    private func generateMealPlan() {
        guard !isGenerating else { return }
        isGenerating = true
        generationError = nil
        let configuration = MealPlanConfiguration(
            weeklyBudget: Int((budget / 5).rounded() * 5),
            dietaryNeeds: dietaryNeeds,
            nutritionalGoals: nutritionalGoals
        )

        print("[MealPrep] Generating weekly meal plan...")
        Task { @MainActor in
            do {
                let plan = try await MealPlanGenerator().generate(configuration: configuration)
                MealPlanLogger.log(plan)
                generatedPlan = plan
            } catch {
                MealPlanLogger.log(error: error)
                generationError = error.localizedDescription
            }
            isGenerating = false
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
