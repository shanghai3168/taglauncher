# QA And Release Evidence

## Local Build

- Version: `7.6.0`
- Build: `20260523.1803`
- App path: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG path: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- App executable size: `1.4M`
- DMG size: `5.7M`

## Hashes

```text
c848f902a8219547b59767b172d5b26453748e7f34ee1ce7d10c421fc61005de  build/TagLauncher.dmg
8a541e00734f0bd5f461b13881e194b29cb9c33b79fc0203cd59864680928d4e  build/TagLauncher.app/Contents/MacOS/TagLauncher
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

Covered checks:

- Repeated self-launch keeps exactly one process.
- Repeated self-launch keeps exactly one Dock tile.
- Fullscreen Space overlay appears above the current fullscreen app.
- App grid claims foreground, hides Dock, and keeps menu bar visible.
- Settings floats above app grid.
- File panel floats above Settings.
- Quick Search stays above app grid and supports two-Escape logic.
- Clicking outside Quick Search closes search, not app grid.
- System Force Quit window stays above TagLauncher.
- Two physical displays passed pointer-following frame checks.

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

- The broken macOS system Help menu entry was removed.
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
