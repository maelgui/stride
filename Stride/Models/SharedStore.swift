import Foundation

/// Shared storage between main app and extensions via App Group
final class SharedStore {
    static let shared = SharedStore()
    private let defaults: UserDefaults

    static let appGroup = "group.fr.maelgui.stride"

    private init() {
        defaults = UserDefaults(suiteName: SharedStore.appGroup) ?? .standard
    }

    // MARK: - App Limits

    var appLimits: [AppLimitConfig] {
        get { decode(forKey: "appLimits") ?? [] }
        set { encode(newValue, forKey: "appLimits") }
    }

    // MARK: - Blackout

    var blackoutConfig: BlackoutConfig {
        get { decode(forKey: "blackoutConfig") ?? .default }
        set { encode(newValue, forKey: "blackoutConfig") }
    }

    // MARK: - Bypass Events

    var bypassEvents: [BypassEvent] {
        get { decode(forKey: "bypassEvents") ?? [] }
        set { encode(newValue, forKey: "bypassEvents") }
    }

    func logBypass(for appLimitId: UUID) {
        var events = bypassEvents
        events.append(BypassEvent(appLimitId: appLimitId))
        bypassEvents = events
    }

    func bypassedToday(for appLimitId: UUID) -> Bool {
        let cal = Calendar.current
        return bypassEvents.contains {
            $0.appLimitId == appLimitId && cal.isDateInToday($0.date)
        }
    }

    func bypassesThisWeek() -> Int {
        let cal = Calendar.current
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return bypassEvents.filter { $0.date >= startOfWeek }.count
    }

    // MARK: - Helpers

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private func decode<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
