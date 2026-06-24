import Foundation

enum AppDefaults {
    static let schemaVersionKey = "initialDefaultsSchemaVersion"
    static let currentSchemaVersion = 3

    static let tagFontSize: Double = 22
    static let iconSize: Double = 64
    static let tagPosition = "right"
    static let displayMode = "coloredGridContainer"
    static let hideAppNames = true
    static let showDockIcon = true
    static let launchAtLogin = true
    static let showUncommonAppBubbles = false
    static let hideUsageTips = false
    static let appGridThemeID = AppGridTheme.defaultLight.rawValue
    static let useAppKitTagNavigation = true

    static func register() {
        migrateAppGridThemePreferenceIfNeeded()
        UserDefaults.standard.register(defaults: [
            "tagFontSize": tagFontSize,
            "iconSize": iconSize,
            "tagPosition": tagPosition,
            "displayMode": displayMode,
            "hideAppNames": hideAppNames,
            "showDockIcon": showDockIcon,
            "launchAtLogin": launchAtLogin,
            "showUncommonAppBubbles": showUncommonAppBubbles,
            "hideUsageTips": hideUsageTips,
            AppGridTheme.storageKey: appGridThemeID,
            "useAppKitTagNavigation": useAppKitTagNavigation,
            "skipTagRemovalDropConfirm": false,
            "skipUncategorizedDropConfirm": false,
            LauncherHotkeyRegistrationStore.mainStateKey: LauncherHotkeyRegistrationState.active.rawValue,
            LauncherHotkeyRegistrationStore.quickSearchStateKey: LauncherHotkeyRegistrationState.active.rawValue
        ])
        removeShortcutCustomizationDefaults()
    }

    static func hasStoredValue(for key: String) -> Bool {
        let domain = Bundle.main.bundleIdentifier ?? AppIdentity.bundleIdentifier
        return UserDefaults.standard.persistentDomain(forName: domain)?[key] != nil
    }

    private static func migrateAppGridThemePreferenceIfNeeded() {
        let defaults = UserDefaults.standard
        guard !hasStoredValue(for: AppGridTheme.storageKey),
              hasStoredValue(for: "useDarkAppGrid"),
              defaults.bool(forKey: "useDarkAppGrid")
        else { return }
        defaults.set(AppGridTheme.deepBlue.rawValue, forKey: AppGridTheme.storageKey)
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
