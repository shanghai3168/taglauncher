import Foundation

// MARK: - Smart Start Draft Contract

enum SmartCategorizationDraftSource: String, Codable, Hashable {
    case localSmartStart
    case aiImprove
}

enum SmartCategorizationAssignmentSource: String, Codable, Hashable {
    case localCatalog
    case localHeuristic
    case manualSeed
    case aiImprove
}

struct SmartCategorizationDraft: Codable, Hashable {
    static let currentVersion = 1

    let version: Int
    let draftSource: SmartCategorizationDraftSource
    let categories: [SmartCategoryDefinition]
    let categoryOrder: [SmartCategoryID]
    let assignments: [SmartAppCategorizationAssignment]
    let unassigned: [SmartUnassignedApp]
    let warnings: [SmartCategorizationWarning]

    init(
        version: Int = Self.currentVersion,
        draftSource: SmartCategorizationDraftSource,
        categories: [SmartCategoryDefinition] = SmartCategoryDefaults.definitions,
        categoryOrder: [SmartCategoryID] = SmartCategoryDefaults.orderedIDs,
        assignments: [SmartAppCategorizationAssignment] = [],
        unassigned: [SmartUnassignedApp] = [],
        warnings: [SmartCategorizationWarning] = []
    ) {
        self.version = version
        self.draftSource = draftSource
        self.categories = categories
        self.categoryOrder = categoryOrder
        self.assignments = assignments
        self.unassigned = unassigned
        self.warnings = warnings
    }
}

struct SmartAppCategorizationAssignment: Codable, Hashable, Identifiable {
    let appName: String
    let bundleIdentifier: String?
    let path: String?
    let categoryIDs: [SmartCategoryID]
    let confidence: Double
    let source: SmartCategorizationAssignmentSource
    let reason: String
    let provenance: [String]
    let defaultNote: String?
    let defaultNoteCandidates: [String]

    var id: String {
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            return "bundle:\(bundleIdentifier)"
        }
        if let path, !path.isEmpty {
            return "path:\(path)"
        }
        return "name:\(appName)"
    }

    var primaryCategoryID: SmartCategoryID? {
        categoryIDs.first
    }

    init(
        appName: String,
        bundleIdentifier: String? = nil,
        path: String? = nil,
        categoryIDs: [SmartCategoryID],
        confidence: Double,
        source: SmartCategorizationAssignmentSource,
        reason: String,
        provenance: [String] = [],
        defaultNote: String? = nil,
        defaultNoteCandidates: [String] = []
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.categoryIDs = Self.uniqueOrdered(categoryIDs)
        self.confidence = confidence
        self.source = source
        self.reason = reason
        self.provenance = provenance
        self.defaultNote = defaultNote
        self.defaultNoteCandidates = defaultNoteCandidates
    }

    private static func uniqueOrdered(_ ids: [SmartCategoryID]) -> [SmartCategoryID] {
        var seen = Set<SmartCategoryID>()
        return ids.filter { seen.insert($0).inserted }
    }
}

struct SmartUnassignedApp: Codable, Hashable, Identifiable {
    let appName: String
    let bundleIdentifier: String?
    let path: String?
    let reason: String?

    var id: String {
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            return "bundle:\(bundleIdentifier)"
        }
        if let path, !path.isEmpty {
            return "path:\(path)"
        }
        return "name:\(appName)"
    }
}

struct SmartCategorizationWarning: Codable, Hashable, Identifiable {
    let code: String
    let message: String
    let appName: String?

    var id: String {
        [code, appName, message]
            .compactMap { $0 }
            .joined(separator: "|")
    }
}
