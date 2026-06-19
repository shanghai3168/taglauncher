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
| 构建 | `APP_BUILD=20260619.2142 bash build.sh` | PASS |
| 构建 metadata | `bash Scripts/macos14_build_metadata_qa.sh` | PASS |
| 签名验证 | `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app` | PASS |

## 覆盖的关键场景

- `com.apple.colorsyncutility` 的旧中文默认备注带历史句号 `。`，无 metadata，能被识别为 Apple 默认备注。
- 同样的备注 fingerprint 只在同 bundle 范围内生效，不能跨 bundle 误匹配。
- 用户追加内容后的中文备注不匹配 Apple 默认备注集合，不会被迁移。
- `com.apple.campo` 在 base、translations 和每个 localization 文件中都存在。
- 产物版本与源码版本一致：`7.9.3 / 20260619.2142`。

## 结论

本轮修复满足发布前自查要求。自动化未发现 Apple 默认备注迁移、资源完整性、macOS 14 构建 metadata 或签名问题。
