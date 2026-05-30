# QA Release Evidence

## Build Under Test

- Version: `7.8.7`
- Build: `20260531.0252`
- App: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- Archived DMG: `Archive/TagLauncher-7.8.7-20260531.0252-local-QA.dmg`
- DMG SHA-256: `51cb2861eaf9194dc717cf00b96d3adca490ba89b16438c530b24939a25a94ae`

## Checks

- Version metadata:
  - `CFBundleShortVersionString = 7.8.7`
  - `CFBundleVersion = 20260531.0252`
  - `LSUIElement = true`
- Code signing:
  - `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`
  - Result: passed
- Disk image:
  - `hdiutil verify build/TagLauncher.dmg`
  - Result: passed
- Window logic:
  - `APP_BUILD=20260531.0252 Scripts/window_logic_qa.sh`
  - Result: `ALL WINDOW LOGIC QA PASSED`

## Targeted Fix Coverage

- `Show in Dock = false`, main hotkey:
  - Expected: App Grid appears and no TagLauncher Dock tile appears.
  - Result: passed
- `Show in Dock = true`, Dock icon click:
  - Expected: App Grid appears.
  - Result: passed
- Duplicate launches:
  - Expected: one Dock tile and no unexpected App Grid.
  - Result: passed

