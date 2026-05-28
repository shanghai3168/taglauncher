import Foundation

enum AppDefaults {
    static let schemaVersionKey = "initialDefaultsSchemaVersion"
    static let currentSchemaVersion = 3

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
            "showUncommonAppBubbles": showUncommonAppBubbles,
            "skipTagRemovalDropConfirm": false,
            LauncherHotkeyRegistrationStore.mainStateKey: LauncherHotkeyRegistrationState.active.rawValue,
            LauncherHotkeyRegistrationStore.quickSearchStateKey: LauncherHotkeyRegistrationState.active.rawValue
        ])
        removeShortcutCustomizationDefaults()
    }

    static func hasStoredValue(for key: String) -> Bool {
        let domain = Bundle.main.bundleIdentifier ?? AppIdentity.bundleIdentifier
        return UserDefaults.standard.persistentDomain(forName: domain)?[key] != nil
    }

    private static func removeShortcutCustomizationDefaults() {
        let defaults = UserDefaults.standard
        [
            "mainHotkey",
            "quickSearchHotkey",
            "mainHotkeyPending",
            "quickSearchHotkeyPending",
            "mainHotkeyStatus",
            "quickSearchHotkeyStatus",
            "mainHotkeyConflictMessage",
            "quickSearchHotkeyConflictMessage"
        ].forEach { defaults.removeObject(forKey: $0) }
        defaults.set(currentSchemaVersion, forKey: schemaVersionKey)
    }
}
