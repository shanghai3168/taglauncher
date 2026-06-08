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
        var store = TagDatabase.load()
        var changed = false

        for app in apps where app.isAppleApp {
            let path = app.path.path
            guard let currentNote = normalizedNote(store.appNotes[path]) else { continue }
            guard let metadata = store.appNoteMetadata[path],
                  metadata.origin == .appleDefault
            else { continue }

            let currentFingerprint = TagDatabase.noteFingerprint(currentNote)
            let expectedFingerprint = metadata.apple?.noteFingerprint ?? metadata.noteFingerprint
            guard expectedFingerprint == currentFingerprint else { continue }
            guard let defaultNote = Self.defaultNote(for: app),
                  defaultNote.note != currentNote
            else { continue }

            store.appNotes[path] = defaultNote.note
            store.appNoteMetadata[path] = TagDatabase.AppNoteMetadata(
                origin: .appleDefault,
                apple: defaultNote.provenance,
                noteFingerprint: defaultNote.provenance.noteFingerprint
            )
            changed = true
        }

        if changed {
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
