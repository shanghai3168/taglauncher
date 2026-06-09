# Release Manifest

## Identity

- Product: TagLauncher
- Version: 7.8.24
- Build: 20260609.1221
- Bundle ID: com.taglauncher.app
- Minimum macOS: 15.0
- Category: public.app-category.utilities
- Generated at: 2026-06-09 12:21 HKT
- Branch: codex/relocate-source-to-src
- Source commit: 45a86f77964416a30ba6e93cbea86ed126f35600
- Release tag: v7.8.24-build20260609.1221

## Artifacts

- Local archive DMG: Release/AppStore-7.8.24-20260609.1221/Archive/TagLauncher-7.8.24-build20260609.1221.dmg
- App Store upload pkg: Release/AppStore-7.8.24-20260609.1221/Upload/TagLauncher-7.8.24-build20260609.1221.pkg
- DMG SHA256: 329a87cc769122633f6c306bb9c812151a1a4d68bd9c9ab1fcf6bd665eb0c9d3
- PKG SHA256: 23e9c87db6560fa06c572f6b8353eb74f32f1c4453e87b78ba01f1f6b62c633f
- DMG size: 6002934 bytes
- PKG size: 5818075 bytes

## Commands

```bash
APP_BUILD=20260609.1221 bash build.sh
codesign --force --deep --options runtime --sign 0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C --entitlements /private/tmp/taglauncher-appstore-7.8.24/TagLauncher-AppStore-full.entitlements /private/tmp/taglauncher-appstore-7.8.24/stage/TagLauncher.app
productbuild --component /private/tmp/taglauncher-appstore-7.8.24/stage/TagLauncher.app /Applications --sign "3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)" build/AppStore/TagLauncher-7.8.24-build20260609.1221.pkg
bash make_dmg.sh
cp build/TagLauncher.dmg build/TagLauncher-7.8.24-build20260609.1221.dmg
hdiutil verify build/TagLauncher-7.8.24-build20260609.1221.dmg
```

## Verification Results

- App version/build/category check: PASS
- Code signing strict verification before packaging: PASS
- Apple default app resource QA: PASS
- Apple default note policy QA: PASS
- SmartStart catalog resource QA: PASS
- Quick Search app-name QA: PASS
- Quick Search system app QA: PASS
- DMG verification: PASS
- App Store pkg signature check: signed with `3rd Party Mac Developer Installer`
- Expanded pkg Info.plist check: PASS
- Expanded pkg embedded profile check: PASS
- Expanded pkg signed entitlements check: PASS using `codesign -d --entitlements -`
- Expanded pkg quarantine xattr check: PASS, no `com.apple.quarantine`

## Release Scope

- Fixes first-run Smart Start confirmation hiding the App Grid after the user clicks OK.
- Keeps the 7.8.23 App Grid tag hover stability change.
- Keeps the 7.8.22 Apple default app catalog expansion.
