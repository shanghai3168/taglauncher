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

        return apps.sorted {
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
        let resolvedURL = displayURL.resolvingSymlinksInPath().standardizedFileURL
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

        for app in apps {
            if app.tags.isEmpty {
                let bucket = app.isAppleApp ? macCategory : defaultGroupName
                dict[bucket, default: []].append(app)
            } else {
                for tag in app.tags {
                    let displayName = nameOverrides[tag] ?? tag
                    dict[displayName, default: []].append(app)
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

            for path in uncommonAppPaths where uncommonSources[path] == nil {
                uncommonSources[path] = .manual
            }
        }
    }

    // MARK: Paths

    private static var storeDir: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Apptag")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var storeURL: URL { storeDir.appendingPathComponent("tags.json") }

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

    static func save(_ store: Store) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(store) else { return }
        try? data.write(to: storeURL, options: .atomic)
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

    // MARK: Export / Import

    static func exportTo(_ url: URL) throws {
        migrateLegacyStoreIfNeeded()
        let store = load()
        let data = try JSONEncoder().encode(store)
        try data.write(to: url, options: .atomic)
    }

    static func importFrom(_ url: URL) throws -> Store {
        let data = try Data(contentsOf: url)
        let store = try JSONDecoder().decode(Store.self, from: data)
        save(store)
        return store
    }

    /// Seed default tags on first launch. Only runs if store doesn't exist yet.
    /// Tag names are loaded from the current language's localization.
    static func seedDefaultTags() {
        migrateLegacyStoreIfNeeded()
        guard !FileManager.default.fileExists(atPath: storeURL.path) else { return }

        let keys = [
            "tag.design", "tag.development", "tag.writing",
            "tag.gaming", "tag.entertainment", "tag.system",
            "tag.productivity"
        ]
        let colors: [Int] = [1, 2, 3, 4, 5, 6, 7]

        var store = Store()
        for (i, key) in keys.enumerated() {
            let name = tr(key)
            store.tags[name] = TagDef(color: colors[i])
            store.tagOrder.append(name)
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
        store.tagOrder = names
        TagDatabase.save(store)
    }

    /// Create a new tag definition (no app assignments yet).
    static func createTag(_ name: String, color: Int) {
        var store = TagDatabase.load()
        guard store.tags[name] == nil else { return }
        store.tags[name] = TagDatabase.TagDef(color: color)
        if !store.tagOrder.contains(name) { store.tagOrder.insert(name, at: 0) }
        TagDatabase.save(store)
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
        // Ensure tag definition exists
        if store.tags[tag] == nil {
            store.tags[tag] = TagDatabase.TagDef(color: color)
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
        TagDatabase.save(store)
    }

    /// Replace the full editable tag set for multiple apps.
    static func setTags(_ tags: [String], to paths: [String]) {
        var store = TagDatabase.load()
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
        TagDatabase.save(store)
    }

    /// Append tags to multiple apps without disturbing their existing tag sets.
    static func appendTags(_ tags: [String], to paths: [String]) {
        guard !tags.isEmpty, !paths.isEmpty else { return }

        var store = TagDatabase.load()
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
        TagDatabase.save(store)
    }

    /// Remove tags from multiple apps while preserving every unrelated tag.
    static func removeTags(_ tags: [String], from paths: [String]) {
        guard !tags.isEmpty, !paths.isEmpty else { return }

        var store = TagDatabase.load()
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
        TagDatabase.save(store)
    }

    static func reconcileScannedApps(_ apps: [AppInfo]) -> TagDatabase.Store {
        var store = TagDatabase.load()
        let scannedPaths = Set(apps.map { $0.path.path })
        let knownPaths = Set(store.knownAppPaths)

        if store.knownAppPaths.isEmpty {
            store.knownAppPaths = scannedPaths.sorted()
            if apps.isEmpty == false {
                TagDatabase.save(store)
            }
            return store
        }

        let newPaths = scannedPaths.subtracting(knownPaths)
        guard !newPaths.isEmpty else { return store }

        var uncommonPaths = Set(store.uncommonAppPaths)
        for path in newPaths {
            uncommonPaths.insert(path)
            store.uncommonSources[path] = .auto
            if store.appOpenCounts[path] == nil {
                store.appOpenCounts[path] = 0
            }
        }

        store.uncommonAppPaths = uncommonPaths.sorted()
        store.knownAppPaths = knownPaths.union(newPaths).sorted()
        TagDatabase.save(store)
        return store
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
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let limited = String(trimmed.prefix(TagDatabase.maxAppNoteLength))
        if limited.isEmpty {
            store.appNotes.removeValue(forKey: path)
        } else {
            store.appNotes[path] = limited
        }
        TagDatabase.save(store)
    }

    static func moveApp(path: String, from sourceTag: String, to targetTag: String, color: Int, copy: Bool) {
        var store = TagDatabase.load()
        if store.tags[targetTag] == nil {
            store.tags[targetTag] = TagDatabase.TagDef(color: color)
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
        TagDatabase.save(store)
    }

    /// Rename a tag on all apps that have it.
    static func renameTag(from oldName: String, to newName: String) {
        var store = TagDatabase.load()
        // Update tag definition
        if let def = store.tags.removeValue(forKey: oldName) {
            store.tags[newName] = def
        }
        // Update all app assignments
        for (path, var tags) in store.appTags {
            if let idx = tags.firstIndex(of: oldName) {
                tags[idx] = newName
                store.appTags[path] = tags
            }
        }
        TagDatabase.save(store)
    }

    /// Delete a tag completely (from all apps and tag definitions).
    static func deleteTagCompletely(_ tag: String) {
        var store = TagDatabase.load()
        store.tags.removeValue(forKey: tag)
        store.tagOrder.removeAll { $0 == tag }
        for (path, var tags) in store.appTags {
            tags.removeAll { $0 == tag }
            if tags.isEmpty {
                store.appTags.removeValue(forKey: path)
            } else {
                store.appTags[path] = tags
            }
        }
        TagDatabase.save(store)
    }

    /// Set the color for a tag.
    static func setColor(_ color: Int, for tag: String) {
        var store = TagDatabase.load()
        store.tags[tag] = TagDatabase.TagDef(color: color)
        TagDatabase.save(store)
    }
}
