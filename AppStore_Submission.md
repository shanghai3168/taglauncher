# Apptag — Mac App Store 提审资料

> 版本: 5.7.5 | Bundle ID: com.apptag.launcher | 更新日期: 2026-05-14

---

## 1. App 基本信息

| 字段 | 内容 |
|---|---|
| **App 名称** | Apptag |
| **副标题** | Tag-Based App Launcher |
| **Bundle ID** | com.apptag.launcher |
| **版本号** | 5.7.5 |
| **Build 号** | 575 |
| **SKU** | apptag-mac-001 |
| **主要类别** | Utilities (工具) |
| **次要类别** | Productivity (效率) |
| **售价** | 免费 |
| **最低系统** | macOS 15.0 |

> 当前 `Info.plist` 的 `LSMinimumSystemVersion` 为 `15.0`，与本次提审目标一致。

---

## 2. App 描述 (App Store Description)

### 英文 (Primary)

**Apptag** is a blazing-fast, tag-based app launcher for macOS. Press a hotkey, type a tag, and launch any app instantly — no mouse, no Dock, no hunting through folders.

**Why Apptag?**
- **Tag your way** — Group apps by project, workflow, or mood. "Design", "Coding", "Writing", "Games" — you decide.
- **Instant overlay** — Press Shift+Option+Space, and a full-screen overlay appears with all your tagged apps. Click or type to launch. Press Escape to dismiss.
- **Beautiful layout** — Flat list or waterfall card containers. Drag to reorder tags. Adjustable icon size, font size, and tag position (left/right/top).
- **Container mode** — Each tag group in its own rounded card with material background. Hover to highlight, click tag pills to jump.
- **Zero Finder dependency** — Tags are stored in a local JSON database. No xattr pollution. No SIP permission issues. Export/import your tag setup as a portable JSON file.
- **Privacy-first** — No network access. No analytics. No data collection. Everything stays on your Mac.
- **29 language variants** — English, French, Italian, German, Spanish, Portuguese (Brazil), 简体中文, 繁體中文, Korean, Japanese, Russian, Serbian Cyrillic, Ukrainian, Thai, Vietnamese, Arabic, Arabic (Najdi), Turkish, Indonesian, Czech, Danish, Dutch, Norwegian, Norwegian Nynorsk, Norwegian Bokmål, Malay, Polish, Romanian, Swedish.
- **Hover to reveal** — Hide app names for a clean icon-only grid. Hover to see the name.

**Perfect for:**
- Power users who launch dozens of apps daily
- Designers organizing tools by project
- Developers managing dev tool sets
- Anyone tired of scrolling through the Dock or Launchpad

Apptag lives in your menu bar. Zero clutter, always one hotkey away.

### 简体中文

**Apptag** 是一款极速标签式应用启动器。按下快捷键呼出全屏浮层，按标签找到 App，一键启动——无需鼠标、无需 Dock、无需翻文件夹。

**为什么选 Apptag？**
- **标签分类** — 按项目、工作流或心情分组。"设计"、"编程"、"写作"、"游戏"——随你定义。
- **极速呼出** — Shift+Option+Space 弹出全屏浮层，所有已标签 App 一览无余。点击/键入即启动，Esc 关闭。
- **美观布局** — 扁平列表或瀑布流卡片容器。拖拽排序标签。可调图标大小、字体大小、标签位置（左/右/上）。
- **容器模式** — 每个标签组独立圆角卡片，毛玻璃背景。悬停高亮，点击标签胶囊跳转。
- **零 Finder 依赖** — 标签存储在本地 JSON 数据库。不污染 xattr。不受 SIP 限制。支持 JSON 文件导入/导出备份。
- **隐私优先** — 无网络访问、无分析统计、无数据收集。一切只留在你的 Mac 上。
- **29 个语言版本** — 英语、法语、意大利语、德语、西班牙语、巴西葡萄牙语、简体中文、繁体中文、韩语、日语、俄语、西里尔塞尔维亚语、乌克兰语、泰语、越南语、阿拉伯语、Najdi 阿拉伯语、土耳其语、印尼语、捷克语、丹麦语、荷兰语、挪威语、挪威尼诺斯克语、挪威博克马尔语、马来语、波兰语、罗马尼亚语、瑞典语。
- **悬停显示** — 可隐藏 App 名称获得纯粹图标网格。鼠标悬停时显示名称。

**适合:** 重度 App 用户、设计师、开发者、以及厌倦翻 Dock/Launchpad 的所有人。

Apptag 常驻菜单栏。零干扰，一键直达。

---

## 3. 关键词 (Keywords)

英文市场:
```
app launcher, tag organizer, productivity tool, spotlight alternative, menu bar, hotkey, keyboard launcher, app catalog, workflow, quick launch
```

---

## 4. 隐私政策 & App Privacy 标签

### 隐私策略 URL

如无独立网站，可直接在 App Store Connect 填写简短隐私说明，或托管一个纯文本 URL。建议内容如下：

```
Apptag Privacy Policy

Apptag does not collect, store, transmit, or share any personal data.

All tag data is stored locally on your Mac at:
~/Library/Application Support/Apptag/tags.json

Preferences are stored locally via macOS UserDefaults.

The app has no network access and never communicates with any server.

No analytics, no tracking, no third-party SDKs.

If you have questions, contact: [your-email]
```

### App Privacy 标签 (Nutrition Labels)

> Apptag **不收集任何数据**。所有选项选 "No"。

| 数据类型 | 用于追踪? | 关联到用户? | 用于何种目的? |
|---|---|---|---|
| **All types** | No | No | Not collected |

具体逐项确认：
- **Contact Info**: Not collected
- **Health & Fitness**: Not collected
- **Financial Info**: Not collected
- **Location**: Not collected
- **Sensitive Info**: Not collected
- **Contacts**: Not collected
- **User Content**: Not collected
- **Browsing History**: Not collected
- **Search History**: Not collected
- **Identifiers**: Not collected
- **Purchases**: Not collected
- **Usage Data**: Not collected
- **Diagnostics**: Not collected
- **Other Data**: Not collected

---

## 5. 年龄分级

| 问题 | 回答 |
|---|---|
| 无限制网络访问 | No |
| 用户生成内容 | No |
| 内购 | No |
| 广告 | No |
| 社交媒体 | No |
| 赌博/竞赛 | No |
| 酒精/烟草/药物引用 | No |
| 医疗/治疗信息 | No |
| 色情/成人内容 | No |
| 暴力内容 | No |
| 恐怖/惊悚主题 | No |
| 卡通/幻想暴力 | None |
| 亵渎/粗俗幽默 | None |
| 真人暴力 | None |
| 模拟赌博 | No |
| 性暗示或裸体 | None |
| 不受限网络访问 | No |

**最终评分: 4+**

---

## 6. 截图要求

Mac App Store 要求至少 1 张截图（最多 10 张）。推荐尺寸：

| 显示分辨率 | 截图尺寸 |
|---|---|
| MacBook Pro 16" (默认) | 3456 × 2234 |
| MacBook Pro 14" | 3024 × 1964 |
| iMac 5K | 5120 × 2880 |

**建议截取场景（6张）:**
1. 全屏浮层 Flat 模式 — 展示 app 网格
2. 全屏浮层 Container 模式 — 展示瀑布流卡片
3. 标签编辑面板 — 展示拖拽排序/颜色选择
4. Preferences 面板 — 展示自定义选项
5. 容器 hover 高亮 — 展示交互效果
6. 菜单栏 + 叠加浮层 — 展示整体工作流

截图规范: `.png` 格式, 72 DPI, 不要包含窗口边框/阴影。

---

## 7. App 图标

已有自定义图标文件: `~/Projects/Apptag/icon-icns.icns`

App Store 额外要求:
- **1024×1024 PNG** (用于 App Store 列表展示)
- 无透明背景、无圆角（Apple 自动加圆角）
- 放在 `AppIcon.icns` 中作为 `icon_512x512@2x.png`

---

## 8. What's New (本次版本更新说明)

```
Apptag 5.7.5

- Fixed the menu bar icon visibility issue and added a Show Menu Bar Icon preference
- Fixed Preferences placement when opened above TagLauncher from a fullscreen app Space
- Fixed tag navigation reorder mode so clicking elsewhere exits the shaking state
- Expanded localization support to 29 language variants
- Updated the Language preferences tab to a two-column layout for better readability
- Added long-press drag sorting for tag navigation in normal app-list views
- Tag sorting now works from top, left, or right tag navigation positions across all 5 app-list styles
- Tag reorder animations now update both the tag navigation and matching app containers
- Added automatic migration for legacy non-sandbox tag databases into the App Store sandbox container
- Added a dedicated Language tab in Preferences with live language switching
- Preferences now opens centered above the active TagLauncher overlay, including multi-display setups
- Improved tag reordering in edit mode with live visual feedback and synchronized group layout updates
- Renamed backup actions to Export/Import Categories & Layout across all supported languages
- Added Mac App Store sandbox entitlements and App Store build validation
- Hid Launch at Login controls in sandboxed App Store builds
- Removed deprecated app launch API usage
- Version updated to 5.7.5 (Build 575)
```

---

## 9. App Review 信息

| 字段 | 内容 |
|---|---|
| **联系人** | [你需要填写] |
| **电话** | [你需要填写] |
| **邮箱** | [你需要填写] |
| **备注** | 该 App 使用 Carbon `RegisterEventHotKey` API 注册全局快捷键（Shift+Option+Space），**不**需要辅助功能权限。所有数据本地存储，无网络请求。 |
| **登录信息** | 不需要（无账户系统） |

---

## 10. ⚠️ Mac App Store 合规风险提示（已处理）

### 🟢 已处理: App Sandbox 与全局快捷键

**已完成配置**:
1. **Entitlements 文件**: `Apptag/TagLauncher.entitlements` 已创建，包含:
   - `com.apple.security.app-sandbox`
   - `com.apple.security.files.user-selected.read-write`，用于用户主动选择位置后的导入/导出 JSON
   - `com.apple.security.temporary-exception.files.home-relative-path.read-only`，用于一次性读取旧版非沙盒数据库 `~/Library/Application Support/Apptag/`
2. **build.sh 已更新**:
   - `APP_STORE=1` 时强制检查 entitlements 文件存在
   - `APP_STORE=1 CODESIGN_IDENTITY="..." bash build.sh` 使用 entitlements 签名
3. **代码处理**:
   - App Store 沙盒环境下会优先迁移旧版非沙盒 `tags.json`，避免升级后标签和排序看起来丢失
   - 本地非沙盒版本保留 LaunchAgent 登录启动
   - App Store 沙盒环境下隐藏 Launch at Login 设置项，并跳过 LaunchAgent 写入

**审核说明建议**: 临时 home-relative-path 读取权限仅用于从旧版非沙盒存储位置迁移用户已有标签、分类和排序数据到 sandbox 容器，不用于持续访问用户文件。

**仍需验证**: TestFlight 中确认沙盒下 Carbon `RegisterEventHotKey` 是否可正常工作。

### 🟢 已处理: Launch at Login 与 Sandbox

App Store 沙盒环境下不写入 `~/Library/LaunchAgents`，设置面板也不显示 Launch at Login 开关。本地非沙盒构建仍保留 LaunchAgent 登录启动。

### 🟢 低风险: LSMinimumSystemVersion = 15.0

当前最低系统为 macOS 15.0。这与构建目标 `arm64-apple-macosx15.0` 和 `Info.plist` 中的 `LSMinimumSystemVersion` 一致。

### 🟢 无风险: 隐私/数据安全

- 零网络访问 ✅
- 零数据收集 ✅
- 本地文件读写（sandbox 允许） ✅
- 无第三方 SDK ✅

---

## 11. 提审前 Checklist

- [ ] 生成 1024×1024 App Store 图标 PNG
- [ ] 截取 6 张 Mac 截图 (3456×2234 PNG)
- [ ] 准备隐私政策 URL（GitHub Pages / 独立页面 / Notion）
- [ ] 确认代码签名证书 (Mac App Distribution)
- [ ] 通过 TestFlight 测试 sandbox 下快捷键功能
- [ ] 使用 `APP_STORE=1 CODESIGN_IDENTITY="..." bash build.sh` 生成正式签名包
- [ ] 如有 sandbox 快捷键问题，准备 entitlement 申请理由
- [ ] 填写 App Store Connect 所有字段
- [ ] 上传构建并提交审核

---

## 12. 技术支持 & 营销 URL

如无独立网站，可使用:
- **隐私政策**: GitHub Gist / GitHub Pages / 或直接在 App Store Connect 文本框中填写
- **技术支持**: [你的邮箱]
- **营销 URL**: 可选（如有 GitHub README 可放）
