# QA Evidence - TagLauncher 7.8.28 build 20260611.1558

## Build Metadata

- Version: `7.8.28`
- Build: `20260611.1558`
- Minimum macOS: `14.0`
- Architecture: `arm64`
- Source commit: `d6fb60c8c128566abab21c6e15b1fd7ce2761235`
- Release tag: `v7.8.28-build20260611.1558`

## Automated QA

```text
PASS macOS 14.0 availability typecheck: arm64
PASS build metadata: LSMinimumSystemVersion=14.0 minos=14.0 arches=arm64
PASS Keychain Access indexed search candidates: Keychain Access | 钥匙串访问 | 钥匙串访问
PASS quick search app-name QA: 贝锐向日葵被控 wrapper wins over nested isunclient
PASS Apple default app resources: 89 apps, 29 languages, notes <= 80
PASS Apple default app runtime resource boundary
PASS Apple default note policy: Apple defaults, SmartStart defaults, and manual notes stay separated
PASS SmartStart catalog resources: 29 languages, 3453 non-Apple entries, 29 notes catalogs with no Apple default conflicts
PASS SmartStart runtime boundary: no Apple default notes or legacy Apple source
```

## Settings Visual Smoke

Window-level screenshots were captured from the local build after opening `TagLauncher Settings`.

- `Screenshots/01-language.png`
- `Screenshots/02-general.png`
- `Screenshots/03-hotkeys.png`
- `Screenshots/04-tags.png`
- `Screenshots/05-data.png`
- `Screenshots/06-about.png`

Observed results:

- Settings window frame: `1000x672`, matching `1000x640` content size plus title bar.
- General tab no longer shows the unwanted vertical scrollbar caused by insufficient content height.
- Top custom tab bar labels are not truncated in Chinese.
- Hotkeys, Data, About, and Language tabs do not show height-compression artifacts.
- Tags tab is list-based and can scroll its tag list as normal content behavior.

## DMG Verification

- `hdiutil verify`: PASS
- DMG mounted read-only under `/private/tmp/taglauncher-dmg-mounts/TagLauncher`: PASS
- Contents:
  - `TagLauncher.app`
  - `Applications -> /Applications`
- Mounted app metadata:
  - `CFBundleShortVersionString=7.8.28`
  - `CFBundleVersion=20260611.1558`
  - `LSMinimumSystemVersion=14.0`
- `codesign --verify --deep --strict --verbose=2`: PASS
- `spctl -a -vv -t exec`: `internal error in Code Signing subsystem` on this ad-hoc build. This candidate is not notarized and is not an App Store upload artifact.

## Remaining External Validation

- Install and smoke-test on a real macOS 14 machine.
- If this candidate is accepted for App Store submission, build a separate App Store signed `.pkg` and run App Store preflight.
