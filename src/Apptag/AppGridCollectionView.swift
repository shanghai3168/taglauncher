import SwiftUI
import AppKit
import Carbon.HIToolbox

fileprivate enum AppGridCollectionDisplayMode: Equatable {
    case flat
    case masonryContainer
    case gridContainer

    init(_ rawValue: String) {
        switch rawValue {
        case "container", "coloredContainer":
            self = .masonryContainer
        case "gridContainer", "coloredGridContainer":
            self = .gridContainer
        default:
            self = .flat
        }
    }

    var usesCardSurface: Bool {
        self != .flat
    }
}

fileprivate struct AppGridBubbleSuppressionReasons: OptionSet {
    let rawValue: Int

    static let externalInteraction = AppGridBubbleSuppressionReasons(rawValue: 1 << 0)
    static let scroll = AppGridBubbleSuppressionReasons(rawValue: 1 << 1)
    static let usageTipsHover = AppGridBubbleSuppressionReasons(rawValue: 1 << 2)
}

struct AppGridUsageTip: Equatable {
    let id: Int
    let titleKey: String
    let detailKey: String
}

enum AppGridUsageTipsMetrics {
    static let barHeight: CGFloat = 136
    static let reservedHeight: CGFloat = 176
    static let bottomMargin: CGFloat = 20
    static let horizontalInset: CGFloat = 24
    static let minWidth: CGFloat = 640
}

struct AppGridCollectionView: NSViewRepresentable {
    let groups: [TagGroup]
    let tagColors: [String: Int]
    let displayMode: String
    let iconSize: CGFloat
    let showNames: Bool
    let bubbleDisabled: Bool
    let showUncommonAppBubbles: Bool
    let highlightedGroupName: String?
    let bottomContentPadding: CGFloat
    let usageTipsVisible: Bool
    let usageTips: [AppGridUsageTip]
    @Binding var selectedUsageTipIndex: Int
    let contentRevision: Int
    let scrollTargetID: String?
    let scrollRequestToken: Int
    let onSelectApp: (AppInfo) -> Void
    let onBubbleHover: (AppInfo, CGRect, AppBubbleHoverEvent) -> Void
    let onEditNote: (AppInfo, CGRect) -> Void
    let onDropApp: (String, String, String, Bool) -> Void
    let onDropOutsideGroup: (String, String, Bool) -> Void
    let onReorderApps: (String, [String]) -> Void
    let onGroupActivate: (String) -> Void
    let onScrollActivity: () -> Void
    let onDragModeChange: (Bool) -> Void
    let onUsageTipsHoverChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> AppGridCollectionHostView {
        let view = AppGridCollectionHostView()
        view.configure(coordinator: context.coordinator)
        return view
    }

    func updateNSView(_ view: AppGridCollectionHostView, context: Context) {
        let selectedUsageTipIndexBinding = $selectedUsageTipIndex
        context.coordinator.update(
            groups: groups,
            tagColors: tagColors,
            displayMode: displayMode,
            iconSize: iconSize,
            showNames: showNames,
            bubbleDisabled: bubbleDisabled,
            showUncommonAppBubbles: showUncommonAppBubbles,
            highlightedGroupName: highlightedGroupName,
            bottomContentPadding: bottomContentPadding,
            usageTipsVisible: usageTipsVisible,
            usageTips: usageTips,
            selectedUsageTipIndex: selectedUsageTipIndex,
            contentRevision: contentRevision,
            scrollTargetID: scrollTargetID,
            scrollRequestToken: scrollRequestToken,
            onSelectApp: onSelectApp,
            onBubbleHover: onBubbleHover,
            onEditNote: onEditNote,
            onDropApp: onDropApp,
            onDropOutsideGroup: onDropOutsideGroup,
            onReorderApps: onReorderApps,
            onGroupActivate: onGroupActivate,
            onScrollActivity: onScrollActivity,
            onDragModeChange: onDragModeChange,
            onUsageTipIndexChange: { selectedUsageTipIndexBinding.wrappedValue = $0 },
            onUsageTipsHoverChange: onUsageTipsHoverChange
        )
        view.applyCoordinatorUpdate()
    }

    final class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate {
        var groups: [TagGroup] = []
        var tagColors: [String: Int] = [:]
        var displayMode = AppDefaults.displayMode
        var iconSize: CGFloat = AppDefaults.iconSize
        var showNames = true
        private var externalBubbleDisabled = false
        private var scrollBubbleDisabled = false
        var showUncommonAppBubbles = AppDefaults.showUncommonAppBubbles
        var highlightedGroupName: String?
        var bottomContentPadding: CGFloat = 0
        var usageTipsVisible = false
        var usageTips: [AppGridUsageTip] = []
        var selectedUsageTipIndex = 0
        private var usageTipsBubbleDisabled = false
        var contentRevision = 0
        var scrollTargetID: String?
        var scrollRequestToken = 0
        var lastHandledScrollRequestToken = 0
        var contentSignature = ""
        var needsReload = true

        var onSelectApp: (AppInfo) -> Void = { _ in }
        var onBubbleHover: (AppInfo, CGRect, AppBubbleHoverEvent) -> Void = { _, _, _ in }
        var onEditNote: (AppInfo, CGRect) -> Void = { _, _ in }
        var onDropApp: (String, String, String, Bool) -> Void = { _, _, _, _ in }
        var onDropOutsideGroup: (String, String, Bool) -> Void = { _, _, _ in }
        var onReorderApps: (String, [String]) -> Void = { _, _ in }
        var onGroupActivate: (String) -> Void = { _ in }
        var onScrollActivity: () -> Void = {}
        var onDragModeChange: (Bool) -> Void = { _ in }
        var onUsageTipIndexChange: (Int) -> Void = { _ in }
        var onUsageTipsHoverChange: (Bool) -> Void = { _ in }

        private weak var activeReorderCard: AppGridGroupCardView?
        private var activeDragPath = ""
        private var activeDragSourceContainerID = ""
        private var lastReorderContainerID = ""
        private var lastReorderScreenFrame: NSRect?

        func update(
            groups: [TagGroup],
            tagColors: [String: Int],
            displayMode: String,
            iconSize: CGFloat,
            showNames: Bool,
            bubbleDisabled: Bool,
            showUncommonAppBubbles: Bool,
            highlightedGroupName: String?,
            bottomContentPadding: CGFloat,
            usageTipsVisible: Bool,
            usageTips: [AppGridUsageTip],
            selectedUsageTipIndex: Int,
            contentRevision: Int,
            scrollTargetID: String?,
            scrollRequestToken: Int,
            onSelectApp: @escaping (AppInfo) -> Void,
            onBubbleHover: @escaping (AppInfo, CGRect, AppBubbleHoverEvent) -> Void,
            onEditNote: @escaping (AppInfo, CGRect) -> Void,
            onDropApp: @escaping (String, String, String, Bool) -> Void,
            onDropOutsideGroup: @escaping (String, String, Bool) -> Void,
            onReorderApps: @escaping (String, [String]) -> Void,
            onGroupActivate: @escaping (String) -> Void,
            onScrollActivity: @escaping () -> Void,
            onDragModeChange: @escaping (Bool) -> Void,
            onUsageTipIndexChange: @escaping (Int) -> Void,
            onUsageTipsHoverChange: @escaping (Bool) -> Void
        ) {
            self.groups = groups
            self.tagColors = tagColors
            self.displayMode = displayMode
            self.iconSize = iconSize
            self.showNames = showNames
            self.externalBubbleDisabled = bubbleDisabled
            self.showUncommonAppBubbles = showUncommonAppBubbles
            self.highlightedGroupName = highlightedGroupName
            self.bottomContentPadding = max(0, bottomContentPadding)
            self.usageTipsVisible = usageTipsVisible && !usageTips.isEmpty
            self.usageTips = usageTips
            self.selectedUsageTipIndex = Self.clampedUsageTipIndex(selectedUsageTipIndex, tips: usageTips)
            self.contentRevision = contentRevision
            self.scrollTargetID = scrollTargetID
            self.scrollRequestToken = scrollRequestToken
            self.onSelectApp = onSelectApp
            self.onBubbleHover = onBubbleHover
            self.onEditNote = onEditNote
            self.onDropApp = onDropApp
            self.onDropOutsideGroup = onDropOutsideGroup
            self.onReorderApps = onReorderApps
            self.onGroupActivate = onGroupActivate
            self.onScrollActivity = onScrollActivity
            self.onDragModeChange = onDragModeChange
            self.onUsageTipIndexChange = onUsageTipIndexChange
            self.onUsageTipsHoverChange = onUsageTipsHoverChange
            if !self.usageTipsVisible {
                usageTipsBubbleDisabled = false
            }

            let nextSignature = Self.signature(
                tagColors: tagColors,
                displayMode: displayMode,
                iconSize: iconSize,
                showNames: showNames,
                showUncommonAppBubbles: showUncommonAppBubbles,
                bottomContentPadding: self.bottomContentPadding,
                contentRevision: contentRevision
            )
            if nextSignature != contentSignature {
                contentSignature = nextSignature
                needsReload = true
            }
        }

        func numberOfSections(in collectionView: NSCollectionView) -> Int {
            1
        }

        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            groups.count
        }

        func collectionView(
            _ collectionView: NSCollectionView,
            itemForRepresentedObjectAt indexPath: IndexPath
        ) -> NSCollectionViewItem {
            let item = collectionView.makeItem(
                withIdentifier: AppGridGroupCollectionItem.reuseIdentifier,
                for: indexPath
            )
            guard let groupItem = item as? AppGridGroupCollectionItem,
                  indexPath.item < groups.count
            else { return item }

            groupItem.configure(group: groups[indexPath.item], coordinator: self)
            return groupItem
        }

        func scrollIndex(for tagID: String) -> Int? {
            groups.firstIndex { $0.id == tagID || $0.name == tagID }
        }

        fileprivate var displayStyle: AppGridCollectionDisplayMode {
            AppGridCollectionDisplayMode(displayMode)
        }

        var isColoredContainerMode: Bool {
            displayMode == "coloredContainer" || displayMode == "coloredGridContainer"
        }

        var isColorlessContainerMode: Bool {
            displayMode == "container" || displayMode == "gridContainer"
        }

        fileprivate var bubbleSuppressionReasons: AppGridBubbleSuppressionReasons {
            var reasons: AppGridBubbleSuppressionReasons = []
            if externalBubbleDisabled {
                reasons.insert(.externalInteraction)
            }
            if scrollBubbleDisabled {
                reasons.insert(.scroll)
            }
            if usageTipsBubbleDisabled {
                reasons.insert(.usageTipsHover)
            }
            return reasons
        }

        var bubbleDisabled: Bool {
            !bubbleSuppressionReasons.isEmpty
        }

        @discardableResult
        func setScrollBubbleDisabled(_ disabled: Bool) -> Bool {
            guard scrollBubbleDisabled != disabled else { return false }
            scrollBubbleDisabled = disabled
            return true
        }

        @discardableResult
        func setUsageTipsBubbleDisabled(_ disabled: Bool) -> Bool {
            guard usageTipsBubbleDisabled != disabled else { return false }
            usageTipsBubbleDisabled = disabled
            return true
        }

        func selectUsageTip(offset: Int) {
            guard !usageTips.isEmpty else { return }
            let count = usageTips.count
            let nextIndex = (selectedUsageTipIndex + offset + count) % count
            guard nextIndex != selectedUsageTipIndex else { return }
            selectedUsageTipIndex = nextIndex
            onUsageTipIndexChange(nextIndex)
        }

        fileprivate func beginAppIconDrag(path: String, sourceContainerID: String) {
            activeDragPath = path
            activeDragSourceContainerID = sourceContainerID
            lastReorderContainerID = ""
            lastReorderScreenFrame = nil
            clearReorderInsertion()
            onDragModeChange(true)
        }

        fileprivate func endAppIconDrag() {
            clearReorderInsertion()
            activeDragPath = ""
            activeDragSourceContainerID = ""
            lastReorderContainerID = ""
            lastReorderScreenFrame = nil
            onDragModeChange(false)
        }

        fileprivate func cancelAppIconDrag() {
            clearReorderInsertion()
            activeDragPath = ""
            activeDragSourceContainerID = ""
            lastReorderContainerID = ""
            lastReorderScreenFrame = nil
            onDragModeChange(false)
        }

        fileprivate func setReorderInsertion(card: AppGridGroupCardView, insertionIndex: Int) {
            if let activeReorderCard, activeReorderCard !== card {
                activeReorderCard.clearReorderInsertion()
            }
            activeReorderCard = card
            lastReorderContainerID = card.containerID
            lastReorderScreenFrame = card.screenFrame()
            card.setReorderInsertion(index: insertionIndex)
        }

        fileprivate func clearReorderInsertion(card: AppGridGroupCardView? = nil) {
            if let card {
                card.clearReorderInsertion()
                if activeReorderCard === card {
                    activeReorderCard = nil
                }
                if lastReorderContainerID == card.containerID {
                    lastReorderContainerID = ""
                    lastReorderScreenFrame = nil
                }
                return
            }
            activeReorderCard?.clearReorderInsertion()
            activeReorderCard = nil
            lastReorderContainerID = ""
            lastReorderScreenFrame = nil
        }

        fileprivate func activeReorderPath(in containerID: String, copy: Bool) -> String? {
            guard !copy,
                  !activeDragPath.isEmpty,
                  activeDragSourceContainerID == containerID
            else { return nil }
            return activeDragPath
        }

        fileprivate func shouldCancelEmptyDropForActiveReorder(
            path: String,
            screenPoint: NSPoint,
            copy: Bool
        ) -> Bool {
            guard !copy,
                  !activeDragPath.isEmpty,
                  activeDragPath == path,
                  activeDragSourceContainerID == lastReorderContainerID,
                  let lastReorderScreenFrame
            else { return false }

            let guardOutset = AppGridCollectionMetrics.reorderEmptyDropCancelOutset
            return lastReorderScreenFrame.insetBy(dx: -guardOutset, dy: -guardOutset).contains(screenPoint)
        }

        private static func signature(
            tagColors: [String: Int],
            displayMode: String,
            iconSize: CGFloat,
            showNames: Bool,
            showUncommonAppBubbles: Bool,
            bottomContentPadding: CGFloat,
            contentRevision: Int
        ) -> String {
            let colorPart = tagColors
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ",")
            return [
                displayMode,
                "\(Int(iconSize.rounded()))",
                showNames ? "names" : "nonames",
                showUncommonAppBubbles ? "uncommon" : "allbubbles",
                "bottom=\(Int(bottomContentPadding.rounded()))",
                colorPart,
                "rev=\(contentRevision)"
            ].joined(separator: "|")
        }

        private static func clampedUsageTipIndex(_ index: Int, tips: [AppGridUsageTip]) -> Int {
            guard !tips.isEmpty else { return 0 }
            return min(max(0, index), tips.count - 1)
        }
    }
}

private final class AppGridScrollView: NSScrollView {
    override var acceptsFirstResponder: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        super.scrollWheel(with: event)
    }
}

final class AppGridCollectionHostView: NSView, AppEmptyDropReceivingView {
    private let emptyDropTargetID = UUID()
    private let scrollView = AppGridScrollView()
    private let collectionView = NSCollectionView()
    private let gridLayout = AppGridContainerCollectionLayout()
    private let usageTipsShieldView = AppGridUsageTipsShieldView()
    private let usageTipsView = AppGridUsageTipsNSView()
    private weak var coordinator: AppGridCollectionView.Coordinator?
    private var scrollObserver: NSObjectProtocol?
    private var lastLayoutSize: NSSize = .zero
    private var lastReportedBoundsOrigin: NSPoint?
    private var scrollUnfreezeWorkItem: DispatchWorkItem?
    private var scrollActivityIsActive = false
    private var usageTipsEventRegionIsClaimed = false
    private var usageTipsMouseMonitor: Any?

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        if let scrollObserver {
            NotificationCenter.default.removeObserver(scrollObserver)
        }
        removeUsageTipsMouseMonitor()
        scrollUnfreezeWorkItem?.cancel()
        coordinator?.cancelAppIconDrag()
        AppDragCoordinator.shared.unregisterEmptyDropTarget(id: emptyDropTargetID)
    }

    func configure(coordinator: AppGridCollectionView.Coordinator) {
        self.coordinator = coordinator
        gridLayout.coordinator = coordinator
        usageTipsView.coordinator = coordinator
        collectionView.dataSource = coordinator
        collectionView.delegate = coordinator
    }

    func applyCoordinatorUpdate() {
        guard let coordinator else { return }
        if coordinator.needsReload {
            coordinator.needsReload = false
            collectionView.reloadData()
            gridLayout.invalidateLayout()
        } else {
            refreshVisibleRuntimeState()
        }

        if coordinator.scrollRequestToken != coordinator.lastHandledScrollRequestToken {
            coordinator.lastHandledScrollRequestToken = coordinator.scrollRequestToken
            if let target = coordinator.scrollTargetID,
               let index = coordinator.scrollIndex(for: target) {
                DispatchQueue.main.async { [weak self] in
                    self?.collectionView.scrollToItems(
                        at: [IndexPath(item: index, section: 0)],
                        scrollPosition: .top
                    )
                }
            }
        }
        usageTipsView.applyCoordinatorState()
        positionUsageTipsView()
    }

    override func layout() {
        super.layout()
        scrollView.frame = bounds
        positionUsageTipsView()
        if lastLayoutSize != bounds.size {
            lastLayoutSize = bounds.size
            gridLayout.invalidateLayout()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            removeUsageTipsMouseMonitor()
            AppDragCoordinator.shared.cancelDrag()
            coordinator?.cancelAppIconDrag()
            AppDragCoordinator.shared.unregisterEmptyDropTarget(id: emptyDropTargetID)
        } else {
            installUsageTipsMouseMonitor()
            AppDragCoordinator.shared.registerEmptyDropTarget(id: emptyDropTargetID, view: self)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if !usageTipsView.isHidden,
           usageTipsView.frame.contains(point) {
            let tipsPoint = usageTipsView.convert(point, from: self)
            return usageTipsView.hitTest(tipsPoint) ?? usageTipsView
        }
        return super.hitTest(point)
    }

    func performEmptyDrop(path: String, source: String, screenPoint: NSPoint, copy: Bool) {
        guard let coordinator,
              coordinator.displayStyle != .flat
        else { return }
        if coordinator.shouldCancelEmptyDropForActiveReorder(
            path: path,
            screenPoint: screenPoint,
            copy: copy
        ) {
            coordinator.cancelAppIconDrag()
            return
        }
        DispatchQueue.main.async {
            coordinator.onDropOutsideGroup(path, source, copy)
        }
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        collectionView.collectionViewLayout = gridLayout
        collectionView.backgroundColors = [.clear]
        collectionView.isSelectable = false
        collectionView.register(
            AppGridGroupCollectionItem.self,
            forItemWithIdentifier: AppGridGroupCollectionItem.reuseIdentifier
        )

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = collectionView
        addSubview(scrollView)
        usageTipsShieldView.isHidden = true
        usageTipsShieldView.onClaim = { [weak self] in
            self?.claimUsageTipsEventRegion()
        }
        usageTipsShieldView.onRelease = { [weak self] in
            self?.releaseUsageTipsEventRegion()
        }
        usageTipsView.isHidden = true
        addSubview(usageTipsShieldView, positioned: .above, relativeTo: scrollView)
        addSubview(usageTipsView, positioned: .above, relativeTo: usageTipsShieldView)

        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            guard let self,
                  self.recordScrollIfNeeded()
            else { return }
            self.handleScrollActivity()
        }
    }

    private func positionUsageTipsView() {
        guard let coordinator,
              coordinator.usageTipsVisible
        else {
            usageTipsView.isHidden = true
            usageTipsShieldView.isHidden = true
            usageTipsView.clearHoverState()
            releaseUsageTipsEventRegion()
            usageTipsView.frame = .zero
            usageTipsShieldView.frame = .zero
            return
        }

        let inset = min(AppGridUsageTipsMetrics.horizontalInset, max(0, bounds.width / 4))
        let availableWidth = max(1, bounds.width - inset * 2)
        let width = usageTipsView.preferredWidth(maxAvailableWidth: availableWidth)
        let height = AppGridUsageTipsMetrics.barHeight
        usageTipsShieldView.isHidden = false
        usageTipsShieldView.frame = usageTipsEventRegion()
        usageTipsView.configureVisualLayout(
            width: width,
            height: height,
            bottomMargin: AppGridUsageTipsMetrics.bottomMargin
        )
        usageTipsView.isHidden = false
        usageTipsView.frame = usageTipsEventRegion()
    }

    fileprivate func relayoutUsageTipsAfterContentChange() {
        positionUsageTipsView()
        usageTipsView.needsLayout = true
    }

    private func usageTipsEventRegion() -> NSRect {
        guard let coordinator,
              coordinator.usageTipsVisible
        else { return .zero }
        let height = min(bounds.height, AppGridUsageTipsMetrics.reservedHeight)
        return NSRect(
            x: 0,
            y: max(0, bounds.height - height),
            width: bounds.width,
            height: height
        )
    }

    private func claimUsageTipsEventRegion() {
        usageTipsEventRegionIsClaimed = true
        window?.makeFirstResponder(usageTipsView)
        if coordinator?.setUsageTipsBubbleDisabled(true) == true {
            refreshVisibleRuntimeState()
        }
        coordinator?.onUsageTipsHoverChange(true)
    }

    private func releaseUsageTipsEventRegion() {
        guard usageTipsEventRegionIsClaimed else { return }
        usageTipsEventRegionIsClaimed = false
        if coordinator?.setUsageTipsBubbleDisabled(false) == true {
            refreshVisibleRuntimeState()
        }
        coordinator?.onUsageTipsHoverChange(false)
    }

    private func handleScrollActivity() {
        if AppDragCoordinator.shared.hasActiveDrag {
            AppDragCoordinator.shared.cancelDrag()
        }
        coordinator?.cancelAppIconDrag()

        if !scrollActivityIsActive {
            scrollActivityIsActive = true
            if coordinator?.setScrollBubbleDisabled(true) == true {
                refreshVisibleRuntimeState()
            }
            coordinator?.onScrollActivity()
        }

        scrollUnfreezeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.scrollActivityIsActive = false
            self.replayPointerHover()
            if self.coordinator?.setScrollBubbleDisabled(false) == true {
                self.refreshVisibleRuntimeState()
            }
        }
        scrollUnfreezeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
    }

    private func refreshVisibleRuntimeState() {
        collectionView.visibleItems().forEach { item in
            (item as? AppGridGroupCollectionItem)?.refreshRuntimeState()
        }
    }

    fileprivate func refreshVisibleRuntimeStateForUsageTips() {
        refreshVisibleRuntimeState()
    }

    func handleUsageTipsMouseDown(_ event: NSEvent) -> Bool {
        handleUsageTipsMouseEvent(event, triggerButtons: true)
    }

    private func handleUsageTipsMouseEvent(_ event: NSEvent, triggerButtons: Bool) -> Bool {
        let point = usageTipsHostPoint(for: event)
        guard !usageTipsView.isHidden,
              usageTipsView.frame.contains(point)
        else { return false }

        return usageTipsView.handleMouseEventFromHost(event, triggerButtons: triggerButtons)
    }

    private func installUsageTipsMouseMonitor() {
        guard usageTipsMouseMonitor == nil else { return }
        usageTipsMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [
                .leftMouseDown,
                .leftMouseUp,
                .rightMouseDown,
                .rightMouseUp,
                .otherMouseDown,
                .otherMouseUp
            ]
        ) { [weak self] event in
            guard let self,
                  self.window != nil,
                  self.handleUsageTipsMouseEvent(
                    event,
                    triggerButtons: event.type == .leftMouseDown
                  )
            else { return event }
            return nil
        }
    }

    private func usageTipsHostPoint(for event: NSEvent) -> NSPoint {
        if event.window === window {
            return convert(event.locationInWindow, from: nil)
        }
        guard let window else { return .zero }
        let windowPoint = window.convertPoint(fromScreen: NSEvent.mouseLocation)
        return convert(windowPoint, from: nil)
    }

    private func removeUsageTipsMouseMonitor() {
        if let usageTipsMouseMonitor {
            NSEvent.removeMonitor(usageTipsMouseMonitor)
            self.usageTipsMouseMonitor = nil
        }
    }

    private func replayPointerHover() {
        guard let window else { return }
        let windowPoint = window.convertPoint(fromScreen: NSEvent.mouseLocation)
        collectionView.visibleItems().forEach { item in
            (item as? AppGridGroupCollectionItem)?.replayPointerHover(windowPoint: windowPoint)
        }
    }

    private func recordScrollIfNeeded() -> Bool {
        let origin = scrollView.contentView.bounds.origin
        guard let last = lastReportedBoundsOrigin else {
            lastReportedBoundsOrigin = origin
            return false
        }
        let didScroll = abs(origin.x - last.x) > 0.5 || abs(origin.y - last.y) > 0.5
        if didScroll {
            lastReportedBoundsOrigin = origin
        }
        return didScroll
    }
}

private final class AppGridUsageTipsShieldView: NSView {
    var onClaim: (() -> Void)?
    var onRelease: (() -> Void)?

    private var trackingAreaRef: NSTrackingArea?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, bounds.contains(point) else { return nil }
        onClaim?()
        return self
    }

    override func mouseEntered(with event: NSEvent) { onClaim?() }
    override func mouseMoved(with event: NSEvent) { onClaim?() }
    override func mouseDragged(with event: NSEvent) { onClaim?() }
    override func mouseExited(with event: NSEvent) { onRelease?() }
    override func mouseDown(with event: NSEvent) {
        Diagnostics.log("usageTips.shield.mouseDown")
        onClaim?()
    }
    override func mouseUp(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) { onClaim?() }
    override func rightMouseUp(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) { onClaim?() }
    override func otherMouseUp(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) { onClaim?() }
}

private final class AppGridUsageTipsNSView: NSView {
    weak var coordinator: AppGridCollectionView.Coordinator?

    private let backgroundView = NSVisualEffectView()
    private let iconView = AppGridDecorativeImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailScrollView = NSScrollView()
    private let detailLabel = NSTextField(labelWithString: "")
    private let previousButton = AppGridUsageTipIconButton(systemImage: "chevron.left")
    private let nextButton = AppGridUsageTipIconButton(systemImage: "chevron.right")
    private let dotsView = AppGridUsageTipDotsView()
    private var trackingAreaRef: NSTrackingArea?
    private var isPointerInside = false
    private var visualWidth: CGFloat = AppGridUsageTipsMetrics.minWidth
    private var visualHeight: CGFloat = AppGridUsageTipsMetrics.barHeight
    private var visualBottomMargin: CGFloat = AppGridUsageTipsMetrics.bottomMargin

    private let titleFont = NSFont.systemFont(ofSize: 24, weight: .semibold)
    private let detailFont = NSFont.systemFont(ofSize: 24, weight: .regular)

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            clearHoverState()
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, bounds.contains(point) else { return nil }
        setPointerInside(true)
        let hitView = super.hitTest(point)
        if hitView == nil || hitView === backgroundView || hitView?.isDescendant(of: backgroundView) == true {
            return self
        }
        return hitView
    }

    override func mouseEntered(with event: NSEvent) {
        claimInteractionFocus()
    }

    override func mouseMoved(with event: NSEvent) {
        claimInteractionFocus()
    }

    override func mouseExited(with event: NSEvent) {
        setPointerInside(false)
    }

    override func mouseDown(with event: NSEvent) {
        Diagnostics.log("usageTips.hud.mouseDown")
        if routeButtonClickIfNeeded(event) {
            return
        }
        claimInteractionFocus()
    }

    override func mouseDragged(with event: NSEvent) {
        claimInteractionFocus()
    }

    override func mouseUp(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) { claimInteractionFocus() }
    override func rightMouseUp(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) { claimInteractionFocus() }
    override func otherMouseUp(with event: NSEvent) {}

    override func keyDown(with event: NSEvent) {
        switch Int(event.keyCode) {
        case kVK_LeftArrow:
            selectUsageTip(offset: -1)
        case kVK_RightArrow:
            selectUsageTip(offset: 1)
        default:
            super.keyDown(with: event)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        detailScrollView.scrollWheel(with: event)
    }

    override func layout() {
        super.layout()
        let visualFrame = currentVisualFrame()
        backgroundView.frame = visualFrame

        let paddingLeft: CGFloat = 22
        let paddingRight: CGFloat = 16
        let iconSize: CGFloat = 24
        let iconTextGap: CGFloat = 10
        let controlZoneWidth: CGFloat = 176
        let buttonGap: CGFloat = 6
        let buttonSize: CGFloat = 48
        let buttonDotsGap: CGFloat = 6
        let dotsHeight: CGFloat = 10
        let dotsWidth = dotsView.preferredWidth
        let fullTitleWidth = ceil(titleLabel.attributedStringValue.size().width)

        let titleX = visualFrame.minX + paddingLeft + iconSize + iconTextGap
        let buttonsWidth = buttonSize * 2 + buttonGap
        let buttonsGroupMinX = visualFrame.maxX - paddingRight - buttonsWidth
        let textRight = visualFrame.maxX - controlZoneWidth
        let availableTextWidth = max(1, textRight - titleX)
        let titleWidth = min(fullTitleWidth, availableTextWidth)
        let titleHeight: CGFloat = 32
        let detailHeight: CGFloat = 68
        let lineGap: CGFloat = 8
        let textBlockHeight = titleHeight + lineGap + detailHeight
        let textBlockY = visualFrame.minY + max(0, (visualFrame.height - textBlockHeight) / 2)

        iconView.frame = NSRect(
            x: visualFrame.minX + paddingLeft,
            y: visualFrame.midY - iconSize / 2,
            width: iconSize,
            height: iconSize
        )

        titleLabel.frame = NSRect(
            x: titleX,
            y: textBlockY,
            width: titleWidth,
            height: titleHeight
        )

        let controlGroupHeight = buttonSize + buttonDotsGap + dotsHeight
        let buttonY = visualFrame.minY + max(0, (visualFrame.height - controlGroupHeight) / 2)
        nextButton.frame = NSRect(
            x: buttonsGroupMinX + buttonSize + buttonGap,
            y: buttonY,
            width: buttonSize,
            height: buttonSize
        )
        previousButton.frame = NSRect(
            x: buttonsGroupMinX,
            y: buttonY,
            width: buttonSize,
            height: buttonSize
        )
        dotsView.frame = NSRect(
            x: buttonsGroupMinX + (buttonsWidth - dotsWidth) / 2,
            y: previousButton.frame.maxY + buttonDotsGap,
            width: dotsWidth,
            height: dotsHeight
        )

        let detailX = titleX
        let detailRight = textRight
        detailScrollView.frame = NSRect(
            x: detailX,
            y: titleLabel.frame.maxY + lineGap,
            width: max(1, detailRight - detailX),
            height: detailHeight
        )
        layoutDetailLabel()
    }

    func applyCoordinatorState() {
        guard let coordinator,
              coordinator.usageTipsVisible,
              !coordinator.usageTips.isEmpty
        else {
            isHidden = true
            clearHoverState()
            return
        }

        isHidden = false
        let safeIndex = min(max(0, coordinator.selectedUsageTipIndex), coordinator.usageTips.count - 1)
        let tip = coordinator.usageTips[safeIndex]
        titleLabel.stringValue = tr(tip.titleKey)
        detailLabel.stringValue = formattedTipDetail(tr(tip.detailKey))
        previousButton.buttonAccessibilityLabel = tr("usageTips.previous")
        nextButton.buttonAccessibilityLabel = tr("usageTips.next")
        dotsView.configure(count: coordinator.usageTips.count, selectedIndex: safeIndex)
        updateColors()
        needsLayout = true
        enclosingHostView?.relayoutUsageTipsAfterContentChange()
    }

    func clearHoverState() {
        guard isPointerInside else { return }
        setPointerInside(false)
    }

    func configureVisualLayout(width: CGFloat, height: CGFloat, bottomMargin: CGFloat) {
        visualWidth = max(1, width)
        visualHeight = max(1, height)
        visualBottomMargin = max(0, bottomMargin)
        needsLayout = true
    }

    func preferredWidth(maxAvailableWidth: CGFloat) -> CGFloat {
        let padding: CGFloat = 22 + 16
        let fixedWidth: CGFloat = 24 + 10 + 24 + 48 + 6 + 48
        let titleWidth = ceil(titleLabel.attributedStringValue.size().width)
        let detailWidth = measuredDetailLineWidth()
        let contentWidth = padding + fixedWidth + max(titleWidth, detailWidth)
        let preferredWidth = max(AppGridUsageTipsMetrics.minWidth, contentWidth)
        return min(maxAvailableWidth, preferredWidth)
    }

    private func setup() {
        wantsLayer = true
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.14
        layer?.shadowRadius = 12
        layer?.shadowOffset = NSSize(width: 0, height: -2)

        backgroundView.material = .popover
        backgroundView.blendingMode = .withinWindow
        backgroundView.state = .active
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = 10
        backgroundView.layer?.masksToBounds = true
        backgroundView.layer?.borderWidth = 1
        addSubview(backgroundView)

        let iconConfig = NSImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        iconView.image = NSImage(
            systemSymbolName: "lightbulb.fill",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(iconConfig)
        iconView.imageScaling = .scaleProportionallyDown
        addSubview(iconView)

        configureLabel(titleLabel, font: titleFont, lineBreakMode: .byClipping)
        configureDetailLabel()

        detailScrollView.drawsBackground = false
        detailScrollView.hasVerticalScroller = false
        detailScrollView.hasHorizontalScroller = true
        detailScrollView.autohidesScrollers = true
        detailScrollView.borderType = .noBorder
        detailScrollView.documentView = detailLabel

        previousButton.action = { [weak self] in self?.selectUsageTip(offset: -1) }
        nextButton.action = { [weak self] in self?.selectUsageTip(offset: 1) }

        addSubview(titleLabel)
        addSubview(detailScrollView)
        addSubview(dotsView)
        addSubview(previousButton)
        addSubview(nextButton)

        setAccessibilityRole(.group)
        updateColors()
    }

    private func configureLabel(_ label: NSTextField, font: NSFont, lineBreakMode: NSLineBreakMode) {
        label.cell = AppGridCenteredTextFieldCell(textCell: "")
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.isBordered = false
        label.lineBreakMode = lineBreakMode
        label.maximumNumberOfLines = 1
        label.font = font
    }

    private func configureDetailLabel() {
        detailLabel.cell = NSTextFieldCell(textCell: "")
        detailLabel.isEditable = false
        detailLabel.isSelectable = false
        detailLabel.drawsBackground = false
        detailLabel.isBordered = false
        detailLabel.lineBreakMode = .byWordWrapping
        detailLabel.maximumNumberOfLines = 2
        detailLabel.font = detailFont
        detailLabel.cell?.usesSingleLineMode = false
        detailLabel.cell?.wraps = true
    }

    private func claimInteractionFocus() {
        setPointerInside(true)
        window?.makeFirstResponder(self)
    }

    func handleMouseEventFromHost(_ event: NSEvent, triggerButtons: Bool) -> Bool {
        let point = usageTipsPoint(for: event)
        guard bounds.contains(point) else { return false }
        if triggerButtons, routeButtonClickIfNeeded(event) {
            return true
        }
        claimInteractionFocus()
        return true
    }

    private func selectUsageTip(offset: Int) {
        coordinator?.selectUsageTip(offset: offset)
        applyCoordinatorState()
    }

    private func routeButtonClickIfNeeded(_ event: NSEvent) -> Bool {
        let point = usageTipsPoint(for: event)
        let hitOutset: CGFloat = 24
        if nextButton.frame.insetBy(dx: -hitOutset, dy: -hitOutset).contains(point) {
            Diagnostics.log("usageTips.hud.routedNext")
            selectUsageTip(offset: 1)
            return true
        }
        if previousButton.frame.insetBy(dx: -hitOutset, dy: -hitOutset).contains(point) {
            Diagnostics.log("usageTips.hud.routedPrevious")
            selectUsageTip(offset: -1)
            return true
        }
        return false
    }

    private func usageTipsPoint(for event: NSEvent) -> NSPoint {
        if event.window === window {
            return convert(event.locationInWindow, from: nil)
        }
        guard let window else { return .zero }
        let windowPoint = window.convertPoint(fromScreen: NSEvent.mouseLocation)
        return convert(windowPoint, from: nil)
    }

    private func setPointerInside(_ inside: Bool) {
        guard isPointerInside != inside else { return }
        isPointerInside = inside
        if coordinator?.setUsageTipsBubbleDisabled(inside) == true {
            enclosingHostView?.refreshVisibleRuntimeStateForUsageTips()
        }
        coordinator?.onUsageTipsHoverChange(inside)
    }

    private var enclosingHostView: AppGridCollectionHostView? {
        var current = superview
        while let view = current {
            if let host = view as? AppGridCollectionHostView {
                return host
            }
            current = view.superview
        }
        return nil
    }

    private func layoutDetailLabel() {
        let width = max(1, detailScrollView.contentView.bounds.width)
        detailLabel.preferredMaxLayoutWidth = width
        detailLabel.frame = NSRect(x: 0, y: 0, width: width, height: detailScrollView.bounds.height)
    }

    private func measuredDetailLineWidth() -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: detailFont]
        let lineWidths = detailLabel.stringValue
            .components(separatedBy: .newlines)
            .map { NSAttributedString(string: $0, attributes: attributes).size().width }
        return ceil(lineWidths.max() ?? detailLabel.attributedStringValue.size().width)
    }

    private func currentVisualFrame() -> NSRect {
        let width = min(bounds.width, visualWidth)
        let height = min(bounds.height, visualHeight)
        return NSRect(
            x: max(0, (bounds.width - width) / 2),
            y: max(0, bounds.height - visualBottomMargin - height),
            width: width,
            height: height
        )
    }

    private func formattedTipDetail(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\s*(?:-->|->|>|→|＞|,)\\s*", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\n{2,}", with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateColors() {
        backgroundView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
        iconView.contentTintColor = .systemYellow
        titleLabel.textColor = .secondaryLabelColor
        detailLabel.textColor = .labelColor
        previousButton.tintColor = .labelColor
        nextButton.tintColor = .labelColor
        dotsView.needsDisplay = true
    }
}

private final class AppGridCenteredTextFieldCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var drawingRect = super.drawingRect(forBounds: rect)
        let textHeight = cellSize(forBounds: rect).height
        drawingRect.origin.y = rect.origin.y + max(0, (rect.height - textHeight) / 2)
        drawingRect.size.height = min(rect.height, textHeight + 2)
        return drawingRect
    }
}

private final class AppGridDecorativeImageView: NSImageView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func isAccessibilityElement() -> Bool {
        false
    }
}

private final class AppGridUsageTipIconButton: NSView {
    var action: (() -> Void)?
    var buttonAccessibilityLabel: String = "" {
        didSet {
            setAccessibilityLabel(buttonAccessibilityLabel)
        }
    }
    var tintColor: NSColor = .labelColor {
        didSet {
            imageView.contentTintColor = tintColor
        }
    }

    private let imageView = AppGridDecorativeImageView()
    private var trackingAreaRef: NSTrackingArea?
    private var isHovered = false
    private var isPressed = false

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }

    init(systemImage: String) {
        super.init(frame: .zero)
        setup(systemImage: systemImage)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func isAccessibilityElement() -> Bool {
        true
    }

    override func accessibilityRole() -> NSAccessibility.Role? {
        .button
    }

    override func accessibilityLabel() -> String? {
        buttonAccessibilityLabel
    }

    override func accessibilityPerformPress() -> Bool {
        action?()
        return true
    }

    override func layout() {
        super.layout()
        let size: CGFloat = 26
        imageView.frame = NSRect(
            x: (bounds.width - size) / 2,
            y: (bounds.height - size) / 2,
            width: size,
            height: size
        )
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        isPressed = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        Diagnostics.log("usageTips.button.mouseDown", [
            "label": buttonAccessibilityLabel
        ])
        isPressed = true
        needsDisplay = true
        action?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.isPressed = false
            self?.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard isHovered || isPressed else { return }
        tintColor.withAlphaComponent(isPressed ? 0.14 : 0.08).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6).fill()
    }

    private func setup(systemImage: String) {
        wantsLayer = true
        let config = NSImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        imageView.image = NSImage(
            systemSymbolName: systemImage,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(config)
        imageView.imageScaling = .scaleProportionallyDown
        imageView.contentTintColor = tintColor
        addSubview(imageView)
        setAccessibilityRole(.button)
    }
}

private final class AppGridUsageTipDotsView: NSView {
    private var count = 0
    private var selectedIndex = 0

    override var isFlipped: Bool { true }

    var preferredWidth: CGFloat {
        guard count > 0 else { return 0 }
        return CGFloat(count) * 5 + CGFloat(max(0, count - 1)) * 5 + 2
    }

    func configure(count: Int, selectedIndex: Int) {
        self.count = count
        self.selectedIndex = selectedIndex
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard count > 0 else { return }
        let spacing: CGFloat = 5
        let totalWidth = preferredWidth
        var x = (bounds.width - totalWidth) / 2
        let centerY = bounds.midY

        for index in 0..<count {
            let selected = index == selectedIndex
            let dotSize: CGFloat = selected ? 6 : 5
            let color = NSColor.labelColor.withAlphaComponent(selected ? 0.85 : 0.28)
            color.setFill()
            NSBezierPath(
                ovalIn: NSRect(
                    x: x,
                    y: centerY - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
            ).fill()
            x += 5 + spacing
        }
    }
}

private final class AppGridContainerCollectionLayout: NSCollectionViewLayout {
    weak var coordinator: AppGridCollectionView.Coordinator?

    private var itemAttributes: [IndexPath: NSCollectionViewLayoutAttributes] = [:]
    private var contentSize: NSSize = .zero

    override var collectionViewContentSize: NSSize {
        contentSize
    }

    override func prepare() {
        super.prepare()
        guard let collectionView else {
            itemAttributes = [:]
            contentSize = .zero
            return
        }

        let groups = coordinator?.groups ?? []
        let itemCount = collectionView.numberOfItems(inSection: 0)
        let visibleGroups = Array(groups.prefix(itemCount))
        let iconSize: CGFloat = coordinator?.iconSize ?? CGFloat(AppDefaults.iconSize)
        let plan = Self.makePlan(
            groups: visibleGroups,
            contentWidth: collectionView.bounds.width,
            iconSize: iconSize,
            displayMode: coordinator?.displayMode ?? AppDefaults.displayMode,
            bottomContentPadding: coordinator?.bottomContentPadding ?? 0
        )

        var nextAttributes: [IndexPath: NSCollectionViewLayoutAttributes] = [:]
        for item in plan.items {
            let indexPath = IndexPath(item: item.index, section: 0)
            let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
            attributes.frame = item.frame
            nextAttributes[indexPath] = attributes
        }

        itemAttributes = nextAttributes
        contentSize = plan.contentSize
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        itemAttributes.values.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        itemAttributes[indexPath]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        false
    }

    private struct LayoutItem {
        let index: Int
        let frame: NSRect
    }

    private struct LayoutPlan {
        let items: [LayoutItem]
        let contentSize: NSSize
    }

    private struct Candidate {
        let spans: [Int]
        let cost: CGFloat
    }

    private static func makePlan(
        groups: [TagGroup],
        contentWidth: CGFloat,
        iconSize: CGFloat,
        displayMode: String,
        bottomContentPadding: CGFloat
    ) -> LayoutPlan {
        switch AppGridCollectionDisplayMode(displayMode) {
        case .flat:
            return makeFlatPlan(
                groups: groups,
                contentWidth: contentWidth,
                iconSize: iconSize,
                bottomContentPadding: bottomContentPadding
            )
        case .masonryContainer:
            return makeMasonryPlan(
                groups: groups,
                contentWidth: contentWidth,
                iconSize: iconSize,
                bottomContentPadding: bottomContentPadding
            )
        case .gridContainer:
            return makeGridPlan(
                groups: groups,
                contentWidth: contentWidth,
                iconSize: iconSize,
                bottomContentPadding: bottomContentPadding
            )
        }
    }

    private static func makeGridPlan(
        groups: [TagGroup],
        contentWidth: CGFloat,
        iconSize: CGFloat,
        bottomContentPadding: CGFloat
    ) -> LayoutPlan {
        let boundedContentWidth = max(1, contentWidth)
        let outerPadding = AppGridCollectionMetrics.outerPadding
        let gap = AppGridCollectionMetrics.cardGap
        let availableWidth = max(1, boundedContentWidth - outerPadding * 2)
        let trackCount = preferredTrackCount(availableWidth: availableWidth, iconSize: iconSize)
        let trackWidth = floor((availableWidth - gap * CGFloat(trackCount - 1)) / CGFloat(trackCount))
        let rows = layoutRows(
            groups: groups,
            trackCount: trackCount,
            trackWidth: trackWidth,
            availableWidth: availableWidth,
            gap: gap,
            iconSize: iconSize
        )

        var y = outerPadding
        var items: [LayoutItem] = []
        for row in rows {
            var x = outerPadding
            let height = AppGridCollectionMetrics.cardHeight(rowCount: row.fixedRows, iconSize: iconSize)
            for item in row.items {
                let frame = NSRect(x: x, y: y, width: item.width, height: height)
                items.append(LayoutItem(index: item.index, frame: frame))
                x += item.width + gap
            }
            y += height + gap
        }

        let contentHeight = (rows.isEmpty ? outerPadding * 2 : y - gap + outerPadding)
            + max(0, bottomContentPadding)
        return LayoutPlan(
            items: items,
            contentSize: NSSize(width: boundedContentWidth, height: max(1, contentHeight))
        )
    }

    private static func makeFlatPlan(
        groups: [TagGroup],
        contentWidth: CGFloat,
        iconSize: CGFloat,
        bottomContentPadding: CGFloat
    ) -> LayoutPlan {
        let boundedContentWidth = max(1, contentWidth)
        let outerPadding = AppGridCollectionMetrics.outerPadding
        let availableWidth = max(1, boundedContentWidth - outerPadding * 2)
        var y = outerPadding
        var items: [LayoutItem] = []

        for (index, group) in groups.enumerated() {
            let height = AppGridCollectionMetrics.flatGroupHeight(
                appCount: group.apps.count,
                width: availableWidth,
                iconSize: iconSize
            )
            items.append(
                LayoutItem(
                    index: index,
                    frame: NSRect(x: outerPadding, y: y, width: availableWidth, height: height)
                )
            )
            y += height + AppGridCollectionMetrics.flatGroupGap
        }

        let contentHeight = (groups.isEmpty ? outerPadding * 2 : y - AppGridCollectionMetrics.flatGroupGap + outerPadding)
            + max(0, bottomContentPadding)
        return LayoutPlan(
            items: items,
            contentSize: NSSize(width: boundedContentWidth, height: max(1, contentHeight))
        )
    }

    private static func makeMasonryPlan(
        groups: [TagGroup],
        contentWidth: CGFloat,
        iconSize: CGFloat,
        bottomContentPadding: CGFloat
    ) -> LayoutPlan {
        let boundedContentWidth = max(1, contentWidth)
        let outerPadding = AppGridCollectionMetrics.outerPadding
        let gap = AppGridCollectionMetrics.cardGap
        let availableWidth = max(1, boundedContentWidth - outerPadding * 2)
        let columnCount = preferredMasonryColumnCount(availableWidth: availableWidth)
        let columnWidth = floor((availableWidth - gap * CGFloat(columnCount - 1)) / CGFloat(columnCount))
        var columnHeights = Array(repeating: outerPadding, count: columnCount)
        var items: [LayoutItem] = []

        for (index, group) in groups.enumerated() {
            let columnIndex = columnHeights.indices.min { columnHeights[$0] < columnHeights[$1] } ?? 0
            let x = outerPadding + CGFloat(columnIndex) * (columnWidth + gap)
            let y = columnHeights[columnIndex]
            let height = AppGridCollectionMetrics.cardHeight(
                appCount: group.apps.count,
                width: columnWidth,
                iconSize: iconSize
            )
            items.append(
                LayoutItem(
                    index: index,
                    frame: NSRect(x: x, y: y, width: columnWidth, height: height)
                )
            )
            columnHeights[columnIndex] = y + height + gap
        }

        let tallest = columnHeights.max() ?? outerPadding
        let contentHeight = (groups.isEmpty ? outerPadding * 2 : tallest - gap + outerPadding)
            + max(0, bottomContentPadding)
        return LayoutPlan(
            items: items,
            contentSize: NSSize(width: boundedContentWidth, height: max(1, contentHeight))
        )
    }

    private struct RowItem {
        let index: Int
        let width: CGFloat
    }

    private struct Row {
        let items: [RowItem]
        let fixedRows: Int
    }

    private static func layoutRows(
        groups: [TagGroup],
        trackCount: Int,
        trackWidth: CGFloat,
        availableWidth: CGFloat,
        gap: CGFloat,
        iconSize: CGFloat
    ) -> [Row] {
        let n = groups.count
        guard n > 0 else { return [] }
        let patterns = spanPatterns(trackCount: trackCount)
        var bestCost = Array(repeating: CGFloat.greatestFiniteMagnitude, count: n + 1)
        var bestPattern = Array(repeating: [Int](), count: n)
        bestCost[n] = 0

        for index in stride(from: n - 1, through: 0, by: -1) {
            for pattern in patterns where index + pattern.count <= n {
                let candidate = rowCandidate(
                    groups: groups,
                    startIndex: index,
                    spans: pattern,
                    trackWidth: trackWidth,
                    availableWidth: availableWidth,
                    gap: gap,
                    iconSize: iconSize
                )
                let totalCost = candidate.cost + bestCost[index + pattern.count]
                if totalCost < bestCost[index] {
                    bestCost[index] = totalCost
                    bestPattern[index] = candidate.spans
                }
            }
        }

        var rows: [Row] = []
        var index = 0
        while index < n {
            let spans = bestPattern[index].isEmpty ? [trackCount] : bestPattern[index]
            let widths = spans.map { width(trackWidth: trackWidth, span: $0, gap: gap) }
            let fixedRows = widths.indices.map {
                AppGridCollectionMetrics.iconRows(
                    appCount: groups[index + $0].apps.count,
                    width: widths[$0],
                    iconSize: iconSize
                )
            }.max() ?? 1
            let items = widths.indices.map {
                RowItem(index: index + $0, width: widths[$0])
            }
            rows.append(Row(items: items, fixedRows: fixedRows))
            index += spans.count
        }
        return rows
    }

    private static func rowCandidate(
        groups: [TagGroup],
        startIndex: Int,
        spans: [Int],
        trackWidth: CGFloat,
        availableWidth: CGFloat,
        gap: CGFloat,
        iconSize: CGFloat
    ) -> Candidate {
        let widths = spans.map { width(trackWidth: trackWidth, span: $0, gap: gap) }
        let rowCounts = widths.indices.map {
            AppGridCollectionMetrics.iconRows(
                appCount: groups[startIndex + $0].apps.count,
                width: widths[$0],
                iconSize: iconSize
            )
        }
        let fixedRows = rowCounts.max() ?? 1
        let rowArea = CGFloat(fixedRows) * AppGridCollectionMetrics.iconCellHeight(iconSize: iconSize) * availableWidth
        let paddingCost = CGFloat(spans.count) * 0.001
        return Candidate(spans: spans, cost: rowArea + paddingCost)
    }

    private static func preferredTrackCount(availableWidth: CGFloat, iconSize: CGFloat) -> Int {
        let minCardWidth = max(260, AppGridCollectionMetrics.iconCellWidth(iconSize: iconSize) * 3 + 64)
        if availableWidth >= minCardWidth * 3 + AppGridCollectionMetrics.cardGap * 2 { return 3 }
        if availableWidth >= minCardWidth * 2 + AppGridCollectionMetrics.cardGap { return 2 }
        return 1
    }

    private static func preferredMasonryColumnCount(availableWidth: CGFloat) -> Int {
        let preferredColumnWidth: CGFloat = 280
        return max(
            1,
            Int((availableWidth + AppGridCollectionMetrics.cardGap) / (preferredColumnWidth + AppGridCollectionMetrics.cardGap))
        )
    }

    private static func spanPatterns(trackCount: Int) -> [[Int]] {
        switch trackCount {
        case 3:
            return [[1, 1, 1], [1, 2], [2, 1], [3]]
        case 2:
            return [[1, 1], [2]]
        default:
            return [[1]]
        }
    }

    private static func width(trackWidth: CGFloat, span: Int, gap: CGFloat) -> CGFloat {
        let safeSpan = max(1, span)
        return trackWidth * CGFloat(safeSpan) + gap * CGFloat(safeSpan - 1)
    }
}

private enum AppGridCollectionMetrics {
    static let outerPadding: CGFloat = 20
    static let cardGap: CGFloat = 16
    static let flatGroupGap: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let headerHeight: CGFloat = 28
    static let headerBottomGap: CGFloat = 6
    static let iconColumnGap: CGFloat = 6
    static let iconRowGap: CGFloat = 2
    static let reorderEmptyDropCancelOutset: CGFloat = 4
    static let hoverScale: CGFloat = 1.22
    static let labelHeight: CGFloat = 14

    static func iconCellWidth(iconSize: CGFloat) -> CGFloat {
        iconSize * hoverScale + 8
    }

    static func iconCellHeight(iconSize: CGFloat) -> CGFloat {
        iconSize * hoverScale + labelHeight + 22
    }

    static func columnsForIconArea(width: CGFloat, iconSize: CGFloat) -> Int {
        let inner = max(1, width)
        let itemW = iconCellWidth(iconSize: iconSize)
        return max(1, Int((inner + iconColumnGap) / (itemW + iconColumnGap)))
    }

    static func columns(width: CGFloat, iconSize: CGFloat) -> Int {
        columnsForIconArea(width: width - cardPadding * 2, iconSize: iconSize)
    }

    static func cardHeight(appCount: Int, width: CGFloat, iconSize: CGFloat) -> CGFloat {
        cardHeight(rowCount: iconRows(appCount: appCount, width: width, iconSize: iconSize), iconSize: iconSize)
    }

    static func cardHeight(rowCount: Int, iconSize: CGFloat) -> CGFloat {
        let rows = max(1, rowCount)
        return cardPadding * 2
            + headerHeight
            + headerBottomGap
            + CGFloat(rows) * iconCellHeight(iconSize: iconSize)
            + CGFloat(max(0, rows - 1)) * iconRowGap
    }

    static func iconRows(appCount: Int, width: CGFloat, iconSize: CGFloat) -> Int {
        let cols = columns(width: width, iconSize: iconSize)
        return max(1, (appCount + cols - 1) / cols)
    }

    static func flatGroupHeight(appCount: Int, width: CGFloat, iconSize: CGFloat) -> CGFloat {
        let cols = columnsForIconArea(width: width, iconSize: iconSize)
        let rows = max(1, (appCount + cols - 1) / cols)
        return headerHeight
            + headerBottomGap
            + CGFloat(rows) * iconCellHeight(iconSize: iconSize)
            + CGFloat(max(0, rows - 1)) * iconRowGap
    }
}

private final class AppGridGroupCollectionItem: NSCollectionViewItem {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("AppGridGroupCollectionItem")

    private var cardView: AppGridGroupCardView {
        view as! AppGridGroupCardView
    }

    override func loadView() {
        view = AppGridGroupCardView()
    }

    func configure(group: TagGroup, coordinator: AppGridCollectionView.Coordinator) {
        cardView.configure(group: group, coordinator: coordinator)
    }

    func refreshRuntimeState() {
        cardView.refreshRuntimeState()
    }

    func replayPointerHover(windowPoint: NSPoint) {
        cardView.replayPointerHover(windowPoint: windowPoint)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.prepareForReuse()
    }
}

private final class AppGridGroupCardView: NSView, AppDropTargetReceivingView {
    private let dropTargetID = UUID()
    private weak var coordinator: AppGridCollectionView.Coordinator?
    private var group: TagGroup?
    private var iconViews: [AppGridIconNSView] = []
    private var reorderInsertionIndex: Int?
    private var isMouseInside = false
    private var isHovered = false
    private var trackingAreaRef: NSTrackingArea?
    var containerID: String { group?.containerID ?? "" }

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    deinit {
        AppDragCoordinator.shared.unregister(id: dropTargetID)
    }

    func configure(group: TagGroup, coordinator: AppGridCollectionView.Coordinator) {
        self.group = group
        self.coordinator = coordinator
        rebuildIconViews()
        refreshRuntimeState()
        registerDropTargetIfNeeded()
        needsDisplay = true
        needsLayout = true
    }

    override func prepareForReuse() {
        AppDragCoordinator.shared.unregister(id: dropTargetID)
        group = nil
        coordinator = nil
        reorderInsertionIndex = nil
        isMouseInside = false
        isHovered = false
        layer?.shadowOpacity = 0
        iconViews.forEach {
            $0.prepareForReuse()
            $0.removeFromSuperview()
        }
        iconViews = []
    }

    func refreshRuntimeState() {
        let runtime = AppGridIconRuntimeState(
            bubbleSuppressionReasons: coordinator?.bubbleSuppressionReasons ?? [],
            showUncommonAppBubbles: coordinator?.showUncommonAppBubbles ?? AppDefaults.showUncommonAppBubbles
        )
        iconViews.forEach { $0.runtimeState = runtime }
        updateHoverPresentation()
        needsDisplay = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            AppDragCoordinator.shared.unregister(id: dropTargetID)
        } else {
            registerDropTargetIfNeeded()
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func mouseEntered(with event: NSEvent) {
        setPointerInside(true)
    }

    override func mouseExited(with event: NSEvent) {
        setPointerInside(false)
    }

    override func mouseUp(with event: NSEvent) {
        guard let group,
              bounds.contains(convert(event.locationInWindow, from: nil))
        else { return }
        coordinator?.onGroupActivate(group.name)
    }

    override func layout() {
        super.layout()
        guard let coordinator, let group else { return }
        let contentRect = iconContentRect(displayStyle: coordinator.displayStyle)
        let cols = AppGridCollectionMetrics.columnsForIconArea(width: contentRect.width, iconSize: coordinator.iconSize)
        let cellWidth = max(
            1,
            (contentRect.width - AppGridCollectionMetrics.iconColumnGap * CGFloat(cols - 1)) / CGFloat(cols)
        )
        let cellHeight = AppGridCollectionMetrics.iconCellHeight(iconSize: coordinator.iconSize)

        for index in group.apps.indices {
            guard index < iconViews.count else { continue }
            let row = index / cols
            let col = index % cols
            let x = contentRect.minX
                + CGFloat(col) * (cellWidth + AppGridCollectionMetrics.iconColumnGap)
            let y = contentRect.minY + CGFloat(row) * (cellHeight + AppGridCollectionMetrics.iconRowGap)
            iconViews[index].frame = NSRect(x: x, y: y, width: cellWidth, height: cellHeight)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let coordinator, let group else { return }
        let displayStyle = coordinator.displayStyle
        let tagColor = TagColor.nsColor(for: coordinator.tagColors[group.name] ?? 0)
        let isNavigationHighlighted = coordinator.highlightedGroupName == group.name
        let isColorlessActive = coordinator.isColorlessContainerMode
            && (isHovered || isNavigationHighlighted)

        if displayStyle.usesCardSurface {
            let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
            let path = NSBezierPath(roundedRect: rect, xRadius: 14, yRadius: 14)
            cardSurfaceColor().setFill()
            path.fill()
            if coordinator.isColoredContainerMode || isColorlessActive {
                tagColor.withAlphaComponent(0.30).setFill()
                path.fill()
            }
            NSColor.labelColor.withAlphaComponent(0.08).setStroke()
            path.lineWidth = 1
            path.stroke()
        }

        drawHeader(title: group.name, displayStyle: displayStyle)
        drawReorderInsertionIfNeeded()
    }

    func performDrop(path: String, source: String, copy: Bool) {
        performDrop(path: path, source: source, sourceContainerID: "", copy: copy)
    }

    func performDrop(path: String, source: String, sourceContainerID: String, copy: Bool) {
        guard let group else { return }
        if sourceContainerID == group.containerID {
            if !copy,
               let orderedPaths = reorderedAppPaths(moving: path) {
                coordinator?.onReorderApps(group.containerID, orderedPaths)
            }
            coordinator?.endAppIconDrag()
            clearReorderInsertion()
            return
        }

        coordinator?.onDropApp(path, source, group.name, copy)
        if source != group.name || copy {
            coordinator?.onDragModeChange(false)
        }
    }

    func appDragHoverChanged(active: Bool) {
        if !active {
            coordinator?.clearReorderInsertion(card: self)
        }
    }

    func appDragLocationChanged(screenPoint: NSPoint, copy: Bool) {
        guard let coordinator,
              let group,
              coordinator.activeReorderPath(in: group.containerID, copy: copy) != nil,
              let window
        else {
            coordinator?.clearReorderInsertion(card: self)
            return
        }

        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        let localPoint = convert(windowPoint, from: nil)
        coordinator.setReorderInsertion(
            card: self,
            insertionIndex: insertionIndex(for: localPoint)
        )
    }

    func replayPointerHover(windowPoint: NSPoint) {
        setPointerInside(bounds.contains(convert(windowPoint, from: nil)))
        iconViews.forEach { $0.replayPointerHover(windowPoint: windowPoint) }
    }

    func setReorderInsertion(index: Int) {
        let clamped = min(max(0, index), iconViews.count)
        guard reorderInsertionIndex != clamped else { return }
        reorderInsertionIndex = clamped
        needsDisplay = true
    }

    func clearReorderInsertion() {
        guard reorderInsertionIndex != nil else { return }
        reorderInsertionIndex = nil
        needsDisplay = true
    }

    private func rebuildIconViews() {
        iconViews.forEach {
            $0.prepareForReuse()
            $0.removeFromSuperview()
        }
        guard let coordinator, let group else {
            iconViews = []
            return
        }
        iconViews = group.apps.map { app in
            let iconView = AppGridIconNSView()
            iconView.configure(
                app: app,
                sourceTag: group.name,
                sourceContainerID: group.containerID,
                iconSize: coordinator.iconSize,
                showName: coordinator.showNames,
                coordinator: coordinator
            )
            addSubview(iconView)
            return iconView
        }
    }

    private func insertionIndex(for point: NSPoint) -> Int {
        guard !iconViews.isEmpty else { return 0 }

        var bestIndex = iconViews.count
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for index in 0...iconViews.count {
            guard let candidate = insertionCandidatePoint(for: index) else { continue }
            let dx = point.x - candidate.x
            let dy = point.y - candidate.y
            let distance = dx * dx + dy * dy
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        return bestIndex
    }

    private func reorderedAppPaths(moving path: String) -> [String]? {
        guard let group,
              let insertionIndex = reorderInsertionIndex
        else { return nil }

        var paths = group.apps.map { $0.path.path }
        guard let sourceIndex = paths.firstIndex(of: path) else { return nil }

        paths.remove(at: sourceIndex)
        var targetIndex = insertionIndex
        if sourceIndex < insertionIndex {
            targetIndex -= 1
        }
        targetIndex = min(max(0, targetIndex), paths.count)
        paths.insert(path, at: targetIndex)

        let originalPaths = group.apps.map { $0.path.path }
        guard paths != originalPaths else { return nil }
        return paths
    }

    private func drawReorderInsertionIfNeeded() {
        guard let insertionIndex = reorderInsertionIndex,
              let rect = insertionLineRect(for: insertionIndex)
        else { return }

        NSColor.controlAccentColor.withAlphaComponent(0.92).setFill()
        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        path.fill()
    }

    private func insertionLineRect(for index: Int) -> NSRect? {
        guard let candidate = insertionCandidatePoint(for: index) else { return nil }
        let referenceFrame: NSRect
        if iconViews.indices.contains(index) {
            referenceFrame = iconViews[index].frame
        } else if let lastFrame = iconViews.last?.frame {
            referenceFrame = lastFrame
        } else {
            return nil
        }

        let iconSize = coordinator?.iconSize ?? CGFloat(AppDefaults.iconSize)
        let lineHeight = max(28, min(referenceFrame.height - 8, iconSize + 18))
        return NSRect(
            x: candidate.x - 2,
            y: referenceFrame.midY - lineHeight / 2,
            width: 4,
            height: lineHeight
        )
    }

    private func insertionCandidatePoint(for index: Int) -> NSPoint? {
        guard !iconViews.isEmpty else { return nil }

        if index <= 0 {
            let first = iconViews[0].frame
            return NSPoint(x: first.minX - 3, y: first.midY)
        }

        if index >= iconViews.count {
            let last = iconViews[iconViews.count - 1].frame
            return NSPoint(x: last.maxX + 3, y: last.midY)
        }

        let previous = iconViews[index - 1].frame
        let next = iconViews[index].frame
        if abs(previous.midY - next.midY) < 4 {
            return NSPoint(x: (previous.maxX + next.minX) / 2, y: previous.midY)
        }

        return NSPoint(x: next.minX - 3, y: next.midY)
    }

    private func registerDropTargetIfNeeded() {
        guard window != nil, let group else { return }
        AppDragCoordinator.shared.register(id: dropTargetID, view: self, tag: group.name)
    }

    private func setPointerInside(_ inside: Bool) {
        isMouseInside = inside
        updateHoverPresentation()
    }

    private func updateHoverPresentation() {
        guard let coordinator else { return }
        let shouldHover = coordinator.displayStyle.usesCardSurface
            && isMouseInside
            && !coordinator.bubbleDisabled
        guard isHovered != shouldHover else {
            updateCardShadow()
            return
        }
        isHovered = shouldHover
        updateCardShadow()
        needsDisplay = true
    }

    private func updateCardShadow() {
        guard let coordinator else { return }
        let isNavigationHighlighted = coordinator.highlightedGroupName == group?.name
        let isColorlessActive = coordinator.isColorlessContainerMode
            && (isHovered || isNavigationHighlighted)
        let shouldShadow = coordinator.displayStyle.usesCardSurface
            && ((coordinator.isColoredContainerMode && (isHovered || isNavigationHighlighted)) || isColorlessActive)
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = shouldShadow ? 0.22 : 0
        layer?.shadowRadius = shouldShadow ? 8 : 0
        layer?.shadowOffset = NSSize(width: 0, height: -3)
    }

    private func iconContentRect(displayStyle: AppGridCollectionDisplayMode) -> NSRect {
        switch displayStyle {
        case .flat:
            return NSRect(
                x: 0,
                y: AppGridCollectionMetrics.headerHeight + AppGridCollectionMetrics.headerBottomGap,
                width: bounds.width,
                height: max(1, bounds.height - AppGridCollectionMetrics.headerHeight - AppGridCollectionMetrics.headerBottomGap)
            )
        case .masonryContainer, .gridContainer:
            let startY = AppGridCollectionMetrics.cardPadding
                + AppGridCollectionMetrics.headerHeight
                + AppGridCollectionMetrics.headerBottomGap
            return NSRect(
                x: AppGridCollectionMetrics.cardPadding,
                y: startY,
                width: max(1, bounds.width - AppGridCollectionMetrics.cardPadding * 2),
                height: max(1, bounds.height - startY - AppGridCollectionMetrics.cardPadding)
            )
        }
    }

    private func cardSurfaceColor() -> NSColor {
        if effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor.white.withAlphaComponent(0.055)
        }
        return NSColor.white.withAlphaComponent(0.62)
    }

    private func drawHeader(title: String, displayStyle: AppGridCollectionDisplayMode) {
        let horizontalInset = displayStyle.usesCardSurface ? AppGridCollectionMetrics.cardPadding : 0
        let verticalInset = displayStyle.usesCardSurface ? AppGridCollectionMetrics.cardPadding : 0
        let headerRect = NSRect(
            x: horizontalInset,
            y: verticalInset,
            width: max(1, bounds.width - horizontalInset * 2),
            height: AppGridCollectionMetrics.headerHeight
        )
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: centeredParagraph(lineBreak: .byTruncatingMiddle)
        ]
        let titleSize = title.size(withAttributes: attributes)
        let titleWidth = min(headerRect.width * 0.64, titleSize.width + 20)
        let titleRect = NSRect(
            x: headerRect.midX - titleWidth / 2,
            y: headerRect.minY + 3,
            width: titleWidth,
            height: headerRect.height - 6
        )
        let lineY = headerRect.midY
        NSColor.secondaryLabelColor.withAlphaComponent(0.25).setStroke()
        let leftLine = NSBezierPath()
        leftLine.move(to: NSPoint(x: headerRect.minX, y: lineY))
        leftLine.line(to: NSPoint(x: max(headerRect.minX, titleRect.minX - 2), y: lineY))
        leftLine.stroke()
        let rightLine = NSBezierPath()
        rightLine.move(to: NSPoint(x: min(headerRect.maxX, titleRect.maxX + 2), y: lineY))
        rightLine.line(to: NSPoint(x: headerRect.maxX, y: lineY))
        rightLine.stroke()
        title.draw(with: titleRect, options: [.usesLineFragmentOrigin], attributes: attributes)
    }

    private func centeredParagraph(lineBreak: NSLineBreakMode) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = lineBreak
        return paragraph
    }
}

private struct AppGridIconRuntimeState {
    var bubbleSuppressionReasons: AppGridBubbleSuppressionReasons
    var showUncommonAppBubbles: Bool

    var bubbleDisabled: Bool {
        !bubbleSuppressionReasons.isEmpty
    }
}

private final class AppGridIconNSView: NSView {
    private weak var coordinator: AppGridCollectionView.Coordinator?
    private var app: AppInfo?
    private var sourceTag = ""
    private var sourceContainerID = ""
    private var iconSize: CGFloat = AppDefaults.iconSize
    private var showName = true
    private var isMouseInside = false
    private var isHovered = false
    private var trackingAreaRef: NSTrackingArea?
    private var mouseDownEvent: NSEvent?
    private var didStartDrag = false
    private var isLongPressActive = false
    private var longPressWorkItem: DispatchWorkItem?

    var runtimeState = AppGridIconRuntimeState(
        bubbleSuppressionReasons: [],
        showUncommonAppBubbles: AppDefaults.showUncommonAppBubbles
    ) {
        didSet {
            updateHoverPresentation(notify: true)
        }
    }

    override var isFlipped: Bool { true }

    func configure(
        app: AppInfo,
        sourceTag: String,
        sourceContainerID: String,
        iconSize: CGFloat,
        showName: Bool,
        coordinator: AppGridCollectionView.Coordinator
    ) {
        self.app = app
        self.sourceTag = sourceTag
        self.sourceContainerID = sourceContainerID
        self.iconSize = iconSize
        self.showName = showName
        self.coordinator = coordinator
        runtimeState = AppGridIconRuntimeState(
            bubbleSuppressionReasons: coordinator.bubbleSuppressionReasons,
            showUncommonAppBubbles: coordinator.showUncommonAppBubbles
        )
        needsDisplay = true
    }

    override func prepareForReuse() {
        longPressWorkItem?.cancel()
        if isHovered {
            setHover(false, notify: true)
        }
        isMouseInside = false
        mouseDownEvent = nil
        didStartDrag = false
        isLongPressActive = false
        sourceContainerID = ""
        longPressWorkItem = nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let app else { return }
        NSGraphicsContext.current?.imageInterpolation = .high
        let scale = isHovered ? AppGridCollectionMetrics.hoverScale : 1
        let drawSize = iconSize * scale
        let iconSlot = iconSize * AppGridCollectionMetrics.hoverScale
        let iconRect = NSRect(
            x: (bounds.width - drawSize) / 2,
            y: 8 + (iconSlot - drawSize) / 2,
            width: drawSize,
            height: drawSize
        )

        if isHovered {
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
            shadow.shadowBlurRadius = 14
            shadow.shadowOffset = NSSize(width: 0, height: -8)
            NSGraphicsContext.saveGraphicsState()
            shadow.set()
            app.icon.draw(in: iconRect)
            NSGraphicsContext.restoreGraphicsState()
        } else {
            app.icon.draw(in: iconRect)
        }

        if showName || shouldShowHoverName {
            let labelRect = NSRect(
                x: 0,
                y: 8 + iconSlot + 6,
                width: bounds.width,
                height: AppGridCollectionMetrics.labelHeight
            )
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            let alpha: CGFloat = showName ? 1 : 0.85
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.labelColor.withAlphaComponent(alpha),
                .paragraphStyle: paragraph
            ]
            app.displayName.draw(with: labelRect, options: [.usesLineFragmentOrigin], attributes: attributes)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        setPointerInside(true, notify: true)
    }

    override func mouseExited(with event: NSEvent) {
        setPointerInside(false, notify: true)
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didStartDrag = false
        isLongPressActive = false
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.mouseDownEvent != nil else { return }
            self.isLongPressActive = true
            self.coordinator?.onDragModeChange(true)
            self.updateHoverPresentation(notify: true, forceHidden: true)
        }
        longPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    override func mouseDragged(with event: NSEvent) {
        if didStartDrag {
            AppDragCoordinator.shared.updateDragLocation(
                screenPoint(for: event),
                copy: event.modifierFlags.contains(.option)
            )
            return
        }

        guard let mouseDownEvent, isLongPressActive else { return }
        let dx = event.locationInWindow.x - mouseDownEvent.locationInWindow.x
        let dy = event.locationInWindow.y - mouseDownEvent.locationInWindow.y
        guard hypot(dx, dy) > 3 else { return }

        didStartDrag = true
        longPressWorkItem?.cancel()
        if let app {
            coordinator?.beginAppIconDrag(
                path: app.path.path,
                sourceContainerID: sourceContainerID
            )
        }
        AppDragCoordinator.shared.beginDrag(
            image: makeDragImage(),
            payload: dragPayload,
            at: screenPoint(for: event),
            copy: event.modifierFlags.contains(.option),
            in: window
        )
    }

    override func mouseUp(with event: NSEvent) {
        longPressWorkItem?.cancel()
        if didStartDrag {
            AppDragCoordinator.shared.finishDrag(
                at: screenPoint(for: event),
                copy: event.modifierFlags.contains(.option)
            )
            coordinator?.endAppIconDrag()
        } else if !isLongPressActive, let app {
            coordinator?.onSelectApp(app)
        } else {
            coordinator?.cancelAppIconDrag()
        }
        didStartDrag = false
        isLongPressActive = false
        mouseDownEvent = nil
        longPressWorkItem = nil
    }

    override func rightMouseDown(with event: NSEvent) {
        guard !runtimeState.bubbleDisabled, let app else { return }
        coordinator?.onEditNote(app, rootLocalFrame())
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        guard !runtimeState.bubbleDisabled else { return nil }
        let menu = NSMenu()
        let item = NSMenuItem(title: tr("appNote.edit"), action: #selector(editNoteFromMenu), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return menu
    }

    @objc private func editNoteFromMenu() {
        guard !runtimeState.bubbleDisabled, let app else { return }
        coordinator?.onEditNote(app, rootLocalFrame())
    }

    func replayPointerHover(windowPoint: NSPoint) {
        setPointerInside(bounds.contains(convert(windowPoint, from: nil)), notify: true)
    }

    private var shouldShowAppBubble: Bool {
        guard let app else { return false }
        return !runtimeState.showUncommonAppBubbles || app.isUncommon
    }

    private var shouldShowHoverName: Bool {
        !showName && !shouldShowAppBubble && isHovered
    }

    private var dragPayload: String {
        guard let app else { return "" }
        return "\(app.path.path)\n\(sourceTag)\n\(sourceContainerID)"
    }

    private func setHover(_ hover: Bool, notify: Bool) {
        guard isHovered != hover else { return }
        isHovered = hover
        needsDisplay = true
        guard notify, let app else { return }
        if hover {
            coordinator?.onBubbleHover(app, rootLocalFrame(), .entered(canShowBubble: shouldShowAppBubble))
        } else {
            coordinator?.onBubbleHover(app, rootLocalFrame(), .exited)
        }
    }

    private func setPointerInside(_ inside: Bool, notify: Bool) {
        isMouseInside = inside
        updateHoverPresentation(notify: notify)
    }

    private func updateHoverPresentation(notify: Bool, forceHidden: Bool = false) {
        let shouldHover = isMouseInside && !runtimeState.bubbleDisabled && !forceHidden
        setHover(shouldHover, notify: notify)
    }

    private func makeDragImage() -> NSImage {
        guard let app else { return NSImage(size: .zero) }
        let scale: CGFloat = AppGridCollectionMetrics.hoverScale * 1.5
        let imageSize = iconSize * scale
        let padding = iconSize * 0.45
        let canvasSize = NSSize(width: imageSize + padding * 2, height: imageSize + padding * 2)
        let dragImage = NSImage(size: canvasSize)
        dragImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.48)
        shadow.shadowBlurRadius = 24
        shadow.shadowOffset = NSSize(width: 0, height: -14)
        shadow.set()
        app.icon.draw(in: NSRect(x: padding, y: padding, width: imageSize, height: imageSize))
        dragImage.unlockFocus()
        return dragImage
    }

    private func rootLocalFrame() -> CGRect {
        guard let contentView = window?.contentView else { return .zero }
        let rectInContent = contentView.convert(bounds, from: self)
        let y = contentView.isFlipped
            ? rectInContent.minY
            : contentView.bounds.height - rectInContent.maxY
        return CGRect(
            x: rectInContent.minX,
            y: y,
            width: rectInContent.width,
            height: rectInContent.height
        )
    }

    private func screenPoint(for event: NSEvent) -> NSPoint {
        window?.convertPoint(toScreen: event.locationInWindow) ?? NSEvent.mouseLocation
    }
}
