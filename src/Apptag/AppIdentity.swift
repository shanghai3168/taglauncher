import Foundation

enum AppIdentity {
    static let displayName = "TagLauncher"
    static let bundleIdentifier = "com.taglauncher.app"
    static let applicationSupportDirectoryName = "TagLauncher"

    static var applicationSupportDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(applicationSupportDirectoryName)")
    }

    static let statusItemAutosaveName = "\(bundleIdentifier).statusItem"
    static let launchAgentLabel = bundleIdentifier
    static let categorySchemeBatchQueueLabel = "\(bundleIdentifier).category-scheme-batch"
}
