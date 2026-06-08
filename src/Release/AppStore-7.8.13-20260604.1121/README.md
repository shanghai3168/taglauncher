# TagLauncher 7.8.13 App Store 候选资料

生成时间：2026-06-04 12:15:27 HKT

## 包信息

- 产品：TagLauncher
- 类型：正式可回滚测试包 / App Store 候选资料
- 版本：7.8.13
- Build：20260604.1121
- Bundle ID：com.taglauncher.app
- 最低系统版本：macOS 15.0
- 源码分支：codex/fix-quick-search-focus-routing
- 源码提交：1d19c0593ebe6abe60468e12e87459ab68586603
- 冻结 tag：v7.8.13-build20260604.1121

## 重要结论

- 7.8.12 的 App Store 发布包不应继续提交市场。
- 7.8.13 是本次重新冻结的候选版本，包含用户可见修复：新安装应用后，App Grid 和 Quick Search 会在打开时轻量检查应用目录签名，并在目录变化时刷新索引。
- 本目录内 DMG 是本地可回滚候选包，不是 App Store Connect 的最终上传产物。上传 App Store 仍需要 Apple Developer 账号侧签名证书、Mac App Store provisioning profile 和上传包。

## 安装包

- DMG：Archive/TagLauncher-7.8.13-build20260604.1121.dmg
- SHA256：f594509807ca5aa72c6a9fdf118a4f3c9ee991528cd5dbe68587ea5fe601d6f6
- 大小：5990963 bytes

## App Store 资料

- 发布清单：APP_STORE_RELEASE_CHECKLIST.md
- 资产清单：APP_STORE_ASSET_INVENTORY.md
- App Store Connect 文案草稿：APP_STORE_CONNECT_METADATA.md
- 签名、打包和上传说明：BUILD_SIGN_UPLOAD.md
- 首次上架账号侧待办：FIRST_TIME_MAC_APP_STORE_TODO.md
- 审核备注：Review/APP_REVIEW_NOTES.md
- 隐私政策草稿：Legal/PRIVACY_POLICY.md、Legal/PRIVACY_POLICY.zh-Hans.md
- 支持页草稿：Support/SUPPORT.md
- 截图计划：Screenshots/SCREENSHOT_SHOT_LIST.md
- App 图标：Assets/TagLauncher-AppIcon-1024.png
- 用户原始截图：Screenshots/raw/
- App Store 上传候选截图：Screenshots/AppStore/

## 本版本变更

- App Grid / Quick Search 打开时检查 `/Applications`、`~/Applications`、系统 Applications 等标准应用目录的轻量签名。
- 目录签名未变化时不刷新索引、不重建界面，避免拖慢每次打开体验。
- 目录签名变化时后台刷新应用索引，使新安装应用能被 App Grid 和 Quick Search 发现。
- QA 脚本补强了 Quick Search 搜索结果、全屏 overlay 稳定性、Dock 点击和 hover 轨迹验证。

## 官方要求核对

- Apple 当前要求 Mac 截图为 16:10，接受 1280 x 800、1440 x 900、2560 x 1600、2880 x 1800，且 Mac app 必须提供截图。
- App Store Connect 允许每个平台上传 1 到 10 张截图，格式为 `.jpeg`、`.jpg` 或 `.png`。
- 构建上传可使用 Xcode、Swift Playground、altool 或 Transporter；macOS app 上传也支持 Transporter/altool。
- macOS App Store 手动签名需要 Apple Developer 账号中的 Mac App Distribution / Mac Installer Distribution 证书，以及匹配 `com.taglauncher.app` 的 Mac App Store provisioning profile。
- 隐私政策 URL 是所有 App Store app 的必填项，隐私问卷需要准确声明应用和第三方代码的数据实践。

## 回滚方式

如需回滚到本包对应源码状态：

```bash
git checkout v7.8.13-build20260604.1121
APP_BUILD=20260604.1121 zsh ./build.sh
zsh ./make_dmg.sh
```

如需直接恢复安装包，使用本目录 `Archive/` 下的 DMG。
