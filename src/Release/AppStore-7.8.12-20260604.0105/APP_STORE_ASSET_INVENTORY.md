# App Store Asset Inventory

本发布包冻结 TagLauncher `7.8.12` build `20260604.0105`。

## 已包含

- `Archive/TagLauncher-7.8.12-build20260604.0105.dmg`
- `README.md`
- `QA_RELEASE_EVIDENCE.md`
- `RELEASE_MANIFEST.md`
- `SHA256SUMS.txt`
- `APP_STORE_RELEASE_CHECKLIST.md`
- `APP_STORE_CONNECT_METADATA.md`
- `BUILD_SIGN_UPLOAD.md`
- `APP_STORE_ASSET_INVENTORY.md`
- `Assets/TagLauncher-AppIcon-1024.png`
- `Legal/PRIVACY_POLICY.md`
- `Legal/PRIVACY_POLICY.zh-Hans.md`
- `Review/APP_REVIEW_NOTES.md`
- `Screenshots/SCREENSHOT_SHOT_LIST.md`
- `Support/SUPPORT.md`

## 上传前仍需外部完成

- Apple Developer 账号权限：Account Holder、Admin 或 App Manager。
- Apple Developer 最新协议确认。
- 如果收费：Paid Apps Agreement、税务、银行信息。
- App Store Connect app record。
- Mac App Store 签名证书和 provisioning profile。
- App Store signed build / signed `.pkg`。
- 公网 Privacy Policy URL。
- 公网 Support URL。
- 最终 App Store 截图。
- App Review 联系方式。
- 年龄分级、内容权利、出口合规、隐私问卷、价格和销售区域。

## 本地资产核对

- App icon source：`Apptag/Assets.xcassets/AppIcon.appiconset/icon_1024_preview.png`
- Archived icon：`Assets/TagLauncher-AppIcon-1024.png`
- Archived icon size：`1024 x 1024`
- App Sandbox entitlements：
  - `com.apple.security.app-sandbox = true`
  - `com.apple.security.files.user-selected.read-write = true`

## 不能直接上传的文件

- `Archive/TagLauncher-7.8.12-build20260604.0105.dmg` 是本地可回滚候选包，不是 App Store Connect 的上传包。
- App Store Connect 最终应上传由 Apple Distribution / Mac Installer Distribution 签名流程生成的构建产物。
