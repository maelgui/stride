import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var habits: [Habit]

    private var todayHabits: [Habit] {
        habits.filter { $0.isDueOn(Date()) }
    }

    private var completedCount: Int {
        todayHabits.filter { $0.isCompletedOn(Date()) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                if todayHabits.isEmpty {
                    ContentUnavailableView("No habits today", systemImage: "moon.zzz", description: Text("Add habits in the Habits tab"))
                } else {
                    Section {
                        ProgressView(value: Double(completedCount), total: Double(todayHabits.count))
                            .tint(completedCount == todayHabits.count ? .green : .blue)
                        Text("\(completedCount)/\(todayHabits.count) completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        ForEach(todayHabits) { habit in
                            HabitRow(habit: habit)
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .onAppear { syncAutoManagedHabits() }
        }
    }

    private func syncAutoManagedHabits() {
        let autoHabits = habits.filter { $0.isAutoManaged && $0.linkedAppLimitId != nil }
        let cal = Calendar.current
        for habit in autoHabits {
            guard let idStr = habit.linkedAppLimitId, let id = UUID(uuidString: idStr) else { continue }
            let bypassed = SharedStore.shared.bypassedToday(for: id)
            let alreadyCompleted = habit.isCompletedOn(Date())

            if !bypassed && !alreadyCompleted {
                // Auto-complete: no bypass today
                let completion = HabitCompletion(habit: habit)
                context.insert(completion)
            } else if bypassed && alreadyCompleted {
                // Remove auto-completion if bypassed
                if let existing = habit.completions.first(where: { cal.isDateInToday($0.date) }) {
                    context.delete(existing)
                }
            }
        }
    }
}

private struct HabitRow: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    private var isCompleted: Bool { habit.isCompletedOn(Date()) }

    var body: some View {
        Button {
            if !habit.isAutoManaged { toggle() }
        } label: {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .green : .secondary)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(habit.name)
                        .strikethrough(isCompleted)
                    if habit.currentStreak > 0 {
                        Text("\(habit.currentStreak) day streak 🔥")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if habit.isAutoManaged {
                        Text("Auto-tracked")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .foregroundStyle(isCompleted ? .secondary : .primary)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: isCompleted)
    }

    private func toggle() {
        let cal = Calendar.current
        if let existing = habit.completions.first(where: { cal.isDate($0.date, inSameDayAs: Date()) }) {
            context.delete(existing)
        } else {
            context.insert(HabitCompletion(habit: habit))
        }
    }
}
