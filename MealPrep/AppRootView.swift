import SwiftUI

struct AppRootView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LanderView {
                path.append(.budget)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .budget:
                    BudgetSelectionView()
                }
            }
        }
        .tint(.black)
        .preferredColorScheme(.light)
    }
}

private enum AppRoute: Hashable {
    case budget
}

#Preview("MealPrep flow", traits: .fixedLayout(width: 375, height: 812)) {
    AppRootView()
}
