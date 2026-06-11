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

- [7.9.0 大需求] 容器内 App 手动拖拽排序。
  - 状态: 方案已确认，详细 TODO 和过程文档已归档到 `../Docs/7.90/`。
  - 版本: 后续实现从 `7.9.0` 开始记录，不混入 `7.8.x` 小版本。
  - 入口: `../Docs/7.90/README.md`、`../Docs/7.90/01-容器内App手动排序-TODO.md`、`../Docs/7.90/02-专题讨论纪要.md`。

- [发布后独立任务] 设置页 tab 容器 AppKit/自控化评估与实现。
  - 决策: 当前发布前 No-Go；保留 SwiftUI `TabView`，不改 QA 脚本。
  - 背景: QA 过程中曾观察到设置页顶部 tab 偶发折叠/消失，但目前不是稳定可复现 release blocker。
  - 约束: 必须单独开分支、单独提交、单独构建、单独 QA、单独验收；不得混入当前 quick search/window 修复或 App Store 发布包。
  - 改动边界: 优先只改 `Apptag/PreferencesView.swift`；不碰 `AppDelegate`、`OverlayWindowController`、窗口层级、quick search、App Grid、数据导入导出逻辑。
  - 风险点: 需要保留 Language/General/Hotkeys/Tags/Data/About 六页行为；特别注意 `Tags` 页 `scanApps()`、`Data` 页 `refreshDataState()`、语言热切换、toast/confirmation overlay、固定 `880x460` 布局高度和 accessibility。
  - 验证要求: `bash build.sh`、`codesign --verify --deep --strict`、`Scripts/window_logic_qa.sh`；手工复核 6 个设置页、全屏/Split View 中 Settings 层级、文件面板层级、长文本语言和键盘/辅助功能导航。

## Done

- [2026-06-09] 多语种 App 显示名通用加固。
  - 结果: 新增统一 `AppDisplayNameResolver`；App Grid 与 Quick Search 标题优先走当前语种/同语系/系统可见名/英文官方名/基础 bundle 名 fallback，内部 bundle 名和 bundle id 只作为搜索别名；`7.8.26` 进一步加固 `/Wrapper/`、`/Contents/Helpers/`、`.app/.../*.app` 内部 helper 过滤。
  - 范围: `AppInfo` 增加系统显示名与 bundle 显示名候选；App 扫描层和 Quick Search 文档层都过滤内部 helper；Quick Search 文档使用 resolver 生成别名；版本更新为 `7.8.26 (20260609.2004)`。
  - 不改范围: 未做第三方 App 名称机器翻译，未改 Quick Search 排名算法、App Grid 布局、窗口层级或 Smart Start 分类规则。
  - 验证: `APP_BUILD=20260609.2004 bash build.sh`、`codesign --verify --deep --strict src/build/TagLauncher.app`、`Scripts/quick_search_app_name_qa.sh`、`Scripts/quick_search_system_app_qa.sh` 通过；构建产物 Info.plist 为 `7.8.26 (20260609.2004)`。

- [2026-06-09] 修复首安 Smart Start 提示确认后 App Grid 消失的问题。
  - 结果: Smart Start 自动整理完成提示出现期间会抑制 AppKit 级 backdrop dismiss；点击“OK/好的”只关闭提示弹窗，不再关闭整个 App Grid。
  - 范围: 只改 `ContentView.swift` 的 modal interaction 发布状态，不改 Smart Start 分类规则、不改 App Grid 布局、不改窗口层级。
  - 验证: `APP_BUILD=20260609.1221 bash build.sh`、`codesign --verify --deep --strict build/TagLauncher.app`、版本/build/category 检查、Apple 默认资源 QA、SmartStart catalog QA 通过；首安真实点击路径待最终视觉验收。

- [2026-06-08] 修复 App Grid 顶部 tag hover 触发自动滚动导致的抖动。
  - 结果: hover 只保留 tag 高亮/填色，不再自动滚动；点击 tag 仍滚动到对应分组。
  - 范围: 只改 `Apptag/ContentView.swift` 的 tag hover 处理，不改 App Grid 布局算法、不改拖拽、不改点击导航语义。
  - 验证: `bash build.sh` 和 `codesign --verify --deep --strict build/TagLauncher.app` 通过；用户使用新版后确认仍有轻微小抖，但效果可接受，本轮不继续扩大修复范围。

- [2026-06-04] 修复新安装 App 后 App Grid / Quick Search 不能立即检索到的问题。
  - 提交: 本次提交
  - 结果: App Grid / Quick Search 打开时先轻量检查标准应用目录签名；签名未变化时不刷新也不重建界面，目录变化时才后台重扫应用索引。
  - 范围: 不改搜索匹配规则、不改 App Grid 布局、不改窗口层级策略；只收敛应用索引刷新触发条件和 QA 脚本稳定性。
  - 验证: 本地 `7.8.13 (20260604.1121)` targeted 输入 `notch` 命中 `TheBoringNotch` 且无“未找到”；`APP_BUILD=20260604.1121 zsh ./build.sh`、签名/版本校验、`Scripts/window_logic_qa.sh` 全部通过。

- [2026-06-04] 修复 Quick Search 刚打开即被过期 dismiss 事件关闭的 QA 失败。
  - 提交: 本次提交
  - 结果: quick-search-only 模式会忽略打开初期的过期鼠标/背板关闭事件；键盘 Esc 和再次按 `Fn + Space` 仍立即关闭；QA 脚本对合成 `Fn + Space` 投递增加重试，并把结果点击坐标修正到首条结果行中心。
  - 范围: 不改搜索匹配、App Grid 布局、Settings、文件面板或窗口层级策略。
  - 验证: targeted 两段式 `Fn + Space` 打开/关闭通过；targeted 点击 Quick Search 结果后窗口数为 0；`Scripts/window_logic_qa.sh` 全部通过。

- [2026-05-29] 版本拆分与 7.8.1 默认图标大小调整。
  - 提交: 本次提交
  - 结果: `CHANGELOG.md` 已补充 `7.7.0`、`7.8.0`、`7.8.1` 三段版本记录；源码版本号更新为 `7.8.1`；新用户默认 `iconSize` 从 `80` 调整为 `64`。
  - 范围: 只影响无既有 `iconSize` 偏好设置的新安装用户；已有用户保存过的图标大小不会被覆盖。
  - 验证: 构建、签名、DMG 校验。

- [2026-05-29] 第二批：AppGrid 滚动流畅性优化。
  - 提交: 本次提交
  - 结果: AppGrid 滚动期间只在滚动 burst 开始时通知 SwiftUI 清理 hover 气泡，不再每次 bounds 变化重复写状态；滚动停止后再恢复 hover replay 和 visible item runtime state。
  - 范围: 不改布局算法、不改拖拽、不改 hover 气泡展示规则，只降低滚动期间的刷新频率。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、`Scripts/window_logic_qa.sh` 全部通过；滚动后 Space/Esc 连续循环 QA 保持通过。

- [2026-05-29] 第一批：未分类拖拽确认记忆 + 滚动后键盘兜底。
  - 提交: 本次提交
  - 结果: “拖到未分类”弹窗新增独立“不再提醒”checkbox 和 `skipUncategorizedDropConfirm` 持久化；overlay 键盘处理增加 AppKit `sendEvent` 兜底；AppGrid 滚轮进入时重新声明 key/front，避免滚动后 Space/Esc 偶发丢失。
  - 范围: 不改拖到空隙移除单标签语义；不改全屏/Split View 窗口层级；不改 Quick Search 独立面板结构。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、`Scripts/window_logic_qa.sh` 全部通过；新增滚动后 Space/Esc 连续循环 QA；屏幕 smoke 验证滚动后 Space 打开 Quick Search、Esc 关闭 Quick Search、再次 Esc 关闭 AppGrid。

- [2026-05-29] 设置页和 Smart Start 模块化。
  - 提交: 本次提交
  - 结果: `SmartStartNoticeOverlay` 已从 `ContentView` 拆出；设置页“应用系统智能化初始分类”的扫描、Smart Start 应用和 snapshot 组装改由 `AppLibraryController` 统一处理；窗口 QA 脚本同步适配 `OverlayWindowController` 的屏幕选择静态检查。
  - 范围: 不改设置页 UI 布局、不改 Smart Start 分类规则、不改导入/导出/恢复行为。
  - 验证: `bash build.sh`、`codesign --verify --deep --strict`、设置页语言/通用/快捷键/标签/数据/关于六个 tab 屏幕复核、`Scripts/window_logic_qa.sh` 全部通过。

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
