# 8.0.0 App Grid 主题系统工作日志

## 2026-06-24

### 起点

- 分支：`codex/dark-glass-8.0.0`
- 基线：`v7.9.4-build20260619.2221`
- 目标：基于已认可方案实现 8 个高级渐变背景主题，并保留原浅色毛玻璃主题。
- 关键约束：主题切换只改 UI；不动标签、拖拽、排序、搜索、数据和 SmartStart 功能语义。

### 方案决策

- 8.0.0 先做“8 个高级渐变背景主题 + 自动玻璃适配”。
- 不做容器玻璃深浅的独立开关，降低设置复杂度和 QA 面。
- 默认主题使用浅色玻璃容器；深蓝和黑色使用深色半透明玻璃容器；粉色、紫色、绿色、蓝色、炫彩使用浅色玻璃容器，避免亮色主题被压成暗黑系。
- 渐变只在 App Grid 全屏背景层实现，单个容器内部不做独立渐变，避免视觉噪声。
- 炫彩主题取样自用户提供的 Meilang logo，使用青蓝、浅青、淡紫和粉色作为背景渐变来源，并降低饱和度保证可读性。

### 已完成实现

- 新增 `Apptag/AppGridTheme.swift`：
  - 主题枚举、存储 key、标题 key、背景渐变 token、预览色、玻璃适配策略。
- 修改 `AppDefaults.swift`：
  - 新增 `appGridThemeID` 默认值。
  - 将旧 `useDarkAppGrid=true` 迁移到 `deepBlue`。
- 修改 `ContentView.swift`：
  - App Grid 背景读取当前主题。
  - 默认主题保持原浅色视觉。
  - 黑色主题跳过毛玻璃背板，使用 100% 纯黑全屏背景。
  - 深蓝主题保留暗色渐变和轻暗化层。
  - 粉色、紫色、绿色、蓝色、炫彩使用更明亮的全屏渐变，不叠加暗化层。
- 修改 `AppGridCollectionView.swift`：
  - 容器、标题、分隔线按主题自动选择浅色/深色玻璃适配。
  - 深蓝和黑色为暗玻璃；亮色主题为浅玻璃。
  - 移除 AppKit 层旧的全屏背景渐变，避免 SwiftUI/AppKit 双背景叠加。
- 修改 `PreferencesView.swift`：
  - 新增“主题”tab。
  - 新增 8 个主题选择卡片和主题说明。
  - 移除 General 页旧“启用深色视图”入口。
- 更新 29 个 `Localization/*.json`：
  - 新增主题 tab、说明和 8 个主题名称。
  - 删除旧深色视图设置文案。
- 新增 `Scripts/theme_settings_qa.sh`。
- 新增根 `CODEGRAPH.md`，记录主题系统相关模块依赖。

### 2026-06-24 视觉反馈二次调色

- 用户反馈：默认和深蓝可接受；黑色需要纯黑；粉色和炫彩需要明亮、年轻；绿色需要像明亮草坪/绿树后的毛玻璃；紫色和蓝色需要与深蓝拉开差异。
- 调整结论：
  - 黑色：全屏背景为纯黑，不使用系统毛玻璃背板、不叠加渐变或暗化层。
  - 粉色：改为明亮粉、蜜桃和柔白高光，面向更年轻/少女取向。
  - 绿色：改为草坪绿、嫩绿和明亮高光，保持喜人而不沉闷。
  - 紫色：改为浅薰衣草到高饱和紫，和深蓝明显区分。
  - 蓝色：改为天空蓝、电光蓝和青色，和深蓝明显区分。
  - 炫彩：回到 Meilang logo 的青蓝、浅青、淡紫、亮粉取色方向，整体变亮。
  - 亮色主题统一改回浅色玻璃容器；深色玻璃仅保留给深蓝和黑色。

### QA 记录

- `bash build.sh`：PASS，生成 `src/build/TagLauncher.app`。
- `codesign --verify --deep --strict --verbose=2 src/build/TagLauncher.app`：PASS。
- 29 个 localization JSON 解析：PASS。
- `bash src/Scripts/theme_settings_qa.sh`：PASS，覆盖 8 主题、主题 tab、偏好迁移、纯黑策略、亮色主题浅玻璃策略和 29 语种文案。
- `bash src/Scripts/macos14_availability_typecheck_qa.sh`：PASS。
- `bash src/Scripts/macos14_build_metadata_qa.sh`：PASS。
- `bash src/Scripts/tag_navigation_hover_scroll_qa.sh`：PASS。
- `bash src/Scripts/usage_tips_qa.sh`：PASS。
- `bash src/Scripts/app_ordering_data_qa.sh`：PASS。
- `bash src/Scripts/quick_search_system_app_qa.sh`：PASS。
- `bash src/Scripts/quick_search_app_name_qa.sh`：SKIP，本机未安装 QA fixture `/Applications/贝锐向日葵被控.app`。

### 2026-06-24 15:06 二次调色 QA 与预览包

- Build：`20260624.1506`
- `bash Scripts/theme_settings_qa.sh`：PASS。
- `bash Scripts/macos14_build_metadata_qa.sh`：PASS。
- `bash Scripts/macos14_availability_typecheck_qa.sh`：PASS。
- `APP_BUILD=20260624.1506 bash build.sh`：PASS。
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`：PASS。
- 构建产物版本：`8.0.0 (20260624.1506)`，`LSMinimumSystemVersion=14.0`。
- `bash Scripts/usage_tips_qa.sh`：PASS。
- `bash Scripts/tag_navigation_hover_scroll_qa.sh`：PASS。
- `bash Scripts/app_ordering_data_qa.sh`：PASS。
- `bash Scripts/quick_search_system_app_qa.sh`：PASS。
- `bash Scripts/apple_default_apps_resource_qa.sh`：PASS。
- `hdiutil verify build/TagLauncher-8.0.0-theme-preview-build20260624.1506.dmg`：PASS。
- DMG：
  - `src/build/TagLauncher-8.0.0-theme-preview-build20260624.1506.dmg`
- SHA256：
  - `c2704c435ef0b0ba8e3ea17824cbd3ffe89c118f34a966547b98ab6db96ebac5`

### QA 基础设施备注

- `Scripts/window_logic_qa.sh` 在本机 GUI 自动化环境中出现间歇性失败：
  - Dock 点击或全局热键偶发未触发 overlay。
  - Codex/输入法类 App 偶发抢前台，导致旧的 frontmost app 名断言误报。
- 已对该脚本做两类非产品逻辑加固：
  - Quick Search 结果坐标识别不再依赖固定窗口宽度，并在失败时输出窗口列表。
  - 前台 app 名断言降级为诊断信息，核心仍由窗口层级断言覆盖。
  - 启动与热键触发增加重试等待。
- 该脚本仍建议后续单独作为 QA 基础设施任务继续稳定化；本轮主题功能不依赖其失败点。

### 当前结论

- 8.0.0 主题系统代码已实现。
- 确定性 QA 已覆盖主题模型、设置入口、偏好迁移、多语种文案、构建签名、macOS 14 元数据、标签 hover、使用技巧、App 排序数据和系统 Quick Search 名称回归。
- 下一步需要用户实际体验 8 个主题的视觉效果，再决定是否冻结和打包。

### 2026-06-24 15:53 编辑模式主题对比度修正

- 用户反馈：亮色主题和黑色主题进入编辑模式后，顶部按钮、说明文字、确认按钮、标签列表和页面文字可读性不足。
- 第一版修正策略：
  - 编辑层控件接入主题高对比 token，深色主题白字、亮色主题深字。
- Build 更新为：`20260624.1553`。

### 2026-06-24 15:53 QA 与预览包

- `bash Scripts/theme_settings_qa.sh`：PASS。
- `bash Scripts/macos14_build_metadata_qa.sh`：PASS。
- `bash Scripts/macos14_availability_typecheck_qa.sh`：PASS。
- `APP_BUILD=20260624.1553 bash build.sh`：PASS。
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`：PASS。
- `bash Scripts/usage_tips_qa.sh`：PASS。
- `bash Scripts/tag_navigation_hover_scroll_qa.sh`：PASS。
- `bash Scripts/app_ordering_data_qa.sh`：PASS。
- `bash Scripts/apple_default_apps_resource_qa.sh`：PASS。
- `bash Scripts/quick_search_system_app_qa.sh`：PASS。
- 包内版本：`8.0.0 (20260624.1553)`，`LSMinimumSystemVersion=14.0`。
- `hdiutil verify build/TagLauncher-8.0.0-theme-preview-build20260624.1553.dmg`：PASS。
- DMG：
  - `src/build/TagLauncher-8.0.0-theme-preview-build20260624.1553.dmg`
- SHA256：
  - `543a2f26676f3e57aac0edb26353a8f90d38d3e0290dfd1c951e62b1f3e409ea`

### 2026-06-24 16:32 编辑模式主题策略简化

- 用户反馈：继续按主题适配编辑态仍然复杂，要求做减法。
- 新策略：
  - 用户进入编辑模式时，不管当前选择深蓝、黑色、粉色、绿色、炫彩或其他主题，App Grid 运行态渲染主题都临时切换为默认浅色毛玻璃。
  - 不写入 `appGridThemeID`，不改变设置页选择；退出编辑模式后自动恢复用户原主题。
  - App Grid 背景、AppKit collection renderer、编辑页顶部、标签列表、应用选择项都读取 `renderedAppGridTheme`。
  - `theme_settings_qa.sh` 增加运行态主题 override 检查，防止编辑态重新跟随用户主题。
- Build 更新为：`20260624.1632`。

### 2026-06-24 16:32 QA 与预览包

- `bash Scripts/theme_settings_qa.sh`：PASS。
- `bash Scripts/macos14_availability_typecheck_qa.sh`：PASS。
- `APP_BUILD=20260624.1632 bash build.sh`：PASS。
- `bash Scripts/macos14_build_metadata_qa.sh`：PASS。
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`：PASS。
- `bash Scripts/usage_tips_qa.sh`：PASS。
- `bash Scripts/tag_navigation_hover_scroll_qa.sh`：PASS。
- `bash Scripts/app_ordering_data_qa.sh`：PASS。
- `bash Scripts/quick_search_system_app_qa.sh`：PASS。
- `bash Scripts/apple_default_apps_resource_qa.sh`：PASS。
- 包内版本：`8.0.0 (20260624.1632)`，`LSMinimumSystemVersion=14.0`。
- `hdiutil verify build/TagLauncher-8.0.0-theme-preview-build20260624.1632.dmg`：PASS。
- DMG：
  - `src/build/TagLauncher-8.0.0-theme-preview-build20260624.1632.dmg`
- SHA256：
  - `34962ce1f3114a0b4979125fa92cd788833593ac19173365434c717bd8f159bc`

### 2026-06-24 17:31 App Grid 启动加载体验修复

- 用户反馈：每次启动/打开 App Grid 都出现转圈等待，观感不好，且此前类似问题曾修过。
- 根因结论：
  - App 启动时只预热 `AppIndexer` 的进程内扫描缓存。
  - 每次显示 App Grid 都会新建 `OverlayWindow + ContentView`，新的 `ContentView.allApps` 初始为空。
  - 在后台 `AppLibraryController.refresh()` 返回前，空态直接显示 `ProgressView`，因此用户能看到转圈。
  - 旧修复解决的是“缓存已热但新 ContentView 跳过 hydrate 导致 spinner 不消失”，没有解决冷启动或新面板首屏空态可见。
- 本轮修复：
  - `AppLibraryController` 保存最近一次完整 `AppLibrarySnapshot`。
  - `ContentView.refreshAppsForOverlay()` / `refreshAppsForQuickSearch()` 先复用最近快照，再后台刷新。
  - AppGrid 和编辑 AppGrid 的空态 spinner 改成 250ms 延迟显示；如果快照或扫描快速返回，不再闪现转圈。
  - 新增 `Scripts/appgrid_startup_loading_qa.sh` 锁住快照复用与延迟 spinner 规则。

### 2026-06-24 18:15 QA 与验收候选包

- 包类型：验收候选包，仅供用户安装验证；本轮未做源码冻结、commit 或 tag。
- Build 更新为：`20260624.1815`。
- `bash Scripts/theme_settings_qa.sh`：PASS。
- `bash Scripts/appgrid_startup_loading_qa.sh`：PASS。
- `bash Scripts/macos14_availability_typecheck_qa.sh`：PASS。
- `APP_BUILD=20260624.1815 bash build.sh`：PASS。
- `/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist`：`8.0.0`。
- `/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist`：`20260624.1815`。
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`：PASS。
- `bash Scripts/macos14_build_metadata_qa.sh`：PASS，`LSMinimumSystemVersion=14.0`，`minos=14.0`，`arches=arm64`。
- `hdiutil verify build/TagLauncher-8.0.0-build20260624.1815.dmg`：PASS。
- DMG：
  - `src/build/TagLauncher-8.0.0-build20260624.1815.dmg`
- SHA256：
  - `373355c87055680cb13e873bc5909abd84817d9ac2eaa98cc1ec2748be64bc80`

### 2026-06-24 23:41 使用技巧横幅重设计

- 用户确认最终方案：
  - 布局选“2 分区式教学横幅”。
  - 亮色主题使用浅玻璃配色。
  - 深色/黑色主题使用同样布局，但切换到深色玻璃材质和白色文字。
- 角色分工结论：
  - 架构：继续使用原生 AppKit `AppGridUsageTipsNSView`，不引入 SwiftUI；tips 跟随 `renderedAppGridTheme`，编辑模式仍继承默认浅色主题 override。
  - 代码审核：保留全宽透明 shield 和 local mouse monitor，避免点击穿透到底层 AppGrid；箭头只在命中区域触发翻页。
  - QA：更新 `usage_tips_qa.sh`，覆盖分区式布局、主题配色、关闭按钮、全宽事件拦截、29 语种文案和 macOS 14 兼容。
- 本轮实现：
  - 使用技巧横幅底部横向占满可用宽度。
  - 左侧独立标题面板显示灯泡图标、技巧编号和标题。
  - 中央正文区域展示两行动作说明，保留长文本横向滚动能力。
  - 右侧固定上一条/下一条按钮，页点移动到箭头下方。
  - 右上角新增弱视觉关闭按钮；默认半透明，hover/press 更清晰；点击后写入 `hideUsageTips`。
  - `updateColors()` 按 `AppGridTheme.usesDarkGlass` 切换浅玻璃/深玻璃 token。
  - 29 个语种新增 `usageTips.close`。
- QA：
  - `bash Scripts/usage_tips_qa.sh`：PASS。
  - `bash Scripts/macos14_availability_typecheck_qa.sh`：PASS。
  - `git diff --check`：PASS。
  - `bash build.sh`：PASS，生成 `src/build/TagLauncher.app`。
  - `bash Scripts/macos14_build_metadata_qa.sh`：PASS，`LSMinimumSystemVersion=14.0`，`minos=14.0`，`arches=arm64`。
  - `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`：PASS。
  - 构建产物版本：`8.0.2 (20260625.1322)`。
  - `bash Scripts/theme_settings_qa.sh`：PASS。
  - `bash Scripts/tag_navigation_hover_scroll_qa.sh`：PASS。
  - `bash Scripts/macos14_availability_typecheck_qa.sh`：PASS。
  - `APP_BUILD=20260624.2331 bash build.sh`：PASS。

### 2026-06-25 使用技巧横幅 26.0625-2 视觉优化

- 需求来源：`canvas/26.06-UI调整.excalidraw` frame `26.0625-2`。
- 用户标注问题：
  - 标题区空间充裕但排版仍显拥挤。
  - 标题字号偏小，需要适当放大并加粗，同时不能撑破 29 语种矩形空间。
  - 标题字色需要按主题优化，必须保持清晰可读。
  - 标题前 icon 不应固定为单一灯泡，需要按技巧类型变化。
  - 正文超过一行时应采用 ordered list 样式。
  - 第 1 条标题改为“编辑标签”，正文补充“打开设置切换到标签编辑”和“在标签列表双击标签快速进入标签编辑页”。
  - 以上文案修改覆盖 29 个语种。
- 本轮实现：
  - `AppGridUsageTipsNSView` 标题字号从 22 semibold 调整为 25 bold。
  - 左侧标题面板宽度从 300-380pt 扩展为 350-460pt，降低长语种标题换行/挤压风险。
  - 标题和 icon 改为按 `AppGridTheme` 取高对比 accent；深蓝/黑色主题继续使用白字优先。
  - 按 tip id 切换语义 SF Symbol：编辑标签、套用标签、移动、复制、移除、排序、备注等不再共用灯泡 icon。
  - 正文 formatter 保留分隔符转换规则，并在多段内容时自动渲染为 `1.` / `2.` 编号步骤。
  - 第 1 条使用技巧 29 个语种 title/detail 已同步更新。
  - `Scripts/usage_tips_qa.sh` 增加标题字号、标题面板宽度、语义 icon、主题 accent、ordered list 和第 1 条双击标签说明检查。
- QA：
  - `bash Scripts/usage_tips_qa.sh`：PASS。
  - `bash Scripts/macos14_build_metadata_qa.sh`：PASS，`LSMinimumSystemVersion=14.0`，`minos=14.0`，`arches=arm64`。
  - `bash Scripts/appgrid_startup_loading_qa.sh`：PASS。
  - `bash Scripts/app_ordering_data_qa.sh`：PASS。
  - `bash Scripts/apple_default_note_policy_qa.sh`：PASS。
  - `bash Scripts/apple_default_apps_resource_qa.sh`：PASS。
  - `bash Scripts/quick_search_app_name_qa.sh`：SKIP，本机没有 `/Applications/贝锐向日葵被控.app` fixture。
  - `bash Scripts/window_logic_qa.sh`：未作为本轮通过项；脚本在 Dock tile 去重检查处失败，退出后无 TagLauncher 进程残留，判断为 GUI/Dock 可访问性环境或既有 QA 基础设施问题，和本轮使用技巧横幅代码路径无直接交集。
- 版本推进到：`8.0.2 / 20260624.2341`。
