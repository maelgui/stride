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
                    Label("Habits", systemImage: "checkmark.circle")
                }
            WeeklyView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
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
