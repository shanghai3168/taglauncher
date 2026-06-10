# Release Manifest

## Identity

- Product: TagLauncher
- Version: 7.8.26
- Build: 20260609.2004
- Bundle ID: com.taglauncher.app
- Minimum macOS: 15.0
- Category: public.app-category.utilities
- Generated at: 2026-06-09 22:06 HKT
- Branch: codex/relocate-source-to-src
- Source commit: dd1c9fc4c531f1aceaa6d64bbee919ec464655b7
- Release tag: v7.8.26-build20260609.2004

## Artifacts

- Local archive DMG: Release/AppStore-7.8.26-20260609.2004/Archive/TagLauncher-7.8.26-build20260609.2004.dmg
- App Store upload pkg: Release/AppStore-7.8.26-20260609.2004/Upload/TagLauncher-7.8.26-build20260609.2004.pkg
- DMG SHA256: fbc96c0cd618830ddd62c02ba51f2fc5d9757c7e7aa0f1d44aefd8461ab87c3e
- PKG SHA256: b2a5059246aa076d41d40d3839eaa8535c90c437d7e2d4fcd5cbaa7592f7f6d3
- DMG size: 6007796 bytes
- PKG size: 5826613 bytes

## Commands

```bash
APP_BUILD=20260609.2004 bash build.sh
bash make_dmg.sh
cp src/build/TagLauncher.dmg src/build/TagLauncher-7.8.26-build20260609.2004.dmg
codesign --force --deep --options runtime --sign 0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C --entitlements /private/tmp/taglauncher-appstore-7.8.26.NUeEB7/TagLauncher-AppStore-full.entitlements /private/tmp/taglauncher-appstore-7.8.26.NUeEB7/stage/TagLauncher.app
productbuild --component /private/tmp/taglauncher-appstore-7.8.26.NUeEB7/stage/TagLauncher.app /Applications --sign "3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)" src/build/AppStore/TagLauncher-7.8.26-build20260609.2004.pkg
pkgutil --expand-full src/build/AppStore/TagLauncher-7.8.26-build20260609.2004.pkg /private/tmp/taglauncher-7.8.26-pkg-preflight/pkg
```

## Verification Results

- App version/build/category check: PASS
- Apple default app resource QA: PASS
- Apple default note policy QA: PASS
- SmartStart catalog resource QA: PASS
- Quick Search app-name QA: PASS
- Quick Search system app QA: PASS
- DMG verification: PASS
- App Store pkg generated with `3rd Party Mac Developer Installer`
- Expanded pkg Info.plist check: PASS
- Expanded pkg embedded profile check: PASS
- Expanded pkg signed entitlements check: PASS using `codesign -d --entitlements -`
- Expanded pkg quarantine xattr check: PASS, no `com.apple.quarantine`
- Package payload AppleDouble entries: NOTE, 104 `._*` metadata entries, not quarantine
- Executable architecture: NOTE, arm64 only
- Local certificate trust display: NOTE, `pkgutil --check-signature` and App Store app signature display locally untrusted on this machine, matching the prior 7.8.24 package behavior

## Release Scope

- Filters nested helper/wrapper `.app` bundles so Quick Search does not show internal helper apps such as `isunclient` as standalone app results.
- Keeps the 7.8.25 multilingual app display-name resolver and localized search aliases.
- Keeps the 7.8.24 first-run Smart Start App Grid stability fix.
- Keeps the 7.8.23 App Grid tag hover stability change.
- Keeps the 7.8.22 Apple default app catalog expansion.

## Apple Upload

- Upload the `.pkg` in `Upload/`, not the `.dmg` in `Archive/`.
- Apple App Store Connect Help says builds can be uploaded using Xcode, Swift Playgrounds, altool, or Transporter for macOS, and build processing must complete before the build appears in App Store Connect.
- Official reference: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
