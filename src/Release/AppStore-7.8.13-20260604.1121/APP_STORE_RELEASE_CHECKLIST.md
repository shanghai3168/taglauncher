# App Store Release Checklist

## 本地冻结

- [x] 源码版本为 `7.8.13`
- [x] Build 为 `20260604.1121`
- [x] `CHANGELOG.md` 已包含 7.8.13
- [x] 修复提交已推送到 `origin/codex/fix-quick-search-focus-routing`
- [x] 已重新构建 `.app`
- [x] 已重新生成 7.8.13 DMG
- [x] DMG 已复制到 `Archive/`
- [x] 7.8.12 标记为不再提交 App Store
- [x] 冻结 tag 已创建并推送：`v7.8.13-build20260604.1121`

## 本地 QA

- [x] App bundle 签名校验通过
- [x] DMG `hdiutil verify` 通过
- [x] DMG 挂载检查通过
- [x] DMG 内 app 版本/build 正确
- [x] DMG 内包含 `/Applications` symlink
- [x] Quick Search 新安装应用刷新路径通过 targeted 验证
- [x] Full window logic QA 通过
- [x] `SHA256SUMS.txt` 校验通过
- [x] `git diff --check` 通过

## App Store Connect 资料

- [x] App 图标 1024 png 已准备：`Assets/TagLauncher-AppIcon-1024.png`
- [x] 用户原始截图已收录：`Screenshots/raw/`
- [x] App Store 尺寸截图已导出：`Screenshots/AppStore/`
- [x] 截图均为 2880 x 1800 PNG
- [x] 英文/中文描述草稿已准备
- [x] What's New 草稿已准备
- [x] Review Notes 草稿已准备
- [x] Privacy Policy 草稿已准备
- [x] Support 页草稿已准备

## 账号侧提交前必须完成

- [ ] Apple Developer Program 会员有效
- [ ] App Store Connect 已创建 app record
- [ ] Bundle ID 使用 `com.taglauncher.app`
- [ ] SKU 使用最终值，例如 `taglauncher-macos`
- [ ] 选择 macOS 平台和 Utilities 类别
- [ ] 填写支持 URL
- [ ] 发布隐私政策 URL
- [ ] 在 App Privacy 中选择符合当前代码的数据收集声明
- [ ] 完成 Age Rating 问卷
- [ ] 完成 Export Compliance 问卷
- [ ] 完成价格和可用地区
- [ ] 完成版权、联系信息和审核联系信息
- [ ] 安装或创建 Mac App Distribution 证书
- [ ] 安装或创建 Mac Installer Distribution 证书
- [ ] 创建并下载 `com.taglauncher.app` 的 Mac App Store provisioning profile
- [ ] 用账号证书重新签名并生成上传 `.pkg`
- [ ] 用 Transporter/Xcode/altool 上传构建
- [ ] 在 App Store Connect 选择 build 并提交审核

## 官方要求核对日期

核对日期：2026-06-04。

- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Upload app previews and screenshots: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/
- Upload builds: https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/
- Manage app privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Certificate overview: https://developer.apple.com/help/account/certificates/certificates-overview/
- App Store provisioning profile: https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile/
