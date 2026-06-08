# Release Manifest

## Identity

- Product: TagLauncher
- Package kind: formal rollback test package
- Version: 7.8.9
- Build: 20260602.1929
- Generated at: 2026-06-02 19:51:32 HKT
- Branch: codex/fix-quick-search-focus-routing
- Source commit: 406c5898d103427193e589b4bbe615d0c739b2c5
- Release tag: v7.8.9-build20260602.1929

## Artifact

- Build artifact: build/TagLauncher-7.8.9-build20260602.1929.dmg
- Archived artifact: Release/RollbackTest-7.8.9-20260602.1929/Archive/TagLauncher-7.8.9-build20260602.1929.dmg
- SHA256: 353ac022f66935b4668176958e484988f6f0164bfaa581604dd9301daa4ffaf0
- Size: 5983411 bytes

## Build Commands

```bash
APP_BUILD=20260602.1929 zsh ./build.sh
zsh ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.9-build20260602.1929.dmg
```

## Verification Commands

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
codesign --verify --deep --strict build/TagLauncher.app
hdiutil verify build/TagLauncher-7.8.9-build20260602.1929.dmg
shasum -a 256 build/TagLauncher-7.8.9-build20260602.1929.dmg
```

## Verification Results

- App version check: passed, returned `7.8.9`
- App build check: passed, returned `20260602.1929`
- Code signing verification: passed
- DMG verification: passed
- DMG mount metadata check: passed
- SHA256 recorded: `353ac022f66935b4668176958e484988f6f0164bfaa581604dd9301daa4ffaf0`

## Rollback Reference

- Rollback source reference: `v7.8.9-build20260602.1929`
- Rollback artifact reference: `Archive/TagLauncher-7.8.9-build20260602.1929.dmg`

