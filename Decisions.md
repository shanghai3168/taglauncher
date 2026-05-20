项目决策记录（DECISIONS.md）
由 Hermes Agent 自动维护，用于记录每个版本的需求背景和决策过程。

## 2026-05-20 — 工作流程规范收口为单一权威文档

- 新增唯一权威流程文档：`Docs/ProjectManagement/Apptag_Development_Workflow_Standard_v1.0.md`。
- 该文档统一收口项目级工作流程、文档更新责任、QA 门槛、版本管理、构建规则、发布门槛与冲突处理规则。
- `.hermes.md` 现在只作为入口指针，不再单独维护散落的流程规则。
- 明确将“build 过程不得回写受版本控制的源码文件”升级为硬性规则。
- 当前 `build.sh` 回写 `Apptag/Info.plist` 的做法被定义为流程缺陷；治本要求是只改产物中的 `Info.plist`，不改仓库工作区。
- 后续任何 coder（包括 AI coder）如果收到与流程规范冲突的指令，必须指出违反的具体条款，而不能静默执行。
- 已在 `build.sh` 落地第一步修复：打包时先复制源码 `Info.plist` 到 `.app` 包内，再只修改产物中的 `CFBundleVersion`。
- 验收结果：`build/TagLauncher.app/Contents/Info.plist` 的 `CFBundleVersion` 可独立刷新，而源码 `Apptag/Info.plist` 在构建后保持不变。

## 2026-05-10 — 无色容器交互锁定

- 「无色容器」是 App 列表第 2 种视图样式，对应 `displayMode == "container"`。
- 固定交互：hover 标签或对应容器区域时，容器保持标签色填充；鼠标移开后不自动清除。
- 清除方式：再次点击同一标签，或点击对应容器内部空白处。
- 后续迭代新增/修改其他样式时，不应改变以上无色容器交互逻辑；「彩色容器」应使用独立交互状态。
