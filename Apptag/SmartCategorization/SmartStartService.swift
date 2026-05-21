import Compression
import Foundation

// MARK: - Smart Start Catalog Runtime

struct SmartStartSummary: Equatable {
    let matchedAppCount: Int
    let assignedTagCount: Int
    let createdTagCount: Int
    let backupPath: String?
}

enum SmartStartRunMode: Equatable {
    case none
    case autoApplied
    case suggestionOnly
}

struct SmartStartRunResult {
    let mode: SmartStartRunMode
    let store: TagDatabase.Store
    let draft: SmartCategorizationDraft?
    let summary: SmartStartSummary?
}

private struct SmartStartCatalogEntry {
    let entryID: String
    let rank: Int
    let name: String
    let normalizedName: String
    let bundleIdentifier: String?
    let categoryIDs: [SmartCategoryID]
    let localizedNote: SmartStartLocalizedNote?
    let sourceEvidence: [String]
}

private struct SmartStartLocalizedNote {
    let note: String
    let languageCode: String
    let provenance: SmartDefaultNoteProvenance
}

private struct SmartStartBaseCatalog: Decodable {
    let resourceFormatVersion: Int
    let catalogContentVersion: Int
    let noteLimit: Int?
    let supportedLanguages: [String]
    let fallbackLanguages: [String]
    let entries: [SmartStartBaseCatalogEntry]
}

private struct SmartStartBaseCatalogEntry: Decodable {
    let entryID: String
    let rank: Int?
    let name: String
    let normalizedName: String?
    let bundleIdentifier: String?
    let defaultTag: [String]
    let sourceEvidence: [String]?
}

private struct SmartStartNotesCatalog: Decodable {
    let resourceFormatVersion: Int
    let catalogContentVersion: Int
    let notesVersion: Int
    let language: String
    let entries: [SmartStartNoteEntry]
}

private struct SmartStartNoteEntry: Decodable {
    let entryID: String
    let note: String
}

private struct SmartStartBaseSnapshot {
    let catalogContentVersion: Int
    let supportedLanguages: [String]
    let fallbackLanguages: [String]
    let entries: [SmartStartBaseCatalogEntry]
    let bundleIndex: [String: SmartStartBaseCatalogEntry]
    let nameIndex: [String: SmartStartBaseCatalogEntry]
    let entryIndex: [String: SmartStartBaseCatalogEntry]
}

private struct SmartStartNotesSnapshot {
    let languageCode: String
    let notesVersion: Int
    let notes: [String: String]
}

private struct SmartStartCatalogSnapshot {
    let entries: [SmartStartCatalogEntry]
    let bundleIndex: [String: SmartStartCatalogEntry]
    let nameIndex: [String: SmartStartCatalogEntry]
    let entryIndex: [String: SmartStartCatalogEntry]
}

enum SmartStartService {
    static let catalogVersion = 2
    private static let catalogCacheLock = NSLock()
    private static var cachedBaseSnapshot: SmartStartBaseSnapshot?
    private static var cachedCatalogSnapshots: [String: SmartStartCatalogSnapshot] = [:]
    private static var cachedNotesSnapshots: [String: SmartStartNotesSnapshot] = [:]

    static let systemInitialSchemeCreatedAt: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Asia/Hong_Kong")
        components.year = 2026
        components.month = 5
        components.day = 18
        components.hour = 0
        components.minute = 0
        components.second = 0
        return components.date ?? Date(timeIntervalSince1970: 0)
    }()

    static var systemInitialSchemeName: String {
        TagDatabase.schemeName(prefixKey: "scheme.systemSmartStart", at: systemInitialSchemeCreatedAt)
    }

    static func runIfNeeded(
        apps: [AppInfo],
        store initialStore: TagDatabase.Store
    ) -> SmartStartRunResult {
        guard shouldRun(for: initialStore) else {
            return SmartStartRunResult(mode: .none, store: initialStore, draft: nil, summary: nil)
        }

        let draft = makeDraft(apps: apps)
        guard !draft.assignments.isEmpty else {
            var store = initialStore
            store.smartStart.catalogVersion = catalogVersion
            store.smartStart.lastRunAt = Date()
            store.smartStart.lastMode = "no_matches"
            TagDatabase.save(store)
            return SmartStartRunResult(mode: .none, store: store, draft: nil, summary: nil)
        }

        if shouldAutoApply(to: initialStore) {
            let applied = applyDraft(draft, to: initialStore, mode: "auto_applied")
            return SmartStartRunResult(
                mode: .autoApplied,
                store: applied.store,
                draft: draft,
                summary: applied.summary
            )
        }

        var store = initialStore
        store.smartStart.catalogVersion = catalogVersion
        store.smartStart.lastRunAt = Date()
        store.smartStart.lastSuggestionAt = Date()
        store.smartStart.lastMode = "suggestion_only"
        store.smartStart.lastMatchedAppCount = draft.assignments.count
        store.smartStart.lastAssignedTagCount = draft.assignments.reduce(0) { $0 + $1.categoryIDs.count }
        TagDatabase.save(store)

        let summary = SmartStartSummary(
            matchedAppCount: draft.assignments.count,
            assignedTagCount: draft.assignments.reduce(0) { $0 + $1.categoryIDs.count },
            createdTagCount: 0,
            backupPath: nil
        )

        return SmartStartRunResult(mode: .suggestionOnly, store: store, draft: draft, summary: summary)
    }

    static func applySuggestion(_ draft: SmartCategorizationDraft) -> SmartStartRunResult {
        let applied = applyDraft(draft, to: TagDatabase.load(), mode: "manual_applied")
        return SmartStartRunResult(
            mode: .autoApplied,
            store: applied.store,
            draft: draft,
            summary: applied.summary
        )
    }

    static func applySystemInitialScheme(apps: [AppInfo]) -> SmartStartRunResult {
        let draft = makeDraft(apps: apps)
        guard !draft.assignments.isEmpty else {
            return SmartStartRunResult(mode: .none, store: TagDatabase.load(), draft: draft, summary: nil)
        }

        let applied = applyDraft(
            draft,
            to: TagDatabase.loadWithEnsuredCategoryScheme(),
            mode: "settings_system_applied",
            replaceExistingScheme: true
        )
        return SmartStartRunResult(
            mode: .autoApplied,
            store: applied.store,
            draft: draft,
            summary: applied.summary
        )
    }

    @discardableResult
    static func relocalizeDefaultNotesForCurrentLanguage(apps: [AppInfo]) -> Bool {
        let catalog = loadCatalogSnapshot()
        guard !catalog.entries.isEmpty else { return false }

        var store = TagDatabase.load()
        var changed = false
        let appPaths = Set(apps.map { $0.path.path })

        for path in appPaths {
            guard let currentNote = normalizedNote(store.appNotes[path]) else { continue }
            guard let metadata = store.appNoteMetadata[path],
                  metadata.origin == .catalogDefault,
                  let currentCatalog = metadata.catalog,
                  currentCatalog.noteFingerprint == TagDatabase.noteFingerprint(currentNote),
                  let matched = catalog.entryIndex[currentCatalog.entryID],
                  let localizedNote = matched.localizedNote,
                  localizedNote.note != currentNote
            else { continue }

            store.appNotes[path] = localizedNote.note
            store.appNoteMetadata[path] = TagDatabase.AppNoteMetadata(
                origin: .catalogDefault,
                catalog: localizedNote.provenance,
                noteFingerprint: localizedNote.provenance.noteFingerprint
            )
            changed = true
        }

        if changed {
            TagDatabase.save(store)
        }
        return changed
    }

    static func restoreBackup(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url),
              var store = try? JSONDecoder().decode(TagDatabase.Store.self, from: data)
        else { return false }

        let now = Date()
        if store.categoryScheme.currentName == nil {
            store.categoryScheme.currentName = TagDatabase.schemeName(prefixKey: "scheme.beforeSmartStart", at: now)
            store.categoryScheme.currentCreatedAt = now
        }
        store.categoryScheme.lastChangedAt = now
        store.smartStart.catalogVersion = catalogVersion
        store.smartStart.lastRunAt = now
        store.smartStart.lastMode = "restored_from_backup"
        store.smartStart.lastBackupPath = path
        TagDatabase.save(store)
        return true
    }

    static func makeDraft(apps: [AppInfo]) -> SmartCategorizationDraft {
        let catalog = loadCatalogSnapshot()

        var seenAssignments = Set<String>()
        var assignments: [SmartAppCategorizationAssignment] = []
        var unassigned: [SmartUnassignedApp] = []

        for app in apps {
            let matched = match(
                app: app,
                bundleIndex: catalog.bundleIndex,
                nameIndex: catalog.nameIndex
            )
            guard let matched else {
                unassigned.append(SmartUnassignedApp(
                    appName: app.name,
                    bundleIdentifier: app.bundleIdentifier,
                    path: app.path.path,
                    reason: "No local Smart Start catalog match"
                ))
                continue
            }

            let key = app.bundleIdentifier?.lowercased() ?? app.path.path
            guard seenAssignments.insert(key).inserted else { continue }

            assignments.append(SmartAppCategorizationAssignment(
                appName: app.name,
                bundleIdentifier: app.bundleIdentifier,
                path: app.path.path,
                categoryIDs: matched.categoryIDs,
                confidence: confidence(for: matched),
                source: .localCatalog,
                reason: "Matched Smart Start catalog entry: \(matched.name)",
                provenance: matched.sourceEvidence,
                defaultNote: matched.localizedNote?.note,
                defaultNoteCandidates: matched.localizedNote.map { [$0.note] } ?? [],
                defaultNoteProvenance: matched.localizedNote?.provenance
            ))
        }

        return SmartCategorizationDraft(
            draftSource: .localSmartStart,
            assignments: assignments.sorted {
                $0.appName.localizedStandardCompare($1.appName) == .orderedAscending
            },
            unassigned: unassigned
        )
    }

    private static func shouldRun(for store: TagDatabase.Store) -> Bool {
        store.smartStart.catalogVersion < catalogVersion
            || (store.smartStart.lastRunAt == nil
                && store.smartStart.lastAppliedAt == nil
                && store.smartStart.lastSuggestionAt == nil)
    }

    private static func shouldAutoApply(to store: TagDatabase.Store) -> Bool {
        !store.hasUserTagAssignments
    }

    private static func applyDraft(
        _ draft: SmartCategorizationDraft,
        to initialStore: TagDatabase.Store,
        mode: String,
        replaceExistingScheme: Bool = false
    ) -> (store: TagDatabase.Store, summary: SmartStartSummary) {
        var normalizedInitialStore = initialStore
        _ = TagDatabase.normalizeCategorySchemeMetadata(&normalizedInitialStore)
        var store = normalizedInitialStore
        let now = Date()
        let backupURL = TagDatabase.backup(normalizedInitialStore, reason: "smart-start-\(mode)")
        let usedCategoryIDs = orderedUsedCategoryIDs(in: draft)
        let systemCategoryIDsToCreate = replaceExistingScheme
            ? SmartCategoryDefaults.orderedIDs
            : usedCategoryIDs
        var createdTagCount = 0

        if replaceExistingScheme {
            store.tags = [:]
            store.appTags = [:]
            store.tagOrder = []
            store.disabledSystemCategoryIDs = []
        }

        for categoryID in systemCategoryIDsToCreate {
            guard replaceExistingScheme || !store.disabledSystemCategoryIDs.contains(categoryID) else {
                continue
            }
            if let result = TagDatabase.ensureSystemTag(for: categoryID, in: &store) {
                if var tagDef = store.tags[result.name] {
                    tagDef.color = categoryID.defaultColorIndex
                    store.tags[result.name] = tagDef
                }
                if result.created {
                    createdTagCount += 1
                }
                if !store.tagOrder.contains(result.name) {
                    store.tagOrder.append(result.name)
                }
            }
        }

        var assignedTagCount = 0
        var uncommonPaths = Set(store.uncommonAppPaths)
        for assignment in draft.assignments {
            guard let path = assignment.path, !path.isEmpty else { continue }
            var currentTags = store.appTags[path] ?? []
            for categoryID in assignment.categoryIDs {
                guard replaceExistingScheme || !store.disabledSystemCategoryIDs.contains(categoryID) else {
                    continue
                }
                guard let tagName = TagDatabase.systemTagName(for: categoryID, in: store) else {
                    continue
                }
                guard store.tags[tagName] != nil else { continue }
                if !currentTags.contains(tagName) {
                    currentTags.append(tagName)
                    assignedTagCount += 1
                }
            }
            if currentTags.isEmpty {
                store.appTags.removeValue(forKey: path)
            } else {
                store.appTags[path] = currentTags
            }

            if let defaultNote = assignment.defaultNote?.trimmingCharacters(in: .whitespacesAndNewlines),
               !defaultNote.isEmpty {
                let currentNote = store.appNotes[path]?.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedCurrentNote = normalizedNote(currentNote)
                let existingMetadata = store.appNoteMetadata[path]
                let currentMatchesCatalogDefault = existingMetadata?.origin == .catalogDefault
                    && normalizedCurrentNote.map { TagDatabase.noteFingerprint($0) } == existingMetadata?.catalog?.noteFingerprint
                let knownDefaultNotes = Set(assignment.defaultNoteCandidates.compactMap(normalizedNote))
                let shouldSeedNote = currentNote?.isEmpty != false
                    || currentMatchesCatalogDefault
                    || normalizedCurrentNote.map { knownDefaultNotes.contains($0) } == true

                if shouldSeedNote {
                    store.appNotes[path] = String(defaultNote.prefix(TagDatabase.maxAppNoteLength))
                    if let provenance = assignment.defaultNoteProvenance {
                        store.appNoteMetadata[path] = TagDatabase.AppNoteMetadata(
                            origin: .catalogDefault,
                            catalog: provenance,
                            noteFingerprint: provenance.noteFingerprint
                        )
                    }
                    if currentNote?.isEmpty != false {
                        uncommonPaths.insert(path)
                        if store.uncommonSources[path] == nil {
                            store.uncommonSources[path] = .auto
                        }
                    }
                }
            }
        }

        store.uncommonAppPaths = uncommonPaths.sorted()
        store.smartStart.catalogVersion = catalogVersion
        store.smartStart.lastRunAt = now
        store.smartStart.lastAppliedAt = now
        store.smartStart.lastBackupPath = backupURL?.path
        store.smartStart.lastMode = mode
        store.smartStart.lastMatchedAppCount = draft.assignments.count
        store.smartStart.lastAssignedTagCount = assignedTagCount
        store.categoryScheme.previousName = normalizedInitialStore.categoryScheme.currentName
            ?? TagDatabase.schemeName(prefixKey: "scheme.beforeSmartStart", at: now)
        store.categoryScheme.previousCreatedAt = normalizedInitialStore.categoryScheme.currentCreatedAt
        store.categoryScheme.previousBackupPath = backupURL?.path
        store.categoryScheme.currentName = replaceExistingScheme
            ? Self.systemInitialSchemeName
            : TagDatabase.schemeName(prefixKey: "scheme.smartStart", at: Self.systemInitialSchemeCreatedAt)
        store.categoryScheme.currentCreatedAt = replaceExistingScheme
            ? Self.systemInitialSchemeCreatedAt
            : Self.systemInitialSchemeCreatedAt
        store.categoryScheme.lastChangedAt = now
        TagDatabase.save(store)

        return (
            store,
            SmartStartSummary(
                matchedAppCount: draft.assignments.count,
                assignedTagCount: assignedTagCount,
                createdTagCount: createdTagCount,
                backupPath: backupURL?.path
            )
        )
    }

    private static func orderedUsedCategoryIDs(in draft: SmartCategorizationDraft) -> [SmartCategoryID] {
        let used = Set(draft.assignments.flatMap(\.categoryIDs))
        return SmartCategoryDefaults.orderedIDs.filter { used.contains($0) }
    }

    private static func match(
        app: AppInfo,
        bundleIndex: [String: SmartStartCatalogEntry],
        nameIndex: [String: SmartStartCatalogEntry]
    ) -> SmartStartCatalogEntry? {
        if let bundleIdentifier = app.bundleIdentifier?.lowercased(),
           let bundleMatch = bundleIndex[bundleIdentifier] {
            return bundleMatch
        }
        return nameIndex[normalizedName(app.name)]
    }

    private static func confidence(for entry: SmartStartCatalogEntry) -> Double {
        if entry.rank <= 300 { return 0.86 }
        if entry.categoryIDs.count > 1 { return 0.74 }
        return 0.68
    }

    private static func loadCatalogSnapshot() -> SmartStartCatalogSnapshot {
        let languageCode = L10n.currentCode
        catalogCacheLock.lock()
        if let snapshot = cachedCatalogSnapshots[languageCode] {
            catalogCacheLock.unlock()
            return snapshot
        }
        catalogCacheLock.unlock()

        guard let base = loadBaseSnapshot() else {
            return SmartStartCatalogSnapshot(entries: [], bundleIndex: [:], nameIndex: [:], entryIndex: [:])
        }
        let snapshot = makeCatalogSnapshot(base: base, languageCode: languageCode)

        catalogCacheLock.lock()
        if let cached = cachedCatalogSnapshots[languageCode] {
            catalogCacheLock.unlock()
            return cached
        }
        cachedCatalogSnapshots[languageCode] = snapshot
        catalogCacheLock.unlock()
        return snapshot
    }

    private static func makeCatalogSnapshot(
        base: SmartStartBaseSnapshot,
        languageCode: String
    ) -> SmartStartCatalogSnapshot {
        let localizedNotes = loadLocalizedNotes(
            for: languageFallbacks(preferredCode: languageCode, base: base)
        )
        let entries = base.entries.compactMap { entry -> SmartStartCatalogEntry? in
            let tagIDs = entry.defaultTag
                .compactMap { SmartCategoryID(rawValue: $0) }
                .filter { $0 != .other }
            guard !tagIDs.isEmpty else { return nil }

            return SmartStartCatalogEntry(
                entryID: entry.entryID,
                rank: entry.rank ?? Int.max,
                name: entry.name,
                normalizedName: entry.normalizedName.flatMap {
                    $0.isEmpty ? nil : $0
                } ?? normalizedName(entry.name),
                bundleIdentifier: normalizedBundleIdentifier(entry.bundleIdentifier),
                categoryIDs: uniqueOrdered(tagIDs),
                localizedNote: localizedNotes[entry.entryID],
                sourceEvidence: entry.sourceEvidence ?? []
            )
        }

        var bundleIndex: [String: SmartStartCatalogEntry] = [:]
        var nameIndex: [String: SmartStartCatalogEntry] = [:]
        var entryIndex: [String: SmartStartCatalogEntry] = [:]

        for entry in entries {
            entryIndex[entry.entryID] = entry
            if let bundleIdentifier = entry.bundleIdentifier?.lowercased(), !bundleIdentifier.isEmpty {
                if bundleIndex[bundleIdentifier].map({ $0.rank <= entry.rank }) != true {
                    bundleIndex[bundleIdentifier] = entry
                }
            }

            if nameIndex[entry.normalizedName].map({ $0.rank <= entry.rank }) != true {
                nameIndex[entry.normalizedName] = entry
            }
        }

        return SmartStartCatalogSnapshot(
            entries: entries,
            bundleIndex: bundleIndex,
            nameIndex: nameIndex,
            entryIndex: entryIndex
        )
    }

    private static func loadBaseSnapshot() -> SmartStartBaseSnapshot? {
        catalogCacheLock.lock()
        if let snapshot = cachedBaseSnapshot {
            catalogCacheLock.unlock()
            return snapshot
        }
        catalogCacheLock.unlock()

        guard let url = Bundle.main.url(
            forResource: "SmartStartUltimateDefaultCatalog.base",
            withExtension: "json"
        ),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(SmartStartBaseCatalog.self, from: data),
              catalog.resourceFormatVersion == 1
        else { return nil }

        var bundleIndex: [String: SmartStartBaseCatalogEntry] = [:]
        var nameIndex: [String: SmartStartBaseCatalogEntry] = [:]
        var entryIndex: [String: SmartStartBaseCatalogEntry] = [:]
        for entry in catalog.entries {
            entryIndex[entry.entryID] = entry
            if let bundleIdentifier = normalizedBundleIdentifier(entry.bundleIdentifier)?.lowercased(),
               !bundleIdentifier.isEmpty,
               bundleIndex[bundleIdentifier].map({ ($0.rank ?? Int.max) <= (entry.rank ?? Int.max) }) != true {
                bundleIndex[bundleIdentifier] = entry
            }
            let name = entry.normalizedName.flatMap { $0.isEmpty ? nil : $0 } ?? normalizedName(entry.name)
            if nameIndex[name].map({ ($0.rank ?? Int.max) <= (entry.rank ?? Int.max) }) != true {
                nameIndex[name] = entry
            }
        }

        let snapshot = SmartStartBaseSnapshot(
            catalogContentVersion: catalog.catalogContentVersion,
            supportedLanguages: catalog.supportedLanguages,
            fallbackLanguages: catalog.fallbackLanguages,
            entries: catalog.entries,
            bundleIndex: bundleIndex,
            nameIndex: nameIndex,
            entryIndex: entryIndex
        )

        catalogCacheLock.lock()
        if let cached = cachedBaseSnapshot {
            catalogCacheLock.unlock()
            return cached
        }
        cachedBaseSnapshot = snapshot
        catalogCacheLock.unlock()
        return snapshot
    }

    private static func loadLocalizedNotes(for languageCodes: [String]) -> [String: SmartStartLocalizedNote] {
        var result: [String: SmartStartLocalizedNote] = [:]
        for languageCode in languageCodes {
            guard let notes = loadNotesSnapshot(languageCode: languageCode) else { continue }
            for (entryID, note) in notes.notes where result[entryID] == nil {
                let fingerprint = TagDatabase.noteFingerprint(note)
                result[entryID] = SmartStartLocalizedNote(
                    note: note,
                    languageCode: notes.languageCode,
                    provenance: SmartDefaultNoteProvenance(
                        entryID: entryID,
                        languageCode: notes.languageCode,
                        notesVersion: notes.notesVersion,
                        noteFingerprint: fingerprint
                    )
                )
            }
        }
        return result
    }

    private static func loadNotesSnapshot(languageCode: String) -> SmartStartNotesSnapshot? {
        catalogCacheLock.lock()
        if let snapshot = cachedNotesSnapshots[languageCode] {
            catalogCacheLock.unlock()
            return snapshot
        }
        catalogCacheLock.unlock()

        guard let data = loadNotesCatalogData(languageCode: languageCode),
              let catalog = try? JSONDecoder().decode(SmartStartNotesCatalog.self, from: data),
              catalog.resourceFormatVersion == 1
        else { return nil }

        let notes = Dictionary(uniqueKeysWithValues: catalog.entries.compactMap { entry in
            normalizedNote(entry.note).map { (entry.entryID, $0) }
        })
        let snapshot = SmartStartNotesSnapshot(
            languageCode: catalog.language,
            notesVersion: catalog.notesVersion,
            notes: notes
        )

        catalogCacheLock.lock()
        if let cached = cachedNotesSnapshots[languageCode] {
            catalogCacheLock.unlock()
            return cached
        }
        cachedNotesSnapshots[languageCode] = snapshot
        catalogCacheLock.unlock()
        return snapshot
    }

    private static func loadNotesCatalogData(languageCode: String) -> Data? {
        let resourceName = "SmartStartUltimateDefaultCatalog.notes.\(languageCode)"

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

        let maxOutputSize = 16 * 1024 * 1024
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

    private static func languageFallbacks(
        preferredCode: String,
        base: SmartStartBaseSnapshot
    ) -> [String] {
        var codes: [String] = []
        func append(_ code: String) {
            guard !code.isEmpty,
                  base.supportedLanguages.contains(code),
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
        for code in base.fallbackLanguages {
            append(code)
        }
        append("en")
        append("zh-Hans")
        append("zh-Hant")
        return codes
    }

    private static func normalizedNote(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(TagDatabase.maxAppNoteLength))
    }

    private static func normalizedBundleIdentifier(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              !["null", "nil", "undefined"].contains(value.lowercased())
        else { return nil }
        return value
    }

    private static func uniqueOrdered(_ ids: [SmartCategoryID]) -> [SmartCategoryID] {
        var seen = Set<SmartCategoryID>()
        return ids.filter { seen.insert($0).inserted }
    }

    private static func splitPipe(_ value: String) -> [String] {
        value
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func normalizedName(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "&", with: " and ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private static func parseCSV(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var index = csv.startIndex

        while index < csv.endIndex {
            let character = csv[index]

            if quoted {
                if character == "\"" {
                    let next = csv.index(after: index)
                    if next < csv.endIndex, csv[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else {
                        quoted = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    quoted = true
                case ",":
                    row.append(field)
                    field = ""
                case "\n":
                    row.append(field)
                    rows.append(row)
                    row = []
                    field = ""
                case "\r":
                    break
                default:
                    field.append(character)
                }
            }

            index = csv.index(after: index)
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }

        return rows
    }
}
