# QA Release Evidence

## Build Under Test

- Version: 7.8.14
- Build: 20260605.0122
- Source commit: e5627facd571293ebba8f05f970121716af39603
- Artifact: Archive/TagLauncher-7.8.14-build20260605.0122.dmg

## Completed Checks

- `APP_BUILD=20260605.0122 zsh ./build.sh`: passed
- `codesign --verify --deep --strict build/TagLauncher.app`: passed
- Built app Info.plist version: `7.8.14`
- Built app Info.plist build: `20260605.0122`
- `zsh ./make_dmg.sh`: passed
- `hdiutil verify build/TagLauncher-7.8.14-build20260605.0122.dmg`: passed
- Mounted DMG contains `TagLauncher.app`: passed
- Mounted DMG contains `Applications -> /Applications`: passed
- Mounted app Info.plist version/build: `7.8.14 / 20260605.0122`
- Mounted app signing verification: passed
- `Scripts/quick_search_system_app_qa.sh`: passed
- `bash -n Scripts/window_logic_qa.sh`: passed
- `git diff --check`: pending final run after release docs are staged

## Regression Verified For This Fix

- Repro app: `/System/Library/CoreServices/Applications/Keychain Access.app`
- User-visible names: `Keychain Access`, `钥匙串访问`
- Verified query candidates: `keychain`, `钥匙串`, `yaoshichuan`, `ysc`
- Expected: Keychain Access is under a configured app search path.
- Expected: Chinese Spotlight display name and `InfoPlist.loctable` name are available as Quick Search candidates.
- Observed: `PASS Keychain Access indexed search candidates: Keychain Access | 钥匙串访问 | 钥匙串访问 | 钥匙串访问`

## Known QA Gap

Full window QA was attempted after the fix, but stopped in an existing coordinate helper assumption when Quick Search result-list bounds were not detected. The Keychain regression itself was covered by the new targeted script. Before final App Store submission, either rerun full window QA after fixing the coordinate helper or accept this as a non-UI indexing-only hotfix with the gap recorded.
