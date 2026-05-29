# TagLauncher Mac App Store Release Pack

This folder is the working release pack for the first Mac App Store submission of TagLauncher 7.8.1.

## Release Identity

- Product: TagLauncher
- Platform: macOS / Mac App Store
- Bundle ID: `com.taglauncher.app`
- Version: `7.8.1`
- Local QA build: `20260529.1235`
- Source ref: `appstore-7.8.1-20260529.1235`
- Source branch: `codex/post-freeze-new-requirement`
- Release folder: `Release/AppStore-7.8.1-20260529.1235`
- DMG SHA-256: `72b62d28529ee41e4ae22c972ab14b81b93788d011f0e64df6e941b39a50c1a3`
- App binary SHA-256: `ad08345b3ab64fa85dc6025e076721dc8f6713f17c96e21f08dd0a86436636f4`

## Freeze Status

This release pack freezes TagLauncher `7.8.1` build `20260529.1235` for Mac App Store submission prep. Use the hashes above for the frozen local QA package.

Do not use earlier prep folders or builds such as `20260524.1652`, `20260524.1849`, or the previous `7.6.0` prep package; they predate the final AppKit, fullscreen/Split View, Quick Search, icon, and scroll stability fixes.

## What Changed For This Release

- Split the post-7.6 work into `7.7.0`, `7.8.0`, and `7.8.1` changelog entries.
- Completed AppKit-backed tag navigation, including drag reorder and stronger drag-lift visual feedback.
- Added confirmation and independent "don't remind me again" handling for removing tags by dragging apps out of groups or into Uncategorized.
- Fixed App icon transparency so rounded corners no longer show opaque white corners.
- AppKit-backed Quick Search result list and independent Quick Search panel are included.
- Overlay window management is consolidated in `OverlayWindowController`.
- App library scanning, Smart Start application, and Quick Search document preparation are consolidated in `AppLibraryController`.
- Hardened fullscreen and Split View presentation for AppGrid, Quick Search, Settings, file panels, and Force Quit layering.
- Fixed scroll-after-keyboard edge cases where `Space` or `Esc` could occasionally stop working after AppGrid scrolling.
- Reduced AppGrid scroll churn by avoiding repeated SwiftUI state writes during a scroll burst.
- New installs now default AppGrid icon size to `64`; existing user preferences are not overwritten.
- Expanded `Scripts/window_logic_qa.sh` to include repeated scroll -> Space -> Esc keyboard routing checks.

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

The previous App Store prep folder remains available at:

`Release/AppStore-7.6.0-20260527.0124`

It was retained rather than deleted so old notes remain available if we need to compare decisions.

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
