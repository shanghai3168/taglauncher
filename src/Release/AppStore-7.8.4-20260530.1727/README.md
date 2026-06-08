# TagLauncher 7.8.4 Release Pack

This folder freezes TagLauncher `7.8.4` build `20260530.1727` for local QA distribution and Mac App Store submission preparation.

## Release Identity

- Product: `TagLauncher`
- Version: `7.8.4`
- Build: `20260530.1727`
- Branch: `codex/fix-quick-search-focus-routing`
- Local QA DMG: `Archive/TagLauncher-7.8.4-20260530.1727-local-QA.dmg`
- DMG SHA-256: `c843d06ed620bd2dd776fafef5e5de38d4abdb623e41e1ebc73ea525b63bf56c`

## Changes Since 7.8.3

- Fixed the global `Fn + Space` Quick Search shortcut so repeated presses toggle Quick Search like Spotlight.
- Reused the keyboard-dismiss path so Quick Search-only sessions also close the backing overlay window.

## Verification

- App version metadata verified: `7.8.4 (20260530.1727)`
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`: passed
- `hdiutil verify build/TagLauncher.dmg`: passed
- `Scripts/window_logic_qa.sh`: passed
- Targeted `Fn + Space` loop: window counts `2 -> 0 -> 2 -> 0`

