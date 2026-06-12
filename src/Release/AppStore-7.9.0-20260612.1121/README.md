# TagLauncher 7.9.0 App Store Release Pack

This directory freezes TagLauncher `7.9.0` build `20260612.1121` for App Store upload.

## Upload Package

Upload this file with Transporter:

```text
/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.9.0-20260612.1121/Upload/TagLauncher-7.9.0-build20260612.1121.pkg
```

Do not upload the DMG in `Archive/`; the DMG is only for local rollback and smoke testing.

## Artifacts

- App Store upload pkg: `Upload/TagLauncher-7.9.0-build20260612.1121.pkg`
- Local archive DMG: `Archive/TagLauncher-7.9.0-build20260612.1121.dmg`
- Source commit: `cc75eee3160d200410dd84e5361dc11af7f01baa`
- Release tag: `v7.9.0-build20260612.1121`

## Files

- `APP_STORE_CONNECT_METADATA.md`: App Store Connect fields and copy.
- `APP_STORE_RELEASE_CHECKLIST.md`: upload checklist.
- `APP_REVIEW_NOTES.md`: review notes for Apple.
- `PKG_PREFLIGHT_REPORT.md`: local package inspection report.
- `QA_RELEASE_EVIDENCE.md`: QA evidence.
- `RELEASE_MANIFEST.md`: reproducible release manifest.
