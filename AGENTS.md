# AGENTS.md - Taglauncher Agent 入口

## 项目属性

项目类型：研发项目
主要产物：macOS App / 桌面工具

这是 AI Agent 进入 `/Users/ar/Projects/Taglauncher` 后应先读的入口文件。

## 代码治理入口

开始任何代码、Git、迁移、构建、发布或 QA 工作前，必须读取并遵守：

`/Users/ar/Projects/Taglauncher/CODE_GOVERNANCE.md`

本入口文件只保留高优先级硬约束；完整执行标准以 `CODE_GOVERNANCE.md` 为准。若两者冲突，以更严格、项目本地、更具体的规则为准。

## 源码根目录

唯一源码根目录：`/Users/ar/Projects/Taglauncher/src`

- App 源码、构建脚本、QA 脚本、SmartStart/Apple catalog 资料和发布资料都必须在 `src/` 下维护。
- 不允许再创建或继续使用 `/Users/ar/Projects/Taglauncher-*source`、`/Users/ar/Projects/Apptag-*` 等外部源码工作目录。
- 如果需要多分支并行工作，必须使用当前仓库的正常 Git branch；如确需 worktree，必须先说明原因、限定生命周期，并在任务结束后用 `git worktree remove` 清理。
- 项目根目录只保留仓库入口文档、公开网站资料和非源码管理说明；不要在根目录新增 App 源码副本。

## 命令输出保护

任何输出未知或可能很大的命令都必须限制输出：

```bash
COMMAND 2>&1 | head -c 6000
```

搜索优先用 `rg` / `rg --files`。不要无上限打印大文件、构建日志或目录树。

## 对话记忆保存规则

本项目需要保存重要会话记忆，但不得为了普通会话记录频繁打断用户审批。

- 首选保存目录：项目根目录下的 `.codex-sessionhistory/`，即 `/Users/ar/Projects/Taglauncher/.codex-sessionhistory/`。
- 只在发生以下情况时保存会话记录：关键决策、文件修改、发布 / 构建 / QA 结论、重大问题排查、用户明确要求保存、阶段性收尾。
- 纯询问、路径确认、状态查询、简单说明、无实质决策或无文件变更的对话，不强制保存。
- 文件名格式：`YYYY-MM-DD-主题.md`；主题必须概括本轮 session 的核心内容，控制在 20 个字符以内，优先使用中文短语，避免空格、`/`、`:` 等不适合作为文件名的字符。
- 如果同一天同主题已有记录文件，必须创建新文件并追加序号，避免覆盖：`YYYY-MM-DD-主题-01.md`、`YYYY-MM-DD-主题-02.md`。
- 保存内容至少包括：用户目标、已完成事项、关键决策、文件变更、未决问题、后续建议。
- 如果首选目录在当前沙盒下不可写，不得发起额外权限审批；必须改存到当前 Codex 工作区的 `.codex-sessionhistory/Taglauncher/`，并在最终答复中说明实际保存位置。
- 只有首选目录和当前工作区备用目录都不可写时，才允许跳过保存，并在最终答复中说明原因。
- 如果确需保存，应一次性保存本轮完整摘要，避免为了会话记录反复修正。
- 跨项目对话以主要项目保存；如果多个项目都有实质决策或改动，应按同样的首选目录 / 当前工作区备用目录规则分别保存摘要。
