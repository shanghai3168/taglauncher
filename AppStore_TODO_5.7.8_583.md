# TagLauncher 5.7.8 (Build 583) App Store 提交 To-do List



> 这个本机 .app/.dmg 是本地构建产物。去 App Store 提交时，最好在那台登录开发者账号的电脑上，用 source/ 里的源码重新用正式证书构建、签名、上传。

## A. 换电脑前确认

- 确认要提交的版本号是 `5.7.8`，Build 是 `583`。
- 带走本文件夹里的 `AppStore_Submission.md`、`CHANGELOG.md`、`TagLauncher.dmg`、`TagLauncher.app`。
- 如果要在另一台电脑重新签名构建，也带走源码快照文件夹或整个项目目录。
- 测试时先退出旧版 TagLauncher，再启动新版，避免菜单栏状态项仍来自旧进程。
- 如果菜单栏图标看不到，先检查 Thaw / Bartender / Ice / Hidden Bar / Dozer 等菜单栏管理软件是否隐藏了 TagLauncher。

## B. 开发者电脑准备

- 登录正确的 Apple Developer 账号。
- 确认 Xcode 已安装，并安装 Command Line Tools。
- 在 Xcode 账号里确认有 Mac App Distribution / Apple Distribution 证书。
- 确认 App Store Connect 里 Bundle ID 是 `com.apptag.launcher`。
- 确认 App Store Connect 已创建或选择 Apptag 的 `5.7.8` 版本。

## C. 正式构建与签名

- 在开发者电脑上用开发者证书重新构建，不要直接提交本机 ad-hoc 签名包。
- 使用 App Store sandbox entitlements：`Apptag/TagLauncher.entitlements`。
- 构建完成后确认 About 页显示 `版本 5.7.8（构建 583）`。
- 确认 `LSMinimumSystemVersion` 是 `15.0`。
- 本地打开新构建的 App，快速检查：
  - `⌥⇧空格` 能呼出应用列表。
  - 设置窗口能在当前 TagLauncher 浮层上方居中显示。
  - 设置页语言切换正常。
  - 通用页排版在英文、法语、意大利语、中文下都不拥挤。
  - 数据页导入/导出分类与布局正常。

## D. App Store Connect 填写

- 复制 `AppStore_Submission.md` 里的 App 描述、关键词、隐私说明和审核备注。
- 隐私标签选择“不收集任何数据”。
- 最低系统版本填写 macOS `15.0`。
- What's New 使用 `AppStore_Submission.md` 第 8 节。
- 如果上传截图，优先展示：
  - 主应用列表视图。
  - 设置页语言切换。
  - 通用页布局设置。
  - 标签编辑/拖动排序。
  - 导入/导出分类与布局。

## E. 上传与提交审核

- 用 Xcode Organizer / Transporter 上传正式签名构建。
- 上传后在 App Store Connect 选择 Build `583`。
- 填完审核信息后提交审核。
- 提交后保留本提交包，方便审核反馈时对照版本。

