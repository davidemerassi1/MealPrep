import SwiftUI

struct ShoppingListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var checkedProductIDs: Set<String> = []
    let plan: WeeklyMealPlan

    private var categories: [String] {
        Array(Dictionary(grouping: plan.shoppingList, by: \.category).keys)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func items(in category: String) -> [ShoppingListItem] {
        plan.shoppingList
            .filter { $0.category == category }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var remainingItems: [ShoppingListItem] {
        plan.shoppingList.filter { !checkedProductIDs.contains($0.productId) }
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)
            let topSafeArea = proxy.safeAreaInsets.top

            ZStack(alignment: .top) {
                Color.white
                    .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        header(scale: scale)
                            .padding(.top, topSafeArea + 20 * scale)
                            .padding(.horizontal, 20 * scale)

                        remainingSummary(scale: scale)
                            .padding(.top, 22 * scale)
                            .padding(.horizontal, 22 * scale)
                            .padding(.bottom, 20 * scale)
                    }
                    .background(
                        Color.mealPrepGreen,
                        in: UnevenRoundedRectangle(
                            bottomLeadingRadius: 28 * scale,
                            bottomTrailingRadius: 28 * scale,
                            style: .continuous
                        )
                    )

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(categories, id: \.self) { category in
                                Text(category.uppercased())
                                    .font(.custom("Promo-SemiBold", size: 12 * scale))
                                    .foregroundStyle(Color.mealPrepSecondaryText)
                                    .tracking(0.7 * scale)
                                    .padding(.top, 22 * scale)
                                    .padding(.bottom, 6 * scale)

                                ForEach(items(in: category), id: \.productId) { item in
                                    ShoppingListRow(
                                        item: item,
                                        isChecked: checkedProductIDs.contains(item.productId),
                                        scale: scale,
                                        onToggle: { toggle(item) }
                                    )
                                    Divider()
                                        .padding(.leading, 42 * scale)
                                }
                            }
                        }
                        .padding(.horizontal, 22 * scale)
                        .padding(.bottom, 24 * scale)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }

    private func header(scale: CGFloat) -> some View {
        ZStack {
            Text("Shopping list")
                .font(.custom("Promo-Bold", size: 30 * scale))
                .foregroundStyle(.white)

            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16 * scale, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 42 * scale, height: 42 * scale)
                        .background(.white, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to meal plan")
                Spacer()
            }
        }
    }

    private func remainingSummary(scale: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(remainingItems.count) remaining")
                .font(.custom("Promo-Medium", size: 16 * scale))
                .foregroundStyle(.white.opacity(0.85))
                .contentTransition(.numericText(value: Double(remainingItems.count)))
                .animation(.easeInOut(duration: 0.2), value: remainingItems.count)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 3 * scale) {
                Text("€\(plan.weeklyTotalPrice, format: .number.precision(.fractionLength(2)))")
                    .font(.custom("Promo-Medium", size: 24 * scale))
                    .foregroundStyle(.white)
                Text("total")
                    .font(.custom("Promo-Regular", size: 12 * scale))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private func toggle(_ item: ShoppingListItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if checkedProductIDs.contains(item.productId) {
                checkedProductIDs.remove(item.productId)
            } else {
                checkedProductIDs.insert(item.productId)
            }
        }
    }
}

private struct ShoppingListRow: View {
    let item: ShoppingListItem
    let isChecked: Bool
    let scale: CGFloat
    let onToggle: () -> Void

    private var packageLabel: String {
        "\(item.packages) \(item.packages == 1 ? "package" : "packages")"
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12 * scale) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24 * scale, weight: .regular))
                    .foregroundStyle(isChecked ? Color.mealPrepGreen : Color.mealPrepSecondaryText)
                    .contentTransition(.symbolEffect(.replace))

                HStack(spacing: 8 * scale) {
                    VStack(alignment: .leading, spacing: 3 * scale) {
                        Text(item.brand.uppercased())
                            .font(.custom("Promo-Regular", size: 10 * scale))
                            .foregroundStyle(Color.mealPrepSecondaryText)
                            .lineLimit(1)

                        Text(item.name)
                            .font(.custom("Promo-SemiBold", size: 15 * scale))
                            .foregroundStyle(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("\(packageLabel) · €\(item.packagePrice, format: .number.precision(.fractionLength(2))) each")
                            .font(.custom("Promo-Regular", size: 12 * scale))
                            .foregroundStyle(Color.mealPrepSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8 * scale)

                    Text("€\(item.totalPrice, format: .number.precision(.fractionLength(2)))")
                        .font(.custom("Promo-Medium", size: 15 * scale))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                }
                .opacity(isChecked ? 0.45 : 1)
                .strikethrough(isChecked, color: .black)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12 * scale)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.name), \(packageLabel)")
        .accessibilityValue(isChecked ? "Purchased" : "Remaining")
    }
}
