#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const researchDir = path.resolve(scriptDir, "..");
const outputDir = path.join(researchDir, "PersonaTopApps");

const masterPath = path.join(researchDir, "MacCommonApps_CandidateTop5000_Master.csv");
const reviewPath = path.join(researchDir, "MacCommonApps_DefaultTags_SimplifiedReview.csv");

const rawOutputPath = path.join(outputDir, "MacPersonaTopApps_20x50.csv");
const uniqueOutputPath = path.join(outputDir, "MacPersonaTopApps_Unique.csv");
const reportOutputPath = path.join(outputDir, "MacPersonaTopApps_CrossCheckReport.md");

const stableTagOrder = [
  "browser",
  "communication",
  "productivity",
  "file-management",
  "transfer",
  "development",
  "design",
  "writing",
  "media",
  "video",
  "audio",
  "picture-photo",
  "utilities",
  "system",
  "system-enhancement",
  "entertainment",
  "game",
  "finance",
  "education",
  "ai-tools",
  "security",
  "other",
];

const stableTags = new Set(stableTagOrder);

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
  return rows.slice(1).map((row) =>
    Object.fromEntries(header.map((column, index) => [column, row[index] ?? ""])),
  );
}

function slugify(value) {
  return String(value ?? "")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function splitTags(value) {
  return String(value ?? "")
    .split(/[|;,]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function unique(values) {
  const seen = new Set();
  const output = [];
  for (const value of values) {
    const trimmed = String(value ?? "").trim();
    if (!trimmed || seen.has(trimmed)) continue;
    seen.add(trimmed);
    output.push(trimmed);
  }
  return output;
}

function orderedTags(tags) {
  const cleaned = unique(tags).filter((tag) => stableTags.has(tag));
  return stableTagOrder.filter((tag) => cleaned.includes(tag));
}

function matchesAny(text, patterns) {
  return patterns.some((pattern) => pattern.test(text));
}

const personas = [
  {
    rank: 1,
    id: "software-developer",
    name: "Software Developer",
    zhName: "软件开发工程师",
    angle: "code editors, terminals, API tools, databases, containers, and AI coding assistants",
    tagWeights: { development: 10, "ai-tools": 5, utilities: 3, security: 2, productivity: 2, browser: 1 },
    keywords: [/code|coding|developer|ide|terminal|shell|api|database|sql|git|diff|merge|docker|container|kubernetes|compiler|runtime|debug/],
    seedNames: ["Visual Studio Code", "Cursor", "Xcode", "JetBrains Toolbox", "iTerm2", "Warp", "Docker Desktop", "Postman", "TablePlus", "GitHub Desktop", "Fork", "Sourcetree", "Sublime Text", "Zed", "Claude Code", "Codex", "Android Studio", "DBeaver", "MongoDB Compass", "RedisInsight"],
    allowSupportTools: true,
  },
  {
    rank: 2,
    id: "web-developer",
    name: "Web Developer",
    zhName: "Web 前端/全栈开发者",
    angle: "browsers, frontend tooling, API clients, local servers, and design handoff",
    tagWeights: { development: 9, browser: 6, design: 3, "ai-tools": 3, utilities: 2, productivity: 2 },
    keywords: [/web|frontend|browser|javascript|typescript|node|react|vue|angular|api|http|proxy|local server|debug|responsive|figma/],
    seedNames: ["Google Chrome", "Firefox", "Microsoft Edge", "Brave Browser", "Safari", "Arc", "Visual Studio Code", "Cursor", "Postman", "Insomnia", "RapidAPI", "Proxyman", "Charles", "Figma", "Responsively", "TablePlus", "Docker Desktop", "ngrok", "Hoppscotch", "Sublime Text"],
    allowSupportTools: true,
  },
  {
    rank: 3,
    id: "data-ai-engineer",
    name: "Data / AI Engineer",
    zhName: "数据/AI 工程师",
    angle: "notebooks, model runners, database clients, data tools, and local AI utilities",
    tagWeights: { development: 8, "ai-tools": 8, utilities: 4, productivity: 2, education: 2, security: 1 },
    keywords: [/ai|llm|machine learning|model|notebook|python|data|database|sql|postgres|mongo|redis|jupyter|ollama|studio|analytics|visualization/],
    seedNames: ["JupyterLab", "Anaconda", "Miniconda", "Python", "RStudio", "TablePlus", "DBeaver", "MongoDB Compass", "RedisInsight", "LM Studio", "Ollama", "ChatGPT", "Claude", "Msty", "AnythingLLM", "Orange", "KNIME", "Visual Studio Code", "Cursor", "Docker Desktop"],
    allowSupportTools: true,
  },
  {
    rank: 4,
    id: "product-manager",
    name: "Product Manager",
    zhName: "产品经理",
    angle: "planning, docs, communication, prototyping, analytics, and collaboration",
    tagWeights: { productivity: 9, communication: 6, writing: 5, design: 4, browser: 3, "ai-tools": 3, utilities: 2 },
    keywords: [/productivity|task|todo|project|kanban|calendar|mind map|whiteboard|doc|note|figma|prototype|analytics|meeting|chat|workflow/],
    seedNames: ["Notion", "Linear", "Jira", "Confluence", "Trello", "Asana", "Slack", "Zoom", "Microsoft Teams", "Figma", "Miro", "FigJam", "Whimsical", "Xmind", "MindNode", "Obsidian", "Craft", "Google Chrome", "Raycast", "ChatGPT"],
  },
  {
    rank: 5,
    id: "ui-ux-designer",
    name: "UI / UX Designer",
    zhName: "UI/UX 设计师",
    angle: "interface design, prototyping, screenshots, handoff, and design systems",
    tagWeights: { design: 10, productivity: 4, "picture-photo": 4, browser: 3, communication: 2, "ai-tools": 2, utilities: 2 },
    keywords: [/design|prototype|wireframe|ui|ux|figma|sketch|adobe|vector|screenshot|color|icon|handoff|whiteboard|diagram/],
    seedNames: ["Figma", "Sketch", "Framer", "Principle", "Adobe XD", "Photoshop", "Illustrator", "Affinity Designer", "Pixelmator Pro", "Canva", "Miro", "FigJam", "CleanShot X", "Shottr", "Sip", "Eagle", "IconJar", "Abstract", "Zeplin", "Raycast"],
  },
  {
    rank: 6,
    id: "graphic-brand-designer",
    name: "Graphic / Brand Designer",
    zhName: "平面/品牌设计师",
    angle: "raster editing, vector design, layout, asset management, typography, and presentation",
    tagWeights: { design: 10, "picture-photo": 7, media: 3, productivity: 2, utilities: 2, "ai-tools": 2 },
    keywords: [/graphic|brand|design|vector|photo|image|illustration|layout|font|color|asset|icon|svg|png|adobe|affinity|canva|pixelmator/],
    seedNames: ["Photoshop", "Illustrator", "InDesign", "Affinity Designer", "Affinity Photo", "Affinity Publisher", "Pixelmator Pro", "Canva", "Figma", "Sketch", "Eagle", "IconJar", "FontBase", "Typeface", "RightFont", "Blender", "ImageOptim", "Acorn", "Krita", "GIMP"],
  },
  {
    rank: 7,
    id: "writer-editor",
    name: "Writer / Editor",
    zhName: "写作者/编辑",
    angle: "long-form writing, notes, Markdown, references, grammar, and focused drafting",
    tagWeights: { writing: 10, productivity: 6, education: 3, "ai-tools": 3, utilities: 2, communication: 1 },
    keywords: [/writing|writer|markdown|note|notebook|journal|document|word processor|zettelkasten|reference|grammar|dictionary|pdf|read|book|text/],
    seedNames: ["Ulysses", "Scrivener", "Obsidian", "Bear", "Craft", "Typora", "iA Writer", "Notion", "Logseq", "Joplin", "Evernote", "Zotero", "Mendeley", "Calibre", "Grammarly", "Microsoft Word", "Pages", "DEVONthink", "ChatGPT", "Claude"],
  },
  {
    rank: 8,
    id: "student-researcher",
    name: "Student / Researcher",
    zhName: "学生/研究者",
    angle: "reading, notes, references, PDF workflows, learning, and spaced repetition",
    tagWeights: { education: 9, writing: 7, productivity: 6, "ai-tools": 3, browser: 2, utilities: 2 },
    keywords: [/education|learning|study|research|paper|pdf|reference|citation|flashcard|anki|dictionary|course|note|reading|latex|bibtex|academic/],
    seedNames: ["Zotero", "Mendeley", "EndNote", "Papers", "MarginNote", "LiquidText", "Anki", "Calibre", "Kindle", "Obsidian", "Notion", "Logseq", "DEVONthink", "PDF Expert", "Skim", "Microsoft Word", "Pages", "ChatGPT", "Perplexity", "Google Chrome"],
  },
  {
    rank: 9,
    id: "photographer",
    name: "Photographer",
    zhName: "摄影师",
    angle: "RAW processing, photo management, image repair, metadata, screenshots, and cloud delivery",
    tagWeights: { "picture-photo": 10, media: 7, design: 4, transfer: 2, utilities: 2, productivity: 1 },
    keywords: [/photo|photography|raw|image|picture|camera|metadata|exif|lightroom|capture one|darktable|rawtherapee|heic|jpeg|png|gallery|asset/],
    seedNames: ["Adobe Lightroom", "Lightroom Classic", "Capture One", "Photoshop", "Pixelmator Pro", "Affinity Photo", "Darktable", "RawTherapee", "Photo Mechanic", "ImageOptim", "Eagle", "XnView MP", "ExifTool", "CleanShot X", "Shottr", "Google Drive", "Dropbox", "Transmit", "Cyberduck", "Photos"],
  },
  {
    rank: 10,
    id: "video-creator",
    name: "Video Creator",
    zhName: "视频创作者",
    angle: "editing, recording, transcoding, subtitles, playback, streaming, and media management",
    tagWeights: { video: 10, media: 8, audio: 4, "picture-photo": 3, design: 2, transfer: 2, utilities: 2 },
    keywords: [/video|movie|screen recording|recording|stream|transcode|subtitle|media player|editor|camera|motion|youtube|obs|final cut|premiere|davinci|resolve/],
    seedNames: ["Final Cut Pro", "DaVinci Resolve", "Adobe Premiere Pro", "After Effects", "OBS", "ScreenFlow", "Camtasia", "CapCut", "HandBrake", "IINA", "VLC", "mpv", "LosslessCut", "Subler", "Permute", "Compressor", "Shutter Encoder", "Plex", "YouTube Music", "CleanShot X"],
  },
  {
    rank: 11,
    id: "music-audio-producer",
    name: "Music / Audio Producer",
    zhName: "音乐/音频制作人",
    angle: "DAWs, recording, MIDI, podcasting, audio routing, music libraries, and performance",
    tagWeights: { audio: 10, media: 7, entertainment: 3, utilities: 3, video: 1 },
    keywords: [/audio|music|sound|midi|podcast|daw|recording|synth|ableton|logic|garageband|reaper|fl studio|audacity|blackhole|spotify|tidal|radio/],
    seedNames: ["Logic Pro", "GarageBand", "Ableton Live", "Reaper", "FL Studio", "Audacity", "Ardour", "djay Pro", "rekordbox", "Serato DJ Pro", "BlackHole", "Loopback", "Audio Hijack", "Spotify", "Apple Music", "Vox", "TIDAL", "Plexamp", "IINA", "VLC"],
  },
  {
    rank: 12,
    id: "marketing-growth",
    name: "Marketing / Growth",
    zhName: "市场/增长运营",
    angle: "content creation, analytics, communication, social assets, documents, and automation",
    tagWeights: { productivity: 8, communication: 6, design: 5, writing: 5, browser: 4, "ai-tools": 4, media: 2 },
    keywords: [/marketing|analytics|content|social|campaign|email|design|copy|writing|presentation|spreadsheet|meeting|automation|seo|ads|crm/],
    seedNames: ["Google Chrome", "Slack", "Zoom", "Canva", "Figma", "Notion", "ChatGPT", "Claude", "Grammarly", "Microsoft Excel", "Microsoft PowerPoint", "Keynote", "Numbers", "Miro", "Trello", "Asana", "Mailchimp", "Buffer", "Hootsuite", "Raycast"],
  },
  {
    rank: 13,
    id: "finance-accounting",
    name: "Finance / Accounting",
    zhName: "财务/会计/投资",
    angle: "spreadsheets, budgeting, accounting, trading, wallets, security, and reporting",
    tagWeights: { finance: 10, productivity: 6, security: 4, utilities: 3, writing: 2, browser: 2 },
    keywords: [/finance|money|accounting|budget|invoice|trading|stock|crypto|wallet|bank|ledger|tax|spreadsheet|excel|report|portfolio/],
    seedNames: ["Microsoft Excel", "Numbers", "LibreOffice", "TradingView", "Portfolio Performance", "MoneyMoney", "MoneyWiz", "Actual", "YNAB", "Ledger Live", "Trezor Suite", "Exodus", "Electrum", "MetaMask", "1Password", "Bitwarden", "PDF Expert", "Acrobat Reader", "Notion", "Google Chrome"],
  },
  {
    rank: 14,
    id: "project-operations-manager",
    name: "Project / Operations Manager",
    zhName: "项目/运营管理者",
    angle: "project planning, tasks, diagrams, spreadsheets, meetings, and internal docs",
    tagWeights: { productivity: 10, communication: 6, writing: 5, design: 2, browser: 2, utilities: 2 },
    keywords: [/project|task|todo|kanban|calendar|spreadsheet|diagram|whiteboard|workflow|meeting|planning|operation|doc|note|mind map/],
    seedNames: ["Notion", "Linear", "Jira", "Confluence", "Trello", "Asana", "Microsoft Teams", "Slack", "Zoom", "Miro", "Xmind", "MindNode", "Microsoft Excel", "Numbers", "Keynote", "PowerPoint", "Fantastical", "Things", "Todoist", "OmniFocus"],
  },
  {
    rank: 15,
    id: "teacher-educator",
    name: "Teacher / Educator",
    zhName: "教师/教育工作者",
    angle: "course material, screen recording, reading, notes, communication, and classroom content",
    tagWeights: { education: 9, productivity: 6, writing: 5, video: 4, communication: 4, "ai-tools": 3, media: 2 },
    keywords: [/education|teaching|course|learning|classroom|student|screen recording|presentation|note|pdf|video|quiz|flashcard|dictionary|whiteboard/],
    seedNames: ["Keynote", "PowerPoint", "Pages", "Microsoft Word", "Zoom", "Microsoft Teams", "Google Chrome", "Anki", "Notion", "Obsidian", "PDF Expert", "Skim", "ScreenFlow", "Camtasia", "OBS", "Miro", "Xmind", "ChatGPT", "Perplexity", "Calibre"],
  },
  {
    rank: 16,
    id: "consultant-freelancer",
    name: "Consultant / Freelancer",
    zhName: "顾问/自由职业者",
    angle: "client communication, proposals, documents, finance, project tracking, and secure delivery",
    tagWeights: { productivity: 8, communication: 6, writing: 5, finance: 4, browser: 3, security: 3, transfer: 2 },
    keywords: [/client|proposal|invoice|time tracking|project|task|calendar|meeting|document|pdf|finance|budget|secure|cloud|sync|presentation/],
    seedNames: ["Notion", "Slack", "Zoom", "Microsoft Teams", "Google Chrome", "1Password", "Bitwarden", "PDF Expert", "Acrobat Reader", "Microsoft Word", "Pages", "Keynote", "PowerPoint", "Microsoft Excel", "Numbers", "Dropbox", "Google Drive", "Todoist", "Things", "Fantastical"],
  },
  {
    rank: 17,
    id: "architect-3d-designer",
    name: "Architect / 3D Designer",
    zhName: "建筑/3D 设计师",
    angle: "CAD, BIM, 3D modeling, rendering, references, and large file workflows",
    tagWeights: { design: 10, "picture-photo": 4, media: 3, utilities: 3, productivity: 2, transfer: 2 },
    keywords: [/cad|bim|3d|model|render|architect|architecture|drawing|vector|mesh|blender|sketchup|autocad|freecad|openscad|fusion|rendering/],
    seedNames: ["Blender", "SketchUp", "FreeCAD", "OpenSCAD", "Fusion 360", "AutoCAD", "Rhinoceros", "Cinema 4D", "Maya", "ZBrush", "Vectorworks", "Figma", "Photoshop", "Illustrator", "Affinity Designer", "Eagle", "Dropbox", "Google Drive", "Transmit", "Cyberduck"],
  },
  {
    rank: 18,
    id: "game-developer-gamer",
    name: "Game Developer / Gamer",
    zhName: "游戏开发者/玩家",
    angle: "game engines, launchers, emulators, graphics tools, streaming, and developer utilities",
    tagWeights: { game: 10, entertainment: 8, development: 5, design: 4, media: 3, video: 2, utilities: 2 },
    keywords: [/game|gaming|engine|unity|unreal|godot|steam|emulator|controller|stream|sprite|pixel|3d|shader|graphics|itch|gog|battle/],
    seedNames: ["Steam", "Epic Games", "GOG Galaxy", "itch", "Battle.net", "Roblox", "Roblox Studio", "Minecraft", "Unity Hub", "Unreal Engine", "Godot", "Blender", "Aseprite", "Pixelmator Pro", "OBS", "Discord", "OpenEmu", "Dolphin", "Ryujinx", "Whisky"],
  },
  {
    rank: 19,
    id: "sales-customer-success",
    name: "Sales / Customer Success",
    zhName: "销售/客户成功",
    angle: "email, CRM-style workflows, calls, presentations, docs, scheduling, and secure notes",
    tagWeights: { communication: 8, productivity: 8, writing: 4, browser: 4, security: 3, "ai-tools": 3 },
    keywords: [/sales|customer|crm|email|mail|calendar|meeting|call|chat|presentation|doc|note|schedule|contact|support|ticket/],
    seedNames: ["Slack", "Zoom", "Microsoft Teams", "Outlook", "Spark", "Mimestream", "Google Chrome", "Notion", "Microsoft Word", "PowerPoint", "Keynote", "Microsoft Excel", "Calendly", "Fantastical", "1Password", "Bitwarden", "ChatGPT", "Grammarly", "Todoist", "Things"],
  },
  {
    rank: 20,
    id: "legal-admin-hr",
    name: "Legal / Admin / HR",
    zhName: "法务/行政/HR",
    angle: "documents, PDF, signing, archives, spreadsheets, communication, and secure records",
    tagWeights: { writing: 8, productivity: 7, security: 5, communication: 4, finance: 2, utilities: 2, browser: 2 },
    keywords: [/legal|admin|hr|document|pdf|signature|sign|archive|zip|spreadsheet|invoice|password|secure|mail|calendar|note|ocr|scan/],
    seedNames: ["PDF Expert", "Acrobat Reader", "Foxit PDF Editor", "Microsoft Word", "Pages", "Microsoft Excel", "Numbers", "Outlook", "Spark", "Mimestream", "Zoom", "Microsoft Teams", "1Password", "Bitwarden", "Keka", "The Unarchiver", "DEVONthink", "Notion", "Dropbox", "Google Drive"],
  },
];

function loadApps() {
  return readCSVObjects(masterPath).map((row) => {
    const tags = orderedTags(splitTags(row.defaultTagIDs));
    const artifactTypes = splitTags(row.artifactTypes);
    const normalizedName = row.normalizedName || slugify(row.name);
    const text = [
      row.name,
      normalizedName,
      row.homebrewToken,
      row.bundleIdentifier,
      row.description,
      row.defaultTagIDs,
      row.notes,
    ].join(" ").toLowerCase();

    const userFacing = artifactTypes.some((type) =>
      ["app", "suite", "pkg", "installer", "prefpane", "input_method", "screen_saver"].includes(type),
    ) || row.sourceEvidence.includes("existing_review_seed");

    return {
      ...row,
      rank: Number(row.rank || 999999),
      tags,
      normalizedName,
      text,
      artifactTypes,
      homebrew30dCount: Number(row.homebrew30dCount || 0),
      homebrew365dCount: Number(row.homebrew365dCount || 0),
      userFacing,
    };
  });
}

function reviewMap() {
  const rows = readCSVObjects(reviewPath);
  const bySlug = new Map();
  for (const row of rows) {
    bySlug.set(slugify(row.name), row.defaultTagIDs);
  }
  return bySlug;
}

function scoreAppForPersona(app, persona) {
  if (!app.name || app.tags.includes("other")) return null;
  if (/^font\b/i.test(app.name) || /(?:nerd font|typeface collection)/i.test(app.name)) return null;
  if (!app.userFacing && !persona.allowSupportTools) return null;

  const seedSlugs = new Map(persona.seedNames.map((name, index) => [slugify(name), index]));
  const seedIndex = seedSlugs.get(app.normalizedName);

  let tagScore = 0;
  const signalTags = [];
  for (const tag of app.tags) {
    const weight = persona.tagWeights[tag] ?? 0;
    if (weight > 0) {
      tagScore += weight * 120;
      signalTags.push(tag);
    }
  }

  const keywordHits = persona.keywords.filter((pattern) => pattern.test(app.text)).length;
  const keywordScore = keywordHits * 160;
  const seedScore = seedIndex === undefined ? 0 : 12000 - seedIndex * 90;
  const popularityScore =
    Math.log10(app.homebrew365dCount + 1) * 70 +
    Math.log10(app.homebrew30dCount + 1) * 90 +
    Math.max(0, 5000 - app.rank) * 0.018;
  const userFacingScore = app.userFacing ? 120 : 0;
  const narrowPenalty = tagScore === 0 && keywordHits === 0 && seedIndex === undefined ? -900 : 0;
  const score = tagScore + keywordScore + seedScore + popularityScore + userFacingScore + narrowPenalty;

  if (score <= 0) return null;

  return {
    score,
    signalTags: orderedTags(signalTags.length > 0 ? signalTags : app.tags),
    reasonParts: unique([
      seedIndex !== undefined ? "seed app for persona" : "",
      signalTags.length > 0 ? `matched tags: ${signalTags.join("|")}` : "",
      keywordHits > 0 ? `keyword hits: ${keywordHits}` : "",
      app.homebrew365dCount > 0 ? `homebrew365d=${app.homebrew365dCount}` : "",
    ]),
  };
}

function compareTags(defaultTags, reviewedTags) {
  if (!reviewedTags) return "missing_from_review_table";
  if (defaultTags === reviewedTags) return "matches_reviewed_table";
  const left = orderedTags(splitTags(defaultTags));
  const right = orderedTags(splitTags(reviewedTags));
  const leftOnly = left.filter((tag) => !right.includes(tag));
  const rightOnly = right.filter((tag) => !left.includes(tag));
  if (leftOnly.length === 0 && rightOnly.length === 0) return "matches_reviewed_table";
  return `differs: output_only=${leftOnly.join("|") || "-"} review_only=${rightOnly.join("|") || "-"}`;
}

function build() {
  fs.mkdirSync(outputDir, { recursive: true });

  const apps = loadApps();
  const reviewedTagsBySlug = reviewMap();
  const rawRows = [[
    "occupationRank",
    "occupationID",
    "occupationName",
    "occupationNameZH",
    "appRankInOccupation",
    "appName",
    "defaultTagIDs",
    "personaSignalTagIDs",
    "masterDefaultTagIDs",
    "reviewTableDefaultTagIDs",
    "tagComparison",
    "masterRank",
    "normalizedName",
    "homebrewToken",
    "bundleIdentifier",
    "selectionScore",
    "selectionReason",
    "personaAngle",
  ]];

  const rawObjects = [];

  for (const persona of personas) {
    const scored = apps
      .map((app) => {
        const scoredApp = scoreAppForPersona(app, persona);
        if (!scoredApp) return null;
        return { app, ...scoredApp };
      })
      .filter(Boolean)
      .sort((left, right) => right.score - left.score || left.app.rank - right.app.rank || left.app.name.localeCompare(right.app.name));

    const selected = scored.slice(0, 50);
    if (selected.length < 50) {
      throw new Error(`${persona.id} only selected ${selected.length} apps`);
    }

    selected.forEach((item, index) => {
      const defaultTags = item.app.tags.join("|");
      const reviewedTags = reviewedTagsBySlug.get(item.app.normalizedName) ?? "";
      const tagComparison = compareTags(defaultTags, reviewedTags);
      const rowObject = {
        occupationRank: persona.rank,
        occupationID: persona.id,
        occupationName: persona.name,
        occupationNameZH: persona.zhName,
        appRankInOccupation: index + 1,
        appName: item.app.name,
        defaultTagIDs: defaultTags,
        personaSignalTagIDs: item.signalTags.join("|"),
        masterDefaultTagIDs: defaultTags,
        reviewTableDefaultTagIDs: reviewedTags,
        tagComparison,
        masterRank: item.app.rank,
        normalizedName: item.app.normalizedName,
        homebrewToken: item.app.homebrewToken,
        bundleIdentifier: item.app.bundleIdentifier,
        selectionScore: item.score.toFixed(1),
        selectionReason: item.reasonParts.join("; "),
        personaAngle: persona.angle,
      };
      rawObjects.push(rowObject);
      rawRows.push([
        rowObject.occupationRank,
        rowObject.occupationID,
        rowObject.occupationName,
        rowObject.occupationNameZH,
        rowObject.appRankInOccupation,
        rowObject.appName,
        rowObject.defaultTagIDs,
        rowObject.personaSignalTagIDs,
        rowObject.masterDefaultTagIDs,
        rowObject.reviewTableDefaultTagIDs,
        rowObject.tagComparison,
        rowObject.masterRank,
        rowObject.normalizedName,
        rowObject.homebrewToken,
        rowObject.bundleIdentifier,
        rowObject.selectionScore,
        rowObject.selectionReason,
        rowObject.personaAngle,
      ]);
    });
  }

  const bySlug = new Map();
  for (const row of rawObjects) {
    const existing = bySlug.get(row.normalizedName);
    if (!existing) {
      bySlug.set(row.normalizedName, {
        appName: row.appName,
        normalizedName: row.normalizedName,
        defaultTagIDs: row.defaultTagIDs,
        reviewTableDefaultTagIDs: row.reviewTableDefaultTagIDs,
        tagComparison: row.tagComparison,
        masterRank: Number(row.masterRank),
        homebrewToken: row.homebrewToken,
        bundleIdentifier: row.bundleIdentifier,
        personas: [row.occupationID],
        personaNames: [row.occupationName],
        personaNamesZH: [row.occupationNameZH],
        bestPersonaRank: Number(row.appRankInOccupation),
      });
      continue;
    }
    existing.personas.push(row.occupationID);
    existing.personaNames.push(row.occupationName);
    existing.personaNamesZH.push(row.occupationNameZH);
    existing.bestPersonaRank = Math.min(existing.bestPersonaRank, Number(row.appRankInOccupation));
  }

  const uniqueObjects = [...bySlug.values()].sort((left, right) =>
    right.personas.length - left.personas.length ||
    left.masterRank - right.masterRank ||
    left.appName.localeCompare(right.appName),
  );

  const uniqueRows = [[
    "appName",
    "defaultTagIDs",
    "reviewTableDefaultTagIDs",
    "tagComparison",
    "personaCount",
    "personaIDs",
    "personaNames",
    "personaNamesZH",
    "bestPersonaRank",
    "masterRank",
    "normalizedName",
    "homebrewToken",
    "bundleIdentifier",
  ]];

  for (const row of uniqueObjects) {
    uniqueRows.push([
      row.appName,
      row.defaultTagIDs,
      row.reviewTableDefaultTagIDs,
      row.tagComparison,
      row.personas.length,
      unique(row.personas).join("|"),
      unique(row.personaNames).join("|"),
      unique(row.personaNamesZH).join("|"),
      row.bestPersonaRank,
      row.masterRank,
      row.normalizedName,
      row.homebrewToken,
      row.bundleIdentifier,
    ]);
  }

  fs.writeFileSync(rawOutputPath, `${stringifyCSV(rawRows)}\n`);
  fs.writeFileSync(uniqueOutputPath, `${stringifyCSV(uniqueRows)}\n`);

  const invalidRawRows = rawObjects.filter((row) =>
    splitTags(row.defaultTagIDs).some((tag) => !stableTags.has(tag)),
  );
  const mismatchRows = rawObjects.filter((row) => row.tagComparison !== "matches_reviewed_table");
  const tagCounts = new Map();
  for (const row of rawObjects) {
    for (const tag of splitTags(row.defaultTagIDs)) {
      tagCounts.set(tag, (tagCounts.get(tag) ?? 0) + 1);
    }
  }
  const personaLines = personas.map((persona) => `- ${persona.rank}. ${persona.zhName} / ${persona.name} (\`${persona.id}\`): ${persona.angle}`).join("\n");
  const topDuplicateLines = uniqueObjects
    .slice(0, 30)
    .map((row) => `- ${row.appName}: ${row.personas.length} personas; tags \`${row.defaultTagIDs}\``)
    .join("\n");
  const tagLines = [...tagCounts.entries()]
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .map(([tag, count]) => `- \`${tag}\`: ${count}`)
    .join("\n");
  const mismatchLines = mismatchRows.length === 0
    ? "- None"
    : mismatchRows.slice(0, 100).map((row) => `- ${row.occupationID} / ${row.appName}: ${row.tagComparison}`).join("\n");

  const report = `# Persona Top Apps Cross-check

Generated: ${new Date().toISOString()}

## Outputs

- Raw 20 x 50 table: \`Research/SmartStart/PersonaTopApps/MacPersonaTopApps_20x50.csv\`
- Unique deduped table: \`Research/SmartStart/PersonaTopApps/MacPersonaTopApps_Unique.csv\`
- Cross-check report: \`Research/SmartStart/PersonaTopApps/MacPersonaTopApps_CrossCheckReport.md\`

## Method

This is a persona-derived research pass, not a claim about exact global Mac occupation market share. The 20 occupations are common Mac-heavy professional/user personas. For each persona, the script scores the reviewed 5,000-app master library by:

- persona seed apps,
- stable tag relevance,
- keywords in app name, Homebrew token, bundle id, description, and notes,
- Homebrew cask install popularity already captured in the master table,
- user-facing app likelihood.

The exported \`defaultTagIDs\` stay product-level stable tags. \`personaSignalTagIDs\` explains why the app was selected for that occupation.

## Source Context

- Homebrew Formulae API and cask metadata/analytics are the primary machine-readable public data source: https://formulae.brew.sh/docs/api/
- Setapp's Mac Apps Report is used only as product-research context for Mac app behavior and discovery, not as a row-level source: https://setapp.com/mac-apps-report
- Stack Overflow's developer survey is used only as context for developer tooling and macOS relevance, not as a row-level source: https://survey.stackoverflow.co/

## Summary

- Persona rows: ${rawObjects.length}
- Personas: ${personas.length}
- Apps per persona: 50
- Unique apps after dedupe: ${uniqueObjects.length}
- Duplicate persona placements: ${rawObjects.length - uniqueObjects.length}
- Rows missing from reviewed table: ${mismatchRows.filter((row) => row.tagComparison === "missing_from_review_table").length}
- Tag mismatches vs reviewed table: ${mismatchRows.filter((row) => row.tagComparison !== "missing_from_review_table").length}
- Invalid tag rows: ${invalidRawRows.length}

## Personas

${personaLines}

## Tag Distribution Across 1,000 Persona Rows

${tagLines}

## Most Cross-persona Apps

${topDuplicateLines}

## Review-table Mismatches

${mismatchLines}

## Notes

- Because this pass is intentionally cross-checked against the reviewed master table, a zero-mismatch result means the persona table is consistent with the latest simplified review table.
- The raw table preserves duplicate apps across occupations. The unique table is for dedupe review and later merge planning.
- A future higher-rigor pass can add row-level web evidence URLs for the top 10-20 apps per occupation, but this pass is already useful for coverage and tag sanity checks.
`;

  fs.writeFileSync(reportOutputPath, report);

  return {
    rawRows: rawObjects.length,
    personas: personas.length,
    uniqueApps: uniqueObjects.length,
    duplicatePlacements: rawObjects.length - uniqueObjects.length,
    invalidRows: invalidRawRows.length,
    mismatches: mismatchRows.length,
    rawOutputPath,
    uniqueOutputPath,
    reportOutputPath,
  };
}

console.log(JSON.stringify(build(), null, 2));
