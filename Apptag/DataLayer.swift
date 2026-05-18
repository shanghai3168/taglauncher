import Foundation
import AppKit

// MARK: - Data Models

struct AppInfo: Identifiable, Hashable {
    var id: URL { path }
    let name: String
    let path: URL
    let tags: [String]
    let bundleIdentifier: String?
    let icon: NSImage  // Pre-loaded during background scan
    var isUncommon: Bool = false
    var note: String? = nil

    /// True if this is an Apple pre-installed app.
    var isAppleApp: Bool {
        if let bid = bundleIdentifier, bid.hasPrefix("com.apple.") { return true }
        return AppIndexer.isSystemAppPath(path.path)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(path) }
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool { lhs.path == rhs.path }
}

struct TagGroup: Identifiable {
    var id: String { name }
    let name: String
    let apps: [AppInfo]
}

// MARK: - Tag Color Mapping

enum TagColor {
    static func nsColor(for index: Int) -> NSColor {
        switch index {
        case 0:  return NSColor.systemGray
        case 1:  return NSColor(red: 0.60, green: 0.60, blue: 0.62, alpha: 1.0)
        case 2:  return NSColor(red: 0.38, green: 0.74, blue: 0.35, alpha: 1.0)
        case 3:  return NSColor(red: 0.70, green: 0.45, blue: 0.79, alpha: 1.0)
        case 4:  return NSColor(red: 0.30, green: 0.64, blue: 0.96, alpha: 1.0)
        case 5:  return NSColor(red: 0.97, green: 0.83, blue: 0.29, alpha: 1.0)
        case 6:  return NSColor(red: 0.99, green: 0.38, blue: 0.36, alpha: 1.0)
        case 7:  return NSColor(red: 0.97, green: 0.58, blue: 0.27, alpha: 1.0)
        default: return NSColor.systemGray
        }
    }
    static let allIndices: [Int] = [1, 2, 3, 4, 5, 6, 7]
}

// MARK: - App Scanner

enum AppIndexer {

    static let searchPaths: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: "/System/Cryptexes/App/System/Applications"),
        URL(fileURLWithPath: "/System/Volumes/Preboot/Cryptexes/App/System/Applications"),
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")
    ]

    private static let systemAppPathPrefixes = [
        "/System/Applications/",
        "/System/Cryptexes/App/System/Applications/",
        "/System/Volumes/Preboot/Cryptexes/App/System/Applications/"
    ]

    static func isSystemAppPath(_ path: String) -> Bool {
        systemAppPathPrefixes.contains { path.hasPrefix($0) }
    }

    /// Scan all standard locations. Tags are annotated from TagDatabase by the caller.
    static func scan() -> [AppInfo] {
        var seenResolvedPaths = Set<String>()
        var apps: [AppInfo] = []

        for baseURL in searchPaths {
            scanDirectChildren(
                in: baseURL,
                apps: &apps,
                seenResolvedPaths: &seenResolvedPaths
            )

            guard let enumerator = FileManager.default.enumerator(
                at: baseURL,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator {
                appendAppIfNeeded(
                    at: url,
                    apps: &apps,
                    seenResolvedPaths: &seenResolvedPaths
                )
            }
        }

        return deduplicated(apps).sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func scanDirectChildren(
        in baseURL: URL,
        apps: inout [AppInfo],
        seenResolvedPaths: inout Set<String>
    ) {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: baseURL.path) else { return }

        for name in names where !name.hasPrefix(".") {
            appendAppIfNeeded(
                at: baseURL.appendingPathComponent(name),
                apps: &apps,
                seenResolvedPaths: &seenResolvedPaths
            )
        }
    }

    private static func appendAppIfNeeded(
        at url: URL,
        apps: inout [AppInfo],
        seenResolvedPaths: inout Set<String>
    ) {
        guard url.pathExtension.lowercased() == "app" else { return }

        let displayURL = url.standardizedFileURL
        guard !isNestedInsideAppBundle(displayURL) else { return }

        let resolvedURL = displayURL.resolvingSymlinksInPath().standardizedFileURL
        guard !isNestedInsideAppBundle(resolvedURL) else { return }
        guard seenResolvedPaths.insert(resolvedURL.path).inserted else { return }

        let name = displayURL.deletingPathExtension().lastPathComponent
        let icon = NSWorkspace.shared.icon(forFile: displayURL.path)
        icon.size = NSSize(width: 96, height: 96)

        let bundleId = Bundle(url: displayURL)?.bundleIdentifier
            ?? Bundle(url: resolvedURL)?.bundleIdentifier

        apps.append(AppInfo(
            name: name,
            path: displayURL,
            tags: [],
            bundleIdentifier: bundleId,
            icon: icon
        ))
    }

    private static func isNestedInsideAppBundle(_ url: URL) -> Bool {
        let components = url.standardizedFileURL.pathComponents
        guard let lastAppIndex = components.lastIndex(where: { $0.lowercased().hasSuffix(".app") }) else {
            return false
        }
        return components[..<lastAppIndex].contains { $0.lowercased().hasSuffix(".app") }
    }

    private static func deduplicated(_ apps: [AppInfo]) -> [AppInfo] {
        apps.reduce(into: [String: AppInfo]()) { result, app in
            let identity = deduplicationIdentity(for: app)
            guard let existing = result[identity] else {
                result[identity] = app
                return
            }
            if appDeduplicationScore(app) > appDeduplicationScore(existing) {
                result[identity] = app
            }
        }
        .values
        .map { $0 }
    }

    private static func deduplicationIdentity(for app: AppInfo) -> String {
        if let bundleIdentifier = app.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !bundleIdentifier.isEmpty {
            return "bundle:\(bundleIdentifier.lowercased())"
        }
        return "name:\(normalizedAppName(app.name))"
    }

    private static func normalizedAppName(_ name: String) -> String {
        name
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }

    private static func appDeduplicationScore(_ app: AppInfo) -> Int {
        let path = app.path.path
        var score = 0

        if path.hasPrefix("/Applications/") { score += 500 }
        if path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path + "/") {
            score += 450
        }
        if path.hasPrefix("/System/Applications/") { score += 400 }
        if path.hasPrefix("/System/Cryptexes/") { score += 250 }
        if path.hasPrefix("/System/Volumes/Preboot/") { score += 200 }
        if app.bundleIdentifier?.isEmpty == false { score += 50 }
        if path.split(separator: "/").count <= 3 { score += 25 }
        if isSystemAppPath(path) { score -= 10 }

        return score
    }

    /// Group apps by their tags (from TagDatabase).
    /// Groups are sorted by tagOrder (user-defined), falling back to alpha.
    static func group(
        apps: [AppInfo],
        nameOverrides: [String: String] = [:],
        defaultGroupName: String = "Other",
        tagOrder: [String] = []
    ) -> [TagGroup] {
        let macCategory = "Mac自带"
        var dict: [String: [AppInfo]] = [:]
        var seenAppIDsByGroup: [String: Set<URL>] = [:]

        for app in apps {
            if app.tags.isEmpty {
                let bucket = app.isAppleApp ? macCategory : defaultGroupName
                appendGroupedApp(app, to: bucket, groups: &dict, seenAppIDsByGroup: &seenAppIDsByGroup)
            } else {
                for tag in uniqueOrdered(app.tags) {
                    let displayName = nameOverrides[tag] ?? tag
                    appendGroupedApp(app, to: displayName, groups: &dict, seenAppIDsByGroup: &seenAppIDsByGroup)
                }
            }
        }

        // Build sort index from tagOrder: lower index = appears first
        var orderIndex: [String: Int] = [:]
        for (i, name) in tagOrder.enumerated() {
            orderIndex[name] = i
        }

        return dict
            .sorted { lhs, rhs in
                if lhs.key == macCategory { return false }
                if rhs.key == macCategory { return true }
                if lhs.key == defaultGroupName { return false }
                if rhs.key == defaultGroupName { return true }
                // Use custom order if both are in tagOrder
                let li = orderIndex[lhs.key] ?? Int.max
                let ri = orderIndex[rhs.key] ?? Int.max
                if li != ri { return li < ri }
                return lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
            }
            .map { TagGroup(name: $0.key, apps: $0.value) }
    }

    private static func appendGroupedApp(
        _ app: AppInfo,
        to groupName: String,
        groups: inout [String: [AppInfo]],
        seenAppIDsByGroup: inout [String: Set<URL>]
    ) {
        if seenAppIDsByGroup[groupName, default: []].insert(app.id).inserted {
            groups[groupName, default: []].append(app)
        }
    }

    private static func uniqueOrdered(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}

enum TagDatabase {
    static let uncommonTagKey = "__system.uncommon"
    static let maxAppNoteLength = 80
    static let autoUncommonOpenThreshold = 100

    enum UncommonSource: String, Codable {
        case auto
        case manual
    }

    // MARK: Storage types

    struct TagDef: Codable, Equatable {
        var color: Int
        var systemCategoryID: SmartCategoryID? = nil
    }

    struct Store: Codable {
        var version: Int = 1
        var tags: [String: TagDef] = [:]
        var appTags: [String: [String]] = [:]  // path → tag names
        var tagOrder: [String] = []  // display order; empty → alpha sort
        var uncommonAppPaths: [String] = []  // special marker; does not affect normal groups
        var uncommonSources: [String: UncommonSource] = [:]  // current uncommon source: auto/manual
        var appOpenCounts: [String: Int] = [:]  // launches opened from TagLauncher
        var knownAppPaths: [String] = []  // baseline set to detect newly installed apps
        var appNotes: [String: String] = [:]  // path → user note; retained even if marker is removed
        var disabledSystemCategoryIDs: [SmartCategoryID] = []  // system categories the user deleted
        var smartStart: SmartStartState = SmartStartState()
        var categoryScheme: CategorySchemeState = CategorySchemeState()

        enum CodingKeys: String, CodingKey {
            case version
            case tags
            case appTags
            case tagOrder
            case uncommonAppPaths
            case uncommonSources
            case appOpenCounts
            case knownAppPaths
            case appNotes
            case disabledSystemCategoryIDs
            case smartStart
            case categoryScheme
        }

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
            tags = try container.decodeIfPresent([String: TagDef].self, forKey: .tags) ?? [:]
            appTags = try container.decodeIfPresent([String: [String]].self, forKey: .appTags) ?? [:]
            tagOrder = try container.decodeIfPresent([String].self, forKey: .tagOrder) ?? []
            uncommonAppPaths = try container.decodeIfPresent([String].self, forKey: .uncommonAppPaths) ?? []
            uncommonSources = try container.decodeIfPresent([String: UncommonSource].self, forKey: .uncommonSources) ?? [:]
            appOpenCounts = try container.decodeIfPresent([String: Int].self, forKey: .appOpenCounts) ?? [:]
            knownAppPaths = try container.decodeIfPresent([String].self, forKey: .knownAppPaths) ?? []
            appNotes = try container.decodeIfPresent([String: String].self, forKey: .appNotes) ?? [:]
            disabledSystemCategoryIDs = try container.decodeIfPresent(
                [SmartCategoryID].self,
                forKey: .disabledSystemCategoryIDs
            ) ?? []
            smartStart = try container.decodeIfPresent(SmartStartState.self, forKey: .smartStart) ?? SmartStartState()
            categoryScheme = try container.decodeIfPresent(CategorySchemeState.self, forKey: .categoryScheme) ?? CategorySchemeState()

            for path in uncommonAppPaths where uncommonSources[path] == nil {
                uncommonSources[path] = .manual
            }
        }

        var hasUserTagAssignments: Bool {
            appTags.values.contains { !$0.isEmpty }
        }
    }

    struct SmartStartState: Codable, Equatable {
        var catalogVersion: Int = 0
        var lastRunAt: Date? = nil
        var lastAppliedAt: Date? = nil
        var lastSuggestionAt: Date? = nil
        var lastBackupPath: String? = nil
        var lastMode: String? = nil
        var lastMatchedAppCount: Int = 0
        var lastAssignedTagCount: Int = 0
    }

    struct CategorySchemeState: Codable, Equatable {
        var currentName: String? = nil
        var currentCreatedAt: Date? = nil
        var previousName: String? = nil
        var previousCreatedAt: Date? = nil
        var previousBackupPath: String? = nil
        var lastChangedAt: Date? = nil
    }

    // MARK: Paths

    private static var storeDir: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Apptag")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var storeURL: URL { storeDir.appendingPathComponent("tags.json") }

    static var smartStartBackupDir: URL {
        let dir = storeDir.appendingPathComponent("SmartStartBackups")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var categorySchemeBackupDir: URL {
        let dir = storeDir.appendingPathComponent("CategorySchemeBackups")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var legacyStoreURL: URL? {
        guard ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil else {
            return nil
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        let bundleID = Bundle.main.bundleIdentifier ?? "com.apptag.launcher"
        let marker = "/Library/Containers/\(bundleID)/Data"
        guard let range = home.path.range(of: marker) else { return nil }

        let realHomePath = String(home.path[..<range.lowerBound])
        return URL(fileURLWithPath: realHomePath)
            .appendingPathComponent("Library/Application Support/Apptag/tags.json")
    }

    // MARK: Load / Save

    static func load() -> Store {
        migrateLegacyStoreIfNeeded()
        guard let data = try? Data(contentsOf: storeURL),
              let store = try? JSONDecoder().decode(Store.self, from: data)
        else { return Store() }
        return store
    }

    static func loadWithEnsuredCategoryScheme() -> Store {
        var store = load()
        if normalizeCategorySchemeMetadata(&store) {
            save(store)
        }
        return store
    }

    static func save(_ store: Store) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(store) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    static func backup(_ store: Store, reason: String, in directory: URL? = nil) -> URL? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let safeTimestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let safeReason = reason
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let url = (directory ?? smartStartBackupDir)
            .appendingPathComponent("\(safeTimestamp)-\(safeReason).json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(store) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: Category Scheme Auto Snapshots

    private struct CategorySchemeFingerprint: Equatable {
        let tags: [String: TagDef]
        let appTags: [String: [String]]
        let tagOrder: [String]
        let uncommonAppPaths: [String]
        let uncommonSources: [String: UncommonSource]
        let disabledSystemCategoryIDs: [SmartCategoryID]
    }

    private static let categorySchemeBatchDebounceSeconds: TimeInterval = 90
    private static let categorySchemeRetentionSeconds: TimeInterval = 30 * 24 * 60 * 60
    private static let categorySchemeBatchQueue = DispatchQueue(label: "com.apptag.category-scheme-batch")
    private static var categorySchemeBatchActive = false
    private static var categorySchemeBatchResetWorkItem: DispatchWorkItem?

    static func saveUserCategorySchemeMutation(
        _ store: Store,
        previous previousStore: Store,
        reason: String
    ) {
        guard categorySchemeFingerprint(for: store) != categorySchemeFingerprint(for: previousStore) else {
            save(store)
            return
        }

        var nextStore = store
        recordAutomaticPreviousCategoryScheme(
            in: &nextStore,
            previous: previousStore,
            reason: reason,
            updateCurrentSchemeName: true
        )
        save(nextStore)
    }

    static func attachPreviousCategorySchemeSnapshot(
        to store: inout Store,
        previous previousStore: Store,
        reason: String,
        updateCurrentSchemeName: Bool
    ) {
        guard categorySchemeFingerprint(for: store) != categorySchemeFingerprint(for: previousStore) else { return }
        recordAutomaticPreviousCategoryScheme(
            in: &store,
            previous: previousStore,
            reason: reason,
            updateCurrentSchemeName: updateCurrentSchemeName
        )
    }

    static func flushPendingCategorySchemeBackupBatch() {
        categorySchemeBatchQueue.sync {
            categorySchemeBatchActive = false
            categorySchemeBatchResetWorkItem?.cancel()
            categorySchemeBatchResetWorkItem = nil
        }
        pruneOldCategorySchemeBackups()
    }

    private static func recordAutomaticPreviousCategoryScheme(
        in store: inout Store,
        previous previousStore: Store,
        reason: String,
        updateCurrentSchemeName: Bool
    ) {
        var normalizedPrevious = previousStore
        _ = normalizeCategorySchemeMetadata(&normalizedPrevious)
        let now = Date()
        let shouldCreatePreviousSnapshot = beginOrExtendCategorySchemeBatch()

        if shouldCreatePreviousSnapshot {
            let backupURL = backup(
                normalizedPrevious,
                reason: "auto-\(reason)",
                in: categorySchemeBackupDir
            )
            let previousCreatedAt = normalizedPrevious.categoryScheme.currentCreatedAt
                ?? normalizedPrevious.categoryScheme.lastChangedAt
                ?? now
            store.categoryScheme.previousName = normalizedPrevious.categoryScheme.currentName
                ?? schemeName(prefixKey: "scheme.beforeSmartStart", at: previousCreatedAt)
            store.categoryScheme.previousCreatedAt = previousCreatedAt
            store.categoryScheme.previousBackupPath = backupURL?.path
        }

        if updateCurrentSchemeName {
            store.categoryScheme.currentCreatedAt = now
            store.categoryScheme.currentName = schemeName(prefixKey: "scheme.local", at: now)
        }
        store.categoryScheme.lastChangedAt = now
        pruneOldCategorySchemeBackups()
    }

    private static func beginOrExtendCategorySchemeBatch() -> Bool {
        categorySchemeBatchQueue.sync {
            let isFirstChangeInBatch = !categorySchemeBatchActive
            categorySchemeBatchActive = true
            categorySchemeBatchResetWorkItem?.cancel()

            let workItem = DispatchWorkItem {
                categorySchemeBatchQueue.sync {
                    categorySchemeBatchActive = false
                    categorySchemeBatchResetWorkItem = nil
                }
                pruneOldCategorySchemeBackups()
            }
            categorySchemeBatchResetWorkItem = workItem
            DispatchQueue.main.asyncAfter(
                deadline: .now() + categorySchemeBatchDebounceSeconds,
                execute: workItem
            )
            return isFirstChangeInBatch
        }
    }

    private static func categorySchemeFingerprint(for store: Store) -> CategorySchemeFingerprint {
        CategorySchemeFingerprint(
            tags: store.tags,
            appTags: store.appTags.mapValues(uniqueOrdered),
            tagOrder: uniqueOrdered(store.tagOrder),
            uncommonAppPaths: store.uncommonAppPaths.sorted(),
            uncommonSources: store.uncommonSources,
            disabledSystemCategoryIDs: store.disabledSystemCategoryIDs
        )
    }

    private static func pruneOldCategorySchemeBackups(now: Date = Date()) {
        let fm = FileManager.default
        let cutoff = now.addingTimeInterval(-categorySchemeRetentionSeconds)
        guard let urls = try? fm.contentsOfDirectory(
            at: categorySchemeBackupDir,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for url in urls where url.pathExtension.lowercased() == "json" {
            let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let date = values?.creationDate ?? values?.contentModificationDate ?? .distantFuture
            if date < cutoff {
                try? fm.removeItem(at: url)
            }
        }
    }

    static func restore(fromBackupAt path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url),
              let store = try? JSONDecoder().decode(Store.self, from: data)
        else { return false }
        save(store)
        return true
    }

    /// App Store sandbox builds read Application Support inside the app container.
    /// Older non-sandbox builds stored the same database directly under ~/Library.
    /// On first sandbox launch, migrate the richer legacy database before seeding defaults.
    static func migrateLegacyStoreIfNeeded() {
        let fm = FileManager.default
        guard let legacyURL = legacyStoreURL,
              fm.fileExists(atPath: legacyURL.path)
        else { return }

        guard let legacyData = try? Data(contentsOf: legacyURL),
              let legacyStore = try? JSONDecoder().decode(Store.self, from: legacyData)
        else { return }

        if let currentData = try? Data(contentsOf: storeURL),
           let currentStore = try? JSONDecoder().decode(Store.self, from: currentData),
           storeScore(currentStore) >= storeScore(legacyStore) {
            return
        }

        try? fm.createDirectory(at: storeDir, withIntermediateDirectories: true)
        try? legacyData.write(to: storeURL, options: .atomic)
    }

    private static func storeScore(_ store: Store) -> Int {
        store.appTags.count * 100 + store.tagOrder.count * 10 + store.tags.count
    }

    // MARK: Localization

    @discardableResult
    static func relocalizeSystemTagsForCurrentLanguage() -> Bool {
        var store = load()
        guard relocalizeSystemTags(in: &store) else { return false }
        save(store)
        return true
    }

    private static func relocalizeSystemTags(in store: inout Store) -> Bool {
        var renameMap: [String: String] = [:]

        for (tagName, tagDef) in store.tags {
            guard let categoryID = tagDef.systemCategoryID else { continue }
            let targetName = categoryID.localizedDisplayName
            guard targetName != tagName else { continue }
            if let existing = store.tags[targetName],
               existing.systemCategoryID != categoryID {
                continue
            }
            renameMap[tagName] = targetName
        }

        guard !renameMap.isEmpty else { return false }
        for (oldName, newName) in renameMap {
            renameTagKey(in: &store, from: oldName, to: newName)
        }
        return true
    }

    static func systemTagName(for categoryID: SmartCategoryID, in store: Store) -> String? {
        store.tags.first { $0.value.systemCategoryID == categoryID }?.key
    }

    @discardableResult
    static func ensureSystemTag(
        for categoryID: SmartCategoryID,
        in store: inout Store
    ) -> (name: String, created: Bool)? {
        if let existingName = systemTagName(for: categoryID, in: store) {
            let targetName = categoryID.localizedDisplayName
            if existingName != targetName {
                if let existing = store.tags[targetName],
                   existing.systemCategoryID != categoryID {
                    return (existingName, false)
                }
                renameTagKey(in: &store, from: existingName, to: targetName)
                return (targetName, false)
            }
            if !store.tagOrder.contains(existingName) {
                store.tagOrder.append(existingName)
            }
            return (existingName, false)
        }

        let targetName = categoryID.localizedDisplayName
        if let existing = store.tags[targetName],
           existing.systemCategoryID != categoryID {
            return nil
        }

        store.tags[targetName] = TagDef(
            color: categoryID.defaultColorIndex,
            systemCategoryID: categoryID
        )
        if !store.tagOrder.contains(targetName) {
            store.tagOrder.append(targetName)
        }
        return (targetName, true)
    }

    private static func renameTagKey(in store: inout Store, from oldName: String, to newName: String) {
        guard oldName != newName, let tagDef = store.tags.removeValue(forKey: oldName) else { return }
        store.tags[newName] = tagDef
        store.tagOrder = uniqueOrdered(store.tagOrder.map { $0 == oldName ? newName : $0 })

        for (path, tags) in store.appTags {
            let renamedTags = uniqueOrdered(tags.map { $0 == oldName ? newName : $0 })
            if renamedTags.isEmpty {
                store.appTags.removeValue(forKey: path)
            } else {
                store.appTags[path] = renamedTags
            }
        }
    }

    private static func uniqueOrdered(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    // MARK: Export / Import

    static func exportTo(_ url: URL) throws {
        migrateLegacyStoreIfNeeded()
        let store = loadWithEnsuredCategoryScheme()
        let data = try JSONEncoder().encode(store)
        try data.write(to: url, options: .atomic)
    }

    static func importFrom(_ url: URL) throws -> Store {
        let previousStore = loadWithEnsuredCategoryScheme()
        let data = try Data(contentsOf: url)
        var store = try JSONDecoder().decode(Store.self, from: data)
        applyImportedCategorySchemeMetadata(to: &store, importedFileURL: url)
        attachPreviousCategorySchemeSnapshot(
            to: &store,
            previous: previousStore,
            reason: "manual-import",
            updateCurrentSchemeName: false
        )
        flushPendingCategorySchemeBackupBatch()
        save(store)
        return store
    }

    private static func applyImportedCategorySchemeMetadata(to store: inout Store, importedFileURL url: URL) {
        let importedCreatedAt = importedSchemeCreatedAt(from: url)
        store.categoryScheme.currentCreatedAt = importedCreatedAt
        store.categoryScheme.currentName = schemeName(prefixKey: "scheme.local", at: importedCreatedAt)
        store.categoryScheme.lastChangedAt = Date()
    }

    private static func importedSchemeCreatedAt(from url: URL) -> Date {
        let filename = url.deletingPathExtension().lastPathComponent
        if let timestampDate = schemeTimestampDate(in: filename) {
            return timestampDate
        }

        if let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]) {
            return values.creationDate ?? values.contentModificationDate ?? Date()
        }

        return Date()
    }

    private static func schemeTimestampDate(in text: String) -> Date? {
        let pattern = #"(?<!\d)\d{4}\.\d{4}\.\d{4}(?!\d)"#
        guard let range = text.range(of: pattern, options: .regularExpression) else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy.MMdd.HHmm"
        formatter.isLenient = false
        return formatter.date(from: String(text[range]))
    }

    @discardableResult
    static func normalizeCategorySchemeMetadata(_ store: inout Store) -> Bool {
        var changed = false
        if store.categoryScheme.currentCreatedAt == nil {
            store.categoryScheme.currentCreatedAt = store.categoryScheme.lastChangedAt
                ?? store.smartStart.lastAppliedAt
                ?? store.smartStart.lastRunAt
                ?? Date()
            changed = true
        }

        if let createdAt = store.categoryScheme.currentCreatedAt {
            let prefixKey = store.smartStart.lastAppliedAt == nil ? "scheme.local" : "scheme.smartStart"
            let normalizedName = normalizedSchemeName(
                storedName: store.categoryScheme.currentName,
                createdAt: createdAt,
                fallbackPrefixKey: prefixKey
            )
            if store.categoryScheme.currentName != normalizedName {
                store.categoryScheme.currentName = normalizedName
                changed = true
            }
        } else if store.categoryScheme.currentName == nil {
            changed = true
        }

        if store.categoryScheme.lastChangedAt == nil {
            store.categoryScheme.lastChangedAt = store.categoryScheme.currentCreatedAt
            changed = true
        }

        if store.categoryScheme.previousName == nil,
           store.categoryScheme.previousBackupPath != nil {
            let createdAt = store.categoryScheme.previousCreatedAt
                ?? store.categoryScheme.currentCreatedAt
                ?? Date()
            store.categoryScheme.previousCreatedAt = createdAt
            store.categoryScheme.previousName = normalizedSchemeName(
                storedName: store.categoryScheme.previousName,
                createdAt: createdAt,
                fallbackPrefixKey: "scheme.beforeSmartStart"
            )
            changed = true
        } else if let previousCreatedAt = store.categoryScheme.previousCreatedAt,
                  let previousName = store.categoryScheme.previousName {
            let normalizedName = normalizedSchemeName(
                storedName: previousName,
                createdAt: previousCreatedAt,
                fallbackPrefixKey: "scheme.beforeSmartStart"
            )
            if store.categoryScheme.previousName != normalizedName {
                store.categoryScheme.previousName = normalizedName
                changed = true
            }
        }

        return changed
    }

    static func schemeName(prefixKey: String, at date: Date) -> String {
        "\(tr(prefixKey)) \(schemeTimestamp(at: date))"
    }

    static func schemeTimestamp(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy.MMdd.HHmm"
        return formatter.string(from: date)
    }

    static func exportFileName(for scheme: CategorySchemeState) -> String {
        let fallbackDate = scheme.currentCreatedAt ?? scheme.lastChangedAt ?? Date()
        let baseName = normalizedSchemeName(
            storedName: scheme.currentName,
            createdAt: fallbackDate,
            fallbackPrefixKey: "scheme.local"
        )
        return "\(safeFileName(baseName)).json"
    }

    static func normalizedSchemeName(
        storedName: String?,
        createdAt: Date,
        fallbackPrefixKey: String
    ) -> String {
        let prefix = schemePrefix(from: storedName) ?? tr(fallbackPrefixKey)
        return "\(prefix) \(schemeTimestamp(at: createdAt))"
    }

    private static func schemePrefix(from storedName: String?) -> String? {
        guard let storedName else { return nil }
        let trimmed = storedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let prefixKeys = ["scheme.local", "scheme.smartStart", "scheme.systemSmartStart", "scheme.beforeSmartStart"]
        for key in prefixKeys {
            if trimmed.hasPrefix(tr(key)) {
                return tr(key)
            }
            for language in L10n.supported {
                if let localized = L10n.loadedTranslation(key, for: language.code),
                   !localized.isEmpty,
                   trimmed.hasPrefix(localized) {
                    return tr(key)
                }
            }
        }

        if let firstNumber = trimmed.firstIndex(where: { $0.isNumber }) {
            let prefix = String(trimmed[..<firstNumber])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !prefix.isEmpty { return prefix }
        }

        return trimmed
    }

    private static func safeFileName(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:\n\r\t")
        let parts = value.components(separatedBy: invalid)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let joined = parts.joined(separator: "-")
        return joined.isEmpty ? "TagLauncher-tags" : joined
    }

    /// Seed starter system tags on first launch. Smart Start adds any additional
    /// system tags it needs after scanning the user's installed apps.
    static func seedDefaultTags() {
        migrateLegacyStoreIfNeeded()
        guard !FileManager.default.fileExists(atPath: storeURL.path) else { return }

        let starterCategoryIDs: [SmartCategoryID] = [
            .design,
            .development,
            .writing,
            .game,
            .entertainment,
            .system,
            .productivity
        ]

        var store = Store()
        for categoryID in starterCategoryIDs {
            _ = ensureSystemTag(for: categoryID, in: &store)
        }
        save(store)
    }
}

// MARK: - Tag Editor (CRUD against local TagDatabase)

enum TagEditor {

    // MARK: Read

    /// Get tag→color map from the database.
    static func tagColors() -> [String: Int] {
        let store = TagDatabase.load()
        return store.tags.mapValues { $0.color }
    }

    /// Tag names in display order. Falls back to alpha sort if no custom order.
    static func orderedTagNames() -> [String] {
        let store = TagDatabase.load()
        let ordered = store.tagOrder.filter { store.tags[$0] != nil }
        let remaining = store.tags.keys.filter { !ordered.contains($0) }.sorted()
        return ordered + remaining
    }

    /// Persist a new tag display order.
    static func reorderTags(_ names: [String]) {
        var store = TagDatabase.load()
        let previousStore = store
        store.tagOrder = names
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "reorder-tags"
        )
    }

    /// Create a new tag definition (no app assignments yet).
    static func createTag(_ name: String, color: Int) {
        var store = TagDatabase.load()
        guard store.tags[name] == nil else { return }
        let previousStore = store
        store.tags[name] = TagDatabase.TagDef(color: color, systemCategoryID: nil)
        if !store.tagOrder.contains(name) { store.tagOrder.insert(name, at: 0) }
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "create-tag"
        )
    }

    /// Annotate scanned apps with tags from the database.
    static func annotate(apps: [AppInfo]) -> [AppInfo] {
        annotate(apps: apps, store: TagDatabase.load())
    }

    static func annotate(apps: [AppInfo], store: TagDatabase.Store) -> [AppInfo] {
        let uncommonPaths = Set(store.uncommonAppPaths)
        return apps.map { app in
            let appTags = store.appTags[app.path.path] ?? []
            return AppInfo(
                name: app.name, path: app.path, tags: appTags,
                bundleIdentifier: app.bundleIdentifier, icon: app.icon,
                isUncommon: uncommonPaths.contains(app.path.path),
                note: store.appNotes[app.path.path]
            )
        }
    }

    // MARK: Write

    /// Assign a tag to multiple apps. Preserves existing tags.
    static func assignTag(_ tag: String, color: Int, to paths: [String]) {
        var store = TagDatabase.load()
        let previousStore = store
        // Ensure tag definition exists
        if store.tags[tag] == nil {
            store.tags[tag] = TagDatabase.TagDef(color: color, systemCategoryID: nil)
            // New tag: append to display order
            if !store.tagOrder.contains(tag) { store.tagOrder.insert(tag, at: 0) }
        }
        for path in paths {
            var current = store.appTags[path] ?? []
            if !current.contains(tag) {
                current.append(tag)
                store.appTags[path] = current
            }
        }
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "assign-tag"
        )
    }

    /// Replace the full editable tag set for multiple apps.
    static func setTags(_ tags: [String], to paths: [String]) {
        var store = TagDatabase.load()
        let previousStore = store
        let selectedUncommon = tags.contains(TagDatabase.uncommonTagKey)
        let validTags = tags.filter { store.tags[$0] != nil }
        var uncommonPaths = Set(store.uncommonAppPaths)
        for path in paths {
            if validTags.isEmpty {
                store.appTags.removeValue(forKey: path)
            } else {
                store.appTags[path] = validTags
            }
            if selectedUncommon {
                uncommonPaths.insert(path)
                store.uncommonSources[path] = .manual
            } else {
                uncommonPaths.remove(path)
                store.uncommonSources.removeValue(forKey: path)
            }
        }
        store.uncommonAppPaths = uncommonPaths.sorted()
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "set-tags"
        )
    }

    /// Append tags to multiple apps without disturbing their existing tag sets.
    static func appendTags(_ tags: [String], to paths: [String]) {
        guard !tags.isEmpty, !paths.isEmpty else { return }

        var store = TagDatabase.load()
        let previousStore = store
        let selectedUncommon = tags.contains(TagDatabase.uncommonTagKey)
        let validTags = tags.filter { store.tags[$0] != nil }
        var uncommonPaths = Set(store.uncommonAppPaths)

        for path in paths {
            var current = store.appTags[path] ?? []
            for tag in validTags where !current.contains(tag) {
                current.append(tag)
            }
            if !current.isEmpty {
                store.appTags[path] = current
            }

            if selectedUncommon {
                uncommonPaths.insert(path)
                store.uncommonSources[path] = .manual
            }
        }

        store.uncommonAppPaths = uncommonPaths.sorted()
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "append-tags"
        )
    }

    /// Remove tags from multiple apps while preserving every unrelated tag.
    static func removeTags(_ tags: [String], from paths: [String]) {
        guard !tags.isEmpty, !paths.isEmpty else { return }

        var store = TagDatabase.load()
        let previousStore = store
        let selectedUncommon = tags.contains(TagDatabase.uncommonTagKey)
        let validTags = Set(tags.filter { store.tags[$0] != nil })
        var uncommonPaths = Set(store.uncommonAppPaths)

        for path in paths {
            var current = store.appTags[path] ?? []
            current.removeAll { validTags.contains($0) }

            if current.isEmpty {
                store.appTags.removeValue(forKey: path)
            } else {
                store.appTags[path] = current
            }

            if selectedUncommon {
                uncommonPaths.remove(path)
                store.uncommonSources.removeValue(forKey: path)
            }
        }

        store.uncommonAppPaths = uncommonPaths.sorted()
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "remove-tags"
        )
    }

    static func reconcileScannedApps(_ apps: [AppInfo]) -> TagDatabase.Store {
        var store = TagDatabase.load()
        let scannedPaths = Set(apps.map { $0.path.path })
        let knownPaths = Set(store.knownAppPaths)

        if store.knownAppPaths.isEmpty {
            let seededDefaultNotes = seedDefaultAppleAppNotes(for: apps, in: &store)
            let markedUncommon = markUnfamiliarAppleAppsAsUncommon(apps, in: &store)
            store.knownAppPaths = scannedPaths.sorted()
            if apps.isEmpty == false || seededDefaultNotes || markedUncommon {
                TagDatabase.save(store)
            }
            return store
        }

        let newPaths = scannedPaths.subtracting(knownPaths)
        guard !newPaths.isEmpty else { return store }

        var uncommonPaths = Set(store.uncommonAppPaths)
        let appsByPath = Dictionary(uniqueKeysWithValues: apps.map { ($0.path.path, $0) })
        for path in newPaths {
            if let app = appsByPath[path],
               app.isAppleApp,
               AppleDefaultAppNotes.isFamiliarAppleApp(app) {
                continue
            }
            uncommonPaths.insert(path)
            store.uncommonSources[path] = .auto
            if store.appOpenCounts[path] == nil {
                store.appOpenCounts[path] = 0
            }
        }

        let newApps = apps.filter { newPaths.contains($0.path.path) }
        _ = seedDefaultAppleAppNotes(for: newApps, in: &store)
        store.uncommonAppPaths = uncommonPaths.sorted()
        store.knownAppPaths = knownPaths.union(newPaths).sorted()
        TagDatabase.save(store)
        return store
    }

    private static func seedDefaultAppleAppNotes(
        for apps: [AppInfo],
        in store: inout TagDatabase.Store
    ) -> Bool {
        var changed = false

        for app in apps where app.isAppleApp {
            let path = app.path.path
            if store.appNotes[path]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                continue
            }

            guard let note = AppleDefaultAppNotes.note(for: app) else { continue }
            store.appNotes[path] = String(note.prefix(TagDatabase.maxAppNoteLength))
            changed = true
        }

        return changed
    }

    private static func markUnfamiliarAppleAppsAsUncommon(
        _ apps: [AppInfo],
        in store: inout TagDatabase.Store
    ) -> Bool {
        var uncommonPaths = Set(store.uncommonAppPaths)
        var changed = false

        for app in apps where app.isAppleApp && !AppleDefaultAppNotes.isFamiliarAppleApp(app) {
            let path = app.path.path
            if uncommonPaths.insert(path).inserted {
                changed = true
            }
            if store.uncommonSources[path] == nil {
                store.uncommonSources[path] = .auto
                changed = true
            }
        }

        if changed {
            store.uncommonAppPaths = uncommonPaths.sorted()
        }
        return changed
    }

    static func recordLauncherOpen(for path: String) {
        var store = TagDatabase.load()
        store.appOpenCounts[path] = (store.appOpenCounts[path] ?? 0) + 1

        if store.uncommonSources[path] == .auto,
           store.appOpenCounts[path, default: 0] >= TagDatabase.autoUncommonOpenThreshold {
            var uncommonPaths = Set(store.uncommonAppPaths)
            uncommonPaths.remove(path)
            store.uncommonAppPaths = uncommonPaths.sorted()
            store.uncommonSources.removeValue(forKey: path)
        }

        TagDatabase.save(store)
    }

    static func setAppNote(_ note: String, for path: String) {
        var store = TagDatabase.load()
        let previousStore = store
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let limited = String(trimmed.prefix(TagDatabase.maxAppNoteLength))
        if limited.isEmpty {
            store.appNotes.removeValue(forKey: path)
        } else {
            store.appNotes[path] = limited
            var uncommonPaths = Set(store.uncommonAppPaths)
            if uncommonPaths.insert(path).inserted {
                store.uncommonAppPaths = uncommonPaths.sorted()
            }
            if store.uncommonSources[path] != .manual {
                store.uncommonSources[path] = .manual
            }
        }
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "edit-app-note"
        )
    }

    static func moveApp(path: String, from sourceTag: String, to targetTag: String, color: Int, copy: Bool) {
        var store = TagDatabase.load()
        let previousStore = store
        if store.tags[targetTag] == nil {
            store.tags[targetTag] = TagDatabase.TagDef(color: color, systemCategoryID: nil)
            if !store.tagOrder.contains(targetTag) { store.tagOrder.insert(targetTag, at: 0) }
        }

        var current = store.appTags[path] ?? []
        if !copy, !sourceTag.isEmpty {
            current.removeAll { $0 == sourceTag }
        }
        if !current.contains(targetTag) {
            current.append(targetTag)
        }

        if current.isEmpty {
            store.appTags.removeValue(forKey: path)
        } else {
            store.appTags[path] = current
        }
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "move-app"
        )
    }

    /// Rename a tag on all apps that have it.
    static func renameTag(from oldName: String, to newName: String) {
        var store = TagDatabase.load()
        guard oldName != newName, store.tags[newName] == nil else { return }
        let previousStore = store
        // Update tag definition
        if let def = store.tags.removeValue(forKey: oldName) {
            store.tags[newName] = def
        }
        store.tagOrder = store.tagOrder.map { $0 == oldName ? newName : $0 }
        // Update all app assignments
        for (path, var tags) in store.appTags {
            if let idx = tags.firstIndex(of: oldName) {
                tags[idx] = newName
                store.appTags[path] = Array(NSOrderedSet(array: tags).compactMap { $0 as? String })
            }
        }
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "rename-tag"
        )
    }

    /// Delete a tag completely (from all apps and tag definitions).
    static func deleteTagCompletely(_ tag: String) {
        var store = TagDatabase.load()
        let previousStore = store
        if let removedTag = store.tags.removeValue(forKey: tag),
           let categoryID = removedTag.systemCategoryID,
           !store.disabledSystemCategoryIDs.contains(categoryID) {
            store.disabledSystemCategoryIDs.append(categoryID)
        }
        store.tagOrder.removeAll { $0 == tag }
        for (path, var tags) in store.appTags {
            tags.removeAll { $0 == tag }
            if tags.isEmpty {
                store.appTags.removeValue(forKey: path)
            } else {
                store.appTags[path] = tags
            }
        }
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "delete-tag"
        )
    }

    /// Set the color for a tag.
    static func setColor(_ color: Int, for tag: String) {
        var store = TagDatabase.load()
        let previousStore = store
        var tagDef = store.tags[tag] ?? TagDatabase.TagDef(color: color, systemCategoryID: nil)
        tagDef.color = color
        store.tags[tag] = tagDef
        TagDatabase.saveUserCategorySchemeMutation(
            store,
            previous: previousStore,
            reason: "set-tag-color"
        )
    }
}
