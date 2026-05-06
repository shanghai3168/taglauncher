import SwiftUI
import AppKit

// MARK: - Notification for manual re-index

extension Notification.Name {
    static let apptagReindex = Notification.Name("ApptagReindex")
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

    // Configurable defaults
    @AppStorage("defaultGroupName") private var defaultGroupName = "Other"
    @AppStorage("tagFontSize") private var tagFontSize: Double = 18
    @AppStorage("iconSize") private var iconSize: Double = 56
    @AppStorage("tagPosition") private var tagPosition = "left"
    @State private var notchHeight: CGFloat = 0

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
        .onReceive(NotificationCenter.default.publisher(for: .apptagReindex)) { _ in
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
            // Re-activate to ensure overlay window stays key during view transition
            NSApp.activate(ignoringOtherApps: true)
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
                            action: { scrollTo(tag.id) })
                }
            }.padding(.horizontal, 24)
        }
    }

    private var tagSidebar: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(tagLabels) { tag in
                    SideTagPill(name: tag.name, colorIndex: tag.colorIndex,
                                action: { scrollTo(tag.id) })
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
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(groups) { group in
                                TagGroupView(
                                    group: group,
                                    onSelectApp: { app in openApp(app) },
                                    tagFontSize: tagFontSize,
                                    iconSize: iconSize
                                ).id(group.id)
                            }
                        }.padding(20)
                    }.onAppear { scrollProxy = proxy }
                }
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
                    Label("Exit editing", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                Spacer()
                Text("Edit Tags").font(.headline)
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
                    Label("Exit editing", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                Spacer()
                Text("Edit App Categories").font(.headline)
                Spacer()
                Button("Confirm") { confirmAssign() }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedAppPaths.isEmpty || selectedTagNames.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, notchHeight > 0 ? notchHeight + 10 : 20)
            .padding(.bottom, 12)

            Divider().opacity(0.3)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select tags:").font(.caption).foregroundStyle(.secondary).padding(.bottom, 4)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
                            ForEach(sortedTagNames, id: \.self) { tagName in
                                selectableTagItem(tagName)
                            }
                        }.padding(12)
                    }.frame(width: 145)
                }
                Rectangle().fill(.secondary.opacity(0.12)).frame(width: 1)

                if allApps.isEmpty {
                    Spacer(); ProgressView().scaleEffect(0.8); Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(groups) { group in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 0) {
                                        Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
                                        Text(group.name).font(.system(size: tagFontSize, weight: .semibold))
                                            .foregroundStyle(.secondary).padding(.horizontal, 10)
                                        Rectangle().fill(.secondary.opacity(0.25)).frame(height: 1)
                                    }
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: iconSize + 28, maximum: iconSize + 64), spacing: 6)], spacing: 2) {
                                        ForEach(group.apps) { app in editableAppItem(app) }
                                    }
                                }
                            }
                        }.padding(20)
                    }
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

    private func selectableTagItem(_ tagName: String) -> some View {
        let isSelected = selectedTagNames.contains(tagName)
        return Button {
            if isSelected { selectedTagNames.remove(tagName) } else { selectedTagNames.insert(tagName) }
        } label: {
            HStack(spacing: 6) {
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
        }
        .buttonStyle(.plain)
    }

    private func confirmAssign() {
        guard !selectedAppPaths.isEmpty, !selectedTagNames.isEmpty else { return }
        let paths = selectedAppPaths.map { $0.path }
        for tagName in selectedTagNames {
            TagEditor.assignTag(tagName, color: tagColors[tagName] ?? 0, to: paths)
        }
        selectedAppPaths = []; selectedTagNames = []
        refreshApps()
        withAnimation { successToast = "分类成功" }
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
        tagColors.keys
            .filter { $0 != "Mac自带" && $0 != defaultGroupName }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var tagLabels: [TagLabel] {
        groups.map { TagLabel(name: $0.name, colorIndex: tagColors[$0.name] ?? 0) }
    }

    private var groups: [TagGroup] {
        AppIndexer.group(apps: allApps, defaultGroupName: defaultGroupName)
    }

    // MARK: - Actions

    func scrollTo(_ id: String) {
        withAnimation(.easeInOut(duration: 0.25)) { scrollProxy?.scrollTo(id, anchor: .top) }
    }

    func refreshApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var apps = AppIndexer.scan()
            // Ensure migration ran at least once
            let store = TagDatabase.migrateFromFinderIfNeeded(apps: apps)
            apps = TagEditor.annotate(apps: apps)
            let colors = store.tags.mapValues { $0.color }
            DispatchQueue.main.async {
                allApps = apps
                tagColors = colors
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
