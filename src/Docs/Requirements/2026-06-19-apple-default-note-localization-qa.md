# Apple 默认备注多语种迁移 QA 自查

## 测试目标

- 验证旧版本写入、但没有 metadata 的 Apple 默认备注可以迁移到当前语言。
- 验证用户手写备注和手动清空备注不被覆盖。
- 验证 Apple 默认应用资源在 29 个语种中完整，尤其补齐 `com.apple.campo`。
- 验证本轮源码可以通过 macOS 14 typecheck、构建和签名检查。

## 自动化结果

| 检查项 | 命令 | 结果 |
| --- | --- | --- |
| 旧默认备注迁移 fixture | `bash Scripts/apple_default_note_migration_qa.sh` | PASS |
| Apple 默认备注策略边界 | `bash Scripts/apple_default_note_policy_qa.sh` | PASS |
| Apple 默认应用资源完整性 | `bash Scripts/apple_default_apps_resource_qa.sh` | PASS |
| SmartStart 资源边界 | `bash Scripts/smartstart_catalog_resource_qa.sh` | PASS |
| 使用技巧回归 | `bash Scripts/usage_tips_qa.sh` | PASS |
| macOS 14 typecheck | `bash Scripts/macos14_availability_typecheck_qa.sh` | PASS |
| 真实用户库只读模拟 | Python 读取当前 `tags.json`，模拟 `ms/ja/ar/en` 迁移 | PASS |
| 构建 | `APP_BUILD=20260619.2221 bash build.sh` | PASS |
| 构建 metadata | `bash Scripts/macos14_build_metadata_qa.sh` | PASS |
| 签名验证 | `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app` | PASS |
| DMG | `bash make_dmg.sh` + `hdiutil verify build/TagLauncher.dmg` | PASS |

## 7.9.3 漏测复盘

- 漏测现象：Chess、TV、Phone、Freeform、Music、Time Machine 等旧版本初始化备注在切换到非中文语言后仍显示中文。
- 漏测原因：上一版迁移 QA 只覆盖了 ColorSync 的旧中文默认备注和句末标点变体，没有覆盖 7.9 之前另一批已经写入用户库的历史默认文案。
- 修正后的 QA 原则：Apple 自带应用备注属于初始化内容，任何语种资源中都不允许出现其他语种正文；真实迁移 fixture 必须覆盖已知历史默认备注，而不是只测一个样本。

## 覆盖的关键场景

- `com.apple.colorsyncutility` 的旧中文默认备注带历史句号 `。`，无 metadata，能被识别为 Apple 默认备注。
- Chess、TV、Phone、Freeform、Music、Time Machine、Home、Passwords、Disk Utility、iPhone Mirroring 的历史中文默认备注无 metadata 时，能被识别为 Apple 默认备注。
- 对当前真实 `tags.json` 做只读模拟：上述 10 条 stale Apple 备注在 `ms`、`ja`、`ar`、`en` 下都会迁移到目标语种，不保留旧中文。
- 同样的备注 fingerprint 只在同 bundle 范围内生效，不能跨 bundle 误匹配。
- 用户追加内容后的中文备注不匹配 Apple 默认备注集合，不会被迁移。
- 29 个语种的 Apple 初始化备注均执行跨语种脚本污染检查，translations 和 localizations 任一失败都会阻断发布。
- `com.apple.campo` 在 base、translations 和每个 localization 文件中都存在。
- 产物版本与源码版本一致：`7.9.4 / 20260619.2221`。
- DMG：`/Users/ar/Projects/Taglauncher/src/build/TagLauncher.dmg`
- DMG SHA256：`e6a5b2d1aab96cfd8e8a09edda7ae64b0319c044c2517ad9527887f020507d41`

## 结论

本轮修复满足发布前自查要求。自动化未发现 Apple 默认备注迁移、跨语种资源污染、macOS 14 构建 metadata 或签名问题。
