# QA And Release Evidence

## Local Build

- Version: `7.6.0`
- Build: `20260524.1652`
- App path: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG path: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- App executable size: `1.4M`
- DMG size: `5.7M`

## Hashes

```text
1bf3e53410e18778038c310e1ed083cd89c27b781cc87942dd3dd9fb57d73cb2  build/TagLauncher.dmg
13e74a774662dfec88e69b5f51e5c51c5c46e3e5f8884cbf8cbab5cd44c4442d  build/TagLauncher.app/Contents/MacOS/TagLauncher
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
- Fullscreen Space overlay is checked with `showDockIcon=true` and `showDockIcon=false`.
- Fullscreen Space overlay bounds must match the fullscreen target display and remain stable across repeated samples.
- Split View fullscreen geometry is checked for 50/50 and 33/67 split layouts, while ordinary side-by-side desktop windows are rejected.
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
