import AppKit
import Darwin
import Foundation

enum TagLauncherProcessSingleton {
    private static let lockURL = AppIdentity.applicationSupportDirectory
        .appendingPathComponent("TagLauncher.lock")
    private static let activationNotification = Notification.Name("TagLauncherExternalActivationRequested")

    static func acquireOrHandOffAndExit() -> FileHandle {
        do {
            try FileManager.default.createDirectory(
                at: AppIdentity.applicationSupportDirectory,
                withIntermediateDirectories: true
            )
            if !FileManager.default.fileExists(atPath: lockURL.path) {
                _ = FileManager.default.createFile(atPath: lockURL.path, contents: nil)
            }

            let lockFile = try FileHandle(forUpdating: lockURL)
            if flock(lockFile.fileDescriptor, LOCK_EX | LOCK_NB) == 0 {
                return lockFile
            }
            try? lockFile.close()
        } catch {
            // If locking fails, avoiding a duplicate visible instance is safer than
            // letting another Dock tile appear.
        }

        handOffAndExit()
    }

    private static func handOffAndExit() -> Never {
        let arguments = CommandLine.arguments.dropFirst()
        let shouldShowOverlay = arguments.contains("--show-overlay")
        if !shouldShowOverlay {
            NSApplication.shared.setActivationPolicy(.accessory)
        }
        let ownerInstance = NSRunningApplication
            .runningApplications(withBundleIdentifier: AppIdentity.bundleIdentifier)
            .filter { $0.processIdentifier != getpid() && !$0.isTerminated }
            .sorted(by: prefersRunningInstance)
            .first

        for delay in [0.0, 0.15, 0.4] {
            if delay > 0 {
                Thread.sleep(forTimeInterval: delay)
            }
            DistributedNotificationCenter.default().postNotificationName(
                activationNotification,
                object: AppIdentity.bundleIdentifier,
                userInfo: ["showOverlay": shouldShowOverlay],
                deliverImmediately: true
            )
            if shouldShowOverlay {
                ownerInstance?.activate()
            }
        }
        exit(0)
    }

    private static func prefersRunningInstance(
        _ lhs: NSRunningApplication,
        _ rhs: NSRunningApplication
    ) -> Bool {
        let lhsLaunchDate = lhs.launchDate ?? .distantFuture
        let rhsLaunchDate = rhs.launchDate ?? .distantFuture
        if lhsLaunchDate != rhsLaunchDate {
            return lhsLaunchDate < rhsLaunchDate
        }
        return lhs.processIdentifier < rhs.processIdentifier
    }
}
