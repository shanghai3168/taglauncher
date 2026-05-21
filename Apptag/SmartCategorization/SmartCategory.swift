import Foundation

// MARK: - Smart Start Category Identity

enum SmartCategoryID: String, CaseIterable, Codable, Hashable, Identifiable {
    case browser
    case communication
    case gtd = "GTD"
    case notes = "Notes"
    case meeting = "Meeting"
    case office
    case pdf = "PDF"
    case fileManagement = "file-management"
    case transfer
    case productivity
    case development
    case design
    case aiTools = "ai-tools"
    case apiTools = "api-tools"
    case databaseTools = "database-tools"
    case devops
    case ide
    case runtimeSDK = "runtime-sdk"
    case terminalTools = "terminal-tools"
    case font = "Font"
    case uiPrototyping = "ui-prototyping"
    case threeDCAD = "3d-cad"
    case diagramming
    case writing
    case media
    case video
    case audio
    case picturePhoto = "picture-photo"
    case utilities
    case system
    case systemEnhancement = "system-enhancement"
    case systemMaintenance = "system-maintenance"
    case windowManagement = "window-management"
    case deviceManagement = "device-management"
    case inputTools = "input-tools"
    case automation = "Automation"
    case networkTools = "network-tools"
    case entertainment
    case game
    case finance
    case education
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
        case .gtd:
            return "Tasks & GTD"
        case .notes:
            return "Notes"
        case .meeting:
            return "Meetings"
        case .office:
            return "Office"
        case .pdf:
            return "PDF"
        case .fileManagement:
            return "File Management"
        case .transfer:
            return "Uploads & Downloads"
        case .productivity:
            return "Productivity"
        case .development:
            return "Development"
        case .design:
            return "Design"
        case .aiTools:
            return "AI Tools"
        case .apiTools:
            return "API Tools"
        case .databaseTools:
            return "Databases"
        case .devops:
            return "DevOps"
        case .ide:
            return "IDEs"
        case .runtimeSDK:
            return "Runtimes & SDKs"
        case .terminalTools:
            return "Terminal Tools"
        case .font:
            return "Fonts"
        case .uiPrototyping:
            return "UI Prototyping"
        case .threeDCAD:
            return "3D & CAD"
        case .diagramming:
            return "Diagramming"
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
        case .systemMaintenance:
            return "System Maintenance"
        case .windowManagement:
            return "Window Management"
        case .deviceManagement:
            return "Device Management"
        case .inputTools:
            return "Input Tools"
        case .automation:
            return "Automation"
        case .networkTools:
            return "Network Tools"
        case .entertainment:
            return "Entertainment"
        case .game:
            return "Games"
        case .finance:
            return "Finance"
        case .education:
            return "Education"
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
        case .gtd:
            return 2
        case .notes:
            return 2
        case .meeting:
            return 4
        case .office:
            return 2
        case .pdf:
            return 2
        case .fileManagement:
            return 4
        case .transfer:
            return 4
        case .productivity:
            return 2
        case .development:
            return 3
        case .design:
            return 7
        case .aiTools:
            return 3
        case .apiTools:
            return 3
        case .databaseTools:
            return 5
        case .devops:
            return 5
        case .ide:
            return 3
        case .runtimeSDK:
            return 3
        case .terminalTools:
            return 0
        case .font:
            return 7
        case .uiPrototyping:
            return 7
        case .threeDCAD:
            return 7
        case .diagramming:
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
        case .systemMaintenance:
            return 0
        case .windowManagement:
            return 0
        case .deviceManagement:
            return 0
        case .inputTools:
            return 0
        case .automation:
            return 5
        case .networkTools:
            return 5
        case .entertainment:
            return 7
        case .game:
            return 6
        case .finance:
            return 2
        case .education:
            return 2
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
        .gtd,
        .notes,
        .meeting,
        .office,
        .pdf,
        .fileManagement,
        .transfer,
        .aiTools,
        .apiTools,
        .databaseTools,
        .devops,
        .ide,
        .runtimeSDK,
        .terminalTools,
        .font,
        .uiPrototyping,
        .threeDCAD,
        .diagramming,
        .writing,
        .media,
        .video,
        .audio,
        .picturePhoto,
        .utilities,
        .system,
        .systemMaintenance,
        .windowManagement,
        .deviceManagement,
        .inputTools,
        .automation,
        .networkTools,
        .entertainment,
        .game,
        .finance,
        .education,
        .security,
        .other
    ]

    static let definitions: [SmartCategoryDefinition] = orderedIDs.map {
        SmartCategoryDefinition(id: $0)
    }
}
