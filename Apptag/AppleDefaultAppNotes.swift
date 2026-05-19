import Foundation

enum AppleDefaultAppNotes {
    private static let familiarBundleIDs: Set<String> = [
        "com.apple.appstore",
        "com.apple.calculator",
        "com.apple.ical",
        "com.apple.facetime",
        "com.apple.mail",
        "com.apple.maps",
        "com.apple.mobilesms",
        "com.apple.music",
        "com.apple.notes",
        "com.apple.photos",
        "com.apple.safari",
        "com.apple.systempreferences"
    ]

    private static let byBundleID: [String: String] = [
        "com.apple.activitymonitor": "Mac 的仪表盘，专看谁在耗电、吃内存、拖慢电脑",
        "com.apple.airport.airportutility": "管理 AirPort 和 Time Capsule 的老派网络工具",
        "com.apple.appstore": "Mac 官方软件商店，找应用、更新和订阅都从这里开始",
        "com.apple.apps.launcher": "一个轻量应用入口，帮你从系统层面快速打开 App",
        "com.apple.audio.audiomidisetup": "管音频设备和 MIDI 路由，音乐人和调试党很常用",
        "com.apple.automator": "不写代码也能串起一串 Mac 自动化动作",
        "com.apple.bluetoothfileexchange": "用蓝牙收发文件，古早但关键时能救急",
        "com.apple.ibooksx": "阅读和管理电子书的入口，适合把 Mac 变成书桌",
        "com.apple.bootcampassistant": "Intel Mac 安装 Windows 的官方向导",
        "com.apple.calculator": "小计算器，单位换算和程序员模式也藏在里面",
        "com.apple.ical": "把日程从脑子里搬出来，给时间一张可视化地图",
        "com.apple.chess": "系统自带国际象棋，摸鱼时比刷网页更优雅",
        "com.apple.clock": "闹钟、计时器、秒表和世界时钟的统一入口",
        "com.apple.colorsyncutility": "查看和修复色彩配置文件，处理显示和打印色差",
        "com.apple.console": "看系统日志的窗口，排查异常时很有用",
        "com.apple.addressbook": "通讯录中枢，邮件、信息和 FaceTime 都会用到它",
        "com.apple.dictionary": "离线词典和同义词库，写作查词不用开浏览器",
        "com.apple.digitalcolormeter": "屏幕取色器，设计师临时取色的小神器",
        "com.apple.diskutility": "管磁盘、分区、格式化和急救，别乱点但很重要",
        "com.apple.facetime": "苹果生态里的音视频通话入口",
        "com.apple.findmy": "找设备、找物品，也让丢失的 Mac 有回家的线索",
        "com.apple.fontbook": "字体安装和管理中心，设计前先管好字体",
        "com.apple.freeform": "无限白板，适合头脑风暴、草图和乱七八糟的想法",
        "com.apple.games": "Apple 游戏入口，集中管理可玩的 Apple Arcade 内容",
        "com.apple.grapher": "把方程画成图，数学可视化的隐藏工具",
        "com.apple.home": "控制 HomeKit 设备，让 Mac 也能管家里的灯和空调",
        "com.apple.image_capture": "从相机或扫描仪导入图片，朴素但稳定",
        "com.apple.generativeplaygroundapp": "用 Apple 智能生成图像，适合快速玩创意草稿",
        "com.apple.imovieapp": "入门级视频剪辑，家庭视频和轻量短片够用",
        "com.apple.screencontinuity": "在 Mac 上直接操作 iPhone，少一次伸手拿手机",
        "com.apple.journal": "记录日常片段，让碎碎念慢慢变成个人时间线",
        "com.apple.iwork.keynote": "苹果式演示文稿工具，做漂亮幻灯片很顺手",
        "com.apple.magnifier": "放大屏幕细节，给视力和精细检查一个帮手",
        "com.apple.mail": "系统邮件客户端，多个邮箱可以集中处理",
        "com.apple.maps": "查路线、看城市，也能把目的地推给 iPhone",
        "com.apple.mobilesms": "iMessage 和短信入口，Mac 上回消息更快",
        "com.apple.migrateassistant": "换新 Mac 时搬家，把旧资料迁到新机器",
        "com.apple.exposelauncher": "窗口和桌面的空中俯视图，乱了就看它",
        "com.apple.music": "本地音乐和 Apple Music 的播放器",
        "com.apple.news": "苹果新闻入口，适合看精选媒体内容",
        "com.apple.notes": "最快的系统备忘录，文字、图片、清单都能收",
        "com.apple.iwork.numbers": "苹果表格工具，轻量报表比 Excel 更清爽",
        "com.apple.iwork.pages": "苹果文字处理器，写文档和排版都好看",
        "com.apple.passwords": "系统密码管家，账号、验证码和通行密钥集中管",
        "com.apple.mobilephone": "通过 iPhone 在 Mac 上接打电话",
        "com.apple.photobooth": "摄像头自拍和小特效，测试摄像头也方便",
        "com.apple.photos": "系统照片库，管理、编辑和同步照片的主入口",
        "com.apple.podcasts": "听播客的官方入口，通勤和学习都能用",
        "com.apple.preview": "Mac 最被低估的工具：看图、批注 PDF、简单编辑全能",
        "com.apple.printcenter": "查看和管理打印队列，卡纸卡任务先看这里",
        "com.apple.quicktimeplayerx": "播放、录屏、录音都能干的老牌工具",
        "com.apple.reminders": "待办和提醒事项，适合抓住日常小任务",
        "com.apple.safari": "Apple 官方浏览器，省电、隐私和生态联动是强项",
        "com.apple.screensharing": "远程控制另一台 Mac，帮人修电脑很方便",
        "com.apple.screenshot.launcher": "截图和录屏入口，Shift-Command-5 的背后就是它",
        "com.apple.scripteditor2": "写和运行 AppleScript，控制老派 Mac 自动化",
        "com.apple.sfsymbols": "Apple 官方符号库，做原生界面必备",
        "com.apple.shortcuts": "把多个动作串成一键流程，是现代版 Automator",
        "com.apple.siri.launcher": "语音助手入口，能查信息、开 App、控制系统",
        "com.apple.stickies": "桌面便利贴，临时记事就贴在眼前",
        "com.apple.stocks": "看股票和市场动态的小面板",
        "com.apple.systemprofiler": "查看硬件、软件和设备详情，查配置最准确",
        "com.apple.systempreferences": "Mac 设置总入口，几乎所有系统开关都在这里",
        "com.apple.terminal": "命令行入口，Mac 的隐藏驾驶舱",
        "com.apple.textedit": "最朴素的文本编辑器，开 TXT 和 RTF 很快",
        "com.apple.backup.launcher": "系统备份工具，后悔药就靠它提前准备",
        "com.apple.helpviewer": "苹果官方小技巧，偶尔能发现你没用过的功能",
        "com.apple.tv": "Apple TV 和本地影视内容的入口",
        "com.apple.voicememos": "快速录音，会议灵感和采访素材先存下来",
        "com.apple.voiceoverutility": "管理读屏辅助功能，让 Mac 更适合视觉障碍用户",
        "com.apple.weather": "天气预报入口，出门前看一眼更稳",
        "com.apple.dt.xcode": "苹果开发全家桶，写 iOS 和 macOS App 的主战场"
    ]

    private static let byName: [String: String] = [
        "SF Symbols": "Apple 官方符号库，做原生界面必备"
    ]

    static func note(for app: AppInfo) -> String? {
        if let bundleIdentifier = app.bundleIdentifier?.lowercased(),
           let note = byBundleID[bundleIdentifier] {
            return note
        }
        return byName[app.name]
    }

    static func isFamiliarAppleApp(_ app: AppInfo) -> Bool {
        guard let bundleIdentifier = app.bundleIdentifier?.lowercased() else {
            return false
        }
        return familiarBundleIDs.contains(bundleIdentifier)
    }
}
