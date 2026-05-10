import SwiftUI
import AppKit
import Carbon

// MARK: - Application Entry Point

@main
struct TagLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
        .defaultSize(width: 660, height: 380)
    }
}

// MARK: - App Delegate (menubar + overlay window + hotkey)

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var overlayWindow: NSWindow?
    private var settingsWindow: NSWindow?    // Track Settings window to keep it above overlay
    private var hotkeyRef: EventHotKeyRef?
    private var isInEditMode = false  // Suppress auto-dismiss during editing

    func applicationDidFinishLaunching(_ notification: Notification) {
        L10n.setup()
        migrateDefaultGroupName()
        TagDatabase.seedDefaultTags()
        let showDock = UserDefaults.standard.bool(forKey: "showDockIcon")
        NSApp.setActivationPolicy(showDock ? .regular : .accessory)
        setupMenuBar()
        registerHotkey()
        observeOtherWindows()
        observeSettingsClose()
        observeEditMode()
        observeDockSetting()
        setupLaunchAtLogin()
    }

    /// Dock icon click → show overlay (same as menubar "Show TagLauncher")
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showOverlay()
        return false  // Suppress default "unhide all windows" behavior
    }

    /// Ensure defaultGroupName is always the language-neutral key "Other".
    /// Translates known old values back to "Other" so switching languages works.
    private func migrateDefaultGroupName() {
        let key = "defaultGroupName"
        let stored = UserDefaults.standard.string(forKey: key)
        // "Other" is the neutral key — nothing to do
        if stored == nil || stored == "Other" { return }
        // Check if the stored value is a translated version of "group.uncategorized"
        for (code, _) in L10n.supported {
            let loc = L10n.loadedTranslation("group.uncategorized", for: code)
            if stored == loc {
                UserDefaults.standard.set("Other", forKey: key)
                return
            }
        }
        // User has set a custom name — keep it
    }

    /// Observe Show in Dock changes so it takes effect immediately.
    private func observeDockSetting() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil, queue: .main
        ) { _ in
            let show = UserDefaults.standard.bool(forKey: "showDockIcon")
            NSApp.setActivationPolicy(show ? .regular : .accessory)
        }
    }

    // MARK: - Launch at Login (LaunchAgent, zero permissions)

    private static let launchAgentLabel = "com.apptag.launcher"

    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(launchAgentLabel).plist")
    }

    static func enableLaunchAtLogin() {
        let plist: [String: Any] = [
            "Label": Self.launchAgentLabel,
            "ProgramArguments": ["open", Bundle.main.bundlePath, "--hide"],
            "RunAtLoad": true,
        ]
        let dir = Self.launchAgentURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        (plist as NSDictionary).write(to: Self.launchAgentURL, atomically: true)

        let uid = getuid()
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["bootstrap", "gui/\(uid)", Self.launchAgentURL.path]
        task.launch()
    }

    static func disableLaunchAtLogin() {
        let uid = getuid()
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["bootout", "gui/\(uid)/\(Self.launchAgentLabel)"]
        task.launch()
        try? FileManager.default.removeItem(at: Self.launchAgentURL)
    }

    /// On first launch, enable login item by default via LaunchAgent.
    /// Does NOT require App Management permission.
    private func setupLaunchAtLogin() {
        let key = "launchAtLogin"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(true, forKey: key)
            Self.enableLaunchAtLogin()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        // Remove old status item if re-creating (language switch, etc.)
        if let existing = statusItem {
            NSStatusBar.system.removeStatusItem(existing)
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "tag.fill",
                accessibilityDescription: "TagLauncher"
            )
            button.toolTip = "TagLauncher — Tag-based app launcher"
            button.action = #selector(toggleOverlay)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(
            NSMenuItem(
                title: "\(tr("menu.show"))  ⇧⌥Space",
                action: #selector(toggleOverlay),
                keyEquivalent: ""
            )
        )
        menu.addItem(.separator())

        // Version display
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let versionItem = NSMenuItem(
            title: "\(tr("menu.version")) \(appVersion) (\(buildNumber))",
            action: nil,
            keyEquivalent: ""
        )
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        menu.addItem(.separator())
        let prefsItem = NSMenuItem(
            title: tr("menu.preferences"),
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.keyEquivalentModifierMask = .command
        menu.addItem(prefsItem)
        menu.addItem(.separator())

        // Language submenu
        let langMenu = NSMenu()
        let currentLang = L10n.currentCode
        for (code, name) in L10n.supported {
            let item = NSMenuItem(title: name, action: #selector(switchLanguage(_:)), keyEquivalent: "")
            item.representedObject = code
            item.state = (code == currentLang) ? .on : .off
            langMenu.addItem(item)
        }
        let langItem = NSMenuItem(title: tr("menu.language"), action: nil, keyEquivalent: "")
        langItem.submenu = langMenu
        menu.addItem(langItem)

        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: tr("menu.quit"),
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
        // Use the screen under the mouse cursor — works in fullscreen spaces
        let mousePoint = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: {
            NSMouseInRect(mousePoint, $0.frame, false)
        }) ?? NSScreen.main ?? NSScreen.screens.first else { return }

        overlayWindow?.orderOut(nil)
        overlayWindow = makeOverlayWindow(on: screen)
        overlayWindow?.setFrame(screen.frame, display: true)
        overlayWindow?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))

        // Local key monitor: catch Escape while overlay is up
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideOverlay()
                return nil
            }
            return event
        }

        overlayWindow?.makeKeyAndOrderFront(nil)
        overlayWindow?.orderFrontRegardless()
    }

    private func makeOverlayWindow(on screen: NSScreen) -> NSWindow {
        let panel = OverlayPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [
            .moveToActiveSpace,
            .fullScreenAuxiliary,
            .stationary,
            .transient,
            .ignoresCycle
        ]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isReleasedWhenClosed = false
        panel.contentView = DismissibleHostingView(
            rootView: ContentView(hideOverlay: { [weak self] in
                self?.hideOverlay(force: true)
            }),
            onBackdropTap: { [weak self] in
                self?.hideOverlay()
            }
        )
        return panel
    }

    private func hideOverlay(force: Bool = false) {
        guard force || !isInEditMode else { return }
        overlayWindow?.orderOut(nil)
        if force {
            overlayWindow = nil
        }
    }

    // MARK: - Global Hotkey (Shift+Option+Space)

    /// Carbon RegisterEventHotKey. If it fails (sandbox, etc.), falls back to menu bar only.
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
            print("[TagLauncher] Hotkey registration failed: \(status). Falling back to menu bar only.")
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

            // Settings/Preferences window → float it above overlay for real-time preview
            if NSApp.windows.contains(keyWindow) {
                self.prepareSettingsWindow(keyWindow)
                return
            }

            self.hideOverlay()
        }
    }

    /// Settings must always float above the overlay so changes can be previewed live.
    private func prepareSettingsWindow(_ window: NSWindow) {
        if overlayWindow?.isVisible == true {
            let overlayLevel = overlayWindow?.level.rawValue ?? NSWindow.Level.screenSaver.rawValue
            window.level = NSWindow.Level(rawValue: overlayLevel + 1)
            window.orderFrontRegardless()
        }
        if settingsWindow == nil {
            window.minSize = NSSize(width: 660, height: 380)
            window.maxSize = NSSize(width: 660, height: CGFloat.greatestFiniteMagnitude)
        }
        settingsWindow = window
    }

    /// Clean up settingsWindow reference when the Settings window closes.
    private func observeSettingsClose() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let closingWindow = notification.object as? NSWindow,
                  closingWindow == self.settingsWindow
            else { return }
            self.settingsWindow = nil
        }
    }

    /// Track whether the overlay is in edit mode to suppress auto-dismiss.
    private func observeEditMode() {
        NotificationCenter.default.addObserver(
            forName: .tagLauncherEditModeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.isInEditMode = (notification.userInfo?["active"] as? Bool) ?? false
        }
    }

    @objc private func openPreferences() {
        // Don't hide overlay — keep it visible for real-time setting preview.
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for window in NSApp.windows where window != self.overlayWindow {
                self.prepareSettingsWindow(window)
            }
        }
    }

    @objc private func switchLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        L10n.switchTo(code)
        // Rebuild menu to update checkmarks
        setupMenuBar()
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
    @AppStorage("showDockIcon") private var showDockIcon = false
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    @State private var allApps: [AppInfo] = []
    @State private var tagColors: [String: Int] = [:]

    private func scanApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var apps = AppIndexer.scan()
            let store = TagDatabase.load()
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
        panel.title = tr("settings.export")
        panel.nameFieldStringValue = "TagLauncher-tags.json"
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try TagDatabase.exportTo(url)
            } catch {
                fputs("[TagLauncher] Export failed: \(error)\n", stderr)
            }
        }
    }

    private func importTags() {
        let panel = NSOpenPanel()
        panel.title = tr("settings.import")
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                _ = try TagDatabase.importFrom(url)
                scanApps()
            } catch {
                fputs("[TagLauncher] Import failed: \(error)\n", stderr)
                // Show alert on failure
                let alert = NSAlert()
                alert.messageText = tr("settings.importFailed")
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
            VStack(alignment: .leading, spacing: 0) {
                // Toggle row — centered as a rectangular block
                HStack(spacing: 20) {
                    Toggle(tr("settings.launchAtLogin"), isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, enabled in
                            if enabled {
                                AppDelegate.enableLaunchAtLogin()
                            } else {
                                AppDelegate.disableLaunchAtLogin()
                            }
                        }
                    Toggle(tr("settings.showInDock"), isOn: $showDockIcon)
                    Toggle(tr("settings.hideAppNames"), isOn: $hideAppNames)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

                Divider()
                    .padding(.bottom, 16)

                // Two-column layout: each row label (right-aligned) + controls (left-aligned)
                // All pickers and descriptions share the same left edge
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        Text(tr("settings.appListStyle"))
                            .frame(width: 130, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: $displayMode) {
                                Text(tr("settings.flat")).tag("flat")
                                Text(tr("settings.container")).tag("container")
                                Text(tr("settings.coloredContainer")).tag("coloredContainer")
                                Text(tr("settings.gridContainer")).tag("gridContainer")
                                Text(tr("settings.coloredGridContainer")).tag("coloredGridContainer")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 520, alignment: .leading)
                            Text(tr("settings.flatDesc"))
                                .font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Text(tr("settings.tagPosition"))
                            .frame(width: 130, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: $tagPosition) {
                                Text(tr("settings.left")).tag("left")
                                Text(tr("settings.right")).tag("right")
                                Text(tr("settings.top")).tag("top")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 280, alignment: .leading)
                            Text(tr("settings.tagPosDesc"))
                                .font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Text(tr("settings.tagFontSize"))
                            .frame(width: 130, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: $tagFontSize) {
                                ForEach([16.0, 18.0, 20.0, 22.0, 24.0, 26.0], id: \.self) { size in
                                    Text("\(Int(size))").tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 280, alignment: .leading)
                            Text(tr("settings.tagFontDesc"))
                                .font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Text(tr("settings.iconSize"))
                            .frame(width: 130, alignment: .trailing)
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: $iconSize) {
                                ForEach([40.0, 48.0, 56.0, 64.0, 72.0, 80.0], id: \.self) { size in
                                    Text("\(Int(size))").tag(size)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 280, alignment: .leading)
                            Text(tr("settings.iconSizeDesc"))
                                .font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding()
            .tabItem { Label(tr("settings.general"), systemImage: "gearshape") }

            // Tab 2: Tags
            VStack(spacing: 0) {
                TagEditorView(
                    tagColors: $tagColors,
                    excludedTagNames: ["Mac自带", defaultGroupName],
                    onRefresh: { scanApps() }
                )
            }
            .padding(.leading, 16)
            .tabItem { Label(tr("settings.tags"), systemImage: "tag.fill") }
            .onAppear { scanApps() }

            // Tab 3: Data
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button(tr("settings.export")) { exportTags() }
                            .buttonStyle(.bordered)
                        Button(tr("settings.import")) { importTags() }
                            .buttonStyle(.bordered)
                    }
                    Text(tr("settings.backupDesc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(tr("settings.backup"))
                }
            }
            .tabItem { Label(tr("settings.data"), systemImage: "externaldrive.fill") }
            .padding()

            // Tab 4: About
            Form {
                Section {
                    HStack {
                        if let icon = NSImage(named: NSImage.applicationIconName) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 128, height: 128)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TagLauncher")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(tr("app.description"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Text("\(tr("app.version")) \(appVersion) (\(tr("app.build")) \(buildVersion))")
                                .font(.callout)
                                .foregroundStyle(.tertiary)

                            Divider()
                                .padding(.vertical, 4)

                            Text("万物之中，希望最美")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("永桔@2026-18602102518")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 100)
                }
            }
            .tabItem { Label(tr("settings.about"), systemImage: "info.circle") }
            .padding()
        }
        .frame(minWidth: 660, maxWidth: 660, minHeight: 380)
    }
}
