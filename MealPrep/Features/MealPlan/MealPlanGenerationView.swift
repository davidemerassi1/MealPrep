import SwiftUI

struct MealPlanGenerationView: View {
    @Environment(\.dismiss) private var dismiss
    let configuration: MealPlanConfiguration

    @State private var isGenerating = true
    @State private var isCompleting = false
    @State private var pendingPlan: WeeklyMealPlan?
    @State private var generatedPlan: WeeklyMealPlan?
    @State private var generationError: String?

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)

            ZStack {
                if isGenerating {
                    MealPlanLoadingView(
                        scale: scale,
                        isCompleting: isCompleting,
                        onCompletionFinished: revealGeneratedPlan
                    )
                        .transition(.opacity)
                } else if let generatedPlan {
                    WeeklyMealPlanView(plan: generatedPlan)
                        .transition(.opacity)
                } else if let generationError {
                    MealPlanErrorView(
                        message: generationError,
                        scale: scale,
                        onRetry: retry,
                        onBack: { dismiss() }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isGenerating)
            .animation(.easeInOut(duration: 0.25), value: generatedPlan != nil)
            .animation(.easeInOut(duration: 0.25), value: generationError != nil)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await generateMealPlan() }
    }

    private func retry() {
        Task { await generateMealPlan() }
    }

    @MainActor
    private func generateMealPlan() async {
        isGenerating = true
        isCompleting = false
        pendingPlan = nil
        generationError = nil
        generatedPlan = nil
        print("[MealPrep] Generating weekly meal plan...")

        do {
            let plan = try await MealPlanGenerator().generate(configuration: configuration)
            guard !Task.isCancelled else { return }
            MealPlanLogger.log(plan)
            pendingPlan = plan
            withAnimation(.easeInOut(duration: 0.25)) {
                isCompleting = true
            }
        } catch {
            guard !Task.isCancelled else { return }
            MealPlanLogger.log(error: error)
            generationError = error.localizedDescription
            isGenerating = false
        }
    }

    private func revealGeneratedPlan() {
        guard let pendingPlan else { return }
        generatedPlan = pendingPlan
        withAnimation(.easeInOut(duration: 0.35)) {
            isGenerating = false
        }
    }
}
