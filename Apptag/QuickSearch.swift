import SwiftUI
import AppKit
import Carbon

extension Notification.Name {
    static let tagLauncherQuickSearchRequested = Notification.Name("TagLauncherQuickSearchRequested")
    static let tagLauncherQuickSearchDismissRequested = Notification.Name("TagLauncherQuickSearchDismissRequested")
    static let tagLauncherQuickSearchVisibilityChanged = Notification.Name("TagLauncherQuickSearchVisibilityChanged")
    static let tagLauncherHotkeyRegistrationChanged = Notification.Name("TagLauncherHotkeyRegistrationChanged")
}

enum QuickSearchOpenSource {
    static let mainOverlay = "mainOverlay"
    static let globalHidden = "globalHidden"
    static let globalVisible = "globalVisible"
}

// MARK: - Hotkeys

struct LauncherHotkey: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    var displayString: String {
        let ordered: [(UInt32, String)] = [
            (UInt32(controlKey), "⌃"),
            (UInt32(optionKey), "⌥"),
            (UInt32(shiftKey), "⇧"),
            (UInt32(cmdKey), "⌘"),
            (UInt32(kEventKeyModifierFnMask), "Fn+")
        ]
        let modifierGlyphs = ordered
            .filter { modifiers & $0.0 != 0 }
            .map(\.1)
            .joined()
        return modifierGlyphs + LauncherHotkey.keyDisplayName(for: keyCode)
    }

    static var main: LauncherHotkey {
        LauncherHotkey(keyCode: UInt32(kVK_Space), modifiers: UInt32(shiftKey | optionKey))
    }

    static var quickSearch: LauncherHotkey {
        LauncherHotkey(keyCode: UInt32(kVK_Space), modifiers: UInt32(kEventKeyModifierFnMask))
    }

    static func keyDisplayName(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Escape: return "Esc"
        case kVK_Delete: return "Delete"
        case kVK_Tab: return "Tab"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            if let scalar = keyCodeToPrintableScalar[Int(keyCode)] {
                return String(scalar)
            }
            return "Key \(keyCode)"
        }
    }

    private static let keyCodeToPrintableScalar: [Int: Character] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
        kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
        kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
        kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z", kVK_ANSI_0: "0", kVK_ANSI_1: "1",
        kVK_ANSI_2: "2", kVK_ANSI_3: "3", kVK_ANSI_4: "4", kVK_ANSI_5: "5",
        kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8", kVK_ANSI_9: "9"
    ]
}

enum LauncherHotkeyKind: String {
    case main
    case quickSearch

    var stateKey: String {
        switch self {
        case .main: return LauncherHotkeyRegistrationStore.mainStateKey
        case .quickSearch: return LauncherHotkeyRegistrationStore.quickSearchStateKey
        }
    }

    var failureCodeKey: String {
        switch self {
        case .main: return LauncherHotkeyRegistrationStore.mainFailureCodeKey
        case .quickSearch: return LauncherHotkeyRegistrationStore.quickSearchFailureCodeKey
        }
    }

    var attentionKey: String {
        switch self {
        case .main: return LauncherHotkeyRegistrationStore.mainNeedsAttentionKey
        case .quickSearch: return LauncherHotkeyRegistrationStore.quickSearchNeedsAttentionKey
        }
    }

    var hotkey: LauncherHotkey {
        switch self {
        case .main: return .main
        case .quickSearch: return .quickSearch
        }
    }

    var eventID: UInt32 {
        switch self {
        case .main: return 1
        case .quickSearch: return 2
        }
    }
}

enum LauncherHotkeyRegistrationState: String {
    case active
    case failed
}

enum LauncherHotkeyRegistrationStore {
    static let mainStateKey = "mainHotkeyRegistrationState"
    static let quickSearchStateKey = "quickSearchHotkeyRegistrationState"
    static let mainFailureCodeKey = "mainHotkeyRegistrationFailureCode"
    static let quickSearchFailureCodeKey = "quickSearchHotkeyRegistrationFailureCode"
    static let mainNeedsAttentionKey = "mainHotkeyRegistrationNeedsAttention"
    static let quickSearchNeedsAttentionKey = "quickSearchHotkeyRegistrationNeedsAttention"

    static func state(for kind: LauncherHotkeyKind) -> LauncherHotkeyRegistrationState {
        let rawValue = UserDefaults.standard.string(forKey: kind.stateKey)
        return LauncherHotkeyRegistrationState(rawValue: rawValue ?? "") ?? .active
    }

    static func failureCode(for kind: LauncherHotkeyKind) -> Int? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: kind.failureCodeKey) != nil else { return nil }
        return defaults.integer(forKey: kind.failureCodeKey)
    }

    static func setActive(for kind: LauncherHotkeyKind) {
        setState(.active, failureCode: nil, for: kind)
    }

    static func setFailed(_ failureCode: OSStatus, for kind: LauncherHotkeyKind) {
        setState(.failed, failureCode: Int(failureCode), for: kind)
    }

    static func consumeNeedsAttention(for kind: LauncherHotkeyKind) -> Bool {
        let defaults = UserDefaults.standard
        let needsAttention = defaults.bool(forKey: kind.attentionKey)
        defaults.set(false, forKey: kind.attentionKey)
        return needsAttention
    }

    private static func setState(
        _ state: LauncherHotkeyRegistrationState,
        failureCode: Int?,
        for kind: LauncherHotkeyKind
    ) {
        let defaults = UserDefaults.standard
        let previousState = defaults.string(forKey: kind.stateKey)
        let previousFailureCode = defaults.object(forKey: kind.failureCodeKey) == nil
            ? nil
            : defaults.integer(forKey: kind.failureCodeKey)
        let stateChanged = previousState != state.rawValue || previousFailureCode != failureCode

        defaults.set(state.rawValue, forKey: kind.stateKey)
        if let failureCode {
            defaults.set(failureCode, forKey: kind.failureCodeKey)
        } else {
            defaults.removeObject(forKey: kind.failureCodeKey)
        }

        if state == .active {
            defaults.set(false, forKey: kind.attentionKey)
        } else if stateChanged {
            defaults.set(true, forKey: kind.attentionKey)
        }

        NotificationCenter.default.post(
            name: .tagLauncherHotkeyRegistrationChanged,
            object: nil,
            userInfo: ["kind": kind.rawValue]
        )
    }
}

// MARK: - Search Documents

private enum QuickSearchFieldKind: Int {
    case name = 0
    case tag = 1
    case note = 2
    case bundleIdentifier = 3
    case internalBundleName = 4

    var weight: Double {
        switch self {
        case .name: return 100
        case .tag: return 70
        case .note: return 45
        case .internalBundleName: return 30
        case .bundleIdentifier: return 20
        }
    }
}

private enum QuickSearchMatchKind {
    case exact
    case prefix
    case substring
    case acronym
    case fuzzy

    var weight: Double {
        switch self {
        case .exact: return 100
        case .prefix: return 80
        case .substring: return 60
        case .acronym: return 55
        case .fuzzy: return 35
        }
    }
}

private struct QuickSearchIndexedField {
    let kind: QuickSearchFieldKind
    let text: String
    let normalized: String
    let acronym: String
    let pinyinCandidates: [String]
    let allowPinyinSubstring: Bool
    let allowPinyinFuzzySubsequence: Bool
}

private struct QuickSearchMatchOptions {
    let allowSubstring: Bool
    let allowFuzzySubsequence: Bool
}

private struct QuickSearchTokenMatch {
    let score: Double
    let fieldRank: Int
    let fieldKind: QuickSearchFieldKind
    let originalText: String
}

struct QuickSearchDocument: Identifiable {
    var id: URL { app.id }
    let app: AppInfo
    let localizedNames: [String]
    let internalBundleNames: [String]
    let tagNames: [String]
    let note: String
    let bundleIdentifier: String
    let lastOpenedAt: Date?
    let openCount: Int
    fileprivate let searchableFields: [QuickSearchIndexedField]
}

struct QuickSearchResult: Identifiable {
    var id: URL { document.id }
    let document: QuickSearchDocument
    let finalScore: Double
    let textScore: Double
    let bestFieldRank: Int
    let matchedTagName: String?
    let noteSnippet: String?

    var app: AppInfo { document.app }
}

enum QuickSearchEngine {
    static func makeDocuments(apps: [AppInfo], store: TagDatabase.Store) -> [QuickSearchDocument] {
        apps.map { app in
            let localizedNames = uniqueOrdered(app.localizedNames)
            let internalBundleNames = internalBundleNames(for: app)
            let note = store.appNotes[app.path.path] ?? app.note ?? ""
            let bundleIdentifier = app.bundleIdentifier ?? ""
            let searchableFields = makeSearchableFields(
                appName: app.name,
                localizedNames: localizedNames,
                internalBundleNames: internalBundleNames,
                tagNames: app.tags,
                note: note,
                bundleIdentifier: bundleIdentifier
            )
            return QuickSearchDocument(
                app: app,
                localizedNames: localizedNames,
                internalBundleNames: internalBundleNames,
                tagNames: app.tags,
                note: note,
                bundleIdentifier: bundleIdentifier,
                lastOpenedAt: store.appLastOpenedAt[app.path.path],
                openCount: store.appOpenCounts[app.path.path] ?? 0,
                searchableFields: searchableFields
            )
        }
    }

    static func search(_ query: String, documents: [QuickSearchDocument], limit: Int = 50) -> [QuickSearchResult] {
        let normalizedQuery = normalizeQuery(query)
        guard !normalizedQuery.isEmpty else {
            return emptyQueryResults(documents: documents, limit: min(limit, 6))
        }

        let tokens = normalizedQuery.split(separator: " ").map(String.init)
        let results = documents.compactMap { result(for: $0, tokens: tokens) }
        return results.sorted(by: rank).prefix(limit).map { $0 }
    }

    static func normalizeQuery(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private static func result(for document: QuickSearchDocument, tokens: [String]) -> QuickSearchResult? {
        let fields = document.searchableFields
        var textScore: Double = 0
        var bestFieldRank = Int.max
        var matchedTagName: String?
        var noteSnippet: String?

        for token in tokens {
            guard let tokenMatch = fields
                .compactMap({ match(token: token, field: $0) })
                .max(by: { $0.score < $1.score })
            else {
                return nil
            }
            textScore += tokenMatch.score
            bestFieldRank = min(bestFieldRank, tokenMatch.fieldRank)
            if tokenMatch.fieldKind == .tag {
                matchedTagName = tokenMatch.originalText
            } else if tokenMatch.fieldKind == .note {
                noteSnippet = snippet(from: document.note, token: token)
            }
        }

        let finalScore = textScore + behaviorBoost(for: document)
        return QuickSearchResult(
            document: document,
            finalScore: finalScore,
            textScore: textScore,
            bestFieldRank: bestFieldRank,
            matchedTagName: matchedTagName,
            noteSnippet: noteSnippet
        )
    }

    private static func makeSearchableFields(
        appName: String,
        localizedNames: [String],
        internalBundleNames: [String],
        tagNames: [String],
        note: String,
        bundleIdentifier: String
    ) -> [QuickSearchIndexedField] {
        let names = uniqueOrdered([appName] + localizedNames)
        let nameFields = names.map {
            return QuickSearchIndexedField(
                kind: .name,
                text: $0,
                normalized: normalizeField($0),
                acronym: acronym(for: $0),
                pinyinCandidates: pinyinCandidates(for: $0, includeLatin: true),
                allowPinyinSubstring: true,
                allowPinyinFuzzySubsequence: true
            )
        }
        let tagFields = tagNames.map {
            QuickSearchIndexedField(
                kind: .tag,
                text: $0,
                normalized: normalizeField($0),
                acronym: "",
                pinyinCandidates: pinyinCandidates(for: $0),
                allowPinyinSubstring: false,
                allowPinyinFuzzySubsequence: false
            )
        }
        let noteFields = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [
            QuickSearchIndexedField(
                kind: .note,
                text: note,
                normalized: normalizeField(note),
                acronym: "",
                pinyinCandidates: pinyinCandidates(for: note),
                allowPinyinSubstring: true,
                allowPinyinFuzzySubsequence: false
            )
        ]
        let bundleFields = bundleIdentifier.isEmpty ? [] : [
            QuickSearchIndexedField(
                kind: .bundleIdentifier,
                text: bundleIdentifier,
                normalized: normalizeField(bundleIdentifier),
                acronym: "",
                pinyinCandidates: [],
                allowPinyinSubstring: false,
                allowPinyinFuzzySubsequence: false
            )
        ]
        let internalBundleNameFields = internalBundleNames.map {
            QuickSearchIndexedField(
                kind: .internalBundleName,
                text: $0,
                normalized: normalizeField($0),
                acronym: "",
                pinyinCandidates: [],
                allowPinyinSubstring: false,
                allowPinyinFuzzySubsequence: false
            )
        }
        return nameFields + tagFields + noteFields + bundleFields + internalBundleNameFields
    }

    private static func match(token: String, field: QuickSearchIndexedField) -> QuickSearchTokenMatch? {
        guard let candidate = bestMatchCandidate(token: token, field: field) else { return nil }
        let positionBoost = candidate.0 == .exact ? 0 : max(0, 10 - min(candidate.1, 10))
        let score = field.kind.weight + candidate.0.weight + Double(positionBoost)
        return QuickSearchTokenMatch(
            score: score,
            fieldRank: field.kind.rawValue,
            fieldKind: field.kind,
            originalText: field.text
        )
    }

    private static func bestMatchCandidate(token: String, field: QuickSearchIndexedField) -> (QuickSearchMatchKind, Int)? {
        var candidates: [(QuickSearchMatchKind, Int)] = []

        if let textCandidate = matchCandidate(
            token: token,
            normalized: field.normalized,
            options: matchOptions(for: field.kind)
        ) {
            candidates.append(textCandidate)
        }
        if field.kind == .name && !field.acronym.isEmpty && field.acronym.hasPrefix(token) {
            candidates.append((.acronym, 0))
        }
        for pinyin in field.pinyinCandidates {
            if let pinyinCandidate = matchPinyinCandidate(
                token: token,
                normalized: pinyin,
                allowSubstring: field.allowPinyinSubstring,
                allowFuzzySubsequence: field.allowPinyinFuzzySubsequence
            ) {
                candidates.append(pinyinCandidate)
            }
        }

        return candidates.max { lhs, rhs in
            if lhs.0.weight != rhs.0.weight { return lhs.0.weight < rhs.0.weight }
            return lhs.1 > rhs.1
        }
    }

    private static func matchOptions(for fieldKind: QuickSearchFieldKind) -> QuickSearchMatchOptions {
        switch fieldKind {
        case .name:
            return QuickSearchMatchOptions(allowSubstring: true, allowFuzzySubsequence: true)
        case .tag:
            return QuickSearchMatchOptions(allowSubstring: true, allowFuzzySubsequence: true)
        case .note:
            return QuickSearchMatchOptions(allowSubstring: true, allowFuzzySubsequence: true)
        case .bundleIdentifier, .internalBundleName:
            return QuickSearchMatchOptions(allowSubstring: false, allowFuzzySubsequence: false)
        }
    }

    private static func matchCandidate(
        token: String,
        normalized: String,
        options: QuickSearchMatchOptions
    ) -> (QuickSearchMatchKind, Int)? {
        guard !normalized.isEmpty else { return nil }
        if normalized == token {
            return (.exact, 0)
        }
        if normalized.hasPrefix(token) {
            return (.prefix, 0)
        }
        if options.allowSubstring, let range = normalized.range(of: token) {
            return (.substring, normalized.distance(from: normalized.startIndex, to: range.lowerBound))
        }
        if options.allowFuzzySubsequence, token.count >= 4, isSubsequence(token, of: normalized) {
            return (.fuzzy, 10)
        }
        return nil
    }

    private static func matchPinyinCandidate(
        token: String,
        normalized: String,
        allowSubstring: Bool = false,
        allowFuzzySubsequence: Bool = false
    ) -> (QuickSearchMatchKind, Int)? {
        guard !normalized.isEmpty else { return nil }
        if normalized == token {
            return (.exact, 0)
        }
        if normalized.hasPrefix(token) {
            return (.prefix, 0)
        }
        if allowSubstring, let range = normalized.range(of: token) {
            return (.substring, normalized.distance(from: normalized.startIndex, to: range.lowerBound))
        }
        if allowFuzzySubsequence, token.count >= 3, isSubsequence(token, of: normalized) {
            return (.fuzzy, 10)
        }
        return nil
    }

    private static func emptyQueryResults(documents: [QuickSearchDocument], limit: Int) -> [QuickSearchResult] {
        var used = Set<URL>()
        let recent = documents
            .filter { $0.lastOpenedAt != nil }
            .sorted {
                if ($0.lastOpenedAt ?? .distantPast) != ($1.lastOpenedAt ?? .distantPast) {
                    return ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast)
                }
                return $0.app.name.localizedStandardCompare($1.app.name) == .orderedAscending
            }

        let frequent = documents
            .filter { $0.openCount > 0 }
            .sorted {
                if $0.openCount != $1.openCount { return $0.openCount > $1.openCount }
                return $0.app.name.localizedStandardCompare($1.app.name) == .orderedAscending
            }

        let ordered = (recent + frequent).filter { used.insert($0.id).inserted }
        return ordered.prefix(limit).map {
            QuickSearchResult(
                document: $0,
                finalScore: behaviorBoost(for: $0),
                textScore: 0,
                bestFieldRank: Int.max,
                matchedTagName: nil,
                noteSnippet: nil
            )
        }
    }

    private static func rank(_ lhs: QuickSearchResult, _ rhs: QuickSearchResult) -> Bool {
        if lhs.finalScore != rhs.finalScore { return lhs.finalScore > rhs.finalScore }
        if lhs.textScore != rhs.textScore { return lhs.textScore > rhs.textScore }
        if lhs.bestFieldRank != rhs.bestFieldRank { return lhs.bestFieldRank < rhs.bestFieldRank }
        let leftDate = lhs.document.lastOpenedAt ?? .distantPast
        let rightDate = rhs.document.lastOpenedAt ?? .distantPast
        if leftDate != rightDate { return leftDate > rightDate }
        if lhs.document.openCount != rhs.document.openCount {
            return lhs.document.openCount > rhs.document.openCount
        }
        if lhs.app.name.count != rhs.app.name.count {
            return lhs.app.name.count < rhs.app.name.count
        }
        return lhs.app.name.localizedStandardCompare(rhs.app.name) == .orderedAscending
    }

    private static func behaviorBoost(for document: QuickSearchDocument) -> Double {
        min(recentBoost(for: document.lastOpenedAt) + frequencyBoost(for: document.openCount), 20)
    }

    private static func recentBoost(for date: Date?) -> Double {
        guard let date else { return 0 }
        let age = Date().timeIntervalSince(date)
        if age <= 24 * 60 * 60 { return 15 }
        if age <= 7 * 24 * 60 * 60 { return 10 }
        if age <= 30 * 24 * 60 * 60 { return 5 }
        return 2
    }

    private static func frequencyBoost(for openCount: Int) -> Double {
        min(Double(openCount), 10)
    }

    private static func normalizeField(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private static func pinyinCandidates(for value: String, includeLatin: Bool = false) -> [String] {
        guard includeLatin || containsNonLatinLetter(value) else { return [] }
        let mutable = NSMutableString(string: value)
        CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)

        let spaced = normalizeField(mutable as String)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard !spaced.isEmpty else { return [] }

        let compact = spaced.replacingOccurrences(of: " ", with: "")
        let initials = spaced
            .split(separator: " ")
            .compactMap(\.first)
            .map(String.init)
            .joined()
        return uniqueOrdered([spaced, compact, initials].filter { !$0.isEmpty })
    }

    private static func containsNonLatinLetter(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            CharacterSet.letters.contains(scalar) && !isLatinScriptLetter(scalar)
        }
    }

    private static func isLatinScriptLetter(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0041...0x005A, // Basic Latin uppercase
             0x0061...0x007A, // Basic Latin lowercase
             0x00AA,
             0x00BA,
             0x00C0...0x024F, // Latin-1 Supplement, Extended-A/B
             0x1E00...0x1EFF, // Latin Extended Additional
             0x2C60...0x2C7F, // Latin Extended-C
             0xA720...0xA7FF, // Latin Extended-D
             0xAB30...0xAB6F, // Latin Extended-E
             0xFF21...0xFF3A, // Fullwidth Latin uppercase
             0xFF41...0xFF5A: // Fullwidth Latin lowercase
            return true
        default:
            return false
        }
    }

    private static func isSubsequence(_ token: String, of value: String) -> Bool {
        var searchStart = value.startIndex
        for character in token {
            guard let index = value[searchStart...].firstIndex(of: character) else { return false }
            searchStart = value.index(after: index)
        }
        return true
    }

    private static func acronym(for value: String) -> String {
        var parts: [Character] = []
        var nextStartsWord = true
        var previousWasLowercase = false
        for character in value {
            let current = String(character)
            let isAlphanumeric = current.rangeOfCharacter(from: .alphanumerics) != nil
            guard isAlphanumeric else {
                nextStartsWord = true
                previousWasLowercase = false
                continue
            }

            let isUppercase = current.rangeOfCharacter(from: .uppercaseLetters) != nil
            let isLowercase = current.rangeOfCharacter(from: .lowercaseLetters) != nil
            if nextStartsWord || (isUppercase && previousWasLowercase) {
                parts.append(character)
            }
            nextStartsWord = false
            previousWasLowercase = isLowercase
        }
        return normalizeField(String(parts))
    }

    private static func localizedNames(for app: AppInfo) -> [String] {
        guard let bundle = Bundle(url: app.path) else { return [] }
        let values = [
            bundle.localizedInfoDictionary?["CFBundleDisplayName"] as? String,
            bundle.infoDictionary?["CFBundleDisplayName"] as? String,
            FileManager.default.displayName(atPath: app.path.path).replacingOccurrences(of: ".app", with: "")
        ]
        return uniqueOrdered(values.compactMap { $0 }.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty || trimmed == app.name ? nil : trimmed
        })
    }

    private static func internalBundleNames(for app: AppInfo) -> [String] {
        guard let bundle = Bundle(url: app.path) else { return [] }
        let values = [
            bundle.localizedInfoDictionary?["CFBundleName"] as? String,
            bundle.infoDictionary?["CFBundleName"] as? String
        ]
        return uniqueOrdered(values.compactMap { $0 }.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty || trimmed == app.name ? nil : trimmed
        })
    }

    private static func snippet(from note: String, token: String) -> String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 80 else { return trimmed }
        return String(trimmed.prefix(77)) + "..."
    }

    private static func uniqueOrdered(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert(normalizeField($0)).inserted }
    }
}

// MARK: - Quick Search UI

enum QuickSearchCommand {
    case moveUp
    case moveDown
    case submit
    case dismiss
}

enum QuickSearchPanelMetrics {
    static let width: CGFloat = 760
    static let shadowOutset: CGFloat = 56
    static let rowHeight: CGFloat = 74
    static let rowSpacing: CGFloat = 2
    static let resultListVerticalInset: CGFloat = 10
    static let headerHeight: CGFloat = 84
    static let dividerHeight: CGFloat = 1
    static let messageRowHeight: CGFloat = 86

    static func contentHeight(hasResultList: Bool, visibleRows: Int) -> CGFloat {
        if hasResultList {
            return headerHeight
                + dividerHeight
                + CGFloat(max(1, visibleRows)) * (rowHeight + rowSpacing)
                + resultListVerticalInset * 2
        }
        return headerHeight + dividerHeight + messageRowHeight
    }
}

struct QuickSearchPanelPresentationView: NSViewRepresentable {
    @Binding var query: String
    let results: [QuickSearchResult]
    let selectedID: URL?
    let focusToken: Int
    let selectionScrollToken: Int
    let isLoading: Bool
    let maxVisibleRows: Int
    let panelTopY: CGFloat
    let panelHeight: CGFloat
    let errorMessage: String?
    let onCommand: (QuickSearchCommand) -> Void
    let onHover: (QuickSearchResult) -> Void
    let onLaunch: (QuickSearchResult) -> Void

    func makeNSView(context: Context) -> QuickSearchPanelAnchorView {
        QuickSearchPanelAnchorView()
    }

    func updateNSView(_ view: QuickSearchPanelAnchorView, context: Context) {
        let contentSize = NSSize(width: QuickSearchPanelMetrics.width, height: panelHeight)
        let windowSize = NSSize(
            width: contentSize.width + QuickSearchPanelMetrics.shadowOutset * 2,
            height: contentSize.height + QuickSearchPanelMetrics.shadowOutset * 2
        )
        let rootView = QuickSearchPanelWindowContent(
            windowSize: windowSize,
            contentSize: contentSize,
            content: AnyView(
                QuickSearchOverlayView(
                    query: $query,
                    results: results,
                    selectedID: selectedID,
                    focusToken: focusToken,
                    selectionScrollToken: selectionScrollToken,
                    isLoading: isLoading,
                    maxVisibleRows: maxVisibleRows,
                    errorMessage: errorMessage,
                    onCommand: onCommand,
                    onHover: onHover,
                    onLaunch: onLaunch
                )
            )
        )
        context.coordinator.apply(
            QuickSearchPanelConfiguration(
                panelTopY: panelTopY,
                windowSize: windowSize,
                contentSize: contentSize,
                rootView: AnyView(rootView)
            ),
            anchorView: view
        )
    }

    static func dismantleNSView(_ nsView: QuickSearchPanelAnchorView, coordinator: Coordinator) {
        coordinator.closePanel()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var panel: QuickSearchPanel?
        private var hostingView: NSHostingView<AnyView>?
        private weak var parentWindow: NSWindow?
        private var deferredApplyPending = false

        func apply(_ configuration: QuickSearchPanelConfiguration, anchorView: QuickSearchPanelAnchorView) {
            guard let parentWindow = anchorView.window else {
                scheduleDeferredApply(configuration, anchorView: anchorView)
                return
            }

            deferredApplyPending = false
            let panel = ensurePanel(parentWindow: parentWindow)
            let frame = windowFrame(
                parentWindow: parentWindow,
                panelTopY: configuration.panelTopY,
                contentSize: configuration.contentSize,
                windowSize: configuration.windowSize
            )

            hostingView?.rootView = configuration.rootView
            hostingView?.frame = NSRect(origin: .zero, size: configuration.windowSize)
            panel.contentView?.frame = NSRect(origin: .zero, size: configuration.windowSize)
            panel.collectionBehavior = collectionBehavior(parentWindow: parentWindow)
            panel.level = parentWindow.level

            if panel.parent !== parentWindow {
                if let previousParent = panel.parent {
                    previousParent.removeChildWindow(panel)
                }
                parentWindow.addChildWindow(panel, ordered: .above)
                self.parentWindow = parentWindow
            }

            if panel.frame != frame {
                panel.setFrame(frame, display: true)
            }
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
        }

        func closePanel() {
            if let panel {
                if let parent = panel.parent {
                    parent.removeChildWindow(panel)
                }
                panel.orderOut(nil)
            }
            panel = nil
            hostingView = nil
            parentWindow = nil
            deferredApplyPending = false
        }

        private func ensurePanel(parentWindow: NSWindow) -> QuickSearchPanel {
            if let panel {
                return panel
            }

            let panel = QuickSearchPanel(
                contentRect: .zero,
                styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden
            panel.isReleasedWhenClosed = false
            panel.collectionBehavior = collectionBehavior(parentWindow: parentWindow)

            let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            panel.contentView = hostingView

            self.panel = panel
            self.hostingView = hostingView
            return panel
        }

        private func scheduleDeferredApply(
            _ configuration: QuickSearchPanelConfiguration,
            anchorView: QuickSearchPanelAnchorView
        ) {
            guard !deferredApplyPending else { return }
            deferredApplyPending = true
            DispatchQueue.main.async { [weak self, weak anchorView] in
                guard let self, let anchorView else { return }
                self.deferredApplyPending = false
                self.apply(configuration, anchorView: anchorView)
            }
        }

        private func windowFrame(
            parentWindow: NSWindow,
            panelTopY: CGFloat,
            contentSize: NSSize,
            windowSize: NSSize
        ) -> NSRect {
            let parentFrame = parentWindow.frame
            return NSRect(
                x: parentFrame.minX + (parentFrame.width - contentSize.width) / 2 - QuickSearchPanelMetrics.shadowOutset,
                y: parentFrame.maxY - panelTopY - contentSize.height - QuickSearchPanelMetrics.shadowOutset,
                width: windowSize.width,
                height: windowSize.height
            )
        }

        private func collectionBehavior(parentWindow: NSWindow) -> NSWindow.CollectionBehavior {
            var behavior: NSWindow.CollectionBehavior = [
                .fullScreenAuxiliary,
                .stationary,
                .transient,
                .ignoresCycle
            ]
            if parentWindow.collectionBehavior.contains(.canJoinAllSpaces) {
                behavior.insert(.canJoinAllSpaces)
            }
            return behavior
        }
    }
}

private final class QuickSearchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

final class QuickSearchPanelAnchorView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}

struct QuickSearchPanelConfiguration {
    let panelTopY: CGFloat
    let windowSize: NSSize
    let contentSize: NSSize
    let rootView: AnyView
}

private struct QuickSearchPanelWindowContent: View {
    let windowSize: NSSize
    let contentSize: NSSize
    let content: AnyView

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(width: contentSize.width, height: contentSize.height, alignment: .top)
            Spacer(minLength: 0)
        }
        .padding(.top, QuickSearchPanelMetrics.shadowOutset)
        .padding(.horizontal, QuickSearchPanelMetrics.shadowOutset)
        .padding(.bottom, QuickSearchPanelMetrics.shadowOutset)
        .frame(width: windowSize.width, height: windowSize.height, alignment: .top)
        .background(Color.clear)
    }
}

struct QuickSearchOverlayView: View {
    @Binding var query: String
    let results: [QuickSearchResult]
    let selectedID: URL?
    let focusToken: Int
    let selectionScrollToken: Int
    let isLoading: Bool
    let maxVisibleRows: Int
    let errorMessage: String?
    let onCommand: (QuickSearchCommand) -> Void
    let onHover: (QuickSearchResult) -> Void
    let onLaunch: (QuickSearchResult) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let panelWidth: CGFloat = QuickSearchPanelMetrics.width
    private let rowHeight: CGFloat = QuickSearchPanelMetrics.rowHeight

    private var panelBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.105, green: 0.110, blue: 0.125).opacity(0.97)
            : Color.white.opacity(0.97)
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 18) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 29, weight: .regular))
                    .foregroundStyle(Color.primary.opacity(0.48))
                    .frame(width: 34)

                QuickSearchTextField(
                    text: $query,
                    placeholder: tr("quickSearch.placeholder"),
                    focusToken: focusToken,
                    onCommand: onCommand
                )
                .frame(height: 44)
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)
            .padding(.bottom, 18)

            Divider().opacity(0.35)

            if isLoading {
                QuickSearchMessageRow(
                    systemImage: "hourglass",
                    message: tr("quickSearch.loading"),
                    tint: .secondary
                )
            } else if let errorMessage {
                QuickSearchMessageRow(
                    systemImage: "exclamationmark.triangle.fill",
                    message: errorMessage,
                    tint: .orange
                )
            } else if results.isEmpty {
                QuickSearchMessageRow(
                    systemImage: query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "keyboard" : "magnifyingglass",
                    message: query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? tr("quickSearch.emptyPrompt")
                        : tr("quickSearch.noResults"),
                    tint: .secondary
                )
            } else {
                QuickSearchResultListView(
                    results: results,
                    selectedID: selectedID,
                    selectionScrollToken: selectionScrollToken,
                    maxVisibleRows: maxVisibleRows,
                    rowHeight: rowHeight,
                    isDarkMode: colorScheme == .dark,
                    onHover: onHover,
                    onLaunch: onLaunch
                )
                .frame(
                    height: CGFloat(min(results.count, maxVisibleRows))
                        * (rowHeight + QuickSearchPanelMetrics.rowSpacing)
                        + QuickSearchPanelMetrics.resultListVerticalInset * 2
                )
            }
        }
        .frame(width: panelWidth)
        .background(
            panelShape.fill(panelBackgroundColor)
        )
        .clipShape(panelShape)
        .overlay(
            panelShape.stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .compositingGroup()
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.46 : 0.26), radius: 30, x: 0, y: 18)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.24 : 0.12), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(tr("quickSearch.title"))
    }
}

private struct QuickSearchResultListView: NSViewRepresentable {
    let results: [QuickSearchResult]
    let selectedID: URL?
    let selectionScrollToken: Int
    let maxVisibleRows: Int
    let rowHeight: CGFloat
    let isDarkMode: Bool
    let onHover: (QuickSearchResult) -> Void
    let onLaunch: (QuickSearchResult) -> Void

    func makeNSView(context: Context) -> QuickSearchResultListHostView {
        let view = QuickSearchResultListHostView()
        view.update(
            results: results,
            selectedID: selectedID,
            selectionScrollToken: selectionScrollToken,
            maxVisibleRows: maxVisibleRows,
            rowHeight: rowHeight,
            isDarkMode: isDarkMode,
            onHover: onHover,
            onLaunch: onLaunch
        )
        return view
    }

    func updateNSView(_ view: QuickSearchResultListHostView, context: Context) {
        view.update(
            results: results,
            selectedID: selectedID,
            selectionScrollToken: selectionScrollToken,
            maxVisibleRows: maxVisibleRows,
            rowHeight: rowHeight,
            isDarkMode: isDarkMode,
            onHover: onHover,
            onLaunch: onLaunch
        )
    }
}

final class QuickSearchResultListHostView: NSView {
    private let scrollView = NSScrollView()
    private let documentView = QuickSearchResultListDocumentView()
    private var selectedID: URL?
    private var selectionScrollToken = 0
    private var didInstall = false

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func update(
        results: [QuickSearchResult],
        selectedID: URL?,
        selectionScrollToken: Int,
        maxVisibleRows: Int,
        rowHeight: CGFloat,
        isDarkMode: Bool,
        onHover: @escaping (QuickSearchResult) -> Void,
        onLaunch: @escaping (QuickSearchResult) -> Void
    ) {
        let shouldScrollSelection = selectionScrollToken != self.selectionScrollToken
        self.selectedID = selectedID
        self.selectionScrollToken = selectionScrollToken
        scrollView.hasVerticalScroller = results.count > maxVisibleRows
        documentView.update(
            results: results,
            selectedID: selectedID,
            rowHeight: rowHeight,
            isDarkMode: isDarkMode,
            onHover: onHover,
            onLaunch: onLaunch
        )
        needsLayout = true
        layoutSubtreeIfNeeded()
        if shouldScrollSelection, let selectedID {
            scrollResultToCenter(selectedID)
        }
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds
        let visibleSize = scrollView.contentView.bounds.size
        documentView.frame = NSRect(
            origin: .zero,
            size: NSSize(
                width: max(visibleSize.width, bounds.width),
                height: documentView.preferredHeight
            )
        )
        documentView.needsLayout = true
    }

    private func setup() {
        guard !didInstall else { return }
        didInstall = true
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.documentView = documentView
        addSubview(scrollView)
    }

    private func scrollResultToCenter(_ id: URL) {
        guard let frame = documentView.frameForResult(id) else { return }
        let visibleBounds = scrollView.contentView.bounds
        let maxY = max(0, documentView.bounds.height - visibleBounds.height)
        let targetY = min(max(0, frame.midY - visibleBounds.height / 2), maxY)
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}

final class QuickSearchResultListDocumentView: NSView {
    private var rowViews: [QuickSearchResultRowView] = []
    private var rowIDs: [URL] = []
    private var rowHeight: CGFloat = 74
    private let rowSpacing: CGFloat = 2
    private let horizontalInset: CGFloat = 10
    private let verticalInset: CGFloat = 10

    override var isFlipped: Bool { true }

    var preferredHeight: CGFloat {
        verticalInset * 2
            + CGFloat(rowViews.count) * rowHeight
            + CGFloat(max(0, rowViews.count - 1)) * rowSpacing
    }

    func update(
        results: [QuickSearchResult],
        selectedID: URL?,
        rowHeight: CGFloat,
        isDarkMode: Bool,
        onHover: @escaping (QuickSearchResult) -> Void,
        onLaunch: @escaping (QuickSearchResult) -> Void
    ) {
        self.rowHeight = rowHeight
        let nextIDs = results.map(\.id)
        if nextIDs != rowIDs {
            rebuildRows(for: results)
            rowIDs = nextIDs
        }

        for (index, row) in rowViews.enumerated() {
            guard index < results.count else { continue }
            row.configure(
                result: results[index],
                isSelected: results[index].id == selectedID,
                isDarkMode: isDarkMode,
                onHover: onHover,
                onLaunch: onLaunch
            )
        }
        needsLayout = true
    }

    func frameForResult(_ id: URL) -> NSRect? {
        guard let index = rowIDs.firstIndex(of: id),
              index < rowViews.count
        else { return nil }
        return rowViews[index].frame
    }

    override func layout() {
        super.layout()
        let width = max(0, bounds.width - horizontalInset * 2)
        var y = verticalInset
        for row in rowViews {
            row.frame = NSRect(x: horizontalInset, y: y, width: width, height: rowHeight)
            y += rowHeight + rowSpacing
        }
    }

    private func rebuildRows(for results: [QuickSearchResult]) {
        rowViews.forEach { $0.removeFromSuperview() }
        rowViews = results.map { _ in
            let row = QuickSearchResultRowView()
            addSubview(row)
            return row
        }
    }
}

final class QuickSearchResultRowView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let tagBackgroundView = NSView()
    private let tagLabel = NSTextField(labelWithString: "")
    private var trackingAreaRef: NSTrackingArea?
    private var result: QuickSearchResult?
    private var isSelected = false
    private var isDarkMode = false
    private var onHover: (QuickSearchResult) -> Void = { _ in }
    private var onLaunch: (QuickSearchResult) -> Void = { _ in }

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(
        result: QuickSearchResult,
        isSelected: Bool,
        isDarkMode: Bool,
        onHover: @escaping (QuickSearchResult) -> Void,
        onLaunch: @escaping (QuickSearchResult) -> Void
    ) {
        self.result = result
        self.isSelected = isSelected
        self.isDarkMode = isDarkMode
        self.onHover = onHover
        self.onLaunch = onLaunch

        iconView.image = result.app.icon
        titleLabel.stringValue = result.app.displayName
        detailLabel.stringValue = detailText(for: result) ?? ""
        detailLabel.isHidden = detailLabel.stringValue.isEmpty
        tagLabel.stringValue = rightTagName(for: result) ?? ""
        tagBackgroundView.isHidden = tagLabel.stringValue.isEmpty
        setAccessibilityLabel(accessibilityText(for: result))
        updateColors()
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let iconSize: CGFloat = 46
        let iconX: CGFloat = 18
        iconView.frame = NSRect(
            x: iconX,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )

        let tagMaxWidth: CGFloat = 128
        let tagHeight: CGFloat = 32
        let trailingInset: CGFloat = 18
        var tagFrame = NSRect.zero
        if !tagBackgroundView.isHidden {
            let labelWidth = min(tagMaxWidth - 24, max(22, tagLabel.intrinsicContentSize.width))
            let tagWidth = min(tagMaxWidth, labelWidth + 24)
            tagFrame = NSRect(
                x: bounds.width - trailingInset - tagWidth,
                y: (bounds.height - tagHeight) / 2,
                width: tagWidth,
                height: tagHeight
            )
            tagBackgroundView.frame = tagFrame
            tagLabel.frame = NSRect(x: 12, y: 6, width: tagWidth - 24, height: 20)
        }

        let textX = iconX + iconSize + 16
        let textRight = tagBackgroundView.isHidden ? bounds.width - trailingInset : tagFrame.minX - 16
        let textWidth = max(40, textRight - textX)
        if detailLabel.isHidden {
            titleLabel.frame = NSRect(x: textX, y: (bounds.height - 26) / 2, width: textWidth, height: 26)
            detailLabel.frame = .zero
        } else {
            titleLabel.frame = NSRect(x: textX, y: 14, width: textWidth, height: 25)
            detailLabel.frame = NSRect(x: textX, y: 42, width: textWidth, height: 21)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if let result {
            onHover(result)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if let result {
            DispatchQueue.main.async { [onLaunch] in
                onLaunch(result)
            }
        } else {
            super.mouseDown(with: event)
        }
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 18
        layer?.cornerCurve = .continuous

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = 10
        iconView.layer?.cornerCurve = .continuous
        iconView.layer?.masksToBounds = true
        addSubview(iconView)

        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        titleLabel.backgroundColor = .clear
        addSubview(titleLabel)

        detailLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.maximumNumberOfLines = 1
        detailLabel.backgroundColor = .clear
        addSubview(detailLabel)

        tagBackgroundView.wantsLayer = true
        tagBackgroundView.layer?.cornerRadius = 16
        tagBackgroundView.layer?.cornerCurve = .continuous
        tagBackgroundView.addSubview(tagLabel)
        addSubview(tagBackgroundView)

        tagLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        tagLabel.alignment = .center
        tagLabel.lineBreakMode = .byTruncatingTail
        tagLabel.maximumNumberOfLines = 1
        tagLabel.backgroundColor = .clear
    }

    private func updateColors() {
        layer?.backgroundColor = isSelected
            ? NSColor.labelColor.withAlphaComponent(isDarkMode ? 0.14 : 0.075).cgColor
            : NSColor.clear.cgColor
        titleLabel.textColor = .labelColor
        detailLabel.textColor = NSColor.labelColor.withAlphaComponent(0.38)
        tagLabel.textColor = NSColor.labelColor.withAlphaComponent(0.46)
        tagBackgroundView.layer?.backgroundColor = NSColor.labelColor
            .withAlphaComponent(isDarkMode ? 0.12 : 0.07)
            .cgColor
    }

    private func detailText(for result: QuickSearchResult) -> String? {
        if let note = result.noteSnippet, !note.isEmpty {
            return note
        }
        let note = result.document.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty {
            return note.count > 72 ? String(note.prefix(69)) + "..." : note
        }
        return nil
    }

    private func rightTagName(for result: QuickSearchResult) -> String? {
        let tag = result.matchedTagName ?? result.document.tagNames.first
        guard let tag, !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return tag
    }

    private func accessibilityText(for result: QuickSearchResult) -> String {
        [result.app.displayName, detailText(for: result)].compactMap { $0 }.joined(separator: ", ")
    }
}

private struct QuickSearchMessageRow: View {
    let systemImage: String
    let message: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(minHeight: 86)
        .accessibilityLabel(message)
    }
}

private struct QuickSearchTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let focusToken: Int
    let onCommand: (QuickSearchCommand) -> Void

    func makeNSView(context: Context) -> QuickSearchNativeTextField {
        let field = QuickSearchNativeTextField()
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = NSFont.systemFont(ofSize: 28, weight: .regular)
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.onCommand = onCommand
        context.coordinator.onCommand = onCommand
        field.setAccessibilityLabel(tr("quickSearch.inputAccessibility"))
        context.coordinator.field = field
        requestFocus(field)
        return field
    }

    func updateNSView(_ field: QuickSearchNativeTextField, context: Context) {
        if field.stringValue != text {
            field.stringValue = text
        }
        field.placeholderString = placeholder
        field.onCommand = onCommand
        context.coordinator.onCommand = onCommand
        if context.coordinator.lastFocusToken != focusToken {
            context.coordinator.lastFocusToken = focusToken
            requestFocus(field)
        }
    }

    private func requestFocus(_ field: QuickSearchNativeTextField) {
        for delay in [0.0, 0.03, 0.08, 0.16] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak field] in
                guard let field,
                      let window = field.window,
                      window.isVisible,
                      window.firstResponder !== field
                else { return }
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                window.makeFirstResponder(field)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var lastFocusToken = 0
        var onCommand: ((QuickSearchCommand) -> Void)?
        weak var field: NSTextField?

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.moveUp(_:)):
                onCommand?(.moveUp)
                return true
            case #selector(NSResponder.moveDown(_:)):
                onCommand?(.moveDown)
                return true
            case #selector(NSResponder.insertNewline(_:)):
                onCommand?(.submit)
                return true
            case #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
                onCommand?(.submit)
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                onCommand?(.dismiss)
                return true
            default:
                return false
            }
        }
    }
}

private final class QuickSearchNativeTextField: NSTextField {
    var onCommand: ((QuickSearchCommand) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_UpArrow:
            onCommand?(.moveUp)
        case kVK_DownArrow:
            onCommand?(.moveDown)
        case kVK_Return:
            onCommand?(.submit)
        case kVK_Escape:
            onCommand?(.dismiss)
        default:
            super.keyDown(with: event)
        }
    }
}
