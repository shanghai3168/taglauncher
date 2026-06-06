# Release Manifest

## Identity

- Product: TagLauncher
- Version: 7.8.15
- Build: 20260605.2337
- Bundle ID: com.taglauncher.app
- Minimum macOS: 15.0
- Generated at: 2026-06-05 23:41:00 HKT
- Branch: codex/recover-7.8.15-grok-fix
- Source commit: 6dea81ebd24bcdb3c62ff8d2251a2670cb8b64c5
- Release tag: v7.8.15-build20260605.2337

## Artifact

- Build artifact: build/TagLauncher-7.8.15-build20260605.2337.dmg
- Archived artifact: Release/AppStore-7.8.15-20260605.2337/Archive/TagLauncher-7.8.15-build20260605.2337.dmg
- SHA256: ed1938afe16ee22cb28adc90231f6f9d6566c186025371c70c9da9c7f04ea493
- Size: 5991360 bytes

## Commands

```bash
APP_BUILD=20260605.2337 zsh ./build.sh
zsh ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.15-build20260605.2337.dmg
```

## Verification Results

- App version check: passed, returned `7.8.15`
- App build check: passed, returned `20260605.2337`
- Code signing verification: passed
- DMG verification: passed
- DMG mount metadata check: passed
- DMG contains `TagLauncher.app`
- DMG contains `Applications -> /Applications`

## Release Scope

- This build is the final 7.8.15 App Store submission candidate.
- Fixes App Grid showing an endless loading spinner when reopened while the in-memory app index cache is still valid.
- Warms the app index in the background at launch to reduce first-open wait time.
- Retains 7.8.14 CoreServices system app indexing (Keychain Access) and 7.8.13 lightweight directory-signature refresh behavior.
