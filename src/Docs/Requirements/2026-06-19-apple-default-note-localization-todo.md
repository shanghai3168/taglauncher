# Apple 默认备注多语种迁移修复 TODO

## 目标

- 修复切换到非中文语言后，Apple 自带应用默认备注仍显示中文的问题。
- 保护用户手写备注和手动清空备注，不因语言切换被覆盖。
- 补齐当前系统扫描到但 Apple catalog 缺失的 `com.apple.campo`。
- 补充自动化 QA，覆盖旧中文默认备注迁移、手动备注保护、资源完整性。

## 范围

- 修改 Apple 默认备注 catalog / 迁移 / 重本地化逻辑。
- 修改 Apple 默认备注相关 QA。
- 更新版本号与 changelog。
- 不修改 App Grid 视觉、使用技巧交互、标签拖拽、SmartStart 分类策略。

## TODO

- [x] 读取现有 Apple 默认备注链路与用户库复现证据
- [x] 补齐 `com.apple.campo` Apple catalog base/translations/29 语种 localizations
- [x] 增加旧 Apple 默认备注识别与迁移逻辑
- [x] 补充动态 QA：旧中文默认备注无 metadata 时能迁移到当前语言
- [x] 补充 QA：手写备注与手动清空备注不被覆盖
- [x] 跑资源 QA、Apple 默认备注策略 QA、SmartStart 边界 QA
- [x] 跑 macOS 14 typecheck 与构建验证
- [x] 更新 `CHANGELOG.md`、`Info.plist`
- [x] 保存工作日志与最终 QA 证据

## 完成标准

- 旧版本持久化的 Apple 默认备注，即使没有 metadata，也能在语言切换或启动重本地化时迁移到当前语言。
- 用户手写备注、手动清空备注和非 Apple 默认备注不被覆盖。
- `com.apple.campo` 在 Apple 默认应用目录、translations 和 29 个语种 localizations 中完整存在。
- `7.9.3 / 20260619.2142` 构建产物通过 macOS 14 metadata 和签名检查。
