import SwiftUI

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    let habit: Habit
    @State private var showingEdit = false

    var body: some View {
        List {
            Section("About") {
                LabeledContent("Name", value: habit.name)
                if !habit.desc.isEmpty {
                    Text(habit.desc)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Frequency", value: habit.frequency.rawValue)
                LabeledContent("Created", value: habit.createdAt.formatted(date: .abbreviated, time: .omitted))
            }

            Section("Progress") {
                LabeledContent("Current Streak", value: "\(habit.currentStreak) days")
                LabeledContent("Total Completions", value: "\(habit.completions.count)")
                if habit.isCountBased {
                    LabeledContent("Goal", value: "\(habit.goalTarget)x \(habit.goalPeriod.rawValue.lowercased())")
                }
            }
            .listRowBackground(Color.clear)
            .glassEffect(.regular)

            Section("Reminder") {
                if habit.reminderEnabled {
                    LabeledContent("Time", value: habit.reminderTime.formatted(date: .omitted, time: .shortened))
                } else {
                    Text("No reminder set")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(habit.name)
        .toolbar {
            Button("Edit") { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) {
            HabitFormView(editingHabit: habit)
        }
    }
}
