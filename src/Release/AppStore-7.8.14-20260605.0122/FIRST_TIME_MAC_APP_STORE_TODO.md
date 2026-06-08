# First-Time Mac App Store Todo

## Apple Developer Account

- [ ] Apple Developer Program 会员有效。
- [ ] App Store Connect 账号具备创建和提交 macOS app 的权限。
- [ ] Agreements、Tax、Banking 没有阻塞项。

## App Record

- [ ] Name: `TagLauncher`
- [ ] Bundle ID: `com.taglauncher.app`
- [ ] SKU: `taglauncher-macos`
- [ ] Platform: macOS
- [ ] Category: Utilities
- [ ] Version: `7.8.14`
- [ ] Minimum macOS: `15.0`

## Signing

- [ ] 安装 Mac App Distribution / Apple Distribution 证书。
- [ ] 安装 Mac Installer Distribution 证书。
- [ ] 创建并安装匹配 `com.taglauncher.app` 的 Mac App Store provisioning profile。
- [ ] 按 `BUILD_SIGN_UPLOAD.md` 生成上传 `.pkg`。

## Metadata

- [ ] 填写 description、keywords、support URL、privacy policy URL。
- [ ] 填写 What's New，使用 `APP_STORE_CONNECT_METADATA.md` 中的 7.8.14 文案。
- [ ] 上传 `Screenshots/AppStore/` 中的 Mac 截图。
- [ ] 完成 App Privacy、Age Rating、Export Compliance。
- [ ] 选择价格和可用地区。

## Submission

- [ ] 用 Transporter/Xcode/altool 上传签名 `.pkg`。
- [ ] 等待 Processing 完成。
- [ ] 选择 build `20260605.0122`。
- [ ] 提交审核。
