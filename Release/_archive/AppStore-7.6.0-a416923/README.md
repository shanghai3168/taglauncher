# TagLauncher App Store Release Prep

This folder is the clean App Store preparation workspace for the locked QA-passed build.

## Locked Baseline

- Branch: `main`
- Commit: `a416923`
- Tag: `qa-passed-7.6.0-20260523`
- App version: `7.6.0`
- Build: `20260523.0303`
- QA script: `Scripts/window_logic_qa.sh`
- QA result: `ALL WINDOW LOGIC QA PASSED`

## Local Artifacts

- App: `/Users/ar/Projects/Taglauncher/build/TagLauncher.app`
- DMG: `/Users/ar/Projects/Taglauncher/build/TagLauncher.dmg`
- App size: `7.1M`
- DMG size: `5.6M`
- DMG SHA-256: `1bb9a25c911fc167da6e19b8d483bec9082f73ad2aefa73c1ce5efcdb55ad789`
- Executable SHA-256: `a89f8b3ed4c1ad80202a97f65934f7a5f9e8b5c578e7340bf06d59196e509389`

Note: the current local artifact is ad-hoc signed. App Store submission still needs App Store signing, sandbox entitlements, and an uploadable App Store build.

## Cleanup Done

- Removed old untracked prep material at `Doc/Taglauncher-help`.
- Started App Store prep from the locked commit above.

## Main Checklist

Use [APP_STORE_TODO.md](APP_STORE_TODO.md) as the working checklist.

## Apple References

- [App Store Connect workflow](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-workflow/)
- [Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)
- [Required, localizable, and editable properties](https://developer.apple.com/help/app-store-connect/reference/required-localizable-and-editable-properties/)
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)
- [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox)
- [App Sandbox information](https://developer.apple.com/help/app-store-connect/reference/app-uploads/app-sandbox-information/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Upload app previews and screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/)
