# App Store Connect Metadata Draft

这些是 TagLauncher `7.8.12` 的 App Store Connect 填写草稿。提交前请把支持邮箱、隐私政策 URL、支持 URL、版权归属和价格策略替换为真实值。

## App Information

- Name: `TagLauncher`
- Bundle ID: `com.taglauncher.app`
- SKU: `taglauncher-macos`
- Category: `Utilities`
- Version: `7.8.12`
- Primary language: `English (U.S.)` or `Simplified Chinese`
- Distribution method: Public App Store
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

Version 7.8.12:

- Fixed an issue where Quick Search-only mode could close immediately after opening because of a stale mouse dismiss event.
- Improved Quick Search-only stability after pressing Fn-Space while keeping keyboard cancel and repeated Fn-Space close behavior immediate.
- Updated release QA coverage for synthetic Fn-Space delivery and Quick Search result click targeting.

## App Review Notes Draft

TagLauncher is a macOS utility for organizing installed applications into visual tag groups and launching them from a keyboard-accessible app grid.

Primary review flow:

1. Launch TagLauncher.
2. Press `Option-Shift-Space` to show the app grid.
3. Press `Space` while the app grid is visible to open Quick Search.
4. Press `Escape` once to close Quick Search.
5. Press `Escape` again to close the app grid.
6. Open Settings from the menu bar or with `Command-Comma`.

Expected behavior:

- The app grid intentionally appears above normal and fullscreen app windows.
- In fullscreen and Split View Spaces, AppGrid, Quick Search, and Settings should remain in the current Space instead of switching to another Space.
- While the app grid is visible, TagLauncher may hide the Dock depending on user settings and shows TagLauncher's menu bar.
- The system Force Quit window remains above TagLauncher.
- Import/export uses standard macOS file panels.
- In sandboxed App Store builds, login-at-launch may be disabled if the LaunchAgent approach is unavailable.

No demo account is required.

## Privacy Draft

Current code audit:

- No background network API usage found.
- App preferences are stored locally with `UserDefaults`.
- Tag/category data is stored locally under the user's Application Support area.
- The app scans installed applications locally to build the launcher index.
- Import/export only touches user-selected files.
- No analytics SDK, advertising SDK, tracking SDK, crash reporting SDK, or third-party tracking SDK is bundled.
- Help/support/release links may open externally in the user's browser only after user action.

Privacy questionnaire starting point:

- Data collected: `No`, assuming no analytics/crash reporting/network telemetry is added before submission.
- Tracking: `No`.
- Privacy policy URL: required. Publish `Legal/PRIVACY_POLICY.md` or its final edited version before submission.

## Screenshot Plan

Required Mac screenshot count and sizes:

- Upload 1 to 10 screenshots.
- Use `.png`, `.jpg`, or `.jpeg`.
- Accepted Mac sizes are 16:10: `1280 x 800`, `1440 x 900`, `2560 x 1600`, `2880 x 1800`.
- Prefer `2880 x 1800` final exports.

Suggested shots:

1. App grid with several tag groups.
2. Quick Search with a sample query.
3. Settings showing appearance/layout controls.
4. Hotkey or Quick Search settings.
5. Optional import/export or tag editing view.

Avoid screenshots that expose private installed apps, folders, account names, messages, or notifications.
