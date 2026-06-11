# Release Manifest - TagLauncher 7.9.0 build 20260611.2212

## Identity

- Product: TagLauncher
- Version: `7.9.0`
- Build: `20260611.2212`
- Branch: `codex/7.9-app-ordering`
- Source commit: `a1ade5e8426d9cccd3c59f692d6fab55e67021fa`
- Release tag: `v7.9.0-build20260611.2212`
- Package type: acceptance candidate DMG

## Artifact

- Build output: `src/build/TagLauncher-7.9.0-build20260611.2212.dmg`
- Archived copy: `src/Release/Acceptance-7.9.0-20260611.2212/Archive/TagLauncher-7.9.0-build20260611.2212.dmg`
- SHA256: `986f4b5ad1d351f8ce08460414564c22b599d1c251a4078d571c07c26b8d93f6`

## Build Commands

```bash
cd /Users/ar/Projects/Taglauncher/src
APP_BUILD=20260611.2212 bash build.sh
bash make_dmg.sh
cp build/TagLauncher.dmg build/TagLauncher-7.9.0-build20260611.2212.dmg
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
bash Scripts/window_logic_qa.sh
hdiutil verify build/TagLauncher-7.9.0-build20260611.2212.dmg
codesign --verify --deep --strict build/TagLauncher.app
```

## Metadata Checks

- Source `Info.plist`: `CFBundleShortVersionString=7.9.0`, `CFBundleVersion=20260611.2212`
- Built app `Info.plist`: `CFBundleShortVersionString=7.9.0`, `CFBundleVersion=20260611.2212`
- Mounted DMG app `Info.plist`: `CFBundleShortVersionString=7.9.0`, `CFBundleVersion=20260611.2212`
- Mounted DMG contents: `TagLauncher.app`, `Applications` symlink

## Notes

- This package is for local/user acceptance testing.
- App Store upload packaging is not included in this release directory.
