# TagLauncher 7.8.26 App Store `.pkg` 预检报告

生成日期：2026-06-09

上传包：

`Release/AppStore-7.8.26-20260609.2004/Upload/TagLauncher-7.8.26-build20260609.2004.pkg`

SHA256：

`b2a5059246aa076d41d40d3839eaa8535c90c437d7e2d4fcd5cbaa7592f7f6d3`

## Build Inputs

| 项目 | 值 |
| --- | --- |
| Version | `7.8.26` |
| Build | `20260609.2004` |
| Bundle ID | `com.taglauncher.app` |
| Team ID | `CR3J54M8BQ` |
| Minimum macOS | `15.0` |
| Category | `public.app-category.utilities` |
| App signing identity | `0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C` |
| Installer signing identity | `3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)` |
| Provisioning profile | `TagLauncher Mac App Store 20260605.2337` |
| Profile UUID | `da7839d6-2489-4272-b999-c61efccfe473` |
| Profile expiration | `2027-06-04 13:48:21 UTC` |

## Verification

| 检查项 | 结果 |
| --- | --- |
| `.pkg` 文件生成 | PASS |
| `.pkg` Installer 证书签名 | PASS, local trust display is `signed by untrusted certificate`, same as 7.8.24 |
| 展开最终 `.pkg` 并找到 `TagLauncher.app` | PASS |
| Bundle ID | PASS: `com.taglauncher.app` |
| `CFBundleShortVersionString` | PASS: `7.8.26` |
| `CFBundleVersion` | PASS: `20260609.2004` |
| `LSMinimumSystemVersion` | PASS: `15.0` |
| `LSApplicationCategoryType` | PASS: `public.app-category.utilities` |
| 嵌入 `embedded.provisionprofile` | PASS |
| Profile `com.apple.application-identifier` | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed `com.apple.application-identifier` | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed `com.apple.developer.team-identifier` | PASS: `CR3J54M8BQ` |
| Signed sandbox entitlement | PASS: `com.apple.security.app-sandbox = true` |
| Signed user-selected file entitlement | PASS: `com.apple.security.files.user-selected.read-write = true` |
| Signed keychain access groups | PASS: `CR3J54M8BQ.*` |
| Expanded package has `com.apple.quarantine` | PASS: no quarantine found |
| Package payload AppleDouble `._*` entries | NOTE: 104 entries, caused by macOS package metadata/provenance, not quarantine |
| Executable architecture | NOTE: `arm64` only |

## Important Notes

- Upload the `.pkg` in `Upload/`, not the `.dmg` in `Archive/`.
- A first generated 7.8.26 pkg contained `com.apple.quarantine` on `embedded.provisionprofile`; it was rejected during local preflight, moved to `/private/tmp/taglauncher-appstore-7.8.26.NUeEB7/TagLauncher-7.8.26-build20260609.2004.quarantine-failed.pkg`, and not archived.
- The final package was regenerated after `xattr -cr` on the staged app, then re-signed and re-expanded for inspection.
- `pkgutil --check-signature` reports the App Store Installer certificate as locally untrusted; this matches the prior 7.8.24 package and is recorded as a local trust-chain display note.
- Use `codesign -d --entitlements - <app>` for entitlements inspection on this macOS toolchain.
- The final expanded package was inspected directly for `com.apple.quarantine`; none was found. AppleDouble `._*` payload entries are recorded as metadata/provenance notes, not the App Store `91109` quarantine blocker.

## Next Upload Step

Use Transporter and select:

`/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.8.26-20260609.2004/Upload/TagLauncher-7.8.26-build20260609.2004.pkg`
