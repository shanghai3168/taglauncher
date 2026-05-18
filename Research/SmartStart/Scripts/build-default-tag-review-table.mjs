#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const researchDir = path.resolve(scriptDir, "..");
const inputPath = path.join(researchDir, "MacCommonApps_CandidateTop1000.csv");
const outputPath = path.join(researchDir, "AppDefaultTags_Review.csv");
const notesPath = path.join(researchDir, "AppDefaultTags_ReviewNotes.md");

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

const tagNamesEN = {
  browser: "Browsers",
  communication: "Communication",
  productivity: "Productivity",
  "file-management": "File Management",
  transfer: "Uploads & Downloads",
  development: "Development",
  design: "Design",
  writing: "Writing",
  media: "Media",
  video: "Video",
  audio: "Audio",
  "picture-photo": "Pictures & Photos",
  utilities: "Utilities",
  system: "System Apps",
  "system-enhancement": "System Enhancements",
  entertainment: "Entertainment",
  game: "Games",
  finance: "Finance",
  education: "Education",
  "ai-tools": "AI Tools",
  security: "Security",
  other: "Other",
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

function uniqueList(values) {
  const seen = new Set();
  const output = [];
  for (const value of values) {
    const normalized = String(value ?? "").trim();
    if (!normalized || seen.has(normalized)) {
      continue;
    }
    seen.add(normalized);
    output.push(normalized);
  }
  return output;
}

function splitPipe(value) {
  return String(value ?? "")
    .split("|")
    .map((item) => item.trim())
    .filter(Boolean);
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

function includesAny(text, needles) {
  return needles.some((needle) => text.includes(needle));
}

function matchesAny(text, patterns) {
  return patterns.some((pattern) => pattern.test(text));
}

function mergeRows(rows) {
  const groups = new Map();

  for (const row of rows) {
    const normalizedName = row.normalizedName || slugify(row.name);
    const key = normalizedName || row.bundleIdentifier || row.name;
    if (!groups.has(key)) {
      groups.set(key, {
        rank: Number(row.rank) || Number.MAX_SAFE_INTEGER,
        name: row.name,
        normalizedName,
        bundleIdentifier: row.bundleIdentifier,
        oldCategories: [],
        sources: [],
        sourceRanks: [],
        regionHints: [],
        notes: [],
        confidences: [],
        sourceRows: 0,
        mergedCandidateRanks: [],
      });
    }

    const group = groups.get(key);
    const rank = Number(row.rank) || Number.MAX_SAFE_INTEGER;
    group.sourceRows += 1;
    group.mergedCandidateRanks.push(row.rank);
    group.rank = Math.min(group.rank, rank);

    if (!group.bundleIdentifier && row.bundleIdentifier) {
      group.bundleIdentifier = row.bundleIdentifier;
    }

    for (const value of splitPipe(row.categoryCandidates)) {
      group.oldCategories.push(value);
    }
    for (const value of splitPipe(row.sources)) {
      group.sources.push(value);
    }
    for (const value of splitPipe(row.sourceRanks)) {
      group.sourceRanks.push(value);
    }
    for (const value of splitPipe(row.regionHints)) {
      group.regionHints.push(value);
    }
    if (row.notes) {
      group.notes.push(row.notes);
    }
    if (row.confidence) {
      group.confidences.push(Number(row.confidence));
    }
  }

  return [...groups.values()]
    .map((group) => ({
      ...group,
      oldCategories: uniqueList(group.oldCategories),
      sources: uniqueList(group.sources),
      sourceRanks: uniqueList(group.sourceRanks),
      regionHints: uniqueList(group.regionHints),
      notes: uniqueList(group.notes),
      mergedCandidateRanks: uniqueList(group.mergedCandidateRanks),
      confidence: Math.max(0, ...group.confidences.filter(Number.isFinite)),
    }))
    .sort((left, right) => left.rank - right.rank || left.name.localeCompare(right.name));
}

function addTag(tags, tag) {
  if (!stableTags.has(tag) || tags.includes(tag)) {
    return;
  }
  tags.push(tag);
}

function removeTag(tags, tag) {
  const index = tags.indexOf(tag);
  if (index >= 0) {
    tags.splice(index, 1);
  }
}

function inferDefaultTags(app) {
  const tags = [];
  const name = app.name.toLowerCase();
  const slug = slugify(app.normalizedName || app.name);
  const bundle = String(app.bundleIdentifier ?? "").toLowerCase();
  const text = `${name} ${slug} ${bundle}`;

  const browserPatterns = [
    /(^|[^a-z])(chrome|chromium|firefox|safari|edge|brave|arc|vivaldi|opera|orion|duckduckgo|waterfox|floorp|zen|zen-browser|librewolf|tor-browser|mullvad-browser)([^a-z]|$)/,
    /browser/,
  ];
  const workCommunication = [
    "slack",
    "zoom",
    "microsoft-teams",
    "teams",
    "webex",
    "dingtalk",
    "ding-talk",
    "feishu",
    "lark",
    "tencent-meeting",
    "google-meet",
    "gotomeeting",
    "ringcentral",
    "whereby",
  ];
  const communicationPatterns = [
    /(^|[^a-z])(slack|discord|zoom|teams|webex|telegram|signal|whatsapp|wechat|weixin|qq|skype|line|messenger|facetime|messages|mail|outlook|thunderbird|spark|airmail|superhuman|mattermost|zulip|element|rocket-chat|bluebubbles|dingtalk|feishu|lark|tencent-meeting)([^a-z]|$)/,
    /(^|[^a-z])(proton-mail|fastmail|hey|mimestream)([^a-z]|$)/,
  ];
  const aiPatterns = [
    /(^|[^a-z])(chatgpt|claude|gemini|perplexity|poe|copilot|codex|cursor|windsurf|opencode|antigravity|kiro|finetune|ccswitch|cc-switch|codexbar|ollama|jan|msty|midjourney|runway|leonardo|diffusionbee|comfyui|invokeai)([^a-z]|$)/,
    /(^|[^a-z])(lm-studio|stable-diffusion|bolt-ai|raycast-ai|chatwise|open-webui)([^a-z]|$)/,
  ];
  const aiDevelopmentPatterns = [
    /(^|[^a-z])(cursor|windsurf|claude-code|codex|opencode|antigravity|kiro|ccswitch|cc-switch|codexbar|copilot|ollama|lm-studio|open-webui|comfyui|invokeai)([^a-z]|$)/,
  ];
  const developmentPatterns = [
    /(^|[^a-z])(xcode|visual-studio-code|vscode|zed|sublime-text|textmate|bbedit|nova|jetbrains|intellij|pycharm|webstorm|phpstorm|rubymine|goland|rider|clion|appcode|android-studio|eclipse|netbeans|emacs|vim|macvim|coteditor|cursor|windsurf)([^a-z]|$)/,
    /(^|[^a-z])(docker|podman|orbstack|rancher|postman|insomnia|bruno|rapidapi|proxyman|paw|gitkraken|github-desktop|sourcetree|tower|fork|sublime-merge|tableplus|sequel-ace|pgadmin4|datagrip|dbeaver|beekeeper-studio|mongodb-compass|redisinsight|kaleidoscope|beyond-compare|meld)([^a-z]|$)/,
    /(^|[^a-z])(iterm|iterm2|terminal|warp|ghostty|kitty|wezterm|alacritty|hyper|tabby|fig|homebrew|gcloud|ngrok|aws-vault|minikube|lens|kubernetes|virtualbox|vmware-fusion|parallels|utm|multipass)([^a-z]|$)/,
    /(^|[^a-z])(android-platform-tools|android-commandlinetools|git-credential-manager|microsoft-git|flutter|temurin|temurin-[0-9]+|temurin@[0-9]+|zulu|zulu@[0-9]+|corretto|corretto@[0-9]+|dotnet-sdk|dotnet-sdk@[0-9]+|session-manager-plugin|miniconda|miniforge|anaconda|tuist|vscodium|tfswitch|cmux|godot|unity|unreal)([^a-z]|$)/,
    /(^|[^a-z])(gstreamer-runtime|basictex|mactex|xquartz|hammerspoon|swiftbar|source-code-pro|fira-code)([^a-z]|$)/,
  ];
  const designPatterns = [
    /(^|[^a-z])(figma|sketch|canva|adobe-xd|xd|illustrator|indesign|affinity-designer|principle|protopie|framer|zeplin|abstract|lunacy|rive|drawio)([^a-z]|$)/,
    /(^|[^a-z])(photoshop|pixelmator|lightroom|capture-one|affinity-photo|gimp|krita|inkscape|blender|cinema-4d|c4d|maya|substance|freecad|openscad)([^a-z]|$)/,
  ];
  const writingPatterns = [
    /(^|[^a-z])(notes|notion|obsidian|bear|ulysses|typora|ia-writer|scrivener|microsoft-word|word|pages|craft|logseq|evernote|onenote|joplin|zettlr|drafts|quiver|markdown|markedit|mark-text|macdown)([^a-z]|$)/,
  ];
  const productivityPatterns = [
    /(^|[^a-z])(calendar|reminders|things|todoist|omnifocus|fantastical|microsoft-excel|excel|numbers|microsoft-powerpoint|powerpoint|keynote|wps-office|libreoffice|openoffice|dropbox|google-drive|onedrive|box|raycast|alfred|launchbar|shortcuts|microsoft-to-do|trello|asana|clickup|linear|jira|confluence|miro|xmind|mindnode)([^a-z]|$)/,
  ];
  const fileManagementPatterns = [
    /(^|[^a-z])(finder|qspace|path-finder|forklift|commander-one|mucommander|double-commander|nimble-commander|fman|transmit|openmtp|mounty|cloudmounter|eagle)([^a-z]|$)/,
  ];
  const transferPatterns = [
    /(^|[^a-z])(transmission|qbittorrent|folx|downie|jdownloader|free-download-manager|motrix|aria2|cyberduck|filezilla|transmit|forklift|localsend|syncthing|dropbox|google-drive|onedrive|box|baidu-netdisk|aliyundrive|netdisk|cloudmounter|mountain-duck|openmtp|android-file-transfer)([^a-z]|$)/,
  ];
  const videoPatterns = [
    /(^|[^a-z])(vlc|iina|mpv|quicktime|final-cut|final-cut-pro|premiere|after-effects|davinci|resolve|handbrake|obs|screenflow|camtasia|capcut|screen-studio|loom|plex|infuse|elmedia|movist|mplayer|mkvtoolnix|ffworks|losslesscut|tencent-video|iqiyi|youku|bilibili|youtube|netflix|tv)([^a-z]|$)/,
  ];
  const audioPatterns = [
    /(^|[^a-z])(spotify|music|apple-music|qqmusic|qq-music|netease-cloud-music|ximalaya|audacity|logic-pro|garageband|ableton|reaper|fl-studio|djay|rekordbox|audirvana|vox|foobar|tidal|deezer|qobuz|podcast|podcasts|overcast|downcast|blackhole|blackhole-2ch)([^a-z]|$)/,
  ];
  const picturePatterns = [
    /(^|[^a-z])(photos|preview|lightroom|capture-one|photoshop|pixelmator|affinity-photo|gimp|krita|imageoptim|xnview|eagle|sip|photo|picture|image|rawtherapee|darktable)([^a-z]|$)/,
  ];
  const entertainmentPatterns = [
    /(^|[^a-z])(netflix|youtube|prime-video|disney|hulu|bilibili|iqiyi|youku|tencent-video|tv|twitch|plex|emby|jellyfin|podcast|podcasts|ximalaya|spotify|music|tidal|deezer|steam|epic-games|gog-galaxy|battle-net|minecraft|roblox)([^a-z]|$)/,
  ];
  const gamePatterns = [
    /(^|[^a-z])(steam|epic-games|gog-galaxy|battle-net|minecraft|roblox|itch|origin|ea-app|geforce-now|playcover|whisky|cross-over|crossover|heroic-games-launcher|league-of-legends|riot-client|godot)([^a-z]|$)/,
  ];
  const financePatterns = [
    /(^|[^a-z])(tradingview|ledger-live|exodus|metamask|coinbase|binance|crypto|wallet|ynab|moneywiz|bank|finance|stocks)([^a-z]|$)/,
  ];
  const educationPatterns = [
    /(^|[^a-z])(anki|duolingo|coursera|edx|zotero|mendeley|papers|endnote|ankiapp|kindle|calibre|marginnote|liquidtext)([^a-z]|$)/,
  ];
  const securityPatterns = [
    /(^|[^a-z])(1password|bitwarden|lastpass|dashlane|keepass|keepassxc|proton-vpn|nordvpn|expressvpn|mullvad|tunnelblick|tailscale|wireguard|viscosity|little-snitch|lulu|malwarebytes|gpg|keybase|authy|yubico|clash|surge|shadowrocket|mitmproxy)([^a-z]|$)/,
  ];
  const utilityPatterns = [
    /(^|[^a-z])(cleanmymac|istat|bartender|rectangle|magnet|bettertouchtool|hazel|appcleaner|karabiner|logi-options|syncthing|the-unarchiver|keka|betterzip|unarchiver|rar|istat-menus|istatistica|stats|monitorcontrol|betterdisplay|coconutbattery|onyx|alfred|raycast|keepingyouawake|amphetamine|caffeine|dropzone|transmission|qbittorrent|cyberduck|forklift|path-finder|maccy|shottr|snagit|cleanshot|kap|keycastr|numi|hidden-bar|dozer|ice|alt-tab|aerospace|app-tamer|daisydisk|grandperspective|onyx|etrecheck)([^a-z]|$)/,
    /(^|[^a-z])(macfuse|fuse-t|blackhole|blackhole-2ch|wine|wine-stable|font|font-|nerd-font|xquartz|localsend|dockdoor|puremac|thaw|mos|balenaetcher|windows-app|rustdesk|mounty|openmtp|raspberry-pi-imager|whatcable|boring-notch)([^a-z]|$)/,
  ];
  const systemEnhancementPatterns = [
    /(^|[^a-z])(mole|alt-tab|tembo|alfred|raycast|launchbar|bettertouchtool|karabiner|rectangle|magnet|bartender|hammerspoon|swiftbar|aerospace|dockdoor|boring-notch|betterdisplay|monitorcontrol|maccy|hidden-bar|dozer|ice|app-tamer|keepingyouawake|amphetamine|caffeine|dropzone|hazel|logi-options|shortcuts)([^a-z]|$)/,
  ];
  const systemPatterns = [
    /(^|[^a-z])(finder|system-settings|system-preferences|activity-monitor|disk-utility|console|terminal|app-store|automator|preview|time-machine|migration-assistant|keychain-access)([^a-z]|$)/,
  ];

  if (matchesAny(text, browserPatterns)) addTag(tags, "browser");

  if (matchesAny(text, aiPatterns)) {
    addTag(tags, "ai-tools");
    if (matchesAny(text, aiDevelopmentPatterns)) {
      addTag(tags, "development");
    } else if (matchesAny(text, [/midjourney|runway|leonardo|diffusionbee|stable-diffusion/])) {
      addTag(tags, "design");
    } else {
      addTag(tags, "productivity");
    }
  }

  if (matchesAny(text, communicationPatterns)) {
    addTag(tags, "communication");
    if (includesAny(text, workCommunication)) {
      addTag(tags, "productivity");
    }
  }

  if (matchesAny(text, developmentPatterns)) addTag(tags, "development");

  if (matchesAny(text, designPatterns)) {
    addTag(tags, "design");
    if (matchesAny(text, [/figma|sketch|canva|framer|miro|zeplin|protopie|principle/])) {
      addTag(tags, "productivity");
    }
  }

  if (matchesAny(text, writingPatterns)) addTag(tags, "writing");
  if (matchesAny(text, [/notion|evernote|onenote|craft|logseq|joplin/])) {
    addTag(tags, "productivity");
  }
  if (matchesAny(text, productivityPatterns)) addTag(tags, "productivity");

  if (matchesAny(text, fileManagementPatterns)) addTag(tags, "file-management");

  if (matchesAny(text, transferPatterns)) addTag(tags, "transfer");

  if (matchesAny(text, videoPatterns)) {
    addTag(tags, "video");
    addTag(tags, "media");
  }

  if (matchesAny(text, audioPatterns)) {
    addTag(tags, "audio");
    if (matchesAny(text, [/spotify|music|tidal|deezer|qobuz|podcast|overcast|downcast/])) {
      addTag(tags, "entertainment");
    } else {
      addTag(tags, "media");
    }
  }

  if (matchesAny(text, picturePatterns)) {
    if (matchesAny(text, [/photoshop|pixelmator|affinity-photo|gimp|krita|lightroom|capture-one/])) {
      addTag(tags, "design");
    }
    addTag(tags, "picture-photo");
  }

  if (matchesAny(text, gamePatterns)) {
    addTag(tags, "game");
    addTag(tags, "entertainment");
  } else if (matchesAny(text, entertainmentPatterns)) {
    addTag(tags, "entertainment");
  }

  if (matchesAny(text, financePatterns)) addTag(tags, "finance");
  if (matchesAny(text, educationPatterns)) addTag(tags, "education");

  if (matchesAny(text, securityPatterns)) {
    addTag(tags, "security");
    addTag(tags, "utilities");
  }

  if (matchesAny(text, utilityPatterns)) addTag(tags, "utilities");

  if (matchesAny(text, systemEnhancementPatterns)) {
    addTag(tags, "system-enhancement");
    addTag(tags, "utilities");
  }

  if (matchesAny(text, systemPatterns)) {
    addTag(tags, "system");
    if (!matchesAny(text, [/finder|safari|mail|messages|facetime/])) {
      addTag(tags, "utilities");
    }
  }

  if (matchesAny(text, [/qq-music|qqmusic/])) {
    removeTag(tags, "communication");
  }

  if (tags.length === 0) {
    for (const oldCategory of app.oldCategories) {
      if (stableTags.has(oldCategory) && oldCategory !== "other") {
        addTag(tags, oldCategory);
      }
    }
  }

  if (tags.length === 0) {
    addTag(tags, "other");
  }

  return tags;
}

function reviewStatusFor(app, tags) {
  if (tags.includes("other")) {
    return "needs_classification";
  }
  if (app.rank <= 300) {
    return "top300_needs_human_review";
  }
  if (tags.length > 1) {
    return "multi_tag_heuristic_review";
  }
  return "single_tag_heuristic_review";
}

function tagConfidenceFor(app, tags) {
  if (tags.includes("other")) {
    return "0.30";
  }
  if (app.rank <= 100 && tags.length > 1) {
    return "0.82";
  }
  if (app.rank <= 300) {
    return "0.78";
  }
  if (tags.length > 1) {
    return "0.70";
  }
  return "0.62";
}

function readInputRows() {
  const input = fs.readFileSync(inputPath, "utf8");
  const parsedRows = parseCSV(input);
  const header = parsedRows[0];
  return parsedRows.slice(1).map((row) =>
    Object.fromEntries(header.map((column, index) => [column, row[index] ?? ""])),
  );
}

function buildReviewTable() {
  const rawRows = readInputRows();
  const mergedApps = mergeRows(rawRows);
  const outputHeader = [
    "rank",
    "name",
    "defaultTagIDs",
    "defaultTagNamesEN",
    "bundleIdentifier",
    "normalizedName",
    "oldCategoryCandidates",
    "sourceEvidence",
    "mergedCandidateRanks",
    "tagReviewStatus",
    "tagConfidence",
    "regionHints",
    "notes",
  ];
  const outputRows = [outputHeader];
  let multiTagCount = 0;
  let needsClassificationCount = 0;

  for (const app of mergedApps) {
    const tags = inferDefaultTags(app);
    if (tags.length > 1) multiTagCount += 1;
    if (tags.includes("other")) needsClassificationCount += 1;

    outputRows.push([
      app.rank,
      app.name,
      tags.join("|"),
      tags.map((tag) => tagNamesEN[tag]).join("|"),
      app.bundleIdentifier,
      app.normalizedName,
      app.oldCategories.join("|"),
      app.sources.join("|"),
      app.mergedCandidateRanks.join("|"),
      reviewStatusFor(app, tags),
      tagConfidenceFor(app, tags),
      app.regionHints.join("|"),
      app.notes.slice(0, 2).join(" / "),
    ]);
  }

  fs.writeFileSync(outputPath, `${stringifyCSV(outputRows)}\n`);

  const notes = `# App Default Tags Review Table

Generated from: \`Research/SmartStart/MacCommonApps_CandidateTop1000.csv\`

Output: \`Research/SmartStart/AppDefaultTags_Review.csv\`

## Purpose

This is the product review table for Smart Start default app tags. The original candidate CSV remains the raw source list. This review table is the place where Product, Designer, and Architect should discuss whether each app's default tags feel right.

The two most important columns are:

- \`name\`: app name shown to reviewers
- \`defaultTagIDs\`: pipe-separated stable tag IDs, allowing one app to appear in multiple default tags

## Multi-Tag Rule

\`defaultTagIDs\` is not the old one-category model. One app can and often should receive multiple tags. Examples:

- \`ChatGPT\` -> \`ai-tools|productivity\`
- \`Figma\` -> \`design|productivity\`
- \`Steam\` -> \`game|entertainment\`
- \`VLC\` -> \`video|media\`
- \`Spotify\` -> \`audio|entertainment\`
- \`Photoshop\` -> \`design|picture-photo\`
- \`Finder\` -> \`file-management|system\`
- \`QSpace\` -> \`file-management\`
- \`Transmit\` -> \`transfer|file-management\`
- \`AltTab\` -> \`system-enhancement|utilities\`
- \`Visual Studio Code\` -> \`development\`; the Chinese display name can be \`编程\`

## Localization Rule

\`defaultTagIDs\` must stay language-independent. The UI should map these IDs to localized display names for every supported language. The \`defaultTagNamesEN\` column is only an English review aid, not production identity.

## Current Counts

- Raw candidate rows: ${rawRows.length}
- Deduplicated review apps: ${mergedApps.length}
- Multi-tag apps: ${multiTagCount}
- Rows still needing classification: ${needsClassificationCount}

## Review Status

- \`top300_needs_human_review\`: high-priority app; Designer/Product should review manually
- \`multi_tag_heuristic_review\`: generated multi-tag assignment outside top 300
- \`single_tag_heuristic_review\`: generated single-tag assignment outside top 300
- \`needs_classification\`: rule set could not confidently classify the app
`;

  fs.writeFileSync(notesPath, notes);

  return {
    rawRows: rawRows.length,
    reviewApps: mergedApps.length,
    multiTagCount,
    needsClassificationCount,
  };
}

const summary = buildReviewTable();
console.log(JSON.stringify(summary, null, 2));
