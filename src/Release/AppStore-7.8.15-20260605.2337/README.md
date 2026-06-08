# TagLauncher 7.8.15 App Store 最终上架资料

生成时间：2026-06-05 23:41:00 HKT

## 冻结信息

- 产品：TagLauncher
- 版本：7.8.15
- Build：20260605.2337
- Bundle ID：com.taglauncher.app
- 最低系统版本：macOS 15.0
- 源码分支：codex/fix-quick-search-focus-routing
- 源码提交：ed43ee83789cb99b1cb95db340fee939dd0dedec
- 冻结 tag：`v7.8.15-build20260605.2337`（提交前创建）

## 上架结论

- 7.8.15 build 20260605.2337 是当前准备提交 App Store 的最终候选。
- 7.8.14、7.8.13 及更早 build 都不要再提交市场。
- 本目录内 DMG 是本地可回滚候选包；App Store Connect 最终上传仍需要按 `BUILD_SIGN_UPLOAD.md` 用 Apple Developer 账号证书生成 `.pkg`。

## 安装包

- DMG：Archive/TagLauncher-7.8.15-build20260605.2337.dmg
- SHA256：ed1938afe16ee22cb28adc90231f6f9d6566c186025371c70c9da9c7f04ea493
- 大小：5991360 bytes

## 截图

- App Store 上传候选：`Screenshots/AppStore/`
- 数量：8
- 尺寸：2880 x 1800
- 格式：PNG
- 原始截图备份：`Screenshots/raw/`
- 说明：7.8.15 为 App Grid 加载修复，UI 无变化，沿用 7.8.14 截图资产。

## 官网（GitHub Pages）

- 首页：https://shanghai3168.github.io/taglauncher/
- 支持：https://shanghai3168.github.io/taglauncher/support.html
- 隐私（中文）：https://shanghai3168.github.io/taglauncher/privacy-zh.html
- 隐私（英文）：https://shanghai3168.github.io/taglauncher/privacy.html

源码在公开仓库 `shanghai3168/taglauncher` 的 `docs/` 目录；本地副本见项目内 `publish-website/docs/`。

## 资料入口

- `APP_STORE_MARKETING_AND_METADATA.md`：卖点、对比 Launchpad、Connect 全文案（中英）
- `APP_STORE_CONNECT_METADATA.md`：App Store Connect 精简草稿
- `APP_STORE_RELEASE_CHECKLIST.md`：提交前检查清单
- `APP_STORE_ASSET_INVENTORY.md`：图标和截图清单
- `BUILD_SIGN_UPLOAD.md`：签名、pkg、上传说明
- `FIRST_TIME_MAC_APP_STORE_TODO.md`：账号侧待办
- `Review/APP_REVIEW_NOTES.md`：审核备注
- `Legal/PRIVACY_POLICY.md`：英文隐私政策草稿
- `Legal/PRIVACY_POLICY.zh-Hans.md`：中文隐私政策草稿
- `Support/SUPPORT.md`：支持页草稿

## 已完成验证

- `APP_BUILD=20260605.2337 zsh ./build.sh` 通过
- `codesign --verify --deep --strict build/TagLauncher.app` 通过
- App 版本/build 校验通过：`7.8.15 / 20260605.2337`
- `hdiutil verify build/TagLauncher-7.8.15-build20260605.2337.dmg` 通过
- DMG 挂载检查通过，包含 `TagLauncher.app` 和 `Applications -> /Applications`

## Apple 官方资料入口

- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Upload screenshots: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
- Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- App privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Certificates: https://developer.apple.com/help/account/certificates/certificates-overview/
- App Store provisioning profile: https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/