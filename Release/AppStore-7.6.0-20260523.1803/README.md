# TagLauncher Mac App Store Release Pack

This folder is the working release pack for the first Mac App Store submission of TagLauncher 7.6.0.

## Release Identity

- Product: TagLauncher
- Platform: macOS / Mac App Store
- Bundle ID: `com.taglauncher.app`
- Version: `7.6.0`
- Local QA build: `20260523.1803`
- Source branch at preparation time: `main`
- Release folder: `Release/AppStore-7.6.0-20260523.1803`

## What Changed For This Release

- Fixed fullscreen Space behavior: the app grid now appears above the current fullscreen app instead of switching to another Space.
- Fixed repeated Dock icon creation when "Show in Dock" is enabled.
- Added a process singleton and `LSMultipleInstancesProhibited` guard.
- Made repeated show/focus requests idempotent instead of destroying and recreating the overlay.
- Removed the invalid all-spaces + move-to-active-space window behavior combination that caused the 07:23 crash.
- Removed the broken macOS system Help menu entry.
- Added an About-page Help PDF button that opens the online PDF matching the current app language, plus a copy-link button.
- Strengthened the window logic QA script to cover fullscreen Space, duplicate Dock tiles, repeated self-launch, force quit layering, Settings/file panel layering, Quick Search, and two-display pointer-following behavior.

## Folder Contents

- `FIRST_TIME_MAC_APP_STORE_TODO.md`: step-by-step checklist for a first Mac App Store submission.
- `APP_STORE_CONNECT_METADATA.md`: draft metadata, review notes, privacy answers, screenshot plan.
- `BUILD_SIGN_UPLOAD.md`: exact build/sign/upload path and current signing blockers.
- `QA_RELEASE_EVIDENCE.md`: local QA evidence and artifact hashes.

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
