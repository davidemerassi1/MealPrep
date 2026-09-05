import SwiftUI

struct NutritionalGoalsSelectionView: View {
    @Binding var selection: Set<NutritionalGoal>

    var body: some View {
        PreferenceSelectionScreen(
            title: "Any nutritional goals?",
            options: NutritionalGoal.allCases.map {
                PreferenceOption(id: $0.rawValue, title: $0.title, icon: $0.icon)
            },
            selectedIDs: Set(selection.map(\.rawValue)),
            onSelect: toggle
        )
    }

    private func toggle(_ id: String) {
        guard let option = NutritionalGoal(rawValue: id) else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            if option == .none {
                selection = selection == [.none] ? [] : [.none]
            } else {
                selection.remove(.none)
                if selection.contains(option) {
                    selection.remove(option)
                } else {
                    selection.insert(option)
                }
            }
        }
    }
}

#Preview("Nutritional goals", traits: .fixedLayout(width: 375, height: 812)) {
    NutritionalGoalsSelectionView(selection: .constant([]))
        .padding(20)
}
