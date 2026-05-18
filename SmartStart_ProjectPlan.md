# Apptag 7.0 Smart Start Project Plan

## 1. 项目目标

`Smart Start` 是 Apptag 7.0 的核心升级方向。

它要解决的不是“用户不会启动 App”，而是：

> 用户第一次使用 Apptag 时，不想从零开始创建标签、理解分类、手动拖动几十个 App。

目标体验：

1. 用户第一次打开 Apptag。
2. Apptag 扫描本机 App。
3. Apptag 在本地自动整理大部分常见 App。
4. 用户看到一个简单结果：已经整理多少个 App、创建了哪些分类、还有哪些未分类。
5. 用户可以继续编辑、撤销，或者未来选择 `AI Improve` 进一步优化。

## 2. 产品原则

### Local First

第一版必须默认本地完成，不依赖服务器、不上传用户数据、不需要用户注册。

原因：

- 首次体验更快。
- 没有 AI 成本。
- 隐私和 App Store 压力最低。
- 离线也能工作。
- 实现风险更可控。

### Draft First

所有智能分类都先生成“分类草案”，再决定是否应用。

对于全新用户，可以自动应用高置信度结果，但仍要显示摘要和撤销入口。

对于已有用户，默认只展示预览，不静默覆盖现有分类。

### Undo First

任何自动整理动作都必须可撤销。

应用分类前要保留备份快照，至少支持一次撤销。

### Stable IDs

内部分类必须使用稳定 ID，例如：

```text
browser
communication
development
design
utilities
system
```

显示给用户时再本地化为：

```text
浏览器
沟通
开发
设计
工具
系统
```

不要用中文、英文或其他界面显示名称作为内部身份。

## 3. 推荐总体方案

采用方案三：

```text
本地分类库 + 本地规则 + 可选云端 AI Improve
```

### 第一层：本地分类库

内置一个常见 Mac App 分类表。

主匹配字段：

```text
bundleIdentifier
```

辅助匹配字段：

```text
App 名称
安装路径类型
```

例子：

```json
{
  "bundleIdentifier": "com.figma.Desktop",
  "names": ["Figma"],
  "categoryID": "design",
  "confidence": 0.98
}
```

### 第二层：本地启发式规则

用于处理没有进入分类库、但很容易判断的 App。

例子：

```text
/System/Applications/* -> system
Xcode / VS Code / Terminal / GitHub Desktop -> development 或 utilities
Safari / Chrome / Firefox / Edge -> browser
Music / VLC / Spotify -> media
```

本地规则的置信度低于精确 `bundleIdentifier` 匹配。

### 第三层：AI Improve

后续版本再做，不作为第一版依赖。

用户主动点击 `AI Improve` 后，才上传最小必要信息到服务器。

AI 返回的也必须是草案，不直接覆盖本地数据。

## 4. 第一版范围

### 第一版必须做

- 定义稳定分类 ID。
- 创建本地分类库 JSON。
- 先内置一批常见 App 规则，不追求完整。
- 实现本地分类引擎。
- 生成统一的 `SmartCategorizationDraft`。
- 判断用户是否是“全新用户”。
- 对全新用户自动应用高置信度分类。
- 对已有用户只给预览入口，不静默覆盖。
- 应用前创建备份。
- 应用后显示摘要。
- 支持撤销。

### 第一版暂时不做

- 不做服务器。
- 不做 AI Improve。
- 不做远程规则更新。
- 不做账号系统。
- 不上传用户 App 列表。
- 不重写整个数据存储 schema。
- 不追求一次覆盖所有冷门 App。

## 5. 技术模块规划

建议新增目录：

```text
Apptag/SmartCategorization/
```

建议文件：

```text
SmartCategoryCatalog.json
SmartCategory.swift
SmartCategoryCatalog.swift
SmartCategorizationDraft.swift
SmartCategorizer.swift
SmartStartCoordinator.swift
TagBackupService.swift
SmartStartSummaryView.swift
```

### SmartCategory.swift

负责定义稳定分类 ID 和默认显示信息。

核心内容：

```text
SmartCategoryID
SmartCategoryDefinition
默认分类顺序
分类颜色建议
本地化 key
```

### SmartCategoryCatalog.json

内置常见 App 分类表。

第一版可以先从 80-150 个高频 App 开始，验证机制跑通后再扩到 300-800。

### SmartCategoryCatalog.swift

负责读取、校验、查询分类库。

能力：

```text
按 bundleIdentifier 查询
按 normalized app name 查询
校验重复项
校验 categoryID 是否存在
```

### SmartCategorizationDraft.swift

定义统一草案结构。

本地 Smart Start 和未来 AI Improve 都输出这个结构。

核心字段：

```text
source
tags
tagOrder
assignments
unassigned
warnings
confidence
```

### SmartCategorizer.swift

核心分类引擎。

输入：

```text
[AppInfo]
当前 TagDatabase.Store
```

输出：

```text
SmartCategorizationDraft
```

匹配顺序：

1. 精确 bundleIdentifier 匹配。
2. App 名称匹配。
3. 安装路径和系统规则。
4. 关键词规则。
5. 无法判断则进入 unassigned。

### SmartStartCoordinator.swift

负责流程控制。

它不负责具体 UI，也不负责底层分类判断。

能力：

```text
判断是否需要首次 Smart Start
生成草案
决定是否自动应用
调用备份
调用 TagDatabase 保存
生成摘要
记录 Smart Start 已执行
```

### TagBackupService.swift

负责应用智能分类前备份现有数据。

第一版可以做轻量备份：

```text
读取当前 TagDatabase.Store
保存到内存作为 undo snapshot
可选保存到本地 backup json
```

后续再升级成完整备份历史。

### SmartStartSummaryView.swift

负责结果摘要 UI。

显示：

```text
已整理 App 数
已创建分类
未分类 App 数
撤销按钮
继续编辑按钮
未来 AI Improve 入口
```

## 6. 实施阶段

### Phase 0: 合同和安全边界

目标：

先定义数据结构和应用规则，避免后面边做边猜。

任务：

- 定义 `SmartCategoryID`。
- 定义默认分类列表。
- 定义 `SmartCategorizationDraft`。
- 定义自动应用条件。
- 定义已有用户保护规则。
- 定义撤销策略。

验收标准：

- 能在代码里表达分类草案。
- 不接入 UI 也能构造一个合法草案。
- 文档明确什么情况可以自动应用，什么情况必须预览。

### Phase 1: 本地分类库 MVP

目标：

跑通本地分类库机制。

任务：

- 新增 `SmartCategoryCatalog.json`。
- 先录入 80-150 个常见 App。
- 实现 catalog loader。
- 实现 bundleIdentifier 匹配。
- 加入 catalog 校验逻辑。

验收标准：

- 给定一组 `AppInfo`，能匹配出已知 App 的分类。
- JSON 格式错误时不会让 App 崩溃。
- 重复 bundle id 或未知 category id 能被发现。

### Phase 2: 本地分类引擎

目标：

生成完整 Smart Start 草案。

任务：

- 实现 `SmartCategorizer`。
- 加入名称匹配。
- 加入路径规则。
- 加入关键词规则。
- 未命中 App 进入 `unassigned`。
- 为每个 assignment 标记 `confidence` 和 `reason`。

验收标准：

- 同一批 App 输入，每次输出稳定。
- 高置信度分类和低置信度分类可区分。
- 不改变任何真实用户数据，只生成 draft。

### Phase 3: 应用草案、备份、撤销

目标：

让本地草案安全地落到现有 `TagDatabase.Store`。

任务：

- 实现 `TagBackupService`。
- 实现 draft -> existing store 的转换。
- 创建缺失标签。
- 写入 `tagOrder`。
- 写入 `appTags`。
- 不删除用户现有标签。
- 不覆盖已有用户分类，除非用户明确选择。
- 支持撤销到应用前状态。

验收标准：

- 应用前能创建备份。
- 应用后可以撤销。
- 已有用户数据不会被静默覆盖。
- `bash build.sh` 通过。

### Phase 4: 首次启动 Smart Start 流程

目标：

把 Smart Start 接入真实首次使用体验。

任务：

- 判断用户是否已有标签数据。
- 首次扫描完成后生成 Smart Start 草案。
- 全新用户自动应用高置信度结果。
- 记录 `smartStartCompleted`。
- 显示整理结果摘要。
- 给用户继续编辑和撤销入口。

验收标准：

- 新用户首次打开能看到已整理结果。
- 已经使用过的用户不会被自动改动。
- 用户可以撤销自动整理。
- 用户关闭摘要后不会每次重复弹出。

### Phase 5: 预览体验

目标：

让已有用户可以安全尝试 Smart Start。

任务：

- 做 `CategorizationPlanPreviewView` 或轻量 preview。
- 展示即将创建的分类。
- 展示每个分类下将加入的 App 数。
- 展示未分类 App。
- 提供 Apply / Cancel。

验收标准：

- 已有用户能先看再应用。
- 用户可以只应用缺失分类，不强制替换旧布局。

### Phase 6: Catalog 扩展和质量控制

目标：

提高命中率。

任务：

- 把 catalog 扩展到 300-800 个 App。
- 覆盖中英文常见 App。
- 覆盖 Apple 系统 App。
- 覆盖浏览器、开发、设计、办公、媒体、沟通、工具。
- 建立人工 review 表。

验收标准：

- 一台普通办公/创作 Mac 上，常见 App 命中率明显高于空白初始化。
- 分类结果基本符合直觉。
- 没有明显错误分类的高频 App。

### Phase 6A: 候选 App 数据源研究

目标：

建立一个高覆盖的常见 Mac App 候选库，不追求“全球真实使用量绝对排名”，而追求对 Smart Start 有用的高概率覆盖。

数据源分层：

1. Homebrew Cask 安装统计。
   - 价值：真实安装量，适合开发、AI、效率、工具类 App。
   - 偏差：技术用户占比高。
2. Mac App Store 排行榜。
   - 价值：覆盖普通用户、消费类、免费和付费 App。
   - 偏差：缺少大量官网下载/企业分发 App。
3. 设计师图标包和 macOS 图标库。
   - 价值：反映哪些 App 在设计师和重度 Mac 用户心中“足够常见、足够高可见”，值得专门画图标。
   - 可用来源：macOSicons、Replacicon 使用的图标源、DarkOS、Glacier Icons、Adam's MacOS Icons 等。
   - 额外价值：部分图标库自带 category、downloads 或显式分组，可以帮助我们推断默认分类。
   - 偏差：偏审美/重度用户，不能单独当成使用量排名。
4. Curated Mac app lists。
   - 价值：补充编辑推荐和专业工作流。
   - 偏差：主观性强。
5. 人工补充区域性高频 App。
   - 价值：补齐中国、日本、韩国、欧洲等地区常见 App。
   - 偏差：需要人工 review。

候选库字段：

```text
name
normalizedName
bundleIdentifier
categoryCandidates
sources
sourceRanks
iconPackMentions
iconDownloads
regionHints
confidence
reviewStatus
notes
```

合并策略：

- 多个来源都出现的 App 优先级最高。
- Homebrew 高排名 + 图标包高覆盖，优先进入第一版 catalog。
- Mac App Store 高排名但 Homebrew 不出现，仍要纳入普通用户覆盖。
- 图标包出现但没有排名数据，作为“值得人工 review”的候选。
- 中国/亚洲高频 App 即使全球英文榜不高，也要人工加入。

### Phase 7: AI Improve 预研

目标：

为后续云端增强预留接口，不阻塞本地 MVP。

任务：

- 复用 `SmartCategorizationDraft`。
- 设计 `AICategorizationClient` 接口，但可以先不实现网络。
- 定义上传字段。
- 定义隐私文案。
- 定义服务端返回 schema。

验收标准：

- 本地 Smart Start 和未来 AI Improve 使用同一种草案结构。
- 加 AI 时不需要推翻本地架构。

## 7. 自动应用规则

### 可以自动应用

满足全部条件时可以自动应用：

- 用户没有明显现有分类数据。
- Smart Start 从未执行过。
- assignment 置信度达到阈值，例如 `>= 0.85`。
- 分类来自 bundleIdentifier 精确匹配或强规则。
- 应用前已创建 backup snapshot。

### 必须预览，不自动应用

出现任一情况时必须预览：

- 用户已有自定义标签。
- 用户已有 appTags。
- assignment 置信度较低。
- 分类来自模糊名称或关键词。
- 需要替换或删除现有分类。

## 8. 初始分类建议

第一版稳定分类 ID：

```text
browser
communication
productivity
development
design
writing
media
utilities
system
entertainment
finance
education
ai-tools
security
other
```

可以先不做太细。分类越细，越容易错。

宁可第一版分类少而准。

## 9. 风险清单

### 风险 1：分类不符合用户习惯

缓解：

- 用宽分类。
- 支持撤销。
- 支持手动编辑。
- 不对已有用户自动覆盖。

### 风险 2：本地 catalog 覆盖不够

缓解：

- 先覆盖高频 App。
- 未命中就保留未分类，不强行猜。
- 后续持续扩展 catalog。

### 风险 3：现有数据结构用 tag name 做身份

缓解：

- Smart Start 内部先用 stable category ID。
- 应用到旧 store 时再映射为本地化或默认显示名。
- 后续 store v2 再彻底迁移到 stable tag IDs。

### 风险 4：首次体验等待过久

缓解：

- 分类逻辑必须轻量。
- 不在 first-run 调用云端。
- 分类库加载只做一次。
- UI 显示明确进度和结果。

### 风险 5：用户不信任自动整理

缓解：

- 显示摘要。
- 显示撤销。
- 不隐藏未分类。
- 不说“AI 已经替你决定”，而说“已为你准备一个初始整理方案”。

## 10. 验收指标

第一版 Smart Start 可以用这些指标判断是否成功：

- 全新用户首次启动后，不再看到完全空白/混乱的分类状态。
- 常见 App 能被自动放入合理分类。
- 用户能一键撤销。
- 现有用户不会被静默改动。
- 没有云端依赖。
- 构建通过。
- 分类库格式错误不会导致 App 崩溃。

## 11. 推荐下一步

下一步不要先做 UI。

最合理的第一项开发任务是：

```text
任务 3：建立 Smart Start 数据合同
```

具体内容：

1. 新建 `Apptag/SmartCategorization/`。
2. 新建 `SmartCategory.swift`。
3. 定义 `SmartCategoryID` 和默认分类。
4. 新建 `SmartCategorizationDraft.swift`。
5. 定义 draft 数据结构。
6. 保证 `bash build.sh` 通过。

这一步完成后，Architect 可以审查分类身份是否稳定，Designer 可以围绕 draft 设计预览体验，Coder 可以继续做本地 catalog loader。
