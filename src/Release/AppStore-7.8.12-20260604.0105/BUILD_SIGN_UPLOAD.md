# Build, Sign, And Upload Notes

## 当前冻结包

本地可回滚 DMG 已完成验证，但它不是 App Store Connect 的最终上传产物。

- Version: `7.8.12`
- Build: `20260604.0105`
- Source commit: `be83948fab7b643634ede2403abdca27e6b45f29`
- Release tag: `v7.8.12-build20260604.0105`
- Local DMG: `Archive/TagLauncher-7.8.12-build20260604.0105.dmg`
- Local DMG SHA256: `f93702a912fb56a24a826386467b86e607e5b12b55fcc6dbe3b5a7224321be0a`

## 当前签名资产状态

本机当前 `security find-identity -v -p codesigning` 只发现：

- `VoiceSnap Local Code Signing`
- `PrivateVoice Local Code Signing`

缺少 App Store 上传通常需要的身份：

- `Mac App Distribution` 或 Apple 账号当前显示的等效 distribution identity。
- `Mac Installer Distribution`，如果要用 `productbuild` 生成 signed `.pkg`。
- `Mac App Store Connect` provisioning profile for `com.taglauncher.app`。

## Sandbox 状态

`Apptag/TagLauncher.entitlements` 当前包含：

- `com.apple.security.app-sandbox = true`
- `com.apple.security.files.user-selected.read-write = true`

Mac App Store 分发需要 sandbox。请在最终 signed build 上复核 entitlements。

## 推荐上传路径

优先使用 Apple 官方图形化链路，降低手写签名参数出错概率：

1. 在 Apple Developer 账号安装 Mac App Store distribution certificate 和 provisioning profile。
2. 用 App Store signing 设置构建 `7.8.12 / 20260604.0105`。
3. 用 Xcode Organizer 或 Transporter 上传。
4. 等待 App Store Connect 处理完成。
5. 在 App Store Connect 的 `7.8.12` 版本里选择处理完成的 build。

## CLI 命令形状

证书名称取决于你的 Apple Developer 账号，必须使用 `security find-identity -v -p codesigning` 里显示的真实名称。

```bash
cd /Users/ar/Projects/Taglauncher

APP_STORE=1 \
CODESIGN_IDENTITY="Apple Distribution: <TEAM NAME> (<TEAMID>)" \
APP_BUILD=20260604.0105 \
zsh ./build.sh

codesign --verify --deep --strict --verbose=2 build/TagLauncher.app
codesign -d --entitlements :- build/TagLauncher.app
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
```

如果采用 `.pkg` 上传：

```bash
productbuild \
  --component build/TagLauncher.app /Applications \
  --sign "Mac Installer Distribution: <TEAM NAME> (<TEAMID>)" \
  build/TagLauncher-7.8.12-build20260604.0105-AppStore.pkg

xcrun altool --validate-app \
  --type macos \
  --file build/TagLauncher-7.8.12-build20260604.0105-AppStore.pkg \
  --username "<APPLE_ID>" \
  --password "<APP_SPECIFIC_PASSWORD>"

xcrun altool --upload-app \
  --type macos \
  --file build/TagLauncher-7.8.12-build20260604.0105-AppStore.pkg \
  --username "<APPLE_ID>" \
  --password "<APP_SPECIFIC_PASSWORD>"
```

也可以直接用 Transporter 打开上传包完成上传。

## 上传前验证

在最终 App Store signed build 上执行：

```bash
codesign --verify --deep --strict --verbose=2 build/TagLauncher.app
codesign -d --entitlements :- build/TagLauncher.app
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/TagLauncher.app/Contents/Info.plist
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' build/TagLauncher.app/Contents/Info.plist
bash Scripts/window_logic_qa.sh
```

重点复测：

- Sandbox 下扫描已安装应用。
- Sandbox 下通过 `NSWorkspace` 启动应用。
- 用户选择文件权限下的导入/导出。
- 全局快捷键。
- AppGrid、Quick Search、Settings 在全屏和 Split View 下的窗口层级。
- Quick Search-only 模式刚打开后不被过期鼠标 dismiss 关闭。
- Login-at-launch 设置在 sandbox build 中的行为。

## Build 编号规则

- 如果上传失败并需要重新打包上传，应递增 `CFBundleVersion`，使用新的 `YYYYMMDD.HHMM`。
- 如果递增 build，会产生一个新的发布冻结点，需要更新 `Info.plist`、`CHANGELOG.md`、Release 文档、manifest、tag 和上传资料。
