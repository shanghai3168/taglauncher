# QA Release Evidence

## Build Under Test

- Version: 7.8.13
- Build: 20260604.1121
- Source commit: 1d19c0593ebe6abe60468e12e87459ab68586603
- Artifact: Archive/TagLauncher-7.8.13-build20260604.1121.dmg

## Completed Checks

- `APP_BUILD=20260604.1121 zsh ./build.sh`: passed
- `codesign --verify --deep --strict build/TagLauncher.app`: passed
- Built app Info.plist version: `7.8.13`
- Built app Info.plist build: `20260604.1121`
- `zsh ./make_dmg.sh`: passed
- `hdiutil verify build/TagLauncher-7.8.13-build20260604.1121.dmg`: passed
- Mounted DMG contains `TagLauncher.app`: passed
- Mounted DMG contains `Applications -> /Applications`: passed
- Mounted app Info.plist version/build: `7.8.13 / 20260604.1121`
- Mounted app signing verification: passed
- `bash -n Scripts/window_logic_qa.sh`: passed
- `Scripts/window_logic_qa.sh`: passed, final result `ALL WINDOW LOGIC QA PASSED`
- `git diff --cached --check`: passed for the staged 7.8.13 release materials

## Regression Verified For This Fix

- Scenario: a new app is installed after TagLauncher has already built its app index.
- Repro app used by user: boringNotch.
- Expected: App Grid and Quick Search detect standard application directory signature changes when opened.
- Expected: Quick Search for `notch` returns `boringNotch` instead of `未找到 App`.
- Observed targeted result before packaging: `FOUND_BORING=true`, `FOUND_NO_RESULTS=false`.

## Risk Notes

- The refresh trigger only checks standard application directory signatures. It intentionally avoids a full app scan on every open.
- If an app is installed into a nonstandard directory not covered by the configured search paths, it may still require a manual refresh or future search-path expansion.
- The local DMG is ad-hoc signed for rollback QA. App Store upload requires the account-side signed package described in `BUILD_SIGN_UPLOAD.md`.
