# TagLauncher 7.8.3 Release Pack

This folder freezes TagLauncher `7.8.3` build `20260530.1652` for local QA distribution and Mac App Store submission preparation.

## Release Identity

- Product: `TagLauncher`
- Version: `7.8.3`
- Build: `20260530.1652`
- Branch: `codex/fix-quick-search-focus-routing`
- Local QA DMG: `Archive/TagLauncher-7.8.3-20260530.1652-local-QA.dmg`
- DMG SHA-256: `f369b8ea3ee9b1e3f1e7f8aa9ff2892427292fec1ffbf84943b0044820be749b`

## Changes Since 7.8.2

- Fixed Preferences tabs collapsing into the system `Navigation Tab Bar` overflow by increasing the settings window size.
- Fixed hidden-Dock Quick Search sessions causing a transient Dock/menu chrome flash while preserving automatic input focus.

## Verification

- App version metadata verified: `7.8.3 (20260530.1652)`
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`: passed
- `hdiutil verify build/TagLauncher.dmg`: passed
- `Scripts/window_logic_qa.sh`: passed on rerun; the first run hit one fullscreen-window capture race and the unchanged rerun completed all checks.

