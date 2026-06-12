# QA Evidence - TagLauncher 7.9.0 build 20260612.1121

## Target

- Version: `7.9.0`
- Build: `20260612.1121`
- Source commit: `cc75eee3160d200410dd84e5361dc11af7f01baa`
- DMG: `Archive/TagLauncher-7.9.0-build20260612.1121.dmg`
- PKG: `Upload/TagLauncher-7.9.0-build20260612.1121.pkg`

## Automated QA

| Check | Result |
| --- | --- |
| `git diff --check` | PASS |
| `Scripts/app_ordering_data_qa.sh` | PASS |
| `Scripts/macos14_availability_typecheck_qa.sh` | PASS |
| `Scripts/macos14_build_metadata_qa.sh` | PASS |
| `Scripts/quick_search_app_name_qa.sh` | PASS |
| `Scripts/quick_search_system_app_qa.sh` | PASS |
| `Scripts/smartstart_catalog_resource_qa.sh` | PASS |
| `APP_BUILD=20260612.1121 Scripts/window_logic_qa.sh` | PASS |

## Package Verification

| Check | Result |
| --- | --- |
| DMG generated | PASS |
| `hdiutil verify` | PASS |
| DMG mount contains `TagLauncher.app` and `Applications` symlink | PASS |
| Mounted app version/build | PASS: `7.9.0 / 20260612.1121` |
| App Store `.pkg` generated | PASS |
| `.pkg` Installer certificate signature | PASS |
| Expanded `.pkg` contains `TagLauncher.app` | PASS |
| Bundle ID | PASS: `com.taglauncher.app` |
| Minimum macOS | PASS: `14.0` |
| Embedded provisioning profile | PASS |
| Signed application identifier | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed team identifier | PASS: `CR3J54M8BQ` |
| Sandbox entitlement | PASS |
| User-selected file read/write entitlement | PASS |
| Keychain access group | PASS: `CR3J54M8BQ.*` |
| Expanded package quarantine xattr | PASS: `0` |
| Package payload AppleDouble entries | PASS: `0` |
| Executable architecture | PASS: `arm64` |

## Hashes

- DMG SHA256: `12be827edde9ebe56dd63785eb778b48d69be80214b8bb0c850efb4d601c0adf`
- PKG SHA256: `9ccd96344487844f615616edb14d297cd9a197cca7a0a82d1cbd0dd29387a5bd`

## Notes

- The package is arm64-only, consistent with the current build pipeline.
- `pkgutil --check-signature` reports a valid Apple-issued Installer certificate chain on this machine.
