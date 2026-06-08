# Taglauncher 代码治理与 Git 规范

本文档是 `/Users/ar/Projects/Taglauncher` 的代码管理、Git 使用、交付和 Agent 协作规范。根目录 `AGENTS.md` 是强制入口；本文件是完整执行标准。

## 1. 项目边界

- 主仓库工作区固定为 `/Users/ar/Projects/Taglauncher`。
- 唯一源码根目录固定为 `/Users/ar/Projects/Taglauncher/src`。
- App 源码、构建脚本、QA 脚本、SmartStart/Apple catalog 资料、发布资料都必须在 `src/` 下维护。
- 项目根目录只保留仓库入口文档、公开网站资料、治理规范和非源码管理说明。
- 不允许再创建或继续使用 `/Users/ar/Projects/Taglauncher-*source`、`/Users/ar/Projects/Apptag-*` 等外部源码目录。

## 2. Git 工作区规则

- 开始任何代码、文档、发布或迁移任务前，必须先执行并检查：

```bash
git status --short 2>&1 | head -c 6000
git branch --show-current 2>&1 | head -c 2000
git worktree list --porcelain 2>&1 | head -c 6000
```

- 如果工作区已有改动，必须区分改动来源：
  - 用户或其他 Agent 的改动不得擅自回滚。
  - 与当前任务无关的改动保持原样。
  - 与当前任务相关但来源不明的改动，先读懂再继续。
- 禁止使用 `git reset --hard`、`git checkout --`、`git clean` 等破坏性命令，除非用户明确要求并确认目标。

## 3. 分支策略

- `main` 是主线，不在脏工作区中直接做实验。
- 研发、迁移、修复、发布准备应使用独立分支。
- Agent 创建分支默认使用 `codex/` 前缀，例如：

```bash
git switch -c codex/fix-quick-search-index
git switch -c codex/relocate-source-to-src
```

- 不允许用外部源码目录代替正常 Git branch。
- 大规模重构、历史迁移、发布冻结前，必须先确认当前分支、HEAD 和安全固定点。

## 4. Commit 规则

- 每个 commit 应表达一个明确意图，不把无关改动混在一起。
- 提交前必须确认：

```bash
git status --short 2>&1 | head -c 6000
git diff --stat 2>&1 | head -c 6000
git diff --cached --stat 2>&1 | head -c 6000
```

- 提交信息使用简洁英文或项目已有风格，示例：
  - `Fix quick search system app matching`
  - `Release 7.8.22 Apple default app catalog`
  - `Relocate app source under src`
- 代码行为、构建、发布资料或用户可见改动提交前必须完成对应 QA，并记录结果。
- 不允许为了“看起来干净”而提交未解释的临时产物、缓存、用户本地数据或证书。

## 5. Tag 与发布固定点

- 发布、分发、安装包、App Store 上传、迁移历史前，必须建立可回退固定点。
- 发布 tag 必须包含版本和 build，例如：

```bash
git tag -a v7.8.22-build20260608.1324 -m "Release 7.8.22 build 20260608.1324"
```

- 迁移或高风险操作前建议建立 `pre-*` 安全 tag，例如：

```bash
git tag -a pre-src-migration-main-YYYYMMDD.HHMM -m "Pre src migration main"
```

- tag、`Info.plist`、`CHANGELOG.md`、`Release/` 资料、最终安装包文件名和 build 编号必须一致。

## 6. Worktree 使用规则

- 默认不使用 worktree；需要并行工作时优先使用当前仓库的正常 branch。
- 如确需 worktree，必须先说明：
  - 目的。
  - 路径。
  - 对应分支。
  - 预计生命周期。
  - 清理条件。
- worktree 不得放在 `/Users/ar/Projects/Taglauncher-*source` 或 `/Users/ar/Projects/Apptag-*` 这类容易被误认为正式源码根目录的位置。
- 任务完成后必须执行：

```bash
git worktree remove WORKTREE_PATH 2>&1 | head -c 6000
git worktree prune 2>&1 | head -c 6000
git worktree list --porcelain 2>&1 | head -c 6000
```

- 如果 worktree 有未提交改动，禁止直接删除；必须先确认归属和处理方式。

## 7. 构建产物与敏感文件

- `build/`、临时安装包、编译缓存、用户本地数据、钥匙串资料、p12 证书、provisioning profile 默认不进源码提交。
- 只有明确作为 release archive 的产物，才可放入 `src/Release/.../Archive/`，并必须配套说明、hash、版本和 QA 证据。
- 证书目录只作为本地敏感资料管理，不作为源码迁移内容。
- 不允许把真实用户数据、隐私资料、账号凭证或本地配置写入 Git。

## 8. Agent 接手流程

接手旧线程、长期任务、发布任务或迁移任务时，必须先完成以下检查，不得等待旧线程：

```bash
git status --short 2>&1 | head -c 6000
git branch --show-current 2>&1 | head -c 2000
git log --oneline --decorate --graph --max-count=12 2>&1 | head -c 6000
git worktree list --porcelain 2>&1 | head -c 6000
```

- 必须读取最近会话记录，确认未完成项、已完成项、阻塞项和用户最新指令。
- 必须确认当前工作区是否处于 merge、rebase、cherry-pick 或 no-commit 状态。
- 不得因为旧线程在等待而继续等待；如果当前上下文足够，应直接推进。
- 如果必须等待用户，必须明确说明等待原因、需要用户做什么、收到回复后的下一步。

## 9. QA 与交付门禁

- 开发完成不能直接交付，必须先自查和验证。
- 小改动至少运行与改动直接相关的 QA。
- 影响 App 行为、构建脚本、发布资料或用户可见功能时，至少确认：
  - 代码 diff 范围。
  - 相关 QA 结果。
  - 构建是否通过。
  - 是否产生额外未跟踪文件。
- 迁移、发布、构建任务必须记录可复核证据：版本/build、执行命令、关键结果、产物路径、hash 或 QA 报告。
- QA 失败不能只口头解释；必须判断是产品回归、脚本断言问题、环境问题还是迁移无关问题，并记录结论。

## 10. 命令输出保护

任何未知或可能很大的命令输出都必须 byte-cap：

```bash
COMMAND 2>&1 | head -c 6000
```

- 构建、测试、目录遍历、日志、Git diff、搜索结果都应限制输出。
- 搜索优先用 `rg` / `rg --files`。
- 不无上限打印大文件、构建日志、目录树或二进制信息。

## 11. 禁止事项

- 禁止在 `src/` 外新增 App 源码副本。
- 禁止用外部目录长期承载源码开发。
- 禁止在不看 `git status` 的情况下提交、合并、发布或清理。
- 禁止擅自回滚用户改动。
- 禁止把证书、账号、用户数据、临时 build 缓存提交进 Git。
- 禁止把阶段性通过当成整体完成；仍有明确未完成项时必须继续推进。
- 禁止没有 QA 证据就声称可交付。

## 12. 常用检查命令

```bash
git status --short 2>&1 | head -c 6000
git branch --show-current 2>&1 | head -c 2000
git log --oneline --decorate --graph --max-count=12 2>&1 | head -c 6000
git worktree list --porcelain 2>&1 | head -c 6000
git diff --stat 2>&1 | head -c 6000
git diff --cached --stat 2>&1 | head -c 6000
git ls-files src 2>&1 | wc -l | head -c 2000
```

从源码根目录运行 QA：

```bash
cd /Users/ar/Projects/Taglauncher/src
bash Scripts/apple_default_apps_resource_qa.sh 2>&1 | head -c 12000
bash Scripts/apple_default_note_policy_qa.sh 2>&1 | head -c 12000
bash Scripts/smartstart_catalog_resource_qa.sh 2>&1 | head -c 12000
bash Scripts/quick_search_app_name_qa.sh 2>&1 | head -c 12000
bash Scripts/quick_search_system_app_qa.sh 2>&1 | head -c 12000
```
