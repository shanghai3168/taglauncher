# QA Release Evidence - TagLauncher 8.0.1 build20260624.2021

## Environment

- Date: 2026-06-24
- Branch: `codex/dark-glass-8.0.0`
- Source commit: `c1d6cfc`
- Version/build: `8.0.1 / 20260624.2021`
- SDK selected by scripts: `/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX27.0.sdk`

## Automated QA

| Check | Result |
| --- | --- |
| `bash src/Scripts/tag_double_click_preferences_qa.sh` | PASS |
| `bash src/Scripts/tag_navigation_hover_scroll_qa.sh` | PASS |
| `bash src/Scripts/theme_settings_qa.sh` | PASS |
| `bash src/Scripts/appgrid_startup_loading_qa.sh` | PASS |
| `bash src/Scripts/macos14_availability_typecheck_qa.sh` | PASS |
| `bash src/Scripts/macos14_build_metadata_qa.sh` | PASS |

## Package Verification

| Check | Result |
| --- | --- |
| Built app metadata | `8.0.1 (20260624.2021)`, `LSMinimumSystemVersion=14.0` |
| `codesign --verify --deep --strict --verbose=2 src/build/TagLauncher.app` | PASS |
| `hdiutil verify src/build/TagLauncher-8.0.1-build20260624.2021.dmg` | PASS |
| DMG mount contents | `TagLauncher.app` and `Applications -> /Applications` present |
| Mounted app metadata | `8.0.1 (20260624.2021)` |
| SHA256 | `54d02e0f3f3baba359e6cf5a88e6d05522d9ac5c7a956ddce028c6c6b2773c55` |

## Acceptance Focus

- Confirm App Grid theme switching still works.
- Confirm entering edit mode always uses the default light App Grid and exits back to the selected theme.
- Confirm repeated App Grid opening no longer immediately shows a visible spinner in common warm-cache paths.
- Confirm double-clicking a tag opens Preferences and lands on the Tags tab.
- Confirm single-click tag navigation, tag hover auto-scroll, and long-press reorder still behave normally.
