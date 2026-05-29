import SwiftUI
import AppKit

// MARK: - Notification for manual re-index

extension Notification.Name {
    static let tagLauncherEditModeChanged = Notification.Name("TagLauncherEditModeChanged")
    static let tagLauncherAppNoteEditingChanged = Notification.Name("TagLauncherAppNoteEditingChanged")
    static let tagLauncherDataDidChange = Notification.Name("TagLauncherDataDidChange")
    static let tagLauncherOpenPreferencesRequested = Notification.Name("TagLauncherOpenPreferencesRequested")
    static let tagLauncherOverlayDidShow = Notification.Name("TagLauncherOverlayDidShow")
    static let tagLauncherOverlayDidHide = Notification.Name("TagLauncherOverlayDidHide")
    static let tagLauncherModalInteractionChanged = Notification.Name("TagLauncherModalInteractionChanged")
}

// MARK: - Edit Phase

enum EditPhase {
    case none
    case editingTags
    case editingApps
}

enum EditTagOperation {
    case add
    case remove
}

// MARK: - Native NSTextField (avoids SwiftUI TextField event issues)

/// Custom container that wraps NSTextField so that hitTest returns the container
/// and mouseDown can reliably make the text field first responder.
final class TextFieldContainer: NSView {
    let textField: NSTextField

    init(field: NSTextField) {
        self.textField = field
        super.init(frame: NSRect(x: 0, y: 0, width: 160, height: 24))
        addSubview(field)
        field.frame = bounds
        field.autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        textField.frame = bounds
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if bounds.contains(point) { return self }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        if let w = window { w.makeFirstResponder(textField) }
        textField.mouseDown(with: event)
    }
}

struct MacTextField: NSViewRepresentable {
    typealias NSViewType = TextFieldContainer
    @Binding var text: String
    let placeholder: String
    var onSubmit: (() -> Void)?

    func makeNSView(context: Context) -> TextFieldContainer {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.isBordered = true
        field.isBezeled = true
        field.drawsBackground = true
        field.isEditable = true
        field.isSelectable = true
        field.font = NSFont.systemFont(ofSize: 13)
        field.focusRingType = .default
        field.delegate = context.coordinator
        context.coordinator.field = field
        context.coordinator.onSubmit = onSubmit
        return TextFieldContainer(field: field)
    }

    func updateNSView(_ container: TextFieldContainer, context: Context) {
        if container.textField.stringValue != text {
            container.textField.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var onSubmit: (() -> Void)?
        weak var field: NSTextField?

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit?()
                return true
            }
            return false
        }
    }
}

// MARK: - Native Floating Icon Button

final class FloatingIconButtonView: NSView {
    private let imageView = NSImageView()
    var action: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(imageView)
        imageView.imageScaling = .scaleProportionallyDown
        imageView.contentTintColor = .secondaryLabelColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let size: CGFloat = 16
        imageView.frame = NSRect(
            x: (bounds.width - size) / 2,
            y: (bounds.height - size) / 2,
            width: size,
            height: size
        )
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        action?()
    }

    func setSystemImage(_ systemImage: String) {
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = NSImage(
            systemSymbolName: systemImage,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(config)
    }
}

private struct NativeFloatingIconButton: NSViewRepresentable {
    let systemImage: String
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeNSView(context: Context) -> FloatingIconButtonView {
        let view = FloatingIconButtonView(frame: NSRect(x: 0, y: 0, width: 36, height: 36))
        configure(view, context: context)
        return view
    }

    func updateNSView(_ view: FloatingIconButtonView, context: Context) {
        context.coordinator.action = action
        configure(view, context: context)
    }

    private func configure(_ view: FloatingIconButtonView, context: Context) {
        view.setSystemImage(systemImage)
        view.action = {
            context.coordinator.action()
        }
    }

    final class Coordinator {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }
    }
}

// MARK: - Tag Pill (for top navigation bar)

struct TagPill: View {
    let name: String
    let colorIndex: Int
    var dragModeActive: Bool = false
    var isDragging: Bool = false
    let action: () -> Void

    private var bgColor: Color {
        Color(nsColor: TagColor.nsColor(for: colorIndex))
    }

    private var textColor: Color {
        if colorIndex == 0 || colorIndex == 5 {
            return .primary
        }
        return .white
    }

    var body: some View {
        Text(name)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7).fill(bgColor))
            .shadow(color: .black.opacity(isDragging ? 0.34 : 0.2), radius: isDragging ? 8 : 3, y: isDragging ? 4 : 1)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .opacity(dragModeActive ? (isDragging ? 1.0 : 0.62) : 1.0)
            .animation(.easeOut(duration: 0.08), value: isDragging)
            .animation(.easeOut(duration: 0.08), value: dragModeActive)
            .contentShape(RoundedRectangle(cornerRadius: 7))
            .onTapGesture {
                action()
            }
    }
}

// MARK: - Side Tag Pill

struct SideTagPill: View {
    let name: String
    let colorIndex: Int
    var dragModeActive: Bool = false
    var isDragging: Bool = false
    let action: () -> Void

    private var bgColor: Color {
        Color(nsColor: TagColor.nsColor(for: colorIndex))
    }
    private var textColor: Color {
        colorIndex == 0 || colorIndex == 5 ? .primary : .white
    }

    var body: some View {
        Text(name)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 6).fill(bgColor))
            .shadow(color: .black.opacity(isDragging ? 0.34 : 0.2), radius: isDragging ? 8 : 3, y: isDragging ? 4 : 1)
            .scaleEffect(isDragging ? 1.03 : 1.0)
            .opacity(dragModeActive ? (isDragging ? 1.0 : 0.62) : 1.0)
            .animation(.easeOut(duration: 0.08), value: isDragging)
            .animation(.easeOut(duration: 0.08), value: dragModeActive)
            .contentShape(RoundedRectangle(cornerRadius: 6))
            .onTapGesture {
                action()
            }
    }
}

// MARK: - Color Swatch (for tag color picker)

struct ColorSwatch: View {
    let index: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(nsColor: TagColor.nsColor(for: index)))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                        .padding(2)
                )
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full-Screen Overlay

private struct AppBubbleContext {
    let app: AppInfo
    let frame: CGRect
}

private struct AppBubbleMetrics {
    let centerX: CGFloat
    let centerY: CGFloat
    let arrowX: CGFloat
    let arrowOffset: CGFloat
}

private struct AppGridInteractionState {
    var appDragModeActive = false
    var dropWarningToast: String? = nil
    var dropRefreshVisible = false
    var dropRefreshStartedAt: Date? = nil
    var hoveredBubble: AppBubbleContext? = nil
    var editingBubble: AppBubbleContext? = nil
    var pendingUncategorizedDrop: PendingUncategorizedDrop? = nil
    var pendingTagRemovalDrop: PendingTagRemovalDrop? = nil
    var uncategorizedDropSuppressFuturePrompt = false
    var tagRemovalDropSuppressFuturePrompt = false
    var appDragResetToken = 0
    var bubbleDraftNote = ""
    var tagNavigationHoveredGroupName: String? = nil
    var tagNavigationLastHoverScrollID: String? = nil
    var tagNavigationLastHoverScrollAt: Date? = nil
}

private struct EditActionFeedback: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct PendingUncategorizedDrop: Identifiable {
    let id = UUID()
    let app: AppInfo
    let assignedTags: [String]
    let removableTags: [String]
}

private struct PendingTagRemovalDrop: Identifiable {
    let id = UUID()
    let app: AppInfo
    let tagName: String
}

struct ContentView: View {
    let hideOverlay: () -> Void
    private let initialQuickSearchSource: String?

    @Environment(\.colorScheme) private var colorScheme
    @State private var allApps: [AppInfo] = []
    @State private var displayGroups: [TagGroup] = []
    @State private var tagColors: [String: Int] = [:]
    @State private var groupLayoutVersion = 0
    @State private var appGridScrollTargetID: String? = nil
    @State private var appGridScrollRequestToken = 0

    // Edit mode
    @State private var editPhase: EditPhase = .none
    @State private var selectedAppPaths: Set<URL> = []
    @State private var selectedTagNames: Set<String> = []
    @State private var removableTagNames: Set<String> = []
    @State private var editTagOperation: EditTagOperation = .add
    @State private var editActionFeedback: EditActionFeedback? = nil
    @State private var draggedTagNames: [String] = []  // live drag order
    @State private var dragItem: String? = nil          // currently dragged tag
    @State private var tagReorderFrames: [String: CGRect] = [:]
    @State private var tagNavDragModeActive = false
    @State private var tagNavDragItem: String? = nil
    @State private var tagNavReorderFrames: [String: CGRect] = [:]
    @State private var tagNavReorderDidMove = false
    // Fixed interaction for "Colorless Container": hover fills persistently; click clears.
    @State private var filledColorlessContainer: String? = nil
    @State private var appGridInteraction = AppGridInteractionState()
    @State private var smartStartNotice: SmartStartNotice? = nil
    @State private var pendingSmartStartDraft: SmartCategorizationDraft? = nil
    @State private var refreshInProgress = false
    @State private var refreshAgainAfterCurrent = false
    @State private var refreshAgainForceLayout = false
    @FocusState private var bubbleNoteFocused: Bool

    // Quick Search
    @State private var quickSearchVisible = false
    @State private var quickSearchQuery = ""
    @State private var quickSearchDocuments: [QuickSearchDocument] = []
    @State private var quickSearchResults: [QuickSearchResult] = []
    @State private var quickSearchSelectedID: URL? = nil
    @State private var quickSearchManualSelection = false
    @State private var quickSearchFocusToken = 0
    @State private var quickSearchSelectionScrollToken = 0
    @State private var quickSearchCloseHidesOverlay = false
    @State private var quickSearchErrorMessage: String? = nil
    @State private var initialQuickSearchConsumed = false

    init(hideOverlay: @escaping () -> Void, initialQuickSearchSource: String? = nil) {
        self.hideOverlay = hideOverlay
        self.initialQuickSearchSource = initialQuickSearchSource
        let startsInQuickSearch = initialQuickSearchSource != nil
        _quickSearchVisible = State(initialValue: startsInQuickSearch)
        _quickSearchCloseHidesOverlay = State(initialValue: initialQuickSearchSource == QuickSearchOpenSource.globalHidden)
        _quickSearchFocusToken = State(initialValue: startsInQuickSearch ? 1 : 0)
    }

    // Configurable defaults
    @AppStorage("defaultGroupName") private var defaultGroupName = "Other"
    @AppStorage("tagFontSize") private var tagFontSize: Double = AppDefaults.tagFontSize
    @AppStorage("iconSize") private var iconSize: Double = AppDefaults.iconSize
    @AppStorage("tagPosition") private var tagPosition = AppDefaults.tagPosition
    @State private var notchHeight: CGFloat = 0
    @AppStorage("displayMode") private var displayMode = AppDefaults.displayMode
    @AppStorage("hideAppNames") private var hideAppNames = AppDefaults.hideAppNames
    @AppStorage("showUncommonAppBubbles") private var showUncommonAppBubbles = AppDefaults.showUncommonAppBubbles
    @AppStorage("useAppKitTagNavigation") private var useAppKitTagNavigation = AppDefaults.useAppKitTagNavigation
    @AppStorage("skipTagRemovalDropConfirm") private var skipTagRemovalDropConfirm = false
    @AppStorage("skipUncategorizedDropConfirm") private var skipUncategorizedDropConfirm = false

    private let editSidebarWidth: CGFloat = 188
    private let editSidebarHorizontalInset: CGFloat = 12
    private let floatingControlsTrailingInset: CGFloat = 20
    private let floatingControlsReservedWidth: CGFloat = 120
    private var appBubbleDisabled: Bool {
        appGridInteraction.appDragModeActive
            || appGridInteraction.pendingUncategorizedDrop != nil
            || appGridInteraction.pendingTagRemovalDrop != nil
    }
    private var appGridHighlightedGroupName: String? {
        appGridInteraction.tagNavigationHoveredGroupName
            ?? (isColorlessContainerMode ? filledColorlessContainer : nil)
    }
    private let rightSidebarFloatingClearance: CGFloat = 44
    private let tagNavigationHoverScrollInterval: TimeInterval = 0.22

    private var floatingButtonSurfaceColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.78)
    }

    private var isSideLayout: Bool {
        tagPosition == "left" || tagPosition == "right"
    }

    private var floatingControlsTopInset: CGFloat {
        notchHeight > 0 ? notchHeight + 10 : 20
    }

    private var isColorlessContainerMode: Bool {
        displayMode == "container" || displayMode == "gridContainer"
    }

    private var shouldRenderAppGridBehindQuickSearch: Bool {
        !quickSearchVisible || !quickSearchCloseHidesOverlay
    }

    var body: some View {
        ZStack {
            if shouldRenderAppGridBehindQuickSearch {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if shouldRenderAppGridBehindQuickSearch {
                if notchHeight > 0 {
                    VStack {
                        Rectangle().fill(.black)
                            .frame(height: notchHeight)
                            .ignoresSafeArea(edges: .top)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }

                switch editPhase {
                case .none:
                    normalContent
                case .editingTags:
                    editTagsView
                case .editingApps:
                    editAppsView
                }

                uncommonAppBubbleOverlay
                smartStartNoticeOverlay
                editActionFeedbackOverlay
                uncategorizedDropConfirmOverlay
                tagRemovalDropConfirmOverlay
            }

            quickSearchOverlay

            if shouldRenderAppGridBehindQuickSearch, let message = appGridInteraction.dropWarningToast {
                Text(message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThickMaterial)
                            .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
                    )
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                    .allowsHitTesting(false)
            }

            if shouldRenderAppGridBehindQuickSearch && appGridInteraction.dropRefreshVisible {
                Color.black.opacity(0.08)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)

                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .scaleEffect(1.15)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThickMaterial)
                            .shadow(color: .black.opacity(0.26), radius: 24, y: 12)
                    )
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            refreshNotchHeight()
            refreshAppsIfNeeded()
            if let initialQuickSearchSource, !initialQuickSearchConsumed {
                initialQuickSearchConsumed = true
                quickSearchCloseHidesOverlay = initialQuickSearchSource == QuickSearchOpenSource.globalHidden
                if !quickSearchVisible {
                    quickSearchVisible = true
                    quickSearchFocusToken &+= 1
                }
                refreshQuickSearchResults()
                NotificationCenter.default.post(
                    name: .tagLauncherQuickSearchVisibilityChanged,
                    object: nil,
                    userInfo: ["active": true]
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagLauncherOverlayDidShow)) { _ in
            resetTransientDragState()
            refreshNotchHeight()
            refreshAppsIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagLauncherOverlayDidHide)) { _ in
            resetTransientDragState()
            closeQuickSearch(notify: true, hideOverlayIfNeeded: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagLauncherQuickSearchRequested)) { notification in
            let source = notification.userInfo?["source"] as? String ?? QuickSearchOpenSource.mainOverlay
            openQuickSearch(source: source)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagLauncherQuickSearchDismissRequested)) { _ in
            closeQuickSearch()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            guard allApps.isEmpty, !refreshInProgress else { return }
            refreshApps()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagLauncherDataDidChange)) { _ in
            refreshApps(forceLayoutRefresh: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            let appsSnapshot = allApps
            DispatchQueue.global(qos: .userInitiated).async {
                _ = SmartStartService.relocalizeDefaultNotesForCurrentLanguage(apps: appsSnapshot)
                DispatchQueue.main.async {
                    refreshApps(forceLayoutRefresh: true)
                }
            }
        }
        .onChange(of: editPhase) { _, newPhase in
            let active = newPhase != .none
            dismissAppBubble()
            NotificationCenter.default.post(
                name: .tagLauncherEditModeChanged,
                object: nil,
                userInfo: ["active": active]
            )
        }
        .onChange(of: bubbleNoteFocused) { _, focused in
            if appGridInteraction.editingBubble != nil && !focused {
                commitBubbleNote()
            }
        }
        .onChange(of: draggedTagNames) { _, newOrder in
            rebuildDisplayGroups(apps: allApps, tagOrder: newOrder)
        }
        .onChange(of: defaultGroupName) { _, _ in
            rebuildDisplayGroups(apps: allApps, tagOrder: draggedTagNames)
        }
        .onChange(of: quickSearchQuery) { _, _ in
            quickSearchErrorMessage = nil
            refreshQuickSearchResults()
        }
        .onChange(of: appGridInteraction.pendingUncategorizedDrop != nil) { _, _ in
            publishModalInteractionState()
        }
        .onChange(of: appGridInteraction.pendingTagRemovalDrop != nil) { _, _ in
            publishModalInteractionState()
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .tagLauncherModalInteractionChanged,
                object: nil,
                userInfo: ["active": false]
            )
        }
    }

    private func publishModalInteractionState() {
        NotificationCenter.default.post(
            name: .tagLauncherModalInteractionChanged,
            object: nil,
            userInfo: ["active": appGridInteraction.pendingUncategorizedDrop != nil || appGridInteraction.pendingTagRemovalDrop != nil]
        )
    }

    /// Set edit phase with synchronous notification BEFORE state change.
    func setEditPhase(_ phase: EditPhase) {
        if phase != .none {
            NotificationCenter.default.post(name: .tagLauncherEditModeChanged, object: nil, userInfo: ["active": true])
            NSApp.activate(ignoringOtherApps: true)
            // Always sync tag list from database when entering edit mode
            let store = TagDatabase.load()
            tagColors = store.tags.mapValues { $0.color }
            draggedTagNames = TagEditor.orderedTagNames()
        }
        editPhase = phase
        if phase == .none {
            TagDatabase.flushPendingCategorySchemeBackupBatch()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .tagLauncherEditModeChanged, object: nil, userInfo: ["active": false])
            }
        }
    }

    // MARK: - Quick Search

    private var quickSearchOverlay: some View {
        GeometryReader { proxy in
            if quickSearchVisible {
                Color.black.opacity(0.001)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        closeQuickSearch()
                    }
                    .zIndex(899)

                QuickSearchPanelPresentationView(
                    query: $quickSearchQuery,
                    results: quickSearchResults,
                    selectedID: quickSearchSelectedID,
                    focusToken: quickSearchFocusToken,
                    selectionScrollToken: quickSearchSelectionScrollToken,
                    isLoading: quickSearchDocuments.isEmpty && refreshInProgress,
                    maxVisibleRows: quickSearchMaxVisibleRows(in: proxy.size),
                    panelTopY: quickSearchPanelTopY(in: proxy.size),
                    panelHeight: quickSearchPanelContentHeight(in: proxy.size),
                    errorMessage: quickSearchErrorMessage,
                    onCommand: handleQuickSearchCommand,
                    onHover: selectQuickSearchResult,
                    onLaunch: launchQuickSearchResult
                )
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .zIndex(900)
            }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.12), value: quickSearchVisible)
    }

    private func quickSearchPanelContentHeight(in size: CGSize) -> CGFloat {
        let hasResultList = !(quickSearchDocuments.isEmpty && refreshInProgress)
            && quickSearchErrorMessage == nil
            && !quickSearchResults.isEmpty
        let visibleRows = min(max(1, quickSearchResults.count), quickSearchMaxVisibleRows(in: size))
        return QuickSearchPanelMetrics.contentHeight(
            hasResultList: hasResultList,
            visibleRows: visibleRows
        )
    }

    private func quickSearchPanelTopY(in size: CGSize) -> CGFloat {
        max(notchHeight + 54, min(112, size.height * 0.12))
    }

    private func quickSearchMaxVisibleRows(in size: CGSize) -> Int {
        let bottomClearance: CGFloat = 84
        let chromeHeight = QuickSearchPanelMetrics.headerHeight
            + QuickSearchPanelMetrics.dividerHeight
            + QuickSearchPanelMetrics.resultListVerticalInset * 2
        let rowHeightWithSpacing = QuickSearchPanelMetrics.rowHeight
            + QuickSearchPanelMetrics.rowSpacing
        let availableHeight = max(0, size.height - quickSearchPanelTopY(in: size) - bottomClearance - chromeHeight)
        return max(1, min(8, Int(floor(availableHeight / rowHeightWithSpacing))))
    }

    private func openQuickSearch(source: String) {
        guard canOpenQuickSearch else { return }
        dismissAppBubble()
        quickSearchCloseHidesOverlay = source == QuickSearchOpenSource.globalHidden
        quickSearchVisible = true
        quickSearchQuery = ""
        quickSearchManualSelection = false
        quickSearchErrorMessage = nil
        quickSearchFocusToken &+= 1
        refreshQuickSearchResults()
        NotificationCenter.default.post(
            name: .tagLauncherQuickSearchVisibilityChanged,
            object: nil,
            userInfo: ["active": true]
        )
    }

    private var canOpenQuickSearch: Bool {
        editPhase == .none
            && appGridInteraction.pendingUncategorizedDrop == nil
            && smartStartNotice == nil
            && !appGridInteraction.dropRefreshVisible
            && !quickSearchVisible
    }

    private func closeQuickSearch(notify: Bool = true, hideOverlayIfNeeded: Bool = true) {
        let shouldHideOverlay = quickSearchVisible && quickSearchCloseHidesOverlay && hideOverlayIfNeeded
        guard quickSearchVisible else { return }
        quickSearchVisible = false
        quickSearchQuery = ""
        quickSearchResults = []
        quickSearchSelectedID = nil
        quickSearchManualSelection = false
        quickSearchErrorMessage = nil
        quickSearchCloseHidesOverlay = false
        if notify {
            NotificationCenter.default.post(
                name: .tagLauncherQuickSearchVisibilityChanged,
                object: nil,
                userInfo: ["active": false]
            )
        }
        if shouldHideOverlay {
            hideOverlay()
        }
    }

    private func refreshQuickSearchResults() {
        let previousSelection = quickSearchSelectedID
        quickSearchResults = QuickSearchEngine.search(quickSearchQuery, documents: quickSearchDocuments)

        if quickSearchResults.isEmpty {
            quickSearchSelectedID = nil
            quickSearchManualSelection = false
            return
        }

        if quickSearchManualSelection,
           let previousSelection,
           quickSearchResults.contains(where: { $0.id == previousSelection }) {
            quickSearchSelectedID = previousSelection
        } else {
            quickSearchSelectedID = quickSearchResults.first?.id
            quickSearchManualSelection = false
        }
    }

    private func handleQuickSearchCommand(_ command: QuickSearchCommand) {
        switch command {
        case .moveUp:
            moveQuickSearchSelection(by: -1)
        case .moveDown:
            moveQuickSearchSelection(by: 1)
        case .submit:
            guard let selected = selectedQuickSearchResult else { return }
            launchQuickSearchResult(selected)
        case .dismiss:
            closeQuickSearch()
        }
    }

    private var selectedQuickSearchResult: QuickSearchResult? {
        guard let quickSearchSelectedID else { return nil }
        return quickSearchResults.first { $0.id == quickSearchSelectedID }
    }

    private func moveQuickSearchSelection(by delta: Int) {
        guard !quickSearchResults.isEmpty else { return }
        let currentIndex = quickSearchSelectedID.flatMap { id in
            quickSearchResults.firstIndex { $0.id == id }
        } ?? 0
        let nextIndex = min(max(currentIndex + delta, 0), quickSearchResults.count - 1)
        quickSearchSelectedID = quickSearchResults[nextIndex].id
        quickSearchManualSelection = true
        quickSearchSelectionScrollToken &+= 1
    }

    private func selectQuickSearchResult(_ result: QuickSearchResult) {
        guard quickSearchSelectedID != result.id || !quickSearchManualSelection else { return }
        quickSearchSelectedID = result.id
        quickSearchManualSelection = true
    }

    private func launchQuickSearchResult(_ result: QuickSearchResult) {
        quickSearchErrorMessage = nil
        launchApp(
            result.app,
            closeQuickSearchOnSuccess: true,
            closeOverlayOnSuccess: true,
            onFailure: {
                quickSearchErrorMessage = tr("quickSearch.launchFailed")
                quickSearchFocusToken &+= 1
                NSAccessibility.post(
                    element: NSApp.mainWindow as Any,
                    notification: .announcementRequested,
                    userInfo: [.announcement: tr("quickSearch.launchFailed")]
                )
            }
        )
    }

    // MARK: - Normal Content

    private var normalContent: some View {
        ZStack(alignment: .topTrailing) {
            if isSideLayout {
                sideLayout
            } else {
                topLayout
            }

            floatingActionButtons
                .padding(.top, floatingControlsTopInset)
                .padding(.trailing, floatingControlsTrailingInset)
                .zIndex(2)
        }
    }

    private var floatingActionButtons: some View {
        HStack(spacing: 8) {
            floatingOverlayButton(systemImage: "pencil.line") {
                setEditPhase(.editingApps)
            }
            .keyboardShortcut("e", modifiers: .control)
            .help(tr("edit.title"))

            floatingOverlayButton(systemImage: "gearshape") {
                NotificationCenter.default.post(name: .tagLauncherOpenPreferencesRequested, object: nil)
            }
            .help(tr("menu.preferences"))
        }
    }

    private func floatingOverlayButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        NativeFloatingIconButton(systemImage: systemImage, action: action)
            .frame(width: 36, height: 36)
            .background(Circle().fill(floatingButtonSurfaceColor))
    }

    // MARK: - Top / Side Layouts

    private var topLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: notchHeight > 0 ? notchHeight + 14 : 28)
            if !tagLabels.isEmpty { topTagNavigation.padding(.bottom, 8) }
            Divider().opacity(0.3)
            appGridContent
        }
    }

    private var sideLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: notchHeight > 0 ? notchHeight + 14 : 28)
            Divider().opacity(0.3)
            HStack(spacing: 0) {
                if tagPosition == "left" { leftTagSidebar; sideDivider }
                appGridContent
                if tagPosition == "right" { sideDivider; rightTagSidebar }
            }
        }
    }

    private var topTagNavigation: some View {
        Group {
            if useAppKitTagNavigation {
                appKitTagNavigation(orientation: .horizontal)
                    .frame(height: 34)
            } else {
                swiftUITopTagBar
            }
        }
    }

    private var leftTagSidebar: some View {
        Group {
            if useAppKitTagNavigation {
                appKitTagNavigation(orientation: .vertical)
            } else {
                swiftUITagSidebarList
            }
        }
        .frame(width: 135)
    }

    private var rightTagSidebar: some View {
        Group {
            if useAppKitTagNavigation {
                appKitTagNavigation(orientation: .vertical)
            } else {
                swiftUITagSidebarList
            }
        }
        .padding(.top, rightSidebarFloatingClearance)
        .frame(width: 135)
    }

    private func appKitTagNavigation(orientation: TagNavigationView.Orientation) -> some View {
        let isHorizontal = orientation == .horizontal
        return TagNavigationView(
            items: tagLabels,
            orientation: orientation,
            contentInsets: isHorizontal
                ? NSEdgeInsets(top: 3, left: 24, bottom: 3, right: tagPosition == "top" ? floatingControlsReservedWidth : 24)
                : NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12),
            dragModeActive: tagNavDragModeActive,
            draggingItemID: tagNavDragItem,
            onActivate: { tagID in
                activateTagNavigation(tagID)
            },
            onHoverChange: { tagID, active in
                handleTagNavigationHover(tagID, active: active)
            },
            canReorder: { tagID in
                canReorderTag(tagID)
            },
            onReorderBegan: { tagID in
                beginTagNavReorder(tagID)
            },
            onReorderMoved: { tagID, targetID in
                reorderTagNavItem(fromName: tagID, to: targetID)
            },
            onReorderEnded: {
                endTagNavReorder()
            }
        )
    }

    private var swiftUITopTagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tagLabels) { tag in
                    TagPill(name: tag.name, colorIndex: tag.colorIndex,
                            dragModeActive: tagNavDragModeActive && canReorderTag(tag.name),
                            isDragging: tagNavDragItem == tag.name,
                            action: {
                        activateTagNavigation(tag.id)
                    })
                    .background(tagNavFrameReader(for: tag.name))
                    .zIndex(tagNavDragItem == tag.name ? 1 : 0)
                    .highPriorityGesture(tagNavReorderGesture(for: tag.name))
                    .onHover { hovering in
                        handleTagNavigationHover(tag.id, active: hovering)
                    }
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, tagPosition == "top" ? floatingControlsReservedWidth : 24)
            .coordinateSpace(name: "tagNavReorder")
            .onPreferenceChange(TagNavReorderFramePreferenceKey.self) { frames in
                tagNavReorderFrames = frames
            }
        }
    }

    private var swiftUITagSidebarList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(tagLabels) { tag in
                    SideTagPill(name: tag.name, colorIndex: tag.colorIndex,
                                dragModeActive: tagNavDragModeActive && canReorderTag(tag.name),
                                isDragging: tagNavDragItem == tag.name,
                                action: {
                        activateTagNavigation(tag.id)
                    })
                    .background(tagNavFrameReader(for: tag.name))
                    .zIndex(tagNavDragItem == tag.name ? 1 : 0)
                    .highPriorityGesture(tagNavReorderGesture(for: tag.name))
                    .onHover { hovering in
                        handleTagNavigationHover(tag.id, active: hovering)
                    }
                }
            }
            .padding(12)
            .coordinateSpace(name: "tagNavReorder")
            .onPreferenceChange(TagNavReorderFramePreferenceKey.self) { frames in
                tagNavReorderFrames = frames
            }
        }
    }

    private var sideDivider: some View {
        Rectangle().fill(.secondary.opacity(0.12)).frame(width: 1)
    }

    private var appGridContent: some View {
        Group {
            if allApps.isEmpty {
                Spacer()
                ProgressView().scaleEffect(0.8)
                Spacer()
            } else {
                AppGridCollectionView(
                    groups: displayGroups,
                    tagColors: tagColors,
                    displayMode: displayMode,
                    iconSize: iconSize,
                    showNames: !hideAppNames,
                    bubbleDisabled: appBubbleDisabled,
                    showUncommonAppBubbles: showUncommonAppBubbles,
                    highlightedGroupName: appGridHighlightedGroupName,
                    contentRevision: groupLayoutVersion,
                    scrollTargetID: appGridScrollTargetID,
                    scrollRequestToken: appGridScrollRequestToken,
                    onSelectApp: { app in openApp(app) },
                    onBubbleHover: handleBubbleHover,
                    onEditNote: beginEditingBubbleNote,
                    onDropApp: { path, source, target, copy in
                        dropApp(path: path, sourceTag: source, targetTag: target, copy: copy)
                    },
                    onDropOutsideGroup: { path, source, copy in
                        dropAppOutsideGroup(path: path, sourceTag: source, copy: copy)
                    },
                    onGroupActivate: { groupName in
                        if isColorlessContainerMode {
                            toggleColorlessFill(groupName)
                        }
                    },
                    onScrollActivity: handleAppGridScrollActivity,
                    onDragModeChange: { setAppDragMode($0) }
                )
            }
        }
    }

    private var uncommonAppBubbleOverlay: some View {
        GeometryReader { proxy in
            if let context = appGridInteraction.editingBubble ?? appGridInteraction.hoveredBubble {
                let rootFrame = proxy.frame(in: .global)
                let editing = appGridInteraction.editingBubble != nil
                let width = min(editing ? 440 : 520, max(260, proxy.size.width - 48))
                let placement = bubblePlacement(for: context.frame, rootFrame: rootFrame)
                let metrics = bubbleMetrics(
                    for: context,
                    rootFrame: rootFrame,
                    rootSize: proxy.size,
                    width: width,
                    placement: placement,
                    isEditing: editing
                )

                AppNameBubble(
                    appName: context.app.displayName,
                    note: currentNote(for: context.app),
                    isEditing: editing,
                    placement: placement,
                    arrowOffset: metrics.arrowOffset,
                    draftNote: $appGridInteraction.bubbleDraftNote,
                    noteFocused: $bubbleNoteFocused,
                    onCommit: commitBubbleNote,
                    onCancel: dismissAppBubble
                )
                .frame(width: width)
                .fixedSize(horizontal: false, vertical: true)
                .position(x: metrics.centerX, y: metrics.centerY)
                .transition(.opacity)
                .zIndex(500)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(appGridInteraction.editingBubble != nil)
    }

    private var smartStartNoticeOverlay: some View {
        SmartStartNoticeOverlay(
            notice: smartStartNotice,
            onDismiss: dismissSmartStartNotice,
            onApply: applySmartStartSuggestion,
            onUndo: undoSmartStart
        )
    }
    // MARK: - Edit Tags View

    private var editTagsView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    setEditPhase(.none)
                } label: {
                    Label(tr("edit.exit"), systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                Spacer()
                Text(tr("edit.tags")).font(.headline)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, notchHeight > 0 ? notchHeight + 10 : 20)
            .padding(.bottom, 12)

            Divider().opacity(0.3)

            TagEditorView(
                tagColors: $tagColors,
                excludedTagNames: ["Mac自带", defaultGroupName],
                onRefresh: { refreshApps() }
            )
        }
    }

    // MARK: - Edit Apps View

    private var editAppsView: some View {
        VStack(spacing: 0) {
            EditAppsHeaderView(
                operation: editTagOperation,
                hintText: editModeHintText,
                confirmTitle: editConfirmTitle,
                isConfirmDisabled: selectedAppPaths.isEmpty || pendingOperationTagNames.isEmpty,
                notchHeight: notchHeight,
                onExit: {
                    cancelEditApps()
                    setEditPhase(.none)
                },
                onSelectOperation: setEditTagOperation,
                onConfirm: confirmAssign
            )

            Divider().opacity(0.3)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    EditAppsSidebarIntroView(
                        width: editSidebarWidth,
                        horizontalInset: editSidebarHorizontalInset
                    )

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
                            ForEach(sortedTagNames, id: \.self) { tagName in
                                selectableTagItem(tagName)
                                    .opacity(dragItem == tagName ? 0.72 : 1.0)
                                    .scaleEffect(dragItem == tagName ? 1.03 : 1.0)
                                    .background(
                                        GeometryReader { proxy in
                                            Color.clear.preference(
                                                key: TagReorderFramePreferenceKey.self,
                                                value: [tagName: proxy.frame(in: .named("tagReorderList"))]
                                            )
                                        }
                                    )
                                    .zIndex(dragItem == tagName ? 1 : 0)
                                    .highPriorityGesture(tagReorderGesture(for: tagName))
                            }
                        }
                        .padding(12)
                        .coordinateSpace(name: "tagReorderList")
                        .onPreferenceChange(TagReorderFramePreferenceKey.self) { frames in
                            tagReorderFrames = frames
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(width: editSidebarWidth, alignment: .topLeading)
                Rectangle().fill(.secondary.opacity(0.12)).frame(width: 1)

                if allApps.isEmpty {
                    Spacer(); ProgressView().scaleEffect(0.8); Spacer()
                } else {
                    editAppsGrid
                }
            }

        }
    }

    private var editAppsGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(editGroups) { group in
                    editFlatGroup(group)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func editFlatGroup(_ group: TagGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
                Text(group.name)
                    .font(.system(size: tagFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
            }
            .padding(.bottom, 6)

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(
                            minimum: AppGridItemMetrics.stableWidth(iconSize: iconSize),
                            maximum: AppGridItemMetrics.stableWidth(iconSize: iconSize) + 36
                        ),
                        spacing: 6
                    )
                ],
                spacing: 2
            ) {
                ForEach(group.apps) { app in editableAppItem(app) }
            }
            .frame(minHeight: group.apps.isEmpty ? max(52, iconSize + 12) : 0)
        }
    }

    private func selectableTagItem(_ tagName: String) -> some View {
        let isSelected = selectedTagNames.contains(tagName)
        let isRemovableCandidate = removableTagNames.contains(tagName)
        let isUncommon = tagName == TagDatabase.uncommonTagKey
        let colorIndex = isUncommon ? 0 : (tagColors[tagName] ?? 0)
        return EditSelectableTagItem(
            tagName: tagName,
            displayName: displayTagName(tagName),
            colorIndex: colorIndex,
            operation: editTagOperation,
            isSelected: isSelected,
            isRemovableCandidate: isRemovableCandidate
        ) {
            if isSelected {
                selectedTagNames.remove(tagName)
            } else {
                selectedTagNames.insert(tagName)
            }
        }
    }

    private func tagReorderGesture(for tagName: String) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("tagReorderList"))
            .onChanged { value in
                guard canReorderTag(tagName) else { return }
                if dragItem == nil {
                    dragItem = tagName
                }
                guard dragItem == tagName else { return }
                reorderDraggedTag(at: value.location)
            }
            .onEnded { _ in
                guard canReorderTag(tagName) else { return }
                dragItem = nil
                TagEditor.reorderTags(draggedTagNames)
            }
    }

    private func reorderDraggedTag(at location: CGPoint) {
        guard let fromName = dragItem,
              let targetName = tagReorderFrames.first(where: { $0.value.contains(location) })?.key,
              fromName != targetName,
              let fromIndex = draggedTagNames.firstIndex(of: fromName),
              let toIndex = draggedTagNames.firstIndex(of: targetName)
        else { return }

        withAnimation(.easeInOut(duration: 0.14)) {
            let destination = toIndex > fromIndex ? toIndex + 1 : toIndex
            draggedTagNames.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: destination)
        }
    }

    private func confirmAssign() {
        let selectedApps = allApps.filter { selectedAppPaths.contains($0.path) }
        let tags = pendingOperationTagNames
        guard !selectedApps.isEmpty, !tags.isEmpty else { return }

        let paths = selectedApps.map { $0.path.path }
        let feedback = buildEditActionFeedback(for: selectedApps, tags: tags)

        switch editTagOperation {
        case .add:
            TagEditor.appendTags(tags, to: paths)
        case .remove:
            TagEditor.removeTags(tags, from: paths)
        }
        selectedAppPaths = []
        selectedTagNames = []
        removableTagNames = []
        refreshApps()
        showEditActionFeedback(feedback)
    }

    private func cancelEditApps() {
        selectedAppPaths = []
        selectedTagNames = []
        removableTagNames = []
        editTagOperation = .add
    }

    private func editableAppItem(_ app: AppInfo) -> some View {
        let isSelected = selectedAppPaths.contains(app.path)
        return EditableAppSelectionItem(
            app: app,
            iconSize: iconSize,
            isSelected: isSelected
        ) {
            toggleEditableAppSelection(app)
        }
    }

    private func toggleEditableAppSelection(_ app: AppInfo) {
        if selectedAppPaths.contains(app.path) {
            selectedAppPaths.remove(app.path)
        } else {
            selectedAppPaths.insert(app.path)
        }
        syncSelectedTagsFromSelectedApps()
    }

    private func syncSelectedTagsFromSelectedApps() {
        guard !selectedAppPaths.isEmpty else {
            selectedTagNames = []
            removableTagNames = []
            return
        }

        guard editTagOperation == .remove else {
            removableTagNames = []
            return
        }

        let selectedApps = allApps.filter { selectedAppPaths.contains($0.path) }
        let autoSelectedTags = selectedApps.reduce(into: Set<String>()) { result, app in
            result.formUnion(app.tags)
            if app.isUncommon {
                result.insert(TagDatabase.uncommonTagKey)
            }
        }
        removableTagNames = autoSelectedTags
        selectedTagNames = autoSelectedTags
    }

    private var editConfirmTitle: String {
        switch editTagOperation {
        case .add:
            return tr("edit.confirmAdd")
        case .remove:
            return tr("edit.confirmRemove")
        }
    }

    private func setEditTagOperation(_ mode: EditTagOperation) {
        guard editTagOperation != mode else { return }
        editTagOperation = mode
        if mode == .add {
            selectedTagNames = []
            removableTagNames = []
        } else {
            syncSelectedTagsFromSelectedApps()
        }
    }

    private var pendingOperationTagNames: [String] {
        switch editTagOperation {
        case .add:
            return sortedTagNames.filter { selectedTagNames.contains($0) }
        case .remove:
            return sortedTagNames.filter { removableTagNames.contains($0) && !selectedTagNames.contains($0) }
        }
    }

    private var editModeHintText: String {
        editTagOperation == .remove ? tr("edit.removeHint") : tr("edit.modeHint")
    }

    private var editActionFeedbackOverlay: some View {
        GeometryReader { proxy in
            if let feedback = editActionFeedback {
                ZStack {
                    Color.black.opacity(0.08)
                        .ignoresSafeArea()

                    EditActionFeedbackBubble(
                        title: feedback.title,
                        message: feedback.message,
                        onClose: dismissEditActionFeedback
                    )
                    .frame(width: min(760, max(360, proxy.size.width - 120)))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
                .zIndex(700)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(editActionFeedback != nil)
    }

    private var uncategorizedDropConfirmOverlay: some View {
        GeometryReader { proxy in
            if let pendingDrop = appGridInteraction.pendingUncategorizedDrop {
                ZStack {
                    Color.black.opacity(0.14)
                        .ignoresSafeArea()

                    UncategorizedDropConfirmBubble(
                        title: tr("drop.uncategorizedConfirmTitle"),
                        message: uncategorizedConfirmMessage(for: pendingDrop),
                        doNotRemindTitle: tr("drop.removeTagDoNotAskAgain"),
                        doNotRemind: $appGridInteraction.uncategorizedDropSuppressFuturePrompt,
                        cancelTitle: tr("tag.cancel"),
                        confirmTitle: tr("edit.confirm"),
                        onCancel: dismissUncategorizedDropConfirm,
                        onConfirm: confirmPendingUncategorizedDrop
                    )
                    .frame(width: min(540, max(340, proxy.size.width - 120)))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
                .zIndex(710)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(appGridInteraction.pendingUncategorizedDrop != nil)
    }

    private var tagRemovalDropConfirmOverlay: some View {
        GeometryReader { proxy in
            if let pendingDrop = appGridInteraction.pendingTagRemovalDrop {
                ZStack {
                    Color.black.opacity(0.14)
                        .ignoresSafeArea()

                    TagRemovalDropConfirmBubble(
                        title: tr("drop.removeTagConfirmTitle"),
                        message: tagRemovalConfirmMessage(for: pendingDrop),
                        doNotRemindTitle: tr("drop.removeTagDoNotAskAgain"),
                        doNotRemind: $appGridInteraction.tagRemovalDropSuppressFuturePrompt,
                        cancelTitle: tr("drop.removeTagConfirmNo"),
                        confirmTitle: tr("drop.removeTagConfirmYes"),
                        onCancel: dismissTagRemovalDropConfirm,
                        onConfirm: confirmPendingTagRemovalDrop
                    )
                    .frame(width: min(560, max(350, proxy.size.width - 120)))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                }
                .zIndex(711)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(appGridInteraction.pendingTagRemovalDrop != nil)
    }

    private func buildEditActionFeedback(for selectedApps: [AppInfo], tags: [String]) -> EditActionFeedback {
        let appNames = selectedApps.map(\.name)
            .joined(separator: localizedListSeparator)

        switch editTagOperation {
        case .add:
            let actualAddCount = selectedApps.reduce(into: 0) { count, app in
                count += tags.reduce(into: 0) { subtotal, tagName in
                    if !appHasTag(app, tagName: tagName) {
                        subtotal += 1
                    }
                }
            }

            return EditActionFeedback(
                title: tr("edit.confirmAdd"),
                message: formattedFeedbackMessage(
                    forKey: "edit.feedbackAddFormat",
                    replacements: [
                        "%appCount%": "\(selectedApps.count)",
                        "%appNames%": appNames,
                        "%tagCount%": "\(actualAddCount)"
                    ]
                )
            )

        case .remove:
            let actualRemovedTagNames = tags.filter { tagName in
                selectedApps.contains(where: { appHasTag($0, tagName: tagName) })
            }
            let actualRemoveCount = selectedApps.reduce(into: 0) { count, app in
                count += tags.reduce(into: 0) { subtotal, tagName in
                    if appHasTag(app, tagName: tagName) {
                        subtotal += 1
                    }
                }
            }

            return EditActionFeedback(
                title: tr("edit.confirmRemove"),
                message: formattedFeedbackMessage(
                    forKey: "edit.feedbackRemoveFormat",
                    replacements: [
                        "%appCount%": "\(selectedApps.count)",
                        "%appNames%": appNames,
                        "%tagCount%": "\(actualRemoveCount)",
                        "%tagNames%": actualRemovedTagNames
                            .map(displayTagName)
                            .joined(separator: localizedListSeparator)
                    ]
                )
            )
        }
    }

    private func appHasTag(_ app: AppInfo, tagName: String) -> Bool {
        if tagName == TagDatabase.uncommonTagKey {
            return app.isUncommon
        }
        return app.tags.contains(tagName)
    }

    private func formattedFeedbackMessage(forKey key: String, replacements: [String: String]) -> String {
        replacements.reduce(tr(key)) { partial, replacement in
            partial.replacingOccurrences(of: replacement.key, with: replacement.value)
        }
    }

    private func showEditActionFeedback(_ feedback: EditActionFeedback) {
        let feedbackID = feedback.id
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            editActionFeedback = feedback
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            guard editActionFeedback?.id == feedbackID else { return }
            dismissEditActionFeedback()
        }
    }

    private func dismissEditActionFeedback() {
        withAnimation(.easeOut(duration: 0.18)) {
            editActionFeedback = nil
        }
    }

    private func showSmartStartNotice(
        mode: SmartStartNoticeMode,
        summary: SmartStartSummary
    ) {
        let titleKey: String
        let messageKey: String

        switch mode {
        case .autoApplied:
            titleKey = "smartstart.auto.title"
            messageKey = "smartstart.auto.messageFormat"
        case .suggestionOnly:
            titleKey = "smartstart.suggestion.title"
            messageKey = "smartstart.suggestion.messageFormat"
        case .manuallyApplied:
            titleKey = "smartstart.applied.title"
            messageKey = "smartstart.applied.messageFormat"
        }

        let notice = SmartStartNotice(
            mode: mode,
            title: tr(titleKey),
            message: formattedFeedbackMessage(
                forKey: messageKey,
                replacements: [
                    "%appCount%": "\(summary.matchedAppCount)",
                    "%tagCount%": "\(summary.assignedTagCount)",
                    "%createdTagCount%": "\(summary.createdTagCount)"
                ]
            ),
            summary: summary
        )

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            smartStartNotice = notice
        }
    }

    private func handleSmartStartRunResult(_ result: SmartStartRunResult) {
        switch result.mode {
        case .none:
            return
        case .autoApplied:
            pendingSmartStartDraft = nil
            if let summary = result.summary {
                showSmartStartNotice(mode: .autoApplied, summary: summary)
            }
        case .suggestionOnly:
            pendingSmartStartDraft = result.draft
            if let summary = result.summary {
                showSmartStartNotice(mode: .suggestionOnly, summary: summary)
            }
        }
    }

    private func applySmartStartSuggestion() {
        guard let draft = pendingSmartStartDraft else {
            dismissSmartStartNotice()
            return
        }

        let scannedApps = allApps
        DispatchQueue.global(qos: .userInitiated).async {
            let result = AppLibraryController.applySmartStartSuggestion(
                draft,
                scannedApps: scannedApps
            )

            DispatchQueue.main.async {
                pendingSmartStartDraft = nil
                applyAppLibrarySnapshot(result.snapshot)
                if let summary = result.summary {
                    showSmartStartNotice(mode: .manuallyApplied, summary: summary)
                } else {
                    dismissSmartStartNotice()
                }
            }
        }
    }

    private func undoSmartStart() {
        guard let backupPath = smartStartNotice?.summary.backupPath else {
            dismissSmartStartNotice()
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let restored = SmartStartService.restoreBackup(at: backupPath)
            DispatchQueue.main.async {
                pendingSmartStartDraft = nil
                dismissSmartStartNotice()
                if restored {
                    refreshApps(forceLayoutRefresh: true)
                }
            }
        }
    }

    private func dismissSmartStartNotice() {
        withAnimation(.easeOut(duration: 0.18)) {
            smartStartNotice = nil
        }
    }

    private var localizedListSeparator: String {
        switch L10n.currentCode {
        case "zh-Hans", "zh-Hant", "ja":
            return "、"
        case "ar", "ar-Najdi":
            return "، "
        default:
            return ", "
        }
    }

    // MARK: - Computed

    private var sortedTagNames: [String] {
        let filtered = tagColors.keys.filter { $0 != "Mac自带" && $0 != defaultGroupName }
        // Use user-defined order, fall back to alpha
        let ordered = draggedTagNames.filter { filtered.contains($0) }
        let remaining = filtered.filter { !ordered.contains($0) }.sorted()
        return ordered + remaining + [TagDatabase.uncommonTagKey]
    }

    private func displayTagName(_ tagName: String) -> String {
        tagName == TagDatabase.uncommonTagKey ? tr("group.uncommon") : tagName
    }

    private func makeDisplayGroups(apps: [AppInfo], tagOrder: [String]) -> [TagGroup] {
        let order = tagOrder.isEmpty ? TagEditor.orderedTagNames() : tagOrder
        let rawGroups = AppIndexer.group(apps: apps, defaultGroupName: defaultGroupName, tagOrder: order)
        return rawGroups.map { group in
            if group.name == defaultGroupName {
                return TagGroup(name: tr("group.uncategorized"), apps: group.apps)
            }
            if group.name == "Mac自带" {
                return TagGroup(name: tr("group.appleBuiltIn"), apps: group.apps)
            }
            return group
        }
    }

    private func rebuildDisplayGroups(apps: [AppInfo], tagOrder: [String]) {
        displayGroups = makeDisplayGroups(apps: apps, tagOrder: tagOrder)
        groupLayoutVersion &+= 1
    }

    private var tagLabels: [TagNavigationItem] {
        displayGroups.map { TagNavigationItem(name: $0.name, colorIndex: tagColors[$0.name] ?? 0) }
    }

    private var editGroups: [TagGroup] {
        displayGroups + [
            TagGroup(
                name: tr("group.uncommon"),
                apps: allApps.filter(\.isUncommon).sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
            )
        ]
    }

    // MARK: - Actions

    private func refreshAppsIfNeeded() {
        guard allApps.isEmpty, !refreshInProgress else { return }
        refreshApps()
    }

    private func refreshNotchHeight() {
        let mousePoint = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: {
            NSMouseInRect(mousePoint, $0.frame, false)
        }) ?? NSScreen.main
        notchHeight = activeScreen?.safeAreaInsets.top ?? 0
    }

    private func handleAppGridScrollActivity() {
        if appGridInteraction.hoveredBubble != nil {
            appGridInteraction.hoveredBubble = nil
        }
    }

    private func handleBubbleHover(app: AppInfo, frame: CGRect, event: AppBubbleHoverEvent) {
        guard !appBubbleDisabled else {
            clearAppBubbleState()
            return
        }
        guard appGridInteraction.editingBubble == nil else { return }
        switch event {
        case .entered(let canShowBubble):
            if canShowBubble {
                appGridInteraction.hoveredBubble = AppBubbleContext(app: app, frame: frame)
            } else {
                appGridInteraction.hoveredBubble = nil
            }
        case .exited:
            guard appGridInteraction.hoveredBubble?.app.path == app.path else { return }
            appGridInteraction.hoveredBubble = nil
        }
    }

    private func beginEditingBubbleNote(app: AppInfo, frame: CGRect) {
        guard !appBubbleDisabled else {
            clearAppBubbleState()
            return
        }
        appGridInteraction.bubbleDraftNote = currentNote(for: app)
        appGridInteraction.hoveredBubble = nil
        appGridInteraction.editingBubble = AppBubbleContext(app: app, frame: frame)
        notifyAppNoteEditing(active: true)
        DispatchQueue.main.async {
            bubbleNoteFocused = true
        }
    }

    private func commitBubbleNote() {
        guard let context = appGridInteraction.editingBubble else { return }
        let limited = String(appGridInteraction.bubbleDraftNote.prefix(TagDatabase.maxAppNoteLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        TagEditor.setAppNote(limited, for: context.app.path.path)
        appGridInteraction.bubbleDraftNote = limited
        appGridInteraction.editingBubble = nil
        bubbleNoteFocused = false
        notifyAppNoteEditing(active: false)
        refreshApps()
    }

    private func dismissAppBubble() {
        appGridInteraction.hoveredBubble = nil
        if appGridInteraction.editingBubble != nil {
            notifyAppNoteEditing(active: false)
        }
        appGridInteraction.editingBubble = nil
        bubbleNoteFocused = false
    }

    private func clearAppBubbleState() {
        if appGridInteraction.hoveredBubble != nil {
            appGridInteraction.hoveredBubble = nil
        }
        if appGridInteraction.editingBubble != nil {
            notifyAppNoteEditing(active: false)
            appGridInteraction.editingBubble = nil
        }
        if bubbleNoteFocused {
            bubbleNoteFocused = false
        }
    }

    private func notifyAppNoteEditing(active: Bool) {
        NotificationCenter.default.post(
            name: .tagLauncherAppNoteEditingChanged,
            object: nil,
            userInfo: ["active": active]
        )
    }

    private func currentNote(for app: AppInfo) -> String {
        if let latest = allApps.first(where: { $0.path == app.path })?.note {
            return latest
        }
        return app.note ?? ""
    }

    private func bubblePlacement(for frame: CGRect, rootFrame: CGRect) -> BubblePlacement {
        frame.minY < 170 ? .below : .above
    }

    private func bubbleMetrics(
        for context: AppBubbleContext,
        rootFrame: CGRect,
        rootSize: CGSize,
        width: CGFloat,
        placement: BubblePlacement,
        isEditing: Bool
    ) -> AppBubbleMetrics {
        let appCenterX = context.frame.midX
        let halfWidth = width / 2
        let centerX = min(max(appCenterX, halfWidth + 24), max(halfWidth + 24, rootSize.width - halfWidth - 24))
        let estimatedHeight = estimatedBubbleHeight(for: context.app, width: width, isEditing: isEditing)
        let gap: CGFloat = 16
        let topY: CGFloat
        if placement == .below {
            topY = context.frame.maxY + gap
        } else {
            topY = context.frame.minY - estimatedHeight - gap
        }
        let clampedTopY = min(max(topY, 14), max(14, rootSize.height - estimatedHeight - 14))
        let arrowX = min(max(appCenterX, centerX - halfWidth + 28), centerX + halfWidth - 28)
        return AppBubbleMetrics(
            centerX: centerX,
            centerY: clampedTopY + estimatedHeight / 2,
            arrowX: arrowX,
            arrowOffset: arrowX - centerX
        )
    }

    private func estimatedBubbleHeight(for app: AppInfo, width: CGFloat, isEditing: Bool) -> CGFloat {
        if isEditing {
            return 120
        }
        let note = currentNote(for: app).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return 68 }
        let contentWidth = max(160, width - 48)
        let approxCharsPerLine = max(16, Int(contentWidth / 14))
        let lines = min(4, max(1, Int(ceil(Double(note.count) / Double(approxCharsPerLine)))))
        return 70 + CGFloat(lines) * 20
    }

    func scrollTo(_ id: String) {
        appGridScrollTargetID = id
        appGridScrollRequestToken &+= 1
    }

    private func activateTagNavigation(_ id: String) {
        cancelTagNavReorderVisualState()
        if isColorlessContainerMode {
            toggleColorlessFill(id)
        }
        scrollTo(id)
    }

    private func handleTagNavigationHover(_ id: String, active: Bool) {
        guard active else {
            if appGridInteraction.tagNavigationHoveredGroupName == id {
                appGridInteraction.tagNavigationHoveredGroupName = nil
            }
            return
        }

        appGridInteraction.tagNavigationHoveredGroupName = id
        fillColorlessContainer(id)
        scrollToTagFromHover(id)
    }

    private func scrollToTagFromHover(_ id: String) {
        let now = Date()
        if appGridInteraction.tagNavigationLastHoverScrollID == id,
           let lastScrollAt = appGridInteraction.tagNavigationLastHoverScrollAt,
           now.timeIntervalSince(lastScrollAt) < tagNavigationHoverScrollInterval {
            return
        }
        appGridInteraction.tagNavigationLastHoverScrollID = id
        appGridInteraction.tagNavigationLastHoverScrollAt = now
        scrollTo(id)
    }

    private func fillColorlessContainer(_ id: String) {
        guard isColorlessContainerMode else { return }
        guard filledColorlessContainer != id else { return }
        filledColorlessContainer = id
    }

    private func toggleColorlessFill(_ id: String) {
        guard isColorlessContainerMode else { return }
        filledColorlessContainer = (filledColorlessContainer == id) ? nil : id
    }

    private func canReorderTag(_ name: String) -> Bool {
        tagColors[name] != nil && name != "Mac自带" && name != defaultGroupName
    }

    private func tagNavFrameReader(for tagName: String) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: TagNavReorderFramePreferenceKey.self,
                value: canReorderTag(tagName)
                    ? [tagName: proxy.frame(in: .named("tagNavReorder"))]
                    : [:]
            )
        }
    }

    private func tagNavReorderGesture(for tagName: String) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("tagNavReorder")))
            .onChanged { value in
                guard canReorderTag(tagName) else { return }
                switch value {
                case .second(true, let drag?):
                    if tagNavDragItem == nil {
                        beginTagNavReorder(tagName)
                    }
                    reorderTagNavItem(at: drag.location)
                default:
                    break
                }
            }
            .onEnded { value in
                guard canReorderTag(tagName) else { return }
                if case .second(true, let drag?) = value {
                    reorderTagNavItem(at: drag.location)
                }
                endTagNavReorder()
            }
    }

    private func beginTagNavReorder(_ tagName: String) {
        guard canReorderTag(tagName) else { return }
        if tagNavDragItem == nil {
            tagNavDragItem = tagName
            tagNavReorderDidMove = false
        }
        tagNavDragModeActive = true
    }

    private func endTagNavReorder() {
        let hadDragState = tagNavDragModeActive || tagNavDragItem != nil
        guard hadDragState else { return }
        if tagNavDragModeActive && tagNavReorderDidMove {
            TagEditor.reorderTags(draggedTagNames)
        }
        tagNavDragModeActive = false
        tagNavDragItem = nil
        tagNavReorderDidMove = false
    }

    private func cancelTagNavReorderVisualState() {
        guard tagNavDragModeActive || tagNavDragItem != nil else { return }
        tagNavDragModeActive = false
        tagNavDragItem = nil
        tagNavReorderDidMove = false
    }

    private func reorderTagNavItem(at location: CGPoint) {
        guard let fromName = tagNavDragItem,
              let targetName = tagNavReorderFrames.first(where: { $0.value.contains(location) })?.key,
              fromName != targetName
        else { return }
        reorderTagNavItem(fromName: fromName, to: targetName)
    }

    private func reorderTagNavItem(fromName: String, to targetName: String) {
        guard fromName != targetName,
              canReorderTag(fromName),
              canReorderTag(targetName),
              let fromIndex = draggedTagNames.firstIndex(of: fromName),
              let toIndex = draggedTagNames.firstIndex(of: targetName)
        else { return }
        tagNavReorderDidMove = true
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            let destination = toIndex > fromIndex ? toIndex + 1 : toIndex
            draggedTagNames.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: destination)
        }
    }

    private func dropApp(path: String, sourceTag: String, targetTag: String, copy: Bool) {
        resetTransientDragState(keepingPendingUncategorizedDrop: true)

        if isUncategorizedDropTarget(targetTag) {
            confirmAndMoveAppToUncategorized(path: path)
            return
        }

        guard !isAppleBuiltInDropTarget(targetTag) else {
            showDropWarning()
            return
        }

        guard tagColors[targetTag] != nil else { return }
        guard sourceTag != targetTag || copy else { return }
        TagEditor.moveApp(
            path: path,
            from: sourceTag,
            to: targetTag,
            color: tagColors[targetTag] ?? 0,
            copy: copy
        )
        showDropRefresh()
        refreshApps(forceLayoutRefresh: true)
    }

    private func dropAppOutsideGroup(path: String, sourceTag: String, copy: Bool) {
        resetTransientDragState(keepingPendingTagRemovalDrop: true)
        guard isRemovableRegularTag(sourceTag) else { return }
        guard let app = allApps.first(where: { $0.path.path == path }),
              appHasTag(app, tagName: sourceTag)
        else { return }

        if skipTagRemovalDropConfirm {
            removeTagFromDroppedApp(app: app, tagName: sourceTag)
            return
        }

        clearAppBubbleState()
        appGridInteraction.tagRemovalDropSuppressFuturePrompt = false
        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
            appGridInteraction.pendingTagRemovalDrop = PendingTagRemovalDrop(app: app, tagName: sourceTag)
        }
    }

    private func confirmAndMoveAppToUncategorized(path: String) {
        guard let app = allApps.first(where: { $0.path.path == path }) else { return }
        let removableTags = removableRegularTags(for: app)
        guard !removableTags.isEmpty else { return }
        let assignedTags = assignedRegularDisplayTags(for: removableTags)

        if skipUncategorizedDropConfirm {
            moveDroppedAppToUncategorized(path: app.path.path, tags: removableTags)
            return
        }

        clearAppBubbleState()
        appGridInteraction.uncategorizedDropSuppressFuturePrompt = false
        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
            appGridInteraction.pendingUncategorizedDrop = PendingUncategorizedDrop(
                app: app,
                assignedTags: assignedTags,
                removableTags: removableTags
            )
        }
    }

    private func removableRegularTags(for app: AppInfo) -> [String] {
        var result: [String] = []
        for tag in app.tags {
            guard isRemovableRegularTag(tag) else { continue }
            if !result.contains(tag) {
                result.append(tag)
            }
        }
        return result
    }

    private func assignedRegularDisplayTags(for tags: [String]) -> [String] {
        var result: [String] = []
        for tag in tags {
            let name = displayTagName(tag)
            if !result.contains(name) {
                result.append(name)
            }
        }
        return result
    }

    private func uncategorizedConfirmMessage(for pendingDrop: PendingUncategorizedDrop) -> String {
        formattedFeedbackMessage(
            forKey: "drop.uncategorizedConfirmMessage",
            replacements: [
                "%appName%": pendingDrop.app.displayName,
                "%tagCount%": "\(pendingDrop.assignedTags.count)",
                "%tagNames%": pendingDrop.assignedTags.joined(separator: localizedListSeparator)
            ]
        )
    }

    private func tagRemovalConfirmMessage(for pendingDrop: PendingTagRemovalDrop) -> String {
        formattedFeedbackMessage(
            forKey: "drop.removeTagConfirmMessage",
            replacements: [
                "%appName%": pendingDrop.app.displayName,
                "%tagName%": displayTagName(pendingDrop.tagName)
            ]
        )
    }

    private func dismissUncategorizedDropConfirm() {
        appGridInteraction.uncategorizedDropSuppressFuturePrompt = false
        resetTransientDragState(keepingPendingUncategorizedDrop: true)
        withAnimation(.easeOut(duration: 0.18)) {
            appGridInteraction.pendingUncategorizedDrop = nil
        }
    }

    private func confirmPendingUncategorizedDrop() {
        guard let pendingDrop = appGridInteraction.pendingUncategorizedDrop else { return }
        let path = pendingDrop.app.path.path
        let tags = pendingDrop.removableTags
        let shouldSuppressFuturePrompt = appGridInteraction.uncategorizedDropSuppressFuturePrompt
        if shouldSuppressFuturePrompt {
            skipUncategorizedDropConfirm = true
        }
        appGridInteraction.uncategorizedDropSuppressFuturePrompt = false
        resetTransientDragState(keepingPendingUncategorizedDrop: true)
        withAnimation(.easeOut(duration: 0.16)) {
            appGridInteraction.pendingUncategorizedDrop = nil
        }
        moveDroppedAppToUncategorized(path: path, tags: tags)
    }

    private func moveDroppedAppToUncategorized(path: String, tags: [String]) {
        guard !tags.isEmpty else { return }
        TagEditor.removeTags(tags, from: [path])
        showDropRefresh()
        refreshApps(forceLayoutRefresh: true)
    }

    private func dismissTagRemovalDropConfirm() {
        appGridInteraction.tagRemovalDropSuppressFuturePrompt = false
        withAnimation(.easeOut(duration: 0.18)) {
            appGridInteraction.pendingTagRemovalDrop = nil
        }
    }

    private func confirmPendingTagRemovalDrop() {
        guard let pendingDrop = appGridInteraction.pendingTagRemovalDrop else { return }
        let app = pendingDrop.app
        let tagName = pendingDrop.tagName
        let shouldSuppressFuturePrompt = appGridInteraction.tagRemovalDropSuppressFuturePrompt
        if shouldSuppressFuturePrompt {
            skipTagRemovalDropConfirm = true
        }
        appGridInteraction.tagRemovalDropSuppressFuturePrompt = false
        withAnimation(.easeOut(duration: 0.16)) {
            appGridInteraction.pendingTagRemovalDrop = nil
        }
        DispatchQueue.main.async {
            removeTagFromDroppedApp(app: app, tagName: tagName)
        }
    }

    private func removeTagFromDroppedApp(app: AppInfo, tagName: String) {
        guard isRemovableRegularTag(tagName),
              appHasTag(app, tagName: tagName)
        else { return }
        TagEditor.removeTags([tagName], from: [app.path.path])
        showDropRefresh()
        refreshApps(forceLayoutRefresh: true)
    }

    private func isUncategorizedDropTarget(_ targetTag: String) -> Bool {
        let defaultNames = [
            defaultGroupName,
            tr("group.uncategorized")
        ]
        return defaultNames.contains(targetTag)
    }

    private func isAppleBuiltInDropTarget(_ targetTag: String) -> Bool {
        let defaultNames = [
            "Mac自带",
            tr("group.appleBuiltIn")
        ]
        return defaultNames.contains(targetTag)
    }

    private func isRemovableRegularTag(_ tag: String) -> Bool {
        let protectedNames = [
            "Mac自带",
            tr("group.appleBuiltIn"),
            defaultGroupName,
            tr("group.uncategorized"),
            TagDatabase.uncommonTagKey,
            tr("group.uncommon")
        ]
        return !protectedNames.contains(tag) && tagColors[tag] != nil
    }

    private func showDropWarning() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            appGridInteraction.dropWarningToast = tr("drop.systemDefaultWarning")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.18)) {
                appGridInteraction.dropWarningToast = nil
            }
        }
    }

    private func showDropRefresh() {
        appGridInteraction.dropRefreshStartedAt = Date()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            appGridInteraction.dropRefreshVisible = true
        }
    }

    private func finishDropRefreshAfterMinimumDuration() {
        let minimumDuration: TimeInterval = 0.85
        let elapsed = appGridInteraction.dropRefreshStartedAt.map { Date().timeIntervalSince($0) } ?? minimumDuration
        let delay = max(0, minimumDuration - elapsed)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.18)) {
                appGridInteraction.dropRefreshVisible = false
            }
            appGridInteraction.dropRefreshStartedAt = nil
        }
    }

    private func setAppDragMode(_ active: Bool) {
        guard appGridInteraction.appDragModeActive != active else { return }
        if active {
            endTagNavReorder()
            clearAppBubbleState()
        }
        appGridInteraction.appDragModeActive = active
        if active {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if appGridInteraction.appDragModeActive && !AppDragCoordinator.shared.hasActiveDrag {
                    appGridInteraction.appDragModeActive = false
                }
            }
        }
    }

    private func resetTransientDragState(
        keepingPendingUncategorizedDrop: Bool = false,
        keepingPendingTagRemovalDrop: Bool = false
    ) {
        let hadAppDragState = appGridInteraction.appDragModeActive
        AppDragCoordinator.shared.cancelDrag()
        if appGridInteraction.appDragModeActive {
            appGridInteraction.appDragModeActive = false
        }
        if hadAppDragState {
            appGridInteraction.appDragResetToken &+= 1
        }
        if tagNavDragModeActive {
            tagNavDragModeActive = false
        }
        if tagNavDragItem != nil {
            tagNavDragItem = nil
        }
        if tagNavReorderDidMove {
            tagNavReorderDidMove = false
        }
        if dragItem != nil {
            dragItem = nil
        }
        clearAppBubbleState()
        if !keepingPendingUncategorizedDrop, appGridInteraction.pendingUncategorizedDrop != nil {
            appGridInteraction.pendingUncategorizedDrop = nil
        }
        if !keepingPendingTagRemovalDrop, appGridInteraction.pendingTagRemovalDrop != nil {
            appGridInteraction.pendingTagRemovalDrop = nil
        }
    }

    func refreshApps(forceLayoutRefresh: Bool = false) {
        guard !refreshInProgress else {
            if forceLayoutRefresh {
                refreshAgainAfterCurrent = true
                refreshAgainForceLayout = true
            }
            return
        }

        refreshInProgress = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = AppLibraryController.refresh()
            DispatchQueue.main.async {
                applyAppLibrarySnapshot(result.snapshot)
                handleSmartStartRunResult(result.smartStartResult)
                if forceLayoutRefresh {
                    finishDropRefreshAfterMinimumDuration()
                }
                refreshInProgress = false
                if refreshAgainAfterCurrent {
                    let shouldForceLayout = refreshAgainForceLayout
                    refreshAgainAfterCurrent = false
                    refreshAgainForceLayout = false
                    refreshApps(forceLayoutRefresh: shouldForceLayout)
                }
            }
        }
    }

    private func applyAppLibrarySnapshot(_ snapshot: AppLibrarySnapshot) {
        allApps = snapshot.apps
        quickSearchDocuments = snapshot.quickSearchDocuments
        tagColors = snapshot.tagColors
        draggedTagNames = snapshot.tagOrder
        rebuildDisplayGroups(apps: snapshot.apps, tagOrder: snapshot.tagOrder)
        if quickSearchVisible {
            refreshQuickSearchResults()
        }
    }

    private func launchApp(
        _ app: AppInfo,
        closeQuickSearchOnSuccess: Bool = false,
        closeOverlayOnSuccess: Bool = true,
        onFailure: (() -> Void)? = nil
    ) {
        appGridInteraction.appDragModeActive = false
        endTagNavReorder()
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: app.path, configuration: configuration) { _, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    onFailure?()
                    return
                }

                DispatchQueue.global(qos: .utility).async {
                    TagEditor.recordLauncherOpen(for: app.path.path)
                }
                if closeQuickSearchOnSuccess {
                    closeQuickSearch(hideOverlayIfNeeded: false)
                }
                if closeOverlayOnSuccess {
                    hideOverlay()
                }
            }
        }
    }

    func openApp(_ app: AppInfo) {
        hideOverlay()
        launchApp(app, closeOverlayOnSuccess: false)
    }
}

// MARK: - Tag Label

private struct TagReorderFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct TagNavReorderFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - NSVisualEffectView bridge

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
