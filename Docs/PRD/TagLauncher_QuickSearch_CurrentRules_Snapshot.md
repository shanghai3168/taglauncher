# TagLauncher 当前 Quick Search 规则快照

状态：当前代码实现备份  
用途：在后续调整 Quick Search / 快速建议规则前，保存当前行为，便于回看、对照或恢复  
生成日期：2026-05-20  
主要代码来源：

- `Apptag/QuickSearch.swift`
- `Apptag/ContentView.swift`
- `Apptag/ApptagApp.swift`
- `Apptag/PreferencesView.swift`
- `Apptag/AppDefaults.swift`
- `Apptag/DataLayer.swift`

## 1. 当前能力总览

当前代码中的 Quick Search 已经包含以下能力：

- 主界面内按空格打开 Quick Search。
- 可配置一个全局 Quick Search 快捷键。
- Quick Search 打开后显示浮层输入框。
- 查询为空时显示默认建议列表。
- 输入查询后按应用名称、标签、备注、包标识搜索。
- 支持精确匹配、前缀匹配、子串匹配、缩写匹配、模糊子序列匹配。
- 支持中文拼音候选匹配。
- 支持键盘上下选择、回车启动、Esc 关闭。
- 启动成功后记录启动次数和最近启动时间。

## 2. 快捷键规则

### 2.1 主界面快捷键

当前默认主界面快捷键：

```text
⇧ ⌥ Space
Shift + Option + Space
```

代码定义：

```swift
static var defaultMain: LauncherHotkey {
    LauncherHotkey(keyCode: UInt32(kVK_Space), modifiers: UInt32(shiftKey | optionKey))
}
```

当前行为：

- 主界面快捷键始终返回默认值。
- 设置页中主界面快捷键展示为一项设置，但当前不允许用户编辑。

### 2.2 主界面内 Quick Search 快捷键

当前主界面内快捷键：

```text
Space
```

触发条件：

- 按下的是空格键。
- 不是按键重复事件。
- 没有任何修饰键。
- 主界面窗口当前可见。
- Quick Search 当前未打开。
- 不在编辑模式。
- 不在应用备注编辑状态。
- 没有 modal interaction。
- 当前焦点不在文本输入控件中。
- 当前焦点不在会处理空格的控件中，例如按钮、分段控件、滑块。

代码判断逻辑位于 `Apptag/ApptagApp.swift` 的 `shouldOpenQuickSearch(for:)`。

### 2.3 全局 Quick Search 快捷键

当前默认全局 Quick Search 快捷键：

```text
Fn + Space
```

代码定义：

```swift
static var defaultQuickSearch: LauncherHotkey {
    LauncherHotkey(keyCode: UInt32(kVK_Space), modifiers: UInt32(kEventKeyModifierFnMask))
}
```

当前行为：

- 如果用户没有保存过 Quick Search 全局快捷键，默认返回 `Fn + Space`。
- AppDefaults 迁移逻辑会在没有存储值时写入默认 `Fn + Space`。
- 设置页允许用户修改全局 Quick Search 快捷键。
- 设置页允许恢复默认全局 Quick Search 快捷键，也就是恢复为 `Fn + Space`。

### 2.4 全局快捷键触发行为

全局 Quick Search 快捷键触发后：

- 如果主界面窗口已经可见，则不执行任何动作。
- 如果主界面窗口不可见，则打开主界面，并以 Quick Search 模式进入。
- 这种入口会设置 `quickSearchCloseHidesOverlay = true`。
- 当用户关闭 Quick Search 时，主界面也会一起隐藏。

代码行为：

```swift
private func showQuickSearchFromGlobalHotkey() {
    guard overlayWindow?.isVisible != true else { return }
    showOverlay(initialQuickSearchSource: QuickSearchOpenSource.globalHidden)
}
```

## 3. 快捷键设置和冲突处理

### 3.1 快捷键注册方式

当前使用 Carbon `RegisterEventHotKey` 注册全局快捷键。

注册成功：

- 保存快捷键。
- 状态设置为 `Active`。
- 清除 pending 快捷键。
- 清除冲突信息。

注册失败：

- 保留之前可用的快捷键引用。
- 保存用户刚录入但注册失败的 pending 快捷键。
- 状态设置为 `Conflict`。
- 写入冲突文案。

### 3.2 当前快捷键状态

当前支持三种状态：

```text
Active
Conflict
Disabled
```

设置页展示逻辑：

- 正常时显示当前 active 快捷键。
- 冲突时显示 pending 快捷键，并标记为 blocked。
- 如果之前有可用快捷键，冲突说明中会提示“之前可用的快捷键仍保持可用”。

### 3.3 已知冲突文案

当前代码对以下快捷键有特殊冲突文案：

| 快捷键 | 文案含义 |
|---|---|
| `⌘ Space` | Spotlight 冲突 |
| `⌥ ⌘ Space` | Finder 搜索窗口冲突 |
| `⌃ Space` | 上一个输入法冲突 |
| `⌃ ⌥ Space` | 下一个输入法冲突 |
| `⌃ ⌘ Space` | 表情与符号冲突 |
| `Fn + Space` | Fn / Globe / 输入法相关冲突 |

其他冲突使用 generic 文案：

```text
This shortcut is already used by macOS or another app.
Choose another shortcut, or change the shortcut in the other app and retry.
```

### 3.4 快捷键录制规则

录制快捷键时：

- 按 `Esc` 取消录制。
- 纯修饰键不会被接受。
- 至少要包含一个修饰键。
- 支持 `Shift`、`Option`、`Control`、`Command`、`Fn`。
- 会忽略单独的修饰键 keyCode。
- 捕获到合法快捷键后立即尝试注册。

## 4. Quick Search 打开和关闭规则

### 4.1 打开规则

Quick Search 打开时：

- 必须通过 `canOpenQuickSearch` 判断。
- 会关闭应用备注气泡。
- 会清空查询。
- 会清除手动选择状态。
- 会清除错误信息。
- 会增加 focus token，使输入框获得焦点。
- 会立即刷新搜索结果。
- 会发送 Quick Search 可见状态通知。

`canOpenQuickSearch` 条件：

- 不在编辑模式。
- 没有未处理的 Uncategorized drop。
- 没有 Smart Start notice。
- 没有 drop refresh loading。
- Quick Search 当前未打开。

### 4.2 关闭规则

Quick Search 关闭时：

- 设置 `quickSearchVisible = false`。
- 清空查询。
- 清空结果。
- 清空选中项。
- 清除手动选择状态。
- 清除错误信息。
- 重置 `quickSearchCloseHidesOverlay`。
- 发送 Quick Search 可见状态通知。

如果 Quick Search 是通过全局快捷键在隐藏主界面时直接打开的：

- 关闭 Quick Search 时会隐藏主界面。

### 4.3 Esc 和点击背景

当前行为：

- Quick Search 输入框内按 `Esc` 会关闭 Quick Search。
- 主界面的本地键盘监听中，如果 Quick Search 已打开，按 `Esc` 会关闭 Quick Search。
- 点击 Quick Search 背景层会关闭 Quick Search。

## 5. 搜索索引规则

当前每个应用会生成一个 `QuickSearchDocument`。

文档字段：

```text
app
localizedNames
tagNames
note
bundleIdentifier
lastOpenedAt
openCount
```

字段来源：

- `app` 来自扫描并经过 TagEditor 标注后的应用。
- `localizedNames` 从应用 Bundle 中读取本地化名称、Bundle 名称和 Finder 展示名。
- `tagNames` 来自应用当前标签。
- `note` 优先使用 `store.appNotes[path]`，其次使用 `app.note`，最后为空字符串。
- `bundleIdentifier` 来自应用包标识，没有则为空字符串。
- `lastOpenedAt` 来自 `store.appLastOpenedAt[path]`。
- `openCount` 来自 `store.appOpenCounts[path]`，没有则为 0。

搜索索引刷新时机：

- 应用扫描完成后生成。
- 数据变化后刷新应用并重新生成。
- 语言变化后刷新应用并重新生成。
- 如果 Quick Search 正在打开，刷新完成后会重新计算结果。

## 6. 查询标准化规则

查询标准化：

- 去掉首尾空白和换行。
- 合并连续空白为单个空格。
- 大小写不敏感。
- 去除音调和变音符号。
- 转为小写。

如果标准化后的查询为空：

- 进入空查询建议规则。

如果标准化后的查询不为空：

- 按空格切分为多个 token。
- 每个 token 都必须在同一个应用的某个字段中匹配成功。
- 任何 token 找不到匹配，该应用就不会进入结果。

## 7. 搜索字段和权重

当前搜索字段：

| 字段 | 权重 |
|---|---:|
| 应用名称 / 本地化名称 | 100 |
| 标签名称 | 70 |
| 应用备注 | 45 |
| 包标识 | 20 |

字段优先级也会用于排序：

```text
应用名称优先于标签
标签优先于备注
备注优先于包标识
```

## 8. 匹配类型和权重

当前支持的匹配类型：

| 匹配类型 | 权重 |
|---|---:|
| 精确匹配 | 100 |
| 前缀匹配 | 80 |
| 子串匹配 | 60 |
| 缩写匹配 | 55 |
| 模糊子序列匹配 | 35 |

### 8.1 精确匹配

字段标准化文本与 token 完全相等。

### 8.2 前缀匹配

字段标准化文本以 token 开头。

### 8.3 子串匹配

字段标准化文本包含 token。

### 8.4 缩写匹配

仅应用名称字段支持缩写匹配。

缩写生成规则：

- 单词开头字符进入缩写。
- 非字母数字字符会开启下一个单词。
- 小写字符后跟大写字符时，大写字符会作为新词开头。

示例：

```text
Google Chrome -> gc
Final Cut Pro -> fcp
```

当前缩写匹配要求：

```text
应用名称缩写必须以 token 开头。
```

### 8.5 模糊子序列匹配

当 token 长度至少为 2 时，支持非连续字符子序列匹配。

示例：

```text
ps 可以匹配 Photoshop
```

### 8.6 位置加分

非精确匹配有位置加分：

```text
positionBoost = max(0, 10 - min(matchStartIndex, 10))
```

含义：

- 越靠前命中，分数越高。
- 最高位置加分为 10。
- 精确匹配没有位置加分。

单个 token 在单个字段上的分数：

```text
字段权重 + 匹配类型权重 + 位置加分
```

## 9. 中文和拼音匹配规则

当前代码对包含汉字的字段生成拼音候选。

拼音候选生成规则：

1. 对包含汉字的文本执行 `kCFStringTransformToLatin`。
2. 去掉声调。
3. 标准化并小写。
4. 按非字母数字字符切分后重新用空格连接。
5. 生成三个候选：
   - 带空格拼音。
   - 去掉空格的紧凑拼音。
   - 拼音首字母。

示例：

```text
微信 -> wei xin / weixin / wx
```

拼音候选参与普通匹配流程：

- 精确匹配。
- 前缀匹配。
- 子串匹配。
- 模糊子序列匹配。

应用名称、标签、备注都可以生成拼音候选。

包标识不生成拼音候选。

## 10. 搜索结果打分规则

对于非空查询：

1. 将查询拆成多个 token。
2. 每个 token 在所有字段中寻找最高分匹配。
3. 所有 token 的最高匹配分相加，得到 `textScore`。
4. 加上行为加分，得到 `finalScore`。

公式：

```text
finalScore = textScore + behaviorBoost
```

行为加分最高为 20：

```text
behaviorBoost = min(recentBoost + frequencyBoost, 20)
```

最近启动加分：

| 最近启动时间 | 加分 |
|---|---:|
| 24 小时内 | 15 |
| 7 天内 | 10 |
| 30 天内 | 5 |
| 更早 | 2 |
| 从未启动 | 0 |

启动频率加分：

```text
frequencyBoost = min(openCount, 10)
```

说明：

- 当前实现只有总启动次数 `openCount`，没有 7 天 / 30 天分窗口。
- 行为加分是弱加分，最高只影响 20 分。

## 11. 非空查询排序规则

搜索结果排序规则：

1. `finalScore` 高的排前面。
2. `textScore` 高的排前面。
3. 最好命中的字段优先级更高的排前面。
4. 最近启动时间更近的排前面。
5. 启动次数更多的排前面。
6. 应用名称更短的排前面。
7. 应用名称按本地化标准排序。

默认返回结果上限：

```text
50
```

## 12. 空查询建议规则

当查询为空时，当前代码调用：

```swift
emptyQueryResults(documents: documents, limit: min(limit, 6))
```

也就是说，空查询最多显示 6 个结果。

### 12.1 候选来源

空查询只使用两类候选：

1. 有最近启动时间的应用。
2. 启动次数大于 0 的应用。

不会使用：

- 当前标签上下文。
- Smart Start 分类。
- 冷启动推荐。
- 应用名称字母兜底。
- 固定项。
- 随机应用。

### 12.2 最近启动列表

最近启动列表规则：

- 只包含 `lastOpenedAt != nil` 的应用。
- 按最近启动时间倒序排序。
- 最近启动时间相同时，按应用名称本地化标准升序排序。

### 12.3 高频启动列表

高频启动列表规则：

- 只包含 `openCount > 0` 的应用。
- 按总启动次数倒序排序。
- 启动次数相同时，按应用名称本地化标准升序排序。

### 12.4 合并和去重

空查询建议的合并规则：

```text
ordered = recent + frequent
```

然后按应用 URL 去重：

- 最近启动列表排在高频启动列表前面。
- 同一个应用如果同时在 recent 和 frequent 中，只保留 recent 中的位置。
- 去重后取前 6 个。

### 12.5 空查询结果分数

空查询结果的 `finalScore` 使用行为加分：

```text
finalScore = behaviorBoost
textScore = 0
bestFieldRank = Int.max
matchedTagName = nil
noteSnippet = nil
```

但由于空查询结果已经在 `emptyQueryResults` 内部按 recent + frequent 排好，后续没有再调用通用 rank 排序。

### 12.6 当前空查询的实际特点

当前空查询建议可以概括为：

```text
优先最近启动。
最近启动不足时，用总启动次数补充。
最多 6 个。
没有历史时为空。
```

## 13. 结果行展示规则

每个结果行展示：

- 应用图标。
- 应用名称。
- 一行详情文本，如果存在。
- 右侧标签胶囊，如果存在。

### 13.1 图标

图标尺寸：

```text
46 × 46
```

圆角：

```text
10
```

### 13.2 应用名称

应用名称：

- 字号 20。
- semibold。
- 单行显示。
- 超出尾部截断。

### 13.3 详情文本

详情文本优先级：

1. 如果本次匹配产生了 `noteSnippet`，显示 `noteSnippet`。
2. 否则显示完整应用备注的截断版本。
3. 如果没有备注，则不显示详情文本。

备注截断规则：

- 如果备注长度大于 72，则取前 69 个字符并加 `...`。
- `noteSnippet` 如果原备注长度大于 80，则取前 77 个字符并加 `...`。

当前行为说明：

- 即使空查询建议没有匹配备注，也会显示应用已有备注。
- 如果应用没有备注，不会用标签替代显示在详情文本位置。

### 13.4 右侧标签

右侧标签取值：

```text
matchedTagName ?? document.tagNames.first
```

含义：

- 如果查询命中了某个标签，显示命中的标签。
- 否则显示应用的第一个标签。
- 如果没有标签，则不显示右侧标签。

标签样式：

- 字号 14。
- semibold。
- 胶囊背景。
- 最大宽度 128。
- 单行截断。

## 14. 面板视觉和布局规则

Quick Search 面板：

- 宽度固定为 760。
- 背景为 `.regularMaterial`。
- 圆角为 34。
- 阴影为黑色 0.18，不透明度，半径 36，y 偏移 18。
- 边框为主色 0.10，不透明度，线宽 1。

输入区域：

- 左侧显示放大镜图标。
- 输入框字体大小为 28。
- 输入框高度为 44。
- 横向内边距为 28。
- 顶部内边距为 22。
- 底部内边距为 18。

结果行：

- 行高为 74。
- 行间距为 2。
- 列表外部上下内边距为 10。
- 列表外部左右内边距为 10。

选中态：

- 深色模式：白色 0.14 不透明度。
- 浅色模式：黑色 0.075 不透明度。
- 选中背景圆角为 18。

### 14.1 面板位置

面板水平居中。

顶部位置：

```text
max(notchHeight + 54, min(112, windowHeight * 0.12))
```

面板中心点根据估算高度计算：

```text
estimatedPanelHeight = visibleRows * 76 + 122
panelCenterY = panelTopY + estimatedPanelHeight / 2
```

### 14.2 最大可见行数

最大可见行数根据窗口高度动态计算：

```text
availableHeight = windowHeight - panelTopY - 84 - 122
maxVisibleRows = max(1, min(8, floor(availableHeight / 76)))
```

含义：

- 最多显示 8 行。
- 至少显示 1 行。
- 结果数超过可见行数时显示垂直滚动条。

注意：

- 空查询搜索引擎最多只返回 6 个。
- 非空查询最多返回 50 个，但界面最多同时显示 8 行。

## 15. 选择和导航规则

结果刷新后：

- 如果没有结果，清空选中项，并清除手动选择状态。
- 如果用户此前手动选择过某项，并且该项仍在新结果中，则保留选择。
- 否则选择第一项。

键盘行为：

| 按键 | 行为 |
|---|---|
| `↑` | 选择上一项 |
| `↓` | 选择下一项 |
| `Enter` | 打开选中应用 |
| `Esc` | 关闭 Quick Search |

上下移动规则：

- 不循环。
- 到第一项后继续上移仍停留在第一项。
- 到最后一项后继续下移仍停留在最后一项。

鼠标行为：

- 悬停某个结果时，将该结果设为选中项。
- 点击某个结果时，启动该应用。

## 16. 启动行为和历史记录

### 16.1 启动成功

从 Quick Search 启动应用成功后：

- 异步记录启动历史。
- 关闭 Quick Search。
- 隐藏主界面。

记录的历史：

```text
appOpenCounts[path] += 1
appLastOpenedAt[path] = Date()
```

### 16.2 启动失败

从 Quick Search 启动应用失败后：

- 不关闭 Quick Search。
- 不隐藏主界面。
- 显示错误文案。
- 重新聚焦输入框。
- 发送无障碍 announcement。
- 不记录启动历史。

错误文案 key：

```text
quickSearch.launchFailed
```

### 16.3 和 Uncommon 自动规则的关系

记录启动历史时，如果应用的 uncommon 来源是自动标记，并且启动次数达到自动阈值：

- 从 uncommon 应用列表移除。
- 移除 uncommon 自动来源。

这部分逻辑位于 `TagEditor.recordLauncherOpen(for:)`。

## 17. 当前实现没有的规则

以下是当前代码没有实现、但后续新方案可能会加入的规则：

- 空查询时基于当前标签加权。
- 空查询时基于 Smart Start 分类冷启动。
- 空查询时应用名称字母排序兜底。
- 空查询时固定显示高价值分类应用。
- 空查询时手动固定建议项。
- 7 天启动次数和 30 天启动次数分开统计。
- 空查询建议的明确分数表。
- 空查询建议列表固定不随窗口高度变化。
- 主界面全局快捷键可编辑。

## 18. 恢复当前规则时的关键点

如果后续新规则出问题，需要恢复当前行为，重点恢复以下代码逻辑：

1. 全局 Quick Search 默认快捷键恢复为 `Fn + Space`。
2. 空查询逻辑恢复为 `emptyQueryResults(documents:limit:)`：
   - 先取最近启动应用。
   - 再取高频启动应用。
   - 合并后按应用 URL 去重。
   - 最多取 6 个。
   - 没有历史时返回空列表。
3. 非空查询保留当前字段权重：
   - 名称 100。
   - 标签 70。
   - 备注 45。
   - 包标识 20。
4. 非空查询保留当前匹配权重：
   - 精确 100。
   - 前缀 80。
   - 子串 60。
   - 缩写 55。
   - 模糊 35。
5. 行为加分恢复为最高 20：
   - 最近启动加分最高 15。
   - 启动次数加分最高 10。
   - 两者合计封顶 20。
6. 结果行恢复为：
   - 优先显示 noteSnippet。
   - 否则显示应用备注。
   - 右侧显示命中标签或第一个标签。
7. Quick Search 面板恢复为：
   - 固定宽度 760。
   - `.regularMaterial` 背景。
   - 最多可见 8 行。
   - 空查询最多 6 条。

