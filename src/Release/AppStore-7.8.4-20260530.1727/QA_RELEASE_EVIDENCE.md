# QA Release Evidence

## Build Under Test

- Version: `7.8.4`
- Build: `20260530.1727`
- App: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- Archived DMG: `Archive/TagLauncher-7.8.4-20260530.1727-local-QA.dmg`
- DMG SHA-256: `c843d06ed620bd2dd776fafef5e5de38d4abdb623e41e1ebc73ea525b63bf56c`

## Checks

- Version metadata:
  - `CFBundleShortVersionString = 7.8.4`
  - `CFBundleVersion = 20260530.1727`
- Code signing:
  - `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`
  - Result: passed
- Disk image:
  - `hdiutil verify build/TagLauncher.dmg`
  - Result: passed
- Window logic:
  - `APP_BUILD=20260530.1727 Scripts/window_logic_qa.sh`
  - Result: `ALL WINDOW LOGIC QA PASSED`
- Quick Search toggle:
  - Four consecutive `Fn + Space` invocations produced on-screen TagLauncher window counts `2, 0, 2, 0`
  - Result: passed

## Targeted Fix Coverage

- The Quick Search global hotkey now dismisses an already-open Quick Search instead of only refocusing it.
- Quick Search-only dismissal hides the backing overlay window, matching the Spotlight-style toggle behavior.

