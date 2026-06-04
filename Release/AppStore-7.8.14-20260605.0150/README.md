# TagLauncher 7.8.14 App Store 最终上架资料

生成时间：2026-06-05 02:04:08 HKT

## 冻结信息

- 产品：TagLauncher
- 版本：7.8.14
- Build：20260605.0150
- Bundle ID：com.taglauncher.app
- 最低系统版本：macOS 15.0
- 源码分支：codex/fix-quick-search-focus-routing
- 源码提交：5194065f5cebfa847061c43cf2c568a1c91721ce
- 冻结 tag：v7.8.14-build20260605.0150

## 上架结论

- 7.8.14 build 20260605.0150 是当前准备提交 App Store 的最终候选。
- 7.8.13、7.8.14 build 20260605.0122 都不要再提交市场。
- 本目录内 DMG 是本地可回滚候选包；App Store Connect 最终上传仍需要按 `BUILD_SIGN_UPLOAD.md` 用 Apple Developer 账号证书生成 `.pkg`。

## 安装包

- DMG：Archive/TagLauncher-7.8.14-build20260605.0150.dmg
- SHA256：1f1fb2502aac3d1d069ff9cf8ba731f6d42faa58e479304ebf914de5d8a3ee34
- 大小：5990829 bytes

## 截图

- App Store 上传候选：`Screenshots/AppStore/`
- 数量：8
- 尺寸：2880 x 1800
- 格式：PNG
- 原始截图备份：`Screenshots/raw/`

## 资料入口

- `APP_STORE_CONNECT_METADATA.md`：App Store Connect 文案
- `APP_STORE_RELEASE_CHECKLIST.md`：提交前检查清单
- `APP_STORE_ASSET_INVENTORY.md`：图标和截图清单
- `BUILD_SIGN_UPLOAD.md`：签名、pkg、上传说明
- `FIRST_TIME_MAC_APP_STORE_TODO.md`：账号侧待办
- `Review/APP_REVIEW_NOTES.md`：审核备注
- `Legal/PRIVACY_POLICY.md`：英文隐私政策草稿
- `Legal/PRIVACY_POLICY.zh-Hans.md`：中文隐私政策草稿
- `Support/SUPPORT.md`：支持页草稿

## 已完成验证

- `APP_BUILD=20260605.0150 zsh ./build.sh` 通过
- `codesign --verify --deep --strict build/TagLauncher.app` 通过
- App 版本/build 校验通过：`7.8.14 / 20260605.0150`
- `hdiutil verify build/TagLauncher-7.8.14-build20260605.0150.dmg` 通过
- DMG 挂载检查通过，包含 `TagLauncher.app` 和 `Applications -> /Applications`
- `Scripts/quick_search_system_app_qa.sh` 通过，覆盖 `Keychain Access / 钥匙串访问`

## Apple 官方资料入口

- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Upload screenshots: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
- Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- App privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Certificates: https://developer.apple.com/help/account/certificates/certificates-overview/
- App Store provisioning profile: https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/
