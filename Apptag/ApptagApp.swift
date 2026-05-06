import SwiftUI
import AppKit
import Carbon

// MARK: - Application Entry Point

@main
struct ApptagApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}

// MARK: - App Delegate (menubar + overlay window + hotkey)

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var overlayWindow: NSWindow?
    private var hotkeyRef: EventHotKeyRef?
    private var isInEditMode = false  // Suppress auto-dismiss during editing

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Use .accessory so the app appears in Force Quit (unlike LSUIElement)
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        registerHotkey()
        observeOtherWindows()
        observeEditMode()
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "tag.fill",
                accessibilityDescription: "Apptag"
            )
            button.toolTip = "Apptag — Tag-based app launcher"
            button.action = #selector(toggleOverlay)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "Show Apptag",
                action: #selector(toggleOverlay),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())

        // Version display
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let versionItem = NSMenuItem(
            title: "Version \(appVersion) (\(buildNumber))",
            action: nil,
            keyEquivalent: ""
        )
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        menu.addItem(.separator())
        let prefsItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.keyEquivalentModifierMask = .command
        menu.addItem(prefsItem)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        statusItem.menu = menu
    }

    // MARK: - Overlay Window

    @objc private func toggleOverlay() {
        if overlayWindow?.isVisible == true {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    private func showOverlay() {
        if overlayWindow == nil {
            // Use the screen under the mouse cursor — works in fullscreen spaces
            let mousePoint = NSEvent.mouseLocation
            guard let screen = NSScreen.screens.first(where: {
                NSMouseInRect(mousePoint, $0.frame, false)
            }) ?? NSScreen.main ?? NSScreen.screens.first else { return }

            overlayWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            overlayWindow?.level = .floating
            overlayWindow?.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .ignoresCycle
            ]
            overlayWindow?.isOpaque = false
            overlayWindow?.backgroundColor = .clear
            overlayWindow?.hasShadow = false
            overlayWindow?.titlebarAppearsTransparent = true
            overlayWindow?.titleVisibility = .hidden
            overlayWindow?.isReleasedWhenClosed = false

            overlayWindow?.contentView = DismissibleHostingView(
                rootView: ContentView(hideOverlay: { [weak self] in
                    self?.hideOverlay()
                }),
                onBackdropTap: { [weak self] in
                    self?.hideOverlay()
                }
            )
        }

        // Local key monitor: catch Escape while overlay is up
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideOverlay()
                return nil
            }
            return event
        }

        overlayWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideOverlay() {
        guard !isInEditMode else { return }
        overlayWindow?.orderOut(nil)
    }

    // MARK: - Global Hotkey (Shift+Option+Space)

    private func registerHotkey() {
        var hotkeyID = EventHotKeyID()
        hotkeyID.signature = OSType(0x41505447) // 'APTG'
        hotkeyID.id = 1

        let modifiers = UInt32(shiftKey | optionKey)

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        hotkeyRef = ref

        if status != noErr {
            print("[Apptag] Hotkey registration failed: \(status). Falling back to menu bar only.")
            return
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let userData else { return noErr }
                let delegate = Unmanaged<AppDelegate>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                DispatchQueue.main.async {
                    delegate.toggleOverlay()
                }
                return noErr
            },
            1,
            &eventSpec,
            selfPtr,
            nil
        )
    }

    // MARK: - Preferences

    /// Hide overlay when any other window becomes key (catches Cmd+, via SwiftUI Settings).
    /// Suppressed while in edit mode to prevent false dismissals.
    private func observeOtherWindows() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let keyWindow = notification.object as? NSWindow,
                  keyWindow != self.overlayWindow,
                  !self.isInEditMode
            else { return }
            self.hideOverlay()
        }
    }

    /// Track whether the overlay is in edit mode to suppress auto-dismiss.
    private func observeEditMode() {
        NotificationCenter.default.addObserver(
            forName: .apptagEditModeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.isInEditMode = (notification.userInfo?["active"] as? Bool) ?? false
        }
    }

    @objc private func openPreferences() {
        hideOverlay()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

// MARK: - NSView-level backdrop dismiss (works even if SwiftUI rendering is slow)

final class DismissibleHostingView<Content: View>: NSHostingView<Content> {
    private let onBackdropTap: () -> Void

    @MainActor required init(rootView: Content) {
        self.onBackdropTap = {}
        super.init(rootView: rootView)
    }

    init(rootView: Content, onBackdropTap: @escaping () -> Void) {
        self.onBackdropTap = onBackdropTap
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard let hit = hitTest(location) else {
            super.mouseDown(with: event)
            return
        }
        if hit == self {
            onBackdropTap()
            return
        }
        // Recursively search hit subtree for TextFieldContainer or NSTextField.
        // NSHostingView.hitTest may return a SwiftUI-internal wrapper — the
        // actual AppKit subview may be nested deeper.
        if let container = findTextFieldContainer(in: hit) {
            container.mouseDown(with: event)
            return
        }
        if let tf = findNSTextField(in: hit) {
            tf.window?.makeFirstResponder(tf)
            tf.mouseDown(with: event)
            return
        }
        // Forward to any other NSControl we find
        if let control = findNSControl(in: hit) {
            control.mouseDown(with: event)
            return
        }
        super.mouseDown(with: event)
    }

    private func findTextFieldContainer(in view: NSView) -> TextFieldContainer? {
        if let container = view as? TextFieldContainer { return container }
        for sub in view.subviews {
            if let found = findTextFieldContainer(in: sub) { return found }
        }
        return nil
    }

    private func findNSTextField(in view: NSView) -> NSTextField? {
        if let tf = view as? NSTextField, tf.isEditable { return tf }
        for sub in view.subviews {
            if let found = findNSTextField(in: sub) { return found }
        }
        return nil
    }

    private func findNSControl(in view: NSView) -> NSControl? {
        if let control = view as? NSControl { return control }
        for sub in view.subviews {
            if let found = findNSControl(in: sub) { return found }
        }
        return nil
    }
}

// MARK: - Preferences View

struct PreferencesView: View {
    @AppStorage("tagFontSize") private var tagFontSize: Double = 18
    @AppStorage("iconSize") private var iconSize: Double = 56
    @AppStorage("tagPosition") private var tagPosition = "left"
    @AppStorage("defaultGroupName") private var defaultGroupName = "Other"
    @AppStorage("displayMode") private var displayMode = "flat"
    @AppStorage("hideAppNames") private var hideAppNames = false

    @State private var allApps: [AppInfo] = []
    @State private var tagColors: [String: Int] = [:]

    private func scanApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var apps = AppIndexer.scan()
            let store = TagDatabase.migrateFromFinderIfNeeded(apps: apps)
            apps = TagEditor.annotate(apps: apps)
            let colors = store.tags.mapValues { $0.color }
            DispatchQueue.main.async {
                allApps = apps
                tagColors = colors
            }
        }
    }

    private func exportTags() {
        let panel = NSSavePanel()
        panel.title = "Export Tags"
        panel.nameFieldStringValue = "Apptag-tags.json"
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try TagDatabase.exportTo(url)
            } catch {
                fputs("[Apptag] Export failed: \(error)\n", stderr)
            }
        }
    }

    private func importTags() {
        let panel = NSOpenPanel()
        panel.title = "Import Tags"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                _ = try TagDatabase.importFrom(url)
                scanApps()
            } catch {
                fputs("[Apptag] Import failed: \(error)\n", stderr)
                // Show alert on failure
                let alert = NSAlert()
                alert.messageText = "Import Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    private var buildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    var body: some View {
        TabView {
            // Tab 1: General
            Form {
                Section {
                    LabeledContent("App list style:") {
                        Picker("", selection: $displayMode) {
                            Text("Flat").tag("flat")
                            Text("Container").tag("container")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 210)
                    }
                    Text("\"Flat\" shows apps directly. \"Container\" wraps each tag group in a rounded box.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("Hide app names", isOn: $hideAppNames)
                }

                Section {
                    LabeledContent("Tag position:") {
                        Picker("", selection: $tagPosition) {
                            Text("Left").tag("left")
                            Text("Right").tag("right")
                            Text("Top").tag("top")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 210)
                    }
                    Text("Where the tag navigation bar appears. Left/Right puts tags in a sidebar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    LabeledContent("Tag font size:") {
                        Picker("", selection: $tagFontSize) {
                            ForEach([16.0, 18.0, 20.0, 22.0, 24.0, 26.0], id: \.self) { size in
                                Text("\(Int(size))").tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                    }
                    Text("Adjust the size of group-name labels in the overlay.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Appearance")
                }

                Section {
                    LabeledContent("Icon size:") {
                        Picker("", selection: $iconSize) {
                            ForEach([40.0, 48.0, 56.0, 64.0, 72.0, 80.0], id: \.self) { size in
                                Text("\(Int(size))").tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                    }
                    Text("Icon display size. Grid columns adjust automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Layout")
                }
            }
            .tabItem { Label("General", systemImage: "gearshape") }
            .padding()

            // Tab 2: Tags
            VStack(spacing: 0) {
                TagEditorView(
                    tagColors: $tagColors,
                    excludedTagNames: ["Mac自带", defaultGroupName],
                    onRefresh: { scanApps() }
                )
            }
            .tabItem { Label("Tags", systemImage: "tag.fill") }
            .onAppear { scanApps() }

            // Tab 3: Data
            Form {
                Section {
                    HStack {
                        Button("Re-index Now") {
                            NotificationCenter.default.post(name: .apptagReindex, object: nil)
                        }
                        .buttonStyle(.borderedProminent)

                        Text("Re-scan all app directories and refresh the tag database.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Index Management")
                }

                Section {
                    HStack(spacing: 12) {
                        Button("Export Tags…") { exportTags() }
                            .buttonStyle(.bordered)
                        Button("Import Tags…") { importTags() }
                            .buttonStyle(.bordered)
                    }
                    Text("Export saves your tag assignments to a JSON file. Import replaces the current database with one from a file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Backup & Restore")
                }
            }
            .tabItem { Label("Data", systemImage: "externaldrive.fill") }
            .padding()

            // Tab 3: About
            Form {
                Section {
                    HStack {
                        if let icon = NSImage(named: NSImage.applicationIconName) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 64, height: 64)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apptag")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Tag-based app launcher")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text("Version \(appVersion) (Build \(buildVersion))")
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .tabItem { Label("About", systemImage: "info.circle") }
            .padding()
        }
        .frame(minWidth: 660, idealWidth: 660, minHeight: 380, idealHeight: 380)
    }
}
