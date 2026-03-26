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
                    .listRowBackground(Color.clear)
                    .glassEffect(.regular.interactive())

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
                if habit.isCountBased {
                    countIcon
                } else {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCompleted ? .green : .secondary)
                        .font(.title2)
                }
                VStack(alignment: .leading) {
                    Text(habit.name)
                        .strikethrough(isCompleted)
                    if habit.isCountBased {
                        let current = habit.goalPeriod == .weekly ? habit.countThisWeek() : habit.countOn(Date())
                        Text("\(current)/\(habit.goalTarget) \(habit.goalPeriod.rawValue.lowercased())")
                            .font(.caption)
                            .foregroundStyle(isCompleted ? .green : .secondary)
                    }
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

    @ViewBuilder
    private var countIcon: some View {
        let current = habit.goalPeriod == .weekly ? habit.countThisWeek() : habit.countOn(Date())
        ZStack {
            Circle()
                .trim(from: 0, to: min(1, Double(current) / Double(max(1, habit.goalTarget))))
                .stroke(isCompleted ? Color.green : Color.blue, lineWidth: 3)
                .rotationEffect(.degrees(-90))
                .frame(width: 32, height: 32)
            Text("\(current)")
                .font(.caption2).bold()
        }
        .glassEffect(.regular)
    }

    private func toggle() {
        if habit.isCountBased {
            // Always add — no toggle off for count-based
            context.insert(HabitCompletion(habit: habit))
        } else {
            let cal = Calendar.current
            if let existing = habit.completions.first(where: { cal.isDate($0.date, inSameDayAs: Date()) }) {
                context.delete(existing)
            } else {
                context.insert(HabitCompletion(habit: habit))
            }
        }
    }
}
