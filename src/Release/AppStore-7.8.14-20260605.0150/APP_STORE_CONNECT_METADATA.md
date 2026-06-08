# App Store Connect Metadata Draft

## App Information

- Name: `TagLauncher`
- Bundle ID: `com.taglauncher.app`
- SKU: `taglauncher-macos`
- Category: `Utilities`
- Version: `7.8.14`
- Build: `20260605.0150`
- Minimum macOS: `15.0`

## Subtitle Options

- `Tag-based app launcher`
- `Launch apps by tag`
- `标签化应用启动器`

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

## Keywords

English:

`launcher,tags,apps,productivity,quick search,utility,mac`

Simplified Chinese:

`启动器,标签,应用,效率,搜索,工具,Mac`

## What's New

Version 7.8.14:

- Fixed discovery for Apple system apps installed under CoreServices Applications, including Keychain Access.
- Quick Search and App Grid can now find `Keychain Access` and localized names such as `钥匙串访问`.
- Kept the lightweight app-directory signature check so opening search does not trigger a full scan unless app folders changed.

中文：

- 修复位于 CoreServices Applications 目录下的 Apple 系统应用无法检索的问题，包括“钥匙串访问 / Keychain Access”。
- Quick Search 和 App Grid 现在可以通过英文名、本地化名称和拼音候选找到这些系统应用。
- 继续保留轻量目录签名检查，应用目录未变化时不会在打开搜索时完整重扫。
