# QA Release Evidence

## Scope

本次验证对象是 TagLauncher 7.8.10 build 20260602.2302 的正式可回滚测试包 / App Store 候选 DMG。

重点覆盖本轮修复：

- Quick Search 面板四个圆角不应出现脏色块。
- Quick Search 面板阴影不应被窗口边界裁切。
- Quick Search 面板应呈现更明显的浮层感。
- 不改变搜索匹配、快捷键、App Grid 入口、Dock 图标或窗口路由逻辑。

## 用户视觉确认

- 用户手动触发 Quick Search 后提供截图。
- 截图显示 Quick Search 圆角脏块已消失或不再明显，面板阴影已明显增强。

## 自动/半自动验证

### 构建验证

- `APP_BUILD=20260602.2302 zsh ./build.sh`：通过
- `zsh ./make_dmg.sh`：通过
- 生成 DMG：`build/TagLauncher-7.8.10-build20260602.2302.dmg`

### 包验证

- App version：`7.8.10`
- App build：`20260602.2302`
- `codesign --verify --deep --strict build/TagLauncher.app`：通过
- `hdiutil verify build/TagLauncher-7.8.10-build20260602.2302.dmg`：通过
- DMG 挂载检查：通过
- DMG 内含 `TagLauncher.app`
- DMG 内含 `Applications -> /Applications`
- 挂载后 App version/build 与预期一致
- SHA256：`7e8394ae67194f560a99b86760f08b5d543291253c2c9579758812cbd426bc67`

## 代码路径核对

- 本轮只修改 Quick Search 面板窗口尺寸、内容内边距、圆角裁剪和阴影绘制。
- 没有修改 Quick Search 搜索匹配、结果启动、全局快捷键注册、App Grid 打开入口、Dock 图标策略或窗口路由。

## 未重复执行项

本轮为 Quick Search 视觉修复，未改窗口/Space/快捷键状态机，因此没有重新执行完整窗口 8 大逻辑回归脚本。相关窗口逻辑保持上一轮已验收版本的代码路径。
