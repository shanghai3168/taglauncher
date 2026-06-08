#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const outputDir = path.resolve(scriptDir, "..");
const projectDir = path.resolve(outputDir, "../..");
const smartStartCSV = path.join(
  projectDir,
  "Research",
  "SmartStart",
  "UltimateDefaultCatalog",
  "SmartStart_UltimateDefaultCatalog.csv",
);
const sourceCSV = path.join(outputDir, "AppleDefaultApps.source.csv");
const translationsFile = path.join(outputDir, "AppleDefaultApps.translations.json");
const localizationDir = path.join(projectDir, "Apptag", "Localization");
const l10nSwift = path.join(projectDir, "Apptag", "L10n.swift");

const resourceFormatVersion = 1;
const catalogContentVersion = 1;
const localizationsVersion = 2;
const noteLimit = 80;
const familiarBundleIDs = new Set([
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
  "com.apple.systempreferences",
]);

const canonicalNames = {
  finder: "Finder",
  safari: "Safari",
  mail: "Mail",
  messages: "Messages",
  facetime: "FaceTime",
  calendar: "Calendar",
  notes: "Notes",
  reminders: "Reminders",
  photos: "Photos",
  music: "Music",
  terminal: "Terminal",
  "activity-monitor": "Activity Monitor",
  "airport-utility": "AirPort Utility",
  "app-store": "App Store",
  apps: "Apps",
  "audio-midi-setup": "Audio MIDI Setup",
  automator: "Automator",
  "bluetooth-file-exchange": "Bluetooth File Exchange",
  books: "Books",
  "boot-camp-assistant": "Boot Camp Assistant",
  calculator: "Calculator",
  chess: "Chess",
  clock: "Clock",
  "colorsync-utility": "ColorSync Utility",
  console: "Console",
  contacts: "Contacts",
  dictionary: "Dictionary",
  "digital-color-meter": "Digital Color Meter",
  "disk-utility": "Disk Utility",
  "find-my": "Find My",
  "font-book": "Font Book",
  freeform: "Freeform",
  games: "Games",
  grapher: "Grapher",
  home: "Home",
  "image-capture": "Image Capture",
  "image-playground": "Image Playground",
  imovie: "iMovie",
  "iphone-mirroring": "iPhone Mirroring",
  journal: "Journal",
  keynote: "Keynote",
  magnifier: "Magnifier",
  maps: "Maps",
  "migration-assistant": "Migration Assistant",
  "mission-control": "Mission Control",
  news: "News",
  numbers: "Numbers",
  pages: "Pages",
  passwords: "Passwords",
  phone: "Phone",
  "about-this-mac": "About This Mac",
  "archive-utility": "Archive Utility",
  "desk-view": "Desk View",
  "directory-utility": "Directory Utility",
  "dvd-player": "DVD Player",
  "expansion-slot-utility": "Expansion Slot Utility",
  "feedback-assistant": "Feedback Assistant",
  "folder-actions-setup": "Folder Actions Setup",
  "ios-app-installer": "iOS App Installer",
  "keychain-access": "Keychain Access",
  "ticket-viewer": "Ticket Viewer",
  "wireless-diagnostics": "Wireless Diagnostics",
  "photo-booth": "Photo Booth",
  podcasts: "Podcasts",
  preview: "Preview",
  "print-center": "Print Center",
  "quicktime-player": "QuickTime Player",
  "screen-sharing": "Screen Sharing",
  screenshot: "Screenshot",
  "script-editor": "Script Editor",
  "sf-symbols": "SF Symbols",
  shortcuts: "Shortcuts",
  siri: "Siri",
  stickies: "Stickies",
  stocks: "Stocks",
  "system-information": "System Information",
  "system-settings": "System Settings",
  textedit: "TextEdit",
  "time-machine": "Time Machine",
  tips: "Tips",
  tv: "TV",
  "voice-memos": "Voice Memos",
  "voiceover-utility": "VoiceOver Utility",
  weather: "Weather",
  xcode: "Xcode",
  garageband: "GarageBand",
  "final-cut-pro": "Final Cut Pro",
  "logic-pro": "Logic Pro",
  testflight: "TestFlight",
};

const zhHansNames = {
  finder: "访达",
  mail: "邮件",
  messages: "信息",
  calendar: "日历",
  notes: "备忘录",
  reminders: "提醒事项",
  photos: "照片",
  music: "音乐",
  terminal: "终端",
  "activity-monitor": "活动监视器",
  "airport-utility": "AirPort 实用工具",
  apps: "应用程序",
  "audio-midi-setup": "音频 MIDI 设置",
  automator: "自动操作",
  "bluetooth-file-exchange": "蓝牙文件交换",
  books: "图书",
  "boot-camp-assistant": "启动转换助理",
  calculator: "计算器",
  chess: "国际象棋",
  clock: "时钟",
  "colorsync-utility": "ColorSync 实用工具",
  console: "控制台",
  contacts: "通讯录",
  dictionary: "词典",
  "digital-color-meter": "数码测色计",
  "disk-utility": "磁盘工具",
  "find-my": "查找",
  "font-book": "字体册",
  games: "游戏",
  grapher: "图形计算器",
  home: "家庭",
  "image-capture": "图像捕捉",
  "image-playground": "图像乐园",
  imovie: "iMovie 剪辑",
  "iphone-mirroring": "iPhone 镜像",
  journal: "日记",
  keynote: "讲演",
  magnifier: "放大器",
  maps: "地图",
  "migration-assistant": "迁移助理",
  "mission-control": "调度中心",
  news: "新闻",
  numbers: "表格",
  pages: "文稿",
  passwords: "密码",
  phone: "电话",
  podcasts: "播客",
  preview: "预览",
  "print-center": "打印中心",
  "screen-sharing": "屏幕共享",
  screenshot: "截屏",
  "script-editor": "脚本编辑器",
  shortcuts: "快捷指令",
  stickies: "便笺",
  stocks: "股市",
  "system-information": "系统信息",
  "system-settings": "系统设置",
  textedit: "文本编辑",
  "time-machine": "时间机器",
  tips: "提示",
  "voice-memos": "语音备忘录",
  "voiceover-utility": "VoiceOver 实用工具",
  weather: "天气",
};

const zhHantNames = {
  finder: "訪達",
  mail: "郵件",
  messages: "訊息",
  calendar: "行事曆",
  notes: "備忘錄",
  reminders: "提醒事項",
  photos: "照片",
  music: "音樂",
  terminal: "終端機",
  "activity-monitor": "活動監視器",
  "airport-utility": "AirPort 工具程式",
  apps: "應用程式",
  "audio-midi-setup": "音訊 MIDI 設定",
  automator: "自動操作",
  "bluetooth-file-exchange": "藍牙檔案交換",
  books: "書籍",
  "boot-camp-assistant": "啟動切換輔助程式",
  calculator: "計算機",
  chess: "西洋棋",
  clock: "時鐘",
  "colorsync-utility": "ColorSync 工具程式",
  console: "主控台",
  contacts: "聯絡人",
  dictionary: "辭典",
  "digital-color-meter": "數位測色計",
  "disk-utility": "磁碟工具",
  "find-my": "尋找",
  "font-book": "字體簿",
  games: "遊戲",
  grapher: "圖形計算機",
  home: "家庭",
  "image-capture": "影像擷取",
  "image-playground": "圖像樂園",
  imovie: "iMovie",
  "iphone-mirroring": "iPhone 鏡像輸出",
  journal: "日誌",
  keynote: "Keynote",
  magnifier: "放大鏡",
  maps: "地圖",
  "migration-assistant": "移轉輔助程式",
  "mission-control": "Mission Control",
  news: "新聞",
  numbers: "Numbers",
  pages: "Pages",
  passwords: "密碼",
  phone: "電話",
  podcasts: "Podcast",
  preview: "預覽程式",
  "print-center": "列印中心",
  "screen-sharing": "螢幕共享",
  screenshot: "截圖",
  "script-editor": "指令稿編輯器",
  shortcuts: "捷徑",
  stickies: "便條紙",
  stocks: "股市",
  "system-information": "系統資訊",
  "system-settings": "系統設定",
  textedit: "文字編輯",
  "time-machine": "時光機",
  tips: "提示",
  "voice-memos": "語音備忘錄",
  "voiceover-utility": "VoiceOver 工具程式",
  weather: "天氣",
};

const noteTemplates = {
  en: (name, purpose) => `${name}: Apple app for ${purpose} on Mac`,
  "zh-Hant": (name, purpose) => `${name}：Apple 內建 App，適合${purpose}`,
  fr: (name, purpose) => `${name} : app Apple pour ${purpose} sur Mac`,
  it: (name, purpose) => `${name}: app Apple per ${purpose} su Mac`,
  de: (name, purpose) => `${name}: Apple-App für ${purpose} auf dem Mac`,
  es: (name, purpose) => `${name}: app de Apple para ${purpose} en Mac`,
  "pt-BR": (name, purpose) => `${name}: app da Apple para ${purpose} no Mac`,
  ko: (name, purpose) => `${name}: Mac에서 ${purpose}에 쓰는 Apple 앱`,
  ja: (name, purpose) => `${name}: Macで${purpose}に使うApple純正アプリ`,
  ru: (name, purpose) => `${name}: приложение Apple для ${purpose} на Mac`,
  "sr-Cyrl": (name, purpose) => `${name}: Apple апликација за ${purpose} на Mac-у`,
  uk: (name, purpose) => `${name}: програма Apple для ${purpose} на Mac`,
  th: (name, purpose) => `${name}: แอป Apple สำหรับ${purpose}บน Mac`,
  vi: (name, purpose) => `${name}: ứng dụng Apple cho ${purpose} trên Mac`,
  ar: (name, purpose) => `${name}: تطبيق Apple لـ ${purpose} على Mac`,
  "ar-Najdi": (name, purpose) => `${name}: تطبيق Apple لـ ${purpose} على Mac`,
  tr: (name, purpose) => `${name}: Mac'te ${purpose} için Apple uygulaması`,
  id: (name, purpose) => `${name}: app Apple untuk ${purpose} di Mac`,
  cs: (name, purpose) => `${name}: aplikace Apple pro ${purpose} na Macu`,
  da: (name, purpose) => `${name}: Apple-app til ${purpose} på Mac`,
  nl: (name, purpose) => `${name}: Apple-app voor ${purpose} op Mac`,
  no: (name, purpose) => `${name}: Apple-app for ${purpose} på Mac`,
  nn: (name, purpose) => `${name}: Apple-app for ${purpose} på Mac`,
  nb: (name, purpose) => `${name}: Apple-app for ${purpose} på Mac`,
  ms: (name, purpose) => `${name}: app Apple untuk ${purpose} pada Mac`,
  pl: (name, purpose) => `${name}: aplikacja Apple do ${purpose} na Macu`,
  ro: (name, purpose) => `${name}: aplicație Apple pentru ${purpose} pe Mac`,
  sv: (name, purpose) => `${name}: Apple-app för ${purpose} på Mac`,
};

const purposeByPrimaryTag = {
  browser: "browsing",
  communication: "communication",
  GTD: "productivity",
  Notes: "productivity",
  office: "productivity",
  PDF: "productivity",
  writing: "productivity",
  "file-management": "files",
  transfer: "files",
  video: "video",
  audio: "audio",
  media: "media",
  "picture-photo": "photos",
  utilities: "utilities",
  system: "system",
  "system-maintenance": "maintenance",
  "device-management": "devices",
  "network-tools": "system",
  security: "security",
  Automation: "automation",
  "terminal-tools": "development",
  ide: "development",
  "ai-tools": "development",
  "ui-prototyping": "design",
  Font: "design",
  game: "entertainment",
  entertainment: "entertainment",
  education: "education",
  finance: "finance",
};

const purposeTerms = {
  en: { browsing: "web browsing", communication: "communication", productivity: "notes and productivity", files: "files and transfers", photos: "photos and images", media: "media playback", audio: "audio work", video: "video work", utilities: "utilities", system: "system settings", maintenance: "system maintenance", devices: "device management", security: "security", automation: "automation", development: "development", design: "design work", entertainment: "games and entertainment", education: "learning", finance: "finance" },
  "zh-Hant": { browsing: "網頁瀏覽", communication: "通訊", productivity: "筆記和生產力", files: "檔案和傳輸", photos: "照片和影像", media: "媒體播放", audio: "音訊工作", video: "影片工作", utilities: "實用工具", system: "系統設定", maintenance: "系統維護", devices: "裝置管理", security: "安全管理", automation: "自動化", development: "開發工作", design: "設計工作", entertainment: "遊戲和娛樂", education: "學習", finance: "財務資訊" },
  fr: { browsing: "la navigation web", communication: "la communication", productivity: "les notes et la productivité", files: "les fichiers et transferts", photos: "les photos et images", media: "la lecture multimédia", audio: "le travail audio", video: "le travail vidéo", utilities: "les utilitaires", system: "les réglages système", maintenance: "la maintenance système", devices: "la gestion des appareils", security: "la sécurité", automation: "l'automatisation", development: "le développement", design: "le design", entertainment: "les jeux et loisirs", education: "l'apprentissage", finance: "la finance" },
  it: { browsing: "la navigazione web", communication: "la comunicazione", productivity: "note e produttività", files: "file e trasferimenti", photos: "foto e immagini", media: "la riproduzione multimediale", audio: "il lavoro audio", video: "il lavoro video", utilities: "le utilità", system: "le impostazioni di sistema", maintenance: "la manutenzione del sistema", devices: "la gestione dei dispositivi", security: "la sicurezza", automation: "l'automazione", development: "lo sviluppo", design: "il design", entertainment: "giochi e intrattenimento", education: "l'apprendimento", finance: "la finanza" },
  de: { browsing: "Web-Browsing", communication: "Kommunikation", productivity: "Notizen und Produktivität", files: "Dateien und Übertragungen", photos: "Fotos und Bilder", media: "Medienwiedergabe", audio: "Audioarbeit", video: "Videoarbeit", utilities: "Dienstprogramme", system: "Systemeinstellungen", maintenance: "Systemwartung", devices: "Geräteverwaltung", security: "Sicherheit", automation: "Automatisierung", development: "Entwicklung", design: "Designarbeit", entertainment: "Spiele und Unterhaltung", education: "Lernen", finance: "Finanzen" },
  es: { browsing: "navegación web", communication: "comunicación", productivity: "notas y productividad", files: "archivos y transferencias", photos: "fotos e imágenes", media: "reproducción multimedia", audio: "trabajo de audio", video: "trabajo de vídeo", utilities: "utilidades", system: "ajustes del sistema", maintenance: "mantenimiento del sistema", devices: "gestión de dispositivos", security: "seguridad", automation: "automatización", development: "desarrollo", design: "diseño", entertainment: "juegos y ocio", education: "aprendizaje", finance: "finanzas" },
  "pt-BR": { browsing: "navegação web", communication: "comunicação", productivity: "notas e produtividade", files: "arquivos e transferências", photos: "fotos e imagens", media: "reprodução de mídia", audio: "trabalho com áudio", video: "trabalho com vídeo", utilities: "utilitários", system: "ajustes do sistema", maintenance: "manutenção do sistema", devices: "gerenciamento de dispositivos", security: "segurança", automation: "automação", development: "desenvolvimento", design: "design", entertainment: "jogos e entretenimento", education: "aprendizado", finance: "finanças" },
  ko: { browsing: "웹 탐색", communication: "커뮤니케이션", productivity: "메모와 생산성", files: "파일과 전송", photos: "사진과 이미지", media: "미디어 재생", audio: "오디오 작업", video: "비디오 작업", utilities: "유틸리티", system: "시스템 설정", maintenance: "시스템 관리", devices: "기기 관리", security: "보안", automation: "자동화", development: "개발", design: "디자인 작업", entertainment: "게임과 엔터테인먼트", education: "학습", finance: "금융" },
  ja: { browsing: "Webブラウズ", communication: "コミュニケーション", productivity: "メモと生産性", files: "ファイルと転送", photos: "写真と画像", media: "メディア再生", audio: "オーディオ作業", video: "ビデオ作業", utilities: "ユーティリティ", system: "システム設定", maintenance: "システム保守", devices: "デバイス管理", security: "セキュリティ", automation: "自動化", development: "開発", design: "デザイン作業", entertainment: "ゲームとエンタメ", education: "学習", finance: "金融情報" },
  ru: { browsing: "веб-навигации", communication: "общения", productivity: "заметок и продуктивности", files: "файлов и передачи", photos: "фото и изображений", media: "мультимедиа", audio: "работы со звуком", video: "работы с видео", utilities: "утилит", system: "системных настроек", maintenance: "обслуживания системы", devices: "управления устройствами", security: "безопасности", automation: "автоматизации", development: "разработки", design: "дизайна", entertainment: "игр и развлечений", education: "обучения", finance: "финансов" },
  "sr-Cyrl": { browsing: "веб прегледање", communication: "комуникацију", productivity: "белешке и продуктивност", files: "датотеке и преносе", photos: "фотографије и слике", media: "медије", audio: "аудио рад", video: "видео рад", utilities: "услужне алате", system: "системска подешавања", maintenance: "одржавање система", devices: "управљање уређајима", security: "безбедност", automation: "аутоматизацију", development: "развој", design: "дизајн", entertainment: "игре и забаву", education: "учење", finance: "финансије" },
  uk: { browsing: "перегляду вебу", communication: "спілкування", productivity: "нотаток і продуктивності", files: "файлів і передавання", photos: "фото й зображень", media: "медіа", audio: "роботи зі звуком", video: "роботи з відео", utilities: "утиліт", system: "системних налаштувань", maintenance: "обслуговування системи", devices: "керування пристроями", security: "безпеки", automation: "автоматизації", development: "розробки", design: "дизайну", entertainment: "ігор і розваг", education: "навчання", finance: "фінансів" },
  th: { browsing: "การท่องเว็บ", communication: "การสื่อสาร", productivity: "โน้ตและงานประสิทธิภาพ", files: "ไฟล์และการถ่ายโอน", photos: "รูปภาพและภาพถ่าย", media: "การเล่นสื่อ", audio: "งานเสียง", video: "งานวิดีโอ", utilities: "ยูทิลิตี้", system: "การตั้งค่าระบบ", maintenance: "การดูแลระบบ", devices: "การจัดการอุปกรณ์", security: "ความปลอดภัย", automation: "อัตโนมัติ", development: "การพัฒนา", design: "งานออกแบบ", entertainment: "เกมและความบันเทิง", education: "การเรียนรู้", finance: "การเงิน" },
  vi: { browsing: "duyệt web", communication: "liên lạc", productivity: "ghi chú và năng suất", files: "tệp và chuyển dữ liệu", photos: "ảnh và hình ảnh", media: "phát phương tiện", audio: "xử lý âm thanh", video: "xử lý video", utilities: "tiện ích", system: "cài đặt hệ thống", maintenance: "bảo trì hệ thống", devices: "quản lý thiết bị", security: "bảo mật", automation: "tự động hóa", development: "phát triển", design: "thiết kế", entertainment: "trò chơi và giải trí", education: "học tập", finance: "tài chính" },
  ar: { browsing: "تصفح الويب", communication: "التواصل", productivity: "الملاحظات والإنتاجية", files: "الملفات والنقل", photos: "الصور", media: "تشغيل الوسائط", audio: "العمل الصوتي", video: "العمل المرئي", utilities: "الأدوات", system: "إعدادات النظام", maintenance: "صيانة النظام", devices: "إدارة الأجهزة", security: "الأمان", automation: "الأتمتة", development: "التطوير", design: "التصميم", entertainment: "الألعاب والترفيه", education: "التعلم", finance: "المال" },
  "ar-Najdi": { browsing: "تصفح الويب", communication: "التواصل", productivity: "الملاحظات والإنتاجية", files: "الملفات والنقل", photos: "الصور", media: "تشغيل الوسائط", audio: "العمل الصوتي", video: "العمل المرئي", utilities: "الأدوات", system: "إعدادات النظام", maintenance: "صيانة النظام", devices: "إدارة الأجهزة", security: "الأمان", automation: "الأتمتة", development: "التطوير", design: "التصميم", entertainment: "الألعاب والترفيه", education: "التعلم", finance: "المال" },
  tr: { browsing: "web gezintisi", communication: "iletişim", productivity: "notlar ve üretkenlik", files: "dosyalar ve aktarımlar", photos: "fotoğraflar ve görseller", media: "medya oynatma", audio: "ses çalışmaları", video: "video çalışmaları", utilities: "yardımcı araçlar", system: "sistem ayarları", maintenance: "sistem bakımı", devices: "aygıt yönetimi", security: "güvenlik", automation: "otomasyon", development: "geliştirme", design: "tasarım", entertainment: "oyun ve eğlence", education: "öğrenme", finance: "finans" },
  id: { browsing: "menjelajah web", communication: "komunikasi", productivity: "catatan dan produktivitas", files: "file dan transfer", photos: "foto dan gambar", media: "pemutaran media", audio: "pekerjaan audio", video: "pekerjaan video", utilities: "utilitas", system: "pengaturan sistem", maintenance: "pemeliharaan sistem", devices: "manajemen perangkat", security: "keamanan", automation: "otomatisasi", development: "pengembangan", design: "desain", entertainment: "game dan hiburan", education: "belajar", finance: "keuangan" },
  cs: { browsing: "prohlížení webu", communication: "komunikaci", productivity: "poznámky a produktivitu", files: "soubory a přenosy", photos: "fotky a obrázky", media: "přehrávání médií", audio: "práci se zvukem", video: "práci s videem", utilities: "nástroje", system: "systémová nastavení", maintenance: "údržbu systému", devices: "správu zařízení", security: "zabezpečení", automation: "automatizaci", development: "vývoj", design: "design", entertainment: "hry a zábavu", education: "učení", finance: "finance" },
  da: { browsing: "webbrowsing", communication: "kommunikation", productivity: "noter og produktivitet", files: "filer og overførsler", photos: "fotos og billeder", media: "medieafspilning", audio: "lydarbejde", video: "videoarbejde", utilities: "hjælpeværktøjer", system: "systemindstillinger", maintenance: "systemvedligeholdelse", devices: "enhedsstyring", security: "sikkerhed", automation: "automatisering", development: "udvikling", design: "design", entertainment: "spil og underholdning", education: "læring", finance: "finans" },
  nl: { browsing: "webbrowsen", communication: "communicatie", productivity: "notities en productiviteit", files: "bestanden en overdracht", photos: "foto's en afbeeldingen", media: "media afspelen", audio: "audiowerk", video: "videowerk", utilities: "hulpprogramma's", system: "systeeminstellingen", maintenance: "systeemonderhoud", devices: "apparaatbeheer", security: "beveiliging", automation: "automatisering", development: "ontwikkeling", design: "ontwerp", entertainment: "games en entertainment", education: "leren", finance: "financiën" },
  no: { browsing: "nettlesing", communication: "kommunikasjon", productivity: "notater og produktivitet", files: "filer og overføringer", photos: "bilder og foto", media: "medieavspilling", audio: "lydarbeid", video: "videoarbeid", utilities: "verktøy", system: "systeminnstillinger", maintenance: "systemvedlikehold", devices: "enhetsstyring", security: "sikkerhet", automation: "automatisering", development: "utvikling", design: "designarbeid", entertainment: "spill og underholdning", education: "læring", finance: "finans" },
  nn: { browsing: "nettlesing", communication: "kommunikasjon", productivity: "notat og produktivitet", files: "filer og overføringar", photos: "bilete og foto", media: "medieavspeling", audio: "lydarbeid", video: "videoarbeid", utilities: "verktøy", system: "systeminnstillingar", maintenance: "systemvedlikehald", devices: "einingstyring", security: "tryggleik", automation: "automatisering", development: "utvikling", design: "designarbeid", entertainment: "spel og underhaldning", education: "læring", finance: "finans" },
  nb: { browsing: "nettlesing", communication: "kommunikasjon", productivity: "notater og produktivitet", files: "filer og overføringer", photos: "bilder og foto", media: "medieavspilling", audio: "lydarbeid", video: "videoarbeid", utilities: "verktøy", system: "systeminnstillinger", maintenance: "systemvedlikehold", devices: "enhetsstyring", security: "sikkerhet", automation: "automatisering", development: "utvikling", design: "designarbeid", entertainment: "spill og underholdning", education: "læring", finance: "finans" },
  ms: { browsing: "pelayaran web", communication: "komunikasi", productivity: "nota dan produktiviti", files: "fail dan pemindahan", photos: "foto dan imej", media: "main balik media", audio: "kerja audio", video: "kerja video", utilities: "utiliti", system: "tetapan sistem", maintenance: "penyelenggaraan sistem", devices: "pengurusan peranti", security: "keselamatan", automation: "automasi", development: "pembangunan", design: "reka bentuk", entertainment: "permainan dan hiburan", education: "pembelajaran", finance: "kewangan" },
  pl: { browsing: "przeglądania sieci", communication: "komunikacji", productivity: "notatek i produktywności", files: "plików i transferów", photos: "zdjęć i obrazów", media: "odtwarzania multimediów", audio: "pracy z audio", video: "pracy z wideo", utilities: "narzędzi", system: "ustawień systemu", maintenance: "konserwacji systemu", devices: "zarządzania urządzeniami", security: "bezpieczeństwa", automation: "automatyzacji", development: "programowania", design: "projektowania", entertainment: "gier i rozrywki", education: "nauki", finance: "finansów" },
  ro: { browsing: "navigare web", communication: "comunicare", productivity: "notițe și productivitate", files: "fișiere și transferuri", photos: "poze și imagini", media: "redare media", audio: "lucru audio", video: "lucru video", utilities: "utilitare", system: "setări de sistem", maintenance: "întreținere sistem", devices: "gestionare dispozitive", security: "securitate", automation: "automatizare", development: "dezvoltare", design: "design", entertainment: "jocuri și divertisment", education: "învățare", finance: "finanțe" },
  sv: { browsing: "webbsurfning", communication: "kommunikation", productivity: "anteckningar och produktivitet", files: "filer och överföringar", photos: "bilder och foton", media: "medieuppspelning", audio: "ljudarbete", video: "videoarbete", utilities: "verktyg", system: "systeminställningar", maintenance: "systemunderhåll", devices: "enhetshantering", security: "säkerhet", automation: "automatisering", development: "utveckling", design: "designarbete", entertainment: "spel och underhållning", education: "lärande", finance: "finans" },
};

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
    } else if (char === "\"") {
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
  if (field || row.length) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

function stringifyCSV(rows) {
  return rows.map((row) => row.map((value) => {
    const text = String(value ?? "");
    return /[",\n\r]/.test(text) ? `"${text.replaceAll("\"", "\"\"")}"` : text;
  }).join(",")).join("\n");
}

function objectsFromCSV(text) {
  const rows = parseCSV(text).filter((row) => row.some((cell) => cell.trim()));
  const header = rows[0];
  return rows.slice(1).map((row) => Object.fromEntries(header.map((key, index) => [key, row[index] ?? ""])));
}

function loadSupportedLanguages() {
  const text = fs.readFileSync(l10nSwift, "utf8");
  const block = text.match(/static\s+let\s+supported\s*:\s*\[\(code:\s*String,\s*name:\s*String\)\]\s*=\s*\[(.*?)\n\s*\]/s);
  if (!block) throw new Error("Unable to parse L10n.supported");
  return [...block[1].matchAll(/\("([^"]+)",\s*"[^"]+"\)/g)].map((match) => match[1]);
}

function titleCaseSlug(slug) {
  return slug.split("-").map((part) => {
    if (part === "iphone") return "iPhone";
    if (part === "imovie") return "iMovie";
    return part.charAt(0).toUpperCase() + part.slice(1);
  }).join(" ");
}

function cleanBundle(value) {
  const text = String(value ?? "").trim();
  return text && !["null", "nil", "undefined"].includes(text.toLowerCase()) ? text : null;
}

function normalizedResourceText(value) {
  const text = String(value ?? "").trim();
  return text.length > 0 ? text : null;
}

function trimToWordBoundary(note) {
  const chars = Array.from(note);
  if (chars.length <= noteLimit) return note;
  let sliced = chars.slice(0, noteLimit - 1).join("");
  const lastSpace = sliced.lastIndexOf(" ");
  if (lastSpace > 24) sliced = sliced.slice(0, lastSpace);
  return sliced.trimEnd();
}

function loadTranslations(supportedLanguages, rows) {
  if (!fs.existsSync(translationsFile)) {
    throw new Error(`Missing Apple translations file: ${translationsFile}`);
  }

  const translations = JSON.parse(fs.readFileSync(translationsFile, "utf8"));
  if (translations.resourceFormatVersion !== resourceFormatVersion) {
    throw new Error(`Unsupported Apple translations resource format: ${translations.resourceFormatVersion}`);
  }
  if ((translations.translationsVersion ?? 0) < localizationsVersion) {
    throw new Error(`Apple translations version ${translations.translationsVersion} is older than required ${localizationsVersion}`);
  }

  const supported = new Set(translations.supportedLanguages ?? []);
  for (const languageCode of supportedLanguages) {
    if (!supported.has(languageCode)) {
      throw new Error(`Apple translations missing language: ${languageCode}`);
    }
  }

  for (const languageCode of supportedLanguages) {
    const displayNames = translations.displayNamesByLanguage?.[languageCode] ?? {};
    const notes = translations.notesByLanguage?.[languageCode] ?? {};
    for (const row of rows) {
      const normalizedName = String(row.normalizedName ?? "").trim();
      const displayName = normalizedResourceText(displayNames[normalizedName]);
      const note = normalizedResourceText(notes[normalizedName]);
      if (!displayName) {
        throw new Error(`Apple translations missing display name: ${languageCode}/${normalizedName}`);
      }
      if (!note) {
        throw new Error(`Apple translations missing note: ${languageCode}/${normalizedName}`);
      }
      if (Array.from(note).length > noteLimit) {
        throw new Error(`Apple translation note exceeds ${noteLimit} chars: ${languageCode}/${normalizedName}`);
      }
    }
  }

  return translations;
}

function displayNameFor(languageCode, normalizedName, canonicalName, translations) {
  const translated = normalizedResourceText(translations.displayNamesByLanguage?.[languageCode]?.[normalizedName]);
  if (translated) return translated;
  if (languageCode === "zh-Hans") return zhHansNames[normalizedName] ?? canonicalName;
  if (languageCode === "zh-Hant") return zhHantNames[normalizedName] ?? zhHansNames[normalizedName] ?? canonicalName;
  return canonicalName;
}

function noteFor(languageCode, row, translations) {
  const normalizedName = String(row.normalizedName ?? "").trim();
  const sourceNote = String(row["defaultNote-ZH"] ?? "").trim();
  if (!sourceNote) throw new Error(`Apple source note is empty: ${normalizedName}`);
  if (Array.from(sourceNote).length > noteLimit) {
    throw new Error(`Apple source note exceeds ${noteLimit} chars: ${normalizedName}`);
  }
  if (languageCode === "zh-Hans") return trimToWordBoundary(sourceNote);

  const translated = normalizedResourceText(translations.notesByLanguage?.[languageCode]?.[normalizedName]);
  if (!translated) throw new Error(`Apple translations missing note: ${languageCode}/${normalizedName}`);
  return trimToWordBoundary(translated);
}

function loadSourceRows() {
  if (fs.existsSync(sourceCSV)) {
    return objectsFromCSV(fs.readFileSync(sourceCSV, "utf8"));
  }

  const smartStartRows = objectsFromCSV(fs.readFileSync(smartStartCSV, "utf8"));
  const appleRows = smartStartRows.filter((row) => cleanBundle(row.bundleIdentifier)?.toLowerCase().startsWith("com.apple."));
  if (appleRows.length === 0) {
    throw new Error("No Apple rows found in SmartStart CSV and Apple source CSV does not exist");
  }
  const header = ["normalizedName", "tager", "bundleIdentifier", "defaultNote-ZH"];
  fs.mkdirSync(outputDir, { recursive: true });
  fs.writeFileSync(sourceCSV, `${stringifyCSV([header, ...appleRows.map((row) => header.map((key) => row[key] ?? ""))])}\n`);
  return appleRows;
}

function build() {
  fs.mkdirSync(outputDir, { recursive: true });
  const supportedLanguages = loadSupportedLanguages();
  const rows = loadSourceRows().filter((row) => cleanBundle(row.bundleIdentifier)?.toLowerCase().startsWith("com.apple."));
  if (rows.length === 0) throw new Error("Apple source rows are empty");
  const translations = loadTranslations(supportedLanguages, rows);

  const seenBundles = new Set();
  const baseEntries = rows.map((row) => {
    const bundleIdentifier = cleanBundle(row.bundleIdentifier);
    const normalizedName = String(row.normalizedName ?? "").trim();
    if (!bundleIdentifier || !normalizedName) {
      throw new Error(`Invalid Apple row: ${JSON.stringify(row)}`);
    }
    const bundleKey = bundleIdentifier.toLowerCase();
    if (seenBundles.has(bundleKey)) throw new Error(`Duplicate Apple bundle ID: ${bundleIdentifier}`);
    seenBundles.add(bundleKey);
    const canonicalName = canonicalNames[normalizedName] ?? titleCaseSlug(normalizedName);
    return {
      bundleIdentifier,
      normalizedName,
      canonicalName,
      defaultTag: String(row.tager ?? "").split("|").map((tag) => tag.trim()).filter(Boolean),
      familiar: familiarBundleIDs.has(bundleKey),
      aliases: [normalizedName, canonicalName].filter(Boolean),
    };
  });

  const base = {
    resourceFormatVersion,
    catalogContentVersion,
    noteLimit,
    supportedLanguages,
    entries: baseEntries,
  };
  fs.writeFileSync(path.join(outputDir, "AppleDefaultApps.base.json"), `${JSON.stringify(base, null, 2)}\n`);

  for (const languageCode of supportedLanguages) {
    const entries = rows.map((row) => {
      const normalizedName = String(row.normalizedName ?? "").trim();
      const canonicalName = canonicalNames[normalizedName] ?? titleCaseSlug(normalizedName);
      const note = noteFor(languageCode, row, translations);
      return {
        bundleIdentifier: cleanBundle(row.bundleIdentifier),
        displayName: displayNameFor(languageCode, normalizedName, canonicalName, translations),
        note,
      };
    });
    const catalog = {
      resourceFormatVersion,
      catalogContentVersion,
      language: languageCode,
      localizationsVersion,
      entries,
    };
    fs.writeFileSync(
      path.join(outputDir, `AppleDefaultApps.localizations.${languageCode}.json`),
      `${JSON.stringify(catalog, null, 2)}\n`,
    );
  }

  const manifest = {
    resourceFormatVersion,
    catalogContentVersion,
    localizationsVersion,
    generatedAt: new Date().toISOString(),
    source: "Research/AppleDefaultApps/AppleDefaultApps.source.csv",
    entryCount: baseEntries.length,
    supportedLanguages,
    noteLimit,
    policy: "Apple default apps are authoritative here; every supported language must have curated names and notes, and SmartStart must not carry com.apple.* defaults.",
  };
  fs.writeFileSync(path.join(outputDir, "AppleDefaultApps.manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  console.log(`Generated Apple default app resources: ${baseEntries.length} apps, ${supportedLanguages.length} languages`);
}

build();
