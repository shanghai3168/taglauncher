# TagLauncher 7.8.14 App Store 候选资料

生成时间：2026-06-05 01:33:18 HKT

## 包信息

- 产品：TagLauncher
- 类型：正式可回滚测试包 / App Store 候选资料
- 版本：7.8.14
- Build：20260605.0122
- Bundle ID：com.taglauncher.app
- 最低系统版本：macOS 15.0
- 源码分支：codex/fix-quick-search-focus-routing
- 源码提交：e5627facd571293ebba8f05f970121716af39603
- 冻结 tag：v7.8.14-build20260605.0122

## 重要结论

- 7.8.13 的 App Store 发布包不应继续提交市场。
- 7.8.14 是本次新的候选版本，包含发布前发现的阻塞修复：Quick Search / App Grid 现在会扫描 `/System/Library/CoreServices/Applications`，可检索“钥匙串访问 / Keychain Access”等系统应用。
- 本目录内 DMG 是本地可回滚候选包，不是 App Store Connect 的最终上传 `.pkg`。上传 App Store 仍需要 Apple Developer 账号侧签名证书、Mac App Store provisioning profile 和上传包。

## 安装包

- DMG：Archive/TagLauncher-7.8.14-build20260605.0122.dmg
- SHA256：f6c8049911ee4130031558d1957ea62cd455452518c64edfcbbbabc61aa010b6
- 大小：5990796 bytes

## App Store 资料

- 发布清单：APP_STORE_RELEASE_CHECKLIST.md
- 资产清单：APP_STORE_ASSET_INVENTORY.md
- App Store Connect 文案草稿：APP_STORE_CONNECT_METADATA.md
- 签名、打包和上传说明：BUILD_SIGN_UPLOAD.md
- 审核备注：Review/APP_REVIEW_NOTES.md
- 隐私政策草稿：Legal/PRIVACY_POLICY.md、Legal/PRIVACY_POLICY.zh-Hans.md
- 支持页草稿：Support/SUPPORT.md
- 截图计划：Screenshots/SCREENSHOT_SHOT_LIST.md
- App 图标：Assets/TagLauncher-AppIcon-1024.png
- 用户原始截图：Screenshots/raw/
- App Store 上传候选截图：Screenshots/AppStore/

## 本版本变更

- 新增扫描 `/System/Library/CoreServices/Applications`，覆盖 Keychain Access 等不位于 `/System/Applications` 的 Apple 系统应用。
- 该目录纳入轻量目录签名检查；目录未变化时不触发额外刷新。
- 新增 `Scripts/quick_search_system_app_qa.sh`，覆盖 `keychain`、`钥匙串`、`yaoshichuan`、`ysc` 四类查询候选。

## 回滚方式

```bash
git checkout v7.8.14-build20260605.0122
APP_BUILD=20260605.0122 zsh ./build.sh
zsh ./make_dmg.sh
```

如需直接恢复安装包，使用本目录 `Archive/` 下的 DMG。
