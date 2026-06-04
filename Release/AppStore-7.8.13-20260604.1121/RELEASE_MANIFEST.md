# Release Manifest

## Identity

- Product: TagLauncher
- Package kind: formal rollback test package / App Store candidate materials
- Version: 7.8.13
- Build: 20260604.1121
- Bundle ID: com.taglauncher.app
- Minimum macOS: 15.0
- Generated at: 2026-06-04 12:15:27 HKT
- Branch: codex/fix-quick-search-focus-routing
- Source commit: 1d19c0593ebe6abe60468e12e87459ab68586603
- Release tag: v7.8.13-build20260604.1121

## Artifact

- Build artifact: build/TagLauncher-7.8.13-build20260604.1121.dmg
- Archived artifact: Release/AppStore-7.8.13-20260604.1121/Archive/TagLauncher-7.8.13-build20260604.1121.dmg
- SHA256: f594509807ca5aa72c6a9fdf118a4f3c9ee991528cd5dbe68587ea5fe601d6f6
- Size: 5990963 bytes

## Build Commands

```bash
APP_BUILD=20260604.1121 zsh ./build.sh
zsh ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.13-build20260604.1121.dmg
```

## Verification Commands

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
codesign --verify --deep --strict build/TagLauncher.app
hdiutil verify build/TagLauncher-7.8.13-build20260604.1121.dmg
shasum -a 256 build/TagLauncher-7.8.13-build20260604.1121.dmg
```

## Verification Results

- App version check: passed, returned `7.8.13`
- App build check: passed, returned `20260604.1121`
- Code signing verification: passed
- DMG verification: passed
- DMG mount metadata check: passed
- DMG contains `TagLauncher.app`
- DMG contains `Applications -> /Applications`
- Mounted App version/build matched expected values
- Mounted App code signing verification: passed
- Targeted Quick Search verification: passed, newly installed `boringNotch` was searchable after app directory signature refresh
- Full window logic QA: passed, returned `ALL WINDOW LOGIC QA PASSED`
- SHA256 recorded: `f594509807ca5aa72c6a9fdf118a4f3c9ee991528cd5dbe68587ea5fe601d6f6`

## Release Scope

- This release supersedes 7.8.12 for App Store submission.
- This release keeps the refresh path light: if application directory signatures have not changed, opening App Grid / Quick Search does not rebuild the index.
- This release does not change App Grid layout, Settings, import/export, file panels, or window level strategy beyond QA hardening.

## Rollback Reference

- Rollback source reference: `v7.8.13-build20260604.1121`
- Rollback artifact reference: `Archive/TagLauncher-7.8.13-build20260604.1121.dmg`
