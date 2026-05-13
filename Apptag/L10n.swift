import Foundation

// MARK: - Localization Manager

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("AppLanguageDidChange")
}

enum L10n {
    static var current: [String: String] = [:]
    private(set) static var currentCode = "en"

    /// Call once at startup to load the saved or system language.
    static func setup() {
        let code = UserDefaults.standard.string(forKey: "appLanguage") ?? fallbackCode()
        load(code)
    }

    static let supported: [(code: String, name: String)] = [
        ("en", "English"),
        ("fr", "Français"),
        ("it", "Italiano"),
        ("de", "Deutsch"),
        ("es", "Español"),
        ("pt-BR", "Português (Brasil)"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁體中文"),
        ("ko", "한국어"),
        ("ja", "日本語"),
        ("ru", "Русский"),
        ("sr-Cyrl", "Српски (ћирилица)"),
        ("uk", "Українська"),
        ("th", "ไทย"),
        ("vi", "Tiếng Việt"),
        ("ar", "العربية"),
        ("ar-Najdi", "العربية (نجدي)"),
        ("tr", "Türkçe"),
        ("id", "Bahasa Indonesia"),
        ("cs", "Čeština"),
        ("da", "Dansk"),
        ("nl", "Nederlands"),
        ("no", "Norsk"),
        ("nn", "Norsk nynorsk"),
        ("nb", "Norsk bokmål"),
        ("ms", "Bahasa Melayu"),
        ("pl", "Polski"),
        ("ro", "Română"),
        ("sv", "Svenska"),
    ]

    static func switchTo(_ code: String) {
        guard supported.contains(where: { $0.code == code }) else { return }
        guard code != currentCode else { return }
        load(code)
        UserDefaults.standard.set(code, forKey: "appLanguage")
        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil, userInfo: ["code": currentCode])
    }

    /// Load a specific key's translation for a given language code without switching.
    static func loadedTranslation(_ key: String, for code: String) -> String? {
        guard let url = Bundle.main.url(
            forResource: code, withExtension: "json",
            subdirectory: "Localization"
        ) else { return nil }
        guard let data = try? Data(contentsOf: url),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return nil }
        return dict[key]
    }

    private static func load(_ code: String) {
        guard let url = Bundle.main.url(
            forResource: code, withExtension: "json",
            subdirectory: "Localization"
        ) else {
            if code != "en" { load("en") }
            return
        }
        guard let data = try? Data(contentsOf: url),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return }
        current = dict
        currentCode = code
    }

    private static func fallbackCode() -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        if lang.hasPrefix("zh-Hant") || lang.hasPrefix("zh-HK") || lang.hasPrefix("zh-TW") { return "zh-Hant" }
        if lang.hasPrefix("zh") { return "zh-Hans" }
        if lang.hasPrefix("pt-BR") || lang.hasPrefix("pt_BR") || lang.hasPrefix("pt") { return "pt-BR" }
        if lang.hasPrefix("sr-Cyrl") || lang.hasPrefix("sr_Cyrl") || lang.hasPrefix("sr") { return "sr-Cyrl" }
        if lang.hasPrefix("ar") { return "ar" }
        if lang.hasPrefix("de") { return "de" }
        if lang.hasPrefix("ja") { return "ja" }
        if lang.hasPrefix("ko") { return "ko" }
        if lang.hasPrefix("ru") { return "ru" }
        if lang.hasPrefix("uk") { return "uk" }
        if lang.hasPrefix("fr") { return "fr" }
        if lang.hasPrefix("it") { return "it" }
        if lang.hasPrefix("es") { return "es" }
        if lang.hasPrefix("th") { return "th" }
        if lang.hasPrefix("vi") { return "vi" }
        if lang.hasPrefix("tr") { return "tr" }
        if lang.hasPrefix("id") { return "id" }
        if lang.hasPrefix("cs") { return "cs" }
        if lang.hasPrefix("da") { return "da" }
        if lang.hasPrefix("nl") { return "nl" }
        if lang.hasPrefix("nn") { return "nn" }
        if lang.hasPrefix("nb") { return "nb" }
        if lang.hasPrefix("no") { return "no" }
        if lang.hasPrefix("ms") { return "ms" }
        if lang.hasPrefix("pl") { return "pl" }
        if lang.hasPrefix("ro") { return "ro" }
        if lang.hasPrefix("sv") { return "sv" }
        return "en"
    }
}

/// Convenience function — use `tr("key")` everywhere.
func tr(_ key: String) -> String {
    L10n.current[key] ?? key
}
