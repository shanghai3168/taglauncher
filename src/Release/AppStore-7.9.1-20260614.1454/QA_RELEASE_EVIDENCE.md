# QA Evidence - TagLauncher 7.9.1 build 20260614.1454

## Target

- Version: `7.9.1`
- Build: `20260614.1454`
- Source commit: `bd792cd36d57b8f0741af9a6a64e59969cdce490`
- DMG: `Archive/TagLauncher-7.9.1-build20260614.1454.dmg`
- PKG: `Upload/TagLauncher-7.9.1-build20260614.1454.pkg`

## Automated QA

| Check | Result |
| --- | --- |
| `git diff --check -- src/Apptag/Info.plist src/CHANGELOG.md src/Apptag/AppGridCollectionView.swift src/Scripts/usage_tips_qa.sh src/Apptag/Localization` | PASS |
| `Scripts/usage_tips_qa.sh` | PASS |
| `Scripts/app_ordering_data_qa.sh` | PASS |
| `Scripts/macos14_availability_typecheck_qa.sh` | PASS |
| `Scripts/macos14_build_metadata_qa.sh` | PASS |
| `Scripts/quick_search_app_name_qa.sh` | SKIP: Sunlogin wrapper app not installed on this Mac |
| `Scripts/quick_search_system_app_qa.sh` | PASS |
| `Scripts/smartstart_catalog_resource_qa.sh` | PASS |

## Localization QA

| Check | Result |
| --- | --- |
| 27 non-Chinese languages, tips 1-8 each contain exactly one ASCII comma separator | PASS |
| 27 non-Chinese languages, tips 1-8 have no `>`, `->`, `-->`, `→`, or `＞` separator | PASS |
| 27 non-Chinese languages, both sides of the separator are non-empty | PASS |
| `zh-Hans` and `zh-Hant` usage-tip copy unchanged in this fix | PASS |

## Manual Acceptance

| Check | Result |
| --- | --- |
| App Grid usage tips paging and click behavior | PASS: user manually accepted before this packaging step |

## Package Verification

| Check | Result |
| --- | --- |
| DMG generated | PASS |
| `hdiutil verify` | PASS |
| Built app version/build | PASS: `7.9.1 / 20260614.1454` |
| App Store `.pkg` generated | PASS |
| `.pkg` Installer certificate signature | PASS |
| Expanded `.pkg` contains `TagLauncher.app` | PASS |
| Bundle ID | PASS: `com.taglauncher.app` |
| `CFBundleShortVersionString` | PASS: `7.9.1` |
| `CFBundleVersion` | PASS: `20260614.1454` |
| Minimum macOS | PASS: `14.0` |
| Category | PASS: `public.app-category.utilities` |
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

- DMG SHA256: `2cb29528ef1c137db330ff8a28baa3c622705916f8368b28c373ca95aefd6981`
- PKG SHA256: `7ad097a23c736fc7a7b34a9575348cbc52a968d5fbf433584ace353b120a32ef`

## Notes

- The package is arm64-only, consistent with the current build pipeline.
- `pkgutil --check-signature` reports a valid Apple-issued Installer certificate chain on this machine.
- No extra GUI automation was run after the user's manual acceptance of the latest tips behavior.
