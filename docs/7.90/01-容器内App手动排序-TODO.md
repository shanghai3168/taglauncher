# 容器内 App 手动拖拽排序 TODO

## 目标

用户可以在同一个容器/分组内拖动 App，改变该容器内默认显示顺序；重启、刷新、语言切换、导入导出、恢复布局后顺序仍保持。

## 版本

- 起始版本：`7.9.0`
- 需求级别：较大需求
- 当前状态：已实现，待最终用户体验验收

## 核心决策

- 这不是纯 UI 数组重排；App 顺序必须作为“分类与布局方案”的一部分持久化到 `TagDatabase.Store`。
- 第一版只支持同一容器内排序，不改变 App 的标签归属。
- 跨容器拖动继续沿用现有移动/复制标签逻辑。
- 拖到空白区域继续沿用现有移除来源标签/归为未分类确认逻辑。
- 不改 Quick Search 排名，不改 `appTags[path]` 语义，不存像素坐标、row/column 或 `IndexPath`。

## 数据层 TODO

- [x] 在 `TagDatabase.Store` 新增 `containerAppOrder: [String: [String]]`，旧 JSON 用 `decodeIfPresent` 默认空字典。
- [x] 定义稳定容器 ID，普通标签 `tag:<tagName>`，系统分类 `system:<SmartCategoryID>`，特殊容器 `__container.uncategorized` / `__container.appleBuiltIn`。
- [x] `TagGroup` 和分组构造链路携带稳定 container key，显示名继续只用于 UI。
- [x] 分组生成后按 `containerAppOrder` 排组内 apps；未命中的新 App 按现有默认名称排序追加。
- [x] 新增 `TagEditor.reorderApps(inContainer:orderedPaths:)`，走 `saveUserCategorySchemeMutation(reason: "reorder-apps")`。
- [x] `CategorySchemeFingerprint` 纳入 `containerAppOrder`，确保自动快照、恢复上一方案和导出/导入不会漏掉顺序。
- [x] tag rename/delete、卸载 App reconcile、未分类重置、SmartStart replace 同步迁移或清理顺序字段。

## UI TODO

- [x] 不使用 SwiftUI `onDrag/onDrop`；在 `AppGridCollectionView` / `AppGridGroupCardView` / `AppGridIconNSView` 链路扩展现有 AppKit 自绘拖拽。
- [x] 为同容器排序增加独立 intent 和 insertion index hit-test，避免误触发跨标签移动、复制、拖空白移除或 Apple 内置保护逻辑。
- [x] 第一版显示插入位置指示线，不做复杂跨容器预览。
- [x] 排序开始时继续抑制 hover bubble；结束、取消、滚动、切换窗口时清理拖拽状态。
- [x] 编辑模式的批量添加/移除标签界面第一版不开放 App 排序，只读取排序结果。

## 推荐开发切分

1. 数据层 PR：
   - schema、容器 ID、排序 helper、fingerprint、导入导出/恢复/重置/SmartStart 规则。
   - 先不接 UI。
2. UI hit-test PR：
   - 同容器插入位置计算和本地预览。
   - 不落盘，不改变跨容器拖拽。
3. 集成 PR：
   - `ContentView` 接入 reorder callback。
   - drop/end 时保存该容器完整顺序并刷新。
4. 回归 PR：
   - 数据脚本 QA、macOS 14 typecheck/build、窗口/拖拽 smoke、真实鼠标手工验收。

## QA 阻断项

- [x] 旧 `tags.json` 无顺序字段可加载，默认顺序与现版本一致。
- [x] 新字段导出/导入 roundtrip 保留顺序；恢复上一方案恢复顺序。
- [x] 排序后刷新、重启、语言切换、SmartStart 备份/恢复按容器 ID 保留或清理顺序。
- [x] 同容器排序不破坏跨容器移动、Option 复制、拖空白移除、Apple 内置保护的数据入口。
- [x] 多标签 App 在 A 容器排序不影响 B 容器顺序。
- [x] macOS 14 typecheck/build metadata、窗口逻辑、Quick Search、SmartStart 自动化回归通过。

## 风险等级

- 最小方案：中等。
- 一次性做跨容器插入、跨机器稳定匹配、复杂拖拽 payload 和所有模式完整预览：高。
