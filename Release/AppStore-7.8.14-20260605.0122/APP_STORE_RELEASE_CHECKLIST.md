# App Store Release Checklist

## 本地冻结

- [x] 源码版本为 `7.8.14`
- [x] Build 为 `20260605.0122`
- [x] `CHANGELOG.md` 已包含 7.8.14
- [x] 修复提交已推送到 `origin/codex/fix-quick-search-focus-routing`
- [x] 冻结 tag 已创建并推送：`v7.8.14-build20260605.0122`
- [x] 已重新构建 `.app`
- [x] 已重新生成 7.8.14 DMG
- [x] DMG 已复制到 `Archive/`
- [x] 7.8.13 标记为不再提交 App Store

## 本地 QA

- [x] App bundle 签名校验通过
- [x] DMG `hdiutil verify` 通过
- [x] DMG 挂载检查通过
- [x] DMG 内 app 版本/build 正确
- [x] DMG 内包含 `/Applications` symlink
- [x] Keychain Access targeted regression 通过
- [x] `SHA256SUMS.txt` 校验通过
- [ ] Full window logic QA 通过。当前尝试停止在 Quick Search result-list 坐标辅助脚本，见 `QA_RELEASE_EVIDENCE.md`。

## App Store Connect 资料

- [x] App 图标 1024 png 已准备
- [x] 用户原始截图已收录
- [x] App Store 尺寸截图已导出
- [x] 截图均为 2880 x 1800 PNG
- [x] 英文/中文 What's New 草稿已准备
- [x] Review Notes 草稿已准备
- [x] Privacy Policy 草稿已准备
- [x] Support 页草稿已准备

## 账号侧提交前必须完成

- [ ] Apple Developer Program 会员有效
- [ ] App Store Connect 已创建 app record
- [ ] Bundle ID 使用 `com.taglauncher.app`
- [ ] 发布隐私政策 URL
- [ ] 填写支持 URL
- [ ] 完成 App Privacy、Age Rating、Export Compliance
- [ ] 安装 Mac App Distribution / Mac Installer Distribution 证书
- [ ] 创建并安装 `com.taglauncher.app` 的 Mac App Store provisioning profile
- [ ] 用账号证书重新签名并生成上传 `.pkg`
- [ ] 用 Transporter/Xcode/altool 上传构建
- [ ] 在 App Store Connect 选择 build 并提交审核
