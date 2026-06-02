import Foundation

enum Diagnostics {
    private static let enabledKey = "diagnosticLoggingEnabled"
    private static let queue = DispatchQueue(label: "com.taglauncher.app.diagnostics")

    static var logURL: URL {
        AppIdentity.applicationSupportDirectory
            .appendingPathComponent("TagLauncher-diagnostics.log")
    }

    static func log(_ event: String, _ fields: [String: CustomStringConvertible?] = [:]) {
        guard UserDefaults.standard.bool(forKey: enabledKey) else { return }
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let suffix = fields
            .sorted { $0.key < $1.key }
            .map { key, value in "\(key)=\(value?.description ?? "nil")" }
            .joined(separator: " ")
        let line = suffix.isEmpty
            ? "\(timestamp) \(event)\n"
            : "\(timestamp) \(event) \(suffix)\n"

        queue.async {
            do {
                try FileManager.default.createDirectory(
                    at: AppIdentity.applicationSupportDirectory,
                    withIntermediateDirectories: true
                )
                if !FileManager.default.fileExists(atPath: logURL.path) {
                    FileManager.default.createFile(atPath: logURL.path, contents: nil)
                }
                let handle = try FileHandle(forWritingTo: logURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                if let data = line.data(using: .utf8) {
                    try handle.write(contentsOf: data)
                }
            } catch {
                fputs("[TagLauncher] Diagnostics log failed: \(error)\n", stderr)
            }
        }
    }

}
