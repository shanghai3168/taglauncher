# QA And Release Evidence

## Local Build

- Version: `7.6.0`
- Build: `20260529.0153` icon cleanup copy
- Source ref: `codex/post-freeze-new-requirement` icon-resource hotfix
- App path: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG path: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- App executable size: `1.4M`
- DMG size: `5.7M`

2026-05-29 icon cleanup: the local QA DMG and App icon asset in this archived folder were refreshed so the project tree no longer contains stale icon packages. This archive is reference-only and should not be used for submission.

## Hashes

```text
a887c26943136c629bf36a577ded512f85a0aac8132622e2c418c4c6d2b870f7  build/TagLauncher.dmg
8e0fd85ee62b6791940ce32c220ca802a02f5e6f9d43a366f6d1f6b7bb53eb9a  build/TagLauncher.app/Contents/MacOS/TagLauncher
```

## Commands Run

```bash
bash build.sh
bash make_dmg.sh
CLICK_TOOL=/opt/homebrew/bin/cliclick bash Scripts/window_logic_qa.sh
codesign --verify --deep --strict --verbose=2 build/TagLauncher.app
strings build/TagLauncher.app/Contents/MacOS/TagLauncher | rg "Taglauncher-help-|TagLauncherLocalizedHelpMenuItem|raw.githubusercontent|Ariver"
hdiutil verify build/TagLauncher.dmg
```

## Window Logic QA Result

Final QA result:

```text
ALL WINDOW LOGIC QA PASSED
```

This is the frozen QA result for build `20260525.0016`. Earlier builds `20260524.1652` and `20260524.1849` should not be used for App Store prep because they did not include the final fullscreen/Split View Quick Search, Settings close/refocus, and same-app Split View fixes.

Covered checks:

- Repeated self-launch keeps exactly one process.
- Repeated self-launch keeps exactly one Dock tile.
- Fullscreen Space overlay appears above the current fullscreen app.
- Fullscreen Space overlay is checked with `showDockIcon=true` and `showDockIcon=false`.
- Fullscreen Space overlay bounds must match the fullscreen target display and remain stable across repeated samples.
- Fullscreen Space Quick Search opens from app grid without switching away from the current fullscreen app.
- Fullscreen Space Settings opens from app grid without switching away from the current fullscreen app.
- Closing Settings in a fullscreen/Split View overlay session does not reactivate TagLauncher into another Space.
- Split View fullscreen geometry is checked for 50/50 and 33/67 split layouts, while ordinary side-by-side desktop windows are rejected.
- Same-app two-window Split View geometry follows the same fullscreen Split View path as two-app Split View.
- App grid claims foreground, hides Dock, and keeps menu bar visible.
- Settings floats above app grid.
- File panel floats above Settings.
- Quick Search stays above app grid and supports two-Escape logic.
- Clicking outside Quick Search closes search, not app grid.
- System Force Quit window stays above TagLauncher.
- Pointer-following logic was checked on two displays; AppGrid followed the pointer on each screen.

## Crash Check

After the fix and QA run, no newer TagLauncher crash report appeared. The latest crash report remained the known pre-fix crash:

```text
TagLauncher-2026-05-23-072321.ips
```

Root cause of that crash:

```text
NSWindow _validateCollectionBehavior:
```

The invalid overlay collection behavior was removed.

## DMG Verification

```text
hdiutil: verify: checksum of "/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg" is VALID
```

## Help PDF Verification

- The broken macOS Help Book binding was removed.
- The standard menu bar now has a localized Help menu with a single `Download Help PDF` item.
- The About page includes an `Open Help PDF` button and a copy-link button.
- The app binary contains the immutable GitHub Release Help PDF URL shape.
- The app binary no longer contains the old `raw.githubusercontent` Help URL or `TagLauncherLocalizedHelpMenuItem`.
- The public GitHub Release assets for all 29 Help PDFs returned HTTP `200`.

## Code Signing Verification

```text
/Users/ar/Projects/Taglauncher/build/TagLauncher.app: valid on disk
/Users/ar/Projects/Taglauncher/build/TagLauncher.app: satisfies its Designated Requirement
```

This verification is for the local ad-hoc signed QA build. App Store upload still needs App Store distribution signing.
