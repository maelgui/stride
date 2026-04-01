import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query private var habits: [Habit]
    @State private var displayedMonth = Date()

    private let cal = Calendar.current

    private var monthDates: [Date?] {
        let range = cal.range(of: .day, in: .month, for: displayedMonth)!
        let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (firstWeekday - cal.firstWeekday + 7) % 7

        var dates: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            dates.append(cal.date(byAdding: .day, value: day - 1, to: firstOfMonth))
        }
        return dates
    }

    private func completionRate(for date: Date) -> Double {
        let due = habits.filter { $0.isDueOn(date) }
        guard !due.isEmpty else { return -1 } // no habits due
        let done = due.filter { $0.isCompletedOn(date) }.count
        return Double(done) / Double(due.count)
    }

    private let dayHeaders = Calendar.current.shortWeekdaySymbols

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                    Spacer()
                    Button { shiftMonth(1) } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Day headers
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(dayHeaders, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                        if let date {
                            let rate = completionRate(for: date)
                            let isFuture = date > Date()
                            VStack(spacing: 4) {
                                Text(date.formatted(.dateTime.day()))
                                    .font(.caption)
                                    .foregroundStyle(cal.isDateInToday(date) ? .accentColor : isFuture ? .secondary : .primary)
                                Circle()
                                    .fill(colorForRate(rate, isFuture: isFuture))
                                    .frame(width: 8, height: 8)
                            }
                            .frame(height: 40)
                        } else {
                            Color.clear.frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)

                // Legend
                HStack(spacing: 16) {
                    legendDot(color: .green, label: "All done")
                    legendDot(color: .orange, label: "Partial")
                    legendDot(color: .red, label: "None")
                    legendDot(color: .secondary.opacity(0.2), label: "No habits")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                // Summary
                List {
                    ForEach(habits) { habit in
                        HStack {
                            Text(habit.name)
                            Spacer()
                            Text("\(habit.currentStreak)d streak")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("\(habit.completions.count) total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Stats")
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = d
        }
    }

    private func colorForRate(_ rate: Double, isFuture: Bool) -> Color {
        if isFuture || rate < 0 { return .secondary.opacity(0.2) }
        if rate >= 1 { return .green }
        if rate > 0 { return .orange }
        return .red
    }

    @ViewBuilder
    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}
