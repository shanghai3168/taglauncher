# Build, Sign, And Upload Notes

## Current Local Build

The local QA build is suitable for verification and direct local testing, but it is not an App Store upload artifact.

- Local build command: `bash build.sh`
- Local DMG command: `bash make_dmg.sh`
- App path: `build/TagLauncher.app`
- DMG path: `build/TagLauncher.dmg`
- Local signing: ad-hoc unless `CODESIGN_IDENTITY` is provided.

## Current Signing Inventory

Current `security find-identity -v -p codesigning` only reports:

- `VoiceSnap Local Code Signing`

Missing for App Store upload:

- `Mac App Distribution`
- `Mac Installer Distribution`
- Mac App Store provisioning profile for `com.taglauncher.app`

## Sandbox Status

`Apptag/TagLauncher.entitlements` currently includes:

- `com.apple.security.app-sandbox = true`
- `com.apple.security.files.user-selected.read-write = true`

Apple requires App Sandbox for Mac App Store distribution.

## Recommended Upload Path

The safest first submission path is:

1. Install Mac App Store signing assets from the Apple Developer account.
2. Build with sandbox entitlements and App Store distribution signing.
3. Package as an App Store-ready upload through Xcode Organizer, Transporter, or `altool`.
4. Upload to App Store Connect.
5. Wait for processing, then attach the processed build to version `7.6.0`.

## Manual CLI Shape

Exact commands depend on the installed certificate/profile names. After installing the correct identities, the shape is:

```bash
cd /Users/ar/Projects/Taglauncher

APP_STORE=1 \
CODESIGN_IDENTITY="3rd Party Mac Developer Application: <TEAM NAME> (<TEAMID>)" \
APP_BUILD=20260524.1849 \
bash build.sh

productbuild \
  --component build/TagLauncher.app /Applications \
  --sign "3rd Party Mac Developer Installer: <TEAM NAME> (<TEAMID>)" \
  build/TagLauncher-AppStore.pkg

xcrun altool --upload-app \
  --type macos \
  --file build/TagLauncher-AppStore.pkg \
  --username "<APPLE_ID>" \
  --password "<APP_SPECIFIC_PASSWORD>"
```

Notes:

- Newer accounts may show certificate names as `Apple Distribution` / `Mac Installer Distribution`; use the exact identity shown by `security find-identity`.
- If using Xcode-managed/cloud-managed signing, prefer Xcode/Transporter over hand-written signing commands.
- Increment `APP_BUILD` for every failed upload retry.
- Keep the direct-distribution DMG separate from App Store upload packages.

## Pre-Upload Verification

Run these before uploading:

```bash
codesign --verify --deep --strict --verbose=2 build/TagLauncher.app
codesign -d --entitlements :- build/TagLauncher.app
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
CLICK_TOOL=/opt/homebrew/bin/cliclick bash Scripts/window_logic_qa.sh
```

## App Store-Specific Risks To Re-Test

- Sandbox behavior for scanning installed apps.
- Sandbox behavior for launching apps via `NSWorkspace`.
- Import/export file access with user-selected file entitlement.
- Global hotkey behavior.
- Fullscreen Space overlay behavior.
- Login-at-launch setting: current code disables LaunchAgent support in sandboxed builds.
