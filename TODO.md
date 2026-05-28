# TagLauncher TODO

## Workflow

- 每次修改前先检查本文件。
- 如果用户提出的新需求不在清单中，先新增到 `Todo` 或 `In Progress`。
- 开始做任务时，把任务移动到 `In Progress`。
- 任务完成并验证后，把任务移动到 `Done`，补一句完成结果。
- 每个任务必须单独提交、单独构建、单独验收；验收通过后再进入下一个任务。
- 每个任务的 QA 顺序固定为：自动化/半自动化验证 → QA 屏幕点击复核 → 用户最终体验验收。

## In Progress

## Todo

- [2026-05-28] 设置页和 Smart Start 模块化。
  - 目标: 低频路径后置整理。
  - 验收: 语言、通用、快捷键、标签、数据、关于页都保持现有行为。

## Done

- [2026-05-29] AppLibraryController / 数据刷新管线整理。
  - 提交: 本次提交
  - 结果: 新增 `AppLibraryController` 和 `AppLibrarySnapshot`，把扫描、reconcile、Smart Start、annotate、Quick Search documents、标签颜色和标签顺序组装从 `ContentView` 的刷新路径中抽离。
  - 范围: 不改扫描、数据库、搜索匹配、拖拽改标签逻辑；`ContentView` 只应用 snapshot 并刷新 UI。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、启动 App Grid 屏幕复核、Quick Search `sor` 索引复核、上下键复核、`Scripts/window_logic_qa.sh` 全部通过。

- [2026-05-29] OverlayWindowController 收口。
  - 提交: 本次提交
  - 结果: 新增 `OverlayWindowController`，将 overlay window 实例、generation、Space 避让、show/focus/hide 编排、panel 创建、屏幕选择、全屏/Split View 判定从 `AppDelegate` 中收口出去。
  - 范围: AppDelegate 保留菜单、热键、Settings、Quick Search 和 app chrome 协调入口；窗口策略保持原行为。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、`Scripts/window_logic_qa.sh` 全部通过，覆盖全屏、Split View、Settings、Force Quit、文件面板、Dock 图标重复和屏幕跟随。

- [2026-05-29] Quick Search 独立面板化。
  - 提交: 本次提交
  - 结果: Quick Search 面板已从主 overlay SwiftUI 层拆出，改为独立 `NSPanel` 并作为 overlay child window 显示；搜索状态、输入框、结果列表、启动逻辑保持原路径。
  - 补强: Quick Search panel 与 overlay 保持同层级，避免压过菜单栏；打开 Settings 前统一关闭 Quick Search；本应用内外部点击可关闭 Quick Search 但保留 App Grid。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、`Scripts/window_logic_qa.sh` 全部通过；屏幕 QA 验证打开、输入 `sor`、上下键选中和 Esc 关闭均正常。

- [2026-05-29] Quick Search 结果列表 AppKit 化。
  - 提交: 本次提交
  - 结果: Quick Search 结果列表已替换为 AppKit `NSScrollView` + 自绘 row；输入框、搜索逻辑、快捷键命令、外层 overlay 保持原路径。
  - 范围: 只改结果列表渲染层，不动独立面板、窗口层级、搜索匹配和启动逻辑。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、静态确认旧 SwiftUI `QuickSearchResultRow` 已移除；屏幕 QA 验证默认选中、上下键、滚动跟随、`sor` 搜到 Shottr、无结果状态、Return 启动选中结果并关闭 Quick Search。

- [2026-05-29] 修复 App 图标白边并清除旧图标残留。
  - 提交: 本次提交
  - 结果: 当前 grid/rainbow AppIcon 的圆角外区域已改为透明；`generate_icon.py` 删除旧“两张标签”生成逻辑，并增加 grid/rainbow 图标族校验，防止旧图标被重新生成。
  - 范围: 更新 `.icns`、`AppIcon.appiconset`、Release 1024 图标、Local QA DMG；`build.sh` 改为优先从 `AppIcon.appiconset` 生成 bundle `AppIcon.icns`。
  - 验证: `python3 generate_icon.py`、`bash build.sh`、`codesign --verify --deep --strict`、DMG 挂载检查、全项目图片/DMG 旧图标近似匹配扫描均通过；根 `.icns`、appiconset、Release 1024 图标、bundle/DMG 内 AppIcon 四角 alpha 均为 0。

- [2026-05-29] 清理或改名 `AppGridItem.swift` 残留。
  - 提交: 本次提交
  - 结果: `AppGridItem.swift` 已改名为 `AppGridSupport.swift`，文件标题改为 App Grid shared support，避免误解为旧 SwiftUI 浏览态 grid。
  - 范围: 只做文件命名/注释清理，未改 App Grid 运行逻辑。
  - 验证: 构建 `7.6.0 (20260529.0102)`、签名、静态 QA、App Grid 屏幕 smoke test 通过。

- [2026-05-28] 第二批 AppKit 化第 4.2 项：标签拖拽态轻微放大和更强阴影。
  - 提交: 本次提交
  - 结果: 长按标签进入可移动状态后，拖拽中的标签用 `1.04x` layer transform 做视觉放大，并进一步增强阴影和层级。
  - 范围: 只改 AppKit 标签按钮拖拽态 CALayer 外观；未改变真实 frame、排序命中、持久化、窗口层级。
  - 验证: 构建 `7.6.0 (20260528.2343)`、签名、静态 QA、顶部/左/右三种标签栏拖拽排序、视觉屏幕复核、窗口 8 逻辑 QA 全部通过；QA 后已恢复用户标签顺序和语言自动设置；用户已确认测试通过。

- [2026-05-28] 第二批 AppKit 化第 4.1 项：标签拖拽态浮起阴影。
  - 提交: 本次提交
  - 结果: 长按标签进入可移动状态后，正在拖拽的标签使用更强阴影和更高层级，视觉上更明确地浮在其他标签上方。
  - 范围: 只改 AppKit 标签按钮拖拽态视觉；未改排序命中、持久化、窗口层级。
  - 验证: 构建 `7.6.0 (20260528.2312)`、签名、静态 QA、顶部/左/右三种标签栏拖拽排序、视觉屏幕复核、窗口 8 逻辑 QA 全部通过；QA 后已恢复用户标签顺序和语言自动设置。

- [2026-05-28] 第二批 AppKit 化第 4 项：标签栏 AppKit 化第三阶段，拖拽排序。
  - 提交: 本次提交
  - 结果: AppKit 标签栏已支持长按拖拽排序；排序命中改为 AppKit button frame hit-testing；持久化继续走 `TagEditor.reorderTags`。
  - 验证: 构建 `7.6.0 (20260528.2052)`、签名、静态 QA、顶部/左/右三种标签栏拖拽排序、`tags.json` 持久化、窗口 8 逻辑 QA 全部通过；QA 后已恢复用户标签顺序和语言自动设置。

- [2026-05-28] 第二批 AppKit 化第 3 项：标签栏 AppKit 化第二阶段，hover 与容器高亮。
  - 提交: `9d87dbe`
  - 结果: 标签 hover 进入/离开已接入 AppKit；hover 高亮只刷新可见运行态，不触发 App Grid reload；重复 hover 滚动已去抖。
  - 验证: 构建、签名、本地化 JSON、hover 静态 QA、colorless grid 屏幕 hover/点击复核、窗口 8 逻辑 QA 全部通过；用户已确认第 3 项 OK。

- [2026-05-28] 第二批 AppKit 化第 2 项：标签栏 AppKit 化第一阶段，只读导航。
  - 提交: `b4a1ba5`
  - 结果: 默认启用 AppKit 标签导航，顶部/左侧/右侧标签栏显示和点击滚动接入完成；`useAppKitTagNavigation=false` 可回滚到旧 SwiftUI 标签栏。
  - 验证: 构建、签名、本地化 JSON、三种位置屏幕点击复核、SwiftUI 回滚开关、窗口 8 逻辑 QA 全部通过；用户已确认第 2 项 OK。

- [2026-05-28] 第二批 AppKit 化第 1 项：清理 `ContentView` 的 App Grid 交互职责。
  - 提交: `561541e`
  - 结果: `ContentView` 中 App Grid 的 bubble、drag、drop、refresh toast 临时状态已收口到 `AppGridInteractionState`。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、localization JSON 解析、App Grid targeted QA、`Scripts/window_logic_qa.sh` 全部通过；用户已确认第 1 项 OK。

- [2026-05-28] 冻结发布版本并从冻结 tag 拉出新需求分支。
  - 冻结 tag: `appstore-7.6.0-20260527.0124`
  - 新需求分支: `codex/post-freeze-new-requirement`
  - 说明: 新需求开发失败时可直接回到冻结 tag，不影响准备发布的版本。

- [2026-05-28] 新增“拖出容器空隙只移除来源标签”的确认逻辑。
  - 提交: `71bfdd4`、`da71eb5`
  - 行为: 非 Flat/list 的容器视图中，APP 拖到容器空隙时确认是否只移除来源容器对应的 1 个标签。
  - 补强: “知道了，以后不用再提醒我”改为清晰可见的自绘勾选框。
  - 验证: 用户已验证功能正常。
