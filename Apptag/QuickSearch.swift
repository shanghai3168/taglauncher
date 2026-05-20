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
    private enum FieldKind: Int {
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

    private enum MatchKind {
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

    private struct Field {
        let kind: FieldKind
        let text: String
        let normalized: String
        let acronym: String
        let pinyinCandidates: [String]
    }

    private struct MatchOptions {
        let allowSubstring: Bool
        let allowFuzzySubsequence: Bool
    }

    private struct TokenMatch {
        let score: Double
        let fieldRank: Int
        let fieldKind: FieldKind
        let originalText: String
    }

    static func makeDocuments(apps: [AppInfo], store: TagDatabase.Store) -> [QuickSearchDocument] {
        apps.map { app in
            QuickSearchDocument(
                app: app,
                localizedNames: localizedNames(for: app),
                internalBundleNames: internalBundleNames(for: app),
                tagNames: app.tags,
                note: store.appNotes[app.path.path] ?? app.note ?? "",
                bundleIdentifier: app.bundleIdentifier ?? "",
                lastOpenedAt: store.appLastOpenedAt[app.path.path],
                openCount: store.appOpenCounts[app.path.path] ?? 0
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
        let fields = searchableFields(for: document)
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

    private static func searchableFields(for document: QuickSearchDocument) -> [Field] {
        let names = uniqueOrdered([document.app.name] + document.localizedNames)
        let nameFields = names.map {
            Field(
                kind: .name,
                text: $0,
                normalized: normalizeField($0),
                acronym: acronym(for: $0),
                pinyinCandidates: pinyinCandidates(for: $0)
            )
        }
        let tagFields = document.tagNames.map {
            Field(
                kind: .tag,
                text: $0,
                normalized: normalizeField($0),
                acronym: "",
                pinyinCandidates: pinyinCandidates(for: $0)
            )
        }
        let noteFields = document.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [
            Field(
                kind: .note,
                text: document.note,
                normalized: normalizeField(document.note),
                acronym: "",
                pinyinCandidates: pinyinCandidates(for: document.note)
            )
        ]
        let bundleFields = document.bundleIdentifier.isEmpty ? [] : [
            Field(
                kind: .bundleIdentifier,
                text: document.bundleIdentifier,
                normalized: normalizeField(document.bundleIdentifier),
                acronym: "",
                pinyinCandidates: []
            )
        ]
        let internalBundleNameFields = document.internalBundleNames.map {
            Field(
                kind: .internalBundleName,
                text: $0,
                normalized: normalizeField($0),
                acronym: "",
                pinyinCandidates: []
            )
        }
        return nameFields + tagFields + noteFields + bundleFields + internalBundleNameFields
    }

    private static func match(token: String, field: Field) -> TokenMatch? {
        guard let candidate = bestMatchCandidate(token: token, field: field) else { return nil }
        let positionBoost = candidate.0 == .exact ? 0 : max(0, 10 - min(candidate.1, 10))
        let score = field.kind.weight + candidate.0.weight + Double(positionBoost)
        return TokenMatch(
            score: score,
            fieldRank: field.kind.rawValue,
            fieldKind: field.kind,
            originalText: field.text
        )
    }

    private static func bestMatchCandidate(token: String, field: Field) -> (MatchKind, Int)? {
        var candidates: [(MatchKind, Int)] = []

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
                allowSubstring: field.kind == .note
            ) {
                candidates.append(pinyinCandidate)
            }
        }

        return candidates.max { lhs, rhs in
            if lhs.0.weight != rhs.0.weight { return lhs.0.weight < rhs.0.weight }
            return lhs.1 > rhs.1
        }
    }

    private static func matchOptions(for fieldKind: FieldKind) -> MatchOptions {
        switch fieldKind {
        case .name:
            return MatchOptions(allowSubstring: true, allowFuzzySubsequence: true)
        case .tag:
            return MatchOptions(allowSubstring: true, allowFuzzySubsequence: true)
        case .note:
            return MatchOptions(allowSubstring: true, allowFuzzySubsequence: true)
        case .bundleIdentifier, .internalBundleName:
            return MatchOptions(allowSubstring: false, allowFuzzySubsequence: false)
        }
    }

    private static func matchCandidate(
        token: String,
        normalized: String,
        options: MatchOptions
    ) -> (MatchKind, Int)? {
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
        allowSubstring: Bool = false
    ) -> (MatchKind, Int)? {
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

    private static func pinyinCandidates(for value: String) -> [String] {
        guard value.range(of: #"\p{Han}"#, options: .regularExpression) != nil else { return [] }
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

struct QuickSearchOverlayView: View {
    @Binding var query: String
    let results: [QuickSearchResult]
    let selectedID: URL?
    let focusToken: Int
    let isLoading: Bool
    let maxVisibleRows: Int
    let errorMessage: String?
    let onCommand: (QuickSearchCommand) -> Void
    let onHover: (QuickSearchResult) -> Void
    let onLaunch: (QuickSearchResult) -> Void

    private let panelWidth: CGFloat = 760
    private let rowHeight: CGFloat = 74

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
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(tr("quickSearch.loading"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(minHeight: 86)
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
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: results.count > maxVisibleRows) {
                        LazyVStack(spacing: 2) {
                            ForEach(results) { result in
                                QuickSearchResultRow(
                                    result: result,
                                    isSelected: result.id == selectedID
                                )
                                .frame(height: rowHeight)
                                .id(result.id)
                                .contentShape(Rectangle())
                                .onHover { hovering in
                                    if hovering { onHover(result) }
                                }
                                .onTapGesture {
                                    onLaunch(result)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                    }
                    .frame(height: CGFloat(min(results.count, maxVisibleRows)) * (rowHeight + 2) + 20)
                    .onChange(of: selectedID) { _, id in
                        guard let id else { return }
                        withAnimation(.easeOut(duration: 0.08)) {
                            scrollProxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: panelWidth)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 36, y: 18)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(tr("quickSearch.title"))
    }
}

private struct QuickSearchResultRow: View {
    let result: QuickSearchResult
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            Image(nsImage: result.app.icon)
                .resizable()
                .frame(width: 46, height: 46)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.app.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let detailText {
                    Text(detailText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.primary.opacity(0.38))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            if let tagName = rightTagName {
                Text(tagName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.46))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .frame(maxWidth: 128)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.07))
                    )
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? selectedFill : Color.clear)
        )
        .accessibilityLabel(accessibilityText)
    }

    private var selectedFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.075)
    }

    private var detailText: String? {
        if let note = result.noteSnippet, !note.isEmpty {
            return note
        }
        let note = result.document.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty {
            return note.count > 72 ? String(note.prefix(69)) + "..." : note
        }
        return nil
    }

    private var rightTagName: String? {
        let tag = result.matchedTagName ?? result.document.tagNames.first
        guard let tag, !tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return tag
    }

    private var accessibilityText: String {
        [result.app.name, detailText].compactMap { $0 }.joined(separator: ", ")
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
        field.setAccessibilityLabel(tr("quickSearch.inputAccessibility"))
        context.coordinator.field = field
        DispatchQueue.main.async {
            field.window?.makeFirstResponder(field)
        }
        return field
    }

    func updateNSView(_ field: QuickSearchNativeTextField, context: Context) {
        if field.stringValue != text {
            field.stringValue = text
        }
        field.placeholderString = placeholder
        field.onCommand = onCommand
        if context.coordinator.lastFocusToken != focusToken {
            context.coordinator.lastFocusToken = focusToken
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var lastFocusToken = 0
        weak var field: NSTextField?

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
        }
    }
}

private final class QuickSearchNativeTextField: NSTextField {
    var onCommand: ((QuickSearchCommand) -> Void)?

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
