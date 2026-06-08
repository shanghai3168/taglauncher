# App Store Connect Metadata Draft

These are draft values for the first Mac App Store submission. Edit in App Store Connect before submission.

Frozen local QA source for this metadata:

- Version: `7.8.1`
- Build: `20260529.1235`
- Source ref: `appstore-7.8.1-20260529.1235`
- Release pack: `Release/AppStore-7.8.1-20260529.1235`

## App Information

- Name: `TagLauncher`
- Bundle ID: `com.taglauncher.app`
- SKU: `taglauncher-macos`
- Category: `Utilities`
- Version: `7.8.1`
- Distribution method: Public
- Release option: Manual release after approval

## Subtitle Options

English, 30 characters max:

- `Tag-based app launcher`
- `Launch apps by tag`

Simplified Chinese, 30 characters max:

- `标签化应用启动器`
- `用标签启动 Mac 应用`

## Description Draft

TagLauncher is a fast tag-based launcher for Mac apps.

Organize installed apps into visual tag groups, open a fullscreen-friendly app grid from a global hotkey, and jump directly to apps with Quick Search. It is designed for people who have many apps and want a calmer, faster way to find the right one without hunting through Launchpad, Finder, or the Dock.

Highlights:

- Open the app grid with Option-Shift-Space.
- Search apps, tags, and notes with Quick Search.
- Group apps by custom tags.
- Tune icon size, tag position, app list style, and Dock visibility.
- Import and export your category layout.
- Works across multiple displays and fullscreen Spaces.

## Chinese Description Draft

TagLauncher 是一个基于标签的 Mac 应用启动器。

你可以把已安装的应用整理成可视化标签分组，用全局快捷键唤出应用网格，也可以通过 Quick Search 直接搜索应用、标签和备注。它适合安装了很多应用、希望更快找到目标应用的人。

亮点：

- 使用 Option-Shift-Space 打开应用网格。
- 使用 Quick Search 搜索应用、标签和备注。
- 用自定义标签整理应用。
- 可调整图标大小、标签位置、列表样式和 Dock 显示。
- 支持分类布局的导入和导出。
- 支持多显示器和全屏 Space 场景。

## Keywords Draft

English:

`launcher,tags,apps,productivity,quick search,utility,mac`

Simplified Chinese:

`启动器,标签,应用,效率,搜索,工具,Mac`

## What's New

Version 7.8.1:

- Improved tag navigation with AppKit-backed rendering and drag reordering.
- Improved Quick Search with an AppKit-backed result list and independent panel presentation.
- Improved fullscreen and Split View behavior so AppGrid, Quick Search, and Settings stay in the current Space.
- Fixed duplicate Dock icons when repeatedly showing TagLauncher.
- Fixed App icon transparency so rounded corners render correctly.
- Improved AppGrid keyboard routing after scrolling, so Space and Escape stay responsive.
- Reduced AppGrid scroll churn for smoother browsing.
- Changed the default icon size for new installs to 64.
- Added stronger release QA coverage for Mac window behavior.

## App Review Notes Draft

TagLauncher is a macOS app launcher.

Primary review path:

1. Launch TagLauncher.
2. Press Option-Shift-Space to show the app grid.
3. Press Space while the app grid is visible to open Quick Search.
4. Press Escape once to close Quick Search, then Escape again to close the app grid.
5. Open Preferences from the menu bar or Command-Comma to inspect settings.

Expected behavior:

- The app grid is intentionally displayed above normal and fullscreen app windows.
- In Split View/fullscreen Spaces, Quick Search and Settings are expected to appear above the app grid without switching Spaces.
- While the app grid is visible, TagLauncher becomes the foreground app so its menu bar is visible and the Dock is hidden.
- The system Force Quit window remains above TagLauncher.
- Import/export uses standard file panels.
- Login-at-launch is disabled in sandboxed App Store builds if the LaunchAgent approach is unavailable.

## Privacy Draft

Current code audit:

- No network API usage found.
- App preferences are stored locally with `UserDefaults`.
- Tag/category data is stored locally under the user's Application Support area.
- The app scans installed applications locally to build the launcher index.
- Import/export only touches user-selected files.
- No analytics SDK, advertising SDK, or third-party tracking SDK is bundled.

Privacy questionnaire starting point:

- Data collected: likely `No`, assuming no analytics/crash reporting/network telemetry is added before submission.
- Tracking: `No`.
- Privacy policy URL: required for macOS apps. Publish this before submission.

Do not submit until these answers are reviewed against the exact App Store-signed build.

## Screenshot Plan

Required Mac screenshot sizes include 16:10 images such as:

- `2880 x 1800`
- `2560 x 1600`
- `1440 x 900`
- `1280 x 800`

Suggested shots:

1. App grid with several tag groups.
2. Quick Search with a sample query.
3. Settings showing appearance/hotkey controls.
4. Optional import/export or tag editing view.

Avoid screenshots that expose private installed apps if that matters for marketing.
