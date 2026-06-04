# App Review Notes

TagLauncher is a macOS utility for organizing installed applications into visual tag groups and launching them from a keyboard-accessible app grid.

No demo account is required.

## Review Flow

1. Launch TagLauncher.
2. Press `Option-Shift-Space` to show the app grid.
3. Press `Space` while the app grid is visible to open Quick Search.
4. Type part of an installed app name to search.
5. Press `Escape` once to close Quick Search.
6. Press `Escape` again to close the app grid.
7. Open Settings from the menu bar or with `Command-Comma`.

## Expected Behavior

- The app scans installed applications locally to build the launcher index.
- The app grid intentionally appears above normal and fullscreen app windows.
- In fullscreen and Split View Spaces, AppGrid, Quick Search, and Settings should remain in the current Space instead of switching to another Space.
- While the app grid is visible, TagLauncher may hide the Dock depending on user settings and shows TagLauncher's menu bar.
- The system Force Quit window remains above TagLauncher.
- Import/export uses standard macOS file panels.
- In sandboxed App Store builds, login-at-launch may be disabled if the LaunchAgent approach is unavailable.

## 7.8.13 Specific Note

Version 7.8.13 improves discovery of newly installed applications. When App Grid or Quick Search opens, TagLauncher performs a lightweight signature check of standard application folders. If those folders changed, the local app index refreshes; if not, no full rescan is performed.
