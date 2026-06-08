# QA Release Evidence

## Scope

本次验证对象是 TagLauncher 7.8.9 build 20260602.1929 的正式可回滚测试包。

重点覆盖本轮新增需求：

- 在 5 种 App Grid 视图中，将应用图标拖到标签栏标签名称上。
- 支持顶部、左侧、右侧标签栏。
- 当目标标签尚未关联该应用时，放手后建立关联。
- 拖拽 hover 时目标标签浮起，其他标签变暗，视觉效果与标签排序一致。

## 用户验收

- 用户已试用本轮生成的本地 `.app`，反馈“没有问题”。
- 用户随后要求生成正式可回滚测试包。

## 自动/半自动验证

### 构建验证

- `APP_BUILD=20260602.1929 zsh ./build.sh`：通过
- `zsh ./make_dmg.sh`：通过
- 生成 DMG：`build/TagLauncher-7.8.9-build20260602.1929.dmg`

### 包验证

- App version：`7.8.9`
- App build：`20260602.1929`
- `codesign --verify --deep --strict build/TagLauncher.app`：通过
- `hdiutil verify build/TagLauncher-7.8.9-build20260602.1929.dmg`：通过
- DMG 挂载检查：通过，DMG 内 App version/build 与预期一致，`Applications` 链接存在
- SHA256：`353ac022f66935b4668176958e484988f6f0164bfaa581604dd9301daa4ffaf0`

### 交互逻辑验证

执行临时 AppKit QA 用例，覆盖横向与纵向标签栏：

- 横向标签栏 hover：目标标签 alpha 保持 1，其他标签变暗
- 横向标签栏 drop：drop 正确路由到目标标签
- 纵向标签栏 hover：目标标签 alpha 保持 1，其他标签变暗
- 纵向标签栏 drop：drop 正确路由到目标标签
- hover 结束后状态恢复
- hover active/inactive 事件正常发出

结果：`PASS TagNavigation app-drop visual/drop routing horizontal+vertical`

## 代码路径核对

- 5 种 App Grid 视图共用同一套 AppKit 拖拽路径，不为不同视图分叉实现。
- 顶部、左侧、右侧标签栏共用 `appKitTagNavigation`，横向/纵向只改变布局方向。
- drop 逻辑只追加目标标签，不执行“移除原标签”或“移到未分类”逻辑。

## 未重复执行项

本轮需求不改窗口/Space/Quick Search 路由逻辑，因此没有重新执行完整窗口 8 大逻辑回归脚本。窗口逻辑保持上一轮已验收版本的代码路径。

