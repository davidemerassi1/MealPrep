import SwiftUI

struct AppRootView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LanderView {
                push(.mealSetup)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .mealSetup:
                    MealSetupFlowView()
                }
            }
        }
        .tint(.black)
        .preferredColorScheme(.light)
    }

    private func push(_ route: AppRoute) {
        withAnimation(.easeInOut(duration: 0.34)) {
            path.append(route)
        }
    }
}

private enum AppRoute: Hashable {
    case mealSetup
}

#Preview("MealPrep flow", traits: .fixedLayout(width: 375, height: 812)) {
    AppRootView()
}
