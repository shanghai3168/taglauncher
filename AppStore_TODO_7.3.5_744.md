# Apptag 7.3.5 (Build 744) App Store 提交 To-do List

> 当前发布版本以源码目录中的 `Apptag/Info.plist` 为准；在发布包里对应 `Source/Apptag/Info.plist`：`CFBundleShortVersionString = 7.3.5`，`CFBundleVersion = 744`，`LSMinimumSystemVersion = 15.0`。
> 本地已有构建产物 `build/TagLauncher.app` 与 `build/TagLauncher.dmg`，但正式提交仍建议在登录 Apple Developer 账号的开发者电脑上重新签名、归档、上传。

## 0. 当前状态

- 本地发布包已整理到 `/Users/ar/Projects/Apptag744Release`。
- 本地 QA 已通过，详见 `QA/QA_Report_7.3.5_744.md`。
- 发布资料版本漂移已清理：当前提审资料、清单、发布包均指向 `7.3.5` / Build `744`。
- 本地构建产物为 ad-hoc 签名，仅用于 QA；正式提审仍需使用 Apple Distribution 证书重新签名并上传。
- 下一步需要 Apple Developer 账号环境执行：正式签名、上传、TestFlight/App Store 签名包验证、提交审核。

## A. 发布资料确认

- 确认 App Store Connect 中本次版本为 `7.3.5`，Build 选择 `744`。
- 使用 `AppStore_Submission.md` 填写描述、关键词、隐私说明、审核备注和 What's New。
- 使用 `CHANGELOG.md` 顶部 `7.3.5` 记录作为版本变更来源。
- 发布包目录为 `/Users/ar/Projects/Apptag744Release`，其中 `00todolist.md` 是正式操作清单。
- 确认发布包中包含：
  - `AppStore_Submission.md`
  - `CHANGELOG.md`
  - `00todolist.md`
  - `Artifacts/TagLauncher.app`
  - `Artifacts/TagLauncher.dmg`
  - `Artifacts/AppStore_1024.png`
  - `Artifacts/AppIcon.icns`
  - `Source/` 源码与构建依赖
  - `QA/QA_Report_7.3.5_744.md`

## B. 正式构建与签名

- 登录正确的 Apple Developer 账号。
- 确认 Xcode、Command Line Tools、Transporter 或 Xcode Organizer 可用。
- 确认证书包含 Mac App Distribution / Apple Distribution。
- 确认 Bundle ID 是 `com.apptag.launcher`。
- 使用 App Store sandbox entitlements：`Apptag/TagLauncher.entitlements`。
- 在开发者电脑上进入发布包源码目录后运行：

```bash
cd /Users/ar/Projects/Apptag744Release/Source
APP_STORE=1 CODESIGN_IDENTITY="Apple Distribution: Your Name (TEAMID)" bash build.sh
```

- 构建完成后确认 About 页显示 `版本 7.3.5（构建 744）`。
- 确认 `build/TagLauncher.app/Contents/Info.plist` 中：
  - `CFBundleShortVersionString = 7.3.5`
  - `CFBundleVersion = 744`
  - `LSMinimumSystemVersion = 15.0`

## C. 本地冒烟测试

- 退出旧版 TagLauncher，再启动新版。
- 如果菜单栏图标不可见，检查 Thaw / Bartender / Ice / Hidden Bar / Dozer 等菜单栏管理工具是否隐藏了 TagLauncher。
- 确认 `⌥⇧空格` 能呼出应用列表。
- 确认主列表 Flat / Colored Grid / Container 模式均能显示。
- 确认设置按钮和编辑按钮都能从浮层右上角打开。
- 确认设置页语言切换正常。
- 确认标签拖拽排序、右侧标签点击切换、App 拖入标签、拖到未分类确认面板正常。
- 确认数据页导出 / 导入分类与布局正常。
- 确认 Smart Start 初始分类方案可应用、确认提示不被设置窗口遮挡、恢复和导出。
- 确认 App Store 沙盒构建中 Launch at Login 控件隐藏。
- 在 TestFlight 中重点验证 sandbox 下全局快捷键 `Shift+Option+Space`。
- 已完成本地关键 QA：全新用户、已有用户、Smart Start、语言切换、备注保护、拖到未分类、标签拖拽、右侧标签点击切换、设置页确认层级、菜单栏稳定性。

## D. App Store Connect 填写

- 创建或选择 Apptag `7.3.5` 版本。
- App 名称：`Apptag`。
- Bundle ID：`com.apptag.launcher`。
- SKU：`apptag-mac-001`。
- 类别：Utilities，次要类别 Productivity。
- 最低系统版本：macOS `15.0`。
- 复制 `AppStore_Submission.md` 第 2 节 App 描述。
- 复制第 3 节关键词。
- 隐私标签选择“不收集任何数据”。
- 年龄分级按第 5 节填写，最终应为 `4+`。
- What's New 使用第 8 节 `Apptag 7.3.5` 内容。
- 审核备注使用第 9 节，说明 Carbon 全局快捷键不需要辅助功能权限，且无网络请求。

## E. 截图与图标

- 上传 1024×1024 App Store 图标 PNG，优先使用 `Apptag/Assets.xcassets/AppIcon.appiconset/icon_1024_preview.png`。
- 准备至少 1 张、建议 6 张 Mac 截图。
- 推荐截图场景：
  - 全屏浮层 Flat 或 Colored Grid 模式
  - Container 模式
  - 标签编辑与拖拽排序
  - 设置页通用选项
  - 数据页分类方案管理
  - 菜单栏入口与应用浮层工作流

## F. 上传与提交审核

- 使用 Xcode Organizer 或 Transporter 上传正式签名构建。
- 上传后在 App Store Connect 选择 Build `744`。
- 等待处理完成后，确认版本页显示 `7.3.5 (744)`。
- 检查描述、隐私、截图、价格、年龄分级、审核备注均已填写。
- 提交审核。
- 提交后保留 `/Users/ar/Projects/Apptag744Release`，方便审核反馈时快速对照。
