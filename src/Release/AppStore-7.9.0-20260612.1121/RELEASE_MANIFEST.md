# Release Manifest - TagLauncher 7.9.0 build 20260612.1121

## Identity

- Product: TagLauncher
- Version: `7.9.0`
- Build: `20260612.1121`
- Bundle ID: `com.taglauncher.app`
- Minimum macOS: `14.0`
- Category: `public.app-category.utilities`
- Generated at: `2026-06-12 11:31 HKT`
- Branch: `codex/7.9-app-ordering`
- Source commit: `cc75eee3160d200410dd84e5361dc11af7f01baa`
- Release tag: `v7.9.0-build20260612.1121`

## Artifacts

- Local archive DMG: `Release/AppStore-7.9.0-20260612.1121/Archive/TagLauncher-7.9.0-build20260612.1121.dmg`
- App Store upload pkg: `Release/AppStore-7.9.0-20260612.1121/Upload/TagLauncher-7.9.0-build20260612.1121.pkg`
- DMG SHA256: `12be827edde9ebe56dd63785eb778b48d69be80214b8bb0c850efb4d601c0adf`
- PKG SHA256: `9ccd96344487844f615616edb14d297cd9a197cca7a0a82d1cbd0dd29387a5bd`
- DMG size: `6052912` bytes
- PKG size: `5867022` bytes

## Build Commands

```bash
cd /Users/ar/Projects/Taglauncher/src
APP_BUILD=20260612.1121 bash build.sh
bash make_dmg.sh
cp build/TagLauncher.dmg build/TagLauncher-7.9.0-build20260612.1121.dmg
```

## App Store Package Commands

```bash
codesign --force --deep --options runtime \
  --sign 0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C \
  --entitlements /tmp/.../TagLauncher-AppStore-full.entitlements \
  /tmp/.../stage/TagLauncher.app

productbuild \
  --component /tmp/.../stage/TagLauncher.app /Applications \
  --sign "3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)" \
  build/AppStore/TagLauncher-7.9.0-build20260612.1121.pkg
```

## Verification Commands

```bash
git diff --check
bash Scripts/app_ordering_data_qa.sh
bash Scripts/macos14_availability_typecheck_qa.sh
bash Scripts/macos14_build_metadata_qa.sh
bash Scripts/quick_search_app_name_qa.sh
bash Scripts/quick_search_system_app_qa.sh
bash Scripts/smartstart_catalog_resource_qa.sh
APP_BUILD=20260612.1121 bash Scripts/window_logic_qa.sh
hdiutil verify build/TagLauncher-7.9.0-build20260612.1121.dmg
pkgutil --check-signature build/AppStore/TagLauncher-7.9.0-build20260612.1121.pkg
pkgutil --expand-full build/AppStore/TagLauncher-7.9.0-build20260612.1121.pkg /tmp/pkg-preflight
```

## Release Scope

- Adds same-container App ordering in App Grid.
- Keeps cross-container move, Option copy, empty-space tag removal, Apple built-in protection, and Quick Search ranking behavior unchanged.
- Preserves the macOS 14 compatibility changes and recent Quick Search, SmartStart, settings, edit toolbar, and window logic fixes.

## Apple Upload

- Upload the `.pkg` in `Upload/`, not the `.dmg` in `Archive/`.
- After Transporter upload, wait for App Store Connect processing to finish, then select build `20260612.1121` for version `7.9.0`.
