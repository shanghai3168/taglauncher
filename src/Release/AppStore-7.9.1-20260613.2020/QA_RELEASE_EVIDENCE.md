# QA Evidence - TagLauncher 7.9.1 build 20260613.2020

## Target

- Version: `7.9.1`
- Build: `20260613.2020`
- Source commit: `ed4ebcfa763f66ecd69cae57df2c949a7a9a8a45`
- DMG: `Archive/TagLauncher-7.9.1-build20260613.2020.dmg`
- PKG: `Upload/TagLauncher-7.9.1-build20260613.2020.pkg`

## Automated QA

| Check | Result |
| --- | --- |
| `git diff --check` | PASS |
| `Scripts/usage_tips_qa.sh` | PASS |
| `Scripts/app_ordering_data_qa.sh` | PASS |
| `Scripts/macos14_availability_typecheck_qa.sh` | PASS |
| `Scripts/macos14_build_metadata_qa.sh` | PASS |
| `Scripts/quick_search_app_name_qa.sh` | SKIP: Sunlogin wrapper app not installed on this Mac |
| `Scripts/quick_search_system_app_qa.sh` | PASS |
| `Scripts/smartstart_catalog_resource_qa.sh` | PASS |

## Manual Acceptance

| Check | Result |
| --- | --- |
| App Grid usage tips paging and click behavior | PASS: user manually accepted |

## Package Verification

| Check | Result |
| --- | --- |
| DMG generated | PASS |
| `hdiutil verify` | PASS |
| DMG mount contains `TagLauncher.app` and `Applications` symlink | PASS |
| Built app version/build | PASS: `7.9.1 / 20260613.2020` |
| App Store `.pkg` generated | PASS |
| `.pkg` Installer certificate signature | PASS |
| Expanded `.pkg` contains `TagLauncher.app` | PASS |
| Bundle ID | PASS: `com.taglauncher.app` |
| Minimum macOS | PASS: `14.0` |
| Embedded provisioning profile | PASS |
| Profile application identifier | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed application identifier | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed team identifier | PASS: `CR3J54M8BQ` |
| Sandbox entitlement | PASS |
| User-selected file read/write entitlement | PASS |
| Keychain access group | PASS: `CR3J54M8BQ.*` |
| Expanded package quarantine xattr | PASS: `0` |
| Package payload AppleDouble entries | PASS: `0` |
| Executable architecture | PASS: `arm64` |

## Hashes

- DMG SHA256: `04f93fde15d98901d35f1f6963713a1d6b4af604e83ad3f69dcac2c4c50da138`
- PKG SHA256: `945ba900051e162aa06a4ec6a929b919b6e73062d6507a992c0ea5a807543e12`

## Notes

- The package is arm64-only, consistent with the current build pipeline.
- `pkgutil --check-signature` reports a valid Apple-issued Installer certificate chain on this machine.
- No extra GUI automation was run after the user's manual acceptance of the latest tips behavior.
