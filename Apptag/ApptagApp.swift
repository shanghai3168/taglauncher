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
        .defaultSize(width: 880, height: 460)
        .commands {
            CommandGroup(replacing: .systemServices) { }
            CommandGroup(replacing: .appVisibility) { }
        }
    }
}

// MARK: - App Delegate (menubar + overlay window + hotkey)

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let showDockIconKey = "showDockIcon"
    private static let showAppListMenuItemIdentifier = NSUserInterfaceItemIdentifier("TagLauncherShowAppListMenuItem")
    private static let showAppListShortcutGlyphs = "⌥⇧␣"

    private var statusItem: NSStatusItem?
    private var overlayWindow: NSWindow?
    private var overlayKeyMonitor: Any?
    private var settingsWindow: NSWindow?    // Track Settings window to keep it above overlay
    private var hotkeyRef: EventHotKeyRef?
    private var isInEditMode = false  // Suppress auto-dismiss during editing
    private var isConfiguringApplicationMenu = false
    private var lastShowDockIcon: Bool?

    static func refreshChromeSettings() {
        (NSApp.delegate as? AppDelegate)?.syncChromeSettings(force: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        L10n.setup()
        migrateDefaultGroupName()
        TagDatabase.seedDefaultTags()
        syncChromeSettings(force: true)
        registerHotkey()
        observeOtherWindows()
        observeSettingsClose()
        observeEditMode()
        observeApplicationMenuChanges()
        observeChromeSettings()
        observeLanguageChanges()
        setupLaunchAtLogin()
        configureApplicationMenuWhenAvailable()
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

    /// Observe Dock visibility changes so they take effect immediately.
    private func observeChromeSettings() {
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.syncChromeSettings()
        }
    }

    private func syncChromeSettings(force: Bool = false) {
        let showDock = UserDefaults.standard.bool(forKey: Self.showDockIconKey)
        let dockChanged = lastShowDockIcon != showDock

        if force || dockChanged {
            NSApp.setActivationPolicy(showDock ? .regular : .accessory)
            lastShowDockIcon = showDock
        }

        if force {
            setupMenuBar()
        }
    }

    /// Keep app chrome in sync when language changes from any entry point.
    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            forName: .appLanguageDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.setupMenuBar()
            self?.configureApplicationMenuWhenAvailable()
        }
    }

    // MARK: - Launch at Login (LaunchAgent, zero permissions)

    private static let launchAgentLabel = "com.apptag.launcher"
    static var supportsLaunchAtLogin: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] == nil
    }

    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(launchAgentLabel).plist")
    }

    static func enableLaunchAtLogin() {
        guard supportsLaunchAtLogin else { return }
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
        guard supportsLaunchAtLogin else { return }
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
        guard Self.supportsLaunchAtLogin else {
            if UserDefaults.standard.object(forKey: "launchAtLogin") == nil {
                UserDefaults.standard.set(false, forKey: "launchAtLogin")
            }
            return
        }
        let key = "launchAtLogin"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(true, forKey: key)
            Self.enableLaunchAtLogin()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        removeMenuBarItem()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let statusItem else { return }
        statusItem.isVisible = true

        if let button = statusItem.button {
            button.image = makeMenuBarIcon()
            button.imageScaling = .scaleProportionallyDown
            button.imagePosition = .imageOnly
            button.toolTip = "TagLauncher — Tag-based app launcher"
            button.action = #selector(toggleOverlay)
            button.target = self
        }

        let menu = NSMenu()
        let showItem = NSMenuItem(
            title: showAppListMenuTitle,
            action: #selector(toggleOverlay),
            keyEquivalent: ""
        )
        showItem.target = self
        menu.addItem(showItem)
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

    private func makeMenuBarIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.black.setFill()

        let tagBody = NSBezierPath()
        tagBody.move(to: NSPoint(x: 5.0, y: 2.2))
        tagBody.line(to: NSPoint(x: 15.6, y: 5.0))
        tagBody.line(to: NSPoint(x: 12.8, y: 15.8))
        tagBody.line(to: NSPoint(x: 2.2, y: 13.0))
        tagBody.close()
        tagBody.fill()

        NSGraphicsContext.current?.compositingOperation = .clear
        NSBezierPath(ovalIn: NSRect(x: 10.9, y: 11.2, width: 3.2, height: 3.2)).fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver

        image.isTemplate = true
        image.accessibilityDescription = "TagLauncher"
        return image
    }

    private var showAppListMenuTitle: String {
        "\(tr("menu.showAppList"))  \(Self.showAppListShortcutGlyphs)"
    }

    private func observeApplicationMenuChanges() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: NSApp, queue: .main
        ) { [weak self] _ in
            self?.configureApplicationMenuWhenAvailable(retries: 4)
        }

        NotificationCenter.default.addObserver(
            forName: NSMenu.didAddItemNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            guard let self,
                  !self.isConfiguringApplicationMenu,
                  let menu = notification.object as? NSMenu,
                  menu === NSApp.mainMenu?.items.first?.submenu
            else { return }
            self.configureApplicationMenuWhenAvailable(retries: 2)
        }
    }

    private func configureApplicationMenuWhenAvailable(retries: Int = 20) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            guard NSApp.mainMenu?.items.first?.submenu != nil else {
                if retries > 0 {
                    self.configureApplicationMenuWhenAvailable(retries: retries - 1)
                }
                return
            }

            self.configureApplicationMenu()
            if retries > 0 && self.applicationMenuNeedsCleanup() {
                self.configureApplicationMenuWhenAvailable(retries: retries - 1)
            }
        }
    }

    private func configureApplicationMenu() {
        guard !isConfiguringApplicationMenu else { return }
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }

        isConfiguringApplicationMenu = true
        defer { isConfiguringApplicationMenu = false }

        removeUnusedDefaultItems(from: appMenu)
        upsertShowAppListItem(in: appMenu)
        normalizeSeparators(in: appMenu)
    }

    private func applicationMenuNeedsCleanup() -> Bool {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return true }
        let hasUnusedDefaultItems = appMenu.items.contains(where: isUnusedDefaultApplicationMenuItem)
        let hasShowAppListItem = appMenu.items.contains {
            $0.identifier == Self.showAppListMenuItemIdentifier
        }
        return hasUnusedDefaultItems || !hasShowAppListItem
    }

    private func removeUnusedDefaultItems(from menu: NSMenu) {
        for item in menu.items.reversed() where isUnusedDefaultApplicationMenuItem(item) {
            menu.removeItem(item)
        }
    }

    private func isUnusedDefaultApplicationMenuItem(_ item: NSMenuItem) -> Bool {
        if let servicesMenu = NSApp.servicesMenu, item.submenu === servicesMenu {
            return true
        }
        return item.action == #selector(NSApplication.hide(_:))
            || item.action == #selector(NSApplication.hideOtherApplications(_:))
            || item.action == #selector(NSApplication.unhideAllApplications(_:))
    }

    private func upsertShowAppListItem(in menu: NSMenu) {
        if let existingItem = menu.items.first(where: { $0.identifier == Self.showAppListMenuItemIdentifier }) {
            configureShowAppListItem(existingItem)
            return
        }

        let item = NSMenuItem()
        item.identifier = Self.showAppListMenuItemIdentifier
        configureShowAppListItem(item)

        if let settingsIndex = menu.items.firstIndex(where: { isSettingsMenuItem($0) }) {
            menu.insertItem(item, at: settingsIndex + 1)
        } else if let firstSeparatorIndex = menu.items.firstIndex(where: { $0.isSeparatorItem }) {
            menu.insertItem(item, at: firstSeparatorIndex)
        } else {
            menu.addItem(item)
        }
    }

    private func configureShowAppListItem(_ item: NSMenuItem) {
        item.title = showAppListMenuTitle
        item.action = #selector(toggleOverlay)
        item.target = self
        item.keyEquivalent = ""
        item.keyEquivalentModifierMask = []
        item.isEnabled = true
    }

    private func isSettingsMenuItem(_ item: NSMenuItem) -> Bool {
        item.action == Selector(("showSettingsWindow:"))
            || item.action == #selector(openPreferences)
            || item.title == tr("menu.preferences")
    }

    private func normalizeSeparators(in menu: NSMenu) {
        var indexesToRemove: [Int] = []
        var previousWasSeparator = false

        for (index, item) in menu.items.enumerated() {
            guard item.isSeparatorItem else {
                previousWasSeparator = false
                continue
            }
            if index == 0 || index == menu.items.count - 1 || previousWasSeparator {
                indexesToRemove.append(index)
            }
            previousWasSeparator = true
        }

        for index in indexesToRemove.reversed() {
            menu.removeItem(at: index)
        }
    }

    private func removeMenuBarItem() {
        guard let statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
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

        installOverlayKeyMonitor()

        overlayWindow?.makeKeyAndOrderFront(nil)
        overlayWindow?.orderFrontRegardless()
    }

    private func installOverlayKeyMonitor() {
        guard overlayKeyMonitor == nil else { return }
        overlayKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.hideOverlay()
                return nil
            }
            return event
        }
    }

    private func removeOverlayKeyMonitor() {
        if let monitor = overlayKeyMonitor {
            NSEvent.removeMonitor(monitor)
            overlayKeyMonitor = nil
        }
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
        if let settingsWindow, settingsWindow.parent == overlayWindow {
            detachSettingsWindow(settingsWindow)
        }
        overlayWindow?.orderOut(nil)
        removeOverlayKeyMonitor()
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

            // Settings/Preferences window -> float it above overlay for real-time preview.
            if self.isSettingsWindowCandidate(keyWindow) {
                self.prepareSettingsWindow(keyWindow)
                return
            }

            self.hideOverlay()
        }
    }

    /// Settings must always appear centered over the current overlay view and float above it.
    private func prepareSettingsWindow(_ window: NSWindow) {
        let settingsSize = NSSize(width: 880, height: 460)
        window.identifier = NSUserInterfaceItemIdentifier("TagLauncherPreferencesWindow")
        window.minSize = settingsSize
        window.maxSize = settingsSize
        if abs(window.frame.width - settingsSize.width) > 0.5 || abs(window.frame.height - settingsSize.height) > 0.5 {
            window.setFrame(
                NSRect(origin: window.frame.origin, size: settingsSize),
                display: false
            )
        }

        if let overlayWindow, overlayWindow.isVisible {
            center(window, over: overlayWindow.frame)
            attachSettingsWindow(window, to: overlayWindow)
            window.level = overlayWindow.level
        } else if let screen = screenUnderMouse() {
            center(window, over: screen.visibleFrame)
            window.level = .floating
            detachSettingsWindow(window)
        }

        var behavior = window.collectionBehavior
        behavior.remove(.canJoinAllSpaces)
        behavior.formUnion([.fullScreenAuxiliary, .moveToActiveSpace])
        window.collectionBehavior = behavior
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        settingsWindow = window
    }

    private func attachSettingsWindow(_ window: NSWindow, to overlayWindow: NSWindow) {
        if window.parent != overlayWindow {
            window.parent?.removeChildWindow(window)
            overlayWindow.addChildWindow(window, ordered: .above)
        }
    }

    private func detachSettingsWindow(_ window: NSWindow) {
        window.parent?.removeChildWindow(window)
    }

    private func isSettingsWindowCandidate(_ window: NSWindow) -> Bool {
        if window == settingsWindow { return true }
        if window.identifier?.rawValue == "TagLauncherPreferencesWindow" { return true }
        guard NSApp.windows.contains(window),
              window != overlayWindow,
              window.isVisible,
              !(window is NSPanel)
        else { return false }
        return true
    }

    private func center(_ window: NSWindow, over rect: NSRect) {
        let frame = window.frame
        let origin = NSPoint(
            x: rect.midX - frame.width / 2,
            y: rect.midY - frame.height / 2
        )
        window.setFrameOrigin(origin)
    }

    private func screenUnderMouse() -> NSScreen? {
        let mousePoint = NSEvent.mouseLocation
        return NSScreen.screens.first(where: {
            NSMouseInRect(mousePoint, $0.frame, false)
        }) ?? NSScreen.main ?? NSScreen.screens.first
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
            self.detachSettingsWindow(closingWindow)
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
        if let overlayWindow, overlayWindow.isVisible {
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.orderFrontRegardless()
        }
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        prepareSettingsWindowWhenAvailable(retries: 10)
    }

    private func prepareSettingsWindowWhenAvailable(retries: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            guard let self else { return }
            let candidates = NSApp.windows.filter { window in
                self.isSettingsWindowCandidate(window)
            }
            candidates.forEach { self.prepareSettingsWindow($0) }
            if candidates.isEmpty && retries > 0 {
                self.prepareSettingsWindowWhenAvailable(retries: retries - 1)
            }
        }
    }

    @objc private func switchLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        L10n.switchTo(code)
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
    private let settingsWindowWidth: CGFloat = 880
    private let settingsContentWidth: CGFloat = 820
    private let generalContentWidth: CGFloat = 720
    private let generalLabelWidth: CGFloat = 190
    private let generalControlWidth: CGFloat = 500
    private let compactPickerWidth: CGFloat = 320

    @AppStorage("tagFontSize") private var tagFontSize: Double = 18
    @AppStorage("iconSize") private var iconSize: Double = 56
    @AppStorage("tagPosition") private var tagPosition = "left"
    @AppStorage("defaultGroupName") private var defaultGroupName = "Other"
    @AppStorage("displayMode") private var displayMode = "flat"
    @AppStorage("hideAppNames") private var hideAppNames = false
    @AppStorage("showDockIcon") private var showDockIcon = false
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    @State private var selectedLanguage = L10n.currentCode
    @State private var isRefreshingLanguage = false
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
                showDataAlert(title: tr("settings.exportFailed"), message: error.localizedDescription)
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
                showDataAlert(title: tr("settings.importFailed"), message: error.localizedDescription)
            }
        }
    }

    private func showDataAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    private var buildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    private var languageColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 220), spacing: 18, alignment: .top),
            GridItem(.flexible(minimum: 220), spacing: 18, alignment: .top),
        ]
    }
    private var displayModeColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 220), spacing: 10, alignment: .top),
            GridItem(.flexible(minimum: 220), spacing: 10, alignment: .top),
        ]
    }
    private var displayModeOptions: [(id: String, title: String)] {
        [
            ("flat", tr("settings.flat")),
            ("container", tr("settings.container")),
            ("coloredContainer", tr("settings.coloredContainer")),
            ("gridContainer", tr("settings.gridContainer")),
            ("coloredGridContainer", tr("settings.coloredGridContainer")),
        ]
    }
    private var containerDisplayModeOptions: [(id: String, title: String)] {
        Array(displayModeOptions.dropFirst())
    }

    private func generalSettingRow<Control: View>(
        _ label: String,
        description: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .frame(width: generalLabelWidth, alignment: .trailing)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 6) {
                control()
                    .frame(width: generalControlWidth, alignment: .leading)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: generalControlWidth, alignment: .leading)
            }
        }
        .frame(width: generalContentWidth, alignment: .leading)
    }

    var body: some View {
        ZStack {
            TabView {
                // Tab 1: Language
                VStack(alignment: .leading, spacing: 10) {
                    Text(tr("settings.language"))
                        .font(.headline)
                    Text(tr("settings.languageDesc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVGrid(columns: languageColumns, alignment: .leading, spacing: 6) {
                            ForEach(L10n.supported, id: \.code) { language in
                                Button {
                                    selectedLanguage = language.code
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: selectedLanguage == language.code ? "checkmark" : "circle")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(selectedLanguage == language.code ? Color.accentColor : Color.secondary.opacity(0.28))
                                            .frame(width: 16)
                                        Text(language.name)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(tr("settings.languagePicker")) \(language.name)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 250)

                    Spacer(minLength: 0)
                    ShortcutHintView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 2)
                }
                .frame(maxWidth: settingsContentWidth, alignment: .leading)
                .tabItem { Label(tr("settings.language"), systemImage: "globe") }
                .padding()

                // Tab 2: General
            VStack(alignment: .leading, spacing: 0) {
                // Toggle row — centered as a rectangular block
                HStack(spacing: 20) {
                    if AppDelegate.supportsLaunchAtLogin {
                        Toggle(tr("settings.launchAtLogin"), isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, enabled in
                                if enabled {
                                    AppDelegate.enableLaunchAtLogin()
                                } else {
                                    AppDelegate.disableLaunchAtLogin()
                                }
                            }
                    }
                    Toggle(tr("settings.showInDock"), isOn: $showDockIcon)
                        .onChange(of: showDockIcon) { _, _ in
                            AppDelegate.refreshChromeSettings()
                        }
                    Toggle(tr("settings.hideAppNames"), isOn: $hideAppNames)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

                Divider()
                    .padding(.bottom, 16)

                VStack(spacing: 18) {
                    generalSettingRow(tr("settings.appListStyle"), description: tr("settings.flatDesc")) {
                        VStack(spacing: 8) {
                            DisplayModeOptionButton(
                                mode: "flat",
                                title: tr("settings.flat"),
                                isSelected: displayMode == "flat"
                            ) {
                                displayMode = "flat"
                            }

                            LazyVGrid(columns: displayModeColumns, alignment: .leading, spacing: 8) {
                                ForEach(containerDisplayModeOptions, id: \.id) { option in
                                    DisplayModeOptionButton(
                                        mode: option.id,
                                        title: option.title,
                                        isSelected: displayMode == option.id
                                    ) {
                                        displayMode = option.id
                                    }
                                }
                            }
                        }
                        .frame(width: generalControlWidth, alignment: .leading)
                    }

                    generalSettingRow(tr("settings.tagPosition"), description: tr("settings.tagPosDesc")) {
                        Picker("", selection: $tagPosition) {
                            Text(tr("settings.left")).tag("left")
                            Text(tr("settings.right")).tag("right")
                            Text(tr("settings.top")).tag("top")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: compactPickerWidth, alignment: .leading)
                    }

                    generalSettingRow(tr("settings.tagFontSize"), description: tr("settings.tagFontDesc")) {
                        Picker("", selection: $tagFontSize) {
                            ForEach([16.0, 18.0, 20.0, 22.0, 24.0, 26.0], id: \.self) { size in
                                Text("\(Int(size))").tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: compactPickerWidth, alignment: .leading)
                    }

                    generalSettingRow(tr("settings.iconSize"), description: tr("settings.iconSizeDesc")) {
                        Picker("", selection: $iconSize) {
                            ForEach([40.0, 48.0, 56.0, 64.0, 72.0, 80.0], id: \.self) { size in
                                Text("\(Int(size))").tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: compactPickerWidth, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: generalContentWidth, alignment: .center)
            .padding()
            .tabItem { Label(tr("settings.general"), systemImage: "gearshape") }

            // Tab 3: Tags
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

            // Tab 4: Data
            VStack(spacing: 0) {
                Spacer(minLength: 96)

                VStack(alignment: .leading, spacing: 8) {
                    Text(tr("settings.backup"))
                        .font(.headline)
                    HStack(spacing: 12) {
                        Button(tr("settings.export")) { exportTags() }
                            .buttonStyle(.bordered)
                        Button(tr("settings.import")) { importTags() }
                            .buttonStyle(.bordered)
                    }
                    Text(tr("settings.backupDesc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 420, alignment: .leading)

                Spacer(minLength: 42)
                ShortcutHintView()
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 18)
            }
            .tabItem { Label(tr("settings.data"), systemImage: "externaldrive.fill") }
            .padding()

            // Tab 5: About
            VStack(spacing: 0) {
                Spacer(minLength: 72)

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
                .frame(width: 560, alignment: .leading)

                Spacer(minLength: 30)
                ShortcutHintView()
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer(minLength: 18)
            }
            .tabItem { Label(tr("settings.about"), systemImage: "info.circle") }
            .padding()
            }
            .onChange(of: selectedLanguage) { _, code in
                L10n.switchTo(code)
            }
            .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { notification in
                if let code = notification.userInfo?["code"] as? String {
                    selectedLanguage = code
                }
                showLanguageRefresh()
            }

            if isRefreshingLanguage {
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                        .opacity(0.84)
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 30, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }
        }
        .frame(width: settingsWindowWidth, height: 460)
    }

    private func showLanguageRefresh() {
        isRefreshingLanguage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.18)) {
                isRefreshingLanguage = false
            }
        }
    }
}

private struct DisplayModeOptionButton: View {
    let mode: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                DisplayModeGlyph(mode: mode, isSelected: isSelected)
                    .frame(width: 24, height: 18)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .padding(.horizontal, 9)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct DisplayModeGlyph: View {
    let mode: String
    let isSelected: Bool

    var body: some View {
        switch mode {
        case "flat":
            HStack(spacing: 2) {
                cell(index: 0, width: 5, height: 5, colored: false)
                cell(index: 1, width: 5, height: 5, colored: false)
                cell(index: 2, width: 5, height: 5, colored: false)
            }
        case "gridContainer", "coloredGridContainer":
            let colored = mode == "coloredGridContainer"
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    cell(index: 0, width: 7, height: 6, colored: colored)
                    cell(index: 1, width: 7, height: 6, colored: colored)
                }
                HStack(spacing: 2) {
                    cell(index: 2, width: 7, height: 6, colored: colored)
                    cell(index: 3, width: 7, height: 6, colored: colored)
                }
            }
        default:
            let colored = mode == "coloredContainer"
            HStack(alignment: .bottom, spacing: 2) {
                cell(index: 0, width: 5, height: 8, colored: colored)
                cell(index: 1, width: 5, height: 14, colored: colored)
                cell(index: 2, width: 5, height: 10, colored: colored)
            }
        }
    }

    private func cell(index: Int, width: CGFloat, height: CGFloat, colored: Bool) -> some View {
        let fill = fillColor(index: index, colored: colored)
        let stroke = isSelected ? Color.white.opacity(0.95) : Color.secondary.opacity(0.35)
        return RoundedRectangle(cornerRadius: 1.8, style: .continuous)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 1.8, style: .continuous)
                    .stroke(stroke, lineWidth: 0.8)
            )
            .frame(width: width, height: height)
    }

    private func fillColor(index: Int, colored: Bool) -> Color {
        if isSelected {
            return Color.white.opacity(colored ? 0.9 : 0.18)
        }
        guard colored else {
            return Color.secondary.opacity(0.12)
        }
        let palette: [Color] = [.green, .purple, .blue, .orange]
        return palette[index % palette.count].opacity(0.78)
    }
}

private struct ShortcutHintView: View {
    var body: some View {
        HStack(spacing: 12) {
            ShortcutKeycap(symbol: "⌥")
            Text("+")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.tertiary)
            ShortcutKeycap(symbol: "⇧")
            Text("+")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.tertiary)
            SpacebarKeycap()
        }
        .accessibilityLabel("⌥ ⇧ Space")
        .allowsHitTesting(false)
    }
}

private struct ShortcutKeycap: View {
    let symbol: String

    var body: some View {
        Text(symbol)
            .font(.system(size: 36, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 74, height: 58)
            .background(KeycapBackground())
    }
}

private struct SpacebarKeycap: View {
    var body: some View {
        ZStack {
            KeycapBackground()
            Capsule()
                .fill(Color.secondary.opacity(0.38))
                .frame(width: 72, height: 3)
                .offset(y: 13)
        }
        .frame(width: 190, height: 58)
    }
}

private struct KeycapBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 3)
    }
}
