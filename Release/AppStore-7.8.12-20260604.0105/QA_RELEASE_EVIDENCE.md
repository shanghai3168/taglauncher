# QA Release Evidence

## Scope

本次验证对象是 TagLauncher 7.8.12 build 20260604.0105 的正式可回滚测试包 / App Store 候选 DMG。

重点覆盖本轮修复：

- Quick Search-only 模式刚打开后不应被过期鼠标关闭事件立即关掉。
- `Fn + Space` 打开 Quick Search 后，候选面板应稳定留在屏幕上。
- 键盘取消、再次按 `Fn + Space`、程序化关闭仍应立即生效。
- Quick Search 结果点击验证应命中首条结果行中心。

## 自动/半自动验证

### 源码冻结前验证

- `git diff --check`：通过
- `bash -n Scripts/window_logic_qa.sh`：通过
- `bash Scripts/window_logic_qa.sh`：通过，结论 `ALL WINDOW LOGIC QA PASSED`

### Targeted 验证

- 两段式 `Fn + Space` 验证：第一次打开后窗口数为 2，再次按 `Fn` 后窗口数为 0；第二次重启后第一次尝试窗口数为 2。
- 诊断日志验证：Quick Search 关闭来源为 `keyboard`，不是误触发的 `mouse`。
- Quick Search 结果点击验证：点击首条结果行中心后窗口数为 0。
- 验证后已清理 `diagnosticLoggingEnabled` defaults。

### 构建验证

- `APP_BUILD=20260604.0105 zsh ./build.sh`：通过
- `zsh ./make_dmg.sh`：通过
- 生成 DMG：`build/TagLauncher-7.8.12-build20260604.0105.dmg`

### 包验证

- App version：`7.8.12`
- App build：`20260604.0105`
- `codesign --verify --deep --strict build/TagLauncher.app`：通过
- `hdiutil verify build/TagLauncher-7.8.12-build20260604.0105.dmg`：通过
- DMG 挂载检查：通过
- DMG 内含 `TagLauncher.app`
- DMG 内含 `Applications -> /Applications`
- 挂载后 App version/build 与预期一致
- 挂载后 App 签名验证通过
- SHA256：`f93702a912fb56a24a826386467b86e607e5b12b55fcc6dbe3b5a7224321be0a`

## 代码路径核对

- 本轮只修改 Quick Search dismiss 事件来源标记、早期鼠标/backdrop dismiss 去抖和窗口 QA 脚本。
- 没有修改 Quick Search 搜索匹配、App Grid 布局、Settings、文件面板或窗口层级策略。
- `keyboard`、`programmatic` 来源的关闭请求不走延迟，避免影响 Esc、再次按 `Fn + Space` 和应用失焦等路径。

## 未重复执行项

- 本轮已重新执行完整窗口逻辑 QA 脚本；没有刻意跳过相关窗口/Space/快捷键回归。
