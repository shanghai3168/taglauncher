# TagLauncher 7.8.26 QA Release Evidence

Generated: 2026-06-09 22:06 HKT

## Target

- Version: 7.8.26
- Build: 20260609.2004
- Bundle ID: com.taglauncher.app
- Source commit: dd1c9fc4c531f1aceaa6d64bbee919ec464655b7
- Branch: codex/relocate-source-to-src

## Automated QA

| Check | Result |
| --- | --- |
| `bash Scripts/apple_default_apps_resource_qa.sh` | PASS |
| `bash Scripts/apple_default_note_policy_qa.sh` | PASS |
| `bash Scripts/smartstart_catalog_resource_qa.sh` | PASS |
| `Scripts/quick_search_app_name_qa.sh` | PASS |
| `Scripts/quick_search_system_app_qa.sh` | PASS |
| `APP_BUILD=20260609.2004 bash build.sh` | PASS |
| `bash make_dmg.sh` | PASS |
| `hdiutil verify build/TagLauncher-7.8.26-build20260609.2004.dmg` | PASS |

Notes:

- Quick Search QA initially failed inside the managed sandbox because Swift could not write to `~/.cache/clang/ModuleCache`. The same scripts passed after rerunning in the authorized environment.
- `codesign --verify --deep --strict` on the App Store signed app reports `CSSMERR_TP_NOT_TRUSTED` locally. The same local trust display is present on the prior 7.8.24 App Store package; signed entitlements and Team ID were checked directly.

## User-Facing Regression Coverage

- Quick Search app-name fixture confirms the outer localized `贝锐向日葵被控` wrapper wins over nested `isunclient`.
- Quick Search system app fixture confirms localized system app search candidates still include Keychain Access / 钥匙串访问.
- Apple default app resources and SmartStart resources remain split and localized.
- The build keeps 7.8.24 first-run Smart Start App Grid stability changes.

## Artifacts

- Archive DMG: `Archive/TagLauncher-7.8.26-build20260609.2004.dmg`
- Upload PKG: `Upload/TagLauncher-7.8.26-build20260609.2004.pkg`
- DMG SHA256: `fbc96c0cd618830ddd62c02ba51f2fc5d9757c7e7aa0f1d44aefd8461ab87c3e`
- PKG SHA256: `b2a5059246aa076d41d40d3839eaa8535c90c437d7e2d4fcd5cbaa7592f7f6d3`

## Manual QA Still Recommended Before Upload

- Install from the archive DMG and launch once on the target Mac.
- Confirm the menu bar icon is visible if THAW or another menu-bar manager is not hiding it.
- Confirm first-run Smart Start OK leaves the App Grid visible.
- Confirm Quick Search no longer lists `isunclient` as a standalone app after a fresh launch.
