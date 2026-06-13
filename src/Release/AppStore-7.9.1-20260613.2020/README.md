# TagLauncher 7.9.1 App Store Release Pack

This directory freezes TagLauncher `7.9.1` build `20260613.2020` for App Store upload.

## Upload Package

Upload this file with Transporter:

```text
/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.9.1-20260613.2020/Upload/TagLauncher-7.9.1-build20260613.2020.pkg
```

Do not upload the DMG in `Archive/`; the DMG is only for local rollback and smoke testing.

## Artifacts

- App Store upload pkg: `Upload/TagLauncher-7.9.1-build20260613.2020.pkg`
- Local archive DMG: `Archive/TagLauncher-7.9.1-build20260613.2020.dmg`
- Source commit: `ed4ebcfa763f66ecd69cae57df2c949a7a9a8a45`
- Release tag: `v7.9.1-build20260613.2020`

## Files

- `APP_STORE_CONNECT_METADATA.md`: App Store Connect fields and copy.
- `APP_STORE_RELEASE_CHECKLIST.md`: upload checklist.
- `APP_REVIEW_NOTES.md`: review notes for Apple.
- `PKG_PREFLIGHT_REPORT.md`: local package inspection report.
- `QA_RELEASE_EVIDENCE.md`: QA evidence.
- `RELEASE_MANIFEST.md`: reproducible release manifest.
