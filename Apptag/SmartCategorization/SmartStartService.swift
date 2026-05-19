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
    let rank: Int
    let name: String
    let normalizedName: String
    let bundleIdentifier: String?
    let categoryIDs: [SmartCategoryID]
    let localizedNote: String?
    let notes: [String: String]?
    let sourceEvidence: [String]
}

private struct SmartStartRuntimeCatalog: Decodable {
    let version: Int
    let entries: [SmartStartRuntimeCatalogEntry]
}

private struct SmartStartRuntimeCatalogEntry: Decodable {
    let rank: Int?
    let name: String
    let normalizedName: String?
    let bundleIdentifier: String?
    let defaultTag: [String]
    let notes: [String: String]?
    let sourceEvidence: [String]?
}

enum SmartStartService {
    static let catalogVersion = 2
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
        let catalog = loadCatalog()
        guard !catalog.isEmpty else { return false }

        var bundleIndex: [String: SmartStartCatalogEntry] = [:]
        for entry in catalog {
            guard let bundleIdentifier = entry.bundleIdentifier?.lowercased(), !bundleIdentifier.isEmpty else {
                continue
            }
            if let existing = bundleIndex[bundleIdentifier], existing.rank <= entry.rank {
                continue
            }
            bundleIndex[bundleIdentifier] = entry
        }

        let nameIndex = Dictionary(
            grouping: catalog,
            by: { $0.normalizedName }
        ).compactMapValues { entries in
            entries.sorted { $0.rank < $1.rank }.first
        }

        var store = TagDatabase.load()
        var changed = false

        for app in apps {
            let path = app.path.path
            guard let currentNote = normalizedNote(store.appNotes[path]) else { continue }
            guard let matched = match(app: app, bundleIndex: bundleIndex, nameIndex: nameIndex),
                  let notes = matched.notes,
                  !notes.isEmpty
            else { continue }

            let knownDefaultNotes = Set(notes.values.compactMap(normalizedNote))
            guard knownDefaultNotes.contains(currentNote),
                  let localizedNote = localizedNote(from: notes),
                  localizedNote != currentNote
            else { continue }

            store.appNotes[path] = localizedNote
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
        let catalog = loadCatalog()
        var bundleIndex: [String: SmartStartCatalogEntry] = [:]
        for entry in catalog {
            guard let bundleIdentifier = entry.bundleIdentifier?.lowercased(), !bundleIdentifier.isEmpty else {
                continue
            }
            if let existing = bundleIndex[bundleIdentifier], existing.rank <= entry.rank {
                continue
            }
            bundleIndex[bundleIdentifier] = entry
        }
        let nameIndex = Dictionary(
            grouping: catalog,
            by: { $0.normalizedName }
        ).compactMapValues { entries in
            entries.sorted { $0.rank < $1.rank }.first
        }

        var seenAssignments = Set<String>()
        var assignments: [SmartAppCategorizationAssignment] = []
        var unassigned: [SmartUnassignedApp] = []

        for app in apps {
            let matched = match(app: app, bundleIndex: bundleIndex, nameIndex: nameIndex)
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
                defaultNote: matched.localizedNote,
                defaultNoteCandidates: matched.notes?.values.map { $0 } ?? []
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
                let knownDefaultNotes = Set(assignment.defaultNoteCandidates.compactMap(normalizedNote))
                let normalizedCurrentNote = normalizedNote(currentNote)
                let shouldSeedNote = currentNote?.isEmpty != false
                    || normalizedCurrentNote.map { knownDefaultNotes.contains($0) } == true

                if shouldSeedNote {
                    store.appNotes[path] = String(defaultNote.prefix(TagDatabase.maxAppNoteLength))
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

    private static func loadCatalog() -> [SmartStartCatalogEntry] {
        if let catalog = loadRuntimeCatalog() {
            return catalog
        }
        return loadLegacyCSVCatalog()
    }

    private static func loadRuntimeCatalog() -> [SmartStartCatalogEntry]? {
        guard let url = Bundle.main.url(forResource: "SmartStartUltimateDefaultCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(SmartStartRuntimeCatalog.self, from: data)
        else { return nil }

        return catalog.entries.compactMap { entry in
            let tagIDs = entry.defaultTag
                .compactMap { SmartCategoryID(rawValue: $0) }
                .filter { $0 != .other }
            guard !tagIDs.isEmpty else { return nil }

            return SmartStartCatalogEntry(
                rank: entry.rank ?? Int.max,
                name: entry.name,
                normalizedName: entry.normalizedName.flatMap {
                    $0.isEmpty ? nil : $0
                } ?? normalizedName(entry.name),
                bundleIdentifier: normalizedBundleIdentifier(entry.bundleIdentifier),
                categoryIDs: uniqueOrdered(tagIDs),
                localizedNote: localizedNote(from: entry.notes),
                notes: entry.notes,
                sourceEvidence: entry.sourceEvidence ?? []
            )
        }
    }

    private static func loadLegacyCSVCatalog() -> [SmartStartCatalogEntry] {
        guard let url = Bundle.main.url(forResource: "SmartStartAppDefaultTags", withExtension: "csv"),
              let csv = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }

        let rows = parseCSV(csv)
        guard let header = rows.first else { return [] }
        let dataRows = rows.dropFirst()

        return dataRows.compactMap { row in
            let values = Dictionary(uniqueKeysWithValues: header.enumerated().map { index, key in
                (key, index < row.count ? row[index] : "")
            })
            let tagIDs = splitPipe(values["defaultTagIDs"] ?? "")
                .compactMap { SmartCategoryID(rawValue: $0) }
                .filter { $0 != .other }
            guard !tagIDs.isEmpty else { return nil }

            return SmartStartCatalogEntry(
                rank: Int(values["rank"] ?? "") ?? Int.max,
                name: values["name"] ?? "",
                normalizedName: values["normalizedName"].flatMap {
                    $0.isEmpty ? nil : $0
                } ?? normalizedName(values["name"] ?? ""),
                bundleIdentifier: normalizedBundleIdentifier(values["bundleIdentifier"]),
                categoryIDs: uniqueOrdered(tagIDs),
                localizedNote: nil,
                notes: nil,
                sourceEvidence: splitPipe(values["sourceEvidence"] ?? "")
            )
        }
    }

    private static func localizedNote(from notes: [String: String]?, preferredCode: String = L10n.currentCode) -> String? {
        guard let notes, !notes.isEmpty else { return nil }
        let preferredCodes = [
            preferredCode,
            "en",
            "zh-Hans",
            "zh-Hant"
        ]

        for code in preferredCodes {
            if let note = normalizedNote(notes[code]) {
                return note
            }
        }

        return notes.values
            .compactMap(normalizedNote)
            .first
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
