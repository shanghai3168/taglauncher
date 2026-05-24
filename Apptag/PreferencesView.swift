import SwiftUI
import AppKit

// MARK: - Preferences View

struct PreferencesView: View {
    private let settingsWindowWidth: CGFloat = 880
    private let settingsContentWidth: CGFloat = 820
    private let generalContentWidth: CGFloat = 720
    private let generalLabelWidth: CGFloat = 190
    private let generalControlWidth: CGFloat = 500
    private let compactPickerWidth: CGFloat = 320
    private let dataPanelWidth: CGFloat = 760
    private let dataLabelWidth: CGFloat = 220
    private let dataActionWidth: CGFloat = 112

    @AppStorage("tagFontSize") private var tagFontSize: Double = AppDefaults.tagFontSize
    @AppStorage("iconSize") private var iconSize: Double = AppDefaults.iconSize
    @AppStorage("tagPosition") private var tagPosition = AppDefaults.tagPosition
    @AppStorage("defaultGroupName") private var defaultGroupName = "Other"
    @AppStorage("displayMode") private var displayMode = AppDefaults.displayMode
    @AppStorage("hideAppNames") private var hideAppNames = AppDefaults.hideAppNames
    @AppStorage("showDockIcon") private var showDockIcon = AppDefaults.showDockIcon
    @AppStorage("launchAtLogin") private var launchAtLogin = AppDefaults.launchAtLogin
    @AppStorage("showUncommonAppBubbles") private var showUncommonAppBubbles = AppDefaults.showUncommonAppBubbles
    @AppStorage("mainHotkeyRegistrationState") private var mainHotkeyRegistrationState = LauncherHotkeyRegistrationState.active.rawValue
    @AppStorage("quickSearchHotkeyRegistrationState") private var quickSearchHotkeyRegistrationState = LauncherHotkeyRegistrationState.active.rawValue
    @State private var selectedLanguage = L10n.selectedLanguageCode
    @State private var isRefreshingLanguage = false
    @State private var allApps: [AppInfo] = []
    @State private var tagColors: [String: Int] = [:]
    @State private var categoryScheme = TagDatabase.CategorySchemeState()
    @State private var isApplyingSystemScheme = false
    @State private var showApplySystemSchemeConfirmation = false
    @State private var isDataFilePanelPresented = false
    @State private var hotkeyStatusToast: String? = nil
    @State private var hotkeyStatusToastToken: UUID? = nil

    private func scanApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            var apps = AppIndexer.scan()
            let store = TagDatabase.loadWithEnsuredCategoryScheme()
            apps = TagEditor.annotate(apps: apps)
            let colors = store.tags.mapValues { $0.color }
            DispatchQueue.main.async {
                allApps = apps
                tagColors = colors
                categoryScheme = store.categoryScheme
            }
        }
    }

    private func refreshDataState() {
        categoryScheme = TagDatabase.loadWithEnsuredCategoryScheme().categoryScheme
    }

    private func exportTags() {
        guard prepareDataFilePanelPresentation() else { return }
        DispatchQueue.main.async {
            TagDatabase.flushPendingCategorySchemeBackupBatch()
            let currentScheme = TagDatabase.loadWithEnsuredCategoryScheme().categoryScheme
            categoryScheme = currentScheme

            let panel = NSSavePanel()
            panel.title = tr("settings.export")
            panel.nameFieldStringValue = TagDatabase.exportFileName(for: currentScheme)
            panel.allowedContentTypes = [.json]

            beginFilePanel(panel) { response in
                finishDataFilePanelPresentation()
                guard response == .OK, let url = panel.url else { return }
                do {
                    try TagDatabase.exportTo(url)
                } catch {
                    fputs("[TagLauncher] Export failed: \(error)\n", stderr)
                    showDataAlert(title: tr("settings.exportFailed"), message: error.localizedDescription)
                }
            }
        }
    }

    private func importTags() {
        guard prepareDataFilePanelPresentation() else { return }
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.title = tr("settings.import")
            panel.allowedContentTypes = [.json]
            panel.allowsMultipleSelection = false

            beginFilePanel(panel) { response in
                finishDataFilePanelPresentation()
                guard response == .OK, let url = panel.url else { return }
                do {
                    TagDatabase.flushPendingCategorySchemeBackupBatch()
                    _ = try TagDatabase.importFrom(url)
                    scanApps()
                    refreshDataState()
                    notifyDataChanged()
                } catch {
                    fputs("[TagLauncher] Import failed: \(error)\n", stderr)
                    showDataAlert(title: tr("settings.importFailed"), message: error.localizedDescription)
                }
            }
        }
    }

    private func prepareDataFilePanelPresentation() -> Bool {
        guard !isDataFilePanelPresented else { return false }
        isDataFilePanelPresented = true
        NotificationCenter.default.post(
            name: .tagLauncherModalInteractionChanged,
            object: nil,
            userInfo: ["active": true]
        )
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
        return true
    }

    private func finishDataFilePanelPresentation() {
        isDataFilePanelPresented = false
        NotificationCenter.default.post(
            name: .tagLauncherModalInteractionChanged,
            object: nil,
            userInfo: ["active": false]
        )
    }

    private func beginFilePanel(
        _ panel: NSSavePanel,
        completion: @escaping (NSApplication.ModalResponse) -> Void
    ) {
        if let window = preferencesWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.level = .modalPanel
            panel.begin(completionHandler: completion)
            panel.orderFrontRegardless()
        }
    }

    private var preferencesWindow: NSWindow? {
        if let taggedWindow = NSApp.windows.first(where: {
            $0.identifier?.rawValue == "TagLauncherPreferencesWindow" && $0.isVisible
        }) {
            return taggedWindow
        }

        return [NSApp.keyWindow, NSApp.mainWindow]
            .compactMap { $0 }
            .first(where: isPreferencesWindowFallback(_:))
    }

    private func isPreferencesWindowFallback(_ window: NSWindow) -> Bool {
        guard window.isVisible,
              !(window is NSPanel),
              !(window is OverlayPanel)
        else { return false }

        let preferencesTitle = tr("menu.preferences").replacingOccurrences(of: "…", with: "")
        return window.title == preferencesTitle
    }

    private func showDataAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        if let window = preferencesWindow {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    private var mainHotkeyState: LauncherHotkeyRegistrationState {
        LauncherHotkeyRegistrationState(rawValue: mainHotkeyRegistrationState) ?? .active
    }

    private var quickSearchHotkeyState: LauncherHotkeyRegistrationState {
        LauncherHotkeyRegistrationState(rawValue: quickSearchHotkeyRegistrationState) ?? .active
    }

    private func hotkeyStatusText(for kind: LauncherHotkeyKind) -> String {
        switch kind {
        case .main:
            return mainHotkeyState == .failed
                ? tr("quickSearch.status.registrationFailed")
                : tr("quickSearch.status.Active")
        case .quickSearch:
            return quickSearchHotkeyState == .failed
                ? tr("quickSearch.status.unavailable")
                : tr("quickSearch.status.Active")
        }
    }

    private func hotkeyStatusTone(for kind: LauncherHotkeyKind) -> HotkeyStatusTone {
        switch kind {
        case .main:
            return mainHotkeyState == .failed ? .warning : .active
        case .quickSearch:
            return quickSearchHotkeyState == .failed ? .warning : .active
        }
    }

    private func showPendingHotkeyWarningIfNeeded() {
        var messages: [String] = []
        if LauncherHotkeyRegistrationStore.consumeNeedsAttention(for: .main),
           LauncherHotkeyRegistrationStore.state(for: .main) == .failed {
            messages.append(hotkeyFailureMessage(for: .main))
        }
        if LauncherHotkeyRegistrationStore.consumeNeedsAttention(for: .quickSearch),
           LauncherHotkeyRegistrationStore.state(for: .quickSearch) == .failed {
            messages.append(hotkeyFailureMessage(for: .quickSearch))
        }
        guard !messages.isEmpty else { return }
        showHotkeyStatusToast(messages.joined(separator: "\n\n"))
    }

    private func hotkeyFailureMessage(for kind: LauncherHotkeyKind) -> String {
        let key = kind == .main
            ? "quickSearch.mainHotkeyUnavailableMessage"
            : "quickSearch.globalHotkeyUnavailableMessage"
        let status = LauncherHotkeyRegistrationStore.failureCode(for: kind)
            .map(String.init) ?? "-"
        return tr(key)
            .replacingOccurrences(of: "%shortcut%", with: kind.hotkey.displayString)
            .replacingOccurrences(of: "%status%", with: status)
    }

    private func showHotkeyStatusToast(_ message: String) {
        let token = UUID()
        hotkeyStatusToastToken = token
        withAnimation(.easeOut(duration: 0.16)) {
            hotkeyStatusToast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard hotkeyStatusToastToken == token else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                hotkeyStatusToast = nil
            }
        }
    }

    private func restorePreviousCategoryScheme() {
        TagDatabase.flushPendingCategorySchemeBackupBatch()
        guard let backupPath = categoryScheme.previousBackupPath else { return }
        let restoredName = categoryScheme.previousName ?? tr("settings.noPreviousScheme")
        let restored = SmartStartService.restoreBackup(at: backupPath)
        if restored {
            scanApps()
            refreshDataState()
            notifyDataChanged()
            showDataAlert(title: tr("settings.schemeRestored"), message: restoredName)
        } else {
            showDataAlert(title: tr("settings.restoreFailed"), message: backupPath)
        }
    }

    private func applySystemInitialScheme() {
        guard !isApplyingSystemScheme else { return }
        withAnimation(.easeOut(duration: 0.16)) {
            showApplySystemSchemeConfirmation = true
        }
    }

    private func performApplySystemInitialScheme() {
        guard !isApplyingSystemScheme else { return }
        showApplySystemSchemeConfirmation = false
        TagDatabase.flushPendingCategorySchemeBackupBatch()
        isApplyingSystemScheme = true

        DispatchQueue.global(qos: .userInitiated).async {
            let scannedApps = AppIndexer.scan(useCache: false)
            let result = SmartStartService.applySystemInitialScheme(apps: scannedApps)
            let store = result.store
            let apps = TagEditor.annotate(apps: scannedApps, store: store)
            let colors = store.tags.mapValues { $0.color }

            DispatchQueue.main.async {
                isApplyingSystemScheme = false
                allApps = apps
                tagColors = colors
                refreshDataState()
                notifyDataChanged()

                if let summary = result.summary {
                    showDataAlert(
                        title: tr("settings.systemSchemeApplied"),
                        message: formattedSystemSchemeAppliedMessage(summary)
                    )
                } else {
                    showDataAlert(
                        title: tr("settings.restoreFailed"),
                        message: tr("settings.systemSchemeApplyFailed")
                    )
                }
            }
        }
    }

    private func formattedSystemSchemeAppliedMessage(_ summary: SmartStartSummary) -> String {
        tr("settings.systemSchemeAppliedMessage")
            .replacingOccurrences(of: "%appCount%", with: "\(summary.matchedAppCount)")
            .replacingOccurrences(of: "%tagCount%", with: "\(summary.assignedTagCount)")
    }

    private func notifyDataChanged() {
        NotificationCenter.default.post(name: .tagLauncherDataDidChange, object: nil)
    }

    private var currentCategorySchemeName: String {
        if let createdAt = categoryScheme.currentCreatedAt ?? categoryScheme.lastChangedAt {
            return TagDatabase.normalizedSchemeName(
                storedName: categoryScheme.currentName,
                createdAt: createdAt,
                fallbackPrefixKey: "scheme.local"
            )
        }
        return categoryScheme.currentName ?? tr("settings.schemeNotNamed")
    }

    private var previousCategorySchemeName: String {
        guard let storedName = categoryScheme.previousName ?? (categoryScheme.previousBackupPath != nil ? "" : nil) else {
            return tr("settings.noPreviousScheme")
        }
        let createdAt = categoryScheme.previousCreatedAt
            ?? categoryScheme.currentCreatedAt
            ?? categoryScheme.lastChangedAt
            ?? Date()
        return TagDatabase.normalizedSchemeName(
            storedName: storedName,
            createdAt: createdAt,
            fallbackPrefixKey: "scheme.beforeSmartStart"
        )
    }

    private var canRestorePreviousScheme: Bool {
        guard let path = categoryScheme.previousBackupPath else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    private func bubbleScopeOption(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 16, height: 16)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func syncSelectedLanguage() {
        let code = L10n.selectedLanguageCode
        guard selectedLanguage != code else { return }
        selectedLanguage = code
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }
    private var buildVersion: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
    private var helpPDFURL: URL {
        HelpDocument.currentURL
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

    private func dataActionButton(
        _ title: String,
        prominent: Bool,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(prominent ? Color.white.opacity(enabled ? 1.0 : 0.92) : Color.primary.opacity(enabled ? 1.0 : 0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: dataActionWidth, height: 32, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            prominent
                                ? Color.accentColor.opacity(enabled ? 1.0 : 0.45)
                                : Color(nsColor: .controlBackgroundColor).opacity(enabled ? 1.0 : 0.72)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            prominent
                                ? Color.accentColor.opacity(enabled ? 0.16 : 0.08)
                                : Color.secondary.opacity(enabled ? 0.22 : 0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.98)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func hotkeySettingsPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("quickSearch.hotkeys"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            StaticHotkeyInfoRow(
                title: tr("quickSearch.mainHotkey"),
                description: tr("quickSearch.mainHotkeyDesc"),
                displayText: LauncherHotkey.main.displayString,
                statusText: hotkeyStatusText(for: .main),
                statusTone: hotkeyStatusTone(for: .main)
            )

            StaticHotkeyInfoRow(
                title: tr("quickSearch.internalHotkey"),
                description: tr("quickSearch.internalHotkeyDesc"),
                displayText: tr("quickSearch.spaceDisplay"),
                statusText: tr("quickSearch.internalHotkeyStatus"),
                statusTone: .neutral
            )

            StaticHotkeyInfoRow(
                title: tr("quickSearch.globalHotkey"),
                description: tr("quickSearch.globalHotkeyDesc"),
                displayText: LauncherHotkey.quickSearch.displayString,
                statusText: hotkeyStatusText(for: .quickSearch),
                statusTone: hotkeyStatusTone(for: .quickSearch)
            )
        }
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
                            Button {
                                selectedLanguage = L10n.automaticCode
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedLanguage == L10n.automaticCode ? "checkmark" : "circle")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(selectedLanguage == L10n.automaticCode ? Color.accentColor : Color.secondary.opacity(0.28))
                                        .frame(width: 16)
                                    Text(tr("settings.language.auto"))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text("(\(L10n.supported.first(where: { $0.code == L10n.currentCode })?.name ?? "English"))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(tr("settings.languagePicker")) \(tr("settings.language.auto"))")

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
                }
                .frame(maxWidth: settingsContentWidth, alignment: .leading)
                .tabItem { Label(tr("settings.language"), systemImage: "globe") }
                .padding()

                // Tab 2: General
                ScrollView(.vertical, showsIndicators: true) {
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
                }
                .tabItem { Label(tr("settings.general"), systemImage: "gearshape") }

            // Tab 3: Hotkeys
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    hotkeySettingsPanel()
                        .frame(width: generalContentWidth, alignment: .leading)
                }
                .frame(maxWidth: generalContentWidth, alignment: .center)
                .padding()
            }
            .tabItem { Label(tr("quickSearch.hotkeys"), systemImage: "keyboard") }

            // Tab 4: Tags
            VStack(spacing: 0) {
                TagEditorView(
                    tagColors: $tagColors,
                    excludedTagNames: ["Mac自带", defaultGroupName],
                    onRefresh: { scanApps() }
                )
            }
            .tabItem { Label(tr("settings.tags"), systemImage: "tag.fill") }
            .onAppear { scanApps() }

            // Tab 5: Data
            VStack(spacing: 0) {
                Spacer(minLength: 32)

                VStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            Text(tr("settings.systemScheme"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                                .multilineTextAlignment(.trailing)
                                .frame(width: dataLabelWidth, alignment: .trailing)

                            Text(SmartStartService.systemInitialSchemeName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .layoutPriority(0)

                            dataActionButton(
                                tr("settings.applyScheme"),
                                prominent: true,
                                enabled: !isApplyingSystemScheme,
                                action: applySystemInitialScheme
                            )
                            .frame(width: dataActionWidth, alignment: .trailing)
                            .layoutPriority(2)
                        }

                        HStack(alignment: .center, spacing: 12) {
                            Text(tr("settings.previousScheme"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                                .multilineTextAlignment(.trailing)
                                .frame(width: dataLabelWidth, alignment: .trailing)
                            Text(previousCategorySchemeName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(canRestorePreviousScheme ? .primary : .tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .layoutPriority(0)

                            dataActionButton(
                                tr("settings.restorePreviousScheme"),
                                prominent: false,
                                enabled: canRestorePreviousScheme,
                                action: restorePreviousCategoryScheme
                            )
                            .frame(width: dataActionWidth, alignment: .trailing)
                            .layoutPriority(2)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(tr("settings.currentScheme"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                                .multilineTextAlignment(.trailing)
                                .frame(width: dataLabelWidth, alignment: .trailing)
                            Text(currentCategorySchemeName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Color.clear
                                .frame(width: dataActionWidth, height: 1)
                        }

                        Divider().opacity(0.35)

                        VStack(alignment: .center, spacing: 8) {
                            HStack(spacing: 12) {
                                Button(tr("settings.export")) { exportTags() }
                                    .buttonStyle(.bordered)
                                    .disabled(isDataFilePanelPresented)
                                Button(tr("settings.import")) { importTags() }
                                    .buttonStyle(.bordered)
                                    .disabled(isDataFilePanelPresented)
                            }
                            Text(tr("settings.backupDesc"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: dataPanelWidth - 72, alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(width: dataPanelWidth, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
                    )
                }
                .frame(width: dataPanelWidth, alignment: .center)

                Spacer(minLength: 22)

                HStack(alignment: .center, spacing: 14) {
                    Text(tr("settings.bubbleDisplayScope"))
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 190, alignment: .trailing)

                    HStack(spacing: 20) {
                        bubbleScopeOption(
                            tr("settings.bubbleAllApps"),
                            isSelected: !showUncommonAppBubbles
                        ) {
                            showUncommonAppBubbles = false
                        }
                        bubbleScopeOption(
                            tr("settings.bubbleUncommonOnly"),
                            isSelected: showUncommonAppBubbles
                        ) {
                            showUncommonAppBubbles = true
                        }
                    }
                    .frame(width: 300, alignment: .leading)
                }
                .frame(width: 520, alignment: .center)

                Spacer(minLength: 18)
            }
            .tabItem { Label(tr("settings.data"), systemImage: "externaldrive.fill") }
            .padding()
            .onAppear { refreshDataState() }

            // Tab 6: About
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

                        HStack(spacing: 8) {
                            Button {
                                NSWorkspace.shared.open(helpPDFURL)
                            } label: {
                                Label(tr("help.openPDF"), systemImage: "questionmark.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(helpPDFURL.absoluteString, forType: .string)
                            } label: {
                                Image(systemName: "link")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .help(tr("help.copyLink"))
                        }

                        Text(tr("help.currentLanguage"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)

                        Text("万物之中，希望最美")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("永桔@shanghai3168@gmail.com")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 560, alignment: .leading)

                Spacer(minLength: 30)
                Spacer(minLength: 18)
            }
            .tabItem { Label(tr("settings.about"), systemImage: "info.circle") }
            .padding()
            }
            .onChange(of: selectedLanguage) { _, code in
                L10n.switchSelection(to: code)
            }
            .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { notification in
                if let code = notification.userInfo?["code"] as? String {
                    selectedLanguage = code
                } else {
                    syncSelectedLanguage()
                }
                scanApps()
                refreshDataState()
                showLanguageRefresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .tagLauncherDataDidChange)) { _ in
                refreshDataState()
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

            if showApplySystemSchemeConfirmation {
                ApplySystemSchemeConfirmationView(
                    title: tr("settings.applySystemSchemeWarningTitle"),
                    message: tr("settings.applySystemSchemeWarningMessage"),
                    confirmTitle: tr("settings.confirmApplyScheme"),
                    cancelTitle: tr("settings.cancel"),
                    onConfirm: performApplySystemInitialScheme,
                    onCancel: {
                        withAnimation(.easeOut(duration: 0.14)) {
                            showApplySystemSchemeConfirmation = false
                        }
                    }
                )
                .zIndex(3)
                .transition(.opacity)
            }

            if let hotkeyStatusToast {
                VStack {
                    Spacer()
                    Text(hotkeyStatusToast)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.black.opacity(0.92))
                        )
                        .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
                        .frame(maxWidth: 620)
                        .padding(.bottom, 22)
                }
                .zIndex(4)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(width: settingsWindowWidth, height: 460)
        .onAppear {
            syncSelectedLanguage()
            showPendingHotkeyWarningIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagLauncherHotkeyRegistrationChanged)) { _ in
            showPendingHotkeyWarningIfNeeded()
        }
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

private enum HotkeyStatusTone {
    case active
    case warning
    case neutral

    var foreground: Color {
        switch self {
        case .active: return Color.green
        case .warning: return Color.orange
        case .neutral: return Color.secondary
        }
    }

    var background: Color {
        foreground.opacity(0.13)
    }
}

private struct StaticHotkeyInfoRow: View {
    let title: String
    let description: String
    let displayText: String
    let statusText: String
    let statusTone: HotkeyStatusTone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayText)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(statusTone.foreground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(statusTone.background))
                }
                .frame(width: 180, alignment: .leading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct ApplySystemSchemeConfirmationView: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.20)
                .contentShape(Rectangle())
                .onTapGesture { }

            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.16))
                            .frame(width: 38, height: 38)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(Color.orange)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.primary.opacity(0.78))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    Spacer()
                    ConfirmationActionButton(
                        title: cancelTitle,
                        prominent: false,
                        action: onCancel
                    )
                        .keyboardShortcut(.cancelAction)
                    ConfirmationActionButton(
                        title: confirmTitle,
                        prominent: true,
                        action: onConfirm
                    )
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(22)
            .frame(width: 440)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 20, x: 0, y: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ConfirmationActionButton: View {
    let title: String
    let prominent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(prominent ? Color.white : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
                .frame(minWidth: 82, minHeight: 32)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(prominent ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(
                            prominent ? Color.accentColor.opacity(0.40) : Color.primary.opacity(0.16),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
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
