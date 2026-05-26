# App Store Asset Inventory

This release pack is frozen for TagLauncher `7.6.0` build `20260527.0124`.

Use this file as the submission asset checklist. Anything marked `Needs user input` must be completed before submitting in App Store Connect.

## Frozen Build

- Version: `7.6.0`
- Local QA build: `20260527.0124`
- Source ref: `appstore-7.6.0-20260527.0124`
- Local QA DMG: `Archive/TagLauncher-7.6.0-20260527.0124-local-QA.dmg`
- DMG SHA-256: `1952295e0169853c46572e6226c72adc43059cb20dd7ee9b161e28e42887f5a2`
- App binary SHA-256: `b31270ee22d8c4c74e85b00ea96d0c378e5762f41432b057b653896566ba2f62`

## Metadata

- Draft App Store metadata: `APP_STORE_CONNECT_METADATA.md`
- First-time submission checklist: `FIRST_TIME_MAC_APP_STORE_TODO.md`
- Build/sign/upload instructions: `BUILD_SIGN_UPLOAD.md`
- QA and release evidence: `QA_RELEASE_EVIDENCE.md`
- Changelog source: `../../CHANGELOG.md`

Status: ready as draft, but App Store Connect fields must still be reviewed manually.

## Screenshots

- Screenshot instructions: `Screenshots/SCREENSHOT_SHOT_LIST.md`
- Raw screenshot staging folder: `Screenshots/raw/`
- App Store-ready screenshot folder: `Screenshots/AppStore/`

Status: needs user screenshots.

Apple accepts one to ten screenshots for Mac apps. Mac screenshots must use a 16:10 size such as `2880 x 1800`, `2560 x 1600`, `1440 x 900`, or `1280 x 800`.

Recommended final screenshot count: 5.

## App Icon

- App icon source copy: `Assets/TagLauncher-AppIcon-1024.png`

Status: present.

## Legal And URLs

- Privacy policy draft: `Legal/PRIVACY_POLICY.md`
- Simplified Chinese privacy policy draft: `Legal/PRIVACY_POLICY.zh-Hans.md`
- Support page draft: `Support/SUPPORT.md`
- Public URL publication guide: `Support/GITHUB_PAGES_PUBLICATION_GUIDE.md`

Status: content drafted; needs user identity/contact fields and public URLs.

Needs user input:

- Developer or company display name.
- Support email.
- Privacy contact email, if different.
- Public privacy policy URL.
- Public support URL.
- Copyright holder.

## App Review

- App Review notes draft: `Review/APP_REVIEW_NOTES.md`
- Manual QA notes area: `Review/`

Status: ready as draft.

## Upload Artifacts

- App Store upload staging folder: `Upload/`
- Submitted artifact archive folder: `Submitted/`

Status: waiting for App Store signing assets and final uploaded build.

The local DMG is not an App Store upload artifact. App Store upload still requires Mac App Distribution signing, Mac Installer Distribution signing if packaging a `.pkg`, and a Mac App Store provisioning profile for `com.taglauncher.app`.
