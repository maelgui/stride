@preconcurrency import DeviceActivity
import ManagedSettings

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    // Called when a per-app usage threshold is hit
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        let limits = SharedStore.shared.appLimits
        guard let limit = limits.first(where: { $0.id.uuidString == event.rawValue }),
              let token = try? JSONDecoder().decode(ApplicationToken.self, from: limit.tokenData) else { return }

        // Shield the app
        store.shield.applications = (store.shield.applications ?? []).union([token])
    }

    // Called when blackout window starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        guard activity == .blackout else { return }
        let limits = SharedStore.shared.appLimits
        var tokens = Set<ApplicationToken>()
        for limit in limits {
            if let token = try? JSONDecoder().decode(ApplicationToken.self, from: limit.tokenData) {
                tokens.insert(token)
            }
        }
        store.shield.applications = tokens
    }

    // Called when blackout window ends or daily schedule resets
    override func intervalDidEnd(for activity: DeviceActivityName) {
        if activity == .blackout {
            // Only remove shields if no per-app limit is exceeded
            store.shield.applications = nil
        } else {
            // Daily reset — clear shield for this specific app
            store.shield.applications = nil
        }
    }
}

extension DeviceActivityName {
    static let blackout = Self("blackout")
}
