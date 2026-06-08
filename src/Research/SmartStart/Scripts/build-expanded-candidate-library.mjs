#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const researchDir = path.resolve(scriptDir, "..");

const existingReviewPath = path.join(researchDir, "AppDefaultTags_Review.csv");
const masterOutputPath = path.join(researchDir, "MacCommonApps_CandidateTop5000_Master.csv");
const simplifiedOutputPath = path.join(researchDir, "MacCommonApps_DefaultTags_SimplifiedReview.csv");
const notesOutputPath = path.join(researchDir, "ExpandedCandidateLibraryNotes.md");

const targetCount = 5000;

const urls = {
  casks: "https://formulae.brew.sh/api/cask.json",
  cask30d: "https://formulae.brew.sh/api/analytics/cask-install/homebrew-cask/30d.json",
  cask365d: "https://formulae.brew.sh/api/analytics/cask-install/homebrew-cask/365d.json",
};

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
  if (!fs.existsSync(filePath)) return [];
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

function addTag(tags, tag) {
  if (stableTags.has(tag) && !tags.includes(tag)) {
    tags.push(tag);
  }
}

function orderedTags(tags) {
  const cleaned = unique(tags).filter((tag) => stableTags.has(tag));
  if (cleaned.length > 1) {
    return stableTagOrder.filter((tag) => tag !== "other" && cleaned.includes(tag));
  }
  return stableTagOrder.filter((tag) => cleaned.includes(tag));
}

function artifactTypes(cask) {
  return unique((cask.artifacts ?? []).flatMap((artifact) => Object.keys(artifact)));
}

function hasArtifact(cask, type) {
  return artifactTypes(cask).includes(type);
}

function primaryName(cask) {
  if (Array.isArray(cask.name) && cask.name.length > 0) {
    return cask.name[0];
  }
  return cask.token;
}

function analyticsCount(payload, token) {
  const entries = payload?.formulae?.[token] ?? payload?.formulae?.[primaryTokenCase(token)] ?? [];
  const first = Array.isArray(entries) ? entries[0] : undefined;
  return Number(String(first?.count ?? "0").replace(/,/g, "")) || 0;
}

function primaryTokenCase(token) {
  return token
    .split("-")
    .map((part) => part ? `${part[0].toUpperCase()}${part.slice(1)}` : part)
    .join("-");
}

function matchesAny(text, patterns) {
  return patterns.some((pattern) => pattern.test(text));
}

function textFor(app) {
  return [
    app.name,
    app.normalizedName,
    app.homebrewToken,
    app.bundleIdentifier,
    app.description,
  ].join(" ").toLowerCase();
}

const tagRules = [
  ["browser", [/web browser|browser|(^|[^a-z])(chrome|chromium|firefox|safari|edge|brave|arc|vivaldi|opera|orion|duckduckgo|waterfox|librewolf|tor-browser|mullvad-browser)([^a-z]|$)/]],
  ["communication", [/chat|messag|video conferenc|meeting|mail|email|calendar|(^|[^a-z])(slack|discord|zoom|teams|telegram|signal|whatsapp|wechat|qq|skype|line|irc|matrix|mastodon|outlook|thunderbird|mimestream)([^a-z]|$)/]],
  ["ai-tools", [/artificial intelligence|large language|(^|[^a-z])(ai|llm|chatgpt|claude|gemini|perplexity|poe|copilot|ollama|lm-studio|diffusion|comfyui|stable-diffusion|midjourney|runway)([^a-z]|$)/]],
  ["development", [/developer|development|programming|coding|source code|code editor|(^|[^a-z])ide([^a-z]|$)|terminal|shell|api client|database|sql|git|diff|merge|docker|container|kubernetes|postman|insomnia|xcode|visual-studio-code|vscode|cursor|windsurf|zed|sublime|jetbrains|intellij|pycharm|webstorm|android-studio|emacs|vim|iterm|warp|ghostty|orbstack|tableplus|dbeaver|mongodb|redis/]],
  ["design", [/design|prototype|wireframe|vector|illustration|layout|figma|sketch|canva|adobe|photoshop|illustrator|indesign|affinity|pixelmator|blender|cinema|maya|freecad|openscad|draw\.?io|diagram/]],
  ["writing", [/writing|markdown|note|notebook|journal|word processor|text editor|document|zettelkasten|obsidian|notion|bear|ulysses|typora|scrivener|pages|craft|logseq|evernote|onenote|joplin|zotero|bibtex|reference manager/]],
  ["productivity", [/productivity|task|todo|project management|kanban|calendar|reminder|mind map|spreadsheet|presentation|office|workflow|automation|launcher|clipboard|raycast|alfred|things|todoist|omnifocus|fantastical|trello|asana|linear|jira|confluence|miro|xmind|mindnode|excel|powerpoint|keynote|numbers|libreoffice/]],
  ["file-management", [/file manager|file browser|finder|commander|ftp|sftp|file transfer|cloud storage|disk catalog|path-finder|forklift|transmit|cyberduck|filezilla|qspace|eagle|openmtp|mounty|cloudmounter|mountain-duck/]],
  ["transfer", [/download|upload|torrent|sync|backup|cloud storage|file transfer|ftp|sftp|bittorrent|transmission|qbittorrent|downie|jdownloader|folx|motrix|free-download-manager|localsend|syncthing|dropbox|google-drive|onedrive|baidu|aliyun/]],
  ["video", [/video|movie|media player|screen recording|screen recorder|video streaming|transcode|subtitle|(^|[^a-z])(vlc|iina|mpv|quicktime|final cut|premiere|davinci|resolve|handbrake|obs|screenflow|camtasia|capcut|plex|infuse|elmedia|movist|mkv|losslesscut)([^a-z]|$)/]],
  ["audio", [/audio|music|sound|podcast|radio|midi|daw|spotify|apple music|audacity|logic pro|garageband|ableton|reaper|fl studio|djay|rekordbox|vox|tidal|deezer|qobuz|blackhole/]],
  ["picture-photo", [/photo|picture|image|raw|screenshot|screen capture|(^|[^a-z])icon([^a-z]|$)|svg|png|jpg|jpeg|heic|preview|photos|lightroom|capture one|imageoptim|xnview|darktable|rawtherapee|shottr|cleanshot|snagit|sip/]],
  ["system-enhancement", [/window manager|menu bar|keyboard|mouse|trackpad|clipboard|display|monitor|dock|notch|touch bar|automation|hotkey|shortcut|(^|[^a-z])(bettertouchtool|karabiner|rectangle|magnet|bartender|hammerspoon|swiftbar|aerospace|alt-tab|betterdisplay|monitorcontrol|maccy|hidden-bar|dozer|ice|amphetamine|caffeine|hazel|logi-options|mos|dockdoor)([^a-z]|$)/]],
  ["security", [/password|vpn|firewall|security|encrypt|privacy|authenticator|keychain|gpg|pgp|yubico|1password|bitwarden|lastpass|dashlane|keepass|proton-vpn|nordvpn|expressvpn|mullvad|tailscale|wireguard|little-snitch|lulu|malwarebytes|authy|keybase|clash|surge/]],
  ["game", [/game|gaming|strategy game|(^|[^a-z])(minecraft|steam|epic games|gog|battle.net|roblox|itch|openemu|dolphin|ryujinx|pcsx|ppsspp|playcover|whisky|crossover|heroic|league of legends|riot)([^a-z]|$)/]],
  ["finance", [/finance|money|accounting|budget|trading|stock|crypto|wallet|bank|ledger|exodus|metamask|ynab|moneywiz|tradingview/]],
  ["education", [/education|learning|dictionary|flashcard|course|research|study|anki|duolingo|coursera|edx|kindle|calibre|marginnote|liquidtext|mendeley|endnote|papers/]],
  ["entertainment", [/entertainment|streaming|youtube|netflix|prime video|disney|hulu|bilibili|iqiyi|youku|twitch|plex|emby|jellyfin|spotify|podcast|steam|game/]],
  ["system", [/apple system seed|system settings|system preferences|activity monitor|disk utility|console|automator|time machine|keychain access|migration assistant/]],
  ["utilities", [/utility|utilities|menu bar|status bar|archive|compress|extract|zip|battery|clean|monitor|scanner|remote desktop|virtualization|virtual machine|hardware|driver|printer|firmware|unarchiver|keka|betterzip|istat|stats|cleanmymac|appcleaner|onyx|daisydisk|balenaetcher|raspberry pi imager|utm|virtualbox|parallels|vmware|rustdesk/]],
];

function inferTags(app, seed) {
  const tags = [];
  const seedTags = splitTags(seed?.defaultTagIDs).filter((tag) => tag !== "other");
  for (const tag of seedTags) addTag(tags, tag);

  const text = textFor(app);
  for (const [tag, patterns] of tagRules) {
    if (matchesAny(text, patterns)) addTag(tags, tag);
  }

  if (tags.includes("ai-tools") && !tags.includes("development") && matchesAny(text, [/coding|code|developer|terminal|llm studio|ollama|comfyui|diffusion/])) {
    addTag(tags, "development");
  }
  if (tags.includes("video") || tags.includes("audio") || tags.includes("picture-photo")) {
    addTag(tags, "media");
  }
  if (tags.includes("game")) {
    addTag(tags, "entertainment");
  }
  if (tags.includes("security") || tags.includes("system-enhancement") || tags.includes("file-management") || tags.includes("transfer")) {
    addTag(tags, "utilities");
  }
  if (tags.includes("communication") && matchesAny(text, [/meeting|conference|slack|teams|zoom|webex|lark|feishu|dingtalk/])) {
    addTag(tags, "productivity");
  }
  if (text.includes("command-line") && app.normalizedName !== "line") {
    const index = tags.indexOf("communication");
    if (index >= 0) tags.splice(index, 1);
  }

  if (tags.length === 0 && app.guiLikely) {
    addTag(tags, "utilities");
  }
  if (tags.length === 0) {
    addTag(tags, "other");
  }

  return orderedTags(tags);
}

function reviewStatus(app, tags, seed) {
  if (seed && !splitTags(seed.defaultTagIDs).includes("other")) return "seed_inherited_review";
  if (!app.guiLikely) return "non_gui_or_support_review";
  if (tags.includes("other")) return "needs_classification";
  if (app.rank <= 500) return "top500_needs_human_review";
  if (tags.length > 1) return "multi_tag_heuristic_review";
  return "single_tag_heuristic_review";
}

function confidence(app, tags, seed) {
  if (seed && !splitTags(seed.defaultTagIDs).includes("other")) return "0.78";
  if (tags.includes("other")) return "0.24";
  if (!app.guiLikely) return "0.36";
  if (app.rank <= 500 && tags.length > 1) return "0.70";
  if (app.rank <= 500) return "0.64";
  if (tags.length > 1) return "0.58";
  return "0.46";
}

function buildSeedMap() {
  const rows = readCSVObjects(existingReviewPath);
  const bySlug = new Map();
  const byBundle = new Map();
  for (const row of rows) {
    const slug = row.normalizedName || slugify(row.name);
    if (slug) bySlug.set(slug, row);
    if (row.bundleIdentifier) byBundle.set(row.bundleIdentifier, row);
  }
  return { rows, bySlug, byBundle };
}

async function fetchJSON(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`${url} failed: ${response.status}`);
  }
  return response.json();
}

async function build() {
  const [casks, cask30d, cask365d] = await Promise.all([
    fetchJSON(urls.casks),
    fetchJSON(urls.cask30d),
    fetchJSON(urls.cask365d),
  ]);
  const seed = buildSeedMap();

  const candidates = [];
  for (const cask of casks) {
    const types = artifactTypes(cask);
    if (types.includes("font")) continue;

    const name = primaryName(cask);
    const normalizedName = slugify(name);
    const seedRow = seed.bySlug.get(normalizedName);
    const count30d = analyticsCount(cask30d, cask.token);
    const count365d = analyticsCount(cask365d, cask.token);
    const guiLikely = types.some((type) => ["app", "suite", "pkg", "installer", "prefpane", "screen_saver", "input_method"].includes(type));
    const score = (count365d * 1.0) + (count30d * 12) + (seedRow ? 1_000_000 : 0) + (guiLikely ? 25_000 : 0);
    candidates.push({
      name,
      normalizedName,
      bundleIdentifier: seedRow?.bundleIdentifier ?? "",
      homebrewToken: cask.token,
      description: cask.desc ?? "",
      artifactTypes: types,
      sourceEvidence: unique([
        seedRow ? "existing_review_seed" : "",
        "homebrew_cask_api",
        count30d > 0 ? "homebrew_cask_30d" : "",
        count365d > 0 ? "homebrew_cask_365d" : "",
      ]),
      homebrew30dCount: count30d,
      homebrew365dCount: count365d,
      guiLikely,
      score,
      seedRow,
      regionHints: seedRow?.regionHints ?? "",
      notes: seedRow?.notes ?? "",
    });
  }

  for (const row of seed.rows) {
    const normalizedName = row.normalizedName || slugify(row.name);
    if (candidates.some((candidate) => candidate.normalizedName === normalizedName)) continue;
    candidates.push({
      name: row.name,
      normalizedName,
      bundleIdentifier: row.bundleIdentifier ?? "",
      homebrewToken: "",
      description: "",
      artifactTypes: [],
      sourceEvidence: ["existing_review_seed"],
      homebrew30dCount: 0,
      homebrew365dCount: 0,
      guiLikely: true,
      score: 900_000 - Number(row.rank || 9999),
      seedRow: row,
      regionHints: row.regionHints ?? "",
      notes: row.notes ?? "",
    });
  }

  const seenNormalizedNames = new Set();
  const selected = [];
  for (const candidate of candidates.sort((left, right) => right.score - left.score || left.name.localeCompare(right.name))) {
    const key = candidate.normalizedName || slugify(candidate.name);
    if (seenNormalizedNames.has(key)) continue;
    seenNormalizedNames.add(key);
    selected.push({ ...candidate, rank: selected.length + 1 });
    if (selected.length >= targetCount) break;
  }

  const masterRows = [[
    "rank",
    "name",
    "defaultTagIDs",
    "bundleIdentifier",
    "normalizedName",
    "homebrewToken",
    "description",
    "artifactTypes",
    "sourceEvidence",
    "homebrew30dCount",
    "homebrew365dCount",
    "tagConfidence",
    "reviewStatus",
    "regionHints",
    "notes",
  ]];
  const simplifiedRows = [["name", "defaultTagIDs"]];

  let otherCount = 0;
  let multiTagCount = 0;
  const tagCounts = new Map();

  for (const app of selected) {
    const tags = inferTags(app, app.seedRow);
    if (tags.includes("other")) otherCount += 1;
    if (tags.length > 1) multiTagCount += 1;
    for (const tag of tags) tagCounts.set(tag, (tagCounts.get(tag) ?? 0) + 1);

    masterRows.push([
      app.rank,
      app.name,
      tags.join("|"),
      app.bundleIdentifier,
      app.normalizedName,
      app.homebrewToken,
      app.description,
      app.artifactTypes.join("|"),
      app.sourceEvidence.join("|"),
      app.homebrew30dCount,
      app.homebrew365dCount,
      confidence(app, tags, app.seedRow),
      reviewStatus(app, tags, app.seedRow),
      app.regionHints,
      app.notes,
    ]);
    simplifiedRows.push([app.name, tags.join("|")]);
  }

  fs.writeFileSync(masterOutputPath, `${stringifyCSV(masterRows)}\n`);
  fs.writeFileSync(simplifiedOutputPath, `${stringifyCSV(simplifiedRows)}\n`);

  const topTags = [...tagCounts.entries()]
    .sort((left, right) => right[1] - left[1] || left[0].localeCompare(right[0]))
    .map(([tag, count]) => `- \`${tag}\`: ${count}`)
    .join("\n");

  const notes = `# Expanded Candidate Library Notes

Generated: ${new Date().toISOString()}

## Outputs

- Master table: \`Research/SmartStart/MacCommonApps_CandidateTop5000_Master.csv\`
- Simplified review table: \`Research/SmartStart/MacCommonApps_DefaultTags_SimplifiedReview.csv\`

## Scope

This pass expands Smart Start discovery from the old 1,000-row candidate list to a 5,000-row candidate library. It uses Homebrew's public cask API plus Homebrew 30-day and 365-day cask install analytics, then folds in the existing reviewed Apptag seed table.

The simplified review table intentionally has only:

- \`name\`
- \`defaultTagIDs\`

The master table keeps evidence, artifact type, confidence, and review status so we can audit decisions later.

## Counts

- Selected rows: ${selected.length}
- Multi-tag rows: ${multiTagCount}
- Rows still tagged \`other\`: ${otherCount}
- \`other\` rate: ${(otherCount / selected.length * 100).toFixed(1)}%

## Tag Distribution

${topTags}

## Quality Notes

- Rows marked \`seed_inherited_review\` came from the previous reviewed Apptag table where possible.
- Rows marked \`top500_needs_human_review\` should be reviewed before promotion into production Smart Start data.
- Rows marked \`non_gui_or_support_review\` are retained for discovery but should usually not ship unless verified as user-facing apps.
- The current pass intentionally reduces \`other\` by assigning broad but useful tags such as \`utilities\` when a GUI app has no stronger signal. Low-confidence rows remain visible in the master table.
`;

  fs.writeFileSync(notesOutputPath, notes);

  return {
    selectedRows: selected.length,
    multiTagRows: multiTagCount,
    otherRows: otherCount,
    otherRate: `${(otherCount / selected.length * 100).toFixed(1)}%`,
    masterOutputPath,
    simplifiedOutputPath,
  };
}

build()
  .then((summary) => console.log(JSON.stringify(summary, null, 2)))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
