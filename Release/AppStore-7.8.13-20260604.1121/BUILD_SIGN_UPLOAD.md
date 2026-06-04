# Build, Sign, Package, Upload

## 当前状态

本目录内的 DMG 是本地 QA / 可回滚候选包：

- `Archive/TagLauncher-7.8.13-build20260604.1121.dmg`
- SHA256: `f594509807ca5aa72c6a9fdf118a4f3c9ee991528cd5dbe68587ea5fe601d6f6`

它不是 App Store Connect 最终上传包。App Store 上传需要 Apple Developer 账号侧证书和 provisioning profile。

## 账号侧前置条件

- Apple Developer Program 会员有效。
- App Store Connect 中存在 macOS app record。
- Bundle ID 是 `com.taglauncher.app`。
- Keychain 中有 Mac App Distribution 或 Apple Distribution 证书。
- Keychain 中有 Mac Installer Distribution 证书。
- 已下载并安装匹配 `com.taglauncher.app` 的 Mac App Store provisioning profile。

## 手动签名构建示例

把证书名称替换为你 Keychain 中的真实名称：

```bash
APP_STORE=1 \
APP_BUILD=20260604.1121 \
CODESIGN_IDENTITY="Mac App Distribution: YOUR NAME (TEAMID)" \
zsh ./build.sh
```

验证：

```bash
codesign --verify --deep --strict build/TagLauncher.app
codesign -d --entitlements :- build/TagLauncher.app
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
```

## 生成 Mac App Store 上传包

示例命令：

```bash
mkdir -p build/AppStore
productbuild \
  --component build/TagLauncher.app /Applications \
  --sign "Mac Installer Distribution: YOUR NAME (TEAMID)" \
  build/AppStore/TagLauncher-7.8.13-build20260604.1121.pkg
```

验证 package 签名：

```bash
pkgutil --check-signature build/AppStore/TagLauncher-7.8.13-build20260604.1121.pkg
```

## 上传方式

Apple 当前支持用 Xcode、Swift Playground、altool 或 Transporter 上传构建。对这个项目，推荐先用 Transporter 图形界面上传 `.pkg`，因为它能直接显示交付日志和错误。

可选命令行校验和上传：

```bash
xcrun altool --validate-app \
  -f build/AppStore/TagLauncher-7.8.13-build20260604.1121.pkg \
  -t macos \
  -u APPLE_ID_EMAIL \
  -p APP_SPECIFIC_PASSWORD

xcrun altool --upload-app \
  -f build/AppStore/TagLauncher-7.8.13-build20260604.1121.pkg \
  -t macos \
  -u APPLE_ID_EMAIL \
  -p APP_SPECIFIC_PASSWORD
```

## 上传后检查

- App Store Connect 中 build 进入 Processing。
- Processing 完成后，选择 version `7.8.13` 的 build。
- 检查没有 Invalid Binary、Missing Entitlement、Bundle ID mismatch、version/build mismatch。
- 填写 `APP_STORE_CONNECT_METADATA.md` 中的文案。
- 上传 `Screenshots/AppStore/` 中的截图。
- 发布隐私政策 URL，并在 App Privacy 中提交问卷。
- 提交 App Review。
