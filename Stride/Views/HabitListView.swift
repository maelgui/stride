import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.createdAt, order: .reverse) private var habits: [Habit]
    @State private var showingForm = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                        VStack(alignment: .leading) {
                            Text(habit.name).font(.headline)
                            Text(habit.frequency.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)

                if habits.isEmpty {
                    ContentUnavailableView("No habits yet", systemImage: "plus.circle", description: Text("Tap + to create your first habit"))
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                Button { showingForm = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingForm) {
                HabitFormView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            let habit = habits[i]
            NotificationManager.shared.removeNotification(for: habit)
            context.delete(habit)
        }
    }
}
