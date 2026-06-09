# TagLauncher 7.8.24 App Store `.pkg` 预检报告

生成日期：2026-06-09

上传包：

`Release/AppStore-7.8.24-20260609.1221/Upload/TagLauncher-7.8.24-build20260609.1221.pkg`

SHA256：

`23e9c87db6560fa06c572f6b8353eb74f32f1c4453e87b78ba01f1f6b62c633f`

## Build Inputs

| 项目 | 值 |
| --- | --- |
| Version | `7.8.24` |
| Build | `20260609.1221` |
| Bundle ID | `com.taglauncher.app` |
| Team ID | `CR3J54M8BQ` |
| Minimum macOS | `15.0` |
| Category | `public.app-category.utilities` |
| App signing identity | `0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C` |
| Installer signing identity | `3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)` |
| Provisioning profile | `TagLauncher Mac App Store 20260605.2337` |
| Profile expiration | `2027-06-04 21:48:21 HKT` |

## Verification

| 检查项 | 结果 |
| --- | --- |
| `.pkg` 文件生成 | PASS |
| `.pkg` Installer 证书签名 | PASS |
| 展开最终 `.pkg` 并找到 `TagLauncher.app` | PASS |
| Bundle ID | PASS: `com.taglauncher.app` |
| `CFBundleShortVersionString` | PASS: `7.8.24` |
| `CFBundleVersion` | PASS: `20260609.1221` |
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
- `pkgutil --check-signature` reports the App Store Installer certificate as locally untrusted; this is expected for this App Store packaging path and is not the same as App Store Connect validation.
- Use `codesign -d --entitlements - <app>` for entitlements inspection on this macOS toolchain. The deprecated `:-` form can print a misleading invalid-entitlements warning.
- The final expanded package was inspected directly for `com.apple.quarantine`; none was found. AppleDouble `._*` payload entries are recorded as metadata/provenance notes, not the App Store `91109` quarantine blocker.

## Next Upload Step

Use Transporter and select:

`/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.8.24-20260609.1221/Upload/TagLauncher-7.8.24-build20260609.1221.pkg`
