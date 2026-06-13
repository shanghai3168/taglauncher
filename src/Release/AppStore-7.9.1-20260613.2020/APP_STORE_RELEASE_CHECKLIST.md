# App Store Release Checklist

Version: `7.9.1`

Build: `20260613.2020`

## Before Upload

- [x] Source commit frozen: `ed4ebcfa763f66ecd69cae57df2c949a7a9a8a45`
- [x] Release directory created under `src/Release/AppStore-7.9.1-20260613.2020`
- [x] DMG generated and verified
- [x] App Store `.pkg` generated with Installer certificate
- [x] Final `.pkg` expanded and inspected
- [x] Bundle ID, version, build, category, and minimum macOS verified
- [x] Embedded provisioning profile verified
- [x] Signed entitlements verified
- [x] `com.apple.quarantine` absent from expanded package
- [x] SHA256 recorded
- [x] Release tag created: `v7.9.1-build20260613.2020`

## Upload With Transporter

1. Open Transporter for macOS.
2. Add this package:

```text
/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.9.1-20260613.2020/Upload/TagLauncher-7.9.1-build20260613.2020.pkg
```

3. Deliver the package.
4. Wait for App Store Connect processing to finish.
5. In App Store Connect, open the TagLauncher macOS version page.
6. Select build `20260613.2020` for version `7.9.1`.
7. Fill metadata from `APP_STORE_CONNECT_METADATA.md`.
8. Fill review notes from `APP_REVIEW_NOTES.md`.
9. Submit for review.

## Do Not Upload

- Do not upload `Archive/TagLauncher-7.9.1-build20260613.2020.dmg`.
- Do not upload any temporary package under `/private/tmp` or `/var/folders`.

## After Upload

- Record App Store Connect processing result.
- If Apple rejects the binary, do not reuse the same build number for a new package. Increment `CFBundleVersion` with a new `YYYYMMDD.HHMM` build.
