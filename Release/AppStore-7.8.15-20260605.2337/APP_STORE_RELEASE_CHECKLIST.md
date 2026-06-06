# App Store Release Checklist

## 本地冻结

- [x] 版本为 `7.8.15`
- [x] Build 为 `20260605.2337`
- [ ] Release tag：`v7.8.15-build20260605.2337`（提交前打 tag）
- [x] DMG 已归档
- [x] SHA256 已记录
- [x] 上架截图已生成（沿用 7.8.14 资产）
- [x] App Store 文案、审核备注、隐私政策草稿、支持页草稿已准备

## 提交 App Store 前

- [x] 发布最终隐私政策 URL：`https://shanghai3168.github.io/taglauncher/privacy-zh.html`（英文：`privacy.html`）
- [x] 发布最终支持 URL：`https://shanghai3168.github.io/taglauncher/support.html`
- [ ] 在 Apple Developer 账号中确认证书和 provisioning profile
- [ ] 用 `BUILD_SIGN_UPLOAD.md` 生成 App Store 上传 `.pkg`
- [ ] 用 Transporter、Xcode 或 altool 上传 build
- [ ] 在 App Store Connect 选择 build `20260605.2337`
- [ ] 上传 `Screenshots/AppStore/` 内截图
- [ ] 填写 App Privacy、Age Rating、Export Compliance
- [ ] 提交审核