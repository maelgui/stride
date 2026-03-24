import SwiftUI
import SwiftData

@main
struct StrideApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Habit.self, HabitCompletion.self])
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
                }
            WeeklyView()
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
            HabitListView()
                .tabItem {
                    Label("Habits", systemImage: "list.bullet")
                }
            NavigationStack {
                ScreenTimeLimitsView()
            }
            .tabItem {
                Label("Screen Time", systemImage: "hourglass")
            }
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}
