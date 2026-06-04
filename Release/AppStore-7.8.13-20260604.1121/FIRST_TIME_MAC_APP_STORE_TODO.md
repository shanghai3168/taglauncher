# First-Time Mac App Store Todo

## Apple Developer Account

- [ ] 确认 Apple Developer Program 会员有效。
- [ ] 确认当前 Apple ID 有 Account Holder/Admin/App Manager 权限。
- [ ] 确认 Agreements、Tax、Banking 没有阻塞项。

## App Record

- [ ] 在 App Store Connect 创建 macOS app record。
- [ ] Name: `TagLauncher`
- [ ] Bundle ID: `com.taglauncher.app`
- [ ] SKU: `taglauncher-macos`
- [ ] Primary language: English 或 Simplified Chinese
- [ ] Category: Utilities
- [ ] Minimum macOS: `15.0`

## Certificates And Profiles

- [ ] 创建或确认 Mac App Distribution / Apple Distribution 证书。
- [ ] 创建或确认 Mac Installer Distribution 证书。
- [ ] 创建 Mac App Store Connect provisioning profile。
- [ ] Profile 的 App ID 必须匹配 `com.taglauncher.app`。
- [ ] 把证书私钥和 profile 安装到负责上传的 Mac。

## Metadata

- [ ] 填写 subtitle。
- [ ] 填写 description。
- [ ] 填写 keywords。
- [ ] 填写 what's new。
- [ ] 填写 support URL。
- [ ] 填写 marketing URL，如没有可留空。
- [ ] 填写 copyright。
- [ ] 选择价格和可用地区。
- [ ] 完成 Age Rating。
- [ ] 完成 Export Compliance。

## Privacy

- [ ] 发布隐私政策网页。
- [ ] 在 App Store Connect 填写隐私政策 URL。
- [ ] App Privacy 选择当前版本的数据收集情况。
- [ ] 若代码未来加入 analytics、crash reporting、network telemetry 或第三方 SDK，必须重新审计隐私问卷。

## Screenshots

- [ ] 检查 `Screenshots/AppStore/` 中 8 张 `2880 x 1800` PNG。
- [ ] 删除任何暴露私人信息的截图。
- [ ] 上传 1 到 10 张 Mac 截图。
- [ ] 确认截图顺序能解释核心使用流程。

## Build Upload

- [ ] 按 `BUILD_SIGN_UPLOAD.md` 生成 App Store 签名 `.pkg`。
- [ ] 用 Transporter 或 Xcode 上传。
- [ ] 等待 Processing 完成。
- [ ] 选择 build `20260604.1121`。
- [ ] 提交审核。
