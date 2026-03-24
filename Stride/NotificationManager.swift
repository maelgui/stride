import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleNotifications(for habit: Habit, name: String, reminderEnabled: Bool, reminderTime: Date, scheduledDays: Set<Int>?, frequency: HabitFrequency) {
        removeNotification(for: habit)
        guard reminderEnabled else { return }

        let cal = Calendar.current
        let hour = cal.component(.hour, from: reminderTime)
        let minute = cal.component(.minute, from: reminderTime)

        let days: Set<Int>
        switch frequency {
        case .daily: days = Set(1...7)
        case .weekdays: days = Set(2...6)
        case .weekends: days = [1, 7]
        case .custom: days = scheduledDays ?? Set(1...7)
        }

        for day in days {
            var components = DateComponents()
            components.weekday = day
            components.hour = hour
            components.minute = minute

            let content = UNMutableNotificationContent()
            content.title = "Stride"
            content.body = "Time for: \(name)"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let id = "\(habit.persistentModelID.hashValue)-\(day)"
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    func removeNotification(for habit: Habit) {
        let prefix = "\(habit.persistentModelID.hashValue)-"
        let ids = (1...7).map { "\(prefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
