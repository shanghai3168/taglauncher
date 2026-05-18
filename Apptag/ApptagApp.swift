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
    private static let overlayDefaultLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
    private static let overlayTextInputLevel = NSWindow.Level.modalPanel

    private var statusItem: NSStatusItem?
    private var overlayWindow: NSWindow?
    private var overlayKeyMonitor: Any?
    private var settingsWindow: NSWindow?    // Track Settings window to keep it above overlay
    private var hotkeyRef: EventHotKeyRef?
    private var isInEditMode = false  // Suppress auto-dismiss during editing
    private var isEditingAppNote = false
    private var isConfiguringApplicationMenu = false
    private var lastShowDockIcon: Bool?

    static func refreshChromeSettings() {
        (NSApp.delegate as? AppDelegate)?.syncChromeSettings(force: true)
    }

    static func openPreferencesWindow() {
        (NSApp.delegate as? AppDelegate)?.openPreferences()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDefaults.register()
        L10n.setup()
        migrateDefaultGroupName()
        TagDatabase.seedDefaultTags()
        syncChromeSettings(force: true)
        registerHotkey()
        observeOtherWindows()
        observeSettingsClose()
        observeEditMode()
        observeAppNoteEditing()
        observePreferencesRequests()
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

    func applicationWillTerminate(_ notification: Notification) {
        TagDatabase.flushPendingCategorySchemeBackupBatch()
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
        if !AppDefaults.hasStoredValue(for: key) && UserDefaults.standard.bool(forKey: key) {
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
        prefsItem.target = self
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
        let menuBarIconSize = NSSize(width: 19, height: 19)
        if let url = Bundle.main.url(forResource: "TagLauncherMenuBarIcon", withExtension: "svg"),
           let image = NSImage(contentsOf: url) {
            image.size = menuBarIconSize
            image.isTemplate = true
            image.accessibilityDescription = "TagLauncher"
            return image
        }

        let image = NSImage(size: menuBarIconSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSGraphicsContext.current?.shouldAntialias = true
        NSColor.black.withAlphaComponent(0.88).setStroke()
        NSColor.black.withAlphaComponent(0.88).setFill()

        let scale = image.size.width / 220.0
        func rectFromSVG(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
            NSRect(
                x: x * scale,
                y: (220.0 - y - height) * scale,
                width: width * scale,
                height: height * scale
            )
        }

        let outline = NSBezierPath(
            roundedRect: rectFromSVG(x: 15, y: 15, width: 190, height: 190),
            xRadius: 44 * scale,
            yRadius: 44 * scale
        )
        outline.lineWidth = 11 * scale
        outline.stroke()

        for rect in [
            rectFromSVG(x: 49, y: 134, width: 27, height: 27),
            rectFromSVG(x: 92, y: 134, width: 27, height: 27),
            rectFromSVG(x: 49, y: 91, width: 27, height: 27),
            rectFromSVG(x: 92, y: 91, width: 27, height: 27),
            rectFromSVG(x: 49, y: 48, width: 27, height: 27),
            rectFromSVG(x: 92, y: 48, width: 27, height: 27)
        ] {
            NSBezierPath(roundedRect: rect, xRadius: 8 * scale, yRadius: 8 * scale).fill()
        }

        for rect in [
            rectFromSVG(x: 132, y: 133, width: 47, height: 28),
            rectFromSVG(x: 132, y: 90.5, width: 47, height: 28),
            rectFromSVG(x: 132, y: 48, width: 47, height: 28)
        ] {
            NSBezierPath(roundedRect: rect, xRadius: 12 * scale, yRadius: 12 * scale).fill()
        }

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
        configurePreferencesMenuItem(in: appMenu)
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

    private func configurePreferencesMenuItem(in menu: NSMenu) {
        let item: NSMenuItem
        if let existingItem = menu.items.first(where: { isSettingsMenuItem($0) }) {
            item = existingItem
        } else {
            item = NSMenuItem()
            if let firstSeparatorIndex = menu.items.firstIndex(where: { $0.isSeparatorItem }) {
                menu.insertItem(item, at: firstSeparatorIndex)
            } else {
                menu.addItem(item)
            }
        }

        item.title = tr("menu.preferences")
        item.action = #selector(openPreferences)
        item.target = self
        item.keyEquivalent = ","
        item.keyEquivalentModifierMask = .command
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
        overlayWindow?.level = isEditingAppNote ? Self.overlayTextInputLevel : Self.overlayDefaultLevel

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
        TagDatabase.flushPendingCategorySchemeBackupBatch()
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

    /// Lower the overlay while editing app notes so IME candidate windows are not hidden behind it.
    private func observeAppNoteEditing() {
        NotificationCenter.default.addObserver(
            forName: .tagLauncherAppNoteEditingChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.isEditingAppNote = (notification.userInfo?["active"] as? Bool) ?? false
            self.updateOverlayLevelForTextInput()
        }
    }

    private func updateOverlayLevelForTextInput() {
        guard let overlayWindow else { return }
        overlayWindow.level = isEditingAppNote ? Self.overlayTextInputLevel : Self.overlayDefaultLevel
        if let settingsWindow, settingsWindow.parent == overlayWindow {
            settingsWindow.level = overlayWindow.level
        }
    }

    /// The overlay buttons live inside SwiftUI; use an app-level notification like edit mode does.
    private func observePreferencesRequests() {
        NotificationCenter.default.addObserver(
            forName: .tagLauncherOpenPreferencesRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openPreferences()
        }
    }

    @objc private func openPreferences() {
        TagDatabase.flushPendingCategorySchemeBackupBatch()
        // Don't hide overlay — keep it visible for real-time setting preview.
        if let overlayWindow, overlayWindow.isVisible {
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.orderFrontRegardless()
        }
        NSApp.activate(ignoringOtherApps: true)

        if let settingsWindow {
            prepareSettingsWindow(settingsWindow)
            return
        }

        let settingsSize = NSSize(width: 880, height: 460)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: settingsSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = tr("menu.preferences").replacingOccurrences(of: "…", with: "")
        window.contentView = NSHostingView(rootView: PreferencesView())
        window.isReleasedWhenClosed = false
        settingsWindow = window
        prepareSettingsWindow(window)
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
        if let floatingButton = findFloatingIconButton(at: event.locationInWindow, in: self) {
            floatingButton.mouseDown(with: event)
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

    private func findFloatingIconButton(at windowPoint: NSPoint, in view: NSView) -> FloatingIconButtonView? {
        for subview in view.subviews.reversed() where !subview.isHidden {
            if let found = findFloatingIconButton(at: windowPoint, in: subview) {
                return found
            }
        }
        guard let floatingButton = view as? FloatingIconButtonView else { return nil }
        let localPoint = floatingButton.convert(windowPoint, from: nil)
        if floatingButton.bounds.contains(localPoint) {
            return floatingButton
        }
        return nil
    }

}
