import SwiftUI

struct HabitFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editingHabit: Habit?

    @State private var name = ""
    @State private var desc = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var customDays: Set<Int> = []
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9))!
    @State private var goalTarget = 0
    @State private var goalPeriod: GoalPeriod = .daily

    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Habit name", text: $name)
                    TextField("Description (optional)", text: $desc, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(HabitFrequency.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    if frequency == .custom {
                        HStack {
                            ForEach(0..<7) { i in
                                let day = i + 1
                                Button(dayNames[i]) {
                                    if customDays.contains(day) { customDays.remove(day) }
                                    else { customDays.insert(day) }
                                }
                                .buttonStyle(.bordered)
                                .tint(customDays.contains(day) ? .blue : .gray)
                                .font(.caption)
                            }
                        }
                    }
                }

                Section("Goal (optional)") {
                    Stepper("Target: \(goalTarget)x", value: $goalTarget, in: 0...100)
                    if goalTarget > 0 {
                        Picker("Period", selection: $goalPeriod) {
                            ForEach(GoalPeriod.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                    }
                }

                Section("Reminder") {
                    Toggle("Enable reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle(editingHabit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let h = editingHabit {
                    name = h.name
                    desc = h.desc
                    frequency = h.frequency
                    customDays = Set(h.customDays)
                    reminderEnabled = h.reminderEnabled
                    reminderTime = h.reminderTime
                    goalTarget = h.goalTarget
                    goalPeriod = h.goalPeriod
                }
            }
        }
    }

    private func save() {
        if let h = editingHabit {
            h.name = name.trimmingCharacters(in: .whitespaces)
            h.desc = desc
            h.frequency = frequency
            h.customDays = Array(customDays)
            h.reminderEnabled = reminderEnabled
            h.reminderTime = reminderTime
            h.goalTarget = goalTarget
            h.goalPeriod = goalPeriod
        } else {
            let habit = Habit(
                name: name.trimmingCharacters(in: .whitespaces),
                desc: desc,
                frequency: frequency,
                customDays: Array(customDays),
                reminderEnabled: reminderEnabled,
                reminderTime: reminderTime,
                goalTarget: goalTarget,
                goalPeriod: goalPeriod
            )
            context.insert(habit)
        }
        NotificationManager.shared.scheduleNotifications(for: editingHabit ?? Habit(name: name), name: name, reminderEnabled: reminderEnabled, reminderTime: reminderTime, scheduledDays: frequency == .custom ? customDays : nil, frequency: frequency)
        dismiss()
    }
}
