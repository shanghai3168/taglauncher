# Release Manifest

## Version

- Product: TagLauncher
- Version: 7.8.30
- Build: 20260611.1858
- Minimum macOS: 14.0
- Architecture: arm64
- Branch: `codex/macos14-compatibility`
- Source tag: `v7.8.30-build20260611.1858`
- Source commit: `2774b3e Add uncategorized layout reset option`

## Artifact

- `Archive/TagLauncher-7.8.30-build20260611.1858.dmg`

## Checksum

```text
15de0d93d93e897690cc146fc058035daa72d06708cc31a6d74409537441ab78  Archive/TagLauncher-7.8.30-build20260611.1858.dmg
```

## Build And Verification

- Build command: `APP_BUILD=20260611.1858 bash build.sh`
- DMG command: `bash make_dmg.sh`
- DMG verification: `hdiutil verify src/build/TagLauncher-7.8.30-build20260611.1858.dmg`
- App signature verification: `/usr/bin/codesign --verify --deep --strict --verbose=2 src/build/TagLauncher.app`
- `com.apple.quarantine`: absent
