# TagLauncher 7.8.5 Release Pack

This folder freezes TagLauncher `7.8.5` build `20260530.1744` for local QA distribution and Mac App Store submission preparation.

## Release Identity

- Product: `TagLauncher`
- Version: `7.8.5`
- Build: `20260530.1744`
- Branch: `codex/fix-quick-search-focus-routing`
- Local QA DMG: `Archive/TagLauncher-7.8.5-20260530.1744-local-QA.dmg`
- DMG SHA-256: `6efdcf32e4d043601749e4b91ca2c63929822d33d4239d17746aeb77bfd246c7`

## Changes Since 7.8.4

- Optimized the Preferences language page to show more languages by default.
- Changed the language grid from two columns to three columns.
- Removed the fixed short language-list height so the list uses the available lower area.

## Verification

- App version metadata verified: `7.8.5 (20260530.1744)`
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`: passed
- `hdiutil verify build/TagLauncher.dmg`: passed
- `Scripts/window_logic_qa.sh`: passed
- Targeted Preferences check: language page shows the full language list in three columns and the toolbar does not collapse.

