import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
    var dragResetToken: Int = 0
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
            .id("\(name)|reset-\(dragResetToken)")
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
    var dragResetToken: Int = 0
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
            .id("\(name)|reset-\(dragResetToken)")
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

private struct EditActionFeedback: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct PendingUncategorizedDrop: Identifiable {
    let id = UUID()
    let app: AppInfo
    let assignedTags: [String]
}

private enum SmartStartNoticeMode {
    case autoApplied
    case suggestionOnly
    case manuallyApplied
}

private struct SmartStartNotice: Identifiable {
    let id = UUID()
    let mode: SmartStartNoticeMode
    let title: String
    let message: String
    let summary: SmartStartSummary
}

struct ContentView: View {
    let hideOverlay: () -> Void
    private let initialQuickSearchSource: String?

    @State private var allApps: [AppInfo] = []
    @State private var tagColors: [String: Int] = [:]
    @State private var scrollProxy: ScrollViewProxy? = nil

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
    @State private var tagNavDragResetToken = 0
    @State private var tagNavReorderFrames: [String: CGRect] = [:]
    @State private var tagNavReorderDidMove = false
    @State private var hoveredContainer: String? = nil  // colored container lift
    // Fixed interaction for "Colorless Container": hover fills persistently; click clears.
    @State private var filledColorlessContainer: String? = nil
    @State private var appDragModeActive = false
    @State private var dropWarningToast: String? = nil
    @State private var smartStartNotice: SmartStartNotice? = nil
    @State private var pendingSmartStartDraft: SmartCategorizationDraft? = nil
    @State private var dropRefreshVisible = false
    @State private var dropRefreshStartedAt: Date? = nil
    @State private var refreshInProgress = false
    @State private var refreshAgainAfterCurrent = false
    @State private var refreshAgainForceLayout = false
    @State private var hoveredAppItemID: String? = nil
    @State private var hoveredBubble: AppBubbleContext? = nil
    @State private var editingBubble: AppBubbleContext? = nil
    @State private var pendingUncategorizedDrop: PendingUncategorizedDrop? = nil
    @State private var appDragResetToken = 0
    @State private var bubbleDraftNote = ""
    @FocusState private var bubbleNoteFocused: Bool

    // Quick Search
    @State private var quickSearchVisible = false
    @State private var quickSearchQuery = ""
    @State private var quickSearchDocuments: [QuickSearchDocument] = []
    @State private var quickSearchResults: [QuickSearchResult] = []
    @State private var quickSearchSelectedID: URL? = nil
    @State private var quickSearchManualSelection = false
    @State private var quickSearchFocusToken = 0
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

    private let editSidebarWidth: CGFloat = 188
    private let editSidebarHorizontalInset: CGFloat = 12
    private let floatingControlsTrailingInset: CGFloat = 20
    private let floatingControlsReservedWidth: CGFloat = 120
    private var appBubbleDisabled: Bool {
        appDragModeActive || pendingUncategorizedDrop != nil
    }
    private let rightSidebarFloatingClearance: CGFloat = 44

    private var isSideLayout: Bool {
        tagPosition == "left" || tagPosition == "right"
    }

    private var floatingControlsTopInset: CGFloat {
        notchHeight > 0 ? notchHeight + 10 : 20
    }

    private var isColorlessContainerMode: Bool {
        displayMode == "container" || displayMode == "gridContainer"
    }

    private var isColoredContainerMode: Bool {
        displayMode == "coloredContainer" || displayMode == "coloredGridContainer"
    }

    private var quickSearchOnlyMode: Bool {
        quickSearchVisible && quickSearchCloseHidesOverlay
    }

    var body: some View {
        ZStack {
            if !quickSearchOnlyMode {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if !quickSearchOnlyMode {
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
            }

            quickSearchOverlay

            if !quickSearchOnlyMode, let message = dropWarningToast {
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

            if !quickSearchOnlyMode && dropRefreshVisible {
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
            refreshApps()
            if let initialQuickSearchSource, !initialQuickSearchConsumed {
                initialQuickSearchConsumed = true
                quickSearchCloseHidesOverlay = initialQuickSearchSource == QuickSearchOpenSource.globalHidden
                quickSearchVisible = true
                quickSearchFocusToken &+= 1
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
            refreshApps()
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
            if editingBubble != nil && !focused {
                commitBubbleNote()
            }
        }
        .onChange(of: quickSearchQuery) { _, _ in
            quickSearchErrorMessage = nil
            refreshQuickSearchResults()
        }
        .onChange(of: pendingUncategorizedDrop != nil) { _, active in
            NotificationCenter.default.post(
                name: .tagLauncherModalInteractionChanged,
                object: nil,
                userInfo: ["active": active]
            )
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .tagLauncherModalInteractionChanged,
                object: nil,
                userInfo: ["active": false]
            )
        }
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
                QuickSearchBackdropClickView {
                    closeQuickSearch()
                }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .ignoresSafeArea()
                    .zIndex(899)

                QuickSearchOverlayView(
                    query: $quickSearchQuery,
                    results: quickSearchResults,
                    selectedID: quickSearchSelectedID,
                    focusToken: quickSearchFocusToken,
                    isLoading: quickSearchDocuments.isEmpty && refreshInProgress,
                    maxVisibleRows: quickSearchMaxVisibleRows(in: proxy.size),
                    errorMessage: quickSearchErrorMessage,
                    onCommand: handleQuickSearchCommand,
                    onHover: selectQuickSearchResult,
                    onLaunch: launchQuickSearchResult
                )
                .position(
                    x: proxy.size.width / 2,
                    y: quickSearchPanelCenterY(in: proxy.size)
                )
                .transition(.scale(scale: 0.98).combined(with: .opacity))
                .zIndex(900)
            }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.12), value: quickSearchVisible)
    }

    private func quickSearchPanelCenterY(in size: CGSize) -> CGFloat {
        let visibleRows = max(1, min(quickSearchResults.isEmpty ? 1 : quickSearchResults.count, quickSearchMaxVisibleRows(in: size)))
        let estimatedPanelHeight = CGFloat(visibleRows) * 76 + 122
        return quickSearchPanelTopY(in: size) + estimatedPanelHeight / 2
    }

    private func quickSearchPanelTopY(in size: CGSize) -> CGFloat {
        max(notchHeight + 54, min(112, size.height * 0.12))
    }

    private func quickSearchMaxVisibleRows(in size: CGSize) -> Int {
        let bottomClearance: CGFloat = 84
        let chromeHeight: CGFloat = 122
        let rowHeightWithSpacing: CGFloat = 76
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
            && pendingUncategorizedDrop == nil
            && smartStartNotice == nil
            && !dropRefreshVisible
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
    }

    private func selectQuickSearchResult(_ result: QuickSearchResult) {
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
            .background(Circle().fill(.ultraThinMaterial))
    }

    // MARK: - Top / Side Layouts

    private var topLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: notchHeight > 0 ? notchHeight + 14 : 28)
            if !tagLabels.isEmpty { tagBar.padding(.bottom, 8) }
            Divider().opacity(0.3)
            appGridContent
        }
    }

    private var sideLayout: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: notchHeight > 0 ? notchHeight + 14 : 28)
            Divider().opacity(0.3)
            HStack(spacing: 0) {
                if tagPosition == "left" { tagSidebar; sideDivider }
                appGridContent
                if tagPosition == "right" { sideDivider; rightTagSidebar }
            }
        }
    }

    private var tagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tagLabels) { tag in
                    TagPill(name: tag.name, colorIndex: tag.colorIndex,
                            dragModeActive: tagNavDragModeActive && canReorderTag(tag.name),
                            isDragging: tagNavDragItem == tag.name,
                            dragResetToken: tagNavDragResetToken,
                            action: {
                        activateTagNavigation(tag.id)
                    })
                    .background(tagNavFrameReader(for: tag.name))
                    .zIndex(tagNavDragItem == tag.name ? 1 : 0)
                    .highPriorityGesture(tagNavReorderGesture(for: tag.name))
                    .onHover { hovering in
                        if hovering {
                            fillColorlessContainer(tag.id)
                            scrollTo(tag.id)
                        }
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

    private var tagSidebar: some View {
        tagSidebarList
            .frame(width: 135)
    }

    private var rightTagSidebar: some View {
        tagSidebarList
            .padding(.top, rightSidebarFloatingClearance)
            .frame(width: 135)
    }

    private var tagSidebarList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(tagLabels) { tag in
                    SideTagPill(name: tag.name, colorIndex: tag.colorIndex,
                                dragModeActive: tagNavDragModeActive && canReorderTag(tag.name),
                                isDragging: tagNavDragItem == tag.name,
                                dragResetToken: tagNavDragResetToken,
                                action: {
                        activateTagNavigation(tag.id)
                    })
                    .background(tagNavFrameReader(for: tag.name))
                    .zIndex(tagNavDragItem == tag.name ? 1 : 0)
                    .highPriorityGesture(tagNavReorderGesture(for: tag.name))
                    .onHover { hovering in
                        if hovering {
                            fillColorlessContainer(tag.id)
                            scrollTo(tag.id)
                        }
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
            } else if displayMode == "gridContainer" || displayMode == "coloredGridContainer" {
                gridContainerGrid
            } else if displayMode == "container" || displayMode == "coloredContainer" {
                containerGrid
            } else {
                flatGrid
            }
        }
    }

    private var uncommonAppBubbleOverlay: some View {
        GeometryReader { proxy in
            if let context = editingBubble ?? hoveredBubble {
                let rootFrame = proxy.frame(in: .global)
                let editing = editingBubble != nil
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
                    appName: context.app.name,
                    note: currentNote(for: context.app),
                    isEditing: editing,
                    placement: placement,
                    arrowOffset: metrics.arrowOffset,
                    draftNote: $bubbleDraftNote,
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
        .allowsHitTesting(editingBubble != nil)
    }

    private var smartStartNoticeOverlay: some View {
        GeometryReader { proxy in
            if let notice = smartStartNotice {
                let panelWidth = min(560, max(320, proxy.size.width - 64))

                ZStack {
                    Color.black.opacity(0.10)
                        .ignoresSafeArea()

                    VStack(spacing: 18) {
                        Image(systemName: notice.mode == .suggestionOnly ? "sparkles" : "checkmark.seal.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 58, height: 58)
                            .background(
                                Circle()
                                    .fill(Color.accentColor.opacity(0.12))
                            )

                        VStack(spacing: 8) {
                            Text(notice.title)
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)

                            Text(notice.message)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 12) {
                            switch notice.mode {
                            case .suggestionOnly:
                                Button(tr("smartstart.later")) {
                                    dismissSmartStartNotice()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)

                                Button(tr("smartstart.apply")) {
                                    applySmartStartSuggestion()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            case .autoApplied, .manuallyApplied:
                                if notice.summary.backupPath != nil {
                                    Button(tr("smartstart.undo")) {
                                        undoSmartStart()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                                }
                                Button(tr("smartstart.ok")) {
                                    dismissSmartStartNotice()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 26)
                    .frame(width: panelWidth)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThickMaterial)
                            .shadow(color: .black.opacity(0.26), radius: 28, y: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .zIndex(650)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(smartStartNotice != nil)
    }
    private var flatGrid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(groups) { group in
                        TagGroupView(
                            group: group,
                            onSelectApp: { app in openApp(app) },
                            tagFontSize: tagFontSize,
                            iconSize: iconSize,
                            showNames: !hideAppNames,
                            dragModeActive: appDragModeActive,
                            onDragModeChange: { setAppDragMode($0) },
                            onBubbleHover: handleBubbleHover,
                            onEditNote: beginEditingBubbleNote,
                            bubbleDisabled: appBubbleDisabled,
                            dragResetToken: appDragResetToken,
                            hoveredAppItemID: $hoveredAppItemID,
                            onDropApp: { path, source, copy in
                                dropApp(path: path, sourceTag: source, targetTag: group.name, copy: copy)
                            }
                        ).id(group.id)
                    }
                }.padding(20)
            }
            .id(displayMode)  // force rebuild on mode switch
            .onAppear { scrollProxy = proxy }
        }
    }

    private var containerGrid: some View {
        GeometryReader { geo in
            let outerPad: CGFloat = 20
            let gap: CGFloat = 16
            let available = geo.size.width - outerPad * 2
            let colW: CGFloat = 280
            let colCount = max(1, Int((available + gap) / (colW + gap)))
            let actualColW = (available - gap * CGFloat(colCount - 1)) / CGFloat(colCount)

            let columns = distributeToColumns(groups: groups, colCount: colCount, colWidth: actualColW)

            ScrollViewReader { proxy in
                ScrollView {
                    HStack(alignment: .top, spacing: gap) {
                        ForEach(0..<colCount, id: \.self) { ci in
                            LazyVStack(spacing: gap) {
                                ForEach(columns[ci]) { group in
                                    masonryCard(group, width: actualColW)
                                        .id(group.id)
                                }
                            }
                        }
                    }
                    .padding(outerPad)
                }
                .id(displayMode)  // force rebuild on mode switch
                .onAppear { scrollProxy = proxy }
            }
        }
    }

    /// Distribute groups to the shortest column.
    private func distributeToColumns(groups: [TagGroup], colCount: Int, colWidth: CGFloat) -> [[TagGroup]] {
        var cols = Array(repeating: [TagGroup](), count: colCount)
        var h = Array(repeating: CGFloat(0), count: colCount)
        for g in groups {
            let est = estimatedCardHeight(g, width: colWidth)
            let ci = h.firstIndex(of: h.min()!)!
            cols[ci].append(g)
            h[ci] += est + 16
        }
        return cols
    }

    private func estimatedCardHeight(_ group: TagGroup, width: CGFloat) -> CGFloat {
        let inner = width - 32
        let itemW = AppGridItem.stableWidth(iconSize: iconSize) + 6
        let perRow = max(1, Int(inner / itemW))
        let rows = (group.apps.count + perRow - 1) / perRow
        return 32
            + CGFloat(rows) * AppGridItem.stableHeight(iconSize: iconSize)
            + CGFloat(max(0, rows - 1)) * 2
    }

    private func masonryCard(_ group: TagGroup, width: CGFloat) -> some View {
        let isColored = displayMode == "coloredContainer"
        let isColorless = isColorlessContainerMode
        let isColorlessFilled = isColorless && filledColorlessContainer == group.name
        let isHovered = hoveredContainer == group.name
        let isColorlessActive = isColorless && (isColorlessFilled || isHovered)
        let tagColor = Color(nsColor: TagColor.nsColor(for: tagColors[group.name] ?? 0))
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
                    .layoutPriority(0)
                Text(group.name)
                    .font(.system(size: tagFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 10)
                    .layoutPriority(1)
                Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
                    .layoutPriority(0)
            }
            let itemSize = AppGridItem.stableWidth(iconSize: iconSize)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: itemSize, maximum: itemSize + 36), spacing: 6)],
                spacing: 2
            ) {
                ForEach(group.apps) { app in
                    AppGridItem(
                        app: app,
                        iconSize: iconSize,
                        showName: !hideAppNames,
                        sourceTag: group.name,
                        dragModeActive: appDragModeActive,
                        onDragModeChange: { setAppDragMode($0) },
                        onBubbleHover: handleBubbleHover,
                        onEditNote: beginEditingBubbleNote,
                        bubbleDisabled: appBubbleDisabled,
                        itemID: "\(group.name)|\(app.path.path)",
                        dragResetToken: appDragResetToken,
                        hoveredAppItemID: $hoveredAppItemID,
                        onSelect: { openApp(app) }
                    )
                }
            }
        }
        .frame(maxWidth: width)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill((isColored || isColorlessActive) ? tagColor.opacity(0.30) : Color.clear)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .overlay {
            AppDropTargetView(targetTag: group.name) { path, source, copy in
                dropApp(path: path, sourceTag: source, targetTag: group.name, copy: copy)
            }
            .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity((isColored && isHovered) || isColorlessActive ? 0.22 : 0),
                radius: (isColored && isHovered) || isColorlessActive ? 8 : 0,
                y: (isColored && isHovered) || isColorlessActive ? 3 : 0)
        .zIndex(isHovered ? 50 : 0)
        .animation(.easeOut(duration: 0.045), value: isHovered)
        .animation(.easeOut(duration: 0.08), value: isColorlessFilled)
        .onHover { hovering in
            if isColored || isColorless {
                hoveredContainer = hovering ? group.name : nil
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            if isColorless {
                toggleColorlessFill(group.name)
            }
        }
        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
            handleAppDrop(providers, targetTag: group.name)
        }
    }

    private var gridContainerGrid: some View {
        GeometryReader { geo in
            let outerPad: CGFloat = 20
            let gap: CGFloat = 16
            let available = geo.size.width - outerPad * 2
            let preferredCount = preferredGridContainersPerRow(availableWidth: available)
            let rows = gridContainerRows(groups: groups, trackCount: preferredCount, availableWidth: available, gap: gap)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: gap) {
                        ForEach(Array(rows.indices), id: \.self) { rowIndex in
                            let row = rows[rowIndex]

                            HStack(alignment: .top, spacing: gap) {
                                ForEach(Array(row.items.indices), id: \.self) { itemIndex in
                                    let item = row.items[itemIndex]
                                    gridContainerCard(item.group, width: item.width, fixedRows: row.fixedRows)
                                        .id(item.group.id)
                                }
                            }
                        }
                    }
                    .padding(outerPad)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .id(displayMode)
                .onAppear { scrollProxy = proxy }
            }
        }
    }

    private func preferredGridContainersPerRow(availableWidth: CGFloat) -> Int {
        let minCardWidth = max(260, AppGridItem.stableWidth(iconSize: iconSize) * 3 + 64)
        if availableWidth >= minCardWidth * 3 + 32 { return 3 }
        if availableWidth >= minCardWidth * 2 + 16 { return 2 }
        return 1
    }

    private struct GridContainerLayoutItem {
        let group: TagGroup
        let width: CGFloat
    }

    private struct GridContainerLayoutRow {
        let items: [GridContainerLayoutItem]
        let fixedRows: Int
    }

    private struct GridContainerCandidate {
        let spans: [Int]
        let rows: Int
        let cost: CGFloat
    }

    private func gridContainerRows(groups: [TagGroup], trackCount: Int, availableWidth: CGFloat, gap: CGFloat) -> [GridContainerLayoutRow] {
        let trackCount = max(1, trackCount)
        let trackWidth = (availableWidth - gap * CGFloat(trackCount - 1)) / CGFloat(trackCount)
        let patterns = gridContainerSpanPatterns(trackCount: trackCount)
        let n = groups.count
        guard n > 0 else { return [] }

        var bestCost = Array(repeating: CGFloat.greatestFiniteMagnitude, count: n + 1)
        var bestPattern = Array(repeating: [Int](), count: n)
        bestCost[n] = 0

        for index in stride(from: n - 1, through: 0, by: -1) {
            for pattern in patterns where index + pattern.count <= n {
                let candidate = gridContainerCandidate(
                    groups: groups,
                    startIndex: index,
                    spans: pattern,
                    trackWidth: trackWidth,
                    availableWidth: availableWidth,
                    gap: gap
                )
                let totalCost = candidate.cost + bestCost[index + pattern.count]
                if totalCost < bestCost[index] {
                    bestCost[index] = totalCost
                    bestPattern[index] = candidate.spans
                }
            }
        }

        var rows: [GridContainerLayoutRow] = []
        var index = 0
        while index < n {
            let spans = bestPattern[index].isEmpty ? [trackCount] : bestPattern[index]
            let widths = spans.map { gridContainerWidth(trackWidth: trackWidth, span: $0, gap: gap) }
            let fixedRows = widths.indices.map {
                iconRows(appCount: groups[index + $0].apps.count, width: widths[$0])
            }.max() ?? 1
            let items = widths.indices.map {
                GridContainerLayoutItem(group: groups[index + $0], width: widths[$0])
            }
            rows.append(GridContainerLayoutRow(items: items, fixedRows: fixedRows))
            index += spans.count
        }
        return rows
    }

    private func gridContainerSpanPatterns(trackCount: Int) -> [[Int]] {
        switch trackCount {
        case 3:
            return [[1, 1, 1], [1, 2], [2, 1], [3]]
        case 2:
            return [[1, 1], [2]]
        default:
            return [[1]]
        }
    }

    private func gridContainerCandidate(
        groups: [TagGroup],
        startIndex: Int,
        spans: [Int],
        trackWidth: CGFloat,
        availableWidth: CGFloat,
        gap: CGFloat
    ) -> GridContainerCandidate {
        let widths = spans.map { gridContainerWidth(trackWidth: trackWidth, span: $0, gap: gap) }
        let rowCounts = widths.indices.map {
            iconRows(appCount: groups[startIndex + $0].apps.count, width: widths[$0])
        }
        let fixedRows = rowCounts.max() ?? 1
        let rowArea = CGFloat(fixedRows) * iconCellHeight() * availableWidth
        let paddingCost = CGFloat(spans.count) * 0.001
        return GridContainerCandidate(spans: spans, rows: fixedRows, cost: rowArea + paddingCost)
    }

    private func gridContainerWidth(trackWidth: CGFloat, span: Int, gap: CGFloat) -> CGFloat {
        let span = max(1, span)
        return trackWidth * CGFloat(span) + gap * CGFloat(span - 1)
    }

    private func iconColumns(width: CGFloat) -> Int {
        let inner = width - 32
        let itemW = AppGridItem.stableWidth(iconSize: iconSize) + 6
        return max(1, Int((inner + 6) / itemW))
    }

    private func iconRows(appCount: Int, width: CGFloat) -> Int {
        let cols = iconColumns(width: width)
        return max(1, (appCount + cols - 1) / cols)
    }

    private func gridContainerCard(_ group: TagGroup, width: CGFloat, fixedRows: Int) -> some View {
        let isColored = displayMode == "coloredGridContainer"
        let isColorlessGrid = displayMode == "gridContainer"
        let isColorless = isColorlessContainerMode
        let isColorlessFilled = isColorless && filledColorlessContainer == group.name
        let isHovered = hoveredContainer == group.name
        let isColorlessGridActive = isColorlessGrid && (isColorlessFilled || isHovered)
        let cols = iconColumns(width: width)
        let contentWidth = max(1, width - 32)
        let cellWidth = max(1, (contentWidth - 6 * CGFloat(cols - 1)) / CGFloat(cols))
        let cellHeight = iconCellHeight()
        let gridHeight = CGFloat(fixedRows) * cellHeight + CGFloat(max(0, fixedRows - 1)) * 2
        let rows = appRows(group.apps, columns: cols, fixedRows: fixedRows)
        let tagColor = Color(nsColor: TagColor.nsColor(for: tagColors[group.name] ?? 0))

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
                    .layoutPriority(0)
                Text(group.name)
                    .font(.system(size: tagFontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 10)
                    .layoutPriority(1)
                Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
                    .layoutPriority(0)
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(alignment: .top, spacing: 6) {
                        ForEach(rows[rowIndex]) { app in
                            AppGridItem(
                                app: app,
                                iconSize: iconSize,
                                showName: !hideAppNames,
                                sourceTag: group.name,
                                dragModeActive: appDragModeActive,
                                onDragModeChange: { setAppDragMode($0) },
                                onBubbleHover: handleBubbleHover,
                                onEditNote: beginEditingBubbleNote,
                                bubbleDisabled: appBubbleDisabled,
                                itemID: "\(group.name)|\(app.path.path)",
                                dragResetToken: appDragResetToken,
                                hoveredAppItemID: $hoveredAppItemID,
                                onSelect: { openApp(app) }
                            )
                                .frame(width: cellWidth)
                                .frame(height: cellHeight)
                        }

                        let emptyCells = max(0, cols - rows[rowIndex].count)
                        ForEach(0..<emptyCells, id: \.self) { _ in
                            Color.clear
                                .frame(width: cellWidth, height: cellHeight)
                        }
                    }
                    .frame(height: cellHeight)
                }
            }
            .frame(height: gridHeight, alignment: .topLeading)
        }
        .frame(width: contentWidth)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill((isColored || isColorlessGridActive) ? tagColor.opacity(0.30) : Color.clear)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .overlay {
            AppDropTargetView(targetTag: group.name) { path, source, copy in
                dropApp(path: path, sourceTag: source, targetTag: group.name, copy: copy)
            }
            .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity((isColored && isHovered) || isColorlessGridActive ? 0.22 : 0),
                radius: (isColored && isHovered) || isColorlessGridActive ? 8 : 0,
                y: (isColored && isHovered) || isColorlessGridActive ? 3 : 0)
        .zIndex(isHovered ? 50 : 0)
        .animation(.easeOut(duration: 0.045), value: isHovered)
        .animation(.easeOut(duration: 0.08), value: isColorlessFilled)
        .onHover { hovering in
            if isColored || isColorlessGrid {
                hoveredContainer = hovering ? group.name : nil
            } else if hovering {
                fillColorlessContainer(group.name)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            if isColorlessGrid {
                toggleColorlessFill(group.name)
            }
        }
        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
            handleAppDrop(providers, targetTag: group.name)
        }
    }

    private func iconCellHeight() -> CGFloat {
        AppGridItem.stableHeight(iconSize: iconSize)
    }

    private func appRows(_ apps: [AppInfo], columns: Int, fixedRows: Int) -> [[AppInfo]] {
        let columns = max(1, columns)
        let rowCount = max(1, fixedRows)
        return (0..<rowCount).map { rowIndex in
            let start = rowIndex * columns
            guard start < apps.count else { return [] }
            let end = min(start + columns, apps.count)
            return Array(apps[start..<end])
        }
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
                            minimum: AppGridItem.stableWidth(iconSize: iconSize),
                            maximum: AppGridItem.stableWidth(iconSize: iconSize) + 36
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
            if let pendingDrop = pendingUncategorizedDrop {
                ZStack {
                    Color.black.opacity(0.14)
                        .ignoresSafeArea()

                    UncategorizedDropConfirmBubble(
                        title: tr("drop.uncategorizedConfirmTitle"),
                        message: uncategorizedConfirmMessage(for: pendingDrop),
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
        .allowsHitTesting(pendingUncategorizedDrop != nil)
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
            let result = SmartStartService.applySuggestion(draft)
            let store = result.store
            let apps = TagEditor.annotate(apps: scannedApps, store: store)
            let colors = store.tags.mapValues { $0.color }
            let order = TagEditor.orderedTagNames()

            DispatchQueue.main.async {
                pendingSmartStartDraft = nil
                allApps = apps
                tagColors = colors
                draggedTagNames = order
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

    private var tagLabels: [TagLabel] {
        groups.map { TagLabel(name: $0.name, colorIndex: tagColors[$0.name] ?? 0) }
    }

    private var groups: [TagGroup] {
        let order = draggedTagNames.isEmpty
            ? TagEditor.orderedTagNames()
            : draggedTagNames
        let raw = AppIndexer.group(apps: allApps, defaultGroupName: defaultGroupName, tagOrder: order)
        // Translate stable keys for display
        return raw.map { group in
            if group.name == defaultGroupName {
                return TagGroup(name: tr("group.uncategorized"), apps: group.apps)
            }
            if group.name == "Mac自带" {
                return TagGroup(name: tr("group.appleBuiltIn"), apps: group.apps)
            }
            return group
        }
    }

    private var editGroups: [TagGroup] {
        groups + [
            TagGroup(
                name: tr("group.uncommon"),
                apps: allApps.filter(\.isUncommon).sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
            )
        ]
    }

    // MARK: - Actions

    private func refreshNotchHeight() {
        let mousePoint = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first(where: {
            NSMouseInRect(mousePoint, $0.frame, false)
        }) ?? NSScreen.main
        notchHeight = activeScreen?.safeAreaInsets.top ?? 0
    }

    private func handleBubbleHover(app: AppInfo, frame: CGRect, event: AppBubbleHoverEvent) {
        guard !appBubbleDisabled else {
            clearAppBubbleState()
            return
        }
        guard editingBubble == nil else { return }
        switch event {
        case .entered(let canShowBubble):
            if canShowBubble {
                hoveredBubble = AppBubbleContext(app: app, frame: frame)
            } else {
                hoveredBubble = nil
            }
        case .exited:
            guard hoveredBubble?.app.path == app.path else { return }
            hoveredBubble = nil
        }
    }

    private func beginEditingBubbleNote(app: AppInfo, frame: CGRect) {
        guard !appBubbleDisabled else {
            clearAppBubbleState()
            return
        }
        bubbleDraftNote = currentNote(for: app)
        hoveredBubble = nil
        editingBubble = AppBubbleContext(app: app, frame: frame)
        notifyAppNoteEditing(active: true)
        DispatchQueue.main.async {
            bubbleNoteFocused = true
        }
    }

    private func commitBubbleNote() {
        guard let context = editingBubble else { return }
        let limited = String(bubbleDraftNote.prefix(TagDatabase.maxAppNoteLength))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        TagEditor.setAppNote(limited, for: context.app.path.path)
        bubbleDraftNote = limited
        editingBubble = nil
        bubbleNoteFocused = false
        notifyAppNoteEditing(active: false)
        refreshApps()
    }

    private func dismissAppBubble() {
        hoveredBubble = nil
        if editingBubble != nil {
            notifyAppNoteEditing(active: false)
        }
        editingBubble = nil
        bubbleNoteFocused = false
    }

    private func clearAppBubbleState() {
        hoveredAppItemID = nil
        hoveredBubble = nil
        if editingBubble != nil {
            notifyAppNoteEditing(active: false)
        }
        editingBubble = nil
        bubbleNoteFocused = false
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
        withAnimation(.easeInOut(duration: 0.25)) { scrollProxy?.scrollTo(id, anchor: .top) }
    }

    private func activateTagNavigation(_ id: String) {
        cancelTagNavReorderVisualState()
        if isColorlessContainerMode {
            toggleColorlessFill(id)
        }
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
        if tagNavDragModeActive && tagNavReorderDidMove {
            TagEditor.reorderTags(draggedTagNames)
        }
        tagNavDragModeActive = false
        tagNavDragItem = nil
        tagNavReorderDidMove = false
        tagNavDragResetToken &+= 1
    }

    private func cancelTagNavReorderVisualState() {
        guard tagNavDragModeActive || tagNavDragItem != nil else { return }
        tagNavDragModeActive = false
        tagNavDragItem = nil
        tagNavReorderDidMove = false
        tagNavDragResetToken &+= 1
    }

    private func reorderTagNavItem(at location: CGPoint) {
        guard let fromName = tagNavDragItem,
              let targetName = tagNavReorderFrames.first(where: { $0.value.contains(location) })?.key,
              fromName != targetName,
              let fromIndex = draggedTagNames.firstIndex(of: fromName),
              let toIndex = draggedTagNames.firstIndex(of: targetName)
        else { return }

        tagNavReorderDidMove = true
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            let destination = toIndex > fromIndex ? toIndex + 1 : toIndex
            draggedTagNames.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: destination)
        }
    }

    private func handleAppDrop(_ providers: [NSItemProvider], targetTag: String) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) else {
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
            let text: String?
            if let data = item as? Data {
                text = String(data: data, encoding: .utf8)
            } else if let string = item as? String {
                text = string
            } else if let string = item as? NSString {
                text = string as String
            } else {
                text = nil
            }
            guard let text else { return }
            let parts = text.components(separatedBy: "\n")
            guard let path = parts.first, !path.isEmpty else { return }
            let source = parts.dropFirst().first ?? ""
            let copy = NSEvent.modifierFlags.contains(.option)
            DispatchQueue.main.async {
                dropApp(path: path, sourceTag: source, targetTag: targetTag, copy: copy)
            }
        }
        return true
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

    private func confirmAndMoveAppToUncategorized(path: String) {
        guard let app = allApps.first(where: { $0.path.path == path }) else { return }
        let assignedTags = assignedRegularDisplayTags(for: app)
        guard !assignedTags.isEmpty else { return }

        clearAppBubbleState()
        withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
            pendingUncategorizedDrop = PendingUncategorizedDrop(app: app, assignedTags: assignedTags)
        }
    }

    private func assignedRegularDisplayTags(for app: AppInfo) -> [String] {
        var result: [String] = []
        for tag in app.tags {
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
                "%appName%": pendingDrop.app.name,
                "%tagCount%": "\(pendingDrop.assignedTags.count)",
                "%tagNames%": pendingDrop.assignedTags.joined(separator: localizedListSeparator)
            ]
        )
    }

    private func dismissUncategorizedDropConfirm() {
        resetTransientDragState(keepingPendingUncategorizedDrop: true)
        withAnimation(.easeOut(duration: 0.18)) {
            pendingUncategorizedDrop = nil
        }
    }

    private func confirmPendingUncategorizedDrop() {
        guard let pendingDrop = pendingUncategorizedDrop else { return }
        let path = pendingDrop.app.path.path
        let tags = pendingDrop.app.tags
        resetTransientDragState(keepingPendingUncategorizedDrop: true)
        withAnimation(.easeOut(duration: 0.16)) {
            pendingUncategorizedDrop = nil
        }
        TagEditor.removeTags(tags, from: [path])
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

    private func showDropWarning() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
            dropWarningToast = tr("drop.systemDefaultWarning")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.18)) {
                dropWarningToast = nil
            }
        }
    }

    private func showDropRefresh() {
        dropRefreshStartedAt = Date()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            dropRefreshVisible = true
        }
    }

    private func finishDropRefreshAfterMinimumDuration() {
        let minimumDuration: TimeInterval = 0.85
        let elapsed = dropRefreshStartedAt.map { Date().timeIntervalSince($0) } ?? minimumDuration
        let delay = max(0, minimumDuration - elapsed)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.18)) {
                dropRefreshVisible = false
            }
            dropRefreshStartedAt = nil
        }
    }

    private func setAppDragMode(_ active: Bool) {
        if active {
            endTagNavReorder()
            clearAppBubbleState()
        }
        appDragModeActive = active
        if active {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                if appDragModeActive {
                    appDragModeActive = false
                }
            }
        }
    }

    private func resetTransientDragState(keepingPendingUncategorizedDrop: Bool = false) {
        AppDragCoordinator.shared.cancelDrag()
        appDragModeActive = false
        appDragResetToken &+= 1
        tagNavDragModeActive = false
        tagNavDragItem = nil
        tagNavReorderDidMove = false
        tagNavDragResetToken &+= 1
        dragItem = nil
        hoveredAppItemID = nil
        hoveredContainer = nil
        clearAppBubbleState()
        if !keepingPendingUncategorizedDrop {
            pendingUncategorizedDrop = nil
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
            let scannedApps = AppIndexer.scan()
            let reconciledStore = TagEditor.reconcileScannedApps(scannedApps)
            let smartStartResult = SmartStartService.runIfNeeded(
                apps: scannedApps,
                store: reconciledStore
            )
            let store = smartStartResult.store
            let apps = TagEditor.annotate(apps: scannedApps, store: store)
            let quickSearchDocs = QuickSearchEngine.makeDocuments(apps: apps, store: store)
            let colors = store.tags.mapValues { $0.color }
            let order = TagEditor.orderedTagNames()
            DispatchQueue.main.async {
                allApps = apps
                quickSearchDocuments = quickSearchDocs
                tagColors = colors
                draggedTagNames = order
                if quickSearchVisible {
                    refreshQuickSearchResults()
                }
                handleSmartStartRunResult(smartStartResult)
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

    private func launchApp(
        _ app: AppInfo,
        closeQuickSearchOnSuccess: Bool = false,
        closeOverlayOnSuccess: Bool = true,
        onFailure: (() -> Void)? = nil
    ) {
        appDragModeActive = false
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
        launchApp(app)
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

private struct TagLabel: Identifiable {
    var id: String { name }
    let name: String
    let colorIndex: Int
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
