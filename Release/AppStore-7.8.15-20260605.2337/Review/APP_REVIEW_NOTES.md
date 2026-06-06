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
7. Press `Option-Shift-Space` again — the app grid should show icons without staying on a loading spinner.
8. Open Settings from the menu bar or with `Command-Comma`.

## 7.8.15 Note

Version 7.8.15 fixes an issue where reopening the App Grid could remain on a loading spinner even though the local app index was already cached. Reviewers should verify step 7 above.

## 7.8.14 Note (still included)

Version 7.8.14 includes Apple system apps under `/System/Library/CoreServices/Applications` in the local app index. This lets users find Keychain Access by English name, localized name, or pinyin candidates.