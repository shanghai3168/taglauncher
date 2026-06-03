# App Review Notes

Use this text as the starting point for App Review notes in App Store Connect.

## Review Notes Draft

TagLauncher is a macOS utility for organizing installed applications into visual tag groups and launching them from a keyboard-accessible app grid.

Primary review flow:

1. Launch TagLauncher.
2. Press `Option-Shift-Space` to show the app grid.
3. Press `Space` while the app grid is visible to open Quick Search.
4. Press `Escape` once to close Quick Search.
5. Press `Escape` again to close the app grid.
6. Open Settings from the menu bar or with `Command-Comma`.

Expected behavior:

- The app grid intentionally appears above normal and fullscreen app windows.
- In fullscreen and Split View Spaces, AppGrid, Quick Search, and Settings should remain in the current Space instead of switching to another Space.
- While the app grid is visible, TagLauncher may hide the Dock depending on user settings and shows TagLauncher's menu bar.
- The system Force Quit window remains above TagLauncher.
- Import/export uses standard macOS file panels.
- In sandboxed App Store builds, login-at-launch may be disabled if the LaunchAgent approach is unavailable.

No demo account is required.

## Local QA Evidence

- QA evidence file: `QA_RELEASE_EVIDENCE.md`
- Final freeze: `7.8.12 / 20260604.0105`
- Frozen source commit: `be83948fab7b643634ede2403abdca27e6b45f29`
- Frozen tag: `v7.8.12-build20260604.0105`
- Full window behavior QA passed on the release line, including fullscreen/Split View, Quick Search, Settings, file panels, Force Quit layering, screen following, and scroll-after-keyboard routing.
