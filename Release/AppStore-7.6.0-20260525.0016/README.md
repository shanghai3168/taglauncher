# TagLauncher Mac App Store Release Pack

This folder is the working release pack for the first Mac App Store submission of TagLauncher 7.6.0.

## Release Identity

- Product: TagLauncher
- Platform: macOS / Mac App Store
- Bundle ID: `com.taglauncher.app`
- Version: `7.6.0`
- Local QA build: `20260525.0016`
- Frozen source commit: `0258b3e`
- Frozen source branch: `main`
- Release folder: `Release/AppStore-7.6.0-20260525.0016`
- DMG SHA-256: `4689856f4a976c394ef4737db5bb5eebcc5b5bb95eea81fe72f5b6c3e3ed4b23`
- App binary SHA-256: `01ace57df10061fd7d684fa8a5bd795f87f55ee2c713cbb1ab2d01f5f63ed404`

## Freeze Status

This release pack is frozen on the locally QA-passed build `20260525.0016`. Use this folder, its hashes, and its metadata as the source of truth for the first Mac App Store submission prep.

Do not use earlier prep folders or builds such as `20260524.1652` or `20260524.1849`; they predate the final fullscreen/Split View secondary-window close and same-app Split View fixes.

## What Changed For This Release

- Fixed fullscreen Space behavior: the app grid now appears above the current fullscreen app instead of switching to another Space.
- Fixed repeated Dock icon creation when "Show in Dock" is enabled.
- Added a process singleton and `LSMultipleInstancesProhibited` guard.
- Made repeated show/focus requests idempotent instead of destroying and recreating the overlay.
- Removed the invalid all-spaces + move-to-active-space window behavior combination that caused the 07:23 crash.
- Removed the broken macOS system Help menu entry.
- Added an About-page Help PDF button that opens the online PDF matching the current app language, plus a copy-link button.
- Hardened fullscreen Space presentation so the app grid stays above the current fullscreen app instead of moving to another Space.
- Added Split View fullscreen detection so two apps sharing one fullscreen Space also keep the app grid on the current Space.
- Kept Quick Search and Settings inside the same fullscreen/Split View Space session instead of activating TagLauncher and sliding to another Space.
- Kept Settings close/refocus inside the same fullscreen/Split View Space session.
- Treated same-app two-window Split View as fullscreen Split View, not only two different apps.
- Expanded window QA to cover fullscreen Space behavior with Dock icon both enabled and disabled, including AppGrid, Quick Search, Settings, and stability checks.
- Strengthened the window logic QA script to cover fullscreen Space, duplicate Dock tiles, repeated self-launch, force quit layering, Settings/file panel layering, Quick Search, and two-display pointer-following behavior.

## Folder Contents

- `APP_STORE_ASSET_INVENTORY.md`: complete submission asset checklist and missing-item tracker.
- `FIRST_TIME_MAC_APP_STORE_TODO.md`: step-by-step checklist for a first Mac App Store submission.
- `APP_STORE_CONNECT_METADATA.md`: draft metadata, review notes, privacy answers, screenshot plan.
- `BUILD_SIGN_UPLOAD.md`: exact build/sign/upload path and current signing blockers.
- `QA_RELEASE_EVIDENCE.md`: local QA evidence and artifact hashes.
- `Screenshots/`: screenshot shot list, raw screenshot staging, and App Store-ready screenshot folder.
- `Legal/`: privacy policy drafts.
- `Support/`: support page draft and GitHub Pages publication guide.
- `Review/`: App Review notes draft.
- `Assets/`: app icon copy and other static submission assets.
- `Archive/`: local QA artifact archive.
- `Upload/`: placeholder for App Store-signed upload artifacts.
- `Submitted/`: placeholder for final submitted App Store Connect build records.

## Archived Old Release Pack

The previous App Store prep folder was moved to:

`Release/_archive/AppStore-7.6.0-a416923`

It was archived rather than deleted so old notes remain available if we need to compare decisions.

## Important Status

The local app and DMG build passed QA and signing verification for local distribution. This is not yet an App Store upload artifact because this Mac does not currently have:

- A `Mac App Distribution` signing certificate.
- A `Mac Installer Distribution` signing certificate.
- A Mac App Store provisioning profile for `com.taglauncher.app`.

Follow `BUILD_SIGN_UPLOAD.md` before uploading to App Store Connect.

## Apple References

- Add a new app: https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/
- Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Submit an app: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/
- App Sandbox: https://developer.apple.com/documentation/security/app_sandbox
- App privacy details: https://developer.apple.com/app-store/app-privacy-details/
- Screenshots: https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
- Pricing and availability: https://developer.apple.com/help/app-store-connect/reference/app-pricing-and-availability/
