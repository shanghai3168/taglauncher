import Foundation

// MARK: - Smart Start Category Identity

enum SmartCategoryID: String, CaseIterable, Codable, Hashable, Identifiable {
    case browser
    case communication
    case productivity
    case fileManagement = "file-management"
    case transfer
    case development
    case design
    case writing
    case media
    case video
    case audio
    case picturePhoto = "picture-photo"
    case utilities
    case system
    case systemEnhancement = "system-enhancement"
    case entertainment
    case game
    case finance
    case education
    case aiTools = "ai-tools"
    case security
    case other

    var id: String { rawValue }

    var localizationKey: String {
        "smart.category.\(rawValue)"
    }

    var defaultDisplayName: String {
        switch self {
        case .browser:
            return "Browsers"
        case .communication:
            return "Communication"
        case .productivity:
            return "Productivity"
        case .fileManagement:
            return "File Management"
        case .transfer:
            return "Uploads & Downloads"
        case .development:
            return "Development"
        case .design:
            return "Design"
        case .writing:
            return "Writing"
        case .media:
            return "Media"
        case .video:
            return "Video"
        case .audio:
            return "Audio"
        case .picturePhoto:
            return "Pictures & Photos"
        case .utilities:
            return "Utilities"
        case .system:
            return "System Apps"
        case .systemEnhancement:
            return "System Enhancements"
        case .entertainment:
            return "Entertainment"
        case .game:
            return "Games"
        case .finance:
            return "Finance"
        case .education:
            return "Education"
        case .aiTools:
            return "AI Tools"
        case .security:
            return "Security"
        case .other:
            return "Other"
        }
    }

    var localizedDisplayName: String {
        let localized = tr(localizationKey)
        return localized == localizationKey ? defaultDisplayName : localized
    }

    func displayName(forLanguageCode code: String) -> String {
        let localized = L10n.loadedTranslation(localizationKey, for: code)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let localized, !localized.isEmpty {
            return localized
        }
        return defaultDisplayName
    }

    var defaultColorIndex: Int {
        switch self {
        case .browser:
            return 4
        case .communication:
            return 4
        case .productivity:
            return 2
        case .fileManagement:
            return 4
        case .transfer:
            return 4
        case .development:
            return 3
        case .design:
            return 7
        case .writing:
            return 2
        case .media:
            return 7
        case .video:
            return 7
        case .audio:
            return 7
        case .picturePhoto:
            return 7
        case .utilities:
            return 5
        case .system:
            return 0
        case .systemEnhancement:
            return 0
        case .entertainment:
            return 7
        case .game:
            return 6
        case .finance:
            return 2
        case .education:
            return 2
        case .aiTools:
            return 3
        case .security:
            return 1
        case .other:
            return 0
        }
    }
}

struct SmartCategoryDefinition: Codable, Hashable, Identifiable {
    let id: SmartCategoryID
    let localizationKey: String
    let defaultDisplayName: String
    let colorIndex: Int

    init(
        id: SmartCategoryID,
        localizationKey: String? = nil,
        defaultDisplayName: String? = nil,
        colorIndex: Int? = nil
    ) {
        self.id = id
        self.localizationKey = localizationKey ?? id.localizationKey
        self.defaultDisplayName = defaultDisplayName ?? id.defaultDisplayName
        self.colorIndex = colorIndex ?? id.defaultColorIndex
    }
}

enum SmartCategoryDefaults {
    static let orderedIDs: [SmartCategoryID] = [
        .browser,
        .communication,
        .productivity,
        .fileManagement,
        .transfer,
        .development,
        .design,
        .writing,
        .media,
        .video,
        .audio,
        .picturePhoto,
        .utilities,
        .system,
        .systemEnhancement,
        .entertainment,
        .game,
        .finance,
        .education,
        .aiTools,
        .security,
        .other
    ]

    static let definitions: [SmartCategoryDefinition] = orderedIDs.map {
        SmartCategoryDefinition(id: $0)
    }
}
