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

    /// True if this is an Apple pre-installed app.
    var isAppleApp: Bool {
        if let bid = bundleIdentifier, bid.hasPrefix("com.apple.") { return true }
        return path.path.hasPrefix("/System/Applications/")
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
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")
    ]

    /// Scan all standard locations. Tags are annotated from TagDatabase by the caller.
    static func scan() -> [AppInfo] {
        var seen = Set<URL>()
        var apps: [AppInfo] = []

        for baseURL in searchPaths {
            guard let enumerator = FileManager.default.enumerator(
                at: baseURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else { continue }
                guard !seen.contains(url) else { continue }
                seen.insert(url)

                let name = url.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                icon.size = NSSize(width: 96, height: 96)
                var bundleId: String? = nil
                if let bundle = Bundle(url: url) {
                    bundleId = bundle.bundleIdentifier
                }

                apps.append(AppInfo(
                    name: name, path: url, tags: [],
                    bundleIdentifier: bundleId, icon: icon
                ))
            }
        }

        return apps.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
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

    // MARK: Storage types

    struct TagDef: Codable, Equatable {
        var color: Int
    }

    struct Store: Codable {
        var version: Int = 1
        var tags: [String: TagDef] = [:]
        var appTags: [String: [String]] = [:]  // path → tag names
        var tagOrder: [String] = []  // display order; empty → alpha sort
    }

    // MARK: Paths

    private static var storeDir: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Apptag")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var storeURL: URL { storeDir.appendingPathComponent("tags.json") }

    // MARK: Load / Save

    static func load() -> Store {
        guard let data = try? Data(contentsOf: storeURL),
              let store = try? JSONDecoder().decode(Store.self, from: data)
        else { return Store() }
        return store
    }

    static func save(_ store: Store) {
        guard let data = try? JSONEncoder().encode(store) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    // MARK: Export / Import

    static func exportTo(_ url: URL) throws {
        try FileManager.default.copyItem(at: storeURL, to: url)
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
        let store = TagDatabase.load()
        return apps.map { app in
            let appTags = store.appTags[app.path.path] ?? []
            return AppInfo(
                name: app.name, path: app.path, tags: appTags,
                bundleIdentifier: app.bundleIdentifier, icon: app.icon
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
        let validTags = tags.filter { store.tags[$0] != nil }
        for path in paths {
            if validTags.isEmpty {
                store.appTags.removeValue(forKey: path)
            } else {
                store.appTags[path] = validTags
            }
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
