# First-Time Mac App Store TODO

用于从 Apple Developer 账号发布 TagLauncher `7.8.12`。

## 0. App Store Connect 前置项

- [ ] Apple Developer Program 会员有效。
- [ ] 使用 Account Holder / Admin / App Manager 权限登录 App Store Connect。
- [ ] Account Holder 已在 Business 区域接受最新协议。
- [ ] 如果收费，完成 Paid Apps Agreement、税务、银行信息。
- [ ] 决定价格、销售国家/地区和是否手动发布。
- [ ] 建议首次发布选择 `Manual release after approval`。

## 1. App ID、证书和 Provisioning

- [ ] 创建或确认 explicit App ID：
  - Platform: `macOS`
  - Bundle ID: `com.taglauncher.app`
- [ ] 启用 App Sandbox capability。
- [ ] 创建/下载 Mac App Store distribution certificate，或使用 Xcode/cloud-managed signing。
- [ ] 如果上传 signed `.pkg`，创建/下载 Mac Installer Distribution certificate。
- [ ] 创建/下载 `Mac App Store Connect` provisioning profile for `com.taglauncher.app`。
- [ ] 在发布 Mac 上安装证书和 profile。
- [ ] 运行 `security find-identity -v -p codesigning` 确认真实 distribution identity 名称。

## 2. App Store Connect App Record

- [ ] 创建新 app record。
- [ ] Platform: `macOS`。
- [ ] Name: `TagLauncher`。
- [ ] Primary language: `English (U.S.)` 或 `Simplified Chinese`。
- [ ] Bundle ID: `com.taglauncher.app`。
- [ ] SKU: `taglauncher-macos`。
- [ ] User Access: `Full Access`，除非团队需要限制访问。
- [ ] Category: `Utilities`。
- [ ] Version: `7.8.12`。

## 3. Product Page Metadata

- [ ] 填写 app name、subtitle、description、keywords、promotional text。
- [ ] 填写 support URL。
- [ ] 填写 privacy policy URL。
- [ ] 填写 copyright。
- [ ] 完成年龄分级问卷。
- [ ] 完成内容权利声明。
- [ ] 完成加密出口合规问题。
- [ ] 完成 app privacy 问卷。
- [ ] 完成税务分类。
- [ ] 填写 App Review 联系方式。
- [ ] 填写 `Review/APP_REVIEW_NOTES.md` 中的审核备注。

## 4. Screenshots

- [ ] 拍摄至少 1 张 Mac screenshot，建议 5 张。
- [ ] 使用 16:10 PNG/JPG/JPEG。
- [ ] 推荐导出为 `2880 x 1800`。
- [ ] 截图覆盖 App Grid、Quick Search、Settings。
- [ ] 确认截图没有私人应用、文件、通知、账号信息。
- [ ] 将原图放入 `Screenshots/raw/`，最终上传图放入 `Screenshots/AppStore/`。

## 5. Build And Upload

- [ ] 按 `BUILD_SIGN_UPLOAD.md` 生成 App Store signed build。
- [ ] 验证 `CFBundleShortVersionString = 7.8.12`。
- [ ] 验证 `CFBundleVersion = 20260604.0105`，如果上传重试需要重新打包则递增 build。
- [ ] 验证 sandbox entitlements 存在。
- [ ] 对 signed build 运行窗口 QA。
- [ ] 通过 Transporter、Xcode Organizer 或 `altool` 上传。
- [ ] 等待 App Store Connect 处理完成邮件。
- [ ] 在 `7.8.12` version record 选择处理完成的 build。

## 6. Submit For Review

- [ ] 确认 App Store Connect 所有 required fields 已完成。
- [ ] 确认 build 已选择。
- [ ] 选择 release option：建议 `Manual release after approval`。
- [ ] 点击 `Add for Review`。
- [ ] 进入 Draft Submission 后点击 `Submit for Review`。
- [ ] 记录 review status。
- [ ] 如果 rejected，把 reviewer message 保存到本 release 目录再修复。

## 7. Approval 后

- [ ] 记录最终提交 build number 和 App Store Connect build ID。
- [ ] 归档最终上传包到 `Upload/`。
- [ ] 归档最终截图、隐私 URL、支持 URL、审核备注到 `Submitted/`。
- [ ] 手动 release。
- [ ] 发布后做 App Store 安装 smoke test。
