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

- [2026-05-28] Quick Search 结果列表 AppKit 化。
  - 目标: 先只替换结果列表，不动独立面板。
  - 保持: 输入框、搜索逻辑、快捷键行为不变。
  - 验收: 默认选中、上下键、Return、滚动、鼠标 hover、无结果状态。

- [2026-05-28] Quick Search 独立面板化。
  - 目标: 从主 overlay 里拆出来，做 Spotlight 风格独立 `NSPanel`。
  - 风险: 高，涉及焦点、Esc、外部点击、全局快捷键、窗口层级。
  - 验收: 普通桌面、全屏、Split View、Settings 同时存在时都不跳 Space。

- [2026-05-28] OverlayWindowController 收口。
  - 目标: 把 `AppDelegate` 里的 overlay 显示、隐藏、层级、屏幕选择拆出去。
  - 时机: Quick Search 窗口边界稳定后再做。
  - 验收: 全屏、Split View、Settings、Force Quit、文件面板、Dock 图标重复问题。

- [2026-05-28] AppLibraryController / 数据刷新管线整理。
  - 目标: 把扫描、reconcile、Smart Start、annotate、Quick Search documents 更新从 `ContentView` 中抽离。
  - 验收: 启动扫描、拖拽改标签、Quick Search 索引同步、新安装 App 后刷新。

- [2026-05-28] 设置页和 Smart Start 模块化。
  - 目标: 低频路径后置整理。
  - 验收: 语言、通用、快捷键、标签、数据、关于页都保持现有行为。

## Done

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
