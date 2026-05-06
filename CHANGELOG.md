# Apptag Changelog

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

