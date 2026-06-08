# Release Manifest

## Identity

- Product: TagLauncher
- Package kind: formal rollback test package / App Store candidate materials
- Version: 7.8.14
- Build: 20260605.0122
- Bundle ID: com.taglauncher.app
- Minimum macOS: 15.0
- Generated at: 2026-06-05 01:33:18 HKT
- Branch: codex/fix-quick-search-focus-routing
- Source commit: e5627facd571293ebba8f05f970121716af39603
- Release tag: v7.8.14-build20260605.0122

## Artifact

- Build artifact: build/TagLauncher-7.8.14-build20260605.0122.dmg
- Archived artifact: Release/AppStore-7.8.14-20260605.0122/Archive/TagLauncher-7.8.14-build20260605.0122.dmg
- SHA256: f6c8049911ee4130031558d1957ea62cd455452518c64edfcbbbabc61aa010b6
- Size: 5990796 bytes

## Build Commands

```bash
APP_BUILD=20260605.0122 zsh ./build.sh
zsh ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.14-build20260605.0122.dmg
```

## Verification Results

- App version check: passed, returned `7.8.14`
- App build check: passed, returned `20260605.0122`
- Code signing verification: passed
- DMG verification: passed
- DMG mount metadata check: passed
- DMG contains `TagLauncher.app`
- DMG contains `Applications -> /Applications`
- Mounted App version/build matched expected values
- Mounted App code signing verification: passed
- `Scripts/quick_search_system_app_qa.sh`: passed
- `bash -n Scripts/window_logic_qa.sh`: passed
- Full `Scripts/window_logic_qa.sh`: attempted with `APP_BUILD=20260605.0122`, stopped at existing Quick Search result-coordinate precondition: `FAIL: could not find quick search result-list bounds`. Do not count this as a passed full-window QA run for 7.8.14.

## Release Scope

- This release supersedes 7.8.13 for App Store submission.
- This release changes app discovery coverage only; it does not alter Quick Search ranking, UI layout, window layering, Settings, or import/export behavior.

## Rollback Reference

- Rollback source reference: `v7.8.14-build20260605.0122`
- Rollback artifact reference: `Archive/TagLauncher-7.8.14-build20260605.0122.dmg`
