# AGENTS.md - Taglauncher Agent 入口

## 项目属性

项目类型：研发项目
主要产物：macOS App

## 项目规则

- 默认遵守 `/Users/ar/.codex/AGENTS.md`；项目本地文档、脚本和 release 规则优先。
- 发布、分发或验证安装包前，必须读取并遵守 `~/.codex/rules/release-versioning.md`。
- 可分发构建应先运行 `./build.sh` 生成 `.app`，再运行 `./make_dmg.sh` 生成 `.dmg`；只生成 `.app` 只能视为本地 QA 构建。
- 版本、build 编号、`CHANGELOG.md`、`Release/` 资料和最终安装包文件必须保持一致。
