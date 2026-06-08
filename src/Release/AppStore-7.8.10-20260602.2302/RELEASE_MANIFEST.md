# Release Manifest

## Identity

- Product: TagLauncher
- Package kind: formal rollback test package / App Store candidate DMG
- Version: 7.8.10
- Build: 20260602.2302
- Generated at: 2026-06-02 23:08:30 HKT
- Branch: codex/fix-quick-search-focus-routing
- Source commit: bab027127c5d89c5e3f3e83f369065b07a1b0e57
- Release tag: v7.8.10-build20260602.2302

## Artifact

- Build artifact: build/TagLauncher-7.8.10-build20260602.2302.dmg
- Archived artifact: Release/AppStore-7.8.10-20260602.2302/Archive/TagLauncher-7.8.10-build20260602.2302.dmg
- SHA256: 7e8394ae67194f560a99b86760f08b5d543291253c2c9579758812cbd426bc67
- Size: 5984904 bytes

## Build Commands

```bash
APP_BUILD=20260602.2302 zsh ./build.sh
zsh ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.10-build20260602.2302.dmg
```

## Verification Commands

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
codesign --verify --deep --strict build/TagLauncher.app
hdiutil verify build/TagLauncher-7.8.10-build20260602.2302.dmg
shasum -a 256 build/TagLauncher-7.8.10-build20260602.2302.dmg
```

## Verification Results

- App version check: passed, returned `7.8.10`
- App build check: passed, returned `20260602.2302`
- Code signing verification: passed
- DMG verification: passed
- DMG mount metadata check: passed
- DMG contains `TagLauncher.app`
- DMG contains `Applications -> /Applications`
- Mounted App version/build matched expected values
- SHA256 recorded: `7e8394ae67194f560a99b86760f08b5d543291253c2c9579758812cbd426bc67`

## Rollback Reference

- Rollback source reference: `v7.8.10-build20260602.2302`
- Rollback artifact reference: `Archive/TagLauncher-7.8.10-build20260602.2302.dmg`
