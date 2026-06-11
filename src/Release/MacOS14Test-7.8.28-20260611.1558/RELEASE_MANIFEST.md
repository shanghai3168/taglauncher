# Release Manifest - TagLauncher 7.8.28 build 20260611.1558

## Identity

- Product: `TagLauncher`
- Version: `7.8.28`
- Build: `20260611.1558`
- Package type: macOS 14 verification candidate DMG
- Generated at: `2026-06-11 16:27:18 HKT`
- Agent: Codex

## Source

- Branch: `codex/macos14-compatibility`
- Source commit: `d6fb60c8c128566abab21c6e15b1fd7ce2761235`
- Release tag: `v7.8.28-build20260611.1558`
- Source root: `/Users/ar/Projects/Taglauncher/src`

## Build Commands

```bash
APP_BUILD=20260611.1558 bash build.sh
bash make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-7.8.28-build20260611.1558.dmg
```

## Artifact

- Build output: `/Users/ar/Projects/Taglauncher/src/build/TagLauncher-7.8.28-build20260611.1558.dmg`
- Archived copy: `Archive/TagLauncher-7.8.28-build20260611.1558.dmg`
- SHA256: `d5e370542baace17e2e5dac86dd8c912f17cec6f525a6d7a032be4099cab5ed5`
- Size: `5.7M`

## Verification Summary

- `bash Scripts/macos14_availability_typecheck_qa.sh`: PASS
- `bash Scripts/macos14_build_metadata_qa.sh`: PASS
- `bash Scripts/quick_search_system_app_qa.sh`: PASS
- `bash Scripts/quick_search_app_name_qa.sh`: PASS
- `bash Scripts/apple_default_apps_resource_qa.sh`: PASS
- `bash Scripts/apple_default_note_policy_qa.sh`: PASS
- `bash Scripts/smartstart_catalog_resource_qa.sh`: PASS
- `git diff --check`: PASS
- `hdiutil verify build/TagLauncher-7.8.28-build20260611.1558.dmg`: PASS
- Mounted DMG contains `TagLauncher.app` and `Applications -> /Applications`: PASS
- Mounted app metadata: `7.8.28`, `20260611.1558`, `LSMinimumSystemVersion=14.0`
- `codesign --verify --deep --strict --verbose=2`: PASS
- `spctl -a -vv -t exec`: returned `internal error in Code Signing subsystem` for this ad-hoc local test build; not treated as Gatekeeper/notarization PASS.

## Notes

- The DMG is intended for macOS 14 real-machine validation.
- App Store submission needs a separate App Store signed package.
