import SwiftUI
import AppKit

// MARK: - Notification for manual re-index

extension Notification.Name {
    static let apptagEditModeChanged = Notification.Name("ApptagEditModeChanged")
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
        Button(action: action) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 7).fill(bgColor))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Side Tag Pill

struct SideTagPill: View {
    let name: String
    let colorIndex: Int
    let action: () -> Void

    private var bgColor: Color {
        Color(nsColor: TagColor.nsColor(for: colorIndex))
    }
    private var textColor: Color {
        colorIndex == 0 || colorIndex == 5 ? .primary : .white
    }

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(bgColor))
                .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
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
    @State private var hoveredContainer: String? = nil  // colored container lift
    // Fixed interaction for "Colorless Container": hover fills persistently; click clears.
    @State private var filledColorlessContainer: String? = nil

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
                name: .apptagEditModeChanged,
                object: nil,
                userInfo: ["active": active]
            )
        }
    }

    /// Set edit phase with synchronous notification BEFORE state change.
    func setEditPhase(_ phase: EditPhase) {
        if phase != .none {
            NotificationCenter.default.post(name: .apptagEditModeChanged, object: nil, userInfo: ["active": true])
            NSApp.activate(ignoringOtherApps: true)
            // Always sync tag list from database when entering edit mode
            let store = TagDatabase.load()
            tagColors = store.tags.mapValues { $0.color }
            draggedTagNames = TagEditor.orderedTagNames()
        }
        editPhase = phase
        if phase == .none {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .apptagEditModeChanged, object: nil, userInfo: ["active": false])
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
                            action: {
                        if displayMode == "container" {
                            toggleColorlessFill(tag.id)
                        }
                        scrollTo(tag.id)
                    })
                    .onHover { hovering in
                        if hovering {
                            fillColorlessContainer(tag.id)
                            scrollTo(tag.id)
                        }
                    }
                }
            }.padding(.horizontal, 24)
        }
    }

    private var tagSidebar: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(tagLabels) { tag in
                    SideTagPill(name: tag.name, colorIndex: tag.colorIndex,
                                action: {
                        if displayMode == "container" {
                            toggleColorlessFill(tag.id)
                        }
                        scrollTo(tag.id)
                    })
                    .onHover { hovering in
                        if hovering {
                            fillColorlessContainer(tag.id)
                            scrollTo(tag.id)
                        }
                    }
                }
            }.padding(12)
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
            } else if displayMode == "container" || displayMode == "coloredContainer" {
                containerGrid
            } else {
                flatGrid
            }
        }
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
                            showNames: !hideAppNames
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
        let itemW = iconSize + 28 + 6
        let perRow = max(1, Int(inner / itemW))
        let rows = (group.apps.count + perRow - 1) / perRow
        return 32 + CGFloat(rows) * (iconSize + 30)
    }

    private func masonryCard(_ group: TagGroup, width: CGFloat) -> some View {
        let isColored = displayMode == "coloredContainer"
        let isColorless = displayMode == "container"
        let isColorlessFilled = isColorless && filledColorlessContainer == group.name
        let isHovered = hoveredContainer == group.name
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
            let itemSize = iconSize + 28
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: itemSize, maximum: itemSize + 36), spacing: 6)],
                spacing: 2
            ) {
                ForEach(group.apps) { app in
                    AppGridItem(app: app, iconSize: iconSize, showName: !hideAppNames, onSelect: { openApp(app) })
                }
            }
        }
        .frame(maxWidth: width)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill((isColored || isColorlessFilled) ? tagColor.opacity(0.30) : Color.clear)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isColored && isHovered ? 0.22 : 0),
                radius: isColored && isHovered ? 18 : 0,
                y: isColored && isHovered ? 10 : 0)
        .scaleEffect(isColored && isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isHovered)
        .onHover { hovering in
            if isColored {
                hoveredContainer = hovering ? group.name : nil
            } else if hovering {
                fillColorlessContainer(group.name)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            if isColorlessFilled {
                filledColorlessContainer = nil
            }
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
                    .disabled(selectedAppPaths.isEmpty || selectedTagNames.isEmpty)
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
                                    .onDrag {
                                        dragItem = tagName
                                        return NSItemProvider(object: tagName as NSString)
                                    }
                                    .onDrop(of: [.text], isTargeted: nil) { providers, _ in
                                        guard let fromName = dragItem,
                                              var names = draggedTagNames as [String]?,
                                              let fromIdx = names.firstIndex(of: fromName),
                                              let toIdx = names.firstIndex(of: tagName),
                                              fromIdx != toIdx
                                        else { return false }
                                        let toOffset = toIdx > fromIdx ? toIdx + 1 : toIdx
                                        names.move(fromOffsets: [fromIdx], toOffset: toOffset)
                                        draggedTagNames = names
                                        TagEditor.reorderTags(names)
                                        dragItem = nil
                                        return true
                                    }
                            }
                        }.padding(12)
                    }.frame(width: 155)
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
        GeometryReader { geo in
            let outerPad: CGFloat = 20
            let gap: CGFloat = 16
            let available = geo.size.width - outerPad * 2
            let colW: CGFloat = 300
            let colCount = max(1, Int((available + gap) / (colW + gap)))
            let actualColW = (available - gap * CGFloat(colCount - 1)) / CGFloat(colCount)
            let columns = distributeToColumns(groups: groups, colCount: colCount, colWidth: actualColW)

            ScrollView {
                HStack(alignment: .top, spacing: gap) {
                    ForEach(0..<colCount, id: \.self) { ci in
                        LazyVStack(spacing: gap) {
                            ForEach(columns[ci]) { group in
                                editGroupCard(group, width: actualColW)
                            }
                        }
                    }
                }
                .padding(outerPad)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func editGroupCard(_ group: TagGroup, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
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
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: iconSize + 28, maximum: iconSize + 64), spacing: 6)],
                spacing: 2
            ) {
                ForEach(group.apps) { app in editableAppItem(app) }
            }
        }
        .frame(maxWidth: width)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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

    private func confirmAssign() {
        guard !selectedAppPaths.isEmpty, !selectedTagNames.isEmpty else { return }
        let paths = selectedAppPaths.map { $0.path }
        for tagName in selectedTagNames {
            TagEditor.assignTag(tagName, color: tagColors[tagName] ?? 0, to: paths)
        }
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
            if isSelected { selectedAppPaths.remove(app.path) } else { selectedAppPaths.insert(app.path) }
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
        guard displayMode == "container" else { return }
        filledColorlessContainer = id
    }

    private func toggleColorlessFill(_ id: String) {
        guard displayMode == "container" else { return }
        filledColorlessContainer = (filledColorlessContainer == id) ? nil : id
    }

    func refreshApps() {
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
            }
        }
    }

    func openApp(_ app: AppInfo) {
        hideOverlay()
        NSWorkspace.shared.open(app.path)
    }
}

// MARK: - Tag Label

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
