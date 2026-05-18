import SwiftUI
import AppKit
import Carbon

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
    @State private var selectedLanguage = L10n.currentCode
    @State private var isRefreshingLanguage = false
    @State private var allApps: [AppInfo] = []
    @State private var tagColors: [String: Int] = [:]
    @State private var categoryScheme = TagDatabase.CategorySchemeState()
    @State private var isApplyingSystemScheme = false

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
        let panel = NSSavePanel()
        panel.title = tr("settings.export")
        TagDatabase.flushPendingCategorySchemeBackupBatch()
        refreshDataState()
        panel.nameFieldStringValue = TagDatabase.exportFileName(for: categoryScheme)
        panel.allowedContentTypes = [.json]
        beginFilePanel(panel) { response in
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
        beginFilePanel(panel) { response in
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

    private func beginFilePanel(
        _ panel: NSSavePanel,
        completion: @escaping (NSApplication.ModalResponse) -> Void
    ) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = preferencesWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.level = .modalPanel
            panel.begin(completionHandler: completion)
            panel.orderFrontRegardless()
        }
    }

    private var preferencesWindow: NSWindow? {
        NSApp.windows.first {
            $0.identifier?.rawValue == "TagLauncherPreferencesWindow" && $0.isVisible
        } ?? NSApp.keyWindow ?? NSApp.mainWindow
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
        guard confirmApplySystemInitialScheme() else { return }
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

    private func confirmApplySystemInitialScheme() -> Bool {
        let alert = NSAlert()
        alert.messageText = tr("settings.applySystemSchemeWarningTitle")
        alert.informativeText = tr("settings.applySystemSchemeWarningMessage")
        alert.alertStyle = .warning
        alert.addButton(withTitle: tr("settings.confirmApplyScheme"))
        alert.addButton(withTitle: tr("settings.cancel"))
        return alert.runModal() == .alertFirstButtonReturn
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
        let code = L10n.currentCode
        guard selectedLanguage != code else { return }
        selectedLanguage = code
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
            .tabItem { Label(tr("settings.tags"), systemImage: "tag.fill") }
            .onAppear { scanApps() }

            // Tab 4: Data
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
                                Button(tr("settings.import")) { importTags() }
                                    .buttonStyle(.bordered)
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
        }
        .frame(width: settingsWindowWidth, height: 460)
        .onAppear {
            syncSelectedLanguage()
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
