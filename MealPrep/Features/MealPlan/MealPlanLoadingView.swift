import SwiftUI

struct MealPlanLoadingView: View {
    let scale: CGFloat
    let isCompleting: Bool
    let onCompletionFinished: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbitRotation: Double = 0
    @State private var highLightedFoodIndex: Int?
    @State private var messageIndex = 0
    @State private var foodsVisible = true
    @State private var bagScale: CGFloat = 1
    @State private var showsReadyMessage = false

    private let messages = [
        "Creating a plan that fits your budget",
        "Adapting every meal to your preferences",
        "Balancing variety across the whole week",
        "Calculating quantities and package costs",
        "Organizing your breakfasts, lunches, and dinners"
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            Spacer()

            VStack(spacing: 60 * scale) {
                MealPrepHero(
                    bagScale: bagScale,
                    foodsVisible: foodsVisible,
                    orbitRotation: orbitRotation,
                    highlightedFoodIndex: highLightedFoodIndex
                )
                .frame(width: 246 * scale, height: 290 * scale)
                .scaleEffect(scale)

                ZStack {
                    if showsReadyMessage {
                        Text("Your meal plan is ready!")
                            .font(.custom("Promo-Bold", size: 27 * scale))
                            .foregroundStyle(.black)
                            .transition(.scale(scale: 0.88).combined(with: .opacity))
                    } else {
                        VStack {
                            Text("Preparing your plan")
                                .font(.custom("Promo-Bold", size: 25 * scale))
                                .foregroundStyle(.black)
                                .frame(height: 34 * scale)

                            ZStack {
                                Text(messages[messageIndex])
                                    .font(.custom("Promo-Medium", size: 15 * scale))
                                    .foregroundStyle(Color.mealPrepSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 38 * scale)
                                    .id(messageIndex)
                                    .transition(messageTransition)
                            }
                            .frame(height: 30 * scale)
                            .clipped()
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: 64 * scale)
                .animation(.easeInOut(duration: 0.35), value: showsReadyMessage)
            }

            Spacer()
        }
        .onAppear {
            guard !reduceMotion else { return }
            orbitRotation = 0
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                orbitRotation = 360
            }
        }
        .task(id: isCompleting) {
            guard !reduceMotion, !isCompleting else { return }
            let appearanceOrder = [0, 3, 1, 5, 2, 6, 4]
            try? await Task.sleep(for: .seconds(1.0))
            while !Task.isCancelled {
                for index in appearanceOrder {
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        highLightedFoodIndex = index
                    }
                    try? await Task.sleep(for: .seconds(1.7))
                    withAnimation(.easeInOut(duration: 0.4)) {
                        highLightedFoodIndex = nil
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        .task(id: isCompleting) {
            guard !isCompleting else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5.0))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
        .task(id: isCompleting) {
            guard isCompleting else { return }
            highLightedFoodIndex = nil

            withAnimation(.easeInOut(duration: 0.7)) {
                foodsVisible = false
            }
            
            try? await Task.sleep(for: .milliseconds(500))

            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.8, dampingFraction: 0.72)) {
                bagScale = 1.28
                showsReadyMessage = true
            }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            onCompletionFinished()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preparing your meal plan")
    }

    private var messageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .offset(y: 18 * scale).combined(with: .opacity),
            removal: .offset(y: -18 * scale).combined(with: .opacity)
        )
    }
}
