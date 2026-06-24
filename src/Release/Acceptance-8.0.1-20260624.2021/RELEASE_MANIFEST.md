# TagLauncher 8.0.1 build20260624.2021 Release Manifest

## Scope

- Package type: acceptance candidate DMG for user validation.
- Version: `8.0.1`
- Build: `20260624.2021`
- Branch: `codex/dark-glass-8.0.0`
- Source commit: `c1d6cfc`
- CODEGRAPH check: checked and updated. `CODEGRAPH.md` records the 8.0 theme system, startup loading smoothing, and tag double-click settings QA entry.

## Changes

- App Grid theme system with 8 background themes.
- Edit mode temporarily renders with the default light App Grid regardless of selected theme.
- App Grid startup loading smoothing via last snapshot reuse and delayed spinner.
- Tag navigation double-click opens Preferences on the Tags tab.
- Single-click tag navigation, hover auto-scroll, and long-press tag reorder remain protected.

## Build Commands

```bash
bash src/Scripts/tag_double_click_preferences_qa.sh
bash src/Scripts/tag_navigation_hover_scroll_qa.sh
bash src/Scripts/theme_settings_qa.sh
bash src/Scripts/appgrid_startup_loading_qa.sh
bash src/Scripts/macos14_availability_typecheck_qa.sh
APP_BUILD=20260624.2021 bash ./build.sh
bash ./make_dmg.sh
mv build/TagLauncher.dmg build/TagLauncher-8.0.1-build20260624.2021.dmg
```

## Artifacts

- Build output DMG: `src/build/TagLauncher-8.0.1-build20260624.2021.dmg`
- Archived DMG: `src/Release/Acceptance-8.0.1-20260624.2021/Archive/TagLauncher-8.0.1-build20260624.2021.dmg`
- SHA256: `54d02e0f3f3baba359e6cf5a88e6d05522d9ac5c7a956ddce028c6c6b2773c55`
- Size: `5.8M`

## Verification

- `tag_double_click_preferences_qa.sh`: PASS.
- `tag_navigation_hover_scroll_qa.sh`: PASS.
- `theme_settings_qa.sh`: PASS.
- `appgrid_startup_loading_qa.sh`: PASS.
- `macos14_availability_typecheck_qa.sh`: PASS.
- `macos14_build_metadata_qa.sh`: PASS.
- Built app metadata: `8.0.1 (20260624.2021)`, minimum macOS `14.0`.
- `codesign --verify --deep --strict --verbose=2`: PASS.
- `hdiutil verify`: PASS.
- Mounted DMG contains `TagLauncher.app` and `Applications -> /Applications`: PASS.

## Notes

- DMG is ad-hoc signed for local acceptance validation, not an App Store upload package.
- User acceptance is still required before treating this as a frozen release package.
