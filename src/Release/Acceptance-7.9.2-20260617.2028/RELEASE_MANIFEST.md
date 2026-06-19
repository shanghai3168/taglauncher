# Release Manifest - TagLauncher 7.9.2 build 20260617.2028

## Identity

- Product: TagLauncher
- Version: `7.9.2`
- Build: `20260617.2028`
- Bundle ID: `com.taglauncher.app`
- Minimum macOS: `14.0`
- Generated at: `2026-06-19 11:35 CST`
- Branch: `codex/appgrid-usage-tips`
- Source commit: `aba608b433a9dd7e218239947c2c983741fc7fc7`
- Release tag: `v7.9.2-build20260617.2028`

## Artifacts

- Build output DMG: `src/build/TagLauncher-7.9.2-build20260617.2028.dmg`
- Archived DMG: `src/Release/Acceptance-7.9.2-20260617.2028/Archive/TagLauncher-7.9.2-build20260617.2028.dmg`
- DMG SHA256: `7116565fd3a6eac5c65fb785ad31920eea02a9bb8aa5b14f811942e97972231e`
- DMG size: `6041317` bytes

## Build Commands

```bash
cd /Users/ar/Projects/Taglauncher/src
APP_BUILD=20260617.2028 bash build.sh
bash make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.9.2-build20260617.2028.dmg
cp build/TagLauncher-7.9.2-build20260617.2028.dmg Release/Acceptance-7.9.2-20260617.2028/Archive/
```

## Verification Commands

```bash
git diff --check -- src/Apptag/Info.plist src/CHANGELOG.md src/Apptag/ContentView.swift src/Apptag/ApptagApp.swift src/build.sh src/Scripts/macos14_availability_typecheck_qa.sh src/Scripts/tag_navigation_hover_scroll_qa.sh
bash Scripts/tag_navigation_hover_scroll_qa.sh
bash Scripts/macos14_availability_typecheck_qa.sh
APP_BUILD=20260617.2028 bash build.sh
bash Scripts/macos14_build_metadata_qa.sh
hdiutil verify build/TagLauncher-7.9.2-build20260617.2028.dmg
codesign --verify --deep --strict --verbose=2 build/TagLauncher.app
```

Mounted DMG verification checked:

- `CFBundleShortVersionString=7.9.2`
- `CFBundleVersion=20260617.2028`
- `LSMinimumSystemVersion=14.0`
- mounted app `codesign --verify --deep --strict`
- `/Applications` symlink exists

## Release Scope

- Restores App Grid tag-list hover auto-scroll while keeping click-to-scroll immediate.
- Adds hover intent delay and same-tag throttling to reduce the risk of the old hover-scroll jitter regression.
- Keeps app-drag and tag-drag interactions protected from hover-triggered scroll.
- Includes Chinese IME tag input protection, live Dock icon policy repair, and SDK selection hardening already committed in the source freeze.

## Package Type

This release directory contains a DMG acceptance candidate. It does not include an App Store `.pkg` upload package.
