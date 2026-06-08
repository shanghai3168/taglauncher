# TagLauncher 7.8.9 可回滚测试包

生成时间：2026-06-02 19:51:32 HKT

## 包信息

- 产品：TagLauncher
- 类型：正式可回滚测试包
- 版本：7.8.9
- Build：20260602.1929
- 源码分支：codex/fix-quick-search-focus-routing
- 源码提交：406c5898d103427193e589b4bbe615d0c739b2c5
- 冻结 tag：v7.8.9-build20260602.1929

## 安装包

- DMG：Archive/TagLauncher-7.8.9-build20260602.1929.dmg
- SHA256：353ac022f66935b4668176958e484988f6f0164bfaa581604dd9301daa4ffaf0
- 大小：5983411 bytes

## 本版本变更

- 新增 App Grid 拖拽到标签栏建立关联。
- 支持 5 种 App Grid 视图中的应用图标拖到顶部、左侧或右侧标签名称上。
- 放手后只追加目标标签，不移除原标签；已有关联时不重复写入。
- 拖到标签名称时复用标签排序的视觉反馈：目标标签浮起，其他标签变暗。

## 回滚方式

如需回滚到本测试包对应源码状态：

```bash
git checkout v7.8.9-build20260602.1929
APP_BUILD=20260602.1929 zsh ./build.sh
zsh ./make_dmg.sh
```

如需直接恢复安装包，使用本目录 `Archive/` 下的 DMG。

