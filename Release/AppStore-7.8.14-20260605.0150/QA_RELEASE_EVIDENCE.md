# QA Release Evidence

## Build Under Test

- Version: 7.8.14
- Build: 20260605.0150
- Source commit: 5194065f5cebfa847061c43cf2c568a1c91721ce
- Artifact: Archive/TagLauncher-7.8.14-build20260605.0150.dmg

## Passed

- Build completed with fixed build number.
- App signing verification passed.
- App version/build matched `7.8.14 / 20260605.0150`.
- DMG verification passed.
- DMG mount verification passed.
- Keychain targeted regression passed.
- Screenshot dimensions verified as `2880 x 1800`.
- `SHA256SUMS.txt` verified.

## Keychain Regression

Verified app:

- `/System/Library/CoreServices/Applications/Keychain Access.app`

Verified searchable candidates:

- `Keychain Access`
- `钥匙串访问`

Verified queries:

- `keychain`
- `钥匙串`
- `yaoshichuan`
- `ysc`

Result:

```text
PASS Keychain Access indexed search candidates: Keychain Access | 钥匙串访问 | 钥匙串访问 | 钥匙串访问
```
