# App Store Connect Metadata Draft

## App Information

- Name: `TagLauncher`
- Bundle ID: `com.taglauncher.app`
- SKU: `taglauncher-macos`
- Category: `Utilities`
- Version: `7.8.14`
- Minimum macOS: `15.0`
- Release option: Manual release after approval

## What's New

Version 7.8.14:

- Fixed an issue where some Apple system apps, including Keychain Access, could not appear in TagLauncher's App Grid or Quick Search because they are installed under CoreServices Applications rather than the usual Applications folders.
- Added CoreServices Applications to the lightweight app-directory signature check without adding a full scan on every open.

中文：

- 修复“钥匙串访问 / Keychain Access”等 Apple 系统应用无法在 App Grid 或 Quick Search 中检索的问题。这类应用位于 CoreServices Applications，而不是常规 Applications 目录。
- 将 CoreServices Applications 纳入轻量目录签名检查，不会因此在每次打开时执行完整扫描。

## Description Draft

Use the 7.8.13 description draft unless product positioning changes. Only the version and What's New need to change for this hotfix.

## Keywords Draft

English:

`launcher,tags,apps,productivity,quick search,utility,mac`

Simplified Chinese:

`启动器,标签,应用,效率,搜索,工具,Mac`
