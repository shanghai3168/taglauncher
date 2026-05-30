# TagLauncher 7.8.7 Release Pack

This folder freezes TagLauncher `7.8.7` build `20260531.0252` for local QA distribution and Mac App Store submission preparation.

## Release Identity

- Product: `TagLauncher`
- Version: `7.8.7`
- Build: `20260531.0252`
- Branch: `codex/fix-quick-search-focus-routing`
- Local QA DMG: `Archive/TagLauncher-7.8.7-20260531.0252-local-QA.dmg`
- DMG SHA-256: `51cb2861eaf9194dc717cf00b96d3adca490ba89b16438c530b24939a25a94ae`

## Changes Since 7.8.6

- Hidden-Dock mode no longer flashes the TagLauncher Dock icon when opening App Grid with the main hotkey.
- Dock icon click opens App Grid when `Show in Dock` is enabled.
- Programmatic duplicate launches remain blocked from opening App Grid.
- Overlay frame is rechecked after show-time system coordinate changes to reduce fullscreen/multi-display drift.

## Verification

- App version metadata verified: `7.8.7 (20260531.0252)`
- `LSUIElement = true`
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`: passed
- `hdiutil verify build/TagLauncher.dmg`: passed
- `Scripts/window_logic_qa.sh`: passed
- Targeted checks:
  - `showDockIcon=false` + main hotkey: App Grid appears, no TagLauncher Dock tile.
  - `showDockIcon=true` + Dock click: App Grid appears.
  - repeated launches: one Dock tile, no unexpected App Grid.

