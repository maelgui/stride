import Foundation
import SwiftData

enum HabitFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case custom = "Custom"
}

enum GoalPeriod: String, Codable, CaseIterable {
    case daily = "Per Day"
    case weekly = "Per Week"
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
    var goalTarget: Int // 0 = simple checkbox habit, >0 = count-based
    var goalPeriod: GoalPeriod
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion]

    var isCountBased: Bool { goalTarget > 0 }

    init(name: String, desc: String = "", frequency: HabitFrequency = .daily, customDays: [Int] = [], reminderEnabled: Bool = false, reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9))!, isAutoManaged: Bool = false, linkedAppLimitId: String? = nil, goalTarget: Int = 0, goalPeriod: GoalPeriod = .daily) {
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
        self.goalTarget = goalTarget
        self.goalPeriod = goalPeriod
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
        if isCountBased {
            switch goalPeriod {
            case .daily:
                return countOn(date) >= goalTarget
            case .weekly:
                return countThisWeek(from: date) >= goalTarget
            }
        }
        let cal = Calendar.current
        return completions.contains { cal.isDate($0.date, inSameDayAs: date) }
    }

    func countOn(_ date: Date) -> Int {
        let cal = Calendar.current
        return completions.filter { cal.isDate($0.date, inSameDayAs: date) }.count
    }

    func countThisWeek(from date: Date = Date()) -> Int {
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfWeek)!
        return completions.filter { $0.date >= startOfWeek && $0.date < endOfWeek }.count
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
