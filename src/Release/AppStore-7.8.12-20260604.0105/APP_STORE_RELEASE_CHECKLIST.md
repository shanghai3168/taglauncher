# TagLauncher 7.8.12 App Store 发布清单

核对日期：2026-06-04 HKT

## 当前冻结状态

- 版本：`7.8.12`
- Build：`20260604.0105`
- Bundle ID：`com.taglauncher.app`
- 源码冻结提交：`be83948fab7b643634ede2403abdca27e6b45f29`
- 源码冻结 tag：`v7.8.12-build20260604.0105`
- Release 归档提交：`6478431`
- 分支：`codex/fix-quick-search-focus-routing`
- 本地可回滚 DMG：`Archive/TagLauncher-7.8.12-build20260604.0105.dmg`
- DMG SHA256：`f93702a912fb56a24a826386467b86e607e5b12b55fcc6dbe3b5a7224321be0a`

## 已完成

- [x] 源码已提交并冻结到固定 commit。
- [x] 已创建 release tag，且 tag 指向源码冻结 commit。
- [x] `CHANGELOG.md`、`Info.plist`、DMG 文件名和 Release 文档的版本/build 一致。
- [x] `APP_BUILD=20260604.0105 zsh ./build.sh` 通过。
- [x] `zsh ./make_dmg.sh` 通过。
- [x] `codesign --verify --deep --strict build/TagLauncher.app` 通过。
- [x] `hdiutil verify build/TagLauncher-7.8.12-build20260604.0105.dmg` 通过。
- [x] DMG 挂载检查通过，包含 `TagLauncher.app` 和 `Applications -> /Applications`。
- [x] 完整窗口逻辑 QA 通过，结论为 `ALL WINDOW LOGIC QA PASSED`。
- [x] App entitlements 文件存在，含 App Sandbox 和用户选择文件读写权限。
- [x] App 图标 1024x1024 已归档。
- [x] App Store Connect 文案、审核备注、截图计划、隐私政策草稿和支持页草稿已准备。

## 去 App Store Connect 前必须完成

- [ ] 登录 Apple Developer / App Store Connect，确认账号协议已接受。
- [ ] 若准备收费，完成 Paid Apps Agreement、税务和银行信息。
- [ ] 创建或确认 macOS App ID：`com.taglauncher.app`。
- [ ] 启用 App Sandbox capability。
- [ ] 安装 Mac App Store 上传所需证书和 profile：
  - `Mac App Distribution` 或账号当前显示的等效 Apple Distribution 证书。
  - `Mac Installer Distribution` 证书，如果采用 signed `.pkg` 上传。
  - `Mac App Store Connect` provisioning profile，Bundle ID 为 `com.taglauncher.app`。
- [ ] 重新运行 `security find-identity -v -p codesigning`，确认不再只有本地签名证书。
- [ ] 发布隐私政策 URL 和支持 URL 到公网，并替换文档中的占位符。
- [ ] 采集至少 1 张 Mac 截图，建议 5 张，尺寸使用 16:10：`2880 x 1800` 优先。
- [ ] 按 `BUILD_SIGN_UPLOAD.md` 生成 App Store signed build 和上传包。
- [ ] 对 App Store signed build 再跑一遍 QA，尤其是 sandbox 下扫描应用、启动应用、导入导出、全局快捷键、全屏/Split View。
- [ ] 上传构建到 App Store Connect，等待处理完成。
- [ ] 在 App Store Connect 选择构建并提交审核。

## App Store Connect 需要填写/上传的内容

- App record：平台 `macOS`、Name `TagLauncher`、Bundle ID `com.taglauncher.app`、SKU `taglauncher-macos`。
- 版本：`7.8.12`。
- 分类：`Utilities`。
- 价格与销售区域：由账号策略决定；首次发布建议手动发布。
- Product page metadata：名称、副标题、描述、关键词、What's New、Support URL、Privacy Policy URL、Copyright。
- App Privacy：当前代码审计建议填写“不收集数据”，提交前必须按最终 signed build 复核。
- 年龄分级、内容权利、出口合规、税务分类、App Review 联系方式。
- App Review Notes：使用 `Review/APP_REVIEW_NOTES.md`。
- Screenshots：使用 `Screenshots/SCREENSHOT_SHOT_LIST.md` 拍摄和导出。
- Build：上传后选择 App Store Connect 处理完成的 `7.8.12 / 20260604.0105` 构建。

## 当前阻塞项

本机钥匙串目前只发现本地签名身份：

- `VoiceSnap Local Code Signing`
- `PrivateVoice Local Code Signing`

未发现 App Store 上传所需的 `Mac App Distribution` / `Mac Installer Distribution` 身份。因此我无法在本机完成最终 App Store signed `.pkg` 或上传动作。安装 Apple Developer 账号侧签名资产后，继续按 `BUILD_SIGN_UPLOAD.md` 执行。

## 官方依据

- Apple：创建 App Store Connect app record 前需先添加 app record，且 Account Holder 需签署最新协议。
- Apple：上传构建可使用 Xcode、Swift Playgrounds、altool 或 Transporter，构建由 bundle ID、版本号和 build string 关联到 App Store Connect。
- Apple：Mac App 截图必须上传 1 到 10 张，格式为 JPEG/JPG/PNG，Mac 尺寸为 16:10 的 `1280 x 800`、`1440 x 900`、`2560 x 1600` 或 `2880 x 1800`。
- Apple：App Store 分发需要在 App Store Connect 提供数据处理实践；隐私政策 URL 对所有 App 必填。
- Apple：macOS App 上传需要 `Mac App Store Connect` provisioning profile，App ID 必须匹配 Bundle ID。
