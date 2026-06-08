#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const researchDir = path.resolve(scriptDir, "..");
const personaDir = path.join(researchDir, "PersonaTopApps");

const uniquePath = path.join(personaDir, "MacPersonaTopApps_Unique.csv");
const masterPath = path.join(researchDir, "MacCommonApps_CandidateTop5000_Master.csv");
const reportPath = path.join(personaDir, "MacPersonaTopApps_NotesQualityReport.md");

const noteLimit = 80;

function parseCSV(text) {
  const rows = [];
  let row = [];
  let field = "";
  let quoted = false;

  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    if (quoted) {
      if (char === "\"") {
        if (text[index + 1] === "\"") {
          field += "\"";
          index += 1;
        } else {
          quoted = false;
        }
      } else {
        field += char;
      }
      continue;
    }
    if (char === "\"") {
      quoted = true;
    } else if (char === ",") {
      row.push(field);
      field = "";
    } else if (char === "\n") {
      row.push(field);
      rows.push(row);
      row = [];
      field = "";
    } else if (char !== "\r") {
      field += char;
    }
  }
  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

function stringifyCSV(rows) {
  return rows
    .map((row) =>
      row
        .map((field) => {
          const value = String(field ?? "");
          if (/[",\n\r]/.test(value)) {
            return `"${value.replace(/"/g, "\"\"")}"`;
          }
          return value;
        })
        .join(","),
    )
    .join("\n");
}

function readCSVObjects(filePath) {
  const rows = parseCSV(fs.readFileSync(filePath, "utf8"));
  const header = rows[0] ?? [];
  return {
    header,
    rows: rows.slice(1).map((row) =>
      Object.fromEntries(header.map((column, index) => [column, row[index] ?? ""])),
    ),
  };
}

function splitTags(value) {
  return String(value ?? "")
    .split(/[|;,]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function noteLength(note) {
  return Array.from(note).length;
}

function limitNote(note) {
  const clean = String(note ?? "")
    .replace(/\s+/g, " ")
    .replace(/\s+([，。；：、])/g, "$1")
    .trim();
  if (noteLength(clean) <= noteLimit) return clean;

  const chars = Array.from(clean);
  let sliced = chars.slice(0, noteLimit).join("");
  sliced = sliced.replace(/[，、；：,.!！?？]$/, "");
  if (!/[。.!！?？]$/.test(sliced)) {
    sliced = `${Array.from(sliced).slice(0, noteLimit - 1).join("")}。`;
  }
  return sliced;
}

const manualNotes = new Map(Object.entries({
  "Notion": "把笔记、文档、数据库和项目管理收进一个团队工作台。",
  "Obsidian": "本地 Markdown 知识库，适合长期沉淀自己的第二大脑。",
  "ChatGPT": "把 AI 助手放到桌面，写作、学习和头脑风暴随手就来。",
  "ChatGPT Atlas": "带 AI 助手的浏览器，边看网页边提问、整理和行动。",
  "Granola": "自动记录会议重点，把对话变成可追踪的行动项。",
  "Plaud": "把录音、转写和 AI 总结连起来，会议复盘省很多力。",
  "Reflect Notes": "轻量笔记加日程回顾，适合把想法按时间串起来。",
  "Fellow": "会议议程、纪要和跟进事项的团队协作台。",
  "Jamie": "AI 会议记录员，自动整理纪要和待办。",
  "Google Chrome": "插件生态最强的浏览器，调试网页和日常上网都稳。",
  "Joplin": "开源笔记和待办工具，适合同步自己的 Markdown 资料。",
  "Zoom": "视频会议常用入口，远程沟通和线上课程都离不开。",
  "Microsoft Teams": "微软系团队协作中心，聊天、会议和文件集中处理。",
  "ONLYOFFICE": "本地 Office 套件，适合编辑文档、表格和演示稿。",
  "LogiTune": "管理罗技摄像头和耳机，开会前调设备很方便。",
  "Quip": "文档、表格和团队讨论放在同一个协作空间。",
  "Figma": "在线协作设计工具，界面、原型和设计系统都能做。",
  "Microsoft Word": "经典文字处理器，正式文档和审阅协作都很稳。",
  "Microsoft Excel": "表格和数据分析老将，财务、运营和模型都靠它。",
  "Itsycal": "菜单栏小日历，快速看日期和日程。",
  "Notion Calendar": "把日历和 Notion 工作流连起来，安排时间更顺。",
  "Tencent Meeting": "腾讯会议入口，中文办公和远程协作很常见。",
  "DevToys": "开发者小工具箱，编码转换、哈希和格式化一站解决。",
  "Webex": "企业级视频会议工具，适合正式远程沟通。",
  "Dot": "菜单栏小工具入口，适合把常用动作收得更近。",
  "Keynote": "苹果演示工具，做漂亮幻灯片比想象中更快。",
  "Slack": "团队聊天和工作流入口，项目沟通不必埋在邮件里。",
  "Google Drive": "云端文件同步和协作入口，跨设备找资料很省心。",
  "KiCad": "开源电路设计工具，画原理图和 PCB 很专业。",
  "Adobe Creative Cloud": "Adobe 全家桶管理器，装插件和更新设计工具都靠它。",
  "MeetingBar": "菜单栏显示下一场会议，一键加入不再翻日历。",
  "CapCut": "轻量视频剪辑工具，做短视频和社媒内容很顺手。",
  "Miro": "在线白板，适合头脑风暴、流程图和远程共创。",
  "Jan": "本地 AI 聊天工具，把模型运行在自己的电脑上。",
  "PDF Expert": "PDF 阅读、批注和编辑工具，处理合同论文都方便。",
  "Draw Things": "本地 AI 绘图工具，直接在 Mac 上跑图像生成。",
  "Numbers": "苹果表格工具，轻量报表和个人数据管理很清爽。",
  "Pages": "苹果文字处理器，写文档和简单排版都好看。",
  "Prism Launcher": "Minecraft 启动器，管理模组和多个游戏实例很方便。",
  "Lunatask": "把任务、习惯和笔记放一起的个人效率系统。",
  "Claude": "Claude 桌面入口，适合长文阅读、写作和思考辅助。",
  "Raycast": "键盘驱动的效率入口，启动 App、脚本和搜索都很快。",
  "1Password": "密码和密钥管理器，账号安全的核心保险箱。",
  "Bitwarden": "开源密码管理器，跨平台保存账号和验证码。",
  "Blender": "开源 3D 创作工具，建模、动画和渲染都能做。",
  "GIMP": "开源图像编辑器，修图和简单设计不必上重型套件。",
  "Shottr": "截图和标注工具，做产品反馈和视觉说明很利索。",
  "Dropbox": "老牌云同步工具，跨设备和团队共享文件很稳定。",
  "ComfyUI": "节点式 AI 绘图工作流，适合精细控制生成过程。",
  "Affinity": "Affinity 设计套件入口，适合替代订阅制设计工具。",
  "Feishu": "飞书协作入口，中文团队的聊天、文档和会议都在这。",
  "Logseq": "大纲式知识库，用双链组织笔记和研究脉络。",
  "Krita": "开源绘画工具，插画、概念图和数字绘画很强。",
  "Proton Mail": "重视隐私的邮件客户端，适合安全收发邮件。",
  "Mattermost": "自部署团队聊天工具，适合重视数据控制的团队。",
  "Microsoft OneNote": "微软笔记本，适合课堂记录、项目资料和手写内容。",
  "Canva": "模板化设计工具，海报、社媒图和演示稿都能快速出图。",
  "Fantastical": "高级日历工具，用自然语言快速安排日程。",
  "Lark": "Lark 协作入口，聊天、文档、会议和审批放在一起。",
  "Sketch": "经典 Mac 界面设计工具，适合 UI 和图标设计。",
  "Photoshop": "专业图像编辑工具，修图、合成和设计都绕不开。",
  "Illustrator": "矢量图形设计工具，Logo、图标和插画很专业。",
  "Adobe Lightroom": "照片管理和调色工具，处理 RAW 与批量照片很顺。",
  "Visual Studio Code": "轻量但强大的代码编辑器，插件生态非常完整。",
  "Xcode": "苹果开发主战场，做 iOS 和 macOS App 必备。",
  "Safari": "苹果官方浏览器，省电、隐私和生态联动是强项。",
  "Photos": "系统照片库，管理、编辑和同步照片的主入口。",
  "GarageBand": "苹果入门音乐制作工具，录音和编曲都容易上手。",
  "Final Cut Pro": "苹果专业视频剪辑工具，剪片、调色和导出都很快。",
  "Logic Pro": "苹果专业音乐制作工具，录音、编曲和混音都很强。",
  "Godot": "开源游戏引擎，适合快速制作 2D 和 3D 游戏。",
  "Anaconda": "Python 数据科学发行版，环境和包管理更省心。",
  "Sourcetree": "图形化 Git 客户端，提交、分支和冲突更直观。",
  "Epic Games": "Epic 游戏平台入口，管理游戏库和启动游戏。",
  "Tradingview": "行情图表和交易分析工具，适合盯盘和画策略。",
  "Battle Net": "暴雪游戏启动器，管理战网游戏和更新。",
  "Firefox": "开源浏览器，重视隐私和扩展自由。",
  "Brave Browser": "主打隐私和广告拦截的 Chromium 浏览器。",
  "VLC": "万能播放器，格式再冷门也多半能打开。",
  "Drawio": "流程图和架构图工具，画清楚系统关系很方便。",
  "Perplexity": "AI 搜索和问答入口，适合快速查资料和追来源。",
  "GitHub Desktop": "GitHub 官方桌面客户端，提交和同步仓库更直观。",
  "iTerm2": "增强版终端，开发者常用的命令行工作台。",
  "Warp": "现代终端，把命令行、搜索和 AI 辅助结合起来。",
  "Zed": "高性能代码编辑器，适合追求速度和协作体验。",
  "Android Studio": "Android 官方 IDE，开发和调试 Android App 必备。",
  "Maccy": "剪贴板历史工具，复制过的内容随时找回来。",
  "Spotify": "流媒体音乐播放器，工作和放松都能配一首歌。",
  "Discord": "语音和社区聊天工具，游戏和创作者圈子很常用。",
  "Steam": "PC 游戏平台核心入口，买游戏、更新和启动都靠它。",
  "Keka": "压缩解压工具，处理 ZIP、7z 和 RAR 很方便。",
  "Signal": "重视隐私的加密聊天工具。",
  "Arc": "工作流式浏览器，把网页、空间和资料组织得更清楚。",
  "JetBrains Toolbox": "JetBrains IDE 管理器，安装和更新全家桶更省心。",
  "Audacity": "开源音频编辑器，录音、剪辑和降噪都能做。",
  "Whisky": "在 Mac 上运行 Windows 游戏和应用的轻量工具。",
  "Alfred": "老牌效率启动器，搜索、工作流和剪贴板都很强。",
  "The Unarchiver": "轻量解压工具，打开各种压缩包很省事。",
  "Insomnia": "API 调试工具，测试接口和管理请求集合很顺。",
  "Unity Hub": "Unity 项目和编辑器版本管理入口。",
  "Proxyman": "网络抓包工具，调试 App 和网页请求很清楚。",
  "Typora": "所见即所得 Markdown 编辑器，写作体验很顺。",
  "RStudio": "R 语言 IDE，统计分析和数据可视化常用。",
  "Fork": "漂亮的 Git 客户端，分支、提交和冲突处理更轻松。",
  "Microsoft PowerPoint": "经典演示工具，商务汇报和课程课件都常用。",
  "HandBrake": "视频转码工具，压缩和转换格式很稳。",
  "MySQL Workbench": "MySQL 官方图形工具，建模、查询和管理数据库。",
  "Mozilla Firefox Developer Edition": "面向开发者的 Firefox，网页调试功能更前沿。",
  "mpv": "轻量播放器，键盘控制和格式兼容都很强。",
  "GOG Galaxy": "GOG 游戏平台入口，管理 DRM-free 游戏很方便。",
  "Loopback": "虚拟音频路由工具，把不同 App 的声音灵活串起来。",
  "Audio Hijack": "录制和处理 Mac 音频流，播客和直播很常用。",
  "Plexamp": "Plex 音乐播放器，适合管理和播放自己的音乐库。",
  "League of Legends": "英雄联盟客户端，经典团队竞技游戏入口。",
  "GnuCash": "开源财务记账工具，个人和小团队账本都能管。",
  "PCSX2": "PlayStation 2 模拟器，重温老游戏很方便。",
  "Permute": "媒体格式转换工具，视频、音频和图片都能批量处理。",
  "DriveDX": "硬盘健康监测工具，提前发现磁盘风险。",
  "Msty": "多模型 AI 客户端，适合统一管理本地和云端模型。",
  "Electrum": "轻量比特币钱包，适合管理和签署 BTC 交易。",
  "Scrivener": "长文写作工具，小说、论文和大纲管理很强。",
  "Descript": "用编辑文字的方式剪音视频，播客和短视频很省力。",
  "Fathom": "AI 会议记录工具，自动生成纪要和行动项。",
  "Orange": "可视化数据挖掘工具，拖拽节点做分析和建模。",
  "Whimsical": "流程图、线框图和白板工具，产品讨论很快出图。",
  "GameMaker": "2D 游戏制作工具，适合快速做原型和发布小游戏。",
  "Defold": "轻量游戏引擎，适合跨平台 2D 游戏开发。",
  "Sip": "设计师取色工具，管理调色板和屏幕颜色很方便。",
  "Rhinoceros": "专业 3D 建模工具，工业设计和建筑建模常用。",
  "Zeplin": "设计交付工具，把设计稿转换成开发可读的规格。",
  "Runway": "AI 视频和创意生成工具，适合快速制作视觉素材。",
  "Affinity Publisher": "专业排版工具，杂志、手册和宣传册都能做。",
  "CashNotify": "菜单栏收款提醒工具，适合关注支付和收入动态。",
  "Slack CLI": "用命令行操作 Slack，适合把团队消息接进脚本流程。",
  "ClickUp": "项目和任务管理平台，适合把团队执行过程管清楚。",
  "Clocker": "菜单栏世界时钟，跨时区协作时很省心。",
  "Calendr": "菜单栏日历工具，不打开日历也能看安排。",
  "Framer": "交互原型和网站设计工具，适合把想法快速做成可体验页面。",
  "Adobe Connect": "企业线上会议和课堂工具，适合培训、会议和网络研讨会。",
  "Gopass UI": "gopass 密码库图形界面，适合安全管理团队密钥。",
  "Teleport TSH": "Teleport 命令行入口，适合安全登录服务器和集群。",
  "GhostPepper": "轻量日程提醒工具，适合把重要时间放在菜单栏。",
  "BusyCal": "高级日历工具，适合管理复杂日程和多账号安排。",
  "LunarBar": "菜单栏月相工具，适合快速查看月亮状态和天文节律。",
  "DingTalk": "钉钉桌面端，中文团队的沟通、会议和审批入口。",
  "Spark": "现代邮件客户端，适合把多个邮箱集中处理。",
  "Moom": "窗口管理工具，快速排列和保存窗口布局。",
  "Ukelele": "键盘布局编辑器，适合自定义输入法和键位。",
  "Mimestream": "Gmail 原生风格邮件客户端，Mac 上收发 Gmail 很顺。",
  "Calendar 366 II": "菜单栏日历和日程工具，适合快速查看安排。",
  "DavMail": "把 Exchange 服务转成标准协议，方便老客户端接入。",
  "Morgen": "日历和任务统一规划工具，适合安排一天的时间块。",
  "Xiaomi Cloud": "小米云服务入口，适合同步和管理小米生态资料。",
  "draw.io Desktop": "流程图和架构图工具，适合把系统关系画清楚。",
  "Affinity Photo 2": "专业修图工具，适合照片编辑、合成和精细调色。",
  "Eagle": "设计素材管理器，图片、截图和灵感图都能收好。",
  "macSVG": "SVG 矢量编辑器，适合轻量修改图标和网页矢量图。",
  "Epson Print Layout": "爱普生照片打印排版工具，适合控制纸张和色彩输出。",
  "Rayon": "建筑和室内平面图工具，适合快速绘制空间方案。",
  "EdrawMax": "综合绘图工具，流程图、组织图和信息图都能画。",
  "Adobe Photoshop Patterns Quicklook Plugin": "给 Photoshop 图案文件加预览，找素材更快。",
  "DMG Canvas": "DMG 安装包设计工具，适合做漂亮的 Mac 分发镜像。",
  "i1Profiler": "显示器和打印色彩校准工具，适合严肃影像工作流。",
  "PaintCode": "把矢量设计转成代码，适合开发可复用界面图形。",
  "Adobe Acrobat Reader": "PDF 阅读和批注工具，合同、论文和表单都能处理。",
  "Hammerspoon": "用 Lua 自动化 Mac，键盘、窗口和脚本都能接管。",
  "Raspberry Pi Imager": "树莓派系统写盘工具，制作启动卡很省事。",
  "Etcher": "系统镜像写盘工具，制作启动 U 盘直观可靠。",
  "Notion Mail": "Notion 风格邮件工具，适合把邮件变成可整理的信息流。",
  "Evernote": "老牌笔记工具，适合收集网页、文件和日常记录。",
  "QOwnNotes": "开源 Markdown 笔记工具，适合本地资料和云同步。",
  "DEVONthink": "个人知识资料库，适合收纳 PDF、网页和研究材料。",
  "WorkFlowy": "无限大纲工具，适合把复杂想法拆成清晰层级。",
  "Send to Kindle": "把文档发送到 Kindle，长文阅读更舒服。",
  "Dangerzone": "把可疑文档转成安全 PDF，适合处理不可信附件。",
  "Tencent Docs": "腾讯文档桌面入口，适合中文团队在线协作。",
  "Autodesk EAGLE": "电路设计工具，适合画原理图和 PCB。",
  "Affinity Designer": "矢量设计工具，适合图标、插画和品牌视觉。",
  "OrbStack": "轻量容器和 Linux 环境，替代 Docker Desktop 很顺手。",
  "IINA": "现代 Mac 视频播放器，界面清爽、格式兼容好。",
  "Cyberduck": "FTP/SFTP 和云存储客户端，传文件很方便。",
  "Skim": "PDF 阅读和批注工具，适合看论文和做研究标注。",
  "darktable": "开源 RAW 照片处理工具，适合摄影后期。",
  "Bartender": "菜单栏整理工具，把杂乱图标收得干干净净。",
  "CleanShot": "截图、录屏和标注工具，做反馈和教程很利索。",
  "ImageOptim": "图片压缩工具，减小体积但尽量保住画质。",
  "Snipaste": "截图加贴图工具，适合把参考内容固定在屏幕上。",
  "Linear": "面向产品和研发团队的问题追踪工具。",
  "Anytype": "本地优先的知识库和资料管理工具，强调隐私和结构化。",
  "TIDAL": "高音质流媒体音乐服务，适合认真听歌的人。",
  "MediaInfo": "查看媒体文件编码、码率和轨道信息的工具。",
  "PicGo": "图床上传工具，写文档和发博客时传图很快。",
  "Moom": "窗口管理工具，快速排列和保存窗口布局。",
  "Craft": "漂亮的文档和笔记工具，适合写知识卡片和项目资料。",
  "ClipGrab": "在线视频下载工具，适合保存公开视频素材。",
  "Glide": "从表格快速生成应用，适合无代码原型和内部工具。",
  "Notchi": "刘海区域美化工具，让菜单栏视觉更有趣。",
  "A Better Finder Rename": "批量重命名工具，整理照片和文件特别省时间。",
  "Adobe Creative Cloud Cleaner Tool": "清理 Adobe 安装残留，修复 Creative Cloud 玄学问题。",
  "Camtasia": "录屏和视频教程制作工具，适合课程与演示。",
  "ScreenFlow": "录屏剪辑工具，做教程、演示和产品视频很顺。",
  "EndNote": "文献管理工具，适合论文引用和参考文献整理。",
  "Realm Studio": "Realm 数据库查看工具，适合调试移动端本地数据。",
  "Weka": "机器学习教学和实验工具，拖拽就能做数据挖掘。",
  "Vibe Notch": "把 Mac 刘海变成动态状态区，给桌面加一点趣味。",
  "Mochi": "间隔重复记忆卡片工具，适合背词和长期学习。",
  "Deckset": "用 Markdown 做演示文稿，写完文字就能出幻灯片。",
  "Multi MC": "Minecraft 多实例启动器，模组管理更清楚。",
  "Mutedeck": "菜单栏会议控制器，静音和摄像头状态一眼可见。",
  "GoToMeeting": "在线会议工具，适合远程沟通和商务演示。",
  "iA Presenter": "用文本结构生成演示稿，适合先想清楚再做幻灯片。",
  "RightFont": "字体管理工具，设计时找字、启用字都更快。",
  "PhotoSync Companion": "照片和视频传输助手，手机与 Mac 互传更顺。",
  "CoverLoad": "媒体封面下载工具，适合整理影视和音乐资料。",
  "LehrerOffice": "教师办公工具，适合管理班级、成绩和教学资料。",
  "IconJar": "图标素材管理器，设计系统和图标库都能收好。",
  "LibreOffice": "开源 Office 套件，文档、表格和演示都能编辑。",
  "BlackHole 2ch": "虚拟音频驱动，适合录屏、直播和音频路由。",
  "BlackHole 16ch": "多通道虚拟音频驱动，适合复杂录音和直播。",
  "BlackHole 64ch": "高通道虚拟音频驱动，适合专业音频路由。",
  "Miniconda": "轻量 Python 环境管理工具，做数据和开发更干净。",
  "Docker Desktop": "在 Mac 上运行容器和微服务，本地开发环境更容易复现。",
  "Sublime Text": "轻快的代码与文本编辑器，写代码、改配置和记草稿都顺手。",
  "Zed Preview": "高性能协作代码编辑器，适合尝鲜新版 Zed 功能。",
  "REAPER": "专业数字音频工作站，录音、剪辑、编曲和混音都很灵活。",
  "Godot Mono": "带 C# 支持的 Godot 版本，适合用 .NET 开发游戏。",
  "Adobe AIR": "运行 AIR 应用的运行时，常见于旧游戏和跨平台桌面工具。",
  "DCP-o-matic": "把影片、字幕和音频打包成影院放映用的 DCP。",
  "DCP-o-matic KDM Creator": "为 DCP 生成影院密钥，适合数字电影发行流程。",
  "DCP-o-matic Disk Writer": "把 DCP 写入放映介质，适合影院交付前检查。",
  "DCP-o-matic Playlist Editor": "编辑 DCP 放映列表，整理影院播放顺序更清楚。",
  "DCP-o-matic Batch converter": "批量转换影片到 DCP，处理多条片源时很省事。",
  "DCP-o-matic Encode Server": "分担 DCP 编码任务，让电影打包速度更快。",
  "Charles": "网页抓包代理，调试接口、证书和网络请求很清楚。",
  "Subler": "给 MP4 封装、加字幕和改元数据，整理影片很方便。",
  "Foxit PDF Editor": "PDF 编辑器，适合修改、批注、签署和整理 PDF。",
  "Moonlight": "串流游戏客户端，把远端 PC 游戏流畅投到 Mac 上玩。",
  "CrossOver": "在 Mac 上运行 Windows 软件和游戏，不必完整装虚拟机。",
  "Epic Games Launcher": "Epic 游戏启动器，领取、下载和更新游戏都靠它。",
  "Minecraft": "开放世界沙盒游戏，建造、探索和模组玩法都很丰富。",
  "NVIDIA GeForce NOW": "云游戏入口，低配置 Mac 也能玩高性能游戏。",
  "Roblox": "Roblox 游戏平台，玩社区创作的多人游戏和体验。",
  "LÖVE": "Lua 2D 游戏框架，适合快速做轻量游戏原型。",
  "Porting Kit": "把 Windows 游戏移植到 Mac，少折腾一点兼容层配置。",
  "BlueStacks": "安卓模拟器，适合在 Mac 上运行手机游戏和应用。",
  "Dolphin": "任天堂 GameCube 和 Wii 模拟器，老游戏重温很方便。",
  "SteamCMD": "Steam 命令行工具，适合管理游戏服务器和批量下载。",
  "Godot Engine": "开源游戏引擎，适合制作 2D、3D 和独立游戏。",
  "0 A.D.": "开源即时战略游戏，适合喜欢历史题材和基地建设的人。",
  "PlayCover": "让部分 iOS 游戏在 Apple Silicon Mac 上运行。",
  "Blizzard Battle.net": "暴雪游戏平台入口，管理战网游戏、更新和好友。",
  "Heroic Games Launcher": "GOG、Epic 等游戏库的开源启动器，跨平台管理更轻。",
  "OpenTTD": "经典交通经营游戏，规划铁路、公路和城市物流。",
  "Roblox Studio": "Roblox 创作工具，用来制作和发布 Roblox 体验。",
  "itch": "独立游戏平台入口，发现、下载和管理小众游戏。",
  "Dungeon Crawl Stone Soup": "硬核 Roguelike 地牢游戏，适合喜欢策略探索的人。",
  "OBS": "直播和录屏工具，课程、演示和游戏录制都很常用。",
  "YouTube Music": "YouTube 音乐客户端，适合听歌、歌单和音乐视频。",
  "Luanti": "开源方块沙盒游戏平台，适合玩和制作类 Minecraft 世界。",
  "Background Music": "按 App 调节音量，还能把系统声音录进工作流。",
  "FineTune": "AI 音频工具，适合整理、转写或优化声音内容。",
  "Kap": "开源录屏工具，快速录制屏幕并导出 GIF 或视频。",
  "Plex": "家庭媒体库中心，把电影、剧集和音乐整理后跨设备播放。",
  "QuickLook Video": "给 Finder 预览更多视频格式，选片找素材更快。",
  "LosslessCut": "无损剪切音视频，不重新编码也能快速裁片段。",
  "NetEase cloud music": "网易云音乐桌面端，听歌、歌单和中文音乐社区都方便。",
  "OpenEmu": "复古游戏模拟器，把多平台游戏库统一管理起来。",
  "LyricsX": "桌面歌词工具，听歌时同步显示歌词很舒服。",
  "YouTube Music Desktop App": "YouTube Music 桌面封装，听歌时不用一直开浏览器。",
  "Elmedia Player": "Mac 媒体播放器，视频、音频和投屏播放都方便。",
  "Douyin": "抖音桌面端，浏览、发布和管理短视频内容更方便。",
  "AWA": "日本流媒体音乐服务，适合听歌和发现日系音乐。",
  "Shutter Encoder": "音视频转码工具，格式转换、压缩和批处理很稳。",
  "rekordbox": "DJ 音乐管理和演出准备工具，整理歌库和歌单很专业。",
  "FileBot": "自动重命名影视文件，剧集、字幕和媒体库更整齐。",
  "VOX": "高音质音乐播放器，适合播放本地无损音乐。",
  "Pocket Casts": "播客客户端，订阅、收听和同步节目都很顺。",
  "Nuclear": "开源音乐播放器，从多个在线来源聚合音乐。",
  "Lyric Fever": "动态歌词显示工具，让听歌时的歌词更醒目。",
  "Music Decoy": "音乐占位工具，适合配合媒体键和播放状态工作流。",
  "Adapter": "媒体转换工具，视频、音频和图片格式批量转换很轻松。",
  "Mac Media Key Forwarder": "把媒体键转发给指定播放器，控制音乐更稳定。",
  "Snes9x": "Super Nintendo 模拟器，适合重温经典主机游戏。",
  "Forecast": "播客章节编辑工具，给音频节目加章节和元数据。",
  "SonoBus": "低延迟网络音频工具，远程合奏和实时传声很实用。",
  "Viz": "轻量图像查看工具，适合快速翻看图片素材。",
  "QLab": "现场演出音视频控制台，剧场、舞台和活动常用。",
  "Sonixd": "Subsonic 音乐客户端，适合播放自建音乐库。",
  "Tickeys": "给键盘输入加打字音效，让敲字更有仪式感。",
  "Riverside Studio": "远程录音录像工具，适合播客、访谈和视频节目。",
  "RetroArch Metal Nightly": "RetroArch 的 Metal 测试版，适合尝鲜复古模拟性能。",
  "Elgato Game Capture HD": "游戏采集工具，录制和直播主机画面很方便。",
  "Pimosa": "媒体小工具，适合处理特定的视频、音频或图片任务。",
  "Playdate Mirror": "把 Playdate 掌机画面镜像到 Mac，录制演示更方便。",
  "Tracker": "视频运动分析工具，适合物理教学和实验研究。",
  "Olympus": "游戏模组管理工具，适合管理 Celeste 等游戏内容。",
  "Ankama Launcher": "Ankama 游戏启动器，管理 Dofus 等游戏和账号。",
  "Bfxr": "复古游戏音效生成器，快速做 8-bit 风格声音。",
  "Ledger Wallet": "硬件钱包管理工具，适合查看和签署加密资产交易。",
  "TradingView Desktop": "桌面行情图表工具，盯盘、画线和分析策略更专注。",
  "Portfolio Performance": "投资组合分析工具，适合复盘收益、资产和风险。",
  "Actual": "本地优先的预算记账工具，适合认真管理个人现金流。",
  "IBKR Desktop": "盈透证券桌面端，适合交易、行情和账户管理。",
  "TREZOR Suite": "Trezor 硬件钱包管理器，安全查看和签署交易。",
  "MoneyMoney": "德国常用财务管理工具，适合聚合银行账户和账单。",
  "Binance": "币安桌面入口，适合管理加密资产、行情和交易。",
  "Monero Wallet": "门罗币钱包，适合重视隐私的 XMR 收付款。",
  "Specter": "比特币钱包管理工具，适合多签和硬件钱包工作流。",
  "Actual ODBC Driver Pack": "Actual 的 ODBC 驱动包，方便旧数据库接入 Mac 应用。",
  "BitBox": "BitBox 硬件钱包套件，适合安全管理加密资产。",
  "BTCPayServer Vault": "BTCPay 硬件钱包桥接工具，帮助安全签署付款。",
  "Nault": "Nano 钱包客户端，适合管理和发送 Nano 资产。",
  "Clop": "自动压缩图片、视频和 PDF，拖进去就能瘦身文件。",
  "CodexBar": "菜单栏 AI 编码助手入口，把开发提示放到手边。",
  "ClaudeBar": "菜单栏 Claude 入口，随手提问和处理文本更快。",
  "VibeProxy": "AI 开发代理工具，适合把模型接进本地工作流。",
  "LinearMouse": "鼠标和触控板调校工具，滚动、加速度和按键更顺手。",
  "LidAngleSensor": "读取笔记本开合角度的小工具，适合自动化和硬件实验。",
  "Flycut": "开源剪贴板历史工具，复制过的文字随时找回来。",
  "qutebrowser": "键盘驱动的浏览器，适合喜欢 Vim 操作的人。",
  "Weasis": "医学影像 DICOM 查看器，适合浏览和分析医疗影像。",
  "SpotMenu": "菜单栏 Spotify 控制器，当前播放和切歌都更顺手。",
  "Radiola": "网络电台播放器，适合在菜单栏收听在线广播。",
  "Enjoyable": "手柄映射工具，把游戏控制器变成键盘鼠标输入。",
  "MIDI Monitor": "查看 MIDI 事件的小工具，调试键盘和控制器很清楚。",
  "Mechvibes": "键盘音效工具，让普通键盘模拟机械键盘声音。",
  "Bowtie": "桌面音乐控制器，显示封面并控制播放器。",
  "MusaicFM Screensaver": "把音乐信息做成屏保，闲置时也能展示正在播放。",
  "Volume Control": "音量控制工具，适合更细地管理系统声音输出。",
  "Baritone": "Minecraft 自动寻路工具，适合研究和辅助复杂移动。",
  "PodcastMenu": "菜单栏播客工具，不打开主应用也能收听节目。",
  "RetroArch": "统一模拟器前端，把复古游戏、核心和手柄配置收一起。",
  "VibeTunnel": "把本地开发服务安全暴露出去，方便远程预览和调试。",
  "Nook": "专注式浏览器工作区，适合把网页资料按项目整理。",
  "Sidekick": "工作流浏览器，适合把常用 SaaS 和网页应用放一起。",
  "Vieb": "Vim 风格浏览器，键盘浏览和网页操作效率很高。",
  "Chromium-Gost": "带 GOST 加密支持的 Chromium，适合特定合规浏览需求。",
  "DB Browser for SQLCipher Nightly": "SQLCipher 数据库浏览器，适合查看加密 SQLite 数据。",
  "DB Browser for SQLite Nightly": "SQLite 数据库浏览器测试版，适合查看和编辑本地库。",
  "Affinity Photo": "一次性买断的专业修图工具，照片编辑和合成都很强。",
  "Adobe Photoshop": "专业图像编辑工具，修图、合成和商业设计都很强。",
  "ExifRenamer": "按 EXIF 信息批量重命名照片和视频，整理素材更快。",
  "Tentacle Sync Studio": "同步多机位音视频时间码，拍摄现场对齐素材更省心。",
  "Cisco Proximity": "连接会议室设备共享屏幕，适合企业会议和演示。",
  "Zoom for IT Admins": "给 IT 管理员部署 Zoom，批量配置会议客户端更方便。",
  "Webex Meetings": "Webex 会议客户端，适合企业远程会议和线上沟通。",
  "Yandex Telemost": "Yandex 视频会议工具，适合远程通话和线上协作。",
  "VooV Meeting": "腾讯会议国际版，适合跨地区视频会议和协作。",
  "RingCentral": "企业通信平台，电话、消息和视频会议集中处理。",
  "RingCentral Meetings": "RingCentral 会议客户端，适合远程视频沟通。",
  "Yealink Meeting": "亿联会议客户端，适合连接会议室设备和远程会议。",
  "Cryptomator": "给云盘文件加密，敏感资料同步前先锁起来。",
  "BankID Security Application (Sweden)": "瑞典 BankID 安全组件，用来完成银行和身份认证。",
  "Standard Notes": "端到端加密笔记工具，适合保存私密文字和资料。",
  "Glance": "Quick Look 扩展，让代码、图片和文档预览更好用。",
  "4K Video Downloader Plus": "下载在线视频和播放列表，保存素材更直接。",
  "Open Video Downloader": "开源视频下载器，适合保存公开视频素材。",
  "4K Video Downloader": "在线视频下载工具，适合保存课程、素材和播放列表。",
  "Mora Downloader": "mora 音乐下载工具，适合保存购买的高音质曲目。",
  "FoldingText": "大纲式文本编辑器，适合用层级结构整理写作思路。",
  "(Deep) HIARCS Chess Explorer": "国际象棋数据库和分析工具，适合研究棋局与开局。",
  "LM Studio": "本地大模型运行工具，适合下载、测试和调用开源模型。",
  "AnythingLLM": "把文档和知识库接入 AI 问答，适合私有资料助手。",
  "Open WebUI": "本地 AI 模型网页界面，适合统一管理聊天和模型。",
  "Diffusion Bee": "本地 AI 绘图工具，不上云也能生成图片。",
  "Ollamac": "Ollama 的 Mac 客户端，管理本地模型和聊天更直观。",
  "Langflow Desktop": "可视化搭建 AI 工作流，把模型、工具和数据连起来。",
  "Paseo": "AI 辅助开发工具，适合把模型接进代码工作流。",
  "Gram": "AI 开发工具，适合把智能能力嵌进产品和流程。",
  "Upscayl": "AI 图片放大工具，低清图片也能变得更清晰。",
  "Easydict": "划词翻译和词典工具，读外文资料时很省心。",
  "Asset Catalog Tinkerer": "查看和导出 Xcode 资源目录，处理 App 素材很方便。",
  "Qobuz": "高解析音乐服务，适合认真听歌和管理高音质曲库。",
  "Music Presence": "把正在播放的音乐同步到状态，适合展示听歌动态。",
  "TunnelBear": "轻量 VPN 工具，适合保护网络连接和临时换区。",
  "Mac Monitor": "系统状态监控工具，查看硬件和性能信息更直观。",
  "Label LIVE": "标签设计和打印工具，适合电商、仓储和物流贴纸。",
  "Canon Driver": "佳能设备驱动，保证打印机、扫描仪等硬件正常工作。",
  "ATLauncher": "Minecraft 启动器，管理整合包、模组和多个实例。",
  "GDLauncher": "Minecraft 启动器，安装和切换模组包很方便。",
  "Badlion": "Minecraft PvP 客户端，内置性能和竞技辅助功能。",
  "LabyMod": "Minecraft 客户端增强工具，适合服务器和社区玩法。",
  "sipgate": "VoIP 电话服务客户端，适合网络电话和商务通信。",
  "Sipgate Softphone": "软电话客户端，直接在 Mac 上拨打和接听 VoIP。",
  "Acronis True Image": "备份和恢复工具，适合保护整机、磁盘和重要文件。",
  "MusaicFM Screensaver": "把音乐信息做成屏保，闲置时也能展示正在播放。",
  "Principle": "交互动效原型工具，适合做 App 转场和微交互演示。",
  "GDevelop": "无代码游戏制作工具，适合快速做 2D 游戏原型。",
  "Warsaw": "银行安全组件，常见于巴西网银登录和交易保护。",
  "WriteMapper": "把思维导图变成写作大纲，适合文章和报告起草。",
  "Downie": "在线视频下载工具，适合保存课程、演讲和公开素材。",
  "MediaHuman YouTube to MP3 Converter": "把在线视频转成 MP3，适合保存音乐和播客音频。",
  "TextSniper": "截图识别文字工具，屏幕上的文字可以一键复制。",
  "MacX YouTube Downloader": "YouTube 视频下载工具，适合保存公开视频素材。",
  "YouTube Downloader": "轻量视频下载工具，适合把在线素材保存到本地。",
  "Badlion Client": "Minecraft PvP 客户端，内置性能优化和竞技辅助。",
  "LabyMod Launcher": "LabyMod 启动器，管理 Minecraft 模组和服务器体验。",
  "Syncplay": "多人同步观影工具，让不同电脑上的视频一起播放。",
  "4K Stogram": "Instagram 下载工具，适合保存照片、视频和账号内容。",
  "ZeroNet": "去中心化网络客户端，适合访问和托管点对点网站。",
  "GpgFrontend": "GPG 图形界面，适合加密、签名和管理密钥。",
  "Radio Silence": "出站防火墙工具，阻止 App 悄悄联网。",
  "Paranoia File & Text Encryption": "文件和文本加密工具，适合临时保护敏感内容。",
  "Electrum-LTC": "莱特币轻钱包，适合管理和签署 LTC 交易。",
  "Wasabi Wallet": "重视隐私的比特币钱包，适合 CoinJoin 工作流。",
  "Anchor Wallet": "EOS 系钱包客户端，适合管理账号和签署交易。",
  "Boxcryptor": "云盘文件加密工具，同步前先给敏感资料上锁。",
  "Crypto Native App NG": "加密资产工具入口，适合处理钱包和链上操作。",
  "Zotero": "文献管理工具，收集论文、引用和参考文献很省心。",
  "Mendeley Reference Manager": "文献管理器，适合整理论文库和生成引用。",
  "MarginNote": "读书和论文标注工具，适合把阅读变成知识网络。",
  "Hepta": "卡片式知识管理工具，适合把阅读和研究连成图谱。",
  "Zotero Beta": "Zotero 测试版，适合提前体验新的文献管理功能。",
  "Roam Research": "双链笔记工具，适合把研究想法织成网络。",
  "kiro": "AI 编码工具，适合用自然语言推进代码实现和调试。",
  "Windsurf": "AI 原生代码编辑器，适合边写边让助手理解工程上下文。",
  "Trae": "AI 编程 IDE，适合让智能体帮你写代码和改项目。",
  "Trae CN": "Trae 中文版 AI 编程工具，适合中文开发工作流。",
  "Google Antigravity": "Google AI 开发工具，适合探索智能体式编码流程。",
  "Transmit": "经典文件传输客户端，FTP、SFTP 和云端文件管理都很稳。",
  "Todoist": "清爽的任务管理工具，适合收集待办和安排优先级。",
  "Asana": "团队项目管理工具，适合跟踪任务、责任人和进度。",
  "OmniFocus": "GTD 任务管理工具，适合把复杂个人待办梳理清楚。",
  "Inkscape": "开源矢量绘图工具，适合 Logo、插画和 SVG 编辑。",
  "Abstract": "设计版本协作工具，适合管理 Sketch 文件和设计交付。",
  "RawTherapee": "开源 RAW 照片处理工具，适合摄影调色和细节恢复。",
  "Acorn": "轻量图像编辑器，修图、标注和简单设计都很快。",
  "Canon UFR II/UFRII LT/LIPSLX/CARPS2 Printer Driver": "佳能打印驱动包，保证办公打印机在 Mac 上正常工作。",
  "calibre": "电子书管理器，适合整理、转换和同步书库。",
  "Anki": "间隔重复记忆工具，背词、考试和长期学习都很强。"
}));

function lower(value) {
  return String(value ?? "").toLowerCase();
}

function tagSet(row) {
  return new Set(splitTags(row.defaultTagIDs));
}

function noteFromDescription(row, meta) {
  const name = row.appName;
  const tags = tagSet(row);
  const description = lower(meta.description);
  const token = lower(row.homebrewToken || row.normalizedName || name);
  const text = `${description} ${token}`;

  if (/container|microservice|docker|kubernetes|linux environment|virtualization/.test(text)) {
    return `${name} 适合运行容器、虚拟环境或本地开发服务。`;
  }
  if (/digital audio production|audio workstation|music production|daw|midi/.test(text)) {
    return `${name} 适合录音、编曲、混音或调试音频设备。`;
  }
  if (/dcp|digital cinema package|cinema/.test(text)) {
    return `${name} 适合处理影院放映用的视频、音频和 DCP 流程。`;
  }
  if (/dicom|medical image|medical images/.test(text)) {
    return `${name} 适合查看、分析和管理医学影像。`;
  }
  if (/game launcher|cloud gaming|gamestream|emulator|emulators|\brom\b|roms|minecraft|roblox|game engine|\bsteam\b|battle/.test(text)) {
    return `${name} 适合启动、串流、模拟或管理游戏内容。`;
  }
  if (/code editor|text editor|source editor|integrated development environment|\bide\b/.test(text)) {
    return `${name} 适合写代码、改文本和管理开发项目。`;
  }
  if (/web debugging proxy|proxy application|http proxy|network analyzer/.test(text)) {
    return `${name} 适合抓包、代理和分析网络请求。`;
  }
  if (/mux|metadata|tag mp4|rename digital photos|exif/.test(text)) {
    return `${name} 适合整理媒体元数据、命名或封装文件。`;
  }
  if (/database|sql|postgres|mysql|mongodb|redis|sqlite/.test(text)) {
    return `${name} 用来查看、查询和管理数据库。`;
  }
  if (/pdf|acrobat|foxit/.test(text) && tags.has("writing")) {
    return `${name} 适合阅读、批注、签署或编辑 PDF 文件。`;
  }
  if (/calendar|calendr|clocker|schedule|busycal|morgen|itsycal/.test(text)) {
    return `${name} 适合查看日程、安排时间和处理跨时区计划。`;
  }
  if (/mail|email|gmail|outlook|mimestream|spark/.test(text) && tags.has("communication")) {
    return `${name} 是邮件工具，适合集中处理收件箱和通信。`;
  }
  if (/password|pass|vault|encrypt|crypto|wallet|security|vpn|firewall|gpg|pgp/.test(text) && tags.has("security")) {
    return `${name} 适合管理密码、密钥、隐私或安全连接。`;
  }
  if (/diagram|flowchart|mind map|uml|plantuml|draw|whiteboard|wireframe/.test(text)) {
    return `${name} 适合画流程图、结构图或头脑风暴草图。`;
  }
  if (/font|typeface|rightfont/.test(text)) {
    return `${name} 适合管理字体、预览字形和整理设计字库。`;
  }
  if (/screenshot|screen capture|snip|shot|flameshot|cleanshot|textsniper/.test(text)) {
    return `${name} 适合截图、标注、识别文字或制作视觉反馈。`;
  }
  if (/download|youtube|torrent|ftp|sftp|transfer|sync|cloud|drive|dropbox|cyberduck|transmit/.test(text)
      && (tags.has("transfer") || tags.has("file-management"))) {
    return `${name} 适合下载、同步、传输或管理文件。`;
  }
  if (/window|menu bar|clipboard|keyboard|mouse|notch|display|monitor|shortcut|hotkey|launcher/.test(text)
      && tags.has("system-enhancement")) {
    return `${name} 用来增强 Mac 日常操作，让系统更顺手。`;
  }
  if (tags.has("communication") && tags.has("video")) {
    return `${name} 是音视频沟通工具，适合会议、课程和远程协作。`;
  }
  if (tags.has("game") && tags.has("development")) {
    return `${name} 适合游戏开发、调试或管理游戏项目。`;
  }
  if (tags.has("browser")) {
    if (/developer|debug|responsive|web/i.test(text)) return `${name} 是网页调试和浏览工具，适合开发者检查页面细节。`;
    return `${name} 是浏览器入口，适合浏览网页、查资料和管理在线工作。`;
  }
  if (tags.has("communication") && tags.has("ai-tools")) {
    return `${name} 用 AI 帮你处理沟通、会议或信息整理。`;
  }
  if (tags.has("development") && tags.has("ai-tools")) {
    return `${name} 把 AI 带进开发流程，适合写代码、调试和自动化。`;
  }
  if (tags.has("development") && /api|http|request|proxy|network/i.test(text)) {
    return `${name} 适合调试接口、网络请求和开发环境。`;
  }
  if (tags.has("development") && /terminal|shell|command|cli/i.test(text)) {
    return `${name} 是命令行工作台，适合开发、脚本和系统操作。`;
  }
  if (tags.has("development")) {
    return `${name} 是开发工具，适合写代码、调试或管理工程项目。`;
  }
  if (tags.has("video")) {
    return `${name} 适合播放、录制、剪辑或转换视频。`;
  }
  if (tags.has("audio")) {
    return `${name} 适合播放、录制、剪辑或管理音频。`;
  }
  if (tags.has("design") && tags.has("picture-photo")) {
    return `${name} 适合修图、视觉设计和管理创意素材。`;
  }
  if (tags.has("design") && /3d|cad|model|render|bim|mesh/i.test(text)) {
    return `${name} 适合建模、渲染和三维设计工作。`;
  }
  if (tags.has("design")) {
    return `${name} 适合界面、图形、原型或视觉设计。`;
  }
  if (tags.has("writing") && tags.has("education")) {
    return `${name} 适合阅读、引用、学习资料和研究笔记。`;
  }
  if (tags.has("writing") && tags.has("productivity")) {
    return `${name} 适合整理笔记、文档和长期知识资料。`;
  }
  if (tags.has("writing")) {
    return `${name} 适合写作、记录和处理文档。`;
  }
  if (tags.has("finance") && tags.has("security")) {
    return `${name} 适合管理钱包、资产或安全相关的金融操作。`;
  }
  if (tags.has("finance")) {
    return `${name} 适合记账、投资、预算或财务分析。`;
  }
  if (tags.has("game")) {
    return `${name} 是游戏相关工具，适合启动、管理或畅玩游戏。`;
  }
  if (tags.has("picture-photo")) {
    return `${name} 适合处理照片、图片或截图素材。`;
  }
  if (tags.has("communication")) {
    return `${name} 用来处理聊天、邮件或团队沟通。`;
  }
  if (tags.has("security")) {
    return `${name} 适合保护账号、隐私、连接或本地文件安全。`;
  }
  if (tags.has("file-management") || tags.has("transfer")) {
    return `${name} 适合管理、同步、下载或传输文件。`;
  }
  if (tags.has("system-enhancement")) {
    return `${name} 用来增强 Mac 系统体验，让日常操作更顺手。`;
  }
  if (tags.has("education")) {
    return `${name} 适合学习、阅读、课程或研究资料管理。`;
  }
  if (tags.has("productivity")) {
    return `${name} 适合任务、日程、资料或团队协作管理。`;
  }
  if (tags.has("utilities")) {
    return `${name} 是实用工具，适合解决某个具体的小麻烦。`;
  }
  return `${name} 是一个专业工具，适合在需要时快速完成特定任务。`;
}

function build() {
  const uniqueCSV = readCSVObjects(uniquePath);
  const masterRows = readCSVObjects(masterPath).rows;
  const masterBySlug = new Map(masterRows.map((row) => [row.normalizedName, row]));

  const outputHeader = uniqueCSV.header.includes("defaultNoteZH")
    ? uniqueCSV.header
    : [...uniqueCSV.header, "defaultNoteZH"];

  const outputRows = uniqueCSV.rows.map((row) => {
    const meta = masterBySlug.get(row.normalizedName) ?? {};
    const manual = manualNotes.get(row.appName);
    const note = limitNote(manual ?? noteFromDescription(row, meta));
    return { ...row, defaultNoteZH: note };
  });

  const csvRows = [
    outputHeader,
    ...outputRows.map((row) => outputHeader.map((column) => row[column] ?? "")),
  ];
  fs.writeFileSync(uniquePath, `${stringifyCSV(csvRows)}\n`);

  const emptyRows = outputRows.filter((row) => !row.defaultNoteZH.trim());
  const overLimitRows = outputRows.filter((row) => noteLength(row.defaultNoteZH) > noteLimit);
  const manualRows = outputRows.filter((row) => manualNotes.has(row.appName));
  const generatedRows = outputRows.filter((row) => !manualNotes.has(row.appName));
  const lengths = outputRows.map((row) => noteLength(row.defaultNoteZH));
  const duplicateNotes = new Map();
  for (const row of outputRows) {
    duplicateNotes.set(row.defaultNoteZH, [...(duplicateNotes.get(row.defaultNoteZH) ?? []), row.appName]);
  }
  const repeatedNotes = [...duplicateNotes.entries()]
    .filter(([, names]) => names.length > 1)
    .sort((left, right) => right[1].length - left[1].length || left[0].localeCompare(right[0]));

  const samples = outputRows
    .filter((row) => Number(row.personaCount) >= 5 || manualNotes.has(row.appName))
    .slice(0, 40)
    .map((row) => `- ${row.appName}: ${row.defaultNoteZH}`)
    .join("\n");
  const repeatedSummary = repeatedNotes.slice(0, 20)
    .map(([note, names]) => `- ${names.length} apps share: ${note}`)
    .join("\n") || "- None";

  const report = `# Persona App Notes Quality Report

Generated: ${new Date().toISOString()}

## Output

- Updated CSV: \`Research/SmartStart/PersonaTopApps/MacPersonaTopApps_Unique.csv\`
- Added/updated column: \`defaultNoteZH\`

## Rules

- Every note must be non-empty.
- Every note must be at most ${noteLimit} Unicode characters, matching TagLauncher's app note limit.
- Notes are written as Chinese product copy and are meant to be editable by users after import/seeding.

## Summary

- Rows: ${outputRows.length}
- Manual curated notes: ${manualRows.length}
- Rule-generated notes: ${generatedRows.length}
- Empty notes: ${emptyRows.length}
- Over-limit notes: ${overLimitRows.length}
- Max note length: ${Math.max(...lengths)}
- Average note length: ${(lengths.reduce((sum, value) => sum + value, 0) / lengths.length).toFixed(1)}
- Repeated note texts: ${repeatedNotes.length}

## Sample Notes

${samples}

## Most Repeated Generated Notes

${repeatedSummary}
`;

  fs.writeFileSync(reportPath, report);

  return {
    rows: outputRows.length,
    manualNotes: manualRows.length,
    generatedNotes: generatedRows.length,
    emptyNotes: emptyRows.length,
    overLimitNotes: overLimitRows.length,
    maxLength: Math.max(...lengths),
    reportPath,
    uniquePath,
  };
}

console.log(JSON.stringify(build(), null, 2));
