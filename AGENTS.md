# AGENTS.md - Taglauncher Agent 入口

## 项目属性

项目类型：研发项目
主要产物：macOS App / 桌面工具

这是 AI Agent 进入 `/Users/ar/Projects/Taglauncher` 后应先读的入口文件。

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

本项目必须严格执行对话记忆保存。

- 保存根目录：`/Users/ar/Projects/X-sessionhistory/Taglauncher/`
- 每一轮与 Taglauncher 有关的实质对话 / 决策 / 文件修改 / 排查过程，都必须保存为一个独立 Markdown 文件。
- 文件名格式：`YYYY-MM-DD-主题.md`。
- 主题必须概括本轮 session 的核心内容，控制在 20 个字符以内，优先使用中文短语，避免空格、`/`、`:` 等不适合作为文件名的字符。
- 如果同一天同主题已有记录文件，必须创建新文件并追加序号，避免覆盖：`YYYY-MM-DD-主题-01.md`、`YYYY-MM-DD-主题-02.md`。
- 保存内容至少包括：用户目标、已完成事项、关键决策、文件变更、未决问题、后续建议。
- 在最终答复用户前，必须完成本轮会话记录保存；如果因为权限、路径或上下文不足无法保存，必须在最终答复中明确说明。
- 跨项目对话以主要项目保存；如果多个项目都有实质决策或改动，应分别在对应项目文件夹保存摘要，或保存到 `/Users/ar/Projects/X-sessionhistory/_CrossProject/`。
