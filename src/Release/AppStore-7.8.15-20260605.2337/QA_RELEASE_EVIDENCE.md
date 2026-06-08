# QA Release Evidence

## Build Under Test

- Version: 7.8.15
- Build: 20260605.2337
- Source commit: ed43ee83789cb99b1cb95db340fee939dd0dedec
- Artifact: Archive/TagLauncher-7.8.15-build20260605.2337.dmg

## Passed

- Build completed with fixed build number `20260605.2337`.
- App signing verification passed.
- App version/build matched `7.8.15 / 20260605.2337`.
- DMG verification passed.
- DMG mount verification passed.
- Screenshot dimensions verified as `2880 x 1800` (assets reused from 7.8.14).
- `SHA256SUMS.txt` recorded.

## Manual QA Recommended Before Submit

- Open App Grid with `Option-Shift-Space`, press `Escape`, reopen App Grid — icons should appear without an endless spinner.
- Optional regression: `Scripts/quick_search_system_app_qa.sh` for Keychain Access indexing (carried from 7.8.14).

## App Grid Regression (7.8.15)

Expected:

1. Launch TagLauncher.
2. Press `Option-Shift-Space` — App Grid shows app icons.
3. Press `Escape` to close.
4. Press `Option-Shift-Space` again — App Grid shows icons immediately (no endless spinner).