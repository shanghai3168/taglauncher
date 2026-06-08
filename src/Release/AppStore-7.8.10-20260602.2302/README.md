# TagLauncher 7.8.10 App Store 候选 DMG

生成时间：2026-06-02 23:08:30 HKT

## 包信息

- 产品：TagLauncher
- 类型：正式可回滚测试包 / App Store 候选 DMG
- 版本：7.8.10
- Build：20260602.2302
- 源码分支：codex/fix-quick-search-focus-routing
- 源码提交：bab027127c5d89c5e3f3e83f369065b07a1b0e57
- 冻结 tag：v7.8.10-build20260602.2302

## 安装包

- DMG：Archive/TagLauncher-7.8.10-build20260602.2302.dmg
- SHA256：7e8394ae67194f560a99b86760f08b5d543291253c2c9579758812cbd426bc67
- 大小：5984904 bytes

## 本版本变更

- 修复 Quick Search 面板四个圆角处出现脏色块的问题。
- 为 Quick Search 独立面板预留阴影外扩空间，避免阴影被窗口边界裁切。
- 增强 Quick Search 面板阴影，让浮层感更接近 macOS Spotlight。
- 本次未改搜索匹配、快捷键、App Grid 入口、Dock 图标或窗口路由逻辑。

## 回滚方式

如需回滚到本包对应源码状态：

```bash
git checkout v7.8.10-build20260602.2302
APP_BUILD=20260602.2302 zsh ./build.sh
zsh ./make_dmg.sh
```

如需直接恢复安装包，使用本目录 `Archive/` 下的 DMG。
