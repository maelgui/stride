import Foundation
import FamilyControls
@preconcurrency import DeviceActivity
import ManagedSettings

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    private let center = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    private let store = ManagedSettingsStore()

    @Published var isAuthorized = false
    @Published var authError: String?
    @Published var selection = FamilyActivitySelection()

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
            authError = nil
        } catch {
            isAuthorized = false
            authError = error.localizedDescription
            print("Screen Time auth failed: \(error)")
        }
    }

    func checkAuthorization() {
        isAuthorized = center.authorizationStatus == .approved
    }

    // MARK: - Schedule Monitoring

    func applyLimits() {
        // Remove all existing schedules
        activityCenter.stopMonitoring()

        let limits = SharedStore.shared.appLimits.filter(\.isActive)
        guard !limits.isEmpty else { return }

        // Per-app daily limit schedules
        for limit in limits {
            guard let token = try? JSONDecoder().decode(ApplicationToken.self, from: limit.tokenData) else { continue }

            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )

            let eventName = DeviceActivityEvent.Name(limit.id.uuidString)
            let event = DeviceActivityEvent(
                applications: [token],
                threshold: DateComponents(minute: limit.limitMinutes)
            )

            let activityName = DeviceActivityName(limit.id.uuidString)
            try? activityCenter.startMonitoring(activityName, during: schedule, events: [eventName: event])
        }

        // Blackout window
        let blackout = SharedStore.shared.blackoutConfig
        if blackout.isEnabled {
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: blackout.startHour, minute: blackout.startMinute),
                intervalEnd: DateComponents(hour: blackout.endHour, minute: blackout.endMinute),
                repeats: true
            )
            try? activityCenter.startMonitoring(.blackout, during: schedule)
        }
    }

    func removeAllLimits() {
        activityCenter.stopMonitoring()
        store.clearAllSettings()
    }
}

extension DeviceActivityName {
    static let blackout = Self("blackout")
}
