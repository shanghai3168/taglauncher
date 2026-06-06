# TagLauncher 7.8.15 App Store 上架文案与卖点手册

生成日期：2026-06-05  
适用版本：**7.8.15** / Build **20260605.2337**  
用途：App Store Connect 填写、审核沟通、官网/支持页引用。

---

## 一、产品一句话定位

**中文：** TagLauncher 是用「标签」而不是「文件夹」管理 Mac 应用的启动器——一屏浏览、多标签归类、可写备忘、布局可备份，用快捷键比 Launchpad 更快找到应用。

**English：** TagLauncher is a tag-based Mac app launcher: browse apps on one scrollable grid, assign multiple tags, add notes, back up your layout, and open apps faster than Launchpad with global hotkeys.

---

## 二、相对 macOS Launchpad 的核心优势（上架重点）

你关心的四点，加上产品本身能力，建议对外统一成下面这张对比表（审核备注、描述、官网都能用）。

| 维度 | macOS Launchpad | TagLauncher |
|------|-----------------|-------------|
| **浏览方式** | 分页翻屏，一屏只能看一部分图标 | **可滚动的大网格**，连续浏览，减少「找图标在哪一页」的心智负担 |
| **归类逻辑** | 主要靠**文件夹**，一个 App 通常只能放进一个文件夹 | **标签（Tag）**：同一 App 可同时属于多个标签（如「设计」+「办公」） |
| **备忘说明** | 几乎无法给单个 App 写用途说明 | 支持 **App 用途备忘**，Quick Search 也能搜到备注 |
| **布局备份** | 用户布局难以导出、迁移、恢复 | **一键导出/导入 JSON**，换机或重装后可恢复分类与布局 |
| **启动方式** | 手势或 F4，与全屏/多桌面体验一般 | **全局快捷键**（默认 Option-Shift-Space）+ **Quick Search**（Fn+Space） |
| **搜索** | 系统聚焦搜索，不按你的标签体系组织 | 搜 **应用名、标签、备忘**，支持拼音等候选（视语言环境） |
| **显示样式** | 固定 Launchpad 样式 | 多种列表样式（平铺 / 容器 / 网格）、可调图标大小、标签栏位置 |
| **多显示器 / 全屏** | 易触发 Space 切换等干扰 | 针对全屏、Split View、多屏做了窗口层级优化 |
| **智能整理** | 无 | **Smart Start** 可按场景给新应用建议标签（可选应用） |

### 可写进「What's New / 审核说明」的短句（中文）

- 不用 Launchpad 翻页找图标：打开即是可滚动的应用网格。  
- 不用文件夹硬塞分类：一个 App 可挂多个标签，贴近真实使用场景。  
- 给常用/不常用 App 写用途备忘，搜索时直接命中。  
- 分类与布局可导出 JSON，备份、迁移、恢复都方便。

---

## 三、产品功能卖点清单（来自帮助文档与 7.8.x 能力）

填写描述时可从中勾选，不必全部塞进 4000 字上限。

### 启动与效率

- 全局快捷键唤起 **App Grid**（默认 `Option-Shift-Space`）
- **Quick Search**：在网格内按 `Space`，或 `Fn+Space` 快速搜索
- 支持菜单栏常驻、可选登录启动、可选隐藏 Dock 图标
- 多显示器、全屏 Space 场景下仍可在当前空间使用

### 整理与浏览

- 自定义标签：新建、配色、排序、侧边/顶部导航
- **五种应用列表样式**：平铺、无色/彩色容器、无色/彩色网格
- 可调图标大小、标签字号、是否显示应用名
- 编辑模式：批量给多个 App 添加/移除标签
- 拖拽：App 图标拖到标签名上即可建立关联
- 「不常用」分组 + 气泡提示（大号名称 + 备忘）

### 搜索与记忆

- 搜索范围：应用名、标签名、用途备忘
- 本地索引扫描已安装应用（含部分系统目录应用，如钥匙串访问）
- 应用目录变化时轻量刷新，避免每次打开都全量重扫

### 数据与迁移

- **导出 / 导入**「分类与布局」JSON（设置 → 数据）
- 本地存储，无账号、无云端上传（隐私友好）

### 语言与帮助

- 应用内 **29 种界面语言**（设置中切换）
- 内置多语言帮助 PDF（GitHub Release 托管）

### 7.8.15 本次更新（What's New 必写）

- 修复再次打开 App Grid 时可能一直转圈的问题  
- 启动后后台预热应用索引，首次打开更快  
- 延续 7.8.14：CoreServices 系统应用（如钥匙串访问）可检索  

---

## 四、App Store Connect 字段（可直接复制）

以下按 [App Store Connect](https://appstoreconnect.apple.com/) 常见字段整理。字符数请在提交前用 Connect 界面再核对（不同地区略有差异）。

### 4.1 基础信息

| 字段 | 建议值 |
|------|--------|
| **Name** | TagLauncher |
| **Subtitle（≤30 字符）** | 见下方中英备选 |
| **Bundle ID** | com.taglauncher.app |
| **SKU** | taglauncher-macos |
| **Primary Category** | Utilities |
| **Secondary Category（可选）** | Productivity |
| **Copyright** | © 2026 海南万幸科技有限公司 / Hainan Wanxing Technology Co., Ltd. |
| **Minimum macOS** | 15.0 |

**Subtitle 备选（任选其一，注意 30 字符限制）**

| 语言 | 文案 | 说明 |
|------|------|------|
| 英文 | `Tags, notes, one grid` | 24 字符 |
| 英文 | `Beyond Launchpad folders` | 26 字符 |
| 英文 | `Tag-based app launcher` | 22 字符 |
| 简体中文 | `标签启动器，胜过启动台` | 需数 Connect 是否按字符计 |
| 简体中文 | `多标签、可备忘、可备份` | 强调差异点 |

推荐英文主字幕：**`Tag-based app launcher`** 或 **`Beyond Launchpad folders`**。

---

### 4.2 关键词 Keywords（≤100 字符，逗号分隔，不要重复 App 名称）

**English（99 字符示例）**

```text
launcher,launchpad,tags,apps,organizer,notes,backup,hotkey,search,utility,macos,productivity
```

**简体中文（若 Connect 该本地化支持关键词）**

```text
启动器,启动台,标签,应用,整理,备忘,备份,快捷键,搜索,效率,工具,Mac
```

说明：App Store **不会**把关键词当 SEO 堆砌排名用，但可覆盖用户搜索习惯词；避免空格占额度，用英文逗号。

---

### 4.3 推广文本 Promotional Text（≤170 字符，可随时改，无需新版本）

**English**

```text
Tired of flipping Launchpad pages? TagLauncher shows a scrollable app grid, multi-tag apps, per-app notes, and JSON layout backup—open with Option-Shift-Space.
```

**简体中文**

```text
厌倦启动台翻页？TagLauncher 用可滚动应用网格、多标签归类、应用备忘和布局备份，Option-Shift-Space 一键唤起。
```

---

### 4.4 描述 Description（建议英文为主语言撰写，≤4000 字符）

#### English（主描述，可直接粘贴）

```text
TagLauncher is a tag-based launcher for Mac power users who have outgrown Launchpad.

WHY NOT JUST LAUNCHPAD?
• One scrollable grid instead of flipping through pages to find an icon
• Tags instead of folders—put the same app in Design and Work at once
• Per-app notes you can search later (purpose, version, reminders)
• Export and import your categories and layout as JSON—easy backup and migration

HOW YOU WORK WITH TAGLAUNCHER
• Press Option-Shift-Space to open the App Grid over your current Space
• Press Space in the grid (or Fn+Space) for Quick Search across apps, tags, and notes
• Create colored tags, drag apps onto tag names, and batch-edit assignments
• Choose list styles: flat, containers, or aligned grids; tune icon and tag sizes
• Mark rarely used apps as Uncommon and show a large name + note bubble on hover
• Optional Smart Start suggestions to categorize newly installed apps
• Import/export your layout from Settings → Data

BUILT FOR REAL MAC SETUPS
• Works with multiple displays and fullscreen Spaces
• Menu bar access, optional login item, optional Dock icon
• Local-only indexing—no account, no analytics SDK in this build
• Interface available in 29 languages inside the app

TagLauncher helps you see all your apps, organize them the way you actually think, and launch them in seconds—without hunting through Launchpad pages or single-folder limits.
```

#### 简体中文（若添加「简体中文」本地化，可粘贴）

```text
TagLauncher 是一款面向「应用很多」的 Mac 用户的标签化启动器——当你觉得启动台不够用，它会是一个更顺手的日常入口。

为什么不只是启动台？
• 可滚动的应用网格，不必一页一页翻图标
• 用标签代替文件夹：同一个 App 可同时属于「设计」「办公」等多个标签
• 给每个 App 写用途备忘，之后搜索直达
• 分类与布局可导出/导入 JSON，备份、换机、恢复都方便

日常使用
• Option-Shift-Space 打开应用网格，覆盖在当前空间之上
• 在网格内按 Space，或 Fn+Space 打开 Quick Search，搜索应用、标签与备忘
• 自定义彩色标签，拖拽图标到标签名即可归类，支持批量编辑
• 五种列表样式、可调图标与标签字号
• 「不常用」应用可显示大号名称与备忘气泡
• 可选 Smart Start，为新安装应用建议标签
• 设置 → 数据：导出/导入布局

为真实 Mac 场景设计
• 多显示器、全屏与 Split View 场景优化
• 菜单栏、登录启动、Dock 显示可配置
• 本地扫描与本地数据，无需账号
• 应用内提供 29 种界面语言

TagLauncher 让你一屏掌握应用、按真实习惯归类，并用快捷键秒开——告别启动台翻页和「一个 App 只能进一个文件夹」的限制。
```

---

### 4.5 此版本更新 What's New（7.8.15）

**English**

```text
• Fixed an issue where the App Grid could stay on a loading spinner when reopened
• Faster first open by warming the app index in the background at launch
• Still includes improved discovery for system apps such as Keychain Access (from 7.8.14)
```

**简体中文**

```text
• 修复再次打开应用网格时可能一直转圈的问题
• 启动后后台预热应用索引，首次打开更快
• 继续支持钥匙串访问等 CoreServices 系统应用的检索（7.8.14）
```

---

### 4.6 审核备注（给 App Review，见 `Review/APP_REVIEW_NOTES.md`）

补充一句与 Launchpad 的差异即可，避免过长：

> TagLauncher is an alternative to Launchpad for users who want multi-tag organization, per-app notes, and exportable layouts. It does not replace or modify system Launchpad; it adds a separate overlay invoked by hotkey.

---

## 五、截图与副图文案建议（8 张，沿用 7.8.14 资产）

| 顺序 | 画面建议 |  caption 思路（可选，部分商店支持） |
|------|----------|-------------------------------------|
| 1 | App Grid + 顶部标签 | 一屏浏览，无需像启动台那样翻页 |
| 2 | Quick Search 输入 | 搜应用、标签、备忘 |
| 3 | 编辑标签 / 多标签 | 一个 App，多个标签 |
| 4 | 用途备忘气泡 | 给 App 写说明，不再忘记用途 |
| 5 | 设置 → 数据 导出 | 布局 JSON 备份与恢复 |
| 6 | 多种列表样式 | 平铺 / 网格 / 容器 |
| 7 | 全屏场景下的网格 | 全屏 Space 仍可用 |
| 8 | 设置 / 语言 | 29 种界面语言（应用内） |

7.8.15 为修复版，**无需重截**，见 `Screenshots/SCREENSHOT_SHOT_LIST.md`。

---

## 六、29 种语言：应用内 vs App Store 资料（建议读这一节）

### 结论（直接建议）

| 类型 | 是否必须 29 种 | 建议 |
|------|----------------|------|
| **应用内界面**（你已做） | 否，但已是产品亮点 | 保持 29 种；设置里可切换 |
| **App Store Connect 商店文案** | **否** | **首版先做好 2 种：英文 + 简体中文** |

不必为上架第一天准备 29 套商店描述、关键词和截图说明。

### 原因说明

1. **Apple 不要求**商店本地化数量与应用内语言一致。没有填写的语言会回退到「主要语言」（Primary Language）。
2. **维护成本**：29 套描述 + 关键词 + 推广文本 + What's New，每次发版都要同步，极易漏翻或过时。
3. **转化优先级**：Mac App Store 流量仍以 **English** 为主；若你主要面向中文用户，再加 **简体中文** 即可覆盖大部分需求。
4. **繁体、日文、韩文**等：有精力时作为 **第二批** 在 Connect 里「添加本地化」，不必阻塞首次提交。

### 推荐上架语言策略（分阶段）

**阶段 A — 首次提审（现在）**

- Primary Language：**English（U.S.）** 或 **English（Australia）**（二选一，全文案用英文填齐）
- 额外本地化：**简体中文（中国）**（描述 + 关键词 + What's New + 推广文本）
- 截图：一套即可（界面已是多语言，不必 29 套截图）

**阶段 B — 上架后 1～2 个版本**

按下载地区加：**繁体中文（台湾）**、**日语**、**韩语**、**德语**、**法语**（选你真有用户的地区）

**阶段 C — 长期**

其余语言可逐步补；或仅保留应用内 29 语言，商店仍用英文主文案（很多独立开发者这样做）。

### 和「29 种语言」卖点的关系

- **在英文/中文描述里写一句**：「App interface available in 29 languages」——这是事实，也是差异化，**不需要**为 29 种各写一整页商店文案。
- 帮助 PDF 已有 29 语言，上架后可在支持页放链接，不必全部搬进 Connect。

---

## 七、Connect 填写顺序 checklist（今日上架）

- [ ] 创建/确认 App 记录，Bundle ID `com.taglauncher.app`
- [ ] Primary Language：English，粘贴第四节英文稿
- [ ] 添加本地化：简体中文，粘贴中文稿
- [ ] Subtitle、Keywords、Promotional Text、Description、What's New
- [ ] 上传 8 张截图（`Screenshots/AppStore/`）
- [ ] 隐私政策 URL、支持 URL（公开可访问）
- [ ] App Privacy 问卷（本地数据、不收集个人数据为主）
- [ ] 上传 build `20260605.2337`（签名 pkg，非 DMG）
- [ ] 审核备注引用 Launchpad 差异与测试步骤（`Review/APP_REVIEW_NOTES.md`）

---

## 八、相关文件

| 文件 | 用途 |
|------|------|
| `APP_STORE_CONNECT_METADATA.md` | 精简版元数据草稿 |
| `Review/APP_REVIEW_NOTES.md` | 审核操作步骤 |
| `APP_STORE_RELEASE_CHECKLIST.md` | 提交前清单 |
| `BUILD_SIGN_UPLOAD.md` | 证书签名与 pkg 上传 |
| `Docs/Help/v7.6.0/Taglauncher-help-zh.pdf` | 用户帮助（功能细节） |

---

*本文档随 7.8.15 发布包维护；下次发版请同步更新 What's New 与版本号。*