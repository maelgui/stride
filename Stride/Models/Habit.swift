import Foundation
import SwiftData

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case custom = "Custom"
}

@Model
final class Habit {
    var name: String
    var desc: String
    var frequency: HabitFrequency
    var customDays: [Int] // 1=Sun, 2=Mon, ..., 7=Sat
    var reminderEnabled: Bool
    var reminderTime: Date
    var createdAt: Date
    var isAutoManaged: Bool // screen time habits
    var linkedAppLimitId: String? // UUID string of AppLimitConfig
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]

    init(name: String, desc: String = "", frequency: HabitFrequency = .daily, customDays: [Int] = [], reminderEnabled: Bool = false, reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9))!, isAutoManaged: Bool = false, linkedAppLimitId: String? = nil) {
        self.name = name
        self.desc = desc
        self.frequency = frequency
        self.customDays = customDays
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.createdAt = Date()
        self.completions = []
        self.isAutoManaged = isAutoManaged
        self.linkedAppLimitId = linkedAppLimitId
    }

    var scheduledDays: Set<Int> {
        switch frequency {
        case .daily: return Set(1...7)
        case .weekdays: return Set(2...6)
        case .weekends: return [1, 7]
        case .custom: return Set(customDays)
        }
    }

    func isDueOn(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return scheduledDays.contains(weekday)
    }

    func isCompletedOn(_ date: Date) -> Bool {
        let cal = Calendar.current
        return completions.contains { cal.isDate($0.date, inSameDayAs: date) }
    }

    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var date = Date()
        // If not completed today yet, start from yesterday
        if isDueOn(date) && !isCompletedOn(date) {
            date = cal.date(byAdding: .day, value: -1, to: date)!
        }
        while true {
            if isDueOn(date) {
                if isCompletedOn(date) {
                    streak += 1
                } else {
                    break
                }
            }
            date = cal.date(byAdding: .day, value: -1, to: date)!
            if cal.dateComponents([.day], from: createdAt, to: date).day! < -1 { break }
        }
        return streak
    }
}

@Model
final class HabitCompletion {
    var date: Date
    var habit: Habit?

    init(date: Date = Date(), habit: Habit) {
        self.date = date
        self.habit = habit
    }
}
