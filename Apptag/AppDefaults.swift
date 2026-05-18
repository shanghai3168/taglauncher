import Foundation

enum AppDefaults {
    static let schemaVersionKey = "initialDefaultsSchemaVersion"
    static let currentSchemaVersion = 1

    static let tagFontSize: Double = 22
    static let iconSize: Double = 80
    static let tagPosition = "right"
    static let displayMode = "coloredGridContainer"
    static let hideAppNames = true
    static let showDockIcon = true
    static let launchAtLogin = true
    static let showUncommonAppBubbles = false

    static func register() {
        UserDefaults.standard.register(defaults: [
            "tagFontSize": tagFontSize,
            "iconSize": iconSize,
            "tagPosition": tagPosition,
            "displayMode": displayMode,
            "hideAppNames": hideAppNames,
            "showDockIcon": showDockIcon,
            "launchAtLogin": launchAtLogin,
            "showUncommonAppBubbles": showUncommonAppBubbles
        ])
    }

    static func hasStoredValue(for key: String) -> Bool {
        let domain = Bundle.main.bundleIdentifier ?? "com.apptag.launcher"
        return UserDefaults.standard.persistentDomain(forName: domain)?[key] != nil
    }
}
