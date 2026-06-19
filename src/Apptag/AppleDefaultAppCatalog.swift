import Compression
import Foundation

struct AppleDefaultCategorization {
    let canonicalName: String
    let categoryIDs: [SmartCategoryID]
    let provenance: [String]
}

enum AppleDefaultAppCatalog {
    private struct BaseCatalog: Decodable {
        let resourceFormatVersion: Int
        let catalogContentVersion: Int
        let noteLimit: Int?
        let supportedLanguages: [String]
        let entries: [BaseEntry]
    }

    private struct BaseEntry: Decodable {
        let bundleIdentifier: String
        let normalizedName: String
        let canonicalName: String
        let defaultTag: [String]
        let familiar: Bool
        let aliases: [String]?
    }

    private struct LocalizationCatalog: Decodable {
        let resourceFormatVersion: Int
        let catalogContentVersion: Int
        let language: String
        let localizationsVersion: Int
        let entries: [LocalizationEntry]
    }

    private struct LocalizationEntry: Decodable {
        let bundleIdentifier: String
        let displayName: String
        let note: String
    }

    private struct BaseSnapshot {
        let catalogContentVersion: Int
        let noteLimit: Int
        let supportedLanguages: [String]
        let byBundleIdentifier: [String: BaseEntry]
    }

    private struct LocalizationSnapshot {
        let languageCode: String
        let localizationsVersion: Int
        let displayNames: [String: String]
        let notes: [String: String]
    }

    private struct LocalizedNote {
        let note: String
        let provenance: SmartDefaultNoteProvenance
    }

    private static let cacheLock = NSLock()
    private static var cachedBaseSnapshot: BaseSnapshot?
    private static var cachedLocalizationSnapshots: [String: LocalizationSnapshot] = [:]
    private static let legacyDefaultNoteFingerprintsByBundleIdentifier: [String: Set<String>] = [
        "com.apple.chess": [
            "9f72f1448c7e9b47",
            "a3b754a4f06eee33",
            "abc8528f6a2ca356"
        ],
        "com.apple.freeform": [
            "32fee0886cf2c6bb",
            "503c25567e9640c2",
            "aee5e9a7730252f7"
        ],
        "com.apple.home": [
            "003e996159a187cc",
            "2707ce5206adfb2a",
            "5b0207586af532a9"
        ],
        "com.apple.music": [
            "545fa7c8a0d216fa",
            "8867798c868c8c30",
            "bce11863b08fac8b"
        ],
        "com.apple.passwords": [
            "58b38191593ec9b9",
            "a72f91e414c90254",
            "fa1ce5e1bb5998cd"
        ],
        "com.apple.mobilephone": [
            "703bd99a660e80e4",
            "80d0df54c7ddf2d1",
            "9d57741d3114a1a2"
        ],
        "com.apple.tv": [
            "6a29d8ece97cd432",
            "e1efb690bf1c6b94",
            "e28785e11f914401"
        ],
        "com.apple.backup.launcher": [
            "78edffa39f28cee2",
            "cbf81a2b5e77725b",
            "dc568bb30164e897"
        ],
        "com.apple.diskutility": [
            "77324bc5de72e176",
            "c43f8e117573f5ed",
            "fd581938fd34e888"
        ],
        "com.apple.screencontinuity": [
            "171a629bd17970fa",
            "2965e73ff5566d19",
            "bb4662c4f15ab83c"
        ]
    ]

    static func isKnownAppleApp(_ app: AppInfo) -> Bool {
        entry(for: app) != nil
    }

    static func isFamiliarAppleApp(_ app: AppInfo) -> Bool {
        entry(for: app)?.familiar ?? false
    }

    static func categorization(for app: AppInfo) -> AppleDefaultCategorization? {
        guard let entry = entry(for: app) else { return nil }
        let categoryIDs = entry.defaultTag
            .compactMap { SmartCategoryID(rawValue: $0) }
            .filter { $0 != .other }
        guard !categoryIDs.isEmpty else { return nil }
        return AppleDefaultCategorization(
            canonicalName: entry.canonicalName,
            categoryIDs: uniqueOrdered(categoryIDs),
            provenance: ["apple_default_app_catalog"]
        )
    }

    static func localizedNamesByLanguage(forBundleIdentifier bundleIdentifier: String?) -> [String: String] {
        guard let bundleIdentifier = normalizedBundleIdentifier(bundleIdentifier),
              let base = loadBaseSnapshot(),
              base.byBundleIdentifier[bundleIdentifier] != nil
        else { return [:] }

        var result: [String: String] = [:]
        for languageCode in base.supportedLanguages {
            guard let snapshot = loadLocalizationSnapshot(languageCode: languageCode),
                  let displayName = normalizedText(snapshot.displayNames[bundleIdentifier])
            else { continue }
            result[languageCode] = displayName
        }
        return result
    }

    static func defaultNote(for app: AppInfo) -> (note: String, provenance: SmartDefaultNoteProvenance)? {
        guard let bundleIdentifier = normalizedBundleIdentifier(app.bundleIdentifier),
              let localizedNote = localizedNote(forBundleIdentifier: bundleIdentifier)
        else { return nil }
        return (localizedNote.note, localizedNote.provenance)
    }

    @discardableResult
    static func relocalizeDefaultNotesForCurrentLanguage(apps: [AppInfo]) -> Bool {
        guard let base = loadBaseSnapshot() else { return false }

        var store = TagDatabase.load()
        let originalStore = store
        var changed = false
        var adoptedLegacyDefaultNote = false

        for app in apps where app.isAppleApp {
            let path = app.path.path
            guard let bundleIdentifier = normalizedBundleIdentifier(app.bundleIdentifier),
                  base.byBundleIdentifier[bundleIdentifier] != nil,
                  let currentNote = normalizedNote(store.appNotes[path], limit: base.noteLimit),
                  let localizedNote = localizedNote(forBundleIdentifier: bundleIdentifier)
            else { continue }

            let metadata = store.appNoteMetadata[path]
            if metadata?.origin == .manual {
                continue
            }

            let currentFingerprint = TagDatabase.noteFingerprint(currentNote)
            let matchesKnownAppleDefault = noteMatchesKnownDefault(
                currentNote,
                forBundleIdentifier: bundleIdentifier,
                base: base
            )

            let canRelocalize: Bool
            switch metadata?.origin {
            case .some(.manual):
                canRelocalize = false
            case .some(.appleDefault):
                let expectedFingerprint = metadata?.apple?.noteFingerprint ?? metadata?.noteFingerprint
                canRelocalize = expectedFingerprint == currentFingerprint || matchesKnownAppleDefault
                if expectedFingerprint != currentFingerprint && matchesKnownAppleDefault {
                    adoptedLegacyDefaultNote = true
                }
            case .some(.catalogDefault):
                canRelocalize = matchesKnownAppleDefault
                if canRelocalize {
                    adoptedLegacyDefaultNote = true
                }
            case .none:
                canRelocalize = matchesKnownAppleDefault
                if canRelocalize {
                    adoptedLegacyDefaultNote = true
                }
            }

            guard canRelocalize else { continue }

            let metadataMatchesLocalizedNote = metadata?.origin == .appleDefault
                && metadata?.apple?.entryID == localizedNote.provenance.entryID
                && metadata?.apple?.languageCode == localizedNote.provenance.languageCode
                && metadata?.apple?.notesVersion == localizedNote.provenance.notesVersion
                && metadata?.apple?.noteFingerprint == localizedNote.provenance.noteFingerprint
                && metadata?.noteFingerprint == localizedNote.provenance.noteFingerprint
            guard localizedNote.note != currentNote || !metadataMatchesLocalizedNote else { continue }

            store.appNotes[path] = localizedNote.note
            store.appNoteMetadata[path] = TagDatabase.AppNoteMetadata(
                origin: .appleDefault,
                apple: localizedNote.provenance,
                noteFingerprint: localizedNote.provenance.noteFingerprint
            )
            changed = true
        }

        if changed {
            if adoptedLegacyDefaultNote {
                _ = TagDatabase.backup(originalStore, reason: "apple-default-note-migration")
            }
            TagDatabase.save(store)
        }
        return changed
    }

    private static func entry(for app: AppInfo) -> BaseEntry? {
        guard app.isAppleApp,
              let bundleIdentifier = normalizedBundleIdentifier(app.bundleIdentifier),
              let base = loadBaseSnapshot()
        else { return nil }
        return base.byBundleIdentifier[bundleIdentifier]
    }

    private static func localizedNote(forBundleIdentifier bundleIdentifier: String) -> LocalizedNote? {
        guard let base = loadBaseSnapshot() else { return nil }
        for languageCode in languageFallbacks(preferredCode: L10n.currentCode, supportedLanguages: base.supportedLanguages) {
            guard let snapshot = loadLocalizationSnapshot(languageCode: languageCode),
                  let note = normalizedNote(snapshot.notes[bundleIdentifier], limit: base.noteLimit)
            else { continue }
            let fingerprint = TagDatabase.noteFingerprint(note)
            return LocalizedNote(
                note: note,
                provenance: SmartDefaultNoteProvenance(
                    entryID: bundleIdentifier,
                    languageCode: snapshot.languageCode,
                    notesVersion: snapshot.localizationsVersion,
                    noteFingerprint: fingerprint
                )
            )
        }
        return nil
    }

    private static func noteMatchesKnownDefault(
        _ note: String,
        forBundleIdentifier bundleIdentifier: String,
        base: BaseSnapshot
    ) -> Bool {
        let fingerprint = TagDatabase.noteFingerprint(note)
        return knownDefaultNoteFingerprints(
            forBundleIdentifier: bundleIdentifier,
            base: base
        ).contains(fingerprint)
    }

    private static func knownDefaultNoteFingerprints(
        forBundleIdentifier bundleIdentifier: String,
        base: BaseSnapshot
    ) -> Set<String> {
        var result = Set<String>()
        for languageCode in base.supportedLanguages {
            guard let snapshot = loadLocalizationSnapshot(languageCode: languageCode),
                  let note = normalizedNote(snapshot.notes[bundleIdentifier], limit: base.noteLimit)
            else { continue }
            for variant in legacyDefaultNoteVariants(note, limit: base.noteLimit) {
                result.insert(TagDatabase.noteFingerprint(variant))
            }
        }
        result.formUnion(legacyDefaultNoteFingerprintsByBundleIdentifier[bundleIdentifier] ?? [])
        return result
    }

    private static func legacyDefaultNoteVariants(_ note: String, limit: Int) -> [String] {
        let trimmed = String(note.trimmingCharacters(in: .whitespacesAndNewlines).prefix(limit))
        guard !trimmed.isEmpty else { return [] }

        var variants = [trimmed]
        let stripped = noteByRemovingTrailingSentencePunctuation(trimmed)
        if stripped != trimmed {
            variants.append(stripped)
        }

        for suffix in [".", "。"] {
            let punctuated = String((stripped + suffix).prefix(limit))
            if !punctuated.isEmpty {
                variants.append(punctuated)
            }
        }

        var seen = Set<String>()
        return variants.filter { seen.insert($0).inserted }
    }

    private static func noteByRemovingTrailingSentencePunctuation(_ value: String) -> String {
        var result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let punctuation = CharacterSet(charactersIn: ".。．!！?？")
        while let scalar = result.unicodeScalars.last,
              punctuation.contains(scalar) {
            result.removeLast()
        }
        return result
    }

    private static func loadBaseSnapshot() -> BaseSnapshot? {
        cacheLock.lock()
        if let snapshot = cachedBaseSnapshot {
            cacheLock.unlock()
            return snapshot
        }
        cacheLock.unlock()

        guard let url = Bundle.main.url(forResource: "AppleDefaultApps.base", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(BaseCatalog.self, from: data),
              catalog.resourceFormatVersion == 1
        else { return nil }

        var byBundleIdentifier: [String: BaseEntry] = [:]
        for entry in catalog.entries {
            guard let bundleIdentifier = normalizedBundleIdentifier(entry.bundleIdentifier) else { continue }
            byBundleIdentifier[bundleIdentifier] = entry
        }
        let snapshot = BaseSnapshot(
            catalogContentVersion: catalog.catalogContentVersion,
            noteLimit: catalog.noteLimit ?? TagDatabase.maxAppNoteLength,
            supportedLanguages: catalog.supportedLanguages,
            byBundleIdentifier: byBundleIdentifier
        )

        cacheLock.lock()
        if let cached = cachedBaseSnapshot {
            cacheLock.unlock()
            return cached
        }
        cachedBaseSnapshot = snapshot
        cacheLock.unlock()
        return snapshot
    }

    private static func loadLocalizationSnapshot(languageCode: String) -> LocalizationSnapshot? {
        cacheLock.lock()
        if let snapshot = cachedLocalizationSnapshots[languageCode] {
            cacheLock.unlock()
            return snapshot
        }
        cacheLock.unlock()

        guard let data = loadLocalizationData(languageCode: languageCode),
              let catalog = try? JSONDecoder().decode(LocalizationCatalog.self, from: data),
              catalog.resourceFormatVersion == 1
        else { return nil }

        let displayNames: [String: String] = Dictionary(uniqueKeysWithValues: catalog.entries.compactMap { entry in
            guard let bundleIdentifier = normalizedBundleIdentifier(entry.bundleIdentifier),
                  let displayName = normalizedText(entry.displayName)
            else { return nil }
            return (bundleIdentifier, displayName)
        })
        let notes: [String: String] = Dictionary(uniqueKeysWithValues: catalog.entries.compactMap { entry in
            guard let bundleIdentifier = normalizedBundleIdentifier(entry.bundleIdentifier),
                  let note = normalizedNote(entry.note)
            else { return nil }
            return (bundleIdentifier, note)
        })
        let snapshot = LocalizationSnapshot(
            languageCode: catalog.language,
            localizationsVersion: catalog.localizationsVersion,
            displayNames: displayNames,
            notes: notes
        )

        cacheLock.lock()
        if let cached = cachedLocalizationSnapshots[languageCode] {
            cacheLock.unlock()
            return cached
        }
        cachedLocalizationSnapshots[languageCode] = snapshot
        cacheLock.unlock()
        return snapshot
    }

    private static func loadLocalizationData(languageCode: String) -> Data? {
        let resourceName = "AppleDefaultApps.localizations.\(languageCode)"
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "json.deflate"),
           let compressedData = try? Data(contentsOf: url),
           let data = inflatedDeflateData(from: compressedData) {
            return data
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    private static func inflatedDeflateData(from compressedData: Data) -> Data? {
        guard !compressedData.isEmpty else { return Data() }
        let maxOutputSize = 2 * 1024 * 1024
        var outputSize = max(compressedData.count * 8, 64 * 1024)

        while outputSize <= maxOutputSize {
            let decoded = compressedData.withUnsafeBytes { sourceBuffer -> Data? in
                guard let sourcePointer = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else {
                    return nil
                }

                let destinationPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: outputSize)
                defer { destinationPointer.deallocate() }

                let decodedCount = compression_decode_buffer(
                    destinationPointer,
                    outputSize,
                    sourcePointer,
                    compressedData.count,
                    nil,
                    COMPRESSION_ZLIB
                )

                guard decodedCount > 0 else { return nil }
                return Data(bytes: destinationPointer, count: decodedCount)
            }

            if let decoded {
                return decoded
            }
            outputSize *= 2
        }

        return nil
    }

    private static func languageFallbacks(preferredCode: String, supportedLanguages: [String]) -> [String] {
        var codes: [String] = []
        func append(_ code: String) {
            guard !code.isEmpty,
                  supportedLanguages.contains(code),
                  !codes.contains(code)
            else { return }
            codes.append(code)
        }

        append(preferredCode)
        switch preferredCode {
        case "ar-Najdi":
            append("ar")
        case "nn":
            append("nb")
            append("no")
        case "no":
            append("nb")
            append("nn")
        case "nb":
            append("no")
            append("nn")
        default:
            break
        }
        append("en")
        append("zh-Hans")
        append("zh-Hant")
        return codes
    }

    private static func normalizedBundleIdentifier(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              !["null", "nil", "undefined"].contains(value.lowercased())
        else { return nil }
        return value.lowercased()
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedNote(_ value: String?, limit: Int = TagDatabase.maxAppNoteLength) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(limit))
    }

    private static func uniqueOrdered(_ ids: [SmartCategoryID]) -> [SmartCategoryID] {
        var seen = Set<SmartCategoryID>()
        return ids.filter { seen.insert($0).inserted }
    }
}
