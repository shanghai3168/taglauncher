import Foundation

struct AppLibrarySnapshot {
    let apps: [AppInfo]
    let quickSearchDocuments: [QuickSearchDocument]
    let tagColors: [String: Int]
    let tagOrder: [String]
    let tagDefinitions: [String: TagDatabase.TagDef]
    let containerAppOrder: [String: [String]]
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

struct AppLibraryUncategorizedResetResult {
    let snapshot: AppLibrarySnapshot
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

    static func resetToUncategorized() -> AppLibraryUncategorizedResetResult {
        let scannedApps = AppIndexer.scan(useCache: false)
        let store = TagDatabase.resetAppTagAssignmentsToUncategorized()
        return AppLibraryUncategorizedResetResult(
            snapshot: makeSnapshot(scannedApps: scannedApps, store: store)
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
            tagOrder: TagEditor.orderedTagNames(in: store),
            tagDefinitions: store.tags,
            containerAppOrder: TagDatabase.normalizedContainerAppOrder(
                store.containerAppOrder,
                tags: store.tags,
                appTags: store.appTags
            )
        )
    }
}
