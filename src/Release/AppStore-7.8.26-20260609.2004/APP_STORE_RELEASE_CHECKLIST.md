# App Store Release Checklist

Version: `7.8.26`

Build: `20260609.2004`

## Before Upload

- [x] Source commit frozen: `dd1c9fc4c531f1aceaa6d64bbee919ec464655b7`
- [x] Release directory created under `src/Release/AppStore-7.8.26-20260609.2004`
- [x] DMG generated and verified
- [x] App Store `.pkg` generated with Installer certificate
- [x] Final `.pkg` expanded and inspected
- [x] Bundle ID, version, build, category, and minimum macOS verified
- [x] Embedded provisioning profile verified
- [x] Signed entitlements verified
- [x] `com.apple.quarantine` absent from expanded package
- [x] SHA256 recorded
- [x] Release tag planned: `v7.8.26-build20260609.2004`

## Upload With Transporter

1. Open Transporter for macOS.
2. Add this package:

```text
/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.8.26-20260609.2004/Upload/TagLauncher-7.8.26-build20260609.2004.pkg
```

3. Deliver the package.
4. Wait for App Store Connect processing to finish.
5. In App Store Connect, open the TagLauncher macOS version page.
6. Select build `20260609.2004` for version `7.8.26`.
7. Fill metadata from `APP_STORE_CONNECT_METADATA.md`.
8. Fill review notes from `Review/APP_REVIEW_RESPONSE_AFTER_REJECTION.md`.
9. Submit for review.

## Do Not Upload

- Do not upload `Archive/TagLauncher-7.8.26-build20260609.2004.dmg`.
- Do not upload the quarantine-failed temporary package saved under `/private/tmp`.

## After Upload

- Record App Store Connect processing result.
- If Apple rejects the binary, do not reuse the same build number for a new package. Increment `CFBundleVersion` with a new `YYYYMMDD.HHMM` build.
- If Apple requests more information, use the prepared review response and existing public review video link.
