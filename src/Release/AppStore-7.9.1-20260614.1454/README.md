# TagLauncher 7.9.1 App Store Release Pack

This directory freezes TagLauncher `7.9.1` build `20260614.1454` for App Store upload.

Version stays `7.9.1`; only `CFBundleVersion` was updated from the previous `20260613.2020` build.

## Upload Package

Upload this file with Transporter:

```text
/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.9.1-20260614.1454/Upload/TagLauncher-7.9.1-build20260614.1454.pkg
```

Do not upload the DMG in `Archive/`; the DMG is only for local rollback and smoke testing.

## Artifacts

- App Store upload pkg: `Upload/TagLauncher-7.9.1-build20260614.1454.pkg`
- Local archive DMG: `Archive/TagLauncher-7.9.1-build20260614.1454.dmg`
- Source commit: `bd792cd36d57b8f0741af9a6a64e59969cdce490`
- Release tag: `v7.9.1-build20260614.1454`

## Files

- `APP_STORE_CONNECT_METADATA.md`: App Store Connect fields and copy.
- `APP_STORE_RELEASE_CHECKLIST.md`: upload checklist.
- `APP_REVIEW_NOTES.md`: review notes for Apple.
- `PKG_PREFLIGHT_REPORT.md`: local package inspection report.
- `QA_RELEASE_EVIDENCE.md`: QA evidence.
- `RELEASE_MANIFEST.md`: reproducible release manifest.
