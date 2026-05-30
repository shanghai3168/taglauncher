# TagLauncher 7.8.6 Release Pack

This folder freezes TagLauncher `7.8.6` build `20260531.0146` for local QA distribution and Mac App Store submission preparation.

## Release Identity

- Product: `TagLauncher`
- Version: `7.8.6`
- Build: `20260531.0146`
- Branch: `codex/fix-quick-search-focus-routing`
- Local QA DMG: `Archive/TagLauncher-7.8.6-20260531.0146-local-QA.dmg`
- DMG SHA-256: `2664a188b3cb601cc86a36d12e4e4b3aae7fb28f7b470caa8cb0f5ff58ca8bef`

## Changes Since 7.8.5

- Removed the implicit App Grid show path from app reopen events.
- Hardened duplicate-instance handoff so repeated launches do not show App Grid unless explicitly requested.
- Started non-show duplicate instances as accessory processes to prevent duplicate Dock tiles.
- Added window QA coverage for repeated duplicate launches: no extra Dock icons and no unexpected overlay.

## Verification

- App version metadata verified: `7.8.6 (20260531.0146)`
- `LSUIElement = true`
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`: passed
- `hdiutil verify build/TagLauncher.dmg`: passed
- `Scripts/window_logic_qa.sh`: passed
- Targeted duplicate-launch check: repeated `open -n` kept one Dock tile and zero TagLauncher overlay windows.

