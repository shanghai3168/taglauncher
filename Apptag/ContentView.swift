import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Notification for manual re-index

extension Notification.Name {
    static let tagLauncherEditModeChanged = Notification.Name("TagLauncherEditModeChanged")
}

// MARK: - Edit Phase

enum EditPhase {
    case none
    case editingTags
    case editingApps
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

// MARK: - Tag Pill (for top navigation bar)

struct TagPill: View {
    let name: String
    let colorIndex: Int
    var dragModeActive: Bool = false
    var isDragging: Bool = false
    let action: () -> Void
    @State private var wiggle = false

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
            .rotationEffect(.degrees(dragModeActive ? (wiggle ? 1.8 : -1.8) : 0))
            .animation(
                dragModeActive
                    ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                    : .default,
                value: wiggle
            )
            .onChange(of: dragModeActive) { _, active in
                wiggle = active
            }
            .contentShape(RoundedRectangle(cornerRadius: 7))
            .onTapGesture {
                if !dragModeActive { action() }
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
    @State private var wiggle = false

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
            .rotationEffect(.degrees(dragModeActive ? (wiggle ? 1.6 : -1.6) : 0))
            .animation(
                dragModeActive
                    ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                    : .default,
                value: wiggle
            )
            .onChange(of: dragModeActive) { _, active in
                wiggle = active
            }
            .contentShape(RoundedRectangle(cornerRadius: 6))
            .onTapGesture {
                if !dragModeActive { action() }
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

struct ContentView: View {
    let hideOverlay: () -> Void

    @State private var allApps: [AppInfo] = []
    @State private var tagColors: [String: Int] = [:]
    @State private var scrollProxy: ScrollViewProxy? = nil

    // Edit mode
    @State private var editPhase: EditPhase = .none
    @State private var selectedAppPaths: Set<URL> = []
    @State private var selectedTagNames: Set<String> = []
    @State private var successToast: String? = nil
    @State private var draggedTagNames: [String] = []  // live drag order
    @State private var dragItem: String? = nil          // currently dragged tag
    @State private var tagReorderFrames: [String: CGRect] = [:]
    @State private var tagNavDragModeActive = false
    @State private var tagNavDragItem: String? = nil
    @State private var tagNavDismissMonitor: Any? = nil
    @State private var tagNavReorderFrames: [String: CGRect] = [:]
    @State private var hoveredContainer: String? = nil  // colored container lift
    // Fixed interaction for "Colorless Container": hover fills persistently; click clears.
    @State private var filledColorlessContainer: String? = nil
    @State private var appDragModeActive = false
    @State private var dropWarningToast: String? = nil
    @State private var dropRefreshVisible = false
    @State private var dropRefreshStartedAt: Date? = nil
    @State private var layoutRefreshID = UUID()

    // Configurable defaults
    @AppStorage("defaultGroupName") private var defaultGroupName = "Other"
    @AppStorage("tagFontSize") private var tagFontSize: Double = 18
    @AppStorage("iconSize") private var iconSize: Double = 56
    @AppStorage("tagPosition") private var tagPosition = "left"
    @State private var notchHeight: CGFloat = 0
    @AppStorage("displayMode") private var displayMode = "flat"
    @AppStorage("hideAppNames") private var hideAppNames = false

    private var isSideLayout: Bool {
        tagPosition == "left" || tagPosition == "right"
    }

    private var isColorlessContainerMode: Bool {
        displayMode == "container" || displayMode == "gridContainer"
    }

    private var isColoredContainerMode: Bool {
        displayMode == "coloredContainer" || displayMode == "coloredGridContainer"
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
                .allowsHitTesting(false)

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

            if let message = dropWarningToast {
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

            if dropRefreshVisible {
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
            let mousePoint = NSEvent.mouseLocation
            let activeScreen = NSScreen.screens.first(where: {
                NSMouseInRect(mousePoint, $0.frame, false)
            }) ?? NSScreen.main
            notchHeight = activeScreen?.safeAreaInsets.top ?? 0
            refreshApps()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshApps()
        }
        .onChange(of: editPhase) { _, newPhase in
            let active = newPhase != .none
            NotificationCenter.default.post(
                name: .tagLauncherEditModeChanged,
                object: nil,
                userInfo: ["active": active]
            )
        }
        .onChange(of: tagNavDragModeActive) { _, active in
            updateTagNavDismissMonitor(active: active)
        }
        .onDisappear {
            removeTagNavDismissMonitor()
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
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .tagLauncherEditModeChanged, object: nil, userInfo: ["active": false])
            }
        }
    }

    // MARK: - Normal Content

    private var normalContent: some View {
        ZStack(alignment: .topTrailing) {
            if isSideLayout {
                sideLayout
            } else {
                topLayout
            }

            if tagNavDragModeActive && tagNavDragItem == nil {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        endTagNavReorder()
                    }
                    .zIndex(1)
            }

            Button {
                setEditPhase(.editingApps)
            } label: {
                Image(systemName: "pencil.line")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
            .padding(.top, notchHeight > 0 ? notchHeight + 10 : 20)
            .padding(.trailing, 20)
            .keyboardShortcut("e", modifiers: .control)
            .zIndex(2)
        }
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
                if tagPosition == "right" { sideDivider; tagSidebar }
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
                            action: {
                        if isColorlessContainerMode {
                            toggleColorlessFill(tag.id)
                        }
                        scrollTo(tag.id)
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
            .padding(.horizontal, 24)
            .coordinateSpace(name: "tagNavReorder")
            .onPreferenceChange(TagNavReorderFramePreferenceKey.self) { frames in
                tagNavReorderFrames = frames
            }
        }
    }

    private var tagSidebar: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(tagLabels) { tag in
                    SideTagPill(name: tag.name, colorIndex: tag.colorIndex,
                                dragModeActive: tagNavDragModeActive && canReorderTag(tag.name),
                                isDragging: tagNavDragItem == tag.name,
                                action: {
                        if isColorlessContainerMode {
                            toggleColorlessFill(tag.id)
                        }
                        scrollTo(tag.id)
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
        }.frame(width: 135)
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
        .id(layoutRefreshID)
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
                radius: (isColored && isHovered) || isColorlessActive ? 18 : 0,
                y: (isColored && isHovered) || isColorlessActive ? 10 : 0)
        .scaleEffect(isColored && isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isColorlessFilled)
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
                radius: (isColored && isHovered) || isColorlessGridActive ? 18 : 0,
                y: (isColored && isHovered) || isColorlessGridActive ? 10 : 0)
        .scaleEffect(isColored && isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isColorlessFilled)
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
            HStack {
                Button { cancelEditApps(); setEditPhase(.none) } label: {
                    Label(tr("edit.exit"), systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                Spacer()
                Text(tr("edit.title")).font(.headline)
                Spacer()
                Button(tr("edit.confirm")) { confirmAssign() }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedAppPaths.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, notchHeight > 0 ? notchHeight + 10 : 20)
            .padding(.bottom, 12)

            Divider().opacity(0.3)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr("edit.selectTags")).font(.caption).foregroundStyle(.secondary).padding(.bottom, 4)
                    Text(tr("edit.dragHint")).font(.caption2).foregroundStyle(.tertiary).padding(.bottom, 2)
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
                    .frame(width: 155)
                }
                Rectangle().fill(.secondary.opacity(0.12)).frame(width: 1)

                if allApps.isEmpty {
                    Spacer(); ProgressView().scaleEffect(0.8); Spacer()
                } else {
                    editAppsGrid
                }
            }

            if let msg = successToast {
                Text(msg).font(.headline)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThickMaterial))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { successToast = nil }
                        }
                    }
            }
        }
    }

    private var editAppsGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(groups) { group in
                    editFlatGroup(group)
                }
            }
            .padding(20)
        }
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
        }
    }

    private func selectableTagItem(_ tagName: String) -> some View {
        let isSelected = selectedTagNames.contains(tagName)
        return HStack(spacing: 6) {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 16, height: 16)
                .overlay(isSelected ? Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundStyle(.white) : nil)
            Text(tagName).font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6)
            .fill(Color(nsColor: TagColor.nsColor(for: tagColors[tagName] ?? 0).withAlphaComponent(0.3))))
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture {
            if isSelected { selectedTagNames.remove(tagName) } else { selectedTagNames.insert(tagName) }
        }
    }

    private func tagReorderGesture(for tagName: String) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("tagReorderList"))
            .onChanged { value in
                if dragItem == nil {
                    dragItem = tagName
                }
                guard dragItem == tagName else { return }
                reorderDraggedTag(at: value.location)
            }
            .onEnded { _ in
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
        TagEditor.reorderTags(draggedTagNames)
    }

    private func confirmAssign() {
        guard !selectedAppPaths.isEmpty else { return }
        let paths = selectedAppPaths.map { $0.path }
        let tags = sortedTagNames.filter { selectedTagNames.contains($0) }
        TagEditor.setTags(tags, to: paths)
        selectedAppPaths = []; selectedTagNames = []
        refreshApps()
        withAnimation { successToast = tr("edit.success") }
    }

    private func cancelEditApps() {
        selectedAppPaths = []; selectedTagNames = []
    }

    private func editableAppItem(_ app: AppInfo) -> some View {
        let isSelected = selectedAppPaths.contains(app.path)
        return Button {
            toggleEditableAppSelection(app)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: app.icon).resizable().aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(isSelected ? Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white) : nil)
                        .offset(x: 6, y: -6)
                }
                Text(app.name).font(.system(size: 11, weight: .medium)).lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: iconSize + 20)
            }
            .padding(.vertical, 8).padding(.horizontal, 4)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .opacity(isSelected ? 1.0 : 0.65)
        }
        .buttonStyle(.plain)
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
        let selectedApps = allApps.filter { selectedAppPaths.contains($0.path) }
        guard !selectedApps.isEmpty else {
            selectedTagNames = []
            return
        }

        let editableTags = Set(sortedTagNames)
        if selectedApps.count == 1 {
            selectedTagNames = Set(selectedApps[0].tags.filter { editableTags.contains($0) })
            return
        }

        selectedTagNames = selectedApps.reduce(into: Set<String>()) { result, app in
            result.formUnion(app.tags.filter { editableTags.contains($0) })
        }
    }

    // MARK: - Computed

    private var sortedTagNames: [String] {
        let filtered = tagColors.keys.filter { $0 != "Mac自带" && $0 != defaultGroupName }
        // Use user-defined order, fall back to alpha
        let ordered = draggedTagNames.filter { filtered.contains($0) }
        let remaining = filtered.filter { !ordered.contains($0) }.sorted()
        return ordered + remaining
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

    // MARK: - Actions

    func scrollTo(_ id: String) {
        withAnimation(.easeInOut(duration: 0.25)) { scrollProxy?.scrollTo(id, anchor: .top) }
    }

    private func fillColorlessContainer(_ id: String) {
        guard isColorlessContainerMode else { return }
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
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(minimumDistance: 3, coordinateSpace: .named("tagNavReorder")))
            .onChanged { value in
                guard canReorderTag(tagName) else { return }
                switch value {
                case .first(true):
                    beginTagNavReorder(tagName)
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
        }
        tagNavDragModeActive = true
    }

    private func endTagNavReorder() {
        if tagNavDragModeActive {
            TagEditor.reorderTags(draggedTagNames)
        }
        tagNavDragModeActive = false
        tagNavDragItem = nil
        removeTagNavDismissMonitor()
    }

    private func updateTagNavDismissMonitor(active: Bool) {
        if active {
            guard tagNavDismissMonitor == nil else { return }
            tagNavDismissMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                guard tagNavDragModeActive, editPhase == .none else { return event }
                endTagNavReorder()
                return nil
            }
        } else {
            removeTagNavDismissMonitor()
        }
    }

    private func removeTagNavDismissMonitor() {
        if let monitor = tagNavDismissMonitor {
            NSEvent.removeMonitor(monitor)
            tagNavDismissMonitor = nil
        }
    }

    private func reorderTagNavItem(at location: CGPoint) {
        guard let fromName = tagNavDragItem,
              let targetName = tagNavReorderFrames.first(where: { $0.value.contains(location) })?.key,
              fromName != targetName,
              let fromIndex = draggedTagNames.firstIndex(of: fromName),
              let toIndex = draggedTagNames.firstIndex(of: targetName)
        else { return }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            let destination = toIndex > fromIndex ? toIndex + 1 : toIndex
            draggedTagNames.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: destination)
        }
        TagEditor.reorderTags(draggedTagNames)
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
        appDragModeActive = false
        guard !isSystemDefaultDropTarget(targetTag) else {
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

    private func isSystemDefaultDropTarget(_ targetTag: String) -> Bool {
        let defaultNames = [
            defaultGroupName,
            tr("group.uncategorized"),
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

    func refreshApps(forceLayoutRefresh: Bool = false) {
        DispatchQueue.global(qos: .userInitiated).async {
            var apps = AppIndexer.scan()
            let store = TagDatabase.load()
            apps = TagEditor.annotate(apps: apps)
            let colors = store.tags.mapValues { $0.color }
            let order = TagEditor.orderedTagNames()
            DispatchQueue.main.async {
                allApps = apps
                tagColors = colors
                draggedTagNames = order
                if forceLayoutRefresh {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        layoutRefreshID = UUID()
                    }
                    finishDropRefreshAfterMinimumDuration()
                }
            }
        }
    }

    func openApp(_ app: AppInfo) {
        appDragModeActive = false
        endTagNavReorder()
        hideOverlay()
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: app.path, configuration: configuration)
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
