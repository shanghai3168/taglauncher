# Release Manifest

## Identity

- Product: TagLauncher
- Package kind: formal rollback test package / App Store candidate DMG
- Version: 7.8.12
- Build: 20260604.0105
- Generated at: 2026-06-04 01:12:12 HKT
- Branch: codex/fix-quick-search-focus-routing
- Source commit: be83948fab7b643634ede2403abdca27e6b45f29
- Release tag: v7.8.12-build20260604.0105

## Artifact

- Build artifact: build/TagLauncher-7.8.12-build20260604.0105.dmg
- Archived artifact: Release/AppStore-7.8.12-20260604.0105/Archive/TagLauncher-7.8.12-build20260604.0105.dmg
- SHA256: f93702a912fb56a24a826386467b86e607e5b12b55fcc6dbe3b5a7224321be0a
- Size: 5991391 bytes

## Build Commands

```bash
APP_BUILD=20260604.0105 zsh ./build.sh
zsh ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.12-build20260604.0105.dmg
```

## Verification Commands

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
codesign --verify --deep --strict build/TagLauncher.app
hdiutil verify build/TagLauncher-7.8.12-build20260604.0105.dmg
shasum -a 256 build/TagLauncher-7.8.12-build20260604.0105.dmg
```

## Verification Results

- App version check: passed, returned `7.8.12`
- App build check: passed, returned `20260604.0105`
- Code signing verification: passed
- DMG verification: passed
- DMG mount metadata check: passed
- DMG contains `TagLauncher.app`
- DMG contains `Applications -> /Applications`
- Mounted App version/build matched expected values
- Mounted App code signing verification: passed
- Full window logic QA: passed, returned `ALL WINDOW LOGIC QA PASSED`
- SHA256 recorded: `f93702a912fb56a24a826386467b86e607e5b12b55fcc6dbe3b5a7224321be0a`

## Rollback Reference

- Rollback source reference: `v7.8.12-build20260604.0105`
- Rollback artifact reference: `Archive/TagLauncher-7.8.12-build20260604.0105.dmg`
