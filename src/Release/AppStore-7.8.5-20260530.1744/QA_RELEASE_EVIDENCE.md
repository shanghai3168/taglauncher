# QA Release Evidence

## Build Under Test

- Version: `7.8.5`
- Build: `20260530.1744`
- App: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- Archived DMG: `Archive/TagLauncher-7.8.5-20260530.1744-local-QA.dmg`
- DMG SHA-256: `6efdcf32e4d043601749e4b91ca2c63929822d33d4239d17746aeb77bfd246c7`

## Checks

- Version metadata:
  - `CFBundleShortVersionString = 7.8.5`
  - `CFBundleVersion = 20260530.1744`
- Code signing:
  - `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`
  - Result: passed
- Disk image:
  - `hdiutil verify build/TagLauncher.dmg`
  - Result: passed
- Window logic:
  - `APP_BUILD=20260530.1744 Scripts/window_logic_qa.sh`
  - Result: `ALL WINDOW LOGIC QA PASSED`
- Preferences language layout:
  - Language page uses three columns.
  - Language list uses the available lower window area instead of a fixed short height.
  - Result: passed.

