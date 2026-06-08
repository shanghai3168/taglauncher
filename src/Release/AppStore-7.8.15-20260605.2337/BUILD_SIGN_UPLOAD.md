# Build, Sign, Package, Upload

本目录内 DMG 是本地可回滚候选包，不是 App Store Connect 最终上传包。

## App Store Signing

```bash
APP_STORE=1 \
APP_BUILD=20260605.2337 \
CODESIGN_IDENTITY="Mac App Distribution: YOUR NAME (TEAMID)" \
zsh ./build.sh
```

## Package

```bash
mkdir -p build/AppStore
productbuild \
  --component build/TagLauncher.app /Applications \
  --sign "Mac Installer Distribution: YOUR NAME (TEAMID)" \
  build/AppStore/TagLauncher-7.8.15-build20260605.2337.pkg
```

## Verify

```bash
pkgutil --check-signature build/AppStore/TagLauncher-7.8.15-build20260605.2337.pkg
```

## Upload

Use Transporter, Xcode, or `xcrun altool` to upload the signed `.pkg`.