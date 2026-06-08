import SwiftUI
import AppKit
import Carbon

// MARK: - Application Entry Point

@main
struct TagLauncherApp: App {
    private static let singletonLockFile = TagLauncherProcessSingleton.acquireOrHandOffAndExit()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        _ = Self.singletonLockFile
    }

    var body: some Scene {
        Settings {
            PreferencesView()
        }
        .defaultSize(width: 1000, height: 480)
        .commands {
            CommandGroup(replacing: .systemServices) { }
            CommandGroup(replacing: .appVisibility) { }
            CommandGroup(replacing: .help) { }
        }
    }
}

// MARK: - App Delegate (menubar + overlay window + hotkey)

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let showDockIconKey = "showDockIcon"
    private static let statusItemAutosaveName = AppIdentity.statusItemAutosaveName
    private static let statusItemButtonIdentifier = NSUserInterfaceItemIdentifier("TagLauncherStatusItemButton")
    private static let statusItemAccessibilityLabel = AppIdentity.displayName
    private static let showAppListMenuItemIdentifier = NSUserInterfaceItemIdentifier("TagLauncherShowAppListMenuItem")
    private static let helpMenuItemIdentifier = NSUserInterfaceItemIdentifier("TagLauncherHelpMenu")
    private static let downloadHelpMenuItemIdentifier = NSUserInterfaceItemIdentifier("TagLauncherDownloadHelpMenuItem")
    private static let externalActivationNotification = Notification.Name("TagLauncherExternalActivationRequested")
    private static let externalActivationObject = AppIdentity.bundleIdentifier
    private static let duplicateLaunchSuppressReopenKey = "duplicateLaunchSuppressReopenAt"
    private static let launcherOverlayLevel = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
    private static let overlayDefaultLevel = launcherOverlayLevel
    private static let overlayTextInputLevel = launcherOverlayLevel

    private var statusItem: NSStatusItem?
    private var overlayKeyMonitor: Any?
    private var quickSearchLocalMouseMonitor: Any?
    private var quickSearchExternalMouseMonitor: Any?
    private var settingsWindow: NSWindow?    // Track Settings window to keep it above overlay
    private var mainHotkeyRef: EventHotKeyRef?
    private var quickSearchHotkeyRef: EventHotKeyRef?
    private var hotkeyEventHandlerInstalled = false
    private var isQuickSearchOpen = false
    private var quickSearchShouldHideOverlayOnClose = false
    private var quickSearchOnlyOverlaySession = false
    private var lastQuickSearchHotkeyAt = Date.distantPast
    private var isModalInteractionActive = false
    private var isInEditMode = false  // Suppress auto-dismiss during editing
    private var isEditingAppNote = false
    private var isConfiguringApplicationMenu = false
    private var lastShowDockIcon: Bool?
    private var statusMenuScreenForNextOverlay: NSScreen?
    private var suppressReopenUntil = Date.distantPast
    private var overlayOpenedByQuickSearchOnly = false

    private lazy var overlayController = OverlayWindowController(
        dependencies: OverlayWindowController.Dependencies(
            shouldStageAsAccessory: { [weak self] in
                self?.shouldStageOverlayAsAccessory ?? false
            },
            isSettingsVisible: { [weak self] in
                self?.isSettingsVisible ?? false
            },
            settingsWindow: { [weak self] in
                self?.settingsWindow
            },
            canHideOverlay: { [weak self] in
                self?.isInEditMode == false
            },
            currentOverlayLevel: { [weak self] in
                self?.currentOverlayLevel ?? Self.overlayDefaultLevel
            },
            overlayLevel: { [weak self] initialQuickSearchSource in
                self?.overlayLevel(initialQuickSearchSource: initialQuickSearchSource) ?? Self.overlayDefaultLevel
            },
            makeContentView: { [weak self] initialQuickSearchSource in
                DismissibleHostingView(
                    rootView: ContentView(
                        hideOverlay: { [weak self] in
                            self?.hideOverlay(force: true)
                        },
                        initialQuickSearchSource: initialQuickSearchSource
                    ),
                    onBackdropTap: { [weak self] in
                        self?.hideOverlay()
                    }
                )
            },
            handleOverlayKeyEvent: { [weak self] event in
                self?.handleOverlayKeyEvent(event) ?? false
            },
            installOverlayKeyMonitor: { [weak self] in
                self?.installOverlayKeyMonitor()
            },
            removeOverlayKeyMonitor: { [weak self] in
                self?.removeOverlayKeyMonitor()
            },
            removeQuickSearchMouseMonitor: { [weak self] in
                Diagnostics.log("app.quickSearch.removeMouseMonitor", [
                    "quickSearchOpen": self?.isQuickSearchOpen,
                    "quickSearchOnlyOverlaySession": self?.quickSearchOnlyOverlaySession,
                    "quickSearchShouldHideOverlayOnClose": self?.quickSearchShouldHideOverlayOnClose
                ])
                self?.removeQuickSearchExternalMouseMonitor()
                self?.quickSearchShouldHideOverlayOnClose = false
                self?.quickSearchOnlyOverlaySession = false
            },
            detachSettingsWindow: { [weak self] window in
                self?.detachSettingsWindow(window)
            },
            prepareSettingsWindow: { [weak self] window in
                self?.prepareSettingsWindow(window)
            },
            refreshChromeState: { [weak self] activate, avoidSpaceSwitch in
                self?.refreshLauncherChromeState(activate: activate, avoidSpaceSwitch: avoidSpaceSwitch)
            },
            onWillHide: {
                TagDatabase.flushPendingCategorySchemeBackupBatch()
            },
            onDidHide: { [weak self] in
                self?.overlayOpenedByQuickSearchOnly = false
                NotificationCenter.default.post(name: .tagLauncherOverlayDidHide, object: nil)
            },
            onDidShow: {
                NotificationCenter.default.post(name: .tagLauncherOverlayDidShow, object: nil)
            }
        )
    )

    private var overlayWindow: NSWindow? {
        overlayController.window
    }

    private var overlayGeneration: Int {
        overlayController.generation
    }

    private var overlayAvoidsSpaceSwitch: Bool {
        get { overlayController.avoidsSpaceSwitch }
        set { overlayController.avoidsSpaceSwitch = newValue }
    }

    private var isOverlayVisible: Bool {
        overlayWindow?.isVisible == true
    }

    private var isSettingsVisible: Bool {
        settingsWindow?.isVisible == true
    }

    private var requiresForegroundOwnership: Bool {
        isOverlayVisible || isSettingsVisible
    }

    private var shouldStageOverlayAsAccessory: Bool {
        !isSettingsVisible && !UserDefaults.standard.bool(forKey: Self.showDockIconKey)
    }

    private var currentOverlayLevel: NSWindow.Level {
        if isEditingAppNote || isQuickSearchOpen {
            return Self.overlayTextInputLevel
        }
        return Self.overlayDefaultLevel
    }

    private func overlayLevel(initialQuickSearchSource: String? = nil) -> NSWindow.Level {
        if initialQuickSearchSource != nil {
            return Self.overlayTextInputLevel
        }
        return currentOverlayLevel
    }

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
        observeHotkeyStatusChanges()
        registerConfiguredHotkeys()
        observeOtherWindows()
        observeSettingsClose()
        observeEditMode()
        observeAppNoteEditing()
        observeQuickSearch()
        observePreferencesRequests()
        observeExternalActivationRequests()
        observeApplicationMenuChanges()
        observeChromeSettings()
        observeLanguageChanges()
        setupLaunchAtLogin()
        suppressReopenUntil = Date().addingTimeInterval(1.0)
        configureApplicationMenuWhenAvailable(retries: 200)
        warmAppIndexInBackground()
        relocalizeDefaultAppNotesForCurrentLanguageAsync()
    }

    /// Pre-scan application folders so the first App Grid open can hydrate from cache quickly.
    private func warmAppIndexInBackground() {
        DispatchQueue.global(qos: .utility).async {
            _ = AppIndexer.scan(useCache: true)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        configureApplicationMenuWhenAvailable(retries: 12)
    }

    /// Dock icon reopen is an explicit App Grid entry only when the user chooses to show the Dock icon.
    /// Duplicate-instance handoff suppresses this path so repeated launches do not show App Grid.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard Date() >= suppressReopenUntil else { return false }
        let lastDuplicateLaunch = UserDefaults.standard.double(forKey: Self.duplicateLaunchSuppressReopenKey)
        if lastDuplicateLaunch > 0,
           Date().timeIntervalSince1970 - lastDuplicateLaunch < 2.0 {
            suppressReopenUntil = Date().addingTimeInterval(1.0)
            return false
        }
        guard UserDefaults.standard.bool(forKey: Self.showDockIconKey) else { return false }
        guard isRecentUserClickNearDockArea() else { return false }
        showOrFocusOverlay()
        return false  // Suppress default "unhide all windows" behavior
    }

    private func isRecentUserClickNearDockArea() -> Bool {
        let lastMouseDown = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .leftMouseDown
        )
        let lastMouseUp = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .leftMouseUp
        )
        let recentMouseClick = min(lastMouseDown, lastMouseUp) < 1.2
        return recentMouseClick && isPointerNearDockArea()
    }

    private func isPointerNearDockArea() -> Bool {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.contains { screen in
            let frame = screen.frame
            let visible = screen.visibleFrame
            guard NSMouseInRect(mouse, frame, false) else { return false }
            let bottomDock = visible.minY > frame.minY
                && mouse.y >= frame.minY
                && mouse.y <= visible.minY + 24
            let leftDock = visible.minX > frame.minX
                && mouse.x >= frame.minX
                && mouse.x <= visible.minX + 24
            let rightDock = visible.maxX < frame.maxX
                && mouse.x <= frame.maxX
                && mouse.x >= visible.maxX - 24
            return bottomDock || leftDock || rightDock
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hideOverlay(force: true, discardWindow: true)
        unregisterHotkey(for: .main)
        unregisterHotkey(for: .quickSearch)
        TagDatabase.flushPendingCategorySchemeBackupBatch()
        removeOverlayKeyMonitor()
        removeQuickSearchExternalMouseMonitor()
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: Self.externalActivationNotification,
            object: Self.externalActivationObject
        )
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
            lastShowDockIcon = showDock
            refreshLauncherChromeState()
        }

        if force {
            setupMenuBar()
        }
    }

    private func beginLauncherForegroundOwnership(activate: Bool = true, keyWindow: NSWindow? = nil) {
        let showDock = UserDefaults.standard.bool(forKey: Self.showDockIconKey)
        let desiredPolicy: NSApplication.ActivationPolicy = showDock ? .regular : .accessory
        if NSApp.activationPolicy() != desiredPolicy {
            NSApp.setActivationPolicy(desiredPolicy)
        }
        if activate, showDock {
            claimLauncherForeground(keyWindow: keyWindow)
        } else if activate {
            NSApp.activate(ignoringOtherApps: true)
            keyWindow?.makeKeyAndOrderFront(nil)
            keyWindow?.orderFrontRegardless()
        }
    }

    private func claimLauncherForeground(
        keyWindow: NSWindow? = nil,
        retries: Int = 0,
        overlayGeneration expectedOverlayGeneration: Int? = nil
    ) {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }

        if isOverlayVisible && !NSApp.presentationOptions.contains(.hideDock) {
            NSApp.presentationOptions = [.hideDock]
        }

        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)

        if let keyWindow, keyWindow.isVisible {
            keyWindow.makeKeyAndOrderFront(nil)
            keyWindow.makeMain()
            keyWindow.orderFrontRegardless()
        }
        configureApplicationMenuWhenAvailable(retries: 4)

        let overlayShouldYieldToSettings = keyWindow == overlayWindow && isSettingsVisible
        let keyWindowStillNeedsFocus = !overlayShouldYieldToSettings
            && keyWindow?.isVisible == true
            && keyWindow?.isKeyWindow == false
        let shouldRetry = !NSApp.isActive
            || !NSApp.presentationOptions.contains(.hideDock)
            || keyWindowStillNeedsFocus
        guard retries > 0, isOverlayVisible else { return }
        guard shouldRetry else { return }

        let retryWindow = keyWindow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self, self.isOverlayVisible else { return }
            if let expectedOverlayGeneration,
               expectedOverlayGeneration != self.overlayGeneration {
                return
            }
            self.refreshLauncherChromeState()
            self.claimLauncherForeground(
                keyWindow: retryWindow,
                retries: retries - 1,
                overlayGeneration: expectedOverlayGeneration
            )
        }
    }

    private func refreshLauncherChromeState(activate: Bool = false, avoidSpaceSwitch: Bool = false) {
        let showDock = UserDefaults.standard.bool(forKey: Self.showDockIconKey)
        lastShowDockIcon = showDock

        let shouldStayAccessoryForCurrentFullscreenSpace = isOverlayVisible
            && (avoidSpaceSwitch || overlayAvoidsSpaceSwitch)
        let shouldStayAccessoryForHiddenDockChrome = requiresForegroundOwnership
            && !showDock
        let shouldStayAccessoryForQuickOnlySearch = isOverlayVisible
            && quickSearchOnlyOverlaySession
            && !showDock
        let desiredPolicy: NSApplication.ActivationPolicy = shouldStayAccessoryForCurrentFullscreenSpace
            ? .accessory
            : (shouldStayAccessoryForHiddenDockChrome ? .accessory
            : (shouldStayAccessoryForQuickOnlySearch ? .accessory
            : (requiresForegroundOwnership
            ? .regular
            : (showDock ? .regular : .accessory))))
        if NSApp.activationPolicy() != desiredPolicy {
            NSApp.setActivationPolicy(desiredPolicy)
        }

        let desiredPresentation: NSApplication.PresentationOptions = isOverlayVisible ? [.hideDock] : []
        if NSApp.presentationOptions != desiredPresentation {
            NSApp.presentationOptions = desiredPresentation
        }

        if activate && requiresForegroundOwnership
            && !shouldStayAccessoryForCurrentFullscreenSpace
            && !shouldStayAccessoryForHiddenDockChrome
            && !shouldStayAccessoryForQuickOnlySearch {
            let keyWindow = isSettingsVisible ? settingsWindow : (isOverlayVisible ? overlayWindow : nil)
            claimLauncherForeground(
                keyWindow: keyWindow,
                retries: isOverlayVisible && !isSettingsVisible ? 5 : 0,
                overlayGeneration: isOverlayVisible ? overlayGeneration : nil
            )
        }
    }

    private func handleApplicationDidResignActive() {
        guard !isOverlayVisible else {
            return
        }

        if isQuickSearchOpen {
            NotificationCenter.default.post(
                name: .tagLauncherQuickSearchDismissRequested,
                object: nil,
                userInfo: ["source": QuickSearchDismissSource.programmatic]
            )
        }

        if !requiresForegroundOwnership {
            refreshLauncherChromeState()
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
            self?.relocalizeDefaultAppNotesForCurrentLanguageAsync()
        }
    }

    private func relocalizeDefaultAppNotesForCurrentLanguageAsync() {
        DispatchQueue.global(qos: .utility).async {
            let apps = AppIndexer.scan(useCache: true)
            let appleChanged = AppleDefaultAppCatalog.relocalizeDefaultNotesForCurrentLanguage(apps: apps)
            let smartStartChanged = SmartStartService.relocalizeDefaultNotesForCurrentLanguage(apps: apps)
            guard appleChanged || smartStartChanged else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .tagLauncherDataDidChange, object: nil)
            }
        }
    }

    // MARK: - Launch at Login (LaunchAgent, zero permissions)

    private static let launchAgentLabel = AppIdentity.launchAgentLabel
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
            "ProgramArguments": Self.expectedLaunchAgentProgramArguments(),
            "RunAtLoad": true,
        ]
        let dir = Self.launchAgentURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        (plist as NSDictionary).write(to: Self.launchAgentURL, atomically: true)

        let uid = getuid()
        let bootoutTask = Process()
        bootoutTask.launchPath = "/bin/launchctl"
        bootoutTask.arguments = ["bootout", "gui/\(uid)/\(Self.launchAgentLabel)"]
        try? bootoutTask.run()
        bootoutTask.waitUntilExit()

        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["bootstrap", "gui/\(uid)", Self.launchAgentURL.path]
        try? task.run()
    }

    static func disableLaunchAtLogin() {
        guard supportsLaunchAtLogin else { return }
        let uid = getuid()
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = ["bootout", "gui/\(uid)/\(Self.launchAgentLabel)"]
        try? task.run()
        try? FileManager.default.removeItem(at: Self.launchAgentURL)
    }

    private static func launchAgentProgramArguments() -> [String]? {
        guard let plist = NSDictionary(contentsOf: Self.launchAgentURL) as? [String: Any] else {
            return nil
        }
        return plist["ProgramArguments"] as? [String]
    }

    private static func expectedLaunchAgentProgramArguments() -> [String] {
        let executablePath = Bundle.main.executablePath
            ?? Bundle.main.bundleURL
                .appendingPathComponent("Contents/MacOS/\(AppIdentity.displayName)")
                .path
        return [executablePath, "--hide"]
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
        guard UserDefaults.standard.bool(forKey: key) else {
            Self.disableLaunchAtLogin()
            return
        }

        let expectedArguments = Self.expectedLaunchAgentProgramArguments()
        if !AppDefaults.hasStoredValue(for: key)
            || Self.launchAgentProgramArguments() != expectedArguments {
            Self.enableLaunchAtLogin()
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        } else {
            statusItem?.length = NSStatusItem.squareLength
        }
        guard let statusItem else { return }
        statusItem.autosaveName = Self.statusItemAutosaveName
        statusItem.isVisible = true

        if let button = statusItem.button {
            button.identifier = Self.statusItemButtonIdentifier
            button.setAccessibilityIdentifier(Self.statusItemAutosaveName)
            button.setAccessibilityLabel(Self.statusItemAccessibilityLabel)
            button.image = makeMenuBarIcon()
            button.imageScaling = .scaleProportionallyDown
            button.imagePosition = .imageOnly
            button.toolTip = "TagLauncher — Tag-based app launcher"
            button.action = #selector(toggleOverlay(_:))
            button.target = self
        }

        let menu = NSMenu()
        menu.delegate = self
        let showItem = NSMenuItem(
            title: showAppListMenuTitle,
            action: #selector(toggleOverlayFromStatusMenu(_:)),
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
            action: #selector(openPreferences(_:)),
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

    func menuWillOpen(_ menu: NSMenu) {
        statusMenuScreenForNextOverlay = overlayController.screenContainingCurrentPointer()
            ?? statusItem?.button?.window?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    func menuDidClose(_ menu: NSMenu) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.statusMenuScreenForNextOverlay = nil
        }
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
        if LauncherHotkeyRegistrationStore.state(for: .main) == .failed {
            return tr("menu.showShortcutUnavailable")
        }
        return "\(tr("menu.showAppList"))  \(LauncherHotkey.main.displayString)"
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
            self.configureHelpMenu()
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
        item.action = #selector(toggleOverlayFromStatusMenu(_:))
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
        item.action = #selector(openPreferences(_:))
        item.target = self
        item.keyEquivalent = ","
        item.keyEquivalentModifierMask = .command
        item.isEnabled = true
    }

    private func isSettingsMenuItem(_ item: NSMenuItem) -> Bool {
        item.action == Selector(("showSettingsWindow:"))
            || item.action == #selector(openPreferences(_:))
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

    private func configureHelpMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }
        NSApp.helpMenu = nil

        for item in mainMenu.items.reversed() {
            let isHelpMenu = item.identifier == Self.helpMenuItemIdentifier
                || item.title.localizedCaseInsensitiveContains("help")
                || item.title == tr("menu.help")
                || item.submenu?.title.localizedCaseInsensitiveContains("help") == true
                || item.submenu?.title == tr("menu.help")
            if isHelpMenu {
                mainMenu.removeItem(item)
            }
        }

        let menuItem = NSMenuItem(title: tr("menu.help"), action: nil, keyEquivalent: "")
        let helpMenu = NSMenu(title: tr("menu.help"))
        menuItem.identifier = Self.helpMenuItemIdentifier
        menuItem.submenu = helpMenu

        let downloadItem = NSMenuItem()
        downloadItem.identifier = Self.downloadHelpMenuItemIdentifier
        downloadItem.title = tr("help.downloadPDF")
        downloadItem.action = #selector(openLocalizedHelp(_:))
        downloadItem.target = self
        downloadItem.keyEquivalent = ""
        downloadItem.keyEquivalentModifierMask = []
        downloadItem.isEnabled = true
        helpMenu.addItem(downloadItem)
        mainMenu.addItem(menuItem)
    }

    @objc private func openLocalizedHelp(_ sender: Any? = nil) {
        NSWorkspace.shared.open(HelpDocument.currentURL)
    }

    private func removeMenuBarItem() {
        guard let statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    // MARK: - Overlay Window

    @objc func toggleOverlay(_ sender: Any) {
        performToggleOverlay(preferredScreen: nil)
    }

    @objc func toggleOverlayFromStatusMenu(_ sender: Any) {
        let preferredScreen = statusMenuScreenForNextOverlay
        statusMenuScreenForNextOverlay = nil
        DispatchQueue.main.async { [weak self] in
            self?.performToggleOverlay(preferredScreen: preferredScreen)
        }
    }

    private func performToggleOverlay(preferredScreen: NSScreen?) {
        overlayOpenedByQuickSearchOnly = false
        overlayController.toggle(preferredScreen: preferredScreen)
    }

    private func showOrFocusOverlay(preferredScreen: NSScreen? = nil) {
        overlayOpenedByQuickSearchOnly = false
        overlayController.showOrFocus(preferredScreen: preferredScreen)
    }

    private func showOverlay(
        initialQuickSearchSource: String? = nil,
        preferredScreen: NSScreen? = nil,
        stagedForAllSpaces: Bool = false
    ) {
        Diagnostics.log("app.overlay.showRequest", [
            "initialQuickSearchSource": initialQuickSearchSource,
            "stagedForAllSpaces": stagedForAllSpaces,
            "isQuickSearchOpen": isQuickSearchOpen,
            "quickSearchOnlyOverlaySession": quickSearchOnlyOverlaySession,
            "overlayOpenedByQuickSearchOnly": overlayOpenedByQuickSearchOnly
        ])
        if initialQuickSearchSource == QuickSearchOpenSource.globalHidden {
            isQuickSearchOpen = true
            quickSearchShouldHideOverlayOnClose = true
            quickSearchOnlyOverlaySession = true
            overlayOpenedByQuickSearchOnly = true
        } else if initialQuickSearchSource == nil {
            overlayOpenedByQuickSearchOnly = false
        }
        overlayController.show(
            initialQuickSearchSource: initialQuickSearchSource,
            preferredScreen: preferredScreen,
            stagedForAllSpaces: stagedForAllSpaces
        )
    }

    private func installOverlayKeyMonitor() {
        guard overlayKeyMonitor == nil else { return }
        overlayKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.handleOverlayKeyEvent(event) {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleOverlayKeyEvent(_ event: NSEvent) -> Bool {
        guard event.type == .keyDown else { return false }

        if event.keyCode == UInt16(kVK_Escape),
           isQuickSearchOpen || quickSearchOnlyOverlaySession {
            return handleOverlayEscapeKey()
        }

        guard shouldHandleOverlayKeyEvent(event) else { return false }

        if event.keyCode == UInt16(kVK_Escape) {
            return handleOverlayEscapeKey()
        }
        if shouldOpenQuickSearch(for: event) {
            requestQuickSearch(source: QuickSearchOpenSource.mainOverlay)
            return true
        }
        return false
    }

    private func handleOverlayEscapeKey() -> Bool {
        if isQuickSearchOpen || quickSearchOnlyOverlaySession {
            dismissQuickSearchFromKeyboard()
            return true
        }
        guard !isSettingsVisible,
              !isEditingAppNote,
              !isModalInteractionActive
        else { return false }
        hideOverlay(force: true)
        return true
    }

    private func dismissQuickSearchFromKeyboard() {
        let shouldHideOverlayAfterDismiss = quickSearchShouldHideOverlayOnClose || quickSearchOnlyOverlaySession
        isQuickSearchOpen = false
        removeQuickSearchExternalMouseMonitor()
        updateOverlayLevelForTextInput()
        NotificationCenter.default.post(
            name: .tagLauncherQuickSearchDismissRequested,
            object: nil,
            userInfo: ["source": QuickSearchDismissSource.keyboard]
        )
        if shouldHideOverlayAfterDismiss {
            quickSearchShouldHideOverlayOnClose = false
            quickSearchOnlyOverlaySession = false
            overlayOpenedByQuickSearchOnly = true
            DispatchQueue.main.async { [weak self] in
                self?.hideOverlay(force: true, discardWindow: true)
            }
        }
    }

    private func requestQuickSearch(source: String) {
        isQuickSearchOpen = true
        quickSearchShouldHideOverlayOnClose = quickSearchShouldHideOverlayOnClose
            || source == QuickSearchOpenSource.globalHidden
        quickSearchOnlyOverlaySession = quickSearchOnlyOverlaySession
            || source == QuickSearchOpenSource.globalHidden
        if source == QuickSearchOpenSource.globalHidden {
            overlayOpenedByQuickSearchOnly = true
        }
        promoteOverlayToForegroundInput()
        updateOverlayLevelForTextInput()
        installQuickSearchExternalMouseMonitor()
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .tagLauncherQuickSearchRequested,
                object: nil,
                userInfo: ["source": source]
            )
        }
    }

    private func shouldHandleOverlayKeyEvent(_ event: NSEvent) -> Bool {
        guard overlayWindow?.isVisible == true else { return false }
        if !isSettingsVisible && NSApp.isActive {
            return true
        }
        if event.window == overlayWindow { return true }
        return event.window == nil && NSApp.keyWindow == overlayWindow
    }

    private func shouldOpenQuickSearch(for event: NSEvent) -> Bool {
        guard event.keyCode == UInt16(kVK_Space),
              !event.isARepeat,
              event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty,
              overlayWindow?.isVisible == true,
              !isQuickSearchOpen,
              !isInEditMode,
              !isEditingAppNote,
              !isModalInteractionActive
        else { return false }

        return true
    }

    private func removeOverlayKeyMonitor() {
        if let monitor = overlayKeyMonitor {
            NSEvent.removeMonitor(monitor)
            overlayKeyMonitor = nil
        }
    }

    private func hideOverlay(force: Bool = false, discardWindow: Bool = false) {
        Diagnostics.log("app.overlay.hideRequest", [
            "force": force,
            "discardWindow": discardWindow,
            "isQuickSearchOpen": isQuickSearchOpen,
            "quickSearchOnlyOverlaySession": quickSearchOnlyOverlaySession,
            "quickSearchShouldHideOverlayOnClose": quickSearchShouldHideOverlayOnClose,
            "overlayOpenedByQuickSearchOnly": overlayOpenedByQuickSearchOnly
        ])
        overlayController.hide(force: force, discardWindow: discardWindow)
    }

    // MARK: - Global Hotkeys

    private func registerConfiguredHotkeys() {
        installHotkeyEventHandlerIfNeeded()
        registerFixedHotkey(.main)
        registerFixedHotkey(.quickSearch)
    }

    private func registerFixedHotkey(_ kind: LauncherHotkeyKind) {
        unregisterHotkey(for: kind)
        let hotkey = kind.hotkey

        var hotkeyID = EventHotKeyID()
        hotkeyID.signature = OSType(0x41505447) // 'APTG'
        hotkeyID.id = kind.eventID

        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode,
            hotkey.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &newRef
        )

        if status == noErr, let newRef {
            setHotkeyRef(newRef, for: kind)
            LauncherHotkeyRegistrationStore.setActive(for: kind)
        } else {
            setHotkeyRef(nil, for: kind)
            LauncherHotkeyRegistrationStore.setFailed(status, for: kind)
            print("[TagLauncher] Fixed hotkey registration failed for \(kind.rawValue): \(status)")
        }
    }

    private func observeHotkeyStatusChanges() {
        NotificationCenter.default.addObserver(
            forName: .tagLauncherHotkeyRegistrationChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupMenuBar()
            self?.configureApplicationMenuWhenAvailable(retries: 2)
        }
    }

    private func installHotkeyEventHandlerIfNeeded() {
        guard !hotkeyEventHandlerInstalled else { return }
        hotkeyEventHandlerInstalled = true

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let event, let userData else { return noErr }
                var hotkeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                guard status == noErr else { return noErr }

                let delegate = Unmanaged<AppDelegate>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                DispatchQueue.main.async {
                    delegate.handleHotkeyEvent(id: hotkeyID.id)
                }
                return noErr
            },
            1,
            &eventSpec,
            selfPtr,
            nil
        )
    }

    private func handleHotkeyEvent(id: UInt32) {
        Diagnostics.log("app.hotkey", [
            "id": id,
            "isOverlayVisible": isOverlayVisible,
            "isQuickSearchOpen": isQuickSearchOpen,
            "quickSearchOnlyOverlaySession": quickSearchOnlyOverlaySession,
            "overlayOpenedByQuickSearchOnly": overlayOpenedByQuickSearchOnly
        ])
        if id == LauncherHotkeyKind.quickSearch.eventID {
            showQuickSearchFromGlobalHotkey()
        } else {
            performToggleOverlay(preferredScreen: nil)
        }
    }

    private func showQuickSearchFromGlobalHotkey() {
        let now = Date()
        if overlayWindow?.isVisible == true,
           isQuickSearchOpen || quickSearchOnlyOverlaySession || overlayOpenedByQuickSearchOnly {
            lastQuickSearchHotkeyAt = now
            if isQuickSearchOpen || quickSearchOnlyOverlaySession {
                dismissQuickSearchFromKeyboard()
            } else {
                hideOverlay(force: true)
            }
            return
        }

        if now.timeIntervalSince(lastQuickSearchHotkeyAt) < 0.28 {
            promoteOverlayToForegroundInput()
            updateOverlayLevelForTextInput()
            return
        }
        lastQuickSearchHotkeyAt = now

        if overlayWindow?.isVisible == true {
            refreshLauncherChromeState(
                activate: !overlayAvoidsSpaceSwitch,
                avoidSpaceSwitch: overlayAvoidsSpaceSwitch
            )
            requestQuickSearch(source: QuickSearchOpenSource.globalVisible)
            return
        }
        isQuickSearchOpen = true
        quickSearchShouldHideOverlayOnClose = true
        quickSearchOnlyOverlaySession = true
        showOverlay(initialQuickSearchSource: QuickSearchOpenSource.globalHidden)
    }

    private func hotkeyRef(for kind: LauncherHotkeyKind) -> EventHotKeyRef? {
        switch kind {
        case .main: return mainHotkeyRef
        case .quickSearch: return quickSearchHotkeyRef
        }
    }

    private func setHotkeyRef(_ ref: EventHotKeyRef?, for kind: LauncherHotkeyKind) {
        switch kind {
        case .main: mainHotkeyRef = ref
        case .quickSearch: quickSearchHotkeyRef = ref
        }
    }

    private func unregisterHotkey(for kind: LauncherHotkeyKind) {
        if let ref = hotkeyRef(for: kind) {
            UnregisterEventHotKey(ref)
            setHotkeyRef(nil, for: kind)
        }
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

            if self.isSettingsOwnedPanel(keyWindow) {
                return
            }

            if self.isMenuTrackingWindow(keyWindow) {
                return
            }

            if self.isAppOwnedDocumentWindow(keyWindow) {
                self.prepareSettingsWindow(keyWindow)
                return
            }

            if NSApp.windows.contains(keyWindow) {
                return
            }

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
        dismissQuickSearchIfNeeded()
        let settingsSize = NSSize(width: 1000, height: 480)
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
        if overlayAvoidsSpaceSwitch {
            behavior.remove(.moveToActiveSpace)
            behavior.formUnion([.fullScreenAuxiliary, .stationary, .transient, .ignoresCycle])
        } else {
            behavior.formUnion([.fullScreenAuxiliary, .moveToActiveSpace])
        }
        window.collectionBehavior = behavior
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        settingsWindow = window
        refreshLauncherChromeState(
            activate: !overlayAvoidsSpaceSwitch,
            avoidSpaceSwitch: overlayAvoidsSpaceSwitch
        )
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
        if isAppOwnedDocumentWindow(window) { return true }
        guard NSApp.windows.contains(window),
              window != overlayWindow,
              window.isVisible,
              !(window is NSPanel)
        else { return false }
        return settingsWindowTitleCandidates().contains(normalizedWindowTitle(window.title))
    }

    private func isAppOwnedDocumentWindow(_ window: NSWindow) -> Bool {
        NSApp.windows.contains(window)
            && window != overlayWindow
            && window.isVisible
            && !(window is NSPanel)
            && !isMenuTrackingWindow(window)
            && window.styleMask.contains(.titled)
    }

    private func isMenuTrackingWindow(_ window: NSWindow) -> Bool {
        let className = NSStringFromClass(type(of: window))
        return className.localizedCaseInsensitiveContains("Menu")
            || className.localizedCaseInsensitiveContains("Popup")
    }

    private func settingsWindowTitleCandidates() -> Set<String> {
        let keys = [
            "menu.preferences",
            "settings.language",
            "settings.general",
            "quickSearch.hotkeys",
            "settings.tags",
            "settings.data",
            "settings.about"
        ]
        return Set(keys.map { normalizedWindowTitle(tr($0)) })
    }

    private func normalizedWindowTitle(_ title: String) -> String {
        title
            .replacingOccurrences(of: "…", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isSettingsOwnedPanel(_ window: NSWindow) -> Bool {
        guard window is NSPanel else { return false }
        if window is NSSavePanel { return true }
        guard let settingsWindow else { return false }
        return window.sheetParent == settingsWindow
            || settingsWindow.attachedSheet == window
            || window.parent == settingsWindow
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
        overlayController.screenUnderMouse()
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
            let shouldRefocusOverlay = self.isOverlayVisible
            let preferredScreen = self.overlayWindow?.screen
            self.detachSettingsWindow(closingWindow)
            self.settingsWindow = nil
            self.refreshLauncherChromeState(
                activate: shouldRefocusOverlay && !self.overlayAvoidsSpaceSwitch,
                avoidSpaceSwitch: self.overlayAvoidsSpaceSwitch
            )
            guard shouldRefocusOverlay else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.showOrFocusOverlay(preferredScreen: preferredScreen)
            }
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

    /// Keep text-input overlays at the launcher level so Quick Search stays visible in fullscreen Spaces.
    private func observeAppNoteEditing() {
        NotificationCenter.default.addObserver(
            forName: .tagLauncherAppNoteEditingChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.isEditingAppNote = (notification.userInfo?["active"] as? Bool) ?? false
            if self.isEditingAppNote {
                self.promoteOverlayToForegroundInput()
            }
            self.updateOverlayLevelForTextInput()
        }
    }

    private func promoteOverlayToForegroundInput() {
        if overlayAvoidsSpaceSwitch {
            refreshLauncherChromeState(activate: false, avoidSpaceSwitch: true)
            guard let overlayWindow else { return }
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.orderFrontRegardless()
            return
        }
        if quickSearchOnlyOverlaySession && !UserDefaults.standard.bool(forKey: Self.showDockIconKey) {
            refreshLauncherChromeState(activate: false)
            guard let overlayWindow else { return }
            NSApp.activate(ignoringOtherApps: true)
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.orderFrontRegardless()
            return
        }
        beginLauncherForegroundOwnership()
        guard let overlayWindow else { return }
        overlayWindow.makeKeyAndOrderFront(nil)
        overlayWindow.orderFrontRegardless()
    }

    private func observeQuickSearch() {
        NotificationCenter.default.addObserver(
            forName: .tagLauncherQuickSearchVisibilityChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let active = (notification.userInfo?["active"] as? Bool) ?? false
            let hideOverlayOnClose = (notification.userInfo?["hideOverlayOnClose"] as? Bool) ?? false
            let wasQuickSearchOnlyOverlay = self.quickSearchOnlyOverlaySession
                || self.quickSearchShouldHideOverlayOnClose
                || self.overlayOpenedByQuickSearchOnly
            Diagnostics.log("app.quickSearch.visibilityChanged", [
                "active": active,
                "hideOverlayOnClose": hideOverlayOnClose,
                "isQuickSearchOpenBefore": self.isQuickSearchOpen,
                "quickSearchOnlyOverlaySessionBefore": self.quickSearchOnlyOverlaySession,
                "quickSearchShouldHideOverlayOnCloseBefore": self.quickSearchShouldHideOverlayOnClose,
                "overlayOpenedByQuickSearchOnlyBefore": self.overlayOpenedByQuickSearchOnly,
                "wasQuickSearchOnlyOverlay": wasQuickSearchOnlyOverlay
            ])
            self.isQuickSearchOpen = active
            if active, hideOverlayOnClose {
                self.quickSearchShouldHideOverlayOnClose = true
                self.quickSearchOnlyOverlaySession = true
                self.overlayOpenedByQuickSearchOnly = true
            }
            if self.isQuickSearchOpen {
                self.promoteOverlayToForegroundInput()
            }
            self.updateOverlayLevelForTextInput()
            if self.isQuickSearchOpen {
                self.installQuickSearchExternalMouseMonitor()
            } else {
                self.removeQuickSearchExternalMouseMonitor()
                if hideOverlayOnClose || wasQuickSearchOnlyOverlay {
                    self.quickSearchShouldHideOverlayOnClose = false
                    self.quickSearchOnlyOverlaySession = false
                    self.hideOverlay(force: true, discardWindow: wasQuickSearchOnlyOverlay)
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .tagLauncherModalInteractionChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.isModalInteractionActive = (notification.userInfo?["active"] as? Bool) ?? false
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            self?.handleApplicationDidResignActive()
        }
    }

    private func installQuickSearchExternalMouseMonitor() {
        installQuickSearchLocalMouseMonitor()
        guard quickSearchExternalMouseMonitor == nil else { return }
        quickSearchExternalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard self?.isQuickSearchOpen == true else { return }
                NotificationCenter.default.post(
                    name: .tagLauncherQuickSearchDismissRequested,
                    object: nil,
                    userInfo: ["source": QuickSearchDismissSource.mouse]
                )
            }
        }
    }

    private func installQuickSearchLocalMouseMonitor() {
        guard quickSearchLocalMouseMonitor == nil else { return }
        quickSearchLocalMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            guard let self, self.isQuickSearchOpen else { return event }
            if event.window === self.overlayWindow {
                NotificationCenter.default.post(
                    name: .tagLauncherQuickSearchDismissRequested,
                    object: nil,
                    userInfo: ["source": QuickSearchDismissSource.mouse]
                )
                return nil
            }
            return event
        }
    }

    private func removeQuickSearchExternalMouseMonitor() {
        if let quickSearchLocalMouseMonitor {
            NSEvent.removeMonitor(quickSearchLocalMouseMonitor)
            self.quickSearchLocalMouseMonitor = nil
        }
        if let quickSearchExternalMouseMonitor {
            NSEvent.removeMonitor(quickSearchExternalMouseMonitor)
            self.quickSearchExternalMouseMonitor = nil
        }
    }

    private func updateOverlayLevelForTextInput() {
        guard let overlayWindow else { return }
        overlayWindow.level = currentOverlayLevel
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

    private func observeExternalActivationRequests() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleExternalActivationRequest(_:)),
            name: Self.externalActivationNotification,
            object: Self.externalActivationObject
        )
    }

    @objc private func handleExternalActivationRequest(_ notification: Notification) {
        let shouldShowOverlay = notification.userInfo?["showOverlay"] as? Bool ?? false
        guard shouldShowOverlay else {
            suppressReopenUntil = Date().addingTimeInterval(1.0)
            return
        }
        showOrFocusOverlay()
    }

    @objc private func openPreferences(_ sender: Any? = nil) {
        dismissQuickSearchIfNeeded()
        TagDatabase.flushPendingCategorySchemeBackupBatch()
        if overlayAvoidsSpaceSwitch {
            refreshLauncherChromeState(activate: false, avoidSpaceSwitch: true)
        } else {
            beginLauncherForegroundOwnership()
        }
        // Don't hide overlay — keep it visible for real-time setting preview.
        if let overlayWindow, overlayWindow.isVisible {
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.orderFrontRegardless()
        }

        if let settingsWindow {
            prepareSettingsWindow(settingsWindow)
            return
        }

        let settingsSize = NSSize(width: 1000, height: 480)
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

    private func dismissQuickSearchIfNeeded() {
        guard isQuickSearchOpen else { return }
        isQuickSearchOpen = false
        removeQuickSearchExternalMouseMonitor()
        updateOverlayLevelForTextInput()
        quickSearchShouldHideOverlayOnClose = false
        quickSearchOnlyOverlaySession = false
        NotificationCenter.default.post(
            name: .tagLauncherQuickSearchDismissRequested,
            object: nil,
            userInfo: ["source": QuickSearchDismissSource.programmatic]
        )
    }

    @objc private func switchLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        L10n.switchTo(code)
    }
}

// MARK: - NSView-level backdrop dismiss (works even if SwiftUI rendering is slow)

final class DismissibleHostingView<Content: View>: NSHostingView<Content> {
    private let onBackdropTap: () -> Void
    private var modalInteractionSuppressesBackdropDismiss = false
    private var quickSearchSuppressesBackdropDismiss = false
    private var modalInteractionObserver: NSObjectProtocol?
    private var quickSearchVisibilityObserver: NSObjectProtocol?

    private var suppressBackdropDismiss: Bool {
        modalInteractionSuppressesBackdropDismiss || quickSearchSuppressesBackdropDismiss
    }

    @MainActor required init(rootView: Content) {
        self.onBackdropTap = {}
        super.init(rootView: rootView)
        installWindowServerAnchorLayer()
        observeBackdropDismissSuppressionChanges()
    }

    init(rootView: Content, onBackdropTap: @escaping () -> Void) {
        self.onBackdropTap = onBackdropTap
        super.init(rootView: rootView)
        installWindowServerAnchorLayer()
        observeBackdropDismissSuppressionChanges()
    }

    deinit {
        if let modalInteractionObserver {
            NotificationCenter.default.removeObserver(modalInteractionObserver)
        }
        if let quickSearchVisibilityObserver {
            NotificationCenter.default.removeObserver(quickSearchVisibilityObserver)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func installWindowServerAnchorLayer() {
        wantsLayer = true
        // A near-transparent backing pixel makes the WindowServer publish the panel immediately.
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.001).cgColor
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard let hit = hitTest(location) else {
            super.mouseDown(with: event)
            return
        }
        if hit == self {
            if quickSearchSuppressesBackdropDismiss {
                NotificationCenter.default.post(
                    name: .tagLauncherQuickSearchDismissRequested,
                    object: nil,
                    userInfo: ["source": QuickSearchDismissSource.backdrop]
                )
                return
            }
            if suppressBackdropDismiss {
                super.mouseDown(with: event)
                return
            }
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

    private func observeBackdropDismissSuppressionChanges() {
        modalInteractionObserver = NotificationCenter.default.addObserver(
            forName: .tagLauncherModalInteractionChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.modalInteractionSuppressesBackdropDismiss = (notification.userInfo?["active"] as? Bool) ?? false
        }

        quickSearchVisibilityObserver = NotificationCenter.default.addObserver(
            forName: .tagLauncherQuickSearchVisibilityChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.quickSearchSuppressesBackdropDismiss = (notification.userInfo?["active"] as? Bool) ?? false
        }
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
