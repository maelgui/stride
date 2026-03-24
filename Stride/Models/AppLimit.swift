import Foundation
import ManagedSettings

struct AppLimitConfig: Codable, Identifiable {
    var id: UUID
    var displayName: String
    var limitMinutes: Int
    var tokenData: Data // encoded ApplicationToken
    var isActive: Bool

    init(displayName: String, limitMinutes: Int, tokenData: Data, isActive: Bool = true) {
        self.id = UUID()
        self.displayName = displayName
        self.limitMinutes = limitMinutes
        self.tokenData = tokenData
        self.isActive = isActive
    }
}

struct BlackoutConfig: Codable {
    var isEnabled: Bool
    var startHour: Int // e.g. 23
    var startMinute: Int
    var endHour: Int   // e.g. 10
    var endMinute: Int

    static let `default` = BlackoutConfig(isEnabled: false, startHour: 23, startMinute: 0, endHour: 10, endMinute: 0)
}

struct BypassEvent: Codable, Identifiable {
    var id: UUID
    var date: Date
    var appLimitId: UUID

    init(date: Date = Date(), appLimitId: UUID) {
        self.id = UUID()
        self.date = date
        self.appLimitId = appLimitId
    }
}
