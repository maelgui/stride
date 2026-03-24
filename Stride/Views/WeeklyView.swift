import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query private var habits: [Habit]

    private var weekDates: [Date] {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let startOfWeek = cal.date(byAdding: .day, value: -(weekday - cal.firstWeekday), to: today)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private let dayNumFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    Section(habit.name) {
                        HStack {
                            ForEach(weekDates, id: \.self) { date in
                                VStack(spacing: 6) {
                                    Text(dayFormatter.string(from: date))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(dayNumFormatter.string(from: date))
                                        .font(.caption)
                                    if habit.isDueOn(date) {
                                        Image(systemName: habit.isCompletedOn(date) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(habit.isCompletedOn(date) ? .green : .secondary)
                                    } else {
                                        Image(systemName: "minus")
                                            .foregroundStyle(.quaternary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if habits.isEmpty {
                    ContentUnavailableView("No habits yet", systemImage: "calendar", description: Text("Add habits in the Habits tab"))
                }
            }
            .navigationTitle("This Week")
        }
    }
}
