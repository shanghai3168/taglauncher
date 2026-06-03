import Foundation

struct AppLibrarySnapshot {
    let apps: [AppInfo]
    let quickSearchDocuments: [QuickSearchDocument]
    let tagColors: [String: Int]
    let tagOrder: [String]
}

struct AppLibraryRefreshResult {
    let snapshot: AppLibrarySnapshot
    let smartStartResult: SmartStartRunResult
}

struct AppLibrarySmartStartApplyResult {
    let snapshot: AppLibrarySnapshot
    let summary: SmartStartSummary?
}

struct AppLibrarySystemSchemeApplyResult {
    let snapshot: AppLibrarySnapshot
    let summary: SmartStartSummary?
}

enum AppLibraryController {
    static func refresh(useCache: Bool = true) -> AppLibraryRefreshResult {
        let scannedApps = AppIndexer.scan(useCache: useCache)
        let reconciledStore = TagEditor.reconcileScannedApps(scannedApps)
        let smartStartResult = SmartStartService.runIfNeeded(
            apps: scannedApps,
            store: reconciledStore
        )
        return AppLibraryRefreshResult(
            snapshot: makeSnapshot(scannedApps: scannedApps, store: smartStartResult.store),
            smartStartResult: smartStartResult
        )
    }

    static func applySmartStartSuggestion(
        _ draft: SmartCategorizationDraft,
        scannedApps: [AppInfo]
    ) -> AppLibrarySmartStartApplyResult {
        let result = SmartStartService.applySuggestion(draft)
        return AppLibrarySmartStartApplyResult(
            snapshot: makeSnapshot(scannedApps: scannedApps, store: result.store),
            summary: result.summary
        )
    }

    static func applySystemInitialScheme() -> AppLibrarySystemSchemeApplyResult {
        let scannedApps = AppIndexer.scan(useCache: false)
        let result = SmartStartService.applySystemInitialScheme(apps: scannedApps)
        return AppLibrarySystemSchemeApplyResult(
            snapshot: makeSnapshot(scannedApps: scannedApps, store: result.store),
            summary: result.summary
        )
    }

    private static func makeSnapshot(
        scannedApps: [AppInfo],
        store: TagDatabase.Store
    ) -> AppLibrarySnapshot {
        let apps = TagEditor.annotate(apps: scannedApps, store: store)
        return AppLibrarySnapshot(
            apps: apps,
            quickSearchDocuments: QuickSearchEngine.makeDocuments(apps: apps, store: store),
            tagColors: store.tags.mapValues { $0.color },
            tagOrder: TagEditor.orderedTagNames()
        )
    }
}
