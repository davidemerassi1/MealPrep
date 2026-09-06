import SwiftUI

struct WeeklyMealPlanView: View {
    let plan: WeeklyMealPlan
    @State private var selectedDay: Int? = 0

    var body: some View {
        GeometryReader { proxy in
            let scale = MealPrepTheme.scale(for: proxy.size.width)
            let cardHorizontalInset = 27 * scale

            ZStack {
                Color.mealPrepGreen.ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Bon appetit!")
                        .font(.custom("Promo-Bold", size: 32 * scale))
                        .foregroundStyle(.white)
                        .padding(.top, 24 * scale)

                    WeeklyCostCard(total: plan.weeklyTotalPrice, scale: scale)
                        .padding(.top, 15 * scale)
                        .padding(.horizontal, 20 * scale)

                    DaySelector(
                        days: plan.days.map(\.day),
                        selectedDay: $selectedDay,
                        scale: scale
                    )
                    .padding(.top, 12 * scale)
                    .padding(.horizontal, 20 * scale)

                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 12 * scale) {
                            ForEach(Array(plan.days.enumerated()), id: \.offset) { index, day in
                                DayPlanCard(day: day, scale: scale)
                                    .frame(width: proxy.size.width - 54 * scale)
                                    .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.horizontal, cardHorizontalInset, for: .scrollContent)
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollPosition(id: $selectedDay)
                    .scrollIndicators(.hidden)
                    .padding(.top, 16 * scale)
                    .padding(.bottom, 14 * scale)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

private struct WeeklyCostCard: View {
    let total: Double
    let scale: CGFloat

    var body: some View {
        VStack(spacing: 7 * scale) {
            Text("Est. cost")
                .font(.custom("Promo-Medium", size: 15 * scale))
                .foregroundStyle(Color.mealPrepSecondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 3 * scale) {
                Text("€\(total, format: .number.precision(.fractionLength(2)))")
                    .font(.custom("Promo-Medium", size: 22 * scale))
                Text("/ week")
                    .font(.custom("Promo-Medium", size: 15 * scale))
            }
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity, minHeight: 66 * scale)
        .background(.white, in: RoundedRectangle(cornerRadius: 14 * scale, style: .continuous))
    }
}

private struct DaySelector: View {
    let days: [String]
    @Binding var selectedDay: Int?
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 5 * scale) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { selectedDay = index }
                } label: {
                    Text(String(day.prefix(3)))
                        .font(.custom("Promo-SemiBold", size: 12 * scale))
                        .foregroundStyle(selectedDay == index ? .white : .black)
                        .frame(maxWidth: .infinity, minHeight: 34 * scale)
                        .background(
                            selectedDay == index ? Color.black : Color.white,
                            in: RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day)
                .accessibilityAddTraits(selectedDay == index ? .isSelected : [])
            }
        }
    }
}

private struct DayPlanCard: View {
    let day: MealPlanDay
    let scale: CGFloat

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18 * scale) {
                Text(day.day)
                    .font(.custom("Promo-Bold", size: 25 * scale))
                    .frame(maxWidth: .infinity, alignment: .center)

                ForEach(Array(day.meals.enumerated()), id: \.offset) { index, meal in
                    if index > 0 && day.meals[index - 1].mealType != meal.mealType {
                        Divider().padding(.vertical, 4 * scale)
                    } else if index > 0 {
                        Color.clear.frame(height: 7 * scale)
                    }
                    if index == 0 || day.meals[index - 1].mealType != meal.mealType {
                        Text(meal.mealType)
                            .font(.custom("Promo-Bold", size: 22 * scale))
                            .foregroundStyle(Color.mealPrepGreen)
                    }
                    MealDetails(meal: meal, scale: scale)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22 * scale)
            .padding(.top, 22 * scale)
            .padding(.bottom, 40 * scale)
        }
        .scrollIndicators(.hidden)
        .background(
            .white,
            in: RoundedRectangle(cornerRadius: 28 * scale, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28 * scale, style: .continuous))
    }
}

private struct MealDetails: View {
    let meal: PlannedMeal
    let scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 13 * scale) {
            Text(meal.course.uppercased())
                .font(.custom("Promo-SemiBold", size: 10 * scale))
                .foregroundStyle(Color.mealPrepSecondaryText)

            Text(meal.name)
                .font(.custom("Promo-SemiBold", size: 17 * scale))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10 * scale) {
                MetadataLabel(icon: "clock", text: "\(meal.preparationMinutes) min", scale: scale)
                MetadataLabel(
                    icon: "person",
                    text: "\(meal.servings) \(meal.servings == 1 ? "serving" : "servings")",
                    scale: scale
                )
                MetadataLabel(
                    icon: "banknote",
                    text: "€\(meal.price.formatted(.number.precision(.fractionLength(2))))\(meal.servings > 1 ? " / serving" : "")",
                    scale: scale
                )
            }

            Text("Ingredients")
                .font(.custom("Promo-SemiBold", size: 14 * scale))
                .padding(.top, 2 * scale)

            VStack(alignment: .leading, spacing: 7 * scale) {
                ForEach(Array(meal.ingredients.enumerated()), id: \.offset) { _, ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: 7 * scale) {
                        Circle()
                            .fill(Color.mealPrepGreen)
                            .frame(width: 5 * scale, height: 5 * scale)
                        Text("\(ingredient.amount, format: .number) \(ingredient.unit) · \(ingredient.name)")
                            .font(.custom("Promo-Normal", size: 13 * scale))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Text("Recipe")
                .font(.custom("Promo-SemiBold", size: 14 * scale))
                .padding(.top, 5 * scale)

            VStack(alignment: .leading, spacing: 9 * scale) {
                ForEach(Array(meal.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .center, spacing: 9 * scale) {
                        Text("\(index + 1)")
                            .font(.custom("Promo-SemiBold", size: 11 * scale))
                            .foregroundStyle(.white)
                            .frame(width: 21 * scale, height: 21 * scale)
                            .background(Color.mealPrepGreen, in: Circle())
                        Text(step)
                            .font(.custom("Promo-Normal", size: 13 * scale))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

private struct MetadataLabel: View {
    let icon: String
    let text: String
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 5 * scale) {
            Image(systemName: icon)
                .font(.system(size: 14 * scale, weight: .regular))
                .frame(width: 15 * scale, height: 15 * scale)
            Text(text)
                .font(.custom("Promo-Normal", size: 11 * scale))
        }
            .foregroundStyle(Color.mealPrepSecondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }
}
