import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var selectedDate = Date()
    @State private var showingForm = false

    private let cal = Calendar.current

    private var weekDates: [Date] {
        let weekday = cal.component(.weekday, from: selectedDate)
        let start = cal.date(byAdding: .day, value: -(weekday - cal.firstWeekday), to: selectedDate)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func progress(for date: Date) -> (done: Int, total: Int) {
        let due = habits.filter { $0.isDueOn(date) }
        let done = due.filter { $0.isCompletedOn(date) }.count
        return (done, due.count)
    }

    var body: some View {
        NavigationStack {
                List {
                    Section {
                        HStack(spacing: 0) {
                            ForEach(weekDates, id: \.self) { date in
                                let p = progress(for: date)
                                let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
                                let isToday = cal.isDateInToday(date)

                                Button {
                                    selectedDate = date
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(date.formatted(.dateTime.weekday(.short)))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        ZStack {
                                            Circle()
                                                .fill(isSelected ? Color.accentColor : .clear)
                                                .frame(width: 32, height: 32)
                                            Text(date.formatted(.dateTime.day()))
                                                .font(.caption.bold())
                                                .foregroundStyle(isSelected ? .white : isToday ? .accentColor : .primary)
                                        }
                                        // Progress ring
                                        ZStack {
                                            Circle()
                                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 3)
                                            Circle()
                                                .trim(from: 0, to: p.total > 0 ? Double(p.done) / Double(p.total) : 0)
                                                .stroke(Color.accentColor, lineWidth: 3)
                                                .rotationEffect(.degrees(-90))
                                            if p.done == p.total && p.total > 0 {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(Color.accentColor)
                                            }
                                        }
                                        .frame(width: 20, height: 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if habits.isEmpty {
                        ContentUnavailableView("No habits yet", systemImage: "plus.circle", description: Text("Tap + to create your first habit"))
                    } else {
                        let dueToday = habits.filter { $0.isDueOn(selectedDate) }
                        let notDue = habits.filter { !$0.isDueOn(selectedDate) }

                        if !dueToday.isEmpty {
                            Section {
                                ForEach(dueToday) { habit in
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        HabitRow(habit: habit, date: selectedDate)
                                    }
                                }
                                .onDelete { offsets in delete(from: dueToday, at: offsets) }
                            }
                        }

                        if !notDue.isEmpty {
                            Section("Not scheduled") {
                                ForEach(notDue) { habit in
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        HStack {
                                            Image(systemName: "minus.circle")
                                                .foregroundStyle(.quaternary)
                                                .font(.title2)
                                            VStack(alignment: .leading) {
                                                Text(habit.name)
                                                Text(habit.frequency.rawValue)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .onDelete { offsets in delete(from: notDue, at: offsets) }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            .navigationTitle("Habits")
            .toolbar {
                Button { showingForm = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingForm) {
                HabitFormView()
            }
            .onAppear { syncAutoManagedHabits() }
        }
    }

    private func delete(from source: [Habit], at offsets: IndexSet) {
        for i in offsets {
            let habit = source[i]
            NotificationManager.shared.removeNotification(for: habit)
            context.delete(habit)
        }
    }

    private func syncAutoManagedHabits() {
        let autoHabits = habits.filter { $0.isAutoManaged && $0.linkedAppLimitId != nil }
        for habit in autoHabits {
            guard let idStr = habit.linkedAppLimitId, let id = UUID(uuidString: idStr) else { continue }
            let bypassed = SharedStore.shared.bypassedToday(for: id)
            let alreadyCompleted = habit.isCompletedOn(Date())

            if !bypassed && !alreadyCompleted {
                context.insert(HabitCompletion(habit: habit))
            } else if bypassed && alreadyCompleted {
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
    let date: Date
    private var isCompleted: Bool { habit.isCompletedOn(date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(habit.name)
                    .strikethrough(isCompleted)
                if habit.isCountBased {
                    let current = habit.goalPeriod == .weekly ? habit.countThisWeek(from: date) : habit.countOn(date)
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
            Spacer()
            if habit.isCountBased {
                countIcon
            } else {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .green : .secondary)
                    .font(.title2)
                    .onTapGesture { if isToday && !habit.isAutoManaged { toggle() } }
            }
        }
        .sensoryFeedback(.impact, trigger: isCompleted)
    }

    @ViewBuilder
    private var countIcon: some View {
        let current = habit.goalPeriod == .weekly ? habit.countThisWeek(from: date) : habit.countOn(date)
        ZStack {
            Circle()
                .trim(from: 0, to: min(1, Double(current) / Double(max(1, habit.goalTarget))))
                .stroke(isCompleted ? Color.green : Color.blue, lineWidth: 3)
                .rotationEffect(.degrees(-90))
                .frame(width: 32, height: 32)
            Text("\(current)")
                .font(.caption2).bold()
        }
        .onTapGesture { if isToday && !habit.isAutoManaged { toggle() } }
    }

    private func toggle() {
        if habit.isCountBased {
            context.insert(HabitCompletion(date: date, habit: habit))
        } else {
            let cal = Calendar.current
            if let existing = habit.completions.first(where: { cal.isDate($0.date, inSameDayAs: date) }) {
                context.delete(existing)
            } else {
                context.insert(HabitCompletion(date: date, habit: habit))
            }
        }
    }
}
