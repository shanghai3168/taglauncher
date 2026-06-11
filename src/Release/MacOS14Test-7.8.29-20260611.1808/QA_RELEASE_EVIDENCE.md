# QA Release Evidence

## Scope

This release validates the edit-mode action controls and localized hint copy for TagLauncher 7.8.29 build 20260611.1808.

## Completed Checks

- `bash Scripts/macos14_availability_typecheck_qa.sh`
  - PASS: arm64 macOS 14.0 availability typecheck.
- `APP_BUILD=20260611.1808 bash build.sh`
  - PASS: app bundle built at `src/build/TagLauncher.app`.
- `bash Scripts/macos14_build_metadata_qa.sh`
  - PASS: `LSMinimumSystemVersion=14.0`, `minos=14.0`, `arches=arm64`.
- `bash Scripts/quick_search_system_app_qa.sh`
  - PASS: Keychain Access system app search candidates.
- `bash Scripts/quick_search_app_name_qa.sh`
  - PASS: Sunlogin wrapper result wins over nested `isunclient`.
- `bash Scripts/apple_default_apps_resource_qa.sh`
  - PASS: 89 Apple default apps, 29 languages, runtime resource boundary.
- `bash Scripts/apple_default_note_policy_qa.sh`
  - PASS: Apple defaults, SmartStart defaults, and manual notes remain separated.
- `bash Scripts/smartstart_catalog_resource_qa.sh`
  - PASS: 29 languages, 3453 non-Apple entries, no Apple default conflicts.
- `git diff --check`
  - PASS.
- Localization JSON parse check
  - PASS: all 29 localization JSON files parse successfully.
- Built resource check
  - PASS: built app bundle contains 29 localization JSON files and the new add-mode hint in Chinese, English, and Japanese.
- `/usr/bin/codesign --verify --deep --strict --verbose=2 src/build/TagLauncher.app`
  - PASS: app bundle is valid on disk and satisfies its designated requirement.
- `hdiutil verify src/build/TagLauncher-7.8.29-build20260611.1808.dmg`
  - PASS: DMG checksum is valid.

## Manual Acceptance

- User manually verified the edit-mode toolbar visual result and confirmed it is OK.
- Evidence screenshot: `Screenshots/01-edit-mode-user-accepted.png`.
- Copy refinement request screenshot: `Screenshots/02-edit-mode-copy-request.png`.

## Known Local QA Limitation

- DMG mount/imageinfo checks could not be completed in this Codex environment because `hdiutil attach` and `hdiutil imageinfo` returned `设备未配置`.
- This limitation was local to the mount/device access path; `hdiutil verify`, app bundle metadata, app bundle signature verification, checksum generation, and built resource checks passed.
