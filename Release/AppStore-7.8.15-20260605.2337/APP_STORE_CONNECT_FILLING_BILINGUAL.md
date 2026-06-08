# TagLauncher App Store Connect 双语填表稿

生成日期：2026-06-07

适用版本：TagLauncher `7.8.15`

适用 build：`20260605.2337`

App Store Connect App ID：`6777149496`

Bundle ID：`com.taglauncher.app`

SKU：`taglauncher-macos`

最低系统：macOS `15.0`

发布前提醒：

- 这份文档用于 App Store Connect 页面逐项填表。
- 最终上传包必须是签名后的 `.pkg`，不要上传 `.dmg`。
- 上传并 Processing 完成后，版本页要选择 build `20260605.2337`。
- 中文本地化建议使用 `Chinese (Simplified) / zh-Hans`；英文建议使用 `English (U.S.) / en-US`。
- 隐私、年龄分级、第三方内容版权、价格这类选项要按实际情况选择；下面给出推荐填法和需要确认的点。

## 1. App Information / App 信息

| 字段                       | 中文填写                                         | English fill                                 |
| ------------------------ | -------------------------------------------- | -------------------------------------------- |
| Name / 名称                | `TagLauncher`                                | `TagLauncher`                                |
| Subtitle / 副标题           | `标签化应用启动器`                                   | `Tag-based app launcher`                     |
| Bundle ID                | `com.taglauncher.app`                        | `com.taglauncher.app`                        |
| SKU                      | `taglauncher-macos`                          | `taglauncher-macos`                          |
| Primary Category / 主分类   | `Utilities / 工具`                             | `Utilities`                                  |
| Secondary Category / 副分类 | `Productivity / 效率`                          | `Productivity`                               |
| Minimum macOS / 最低系统     | `macOS 15.0`                                 | `macOS 15.0`                                 |
| Copyright / 版权           | `© 2026 Hainan Wanxing Technology Co., Ltd.` | `© 2026 Hainan Wanxing Technology Co., Ltd.` |

## 2. URLs / 链接

| 字段                          | 中文填写                                                                                           | English fill                                                                                   |
| --------------------------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Marketing URL / 营销网址        | `https://shanghai3168.github.io/taglauncher/index.html`                                        | `https://shanghai3168.github.io/taglauncher/index-en.html`                                     |
| Support URL / 支持网址          | `https://shanghai3168.github.io/taglauncher/support.html`                                      | `https://shanghai3168.github.io/taglauncher/support.html`                                      |
| Privacy Policy URL / 隐私政策网址 | `https://shanghai3168.github.io/taglauncher/privacy-zh.html`                                   | `https://shanghai3168.github.io/taglauncher/privacy.html`                                      |
| Help PDF / 帮助 PDF           | `https://github.com/shanghai3168/taglauncher/releases/download/v7.6.0/Taglauncher-help-zh.pdf` | `https://github.com/shanghai3168/taglauncher/releases/download/v7.6.0/Taglauncher-help-en.pdf` |

说明：

- 官网、支持页、隐私页已线上可访问。
- 帮助 PDF 链接是直接下载链接，不是仓库说明页。

## 3. Version Information / 版本信息

| 字段                      | 中文填写                                        | English fill                                                                                      |
| ----------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Version / 版本号           | `7.8.15`                                    | `7.8.15`                                                                                          |
| Build / 构建号             | `20260605.2337`                             | `20260605.2337`                                                                                   |
| Promotional Text / 推广文字 | `用标签整理 Mac 应用，用快捷键和 Quick Search 更快找到目标应用。` | `Organize Mac apps by tag and launch them faster with a keyboard-friendly grid and Quick Search.` |

## 4. Description / 描述

### Chinese (Simplified)

TagLauncher 是一个基于标签的 Mac 应用启动器。

你可以把已安装的应用整理成可视化标签分组，用全局快捷键唤出应用网格，也可以通过 Quick Search 直接搜索应用、标签和备注。它适合安装了很多应用、希望更快找到目标应用的人。

亮点：

- 使用 Option-Shift-Space 打开应用网格。
- 使用 Quick Search 搜索应用、标签和备注。
- 用自定义标签整理应用。
- 可调整图标大小、标签位置、列表样式和 Dock 显示。
- 支持分类布局的导入和导出。
- 支持多显示器和全屏 Space 场景。

### English (U.S.)

TagLauncher is a fast tag-based launcher for Mac apps.

Organize installed apps into visual tag groups, open a fullscreen-friendly app grid from a global hotkey, and jump directly to apps with Quick Search. It is designed for people who have many apps and want a calmer, faster way to find the right one without hunting through Launchpad, Finder, or the Dock.

Highlights:

- Open the app grid with Option-Shift-Space.
- Search apps, tags, and notes with Quick Search.
- Group apps by custom tags.
- Tune icon size, tag position, app list style, and Dock visibility.
- Import and export your category layout.
- Works across multiple displays and fullscreen Spaces.

## 5. Keywords / 关键词

| Locale / 语言          | Keywords / 关键词                                             |
| -------------------- | ---------------------------------------------------------- |
| Chinese (Simplified) | `启动器,标签,应用,效率,搜索,工具,Mac`                                   |
| English (U.S.)       | `launcher,tags,apps,productivity,quick search,utility,mac` |

## 6. What's New / 此版本新增内容

### Chinese (Simplified)

- 修复再次打开 App Grid 时可能一直转圈、无法显示应用图标的问题。
- 应用启动后在后台预热应用索引，减轻首次打开 App Grid 的等待。
- 继续包含 7.8.14 对 CoreServices Applications 下系统应用（如钥匙串访问）的检索支持。

### English (U.S.)

- Fixed an issue where the App Grid could show an endless loading spinner when reopened.
- Improved first-open responsiveness by warming the local app index in the background at launch.
- Includes the 7.8.14 fix for Apple system apps under CoreServices Applications, including Keychain Access.

## 7. Screenshots / 截图

上传目录：

`/Users/ar/Projects/Taglauncher-7.8.15-source/Release/AppStore-7.8.15-20260605.2337/Screenshots/AppStore/`

现有截图：

1. `mac-01-SCR-20260604-jwdv-2880x1800.png`
2. `mac-02-SCR-20260604-jwen-2880x1800.png`
3. `mac-03-SCR-20260604-jwgb-2880x1800.png`
4. `mac-04-SCR-20260604-jwgq-2880x1800.png`
5. `mac-05-SCR-20260604-jwhd-2880x1800.png`
6. `mac-06-SCR-20260604-jwic-2880x1800.png`
7. `mac-07-SCR-20260604-jwji-2880x1800.png`
8. `mac-08-SCR-20260604-jwkh-2880x1800.png`

建议：

- 中英文版本可以先共用这组截图。
- 如果 App Store Connect 允许按语言上传不同截图，后续再补英文界面截图；第一次上架先保证截图清晰、尺寸合规、无黑边。

## 8. App Privacy / App 隐私

推荐填法：

| App Store Connect 问题                 | 推荐选择                                 |
| ------------------------------------ | ------------------------------------ |
| Does this app collect data? / 是否收集数据 | `No, this app does not collect data` |
| Tracking / 是否追踪用户                    | `No`                                 |
| Analytics / 是否分析                     | `No`                                 |
| Ads / 是否广告                           | `No`                                 |
| Data linked to user / 是否关联用户数据       | `No`                                 |

可用于说明的文字：

### Chinese

TagLauncher 不收集个人数据，不包含广告，不使用分析 SDK。标签、分类、备注和偏好设置保存在用户本机。用户打开帮助文档时，应用可能从公开 GitHub Releases 下载对应语言的帮助 PDF。

### English

TagLauncher does not collect personal data, does not include ads, and does not use analytics SDKs. Tags, categories, notes, and preferences stay on the user's device. When the user opens Help, the app may download the localized help PDF from public GitHub Releases.

## 9. Age Rating / 年龄分级

推荐结果：`4+`

建议逐项选择：

| 内容项                              | 推荐选择   |
| -------------------------------- | ------ |
| Cartoon or Fantasy Violence      | `None` |
| Realistic Violence               | `None` |
| Sexual Content or Nudity         | `None` |
| Profanity or Crude Humor         | `None` |
| Alcohol, Tobacco, Drug Use       | `None` |
| Medical or Treatment Information | `None` |
| Gambling                         | `None` |
| User-Generated Content           | `No`   |
| Unrestricted Web Access          | `No`   |

## 10. Content Rights / 第三方内容版权

这里要谨慎。TagLauncher 本身不内置第三方媒体内容，但它会显示用户本机已安装 App 的名称和图标，截图里也会出现第三方 App 图标。

推荐填法：

- 如果页面问：`Does your app contain, show, or access third-party content?`
- 建议选择：`Yes`
- 理由：应用会显示本机已安装应用的图标和名称，这属于用户设备上的第三方 App 信息。

可用于备注的说明：

### Chinese

TagLauncher 会读取并显示用户本机已安装应用的名称和图标，用于帮助用户整理和启动这些应用。应用不内置、销售或分发第三方媒体内容。

### English

TagLauncher reads and displays the names and icons of apps installed on the user's Mac so the user can organize and launch them. The app does not bundle, sell, or distribute third-party media content.

## 11. Pricing and Availability / 价格与地区

需要你确认：

| 字段                            | 建议                                              |
| ----------------------------- | ----------------------------------------------- |
| Price / 价格                    | 如果第一版先低摩擦获客，建议设为 `Free`；如果要直接商业化，需要你定价格档位。      |
| Availability / 上架地区           | 建议先选择 `All countries or regions`，除非你有明确不想发布的地区。 |
| App Store Distribution Method | `Public - Available on the App Store`           |
| License Agreement             | 使用 Apple 标准许可协议，除非你要自定义 EULA。                   |

## 12. App Review Information / 审核信息

| 字段                               | 填写                          |
| -------------------------------- | --------------------------- |
| Contact first name / 联系人名        | 用你的 App Store Connect 账号联系人 |
| Contact last name / 联系人姓         | 用你的 App Store Connect 账号联系人 |
| Phone / 电话                       | 用你的开发者账号联系电话                |
| Email / 邮箱                       | `shanghai3168@gmail.com`    |
| Demo account required / 是否需要演示账号 | `No`                        |

### Review Notes / 审核备注

建议在 App Review Notes 填英文；如页面空间允许，也可以中英文都放。

English:

TagLauncher is a macOS utility for organizing installed applications into visual tag groups and launching them from a keyboard-accessible app grid.

No demo account is required.

Review flow:

1. Launch TagLauncher.
2. Press Option-Shift-Space to show the app grid.
3. Press Space while the app grid is visible to open Quick Search.
4. Type part of an installed app name to search.
5. Press Escape once to close Quick Search.
6. Press Escape again to close the app grid.
7. Press Option-Shift-Space again. The app grid should show icons without staying on a loading spinner.
8. Open Settings from the menu bar or with Command-Comma.

Version 7.8.15 fixes an issue where reopening the App Grid could remain on a loading spinner even though the local app index was already cached.

Chinese:

TagLauncher 是一款 macOS 工具，用于把已安装应用整理成可视化标签分组，并通过键盘快捷键唤出应用网格进行启动。

不需要演示账号。

审核流程：

1. 启动 TagLauncher。
2. 按 Option-Shift-Space 打开 App Grid。
3. App Grid 显示后按 Space 打开 Quick Search。
4. 输入部分应用名称进行搜索。
5. 按一次 Escape 关闭 Quick Search。
6. 再按一次 Escape 关闭 App Grid。
7. 再次按 Option-Shift-Space 打开 App Grid，应该能正常显示图标，不会一直停留在加载状态。
8. 从菜单栏或使用 Command-Comma 打开 Settings。

版本 7.8.15 修复了再次打开 App Grid 时可能一直显示加载状态的问题。

## 13. Build Selection / 构建选择

上传 `.pkg` 并等待 Processing 完成后，在版本页面选择：

| 字段        | 值                     |
| --------- | --------------------- |
| Version   | `7.8.15`              |
| Build     | `20260605.2337`       |
| Bundle ID | `com.taglauncher.app` |

不要选择旧 build：

- 不要选 `20260605.0150`
- 不要选 `7.8.14`

## 14. Export Compliance / 出口合规

推荐选择：

| 问题                                     | 推荐                               |
| -------------------------------------- | -------------------------------- |
| Does your app use encryption? / 是否使用加密 | `No`，前提是 App 没有自带加密功能，也没有网络加密逻辑。 |

说明：

- macOS 系统或 HTTPS 的标准能力通常不等于 App 自带加密功能。
- 如果 App Store Connect 的问题表述变化，按“TagLauncher 没有实现自有加密功能”这个事实填写。

## 15. Release Mode / 发布方式

推荐：

| 字段              | 推荐                              |
| --------------- | ------------------------------- |
| Version Release | `Manually release this version` |

理由：

- 第一次上架建议手动发布，避免审核通过后立即上线但页面、截图或价格还没复核完。

## 16. Final Checklist / 提交前检查

- [ ] App 信息、分类、SKU、Bundle ID 正确。
- [ ] 中文和英文描述都已填写。
- [ ] 关键词没有超过 App Store Connect 限制。
- [ ] Support URL、Privacy URL、Marketing URL 可以打开。
- [ ] 隐私问卷选择 `Data Not Collected`。
- [ ] 年龄分级结果是 `4+`。
- [ ] 第三方内容版权字段按“会显示本机已安装 App 名称和图标”的事实填写。
- [ ] 上传包是 `.pkg`，不是 `.dmg`。
- [ ] 选择 build `20260605.2337`。
- [ ] 审核备注包含 Option-Shift-Space 和 Quick Search 的测试路径。
- [ ] 版本发布方式选手动发布。

