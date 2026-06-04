# Release Manifest

## Identity

- Product: TagLauncher
- Version: 7.8.14
- Build: 20260605.0150
- Bundle ID: com.taglauncher.app
- Minimum macOS: 15.0
- Generated at: 2026-06-05 02:04:08 HKT
- Branch: codex/fix-quick-search-focus-routing
- Source commit: 5194065f5cebfa847061c43cf2c568a1c91721ce
- Release tag: v7.8.14-build20260605.0150

## Artifact

- Build artifact: build/TagLauncher-7.8.14-build20260605.0150.dmg
- Archived artifact: Release/AppStore-7.8.14-20260605.0150/Archive/TagLauncher-7.8.14-build20260605.0150.dmg
- SHA256: 1f1fb2502aac3d1d069ff9cf8ba731f6d42faa58e479304ebf914de5d8a3ee34
- Size: 5990829 bytes

## Commands

```bash
APP_BUILD=20260605.0150 zsh ./build.sh
zsh ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.14-build20260605.0150.dmg
```

## Verification Results

- App version check: passed, returned `7.8.14`
- App build check: passed, returned `20260605.0150`
- Code signing verification: passed
- Keychain Access targeted regression: passed
- DMG verification: passed
- DMG mount metadata check: passed
- DMG contains `TagLauncher.app`
- DMG contains `Applications -> /Applications`

## Release Scope

- This build is the final 7.8.14 App Store submission candidate.
- It includes CoreServices system apps such as Keychain Access in the local app index.
- It keeps the lightweight directory-signature refresh behavior introduced in 7.8.13.
