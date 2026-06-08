# QA Release Evidence

## Build Under Test

- Version: `7.8.6`
- Build: `20260531.0146`
- App: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- Archived DMG: `Archive/TagLauncher-7.8.6-20260531.0146-local-QA.dmg`
- DMG SHA-256: `2664a188b3cb601cc86a36d12e4e4b3aae7fb28f7b470caa8cb0f5ff58ca8bef`

## Checks

- Version metadata:
  - `CFBundleShortVersionString = 7.8.6`
  - `CFBundleVersion = 20260531.0146`
  - `LSUIElement = true`
- Code signing:
  - `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`
  - Result: passed
- Disk image:
  - `hdiutil verify build/TagLauncher.dmg`
  - Result: passed
- Window logic:
  - `APP_BUILD=20260531.0146 Scripts/window_logic_qa.sh`
  - Result: `ALL WINDOW LOGIC QA PASSED`
- Duplicate launch regression:
  - Repeated `open -n build/TagLauncher.app`
  - Expected: one Dock tile, no App Grid
  - Result: passed

## Targeted Fix Coverage

- Reopening an already-running app no longer implicitly shows App Grid.
- Duplicate-instance notifications default to no overlay.
- Non-show duplicate instances start with accessory activation policy to avoid Dock tile multiplication.

