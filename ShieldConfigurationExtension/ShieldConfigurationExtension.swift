import ManagedSettings

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            title: ShieldConfiguration.Label(text: "Time's Up!", color: .white),
            subtitle: ShieldConfiguration.Label(text: application.localizedDisplayName.map { "You've reached your limit for \($0)" } ?? "You've reached your limit", color: .white),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .white),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Ignore Limit", color: .systemRed)
        )
    }
}
