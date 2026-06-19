# QA Evidence - TagLauncher 7.9.2 build 20260617.2028

## Identity

- Product: `TagLauncher`
- Version: `7.9.2`
- Build: `20260617.2028`
- Source commit: `aba608b433a9dd7e218239947c2c983741fc7fc7`
- Release tag: `v7.9.2-build20260617.2028`
- Artifact: `Archive/TagLauncher-7.9.2-build20260617.2028.dmg`

## Verification

| Check | Result |
| --- | --- |
| `git diff --check` for release-scoped files | PASS |
| `bash Scripts/tag_navigation_hover_scroll_qa.sh` | PASS |
| `bash Scripts/macos14_availability_typecheck_qa.sh` | PASS |
| `APP_BUILD=20260617.2028 bash build.sh` | PASS |
| `bash Scripts/macos14_build_metadata_qa.sh` | PASS |
| Built app metadata | PASS: `7.9.2 / 20260617.2028 / LSMinimumSystemVersion=14.0` |
| `hdiutil verify build/TagLauncher-7.9.2-build20260617.2028.dmg` | PASS |
| `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app` | PASS |
| Mounted DMG app metadata | PASS: `7.9.2 / 20260617.2028 / LSMinimumSystemVersion=14.0` |
| Mounted DMG app codesign | PASS |
| DMG `/Applications` symlink | PASS |

## Residual Notes

- A lightweight real GUI smoke was attempted during development, but the local desktop did not consistently bring App Grid to front through the global hotkey/menu path. It was not used as pass evidence.
- The hover-scroll semantic is guarded by `Scripts/tag_navigation_hover_scroll_qa.sh`; a final human visual pass is still recommended before external distribution.
