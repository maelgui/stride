import SwiftUI
import SwiftData
import FamilyControls

struct ScreenTimeLimitsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var manager = ScreenTimeManager.shared
    @State private var showingPicker = false
    @State private var limits: [AppLimitConfig] = SharedStore.shared.appLimits
    @State private var blackout = SharedStore.shared.blackoutConfig

    var body: some View {
        Form {
            if !manager.isAuthorized {
                Section {
                    Button("Enable Screen Time Access") {
                        Task { await manager.requestAuthorization() }
                    }
                    if let error = manager.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Text("Requires a physical device — Screen Time API is unavailable in the Simulator.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("App Limits") {
                    ForEach($limits) { $limit in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(limit.displayName).font(.headline)
                                Text("\(limit.limitMinutes) min/day")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Stepper("", value: $limit.limitMinutes, in: 5...480, step: 5)
                                .labelsHidden()
                            Toggle("", isOn: $limit.isActive)
                                .labelsHidden()
                        }
                    }
                    .onDelete(perform: deleteLimit)

                    Button("Add App Limit") { showingPicker = true }
                        .familyActivityPicker(isPresented: $showingPicker, selection: $manager.selection)
                }

                Section("Blackout Window") {
                    Toggle("Enable Blackout", isOn: $blackout.isEnabled)
                    if blackout.isEnabled {
                        DatePicker("Block after", selection: blackoutStartBinding, displayedComponents: .hourAndMinute)
                        DatePicker("Unblock at", selection: blackoutEndBinding, displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    Button("Apply Changes") { save() }
                        .bold()
                }
            }
        }
        .navigationTitle("Screen Time")
        .onChange(of: manager.selection) { _, newValue in
            addSelectedApps(from: newValue)
        }
        .task { await manager.requestAuthorization() }
        .onAppear { manager.checkAuthorization() }
    }

    private var blackoutStartBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.date(from: DateComponents(hour: blackout.startHour, minute: blackout.startMinute)) ?? Date() },
            set: { date in
                blackout.startHour = Calendar.current.component(.hour, from: date)
                blackout.startMinute = Calendar.current.component(.minute, from: date)
            }
        )
    }

    private var blackoutEndBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.date(from: DateComponents(hour: blackout.endHour, minute: blackout.endMinute)) ?? Date() },
            set: { date in
                blackout.endHour = Calendar.current.component(.hour, from: date)
                blackout.endMinute = Calendar.current.component(.minute, from: date)
            }
        )
    }

    private func addSelectedApps(from selection: FamilyActivitySelection) {
        for token in selection.applicationTokens {
            guard let data = try? JSONEncoder().encode(token) else { continue }
            let alreadyExists = limits.contains { $0.tokenData == data }
            if !alreadyExists {
                limits.append(AppLimitConfig(displayName: "App", limitMinutes: 30, tokenData: data))
            }
        }
    }

    private func deleteLimit(at offsets: IndexSet) {
        let idsToRemove = offsets.map { limits[$0].id }
        limits.remove(atOffsets: offsets)
        // Remove linked habits
        for id in idsToRemove {
            let idStr = id.uuidString
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.linkedAppLimitId == idStr })
            if let habits = try? context.fetch(descriptor) {
                habits.forEach { context.delete($0) }
            }
        }
    }

    private func save() {
        SharedStore.shared.appLimits = limits
        SharedStore.shared.blackoutConfig = blackout

        // Sync habits: create/update linked habits for each limit
        for limit in limits where limit.isActive {
            let idStr = limit.id.uuidString
            let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.linkedAppLimitId == idStr })
            let existing = try? context.fetch(descriptor)
            if existing?.isEmpty ?? true {
                let habit = Habit(
                    name: "📱 \(limit.displayName) < \(limit.limitMinutes)min",
                    desc: "Auto-tracked: stay within your screen time limit",
                    isAutoManaged: true,
                    linkedAppLimitId: idStr
                )
                context.insert(habit)
            }
        }

        manager.applyLimits()
    }
}
