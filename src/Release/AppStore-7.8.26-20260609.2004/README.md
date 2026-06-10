# TagLauncher 7.8.26 App Store Release Pack

This directory freezes TagLauncher `7.8.26` build `20260609.2004` for App Store upload.

## Frozen Source

- Branch: `codex/relocate-source-to-src`
- Source commit: `dd1c9fc4c531f1aceaa6d64bbee919ec464655b7`
- Release tag: `v7.8.26-build20260609.2004`

## Files

- `Upload/TagLauncher-7.8.26-build20260609.2004.pkg`: upload this to App Store Connect using Transporter.
- `Archive/TagLauncher-7.8.26-build20260609.2004.dmg`: local archive and manual install smoke-test package. Do not upload this to App Store Connect.
- `RELEASE_MANIFEST.md`: frozen source, commands, artifacts, and verification summary.
- `QA_RELEASE_EVIDENCE.md`: QA evidence and remaining manual smoke-test recommendations.
- `PKG_PREFLIGHT_REPORT.md`: expanded package preflight results.
- `APP_STORE_CONNECT_METADATA.md`: fields to copy into App Store Connect.
- `APP_STORE_RELEASE_CHECKLIST.md`: upload and post-upload checklist.
- `Review/APP_REVIEW_RESPONSE_AFTER_REJECTION.md`: review notes and Resolution Center reply draft.

## Upload

Upload:

```text
/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.8.26-20260609.2004/Upload/TagLauncher-7.8.26-build20260609.2004.pkg
```

After upload, wait for App Store Connect processing to finish, then select build `20260609.2004` on the `7.8.26` version page.
