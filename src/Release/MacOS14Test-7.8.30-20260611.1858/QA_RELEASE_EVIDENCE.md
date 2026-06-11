# QA Release Evidence

## Scope

Validate TagLauncher 7.8.30 build 20260611.1858 as a DMG candidate for the setting-page uncategorized layout reset.

## Completed Checks

- Localization JSON parse check
  - PASS: all 29 localization JSON files parse successfully.
- Localization key coverage
  - PASS: all 29 languages contain `settings.initialLayout` and `settings.resetToUncategorizedWarningMessage`.
- `git diff --check`
  - PASS.
- `bash Scripts/macos14_availability_typecheck_qa.sh`
  - PASS: arm64 macOS 14.0 availability typecheck.
- `APP_BUILD=20260611.1858 bash build.sh`
  - PASS: app bundle built at `src/build/TagLauncher.app`.
- `bash Scripts/macos14_build_metadata_qa.sh`
  - PASS: `LSMinimumSystemVersion=14.0`, `minos=14.0`, `arches=arm64`.
- Built app metadata
  - PASS: `CFBundleShortVersionString=7.8.30`, `CFBundleVersion=20260611.1858`.
- Built localization resources
  - PASS: app bundle contains 29 localization JSON files and the new Chinese/English reset strings.
- `/usr/bin/codesign --verify --deep --strict --verbose=2 src/build/TagLauncher.app`
  - PASS: app bundle is valid on disk and satisfies its designated requirement.
- `hdiutil verify src/build/TagLauncher-7.8.30-build20260611.1858.dmg`
  - PASS: DMG checksum is valid.
- `shasum -a 256 src/build/TagLauncher-7.8.30-build20260611.1858.dmg`
  - PASS: `15de0d93d93e897690cc146fc058035daa72d06708cc31a6d74409537441ab78`.

## Notes

- The reset action was not executed against the user's real TagLauncher database during QA.
- The feature path is guarded by a confirmation dialog before any app-tag relationships are removed.
