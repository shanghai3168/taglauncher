import Foundation

// MARK: - Localization Manager

enum L10n {
    static var current: [String: String] = [:]

    /// Call once at startup to load the saved or system language.
    static func setup() {
        let code = UserDefaults.standard.string(forKey: "appLanguage") ?? fallbackCode()
        load(code)
    }

    static let supported: [(code: String, name: String)] = [
        ("en", "English"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁體中文"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("ru", "Русский"),
        ("fr", "Français"),
        ("it", "Italiano"),
        ("es", "Español"),
    ]

    static func switchTo(_ code: String) {
        load(code)
        UserDefaults.standard.set(code, forKey: "appLanguage")
    }

    private static func load(_ code: String) {
        guard let url = Bundle.main.url(
            forResource: code, withExtension: "json",
            subdirectory: "Localization"
        ) else {
            // Fallback to bundled English
            if code != "en" { load("en") }
            return
        }
        guard let data = try? Data(contentsOf: url),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return }
        current = dict
    }

    private static func fallbackCode() -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        if lang.hasPrefix("zh-Hant") || lang.hasPrefix("zh-HK") || lang.hasPrefix("zh-TW") { return "zh-Hant" }
        if lang.hasPrefix("zh") { return "zh-Hans" }
        if lang.hasPrefix("ja") { return "ja" }
        if lang.hasPrefix("ko") { return "ko" }
        if lang.hasPrefix("ru") { return "ru" }
        if lang.hasPrefix("fr") { return "fr" }
        if lang.hasPrefix("it") { return "it" }
        if lang.hasPrefix("es") { return "es" }
        return "en"
    }
}

/// Convenience function — use `tr("key")` everywhere.
func tr(_ key: String) -> String {
    L10n.current[key] ?? key
}
