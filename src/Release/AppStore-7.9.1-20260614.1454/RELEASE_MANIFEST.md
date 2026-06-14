# Release Manifest - TagLauncher 7.9.1 build 20260614.1454

## Identity

- Product: TagLauncher
- Version: `7.9.1`
- Build: `20260614.1454`
- Bundle ID: `com.taglauncher.app`
- Minimum macOS: `14.0`
- Category: `public.app-category.utilities`
- Generated at: `2026-06-14 15:03 CST`
- Branch: `codex/appgrid-usage-tips`
- Source commit: `bd792cd36d57b8f0741af9a6a64e59969cdce490`
- Release tag: `v7.9.1-build20260614.1454`

## Artifacts

- Local archive DMG: `Release/AppStore-7.9.1-20260614.1454/Archive/TagLauncher-7.9.1-build20260614.1454.dmg`
- App Store upload pkg: `Release/AppStore-7.9.1-20260614.1454/Upload/TagLauncher-7.9.1-build20260614.1454.pkg`
- DMG SHA256: `2cb29528ef1c137db330ff8a28baa3c622705916f8368b28c373ca95aefd6981`
- PKG SHA256: `7ad097a23c736fc7a7b34a9575348cbc52a968d5fbf433584ace353b120a32ef`
- DMG size: `6093221` bytes
- PKG size: `5894105` bytes

## Build Commands

```bash
cd /Users/ar/Projects/Taglauncher/src
APP_BUILD=20260614.1454 bash build.sh
bash make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.9.1-build20260614.1454.dmg
cp build/TagLauncher-7.9.1-build20260614.1454.dmg Release/AppStore-7.9.1-20260614.1454/Archive/
```

## App Store Package Commands

```bash
cd /Users/ar/Projects/Taglauncher/src

codesign --force --deep --options runtime \
  --sign 0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C \
  --entitlements /tmp/taglauncher-appstore-7.9.1.72KIck/TagLauncher-AppStore-full.entitlements \
  /tmp/taglauncher-appstore-7.9.1.72KIck/stage/TagLauncher.app

productbuild \
  --component /tmp/taglauncher-appstore-7.9.1.72KIck/stage/TagLauncher.app /Applications \
  --sign "3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)" \
  build/AppStore/TagLauncher-7.9.1-build20260614.1454.pkg
```

Before signing, the staging app embedded `TagLauncher Mac App Store 20260605.2337` and ran `xattr -cr` to remove quarantine attributes from the app bundle.

## Verification Commands

```bash
git diff --check -- src/Apptag/Info.plist src/CHANGELOG.md src/Apptag/AppGridCollectionView.swift src/Scripts/usage_tips_qa.sh src/Apptag/Localization
bash Scripts/usage_tips_qa.sh
bash Scripts/app_ordering_data_qa.sh
bash Scripts/macos14_availability_typecheck_qa.sh
bash Scripts/macos14_build_metadata_qa.sh
bash Scripts/quick_search_app_name_qa.sh
bash Scripts/quick_search_system_app_qa.sh
bash Scripts/smartstart_catalog_resource_qa.sh
hdiutil verify Release/AppStore-7.9.1-20260614.1454/Archive/TagLauncher-7.9.1-build20260614.1454.dmg
pkgutil --check-signature build/AppStore/TagLauncher-7.9.1-build20260614.1454.pkg
pkgutil --expand-full build/AppStore/TagLauncher-7.9.1-build20260614.1454.pkg /tmp/taglauncher-pkg-preflight-7.9.1-20260614.1454
codesign --verify --deep --strict --verbose=2 /tmp/taglauncher-pkg-preflight-7.9.1-20260614.1454/com.taglauncher.app.pkg/Payload/TagLauncher.app
```

## Release Scope

- Keeps version `7.9.1`; only updates build to `20260614.1454`.
- Fixes incomplete non-Chinese App Grid usage-tip sentences by using a comma in localized strings as the line-break marker.
- Keeps Simplified Chinese and Traditional Chinese usage-tip copy unchanged.
- Keeps the 7.9.1 App Grid features from build `20260613.2020`: empty tag visibility, blank-space tag removal reliability on macOS 14, native AppKit usage tips HUD, tips settings toggle, and manual app ordering.

## Apple Upload

- Upload the `.pkg` in `Upload/`, not the `.dmg` in `Archive/`.
- After Transporter upload, wait for App Store Connect processing to finish, then select build `20260614.1454` for version `7.9.1`.
