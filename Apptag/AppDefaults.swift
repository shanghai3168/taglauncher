import Foundation

enum AppDefaults {
    static let schemaVersionKey = "initialDefaultsSchemaVersion"
    static let currentSchemaVersion = 2

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
        migrateShortcutDefaultsIfNeeded()
    }

    static func hasStoredValue(for key: String) -> Bool {
        let domain = Bundle.main.bundleIdentifier ?? "com.apptag.launcher"
        return UserDefaults.standard.persistentDomain(forName: domain)?[key] != nil
    }

    private static func migrateShortcutDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: schemaVersionKey) < currentSchemaVersion else { return }

        defaults.set(LauncherHotkey.defaultMain.serialized, forKey: LauncherHotkeyKind.main.storageKey)
        defaults.removeObject(forKey: LauncherHotkeyKind.main.pendingStorageKey)
        defaults.removeObject(forKey: LauncherHotkeyKind.main.statusKey)
        defaults.removeObject(forKey: LauncherHotkeyKind.main.conflictMessageKey)

        let quickSearchKey = LauncherHotkeyKind.quickSearch.storageKey
        let storedQuickSearch = defaults.string(forKey: quickSearchKey) ?? ""
        if storedQuickSearch.isEmpty {
            defaults.set(LauncherHotkey.defaultQuickSearch.serialized, forKey: quickSearchKey)
            defaults.removeObject(forKey: LauncherHotkeyKind.quickSearch.pendingStorageKey)
            defaults.removeObject(forKey: LauncherHotkeyKind.quickSearch.statusKey)
            defaults.removeObject(forKey: LauncherHotkeyKind.quickSearch.conflictMessageKey)
        }

        defaults.set(currentSchemaVersion, forKey: schemaVersionKey)
    }
}
