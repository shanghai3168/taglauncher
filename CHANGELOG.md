# Apptag Changelog

## [3.1.32] — 2026-05-10

- 提升 overlay 到 CoreGraphics maximum window level，进一步避免被全屏应用窗口层遮挡

## [3.1.31] — 2026-05-10

- 强化全屏 Space 唤出逻辑：每次显示 overlay 都重新创建绑定当前 Space 的 NSPanel，避免复用旧窗口导致全屏空间迁移失败

## [3.1.30] — 2026-05-10

- 再次修复全屏 Space 唤出不可见问题：overlay 显示时移动到当前活跃 Space，并避免激活 App 导致窗口回到非全屏空间

## [3.1.29] — 2026-05-10

- 继续修复全屏 Space 唤出不可见问题：overlay 改为非激活 NSPanel，并加入 stationary/transient 全屏辅助行为，确保在当前全屏 Space 前置显示

## [3.1.28] — 2026-05-10

- 修复全屏 Space 下 Shift+Option+Space 唤出 Apptag 后 overlay 被全屏应用遮挡的问题：显示时刷新当前屏幕 frame，提升窗口层级并强制前置

## [3.1.27] — 2026-05-07

- 彻底移除 SMAppService，改用 LaunchAgent（~/Library/LaunchAgents）控制登录启动，零权限

## [3.1.26] — 2026-05-07

- 修复每次启动重复触发 App 管理权限弹窗：SMAppService.register() 只在首次调用

## [3.1.25] — 2026-05-07

- 首次启动自动 seed 7 个默认标签（设计/编程/写作/游戏/娱乐/系统优化/办公），9 语言适配

## [3.1.24] — 2026-05-07

- 关于页整体右移 100pt，视觉居中

## [3.1.23] — 2026-05-07

- 关于页：图标放大一倍 (128×128)，签名档精简为两行

## [3.1.22] — 2026-05-07

- 关于页签新增签名档

## [3.1.21] — 2026-05-06

- 大幅缩减包体：4.1MB → 900KB（二进制 strip + icon 压缩）

## [3.1.20] — 2026-05-06

- 修复设置页面切换 tab 时宽度跃变：固定宽度 660pt，高度可拖动调整

## [3.1.19] — 2026-05-06

- 修复默认组名不随语言切换的问题：存储语言中立 key "Other"，显示时翻译
- 移除 Sandbox entitlements（不再索要 App 管理权限）
- 移除 Accessibility 热键降级方案，保持纯 Carbon hotkey + 菜单栏 fallback
- 新增 App Store 提审资料文档 (AppStore_Submission.md) + 截图脚本 (screenshots.sh)
- 新增 App Store 1024×1024 图标 (AppStore_1024.png)

## [3.1.16] — 2026-05-06

- 回滚所有快捷键设置功能（v3.1.13~v3.1.15），回到 v3.1.12 稳定状态

## [3.1.15] — 2026-05-06

- 修复 HotkeyHelper 崩溃：kVK 常量非连续编号，改用字典查表替代 switch range

## [3.1.14] — 2026-05-06

- 快捷键设置独立为第 3 个页签（键盘图标），Data 恢复原样

## [3.1.13] — 2026-05-06

- 新增全局快捷键设置（Data 页签）：点击按钮后按下新快捷键即可更改，支持任意组合键
- 菜单栏「Show Apptag」右侧显示当前快捷键
- HotkeyHelper：Carbon keycode → 人类可读字符串（⇧⌥Space, ⌘A, F1 等）

## [3.1.12] — 2026-05-06

- General 标签页：放弃 Grid，回到逐行 HStack；4 个 Picker 统一 280pt 左对齐，描述文字左边缘与 Picker 严格对齐
- "其他" 默认组改名为 "未分类"，9 语种全部翻译；启动时自动迁移旧 "Other" 值

## [3.1.11] — 2026-05-06

- General 标签页：改用 Grid 布局替代固定 frame，标签列按内容宽度自动右对齐
- 点击 Dock 图标现在等同于菜单栏 "Show Apptag"，直接全屏显示 APP 列表

## [3.1.10] — 2026-05-06

- General 标签页：Toggle 行横向居中；标签-控件改为逐行 HStack（替代并行 VStack），消除垂直不对齐
- 修复设置页面行为：打开偏好设置时不再隐藏 overlay，Settings 窗口提升至 overlay 上方供实时预览
- Tags 标签页整体向右偏移 16px

## [3.1.9] — 2026-05-06

- Grid 布局替换独立 HStack：标签列 + 控件列严格对齐，16pt 间距

## [3.1.8] — 2026-05-06

- 优化 General 标签页排版：标签文字右对齐、选项/说明左对齐、间距16pt

## [3.1.7] — 2026-05-06

- 彻底清除 Finder 标签残留：移除 `migrateFromFinderIfNeeded()`, `readFinderTags()`, `Store.migrated`, `removeTag()`
- 移除 AppIcon.iconset 目录（build 已改用 icon-icns.icns）

## [3.1.6] — 2026-05-06

- 完整国际化：Settings 所有页面、编辑模式、标签编辑器全部使用 tr() 翻译
- 9 语种翻译补全（新增 settings.*, edit.*, tag.*, app.* 共 14 个 key）
- 新增 key：settings.launchAtLogin, settings.showInDock, edit.tags, app.name, app.description, app.version, app.build

## [3.1.3] — 2026-05-06

- 清除 Re-index 功能：已脱离 Finder，每次 overlay 打开自动扫描新 app，无需手动触发

## [3.1.2] — 2026-05-06

- 修复 Show in Dock 不生效：监听 UserDefaults 变化动态切换 activationPolicy
- 新增 Launch at login（开机启动）开关，默认勾选，首次安装自动启用

## [3.1.1] — 2026-05-06

- 修复语言菜单勾选与实际语言不一致（`L10n.currentCode` 替代 UserDefaults）
- 修复 `setupMenuBar` 重复调用导致图标消失（先移除旧 statusItem）
- Preferences → General 新增「Show in Dock」Toggle

## [3.1.0] — 2026-05-06

- 国际化：支持 9 种语言（英/简中/繁中/日/韩/俄/法/意/西）
- 菜单栏新增 Language 子菜单切换语言
- 翻译文件独立存储在 `Apptag/Localization/*.json`
- `L10n.swift` 管理器 + `tr()` 辅助函数

## [3.0.11] — 2026-05-06

- 容器标题最小宽度优化：`.layoutPriority(1)` 让文字优先占空间，分隔线压缩，可显示约15字符

## [3.0.10] — 2026-05-06

- 恢复 hover 左侧标签 → 右侧滚动（之前误移除）
- flatGrid + containerGrid `.id(displayMode)` 修复模式切换后功能失效

## [3.0.9] — 2026-05-06

- 容器模式：hover 左侧标签 → 右侧自动滚动到对应容器
- 容器模式：点击左侧标签 → 对应容器加粗彩色边框（再点取消），边框颜色与标签颜色一致

## [3.0.8] — 2026-05-06

- 修复 hover 显示名称时容器抖动：文本始终渲染，opacity 控制显隐（空间预占位）

## [3.0.7] — 2026-05-06

- 隐藏 APP 名称时，鼠标 hover 自动显示名称（`.opacity` 0.85）

## [3.0.6] — 2026-05-06

- 新增标签输入行显示在标签列表最上面第一行
- Settings Tags 标签页排序改用 tagOrder（新建标签确认后留在顶部）

## [3.0.5] — 2026-05-06

- `createTag` 和 `assignTag` 中 `tagOrder.append` → `tagOrder.insert(at: 0)`，新建标签始终在列表最上面

## [3.0.4] — 2026-05-06

- 新增 **Hide app names** Toggle（Preferences → General → 最后一行），Flat/Container 双模式均支持隐藏 APP 名称
- 去掉 General 标签页中 "Appearance"、"Layout" 两个 section header
- 修复新建 tag 消失的 bug：`addNewTag` 调用 `TagEditor.createTag` 持久化到数据库
- 每次进入编辑模式强制从数据库刷新 tagColors 和 draggedTagNames
- 编辑模式标签名强制单行 + 中间截断（`.truncationMode(.middle)`）

## [3.0.3] — (已回滚)

- 尝试等行高 LazyVGrid 布局 → 用户不满意，回滚至 3.0.2

## [3.0.2] — 2026-05-06

- 容器样式改为瀑布流布局（Pinterest-style）：GeometryReader + HStack + LazyVStack，按最短列分配，16pt 等距间隙
- 容器名强制单行 `.lineLimit(1)` + `.truncationMode(.middle)`
- 标签拖拽排序最终方案：`onDrag`/`onDrop`（放弃 List+.onMove，因 macOS 不原生支持且导致无法退出编辑）

## [3.0.1] — 2026-05-06

- 新增容器显示样式：Preferences → General → "App list style" → Flat / Container
- Container 模式：每个 tag group 包在圆角矩形框内，`ultraThinMaterial` 背景，app 图标网格自动适配

## [2.0.2] — 2026-05-06

- 标签拖拽排序：编辑模式左侧标签列表支持 `onDrag`/`onDrop` 拖拽重排
- 新增 `tagOrder` 字段持久化到数据库，`AppIndexer.group()` 按自定义顺序排列分组

## [2.0.1] — 2026-05-06

- 确认导出已包含完整 app-tag 映射信息（`tags` + `appTags`）

## [2.0] — 2026-05-06

- **架构级变更**：标签完全脱离 Finder，独立存储在本地 JSON 数据库 `~/Library/Application Support/Apptag/tags.json`
- 首次启动一次性导入 Finder 存量标签（含"Mac自带"），之后不再触碰 Finder xattr
- 所有 CRUD（assign/rename/delete/setColor）写入本地 DB
- Preferences → Data 标签页：Export / Import JSON 备份恢复
- `DismissibleHostingView.mouseDown` 递归搜索 `TextFieldContainer`/`NSTextField`
- 编辑模式直接进入 Edit App Categories（去掉 tag 编辑选择页）

## [1.1.6] — 2026-05-06

- xattr 写入失败时通过 `osascript` + `administrator privileges` 弹出系统认证窗口重试
- SIP 保护路径检测并提示

## [1.1.5] — 2026-05-06

- 去除编辑模式中 tag 编辑选择页，直接进 Edit App Categories
- 修复 Settings 中 tag 重命名产生重复标签的 bug

## [1.1.4] — 2026-05-05

- `TagEditorView` 可复用 tag CRUD 组件
- `TextFieldContainer` 模式解决 NSTextField 焦点问题
- `DismissibleHostingView` 点击转发优化
- 编辑模式 Ctrl+E、标签位置 left/right/top

## [1.1.3] — 初始

- macOS menubar 应用，SwiftUI+AppKit，swiftc 编译
- Carbon 全局热键 Shift+Option+Space
- Finder 标签读取、分组显示、全屏 overlay
- 标签编辑（与 Finder xattr 同步）
