# First-Time Mac App Store TODO

Use this as the working checklist when publishing TagLauncher from the Apple Developer account.

Frozen release pack:

- Version: `7.6.0`
- Local QA build: `20260524.1849`
- Source commit: `ba34712`
- Release folder: `Release/AppStore-7.6.0-20260524.1849`

## 0. Before Touching App Store Connect

- [ ] Confirm Apple Developer Program membership is active.
- [ ] Sign in to https://appstoreconnect.apple.com with Account Holder/Admin/App Manager access.
- [ ] Accept all pending agreements in App Store Connect Business.
- [ ] If the app will be paid, complete Paid Apps Agreement, tax, and banking.
- [ ] Decide release type: public App Store listing, not private/custom distribution.
- [ ] Decide release timing: manual release after approval is recommended for first launch.

## 1. App ID, Certificates, And Provisioning

- [ ] In Apple Developer Certificates, Identifiers & Profiles, create or confirm explicit App ID:
  - Bundle ID: `com.taglauncher.app`
  - Platform: macOS
- [ ] Confirm App Sandbox capability is enabled.
- [ ] Create/download `Mac App Distribution` certificate or use Xcode/cloud-managed signing.
- [ ] Create/download `Mac Installer Distribution` certificate if uploading a signed `.pkg`.
- [ ] Create/download a `Mac App Store Connect` provisioning profile for `com.taglauncher.app`.
- [ ] Install certificates and profile on the release Mac.
- [ ] Re-run `security find-identity -v -p codesigning` and verify the Mac App Store identities appear.

## 2. App Store Connect App Record

- [ ] Create a new app record.
- [ ] Platform: `macOS`.
- [ ] Name: `TagLauncher`.
- [ ] Primary language: choose `English (U.S.)` or `Simplified Chinese`.
- [ ] Bundle ID: `com.taglauncher.app`.
- [ ] SKU: `taglauncher-macos`.
- [ ] User Access: Full Access unless team access needs to be restricted.
- [ ] Category: Utilities.
- [ ] Add version `7.6.0`.

## 3. Product Page Metadata

- [ ] Fill app name, subtitle, description, keywords, support URL, privacy policy URL, copyright.
- [ ] Fill promotional text if desired.
- [ ] Complete age rating questionnaire.
- [ ] Complete content rights declaration.
- [ ] Complete encryption export compliance answer.
- [ ] Complete app privacy questionnaire.
- [ ] Add App Review contact information.
- [ ] Add App Review notes from `APP_STORE_CONNECT_METADATA.md`.

## 4. Screenshots

- [ ] Capture at least one required Mac screenshot.
- [ ] Recommended Mac screenshot size: `2880 x 1800`, `2560 x 1600`, `1440 x 900`, or `1280 x 800`.
- [ ] Include app grid.
- [ ] Include Quick Search.
- [ ] Include Settings.
- [ ] Optional: include multi-tag organization or import/export if it helps explain value.
- [ ] Verify screenshots contain no private user data.

## 5. Build And Upload

- [ ] Build the App Store-signed app using `BUILD_SIGN_UPLOAD.md`.
- [ ] Verify `CFBundleShortVersionString = 7.6.0`.
- [ ] Start from frozen local QA build `20260524.1849`; use a newer `CFBundleVersion` only if App Store upload retries require it.
- [ ] Increment `CFBundleVersion` for every upload attempt.
- [ ] Verify sandbox entitlements are present.
- [ ] Run `Scripts/window_logic_qa.sh` against the signed build before uploading.
- [ ] Upload with Transporter, Xcode Organizer, or `altool`.
- [ ] Wait for App Store Connect processing email.
- [ ] Attach the processed build to version `7.6.0`.

## 6. Submit For Review

- [ ] Check every App Store Connect section shows no missing required fields.
- [ ] Select release option: Manual release after approval.
- [ ] Add for Review.
- [ ] Submit for Review.
- [ ] Watch review status: Waiting for Review -> In Review -> Approved/Rejected.
- [ ] If rejected, save the reviewer message in this release folder before fixing.

## 7. After Approval

- [ ] Smoke-test approved build via TestFlight or App Store sandbox flow if available.
- [ ] Create a git tag for the exact submitted commit/build.
- [ ] Record final submitted build number and App Store Connect build ID.
- [ ] Release manually when ready.
- [ ] Archive final metadata, screenshots, and review notes under this release folder.
