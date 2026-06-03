# TagLauncher 7.8.12 App Store 候选 DMG

生成时间：2026-06-04 01:12:12 HKT

## 包信息

- 产品：TagLauncher
- 类型：正式可回滚测试包 / App Store 候选 DMG
- 版本：7.8.12
- Build：20260604.0105
- 源码分支：codex/fix-quick-search-focus-routing
- 源码提交：be83948fab7b643634ede2403abdca27e6b45f29
- 冻结 tag：v7.8.12-build20260604.0105

## 安装包

- DMG：Archive/TagLauncher-7.8.12-build20260604.0105.dmg
- SHA256：f93702a912fb56a24a826386467b86e607e5b12b55fcc6dbe3b5a7224321be0a
- 大小：5991391 bytes

## App Store 发布资料

- 发布清单：`APP_STORE_RELEASE_CHECKLIST.md`
- 资产清单：`APP_STORE_ASSET_INVENTORY.md`
- App Store Connect 文案草稿：`APP_STORE_CONNECT_METADATA.md`
- 签名、打包和上传说明：`BUILD_SIGN_UPLOAD.md`
- 审核备注：`Review/APP_REVIEW_NOTES.md`
- 隐私政策草稿：`Legal/PRIVACY_POLICY.md`、`Legal/PRIVACY_POLICY.zh-Hans.md`
- 支持页草稿：`Support/SUPPORT.md`
- 截图计划：`Screenshots/SCREENSHOT_SHOT_LIST.md`
- App 图标：`Assets/TagLauncher-AppIcon-1024.png`

注意：本目录内 DMG 是本地可回滚候选包，不是 App Store Connect 的最终上传产物。上传 App Store 仍需要 Apple Developer 账号侧的 Mac App Store 签名证书、Provisioning Profile，并按 `BUILD_SIGN_UPLOAD.md` 生成上传包。

## 本版本变更

- 修复 Quick Search-only 模式刚打开后可能被过期鼠标关闭事件立即关掉的问题。
- `Fn + Space` 打开后候选面板保持稳定，键盘取消和再次按 `Fn + Space` 仍可立即关闭。
- 窗口 QA 增加对合成 `Fn + Space` 投递的重试，并把 Quick Search 结果点击坐标修正到首条结果行中心。
- 本次只收敛 Quick Search 打开/关闭时序和 QA 覆盖，不改搜索匹配、App Grid 布局、Settings、文件面板或窗口层级策略。

## 回滚方式

如需回滚到本包对应源码状态：

```bash
git checkout v7.8.12-build20260604.0105
APP_BUILD=20260604.0105 zsh ./build.sh
zsh ./make_dmg.sh
```

如需直接恢复安装包，使用本目录 `Archive/` 下的 DMG。
