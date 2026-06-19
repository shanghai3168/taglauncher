# Apple 默认备注多语种迁移修复工作日志

## 2026-06-19 21:30

### 起点

- 当前分支：`codex/appgrid-usage-tips`
- 当前 HEAD：`50e354e Revert "Refine app grid material background"`
- 当前源码版本：`7.9.2 / 20260617.2028`
- 工作区存在历史脏文件与上一轮 usage tips 未提交改动；本轮只处理 Apple 默认备注相关文件、QA、版本和 changelog。

### 根因结论

- Apple 默认备注资源本身已有多语种，ColorSync 的阿拉伯语备注是阿拉伯语。
- 气泡展示的是持久化 `TagDatabase.Store.appNotes[path]`，不是运行时 `tr()` 文案。
- 旧版本写入了中文 Apple 默认备注，但没有 `appNoteMetadata.origin = appleDefault`。
- 当前重本地化逻辑只覆盖 `.appleDefault` 且 fingerprint 匹配的记录，因此无 metadata 的旧中文默认备注会被当作可能的用户手写备注保留。

### 本机复现证据

- `/Users/ar/Library/Application Support/TagLauncher/tags.json`
- `/System/Applications/Utilities/ColorSync Utility.app`
  - note：`查看和修复色彩配置文件，处理显示和打印色差。`
  - metadata：`None`

### 设计原则

- 不用“是否包含中文”判断旧默认备注，避免误伤用户手写中文。
- 仅当当前备注 fingerprint 精确匹配同 bundle 的已知 Apple 默认备注集合时，才迁移为 `.appleDefault`。
- `origin == manual` 和手动清空备注必须保留。
- 迁移后写入当前语言的 Apple 默认备注，并更新 Apple provenance/fingerprint。

## 2026-06-19 21:42

### 已完成实现

- `AppleDefaultAppCatalog.relocalizeDefaultNotesForCurrentLanguage` 增加旧默认备注识别：
  - `.appleDefault` 继续要求当前 fingerprint 匹配 metadata，或匹配同 bundle 已知 Apple 默认备注集合。
  - `.catalogDefault` / 无 metadata 只有在当前备注匹配同 bundle Apple 默认备注集合时才迁移。
  - `.manual` 和手动清空备注保持跳过，不覆盖。
- 迁移旧默认备注前调用 `TagDatabase.backup(originalStore, reason: "apple-default-note-migration")`。
- 已知 Apple 默认备注集合包含 29 语种资源，并兼容历史句末 `.` / `。` 变体。
- 补齐 `com.apple.campo`：
  - `AppleDefaultApps.base.json`
  - `AppleDefaultApps.translations.json`
  - 29 个 `AppleDefaultApps.localizations.<lang>.json`
  - `AppleDefaultApps.source.csv`
- 新增 `Scripts/apple_default_note_migration_qa.sh`，并加固 `Scripts/apple_default_note_policy_qa.sh`。
- 更新 `CHANGELOG.md` 与 `Apptag/Info.plist` 到 `7.9.3 / 20260619.2142`。

### QA 自查

- `bash Scripts/apple_default_note_migration_qa.sh`：PASS
- `bash Scripts/apple_default_note_policy_qa.sh`：PASS
- `bash Scripts/apple_default_apps_resource_qa.sh`：PASS
- `bash Scripts/smartstart_catalog_resource_qa.sh`：PASS
- `bash Scripts/usage_tips_qa.sh`：PASS
- `bash Scripts/macos14_availability_typecheck_qa.sh`：PASS
- `APP_BUILD=20260619.2142 bash build.sh`：PASS，生成 `/Users/ar/Projects/Taglauncher/src/build/TagLauncher.app`
- `bash Scripts/macos14_build_metadata_qa.sh`：PASS
- `codesign --verify --deep --strict --verbose=2 build/TagLauncher.app`：PASS

### QA 结论

- 本轮修复只按同 bundle 的 Apple 默认备注 fingerprint 迁移旧数据，不按中文字符判断。
- Arabic 等非中文语言资源中 Apple 默认备注保持本地语言；旧中文默认备注会迁移到当前语言。
- 用户手写备注和手动清空备注仍由 `.manual` metadata 保护，不会被本轮迁移覆盖。
