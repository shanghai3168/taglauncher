# Mac App Store 发布手工 TODO

适用版本：

- App：TagLauncher
- Version：`7.6.0`
- 冻结 Build：`20260527.0124`
- 冻结 Git tag：`appstore-7.6.0-20260527.0124`
- 发布资料目录：`Release/AppStore-7.6.0-20260527.0124`

这份清单面向第一次去 Mac App Store 发布。重点列出你需要在 Apple Developer / App Store Connect / GitHub 网页里手工完成的事项，以及容易成为卡点的地方。

## 0. 先明确一个原则

- [ ] 不要上传 `build/TagLauncher.dmg` 到 App Store Connect。DMG 只是本地留档和自测安装包。
- [ ] App Store Connect 需要的是经过 Mac App Store 签名和上传流程处理的 build，通常通过 Xcode Organizer、Transporter，或签名后的 `.pkg` 上传。
- [ ] 当前发布冻结点以 Git tag 为准：`appstore-7.6.0-20260527.0124`。
- [ ] 如果 App Store 上传失败后需要重新传包，每次重新上传都必须增加 `CFBundleVersion`。Version 可以仍然是 `7.6.0`，但 Build 号要递增。

## 1. Apple 账号和权限

- [ ] 确认 Apple Developer Program 会员是有效状态。
- [ ] 登录 App Store Connect：`https://appstoreconnect.apple.com/`
- [ ] 确认你登录的是 Account Holder，或者至少有 Admin / App Manager 权限。
- [ ] 进入 `Business / Agreements, Tax, and Banking`，确认没有待签署协议。
- [ ] 如果只发布免费 App：一般不需要先完成 Paid Apps Agreement。
- [ ] 如果未来要收费、内购、订阅：需要签 Paid Apps Agreement，并填写税务和银行信息。

容易卡点：

- 账号如果有协议待处理，可能无法提交或无法上架。
- 如果你选择收费，税务/银行信息可能需要较长时间审核。
- 个人开发者账号可能会显示你的个人开发者名称；公司账号会显示公司/组织名称。

## 2. 身份、税务、银行信息

你问到“用户协议是不是要填写我的个人身份证”。这里要分开看：

- [ ] 隐私政策 / 用户协议本身通常不需要写身份证号。
- [ ] 隐私政策里需要写清楚开发者/联系邮箱/数据处理方式。
- [ ] Apple Developer 账号注册、协议、收款、税务、银行信息，可能要求填写真实姓名、地址、税务身份信息、银行账户信息。
- [ ] 如果是中国大陆个人开发者，具体是否要身份证、税号、银行账户名，以 App Store Connect 当前表单为准。
- [ ] 如果是免费 App 且不收款，税务/银行压力会小很多；但 Apple 仍可能要求账号资料完整。

建议你准备：

- [ ] Apple ID 登录信息和双重认证设备。
- [ ] 真实姓名或开发者主体名称。
- [ ] 联系邮箱：建议使用 `shanghai3168@gmail.com` 或你准备公开作为支持邮箱的地址。
- [ ] 联系地址。
- [ ] 如果要收费：银行卡信息、税务身份信息、可能需要的身份证/证件信息。
- [ ] 如果是公司主体：营业执照/公司英文名/D-U-N-S 等资料可能会用到。

不要放进公开网页：

- 身份证号
- 银行卡号
- 家庭详细地址
- Apple ID 密码
- App-specific password
- 证书私钥
- provisioning profile 私密文件

## 3. GitHub 上发布隐私政策和支持页面

App Store Connect 需要公开可访问的 URL。建议用你的 GitHub 仓库发布。

仓库建议：

- [ ] 使用公开仓库，例如：`https://github.com/shanghai3168/taglauncher`
- [ ] 开启 GitHub Pages。
- [ ] 放至少两个公开页面：
  - Privacy Policy：隐私政策
  - Support：支持页面

当前已有草稿：

- `Release/AppStore-7.6.0-20260527.0124/Legal/PRIVACY_POLICY.md`
- `Release/AppStore-7.6.0-20260527.0124/Legal/PRIVACY_POLICY.zh-Hans.md`
- `Release/AppStore-7.6.0-20260527.0124/Support/SUPPORT.md`
- `Release/AppStore-7.6.0-20260527.0124/Support/GITHUB_PAGES_PUBLICATION_GUIDE.md`

手工操作：

- [ ] 把隐私政策英文版发布成一个公网 URL。
- [ ] 把中文隐私政策也可以发布，但 App Store Connect 至少要填一个 Privacy Policy URL。
- [ ] 把支持页面发布成一个公网 URL。
- [ ] 用浏览器无痕窗口打开这两个 URL，确认不需要登录 GitHub 也能访问。
- [ ] 在 App Store Connect 填：
  - Privacy Policy URL
  - Support URL

隐私政策内容必须覆盖：

- [ ] TagLauncher 是否收集个人信息。
- [ ] 是否有网络上传。
- [ ] 是否有 analytics / tracking / ads。
- [ ] 是否把数据卖给第三方。
- [ ] 应用扫描本机已安装 App 的用途。
- [ ] 标签、备注、设置保存在哪里。
- [ ] 用户如何联系你。
- [ ] 生效日期。

容易卡点：

- Apple 要求所有 App 都有 Privacy Policy URL。
- URL 不能是本地文件，不能需要登录，不能是未公开 GitHub private 页面。
- App Privacy 问卷和隐私政策内容要一致。

## 4. App Privacy 问卷

初步判断 TagLauncher 当前更接近：

- 不使用广告 SDK。
- 不使用 analytics SDK。
- 不做 tracking。
- 不上传用户数据到服务器。
- 标签、设置、备注主要本地保存。
- 会在本机扫描已安装 App，用于生成启动器列表。

你在 App Store Connect 手工填写时要逐项确认：

- [ ] 是否收集 Contact Info：通常选 No，除非你在 App 内收集邮箱/姓名。
- [ ] 是否收集 Identifiers：通常选 No，除非集成 analytics / ads / account。
- [ ] 是否收集 Usage Data：通常选 No，除非有统计/遥测。
- [ ] 是否收集 Diagnostics：通常选 No，除非接入 crash reporting SDK。
- [ ] 是否收集 User Content：通常选 No，App 本地备注如果不上传，一般不算收集到开发者服务器。
- [ ] 是否用于 Tracking：当前应为 No。
- [ ] 是否数据链接到用户身份：当前应为 No。

容易卡点：

- 如果以后加入第三方 SDK，要重新审查 App Privacy。
- App Privacy 是自我声明，Apple 审核可能会对照二进制和行为检查。
- 隐私政策 URL 和 App Privacy 问卷不一致，可能导致审核问题。

## 5. App Store Connect 创建 App 记录

手工填写：

- [ ] Platform：`macOS`
- [ ] Name：`TagLauncher`
- [ ] Primary Language：建议 `English (U.S.)`，如果你主要面向中文用户，也可以选 Simplified Chinese。
- [ ] Bundle ID：`com.taglauncher.app`
- [ ] SKU：例如 `taglauncher-macos`
- [ ] Category：`Utilities`
- [ ] Version：`7.6.0`
- [ ] Release option：建议选 `Manual release after approval`，审核通过后你再手工发布。

容易卡点：

- App 名称如果已被占用，需要换名字或处理品牌问题。
- Bundle ID 一旦关联 App 记录，后续不能随便换。
- Primary Language 会影响默认展示语言。

## 6. App 信息和文案

可从这里复制草稿：

- `Release/AppStore-7.6.0-20260527.0124/APP_STORE_CONNECT_METADATA.md`

手工填写：

- [ ] App Name：`TagLauncher`
- [ ] Subtitle：建议英文 `Tag-based app launcher`
- [ ] Description：复制英文描述，或再润色。
- [ ] Keywords：英文关键词不要超过限制。
- [ ] Support URL：填 GitHub Pages 支持页。
- [ ] Privacy Policy URL：填 GitHub Pages 隐私政策页。
- [ ] Marketing URL：可空。
- [ ] Copyright：例如 `© 2026 [你的姓名或开发者名称]`
- [ ] Contact 信息：填写 App Review 能联系到你的邮箱/电话。

容易卡点：

- 文案不要承诺不存在的功能。
- 截图里展示的功能必须和实际 App 一致。
- 支持邮箱最好和隐私政策里的邮箱一致。

## 7. 截图准备

Apple 对 Mac App 截图有固定尺寸要求。Mac 截图需要 16:10，常见可接受尺寸包括：

- `1280 x 800`
- `1440 x 900`
- `2560 x 1600`
- `2880 x 1800`

建议准备 5 张：

- [ ] `01-app-grid.png`：主界面 App Grid，展示多个标签分组。
- [ ] `02-quick-search.png`：Quick Search，展示输入和选中条。
- [ ] `03-settings-general.png`：设置页，展示通用/布局/语言。
- [ ] `04-hotkeys.png`：快捷键设置或说明 Quick Search 工作方式。
- [ ] `05-about-help.png`：关于页或 Help PDF 下载入口，强调多语言帮助。

截图注意：

- [ ] 不显示私人聊天、私人文件名、账号、浏览器敏感页面。
- [ ] 不显示未授权品牌素材。
- [ ] 不显示明显测试数据、红色标注、调试窗口。
- [ ] 尽量统一语言。若主 App Store 页面英文，就截图英文 UI；如果要中国区本地化，再准备中文截图。
- [ ] 截图必须真实反映 App，不要做虚假功能图。

截图存放建议：

- 原图：`Release/AppStore-7.6.0-20260527.0124/Screenshots/raw/`
- 最终上传图：`Release/AppStore-7.6.0-20260527.0124/Screenshots/AppStore/`

可选 resize 命令：

```bash
mkdir -p Release/AppStore-7.6.0-20260527.0124/Screenshots/AppStore
for file in Release/AppStore-7.6.0-20260527.0124/Screenshots/raw/*.png; do
  name="$(basename "$file")"
  sips -z 1800 2880 "$file" --out "Release/AppStore-7.6.0-20260527.0124/Screenshots/AppStore/$name"
done
```

## 8. 是否需要视频录屏 / App Preview

结论：

- [ ] 不必须。
- [ ] 第一次发布建议先不做视频，除非你已经有非常干净、专业、无隐私信息的录屏。
- [ ] 如果做视频，重点展示 15-30 秒核心流程：打开 App Grid、Quick Search、设置/帮助。

视频容易卡点：

- 尺寸、编码、时长、设备类型要求更严格。
- 容易露出私人桌面、通知、账号、浏览器标签。
- 审核会按视频里展示的功能理解 App，如果视频显示了 App 没有的能力，可能引发问题。

建议：

- 第一版先用 3-5 张高质量截图，不上传 App Preview。
- 审核通过后，后续版本再考虑做视频。

## 9. 年龄分级、内容权利、加密合规

手工填写：

- [ ] Age Rating：按工具类 App 正常回答；没有暴力、色情、赌博、用户生成公开内容。
- [ ] Content Rights：确认截图、图标、文案、帮助 PDF 都是你有权使用的内容。
- [ ] Export Compliance / Encryption：
  - 如果 App 只使用 Apple 系统 HTTPS/网络能力打开帮助 PDF，通常按 Apple 表单如实选择。
  - 如果没有自研加密、VPN、加密通信功能，通常不会走复杂加密文件上传。
  - 最终答案以 App Store Connect 当前问题为准。

容易卡点：

- 不确定加密问题时不要乱选“有复杂加密”。先看表单说明。
- 如果 App 内未来加入账号登录、云同步、VPN、代理、加密通信，要重新审查。

## 10. 签名、证书、上传包

当前本地 DMG：

- `Release/AppStore-7.6.0-20260527.0124/Archive/TagLauncher-7.6.0-20260527.0124-local-QA.dmg`

它不是 App Store 上传包。

你需要准备：

- [ ] Mac App Distribution / Apple Distribution 证书。
- [ ] Mac Installer Distribution 证书，如果用 `.pkg` 上传。
- [ ] Mac App Store provisioning profile，Bundle ID 是 `com.taglauncher.app`。
- [ ] App Sandbox entitlements 确认开启。
- [ ] 使用 Xcode Organizer / Transporter / CLI 上传。

当前项目已有说明：

- `Release/AppStore-7.6.0-20260527.0124/BUILD_SIGN_UPLOAD.md`

容易卡点：

- 普通 ad-hoc 签名包不能直接上传 App Store。
- 每次上传失败重试，Build 号要增加。
- 证书过期、profile 不匹配、Bundle ID 不一致都会导致上传失败。
- Mac App Store 一般要求 sandbox。

## 11. App Review Notes

从这里复制：

- `Release/AppStore-7.6.0-20260527.0124/Review/APP_REVIEW_NOTES.md`

建议在 App Review Notes 里写：

- [ ] 这是 macOS 应用启动器。
- [ ] 主流程：启动 App -> `Option-Shift-Space` 打开 App Grid -> 按 `Space` 打开 Quick Search。
- [ ] `Escape` 一次关闭 Quick Search，再按一次关闭 App Grid。
- [ ] 全屏/Split View 下 App Grid、Quick Search、Settings 会保持在当前 Space。
- [ ] 不需要 demo account。
- [ ] 如果审核员无法触发快捷键，请让他从菜单栏打开 App Grid。

容易卡点：

- 审核员不知道快捷键，会误以为 App 没反应。
- App 的浮层窗口行为比较特殊，要在 notes 里说明这是预期功能。
- 如果 App 请求权限，说明权限用途。

## 12. TestFlight / 自测

建议：

- [ ] 上传后先等 App Store Connect 处理完成。
- [ ] 如果可以，先用 TestFlight 或处理后的 build 做一次安装测试。
- [ ] 检查首次启动。
- [ ] 检查全局快捷键。
- [ ] 检查 App Grid。
- [ ] 检查 Quick Search 上下键和 Return。
- [ ] 检查 Settings。
- [ ] 检查 Help PDF 链接。
- [ ] 检查退出和重新打开。

## 13. 提交审核前最后检查

- [ ] App Store Connect 每个页面都没有红色缺失提示。
- [ ] Build 已经处理完成并已选中。
- [ ] 版本号是 `7.6.0`。
- [ ] Build 号是你最终上传的 build。
- [ ] Privacy Policy URL 能公开打开。
- [ ] Support URL 能公开打开。
- [ ] App Privacy 问卷已提交。
- [ ] 截图尺寸正确。
- [ ] App Review Notes 已填。
- [ ] 联系电话/邮箱可用。
- [ ] 选择 `Manual release after approval`。
- [ ] 点 `Submit for Review`。

## 14. 审核中和审核后

- [ ] 留意邮箱和 App Store Connect 消息。
- [ ] 如果被拒，先不要急着改代码，把拒绝原因复制保存到：
  `Release/AppStore-7.6.0-20260527.0124/Review/`
- [ ] 如果只是元数据问题，优先在 App Store Connect 改文案/截图/说明。
- [ ] 如果是二进制问题，再改代码并增加 Build 号重新上传。
- [ ] 审核通过后，不建议立刻自动发布；先确认页面、截图、隐私信息无误，再手工发布。

## 15. 公开资料不要遗漏

必须：

- [ ] Privacy Policy URL
- [ ] Support URL
- [ ] App screenshots
- [ ] App Privacy questionnaire
- [ ] App Review contact
- [ ] App Review notes
- [ ] Age rating
- [ ] Export compliance
- [ ] Pricing and availability

可选：

- [ ] Marketing URL
- [ ] App Preview 视频
- [ ] 更多本地化语言的 App Store 页面
- [ ] GitHub README 产品介绍页

## 16. 本项目当前发布文件索引

- 发布包：`Release/AppStore-7.6.0-20260527.0124/`
- 发布包 README：`Release/AppStore-7.6.0-20260527.0124/README.md`
- App Store 文案：`Release/AppStore-7.6.0-20260527.0124/APP_STORE_CONNECT_METADATA.md`
- 首次提交 checklist：`Release/AppStore-7.6.0-20260527.0124/FIRST_TIME_MAC_APP_STORE_TODO.md`
- 签名上传说明：`Release/AppStore-7.6.0-20260527.0124/BUILD_SIGN_UPLOAD.md`
- 审核 notes：`Release/AppStore-7.6.0-20260527.0124/Review/APP_REVIEW_NOTES.md`
- 隐私政策：`Release/AppStore-7.6.0-20260527.0124/Legal/PRIVACY_POLICY.md`
- 中文隐私政策：`Release/AppStore-7.6.0-20260527.0124/Legal/PRIVACY_POLICY.zh-Hans.md`
- 支持页面：`Release/AppStore-7.6.0-20260527.0124/Support/SUPPORT.md`
- GitHub Pages 指南：`Release/AppStore-7.6.0-20260527.0124/Support/GITHUB_PAGES_PUBLICATION_GUIDE.md`
- 截图指南：`Release/AppStore-7.6.0-20260527.0124/Screenshots/SCREENSHOT_SHOT_LIST.md`
- 本地 QA DMG：`Release/AppStore-7.6.0-20260527.0124/Archive/TagLauncher-7.6.0-20260527.0124-local-QA.dmg`

## 17. 官方参考链接

- App Store Connect：https://appstoreconnect.apple.com/
- Apple Developer 账号：https://developer.apple.com/account/
- Screenshot specifications：https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- App Privacy Details：https://developer.apple.com/app-store/app-privacy-details/
- App Privacy reference：https://developer.apple.com/help/app-store-connect/reference/app-privacy/
- Manage App Privacy：https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Agreements, Tax, and Banking：https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/
- Tax information：https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information
- App Review Guidelines：https://developer.apple.com/app-store/review/guidelines

