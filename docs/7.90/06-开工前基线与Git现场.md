# 7.9.0 开工前基线与 Git 现场

记录时间：2026-06-11 21:10

## 目的

在正式实现“容器内 App 手动拖拽排序”之前，先固定当前分支、需求文档和工作区现场，避免 7.9.0 大需求与 7.8.x 已验收改动、公开页资料、其他文档或 subagent 半成品混在一起。

## 当前分支与基线

- 当前分支：`codex/7.9-app-ordering`
- 当前 HEAD：`f7495650aa7067dfbb587a1af76c90b12bc5a40a`
- HEAD commit：`Add 7.9 app ordering planning docs`
- 分支来源：`codex/macos14-compatibility`
- 工作树：单一 worktree，路径 `/Users/ar/Projects/Taglauncher`
- 计划安全 tag：`pre-7.9-app-ordering-20260611.2110`

`f749565` 已包含 7.9 需求包的核心文档：

- `docs/7.90/README.md`
- `docs/7.90/01-容器内App手动排序-TODO.md`
- `docs/7.90/02-专题讨论纪要.md`
- `docs/7.90/03-产品PRD.md`
- `docs/7.90/04-QA测试用例集.md`
- `docs/7.90/05-技术设计方案.md`

说明：Git 当前跟踪路径为 `docs/7.90`。用户口头指定的 `Docs/7.90` 在本机大小写不敏感路径下可访问，但后续提交统一使用 Git 已跟踪的小写路径，避免大小写重复目录。

## 已完成的 Git 管理

- 已从 `codex/macos14-compatibility` 创建并切到 `codex/7.9-app-ordering`。
- 已按需求整理 7.9.0 PRD、QA 测试用例、技术设计、TODO 和专题讨论纪要。
- 已完成 3 个文档 commit：
  - `3c5daa1 Record app ordering implementation todo`
  - `bbd86bd Organize 7.9 app ordering docs`
  - `f749565 Add 7.9 app ordering planning docs`
- 本文档提交后，应在该提交上创建 `pre-7.9-app-ordering-20260611.2110`，作为正式代码实现前的可回退固定点。

## 当前未提交工作区现场

以下改动在写本文档前已经存在或由 subagent 留下，暂不纳入基线 commit：

- `src/Apptag/DataLayer.swift`
  - 来源：数据层 worker 的半成品。
  - 状态：未暂存、未提交。
  - 内容：已开始加入 `AppContainerID`、`TagGroup.containerID`、`AppIndexer.group` 容器排序参数和排序 helper。
  - 风险：未补完 `Store.containerAppOrder`、`TagEditor.reorderApps`、fingerprint、清理迁移、SmartStart/reset/restore 等，当前不能视为可交付代码。
- `src/Apptag/AppGridCollectionView.swift`
  - 来源：UI worker 的半成品。
  - 状态：未暂存、未提交。
  - 内容：已开始加入 `onReorderApps` 占位、拖拽状态字段和清理逻辑。
  - 风险：未完成 insertion index、插入提示线、drop 分支隔离和 payload 扩展，当前不能视为可交付代码。
- `src/Scripts/app_ordering_data_qa.sh`
  - 来源：QA worker。
  - 状态：未跟踪。
  - 内容：新增数据层静态 QA 门禁，当前按预期失败，用于驱动 `Store.containerAppOrder`、fingerprint、import/export、backup/restore 的实现。
- `docs/7.90/04-QA测试用例集.md`
  - 来源：QA worker。
  - 状态：未暂存、未提交。
  - 内容：自动化入口增加 `bash Scripts/app_ordering_data_qa.sh`。
- `docs/index.html`
  - 来源：既有无关改动。
  - 状态：未暂存、未提交。
  - 处理：不纳入 7.9 排序需求 commit。
- `Docs/KM02-技术/`
  - 来源：既有未跟踪技术资料。
  - 状态：未跟踪。
  - 处理：不纳入 7.9 排序需求 commit。

## Subagent 分工与状态

- 数据层 worker：负责 `Store.containerAppOrder`、稳定容器 ID、重排写入、fingerprint、迁移和 reset/SmartStart 生命周期；已暂停，留下 `DataLayer.swift` 半成品。
- UI worker：负责 AppGrid 同容器拖拽排序、插入位置与视觉反馈；已暂停，留下 `AppGridCollectionView.swift` 半成品。
- QA worker：负责数据层自动化 QA；已完成脚本入口，当前脚本按预期失败，等待实现补齐。
- 代码审核 explorer：已完成只读审查，建议拆分为数据层、显示读取、AppGrid UI、生命周期、版本/QA 五个提交阶段。

## 后续提交顺序

1. 数据模型与顺序持久化：`Store.containerAppOrder`、稳定容器 ID、排序 helper、fingerprint。
2. 读取与显示：`TagGroup.containerID`、`ContentView.makeDisplayGroups` 和 AppIndexer 排序读取。
3. AppGrid UI：同容器拖拽排序、插入提示、drop 分支隔离。
4. 生命周期：SmartStart、重置、恢复、导入导出、标签重命名/删除、reconcile。
5. QA 与发布：自动化脚本、macOS 14 typecheck/build metadata、手工 smoke、版本与 changelog。

每个阶段必须单独 commit；半成品 Swift 改动不得直接打包或交付。
