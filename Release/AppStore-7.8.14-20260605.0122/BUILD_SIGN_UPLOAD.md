# Build, Sign, Package, Upload

本目录内 DMG 是本地 QA / 可回滚候选包，不是 App Store Connect 最终上传包。

## Local Candidate

- `Archive/TagLauncher-7.8.14-build20260605.0122.dmg`
- SHA256: `f6c8049911ee4130031558d1957ea62cd455452518c64edfcbbbabc61aa010b6`

## App Store Signing Example

```bash
APP_STORE=1 \
APP_BUILD=20260605.0122 \
CODESIGN_IDENTITY="Mac App Distribution: YOUR NAME (TEAMID)" \
zsh ./build.sh
```

```bash
mkdir -p build/AppStore
productbuild \
  --component build/TagLauncher.app /Applications \
  --sign "Mac Installer Distribution: YOUR NAME (TEAMID)" \
  build/AppStore/TagLauncher-7.8.14-build20260605.0122.pkg
```

```bash
pkgutil --check-signature build/AppStore/TagLauncher-7.8.14-build20260605.0122.pkg
```

Upload the signed `.pkg` with Transporter, Xcode, or `xcrun altool`.
