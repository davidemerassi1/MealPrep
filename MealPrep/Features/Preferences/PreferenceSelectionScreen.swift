import SwiftUI

struct PreferenceOption: Identifiable {
    let id: String
    let title: String
    let icon: String?
}

struct PreferenceSelectionScreen: View {
    let title: String
    let options: [PreferenceOption]
    let selectedIDs: Set<String>
    let onSelect: (String) -> Void

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)

            ZStack(alignment: .topLeading) {
                Text(title)
                    .font(.custom("Promo-Bold", size: 30 * scale))
                    .foregroundStyle(.black)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 12 * scale),
                        count: 2
                    ),
                    spacing: 12 * scale
                ) {
                    ForEach(options) { option in
                        PreferenceCard(
                            title: option.title,
                            icon: option.icon,
                            isSelected: selectedIDs.contains(option.id),
                            scale: scale
                        ) {
                            onSelect(option.id)
                        }
                        .frame(height: 100 * scale)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, -2 * scale)
            }
        }
    }
}
