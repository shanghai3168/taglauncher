# TagLauncher 7.8.15 App Store `.pkg` 预检报告

生成日期：2026-06-07

上传包：

`Release/AppStore-7.8.15-20260605.2337/Upload/TagLauncher-7.8.15-build20260605.2337.pkg`

SHA256：

`a4e3a3002262ff27a2c9333f745fe1b99bff83eac610f022405c4dcce958b17b`

## Build Inputs

| 项目 | 值 |
| --- | --- |
| Version | `7.8.15` |
| Build | `20260605.2337` |
| Bundle ID | `com.taglauncher.app` |
| Team ID | `CR3J54M8BQ` |
| Minimum macOS | `15.0` |
| Category | `public.app-category.utilities` |
| App signing identity | `0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C` |
| Installer signing identity | `3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)` |
| Provisioning profile | `TagLauncher Mac App Store 20260605.2337` |
| Profile expiration | `2027-06-04 13:48:21 +0000` |

## Verification

| 检查项 | 结果 |
| --- | --- |
| `.pkg` 文件生成 | PASS |
| `.pkg` Installer 证书签名 | PASS |
| 展开最终 `.pkg` 并找到 `TagLauncher.app` | PASS |
| Bundle ID | PASS: `com.taglauncher.app` |
| `CFBundleShortVersionString` | PASS: `7.8.15` |
| `CFBundleVersion` | PASS: `20260605.2337` |
| `LSMinimumSystemVersion` | PASS: `15.0` |
| `LSApplicationCategoryType` | PASS: `public.app-category.utilities` |
| 嵌入 `embedded.provisionprofile` | PASS |
| Profile `com.apple.application-identifier` | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed `com.apple.application-identifier` | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed `com.apple.developer.team-identifier` | PASS: `CR3J54M8BQ` |
| Signed sandbox entitlement | PASS: `com.apple.security.app-sandbox = true` |
| Signed user-selected file entitlement | PASS: `com.apple.security.files.user-selected.read-write = true` |
| Code signature strict verification | PASS |
| Expanded package has `com.apple.quarantine` | PASS: no quarantine found |
| Package payload AppleDouble `._*` entries | NOTE: 73 entries, caused by macOS `com.apple.provenance`, not quarantine |
| Executable architecture | NOTE: `arm64` only |

## Important Notes

- This is an App Store upload package. Upload this `.pkg`, not the `.dmg` in `Archive/`.
- The package is signed with the Mac App Store Installer certificate, so local `spctl` may report `rejected`; that is expected for non-Developer-ID App Store packages and is not the same as App Store Connect validation.
- `pkgutil --payload-files` lists AppleDouble `._*` entries. The expanded package was inspected directly: no `com.apple.quarantine` attribute was found. This matches the PrivateVoice lesson that provenance AppleDouble entries must not be mistaken for the `91109` quarantine blocker.
- The app binary is `arm64` only because the current TagLauncher build script targets `arm64-apple-macosx15.0`. If Intel Mac support is required, build a universal package before upload. If Apple Silicon only is acceptable, continue with this package.

## Next Upload Step

Use Transporter and select:

`/Users/ar/Projects/Taglauncher-7.8.15-source/Release/AppStore-7.8.15-20260605.2337/Upload/TagLauncher-7.8.15-build20260605.2337.pkg`

After upload:

1. Wait for App Store Connect Processing to finish.
2. In the `7.8.15` version page, select build `20260605.2337`.
3. Fill the app metadata using `APP_STORE_CONNECT_FILLING_BILINGUAL.md`.
