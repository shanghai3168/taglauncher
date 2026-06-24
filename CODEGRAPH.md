# CODEGRAPH

## Stable Modules

- App entry and overlay state: `src/Apptag/ContentView.swift`
  - Reads user defaults for AppGrid display, theme, tag navigation, usage tips, and hotkeys.
  - Owns the AppGrid full-window background rendering.
  - Reuses the last complete AppLibrary snapshot before showing startup loading UI.
  - Calls `AppGridCollectionView` for AppKit grid rendering.

- App library snapshot assembly: `src/Apptag/AppLibraryController.swift`
  - Scans apps, reconciles tags, runs SmartStart when needed, and assembles AppGrid/Quick Search snapshots.
  - Keeps the most recent in-process `AppLibrarySnapshot` so newly-created overlay views can render immediately while background refresh catches up.

- AppGrid collection renderer: `src/Apptag/AppGridCollectionView.swift`
  - AppKit `NSCollectionView` implementation for grouped app layout, drag/drop, app ordering, bubbles, and usage tips overlay.
  - Should not own full-screen AppGrid theme gradients; it receives theme only for derived glass readability.

- AppGrid theme model: `src/Apptag/AppGridTheme.swift`
  - Central source for theme IDs, localization keys, preview swatches, full-screen background gradients, derived glass tone, and edit-mode contrast tokens.
  - Persistent key: `appGridThemeID`.

- Settings surface: `src/Apptag/PreferencesView.swift`
  - Custom SwiftUI settings tabs.
  - Theme tab writes only `appGridThemeID`; it must not mutate tags, app ordering, or category data.
  - Can be opened with an initial target tab from AppKit/overlay notifications.

- Defaults and migrations: `src/Apptag/AppDefaults.swift`
  - Registers first-run defaults.
  - Migrates legacy `useDarkAppGrid=true` to `appGridThemeID=deepBlue` when no new theme key exists.

- Localization: `src/Apptag/Localization/*.json`
  - 29 language JSON files.
  - New user-visible settings keys must be present in all files.

## QA Entrypoints

- `src/Scripts/theme_settings_qa.sh`
  - Verifies 8 theme cases, Theme tab, legacy dark-grid UI removal, AppGrid-only rendering boundary, edit-mode default-theme override, migration path, and 29-language keys.
- `src/Scripts/appgrid_startup_loading_qa.sh`
  - Verifies AppGrid startup loading uses last-snapshot reuse and delayed spinner instead of immediately exposing empty-state loading.
- `src/Scripts/macos14_availability_typecheck_qa.sh`
  - Typechecks for macOS 14.0 compatibility.
- `src/Scripts/macos14_build_metadata_qa.sh`
  - Verifies build metadata and deployment target.
- `src/Scripts/usage_tips_qa.sh`
  - Verifies usage tips overlay and 29-language coverage.
- `src/Scripts/tag_navigation_hover_scroll_qa.sh`
  - Verifies tag hover scroll semantics remain guarded.
- `src/Scripts/tag_double_click_preferences_qa.sh`
  - Verifies double-clicking a tag navigation item opens Preferences on the Tags tab while preserving single-click activation, hover scroll, and long-press reorder wiring.

## Protected Behavior

- Theme changes are visual preferences and must not change tag data, app ordering, notes, SmartStart/category scheme, quick search, drag/drop behavior, or import/export data.
- AppGrid startup and repeated overlay creation must not immediately show a spinner just because a new `ContentView` starts with `allApps.isEmpty`; it should first reuse the last complete in-process snapshot and only show loading after a short delay if no snapshot is available.
- Editing mode uses a temporary runtime theme override: regardless of the stored `appGridThemeID`, editing renders as the default light glass AppGrid and restores the stored theme when edit mode exits.
- Individual AppGrid containers must remain a consistent translucent glass surface. They may use a derived light/dark glass tone for readability, but must not receive per-theme internal gradients.
- Edit mode controls must use the runtime rendered theme, not the stored theme, so editing stays visually identical to the default light AppGrid.
- Deep Blue and Black use dark glass. Bright Pink, Purple, Green, Blue, and Colorful themes use light glass to keep the theme bright and readable.
- The default theme preserves the original light AppGrid background.
- Legacy users with `useDarkAppGrid=true` must land on the `deepBlue` theme.
- Tag navigation single-click must keep immediate scroll behavior. Hover must keep guarded auto-scroll. Long-press must keep tag reorder behavior. Double-click may open Preferences on the Tags tab but must not replace those existing behaviors.

Last updated: 2026-06-24, tag double-click opens Tags settings.
