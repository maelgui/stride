import ManagedSettings

class ShieldActionExtension: ShieldActionDelegate {
    private let store = ManagedSettingsStore()

    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            // Log bypass
            let limits = SharedStore.shared.appLimits
            if let limit = limits.first(where: { limit in
                guard let token = try? JSONDecoder().decode(ApplicationToken.self, from: limit.tokenData) else { return false }
                return token == application.token
            }) {
                SharedStore.shared.logBypass(for: limit.id)
            }
            // Remove shield for this app
            if let token = application.token {
                var shielded = store.shield.applications ?? []
                shielded.remove(token)
                store.shield.applications = shielded.isEmpty ? nil : shielded
            }
            completionHandler(.defer)
        @unknown default:
            completionHandler(.close)
        }
    }
}
