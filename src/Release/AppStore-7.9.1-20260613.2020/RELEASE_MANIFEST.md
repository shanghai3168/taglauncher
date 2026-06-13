# Release Manifest - TagLauncher 7.9.1 build 20260613.2020

## Identity

- Product: TagLauncher
- Version: `7.9.1`
- Build: `20260613.2020`
- Bundle ID: `com.taglauncher.app`
- Minimum macOS: `14.0`
- Category: `public.app-category.utilities`
- Generated at: `2026-06-13 20:38 CST`
- Branch: `codex/appgrid-usage-tips`
- Source commit: `ed4ebcfa763f66ecd69cae57df2c949a7a9a8a45`
- Release tag: `v7.9.1-build20260613.2020`

## Artifacts

- Local archive DMG: `Release/AppStore-7.9.1-20260613.2020/Archive/TagLauncher-7.9.1-build20260613.2020.dmg`
- App Store upload pkg: `Release/AppStore-7.9.1-20260613.2020/Upload/TagLauncher-7.9.1-build20260613.2020.pkg`
- DMG SHA256: `04f93fde15d98901d35f1f6963713a1d6b4af604e83ad3f69dcac2c4c50da138`
- PKG SHA256: `945ba900051e162aa06a4ec6a929b919b6e73062d6507a992c0ea5a807543e12`
- DMG size: `6094717` bytes
- PKG size: `5896739` bytes

## Build Commands

```bash
cd /Users/ar/Projects/Taglauncher/src
APP_BUILD=20260613.2020 bash build.sh
bash make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.9.1-build20260613.2020.dmg
cp build/TagLauncher-7.9.1-build20260613.2020.dmg Release/AppStore-7.9.1-20260613.2020/Archive/
```

## App Store Package Commands

```bash
cd /Users/ar/Projects/Taglauncher/src
APP_BUILD=20260613.2020 bash build.sh

codesign --force --deep --options runtime \
  --sign 0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C \
  --entitlements /tmp/taglauncher-appstore-7.9.1.xB404E/TagLauncher-AppStore-full.entitlements \
  /tmp/taglauncher-appstore-7.9.1.xB404E/stage/TagLauncher.app

productbuild \
  --component /tmp/taglauncher-appstore-7.9.1.xB404E/stage/TagLauncher.app /Applications \
  --sign "3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)" \
  build/AppStore/TagLauncher-7.9.1-build20260613.2020.pkg
```

Before signing, the staging app embedded `TagLauncher Mac App Store 20260605.2337` and ran `xattr -cr` to remove quarantine attributes from the provisioning profile.

## Verification Commands

```bash
git diff --check
bash Scripts/usage_tips_qa.sh
bash Scripts/app_ordering_data_qa.sh
bash Scripts/macos14_availability_typecheck_qa.sh
bash Scripts/macos14_build_metadata_qa.sh
bash Scripts/quick_search_app_name_qa.sh
bash Scripts/quick_search_system_app_qa.sh
bash Scripts/smartstart_catalog_resource_qa.sh
hdiutil verify Release/AppStore-7.9.1-20260613.2020/Archive/TagLauncher-7.9.1-build20260613.2020.dmg
pkgutil --check-signature build/AppStore/TagLauncher-7.9.1-build20260613.2020.pkg
pkgutil --expand-full build/AppStore/TagLauncher-7.9.1-build20260613.2020.pkg /tmp/taglauncher-pkg-preflight-7.9.1-20260613.2020
```

## Release Scope

- Keeps the 7.9.0 same-container App ordering feature and data schema.
- Fixes empty tag visibility so newly created empty tags appear in the sidebar and App Grid with a minimal placeholder container.
- Fixes dragging an app to the blank area outside containers to remove its tag assignment on macOS 14; blank space inside a container remains non-removal space.
- Adds a native AppKit App Grid usage tips HUD with paging, a settings toggle, non-through-click interaction handling, and 29-language localized copy.
- Refines the tips HUD layout: complete title display, hard line breaks for separator text, dots under the arrow controls, and a fixed right-side control zone.

## Apple Upload

- Upload the `.pkg` in `Upload/`, not the `.dmg` in `Archive/`.
- After Transporter upload, wait for App Store Connect processing to finish, then select build `20260613.2020` for version `7.9.1`.
