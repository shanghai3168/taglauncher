# TagLauncher 7.9.1 App Store `.pkg` 预检报告

生成日期：2026-06-14

上传包：

`Release/AppStore-7.9.1-20260614.1454/Upload/TagLauncher-7.9.1-build20260614.1454.pkg`

SHA256：

`7ad097a23c736fc7a7b34a9575348cbc52a968d5fbf433584ace353b120a32ef`

## Build Inputs

| 项目 | 值 |
| --- | --- |
| Version | `7.9.1` |
| Build | `20260614.1454` |
| Bundle ID | `com.taglauncher.app` |
| Team ID | `CR3J54M8BQ` |
| Minimum macOS | `14.0` |
| Category | `public.app-category.utilities` |
| App signing identity | `0D7D5484FDE4EC1CA2C9225F1E71E65A256A1E7C` |
| Installer signing identity | `3rd Party Mac Developer Installer: Hainan Wanxing Technology Co., Ltd. (CR3J54M8BQ)` |
| Provisioning profile | `TagLauncher Mac App Store 20260605.2337` |
| Profile UUID | `da7839d6-2489-4272-b999-c61efccfe473` |
| Profile expiration | `2027-06-04 21:48:21 CST` |

## Verification

| 检查项 | 结果 |
| --- | --- |
| `.pkg` 文件生成 | PASS |
| `.pkg` Installer 证书签名 | PASS |
| 展开最终 `.pkg` 并找到 `TagLauncher.app` | PASS |
| Bundle ID | PASS: `com.taglauncher.app` |
| `CFBundleShortVersionString` | PASS: `7.9.1` |
| `CFBundleVersion` | PASS: `20260614.1454` |
| `LSMinimumSystemVersion` | PASS: `14.0` |
| `LSApplicationCategoryType` | PASS: `public.app-category.utilities` |
| 嵌入 `embedded.provisionprofile` | PASS |
| Profile application identifier | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed application identifier | PASS: `CR3J54M8BQ.com.taglauncher.app` |
| Signed team identifier | PASS: `CR3J54M8BQ` |
| Signed sandbox entitlement | PASS |
| Signed user-selected file entitlement | PASS |
| Signed keychain access groups | PASS: `CR3J54M8BQ.*` |
| Expanded package has `com.apple.quarantine` | PASS: `0` |
| Package payload AppleDouble `._*` entries | PASS: `0` |
| Executable architecture | PASS: `arm64` |

## Next Upload Step

Use Transporter and select:

`/Users/ar/Projects/Taglauncher/src/Release/AppStore-7.9.1-20260614.1454/Upload/TagLauncher-7.9.1-build20260614.1454.pkg`
