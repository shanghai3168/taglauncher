# QA Release Evidence

## Build Under Test

- Version: `7.8.3`
- Build: `20260530.1652`
- App: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- Archived DMG: `Archive/TagLauncher-7.8.3-20260530.1652-local-QA.dmg`
- DMG SHA-256: `f369b8ea3ee9b1e3f1e7f8aa9ff2892427292fec1ffbf84943b0044820be749b`

## Checks

- Version metadata:
  - `CFBundleShortVersionString = 7.8.3`
  - `CFBundleVersion = 20260530.1652`
- Code signing:
  - `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`
  - Result: passed
- Disk image:
  - `hdiutil verify build/TagLauncher.dmg`
  - Result: passed
- Window logic:
  - `APP_BUILD=20260530.1652 Scripts/window_logic_qa.sh`
  - Result: `ALL WINDOW LOGIC QA PASSED`

## Targeted Fix Coverage

- Preferences tab overflow:
  - Settings default size increased to `1000 x 480`
  - The system `Navigation Tab Bar` overflow indicator was not present in targeted AX verification.
- Quick Search hidden-Dock chrome:
  - Hidden-Dock quick-only Quick Search keeps accessory activation policy instead of switching to regular app chrome.
  - Targeted verification observed `dockCount=0` and focused text field after invoking Quick Search.

