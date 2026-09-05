import SwiftUI

struct DietaryNeedsSelectionView: View {
    @Binding var selection: Set<DietaryNeed>

    var body: some View {
        PreferenceSelectionScreen(
            title: "Any dietary needs?",
            options: DietaryNeed.allCases.map {
                PreferenceOption(id: $0.rawValue, title: $0.title, icon: $0.icon)
            },
            selectedIDs: Set(selection.map(\.rawValue)),
            onSelect: toggle
        )
    }

    private func toggle(_ id: String) {
        guard let option = DietaryNeed(rawValue: id) else { return }
        withAnimation(.easeInOut(duration: 0.1)) {
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

#Preview("Dietary needs", traits: .fixedLayout(width: 375, height: 812)) {
    DietaryNeedsSelectionView(selection: .constant([]))
        .padding(20)
}
