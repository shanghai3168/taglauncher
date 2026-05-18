#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const researchDir = path.resolve(scriptDir, "..");
const projectDir = path.resolve(researchDir, "../..");
const outputDir = path.join(researchDir, "UltimateDefaultCatalog");

const sources = {
  master5000: path.join(researchDir, "MacCommonApps_CandidateTop5000_Master.csv"),
  persona: path.join(researchDir, "PersonaTopApps", "MacPersonaTopApps_Unique.csv"),
  game: path.join(researchDir, "game.csv"),
  top1000: path.join(researchDir, "AppDefaultTags_Review.csv"),
  appleNotes: path.join(projectDir, "Apptag", "AppleDefaultAppNotes.swift"),
  localizationDir: path.join(projectDir, "Apptag", "Localization"),
};

const outputs = {
  reviewCSV: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.csv"),
  runtimeJSON: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.json"),
  report: path.join(outputDir, "SmartStart_UltimateDefaultCatalog_Report.md"),
  duplicateReview: path.join(outputDir, "SmartStart_UltimateDefaultCatalog_DuplicateReview.csv"),
  translationQA: path.join(outputDir, "SmartStart_UltimateDefaultCatalog_TranslationQA.md"),
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
const noteLimit = 80;

const sourcePriority = {
  apple: 100,
  persona: 90,
  top1000: 80,
  game: 70,
  master5000: 60,
};

const tagOverridesByNormalizedName = new Map(Object.entries({
  "android-ndk": ["development", "utilities"],
  "codeql": ["development", "security"],
  "prince": ["writing", "development", "utilities"],
  "qlstephen": ["utilities", "system-enhancement"],
  "kotlin-lsp": ["development"],
  "ghdl": ["development"],
  "android-sdk-platform-tools": ["development", "utilities"],
  "android-sdk-command-line-tools": ["development", "utilities"],
}));

const appleCatalogMetadata = new Map(Object.entries({
  "com.apple.activitymonitor": { name: "Activity Monitor", tags: ["system", "utilities", "system-enhancement"] },
  "com.apple.airport.airportutility": { name: "AirPort Utility", tags: ["system", "utilities"] },
  "com.apple.appstore": { name: "App Store", tags: ["system", "utilities"] },
  "com.apple.apps.launcher": { name: "Apps", tags: ["system", "utilities"] },
  "com.apple.audio.audiomidisetup": { name: "Audio MIDI Setup", tags: ["audio", "system", "utilities"] },
  "com.apple.automator": { name: "Automator", tags: ["system-enhancement", "utilities"] },
  "com.apple.bluetoothfileexchange": { name: "Bluetooth File Exchange", tags: ["transfer", "system", "utilities"] },
  "com.apple.ibooksx": { name: "Books", tags: ["writing", "education", "entertainment"] },
  "com.apple.bootcampassistant": { name: "Boot Camp Assistant", tags: ["system", "utilities"] },
  "com.apple.calculator": { name: "Calculator", tags: ["utilities"] },
  "com.apple.ical": { name: "Calendar", tags: ["productivity"] },
  "com.apple.chess": { name: "Chess", tags: ["game", "entertainment"] },
  "com.apple.clock": { name: "Clock", tags: ["productivity", "utilities"] },
  "com.apple.colorsyncutility": { name: "ColorSync Utility", tags: ["design", "picture-photo", "system", "utilities"] },
  "com.apple.console": { name: "Console", tags: ["system", "utilities"] },
  "com.apple.addressbook": { name: "Contacts", tags: ["communication", "productivity"] },
  "com.apple.dictionary": { name: "Dictionary", tags: ["writing", "education", "utilities"] },
  "com.apple.digitalcolormeter": { name: "Digital Color Meter", tags: ["design", "picture-photo", "utilities"] },
  "com.apple.diskutility": { name: "Disk Utility", tags: ["system", "utilities"] },
  "com.apple.facetime": { name: "FaceTime", tags: ["communication", "video"] },
  "com.apple.findmy": { name: "Find My", tags: ["system", "utilities"] },
  "com.apple.fontbook": { name: "Font Book", tags: ["design", "utilities"] },
  "com.apple.freeform": { name: "Freeform", tags: ["productivity", "design"] },
  "com.apple.games": { name: "Games", tags: ["game", "entertainment"] },
  "com.apple.grapher": { name: "Grapher", tags: ["education", "utilities"] },
  "com.apple.home": { name: "Home", tags: ["system", "utilities"] },
  "com.apple.image_capture": { name: "Image Capture", tags: ["picture-photo", "transfer", "utilities"] },
  "com.apple.generativeplaygroundapp": { name: "Image Playground", tags: ["ai-tools", "picture-photo", "design"] },
  "com.apple.imovieapp": { name: "iMovie", tags: ["video", "media"] },
  "com.apple.screencontinuity": { name: "iPhone Mirroring", tags: ["system-enhancement", "utilities"] },
  "com.apple.journal": { name: "Journal", tags: ["writing", "productivity"] },
  "com.apple.iwork.keynote": { name: "Keynote", tags: ["productivity", "writing"] },
  "com.apple.magnifier": { name: "Magnifier", tags: ["system", "utilities"] },
  "com.apple.mail": { name: "Mail", tags: ["communication"] },
  "com.apple.maps": { name: "Maps", tags: ["productivity", "utilities"] },
  "com.apple.mobilesms": { name: "Messages", tags: ["communication"] },
  "com.apple.migrateassistant": { name: "Migration Assistant", tags: ["transfer", "system", "utilities"] },
  "com.apple.exposelauncher": { name: "Mission Control", tags: ["system", "system-enhancement"] },
  "com.apple.music": { name: "Music", tags: ["audio", "media", "entertainment"] },
  "com.apple.news": { name: "News", tags: ["media", "writing"] },
  "com.apple.notes": { name: "Notes", tags: ["writing", "productivity"] },
  "com.apple.iwork.numbers": { name: "Numbers", tags: ["productivity"] },
  "com.apple.iwork.pages": { name: "Pages", tags: ["writing"] },
  "com.apple.passwords": { name: "Passwords", tags: ["security", "utilities"] },
  "com.apple.mobilephone": { name: "Phone", tags: ["communication"] },
  "com.apple.photobooth": { name: "Photo Booth", tags: ["picture-photo", "media", "entertainment"] },
  "com.apple.photos": { name: "Photos", tags: ["picture-photo", "media"] },
  "com.apple.podcasts": { name: "Podcasts", tags: ["audio", "media", "entertainment"] },
  "com.apple.preview": { name: "Preview", tags: ["picture-photo", "writing", "utilities"] },
  "com.apple.printcenter": { name: "Print Center", tags: ["system", "utilities"] },
  "com.apple.quicktimeplayerx": { name: "QuickTime Player", tags: ["video", "audio", "media"] },
  "com.apple.reminders": { name: "Reminders", tags: ["productivity"] },
  "com.apple.safari": { name: "Safari", tags: ["browser"] },
  "com.apple.screensharing": { name: "Screen Sharing", tags: ["system", "communication", "utilities"] },
  "com.apple.screenshot.launcher": { name: "Screenshot", tags: ["picture-photo", "video", "utilities"] },
  "com.apple.scripteditor2": { name: "Script Editor", tags: ["development", "system-enhancement", "utilities"] },
  "com.apple.sfsymbols": { name: "SF Symbols", tags: ["design", "development"] },
  "com.apple.shortcuts": { name: "Shortcuts", tags: ["system-enhancement", "productivity", "utilities"] },
  "com.apple.siri.launcher": { name: "Siri", tags: ["system", "utilities"] },
  "com.apple.stickies": { name: "Stickies", tags: ["writing", "productivity"] },
  "com.apple.stocks": { name: "Stocks", tags: ["finance"] },
  "com.apple.systemprofiler": { name: "System Information", tags: ["system", "utilities"] },
  "com.apple.systempreferences": { name: "System Settings", tags: ["system", "utilities"] },
  "com.apple.terminal": { name: "Terminal", tags: ["development", "system", "utilities"] },
  "com.apple.textedit": { name: "TextEdit", tags: ["writing"] },
  "com.apple.backup.launcher": { name: "Time Machine", tags: ["system", "utilities"] },
  "com.apple.helpviewer": { name: "Tips", tags: ["education", "utilities"] },
  "com.apple.tv": { name: "TV", tags: ["video", "media", "entertainment"] },
  "com.apple.voicememos": { name: "Voice Memos", tags: ["audio", "media"] },
  "com.apple.voiceoverutility": { name: "VoiceOver Utility", tags: ["system", "utilities"] },
  "com.apple.weather": { name: "Weather", tags: ["utilities"] },
  "com.apple.dt.xcode": { name: "Xcode", tags: ["development"] },
}));

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

function splitTags(value) {
  return String(value ?? "")
    .split(/[|;,]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function orderedTags(tags) {
  const cleaned = [];
  const seen = new Set();
  for (const tag of tags) {
    if (!stableTags.has(tag) || seen.has(tag)) continue;
    seen.add(tag);
    cleaned.push(tag);
  }
  const meaningful = cleaned.filter((tag) => tag !== "other");
  const finalTags = meaningful.length > 0 ? meaningful : cleaned;
  return stableTagOrder.filter((tag) => finalTags.includes(tag));
}

function normalizeName(value) {
  return String(value ?? "")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "") || String(value ?? "").trim().toLowerCase();
}

function normalizeBundle(value) {
  const trimmed = String(value ?? "").trim();
  if (!trimmed || ["null", "nil", "undefined", "n/a", "-"].includes(trimmed.toLowerCase())) {
    return null;
  }
  return trimmed;
}

function charLength(value) {
  return Array.from(String(value ?? "")).length;
}

function truncateNote(value) {
  const clean = String(value ?? "").replace(/\s+/g, " ").trim();
  if (charLength(clean) <= noteLimit) return clean;
  let sliced = Array.from(clean).slice(0, noteLimit).join("");
  sliced = sliced.replace(/[，、；：,.!！?？]$/, "");
  if (!/[。.!！?？]$/.test(sliced)) {
    sliced = `${Array.from(sliced).slice(0, noteLimit - 1).join("")}。`;
  }
  return sliced;
}

function loadCategoryTranslations() {
  const translations = new Map();
  for (const fileName of fs.readdirSync(sources.localizationDir).sort()) {
    if (!fileName.endsWith(".json")) continue;
    const code = fileName.replace(/\.json$/, "");
    const raw = JSON.parse(fs.readFileSync(path.join(sources.localizationDir, fileName), "utf8"));
    const categories = {};
    for (const tag of stableTagOrder) {
      categories[tag] = raw[`smart.category.${tag}`] ?? tag;
    }
    translations.set(code, categories);
  }
  return translations;
}

function localizedGeneratedNote(name, tags, code, translations) {
  const categoryMap = translations.get(code) ?? translations.get("en") ?? {};
  const meaningfulTags = tags.filter((tag) => tag !== "other").slice(0, 2);
  const shownTags = meaningfulTags.length > 0 ? meaningfulTags : tags.slice(0, 1);
  const labels = shownTags.map((tag) => categoryMap[tag] ?? tag);
  const joiner = ["ar", "ar-Najdi"].includes(code) ? "، " : ["zh-Hans", "zh-Hant", "ja"].includes(code) ? "、" : ", ";
  const separator = ["zh-Hans", "zh-Hant", "ja"].includes(code) ? "：" : ": ";
  const end = ["zh-Hans", "zh-Hant", "ja"].includes(code) ? "。" : ".";
  const full = `${name}${separator}${labels.join(joiner)}${end}`;
  if (charLength(full) <= noteLimit) return full;

  const compact = `${name}${separator}${labels[0] ?? "App"}${end}`;
  if (charLength(compact) <= noteLimit) return compact;

  return truncateNote(compact);
}

function buildLocalizedNotes(name, tags, noteZH, translations) {
  if (!noteZH) return {};
  const notes = {};
  for (const code of translations.keys()) {
    if (code === "zh-Hans") {
      notes[code] = truncateNote(noteZH);
    } else {
      notes[code] = localizedGeneratedNote(name, tags, code, translations);
    }
  }
  return notes;
}

function parseAppleNotes() {
  if (!fs.existsSync(sources.appleNotes)) {
    return { byBundle: new Map(), byName: new Map() };
  }

  const swift = fs.readFileSync(sources.appleNotes, "utf8");
  const byBundle = new Map();
  const byName = new Map();
  const entryPattern = /"([^"]+)"\s*:\s*"([^"]+)"/g;
  let currentSection = null;

  for (const line of swift.split("\n")) {
    if (line.includes("private static let byBundleID")) currentSection = "bundle";
    if (line.includes("private static let byName")) currentSection = "name";
    if (line.includes("static func note")) currentSection = null;

    let match;
    while ((match = entryPattern.exec(line)) !== null) {
      if (currentSection === "bundle") {
        byBundle.set(match[1].toLowerCase(), match[2]);
      } else if (currentSection === "name") {
        byName.set(match[1], match[2]);
      }
    }
  }

  return { byBundle, byName };
}

function rawEntry({
  source,
  name,
  normalizedName,
  bundleIdentifier,
  tags,
  noteZH = "",
  rank = Number.MAX_SAFE_INTEGER,
  evidence = [],
}) {
  const cleanName = String(name ?? "").trim();
  const cleanNormalized = String(normalizedName ?? "").trim() || normalizeName(cleanName);
  const cleanBundle = normalizeBundle(bundleIdentifier);
  const cleanTags = orderedTags(tags);
  return {
    source,
    name: cleanName,
    normalizedName: cleanNormalized,
    bundleIdentifier: cleanBundle,
    tags: cleanTags,
    noteZH: truncateNote(noteZH),
    rank: Number.isFinite(Number(rank)) ? Number(rank) : Number.MAX_SAFE_INTEGER,
    evidence: evidence.filter(Boolean),
    priority: sourcePriority[source] ?? 0,
  };
}

function mergeInto(target, incoming, stats) {
  target.sources.add(incoming.source);
  for (const evidence of incoming.evidence) target.sourceEvidence.add(evidence);
  target.sourceEvidence.add(incoming.source);
  target.tags = orderedTags([...target.tags, ...incoming.tags]);
  target.rank = Math.min(target.rank, incoming.rank);

  if (incoming.bundleIdentifier && !target.bundleIdentifier) {
    target.bundleIdentifier = incoming.bundleIdentifier;
  }
  if (incoming.priority > target.namePriority && incoming.name) {
    target.name = incoming.name;
    target.namePriority = incoming.priority;
  }
  if (incoming.noteZH && (!target.noteZH || incoming.priority >= target.notePriority)) {
    target.noteZH = incoming.noteZH;
    target.notePriority = incoming.priority;
  }
  stats.mergedRows += 1;
}

function build() {
  fs.mkdirSync(outputDir, { recursive: true });
  const translations = loadCategoryTranslations();
  const appleNotes = parseAppleNotes();
  const entries = [];
  const byBundle = new Map();
  const byName = new Map();
  const ambiguous = [];
  const mergedGroups = [];
  const stats = {
    sourceRows: {},
    mergedRows: 0,
    appleNotesAttached: 0,
    appleNotesSwiftOnly: 0,
  };

  function addEntry(incoming) {
    if (!incoming.name || incoming.tags.length === 0) return;

    const bundleKey = incoming.bundleIdentifier?.toLowerCase() ?? null;
    let existing = bundleKey ? byBundle.get(bundleKey) : null;

    if (!existing) {
      const normalizedExisting = byName.get(incoming.normalizedName);
      if (normalizedExisting) {
        const existingBundle = normalizedExisting.bundleIdentifier?.toLowerCase() ?? null;
        if (bundleKey && existingBundle && bundleKey !== existingBundle) {
          ambiguous.push({
            kind: "same_normalized_different_bundle",
            identity: incoming.normalizedName,
            names: [normalizedExisting.name, incoming.name].join(" | "),
            bundles: [normalizedExisting.bundleIdentifier, incoming.bundleIdentifier].join(" | "),
            sources: [[...normalizedExisting.sources].join("|"), incoming.source].join(" | "),
            decision: "kept_separate_for_review",
          });
        } else {
          existing = normalizedExisting;
        }
      }
    }

    if (!existing) {
      const entry = {
        name: incoming.name,
        normalizedName: incoming.normalizedName,
        bundleIdentifier: incoming.bundleIdentifier,
        tags: incoming.tags,
        noteZH: incoming.noteZH,
        rank: incoming.rank,
        sourceEvidence: new Set([...incoming.evidence, incoming.source].filter(Boolean)),
        sources: new Set([incoming.source]),
        namePriority: incoming.priority,
        notePriority: incoming.noteZH ? incoming.priority : -1,
      };
      entries.push(entry);
      byName.set(entry.normalizedName, entry);
      if (bundleKey) byBundle.set(bundleKey, entry);
      return;
    }

    const beforeSources = new Set(existing.sources);
    mergeInto(existing, incoming, stats);
    if (incoming.bundleIdentifier) byBundle.set(incoming.bundleIdentifier.toLowerCase(), existing);
    byName.set(existing.normalizedName, existing);
    mergedGroups.push({
      identity: bundleKey ? `bundle:${bundleKey}` : `name:${incoming.normalizedName}`,
      sourcesBefore: [...beforeSources].join("|"),
      mergedSource: incoming.source,
      finalName: existing.name,
    });
  }

  const masterRows = readCSVObjects(sources.master5000);
  stats.sourceRows.master5000 = masterRows.length;
  for (const row of masterRows) {
    addEntry(rawEntry({
      source: "master5000",
      name: row.name,
      normalizedName: row.normalizedName,
      bundleIdentifier: row.bundleIdentifier,
      tags: splitTags(row.defaultTagIDs),
      rank: row.rank,
      evidence: splitTags(row.sourceEvidence),
    }));
  }

  const topRows = readCSVObjects(sources.top1000);
  stats.sourceRows.top1000 = topRows.length;
  for (const row of topRows) {
    addEntry(rawEntry({
      source: "top1000",
      name: row.name,
      normalizedName: row.normalizedName,
      bundleIdentifier: row.bundleIdentifier,
      tags: splitTags(row.defaultTagIDs),
      rank: row.rank,
      evidence: splitTags(row.sourceEvidence),
    }));
  }

  const gameRows = readCSVObjects(sources.game);
  stats.sourceRows.game = gameRows.length;
  for (const row of gameRows) {
    addEntry(rawEntry({
      source: "game",
      name: row.name,
      normalizedName: normalizeName(row.name),
      bundleIdentifier: row.bundleIdentifier,
      tags: orderedTags([...splitTags(row.defaultTagIDs), "entertainment"]),
      rank: row.rank,
      evidence: ["game_seed"],
    }));
  }

  const personaRows = readCSVObjects(sources.persona);
  stats.sourceRows.persona = personaRows.length;
  for (const row of personaRows) {
    addEntry(rawEntry({
      source: "persona",
      name: row.appName,
      normalizedName: row.normalizedName,
      bundleIdentifier: row.bundleIdentifier,
      tags: splitTags(row.defaultTagIDs),
      noteZH: row.defaultNoteZH,
      rank: row.masterRank || row.bestPersonaRank,
      evidence: ["persona_top_apps", ...(row.personaIDs ? [`personas:${row.personaIDs}`] : [])],
    }));
  }

  stats.sourceRows.apple = appleNotes.byBundle.size;
  for (const [bundleIdentifier, note] of appleNotes.byBundle.entries()) {
    const metadata = appleCatalogMetadata.get(bundleIdentifier);
    if (!metadata) continue;
    addEntry(rawEntry({
      source: "apple",
      name: metadata.name,
      normalizedName: normalizeName(metadata.name),
      bundleIdentifier,
      tags: metadata.tags,
      noteZH: note,
      rank: 50,
      evidence: ["apple_default_notes"],
    }));
  }

  for (const entry of entries) {
    const bundleNote = entry.bundleIdentifier
      ? appleNotes.byBundle.get(entry.bundleIdentifier.toLowerCase())
      : null;
    const nameNote = appleNotes.byName.get(entry.name);
    const note = bundleNote ?? nameNote;
    if (note) {
      entry.noteZH = truncateNote(note);
      entry.notePriority = sourcePriority.apple;
      entry.sources.add("apple");
      entry.sourceEvidence.add("apple_default_notes");
      stats.appleNotesAttached += 1;
    }
  }

  for (const bundle of appleNotes.byBundle.keys()) {
    if (!byBundle.has(bundle)) stats.appleNotesSwiftOnly += 1;
  }

  const finalRows = entries
    .map((entry) => {
      entry.tags = orderedTags(entry.tags);
      if (entry.tags.length === 1 && entry.tags[0] === "other") {
        const overrideTags = tagOverridesByNormalizedName.get(entry.normalizedName);
        if (overrideTags) {
          entry.tags = orderedTags(overrideTags);
          entry.sourceEvidence.add("manual_other_reduction");
        }
      }
      const notes = buildLocalizedNotes(entry.name, entry.tags, entry.noteZH, translations);
      return {
        name: entry.name,
        normalizedName: entry.normalizedName || normalizeName(entry.name),
        bundleIdentifier: entry.bundleIdentifier,
        tags: entry.tags,
        noteZH: entry.noteZH,
        notes,
        rank: entry.rank,
        sourceEvidence: [...entry.sourceEvidence].sort(),
        sources: [...entry.sources].sort(),
      };
    })
    .sort((left, right) => {
      const rankDiff = left.rank - right.rank;
      if (rankDiff !== 0) return rankDiff;
      return left.name.localeCompare(right.name);
    });

  const invalidTagRows = finalRows.filter((row) => row.tags.some((tag) => !stableTags.has(tag)));
  const emptyNormalizedRows = finalRows.filter((row) => !row.normalizedName);
  const exactOtherRows = finalRows.filter((row) => row.tags.length === 1 && row.tags[0] === "other");
  const mixedOtherRows = finalRows.filter((row) => row.tags.length > 1 && row.tags.includes("other"));
  const noteRows = finalRows.filter((row) => row.noteZH);
  const localizedNoteIssues = [];
  for (const row of noteRows) {
    for (const code of translations.keys()) {
      const note = row.notes[code];
      if (!note) {
        localizedNoteIssues.push({ name: row.name, code, issue: "missing" });
      } else if (charLength(note) > noteLimit) {
        localizedNoteIssues.push({ name: row.name, code, issue: `over_limit:${charLength(note)}` });
      }
    }
  }

  const reviewHeader = ["Name", "normalizedName", "defaultTag", "bundleIdentifier", "defaultNote-ZH"];
  const reviewRows = [
    reviewHeader,
    ...finalRows.map((row) => [
      row.name,
      row.normalizedName,
      row.tags.join("|"),
      row.bundleIdentifier ?? "null",
      row.noteZH ?? "",
    ]),
  ];
  fs.writeFileSync(outputs.reviewCSV, `${stringifyCSV(reviewRows)}\n`);

  const runtime = {
    version: 2,
    generatedAt: new Date().toISOString(),
    noteLimit,
    supportedLanguages: [...translations.keys()].sort(),
    entries: finalRows.map((row, index) => ({
      rank: index + 1,
      name: row.name,
      normalizedName: row.normalizedName,
      bundleIdentifier: row.bundleIdentifier,
      defaultTag: row.tags,
      notes: row.notes,
      sourceEvidence: row.sourceEvidence,
    })),
  };
  fs.writeFileSync(outputs.runtimeJSON, `${JSON.stringify(runtime, null, 2)}\n`);

  const duplicateRows = [
    ["kind", "identity", "names", "bundles", "sources", "decision"],
    ...ambiguous.map((row) => [row.kind, row.identity, row.names, row.bundles, row.sources, row.decision]),
  ];
  fs.writeFileSync(outputs.duplicateReview, `${stringifyCSV(duplicateRows)}\n`);

  const sourceLines = Object.entries(stats.sourceRows)
    .map(([source, count]) => `- ${source}: ${count}`)
    .join("\n");
  const topTagLines = stableTagOrder
    .map((tag) => [tag, finalRows.filter((row) => row.tags.includes(tag)).length])
    .filter(([, count]) => count > 0)
    .map(([tag, count]) => `- ${tag}: ${count}`)
    .join("\n");
  const report = `# Smart Start Ultimate Default Catalog Report

Generated: ${runtime.generatedAt}

## Inputs

${sourceLines}

## Outputs

- Review CSV: \`Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.csv\`
- Runtime JSON: \`Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.json\`
- Duplicate review: \`Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog_DuplicateReview.csv\`
- Translation QA: \`Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog_TranslationQA.md\`

## Summary

- Final rows: ${finalRows.length}
- Rows with Chinese default notes: ${noteRows.length}
- Merged source rows: ${stats.mergedRows}
- Ambiguous duplicate candidates: ${ambiguous.length}
- Invalid tag rows: ${invalidTagRows.length}
- Empty normalizedName rows: ${emptyNormalizedRows.length}
- Exact \`other\` rows: ${exactOtherRows.length}
- Mixed \`other\` rows after cleanup: ${mixedOtherRows.length}
- Apple notes attached to catalog rows: ${stats.appleNotesAttached}
- Apple notes still handled by Swift-only fallback: ${stats.appleNotesSwiftOnly}
- Localized note issues: ${localizedNoteIssues.length}

## Tag Distribution

${topTagLines}

## Notes

- \`other\` is removed whenever a row has at least one meaningful tag.
- Runtime notes are generated for all supported localization files when a Chinese source note exists.
- Non-Chinese localized notes currently use localized tag-summary copy generated from existing category translations; high-traffic languages can be manually polished later.
`;
  fs.writeFileSync(outputs.report, report);

  const translationReport = `# Smart Start Ultimate Default Catalog Translation QA

Generated: ${runtime.generatedAt}

## Summary

- Supported languages: ${runtime.supportedLanguages.length}
- Rows with source Chinese notes: ${noteRows.length}
- Required localized notes: ${noteRows.length * runtime.supportedLanguages.length}
- Issues: ${localizedNoteIssues.length}
- Note limit: ${noteLimit}

## Issue Sample

${localizedNoteIssues.slice(0, 50).map((issue) => `- ${issue.name} / ${issue.code}: ${issue.issue}`).join("\n") || "- None"}
`;
  fs.writeFileSync(outputs.translationQA, translationReport);

  return {
    finalRows: finalRows.length,
    noteRows: noteRows.length,
    ambiguousDuplicates: ambiguous.length,
    invalidTagRows: invalidTagRows.length,
    emptyNormalizedRows: emptyNormalizedRows.length,
    exactOtherRows: exactOtherRows.length,
    mixedOtherRows: mixedOtherRows.length,
    localizedNoteIssues: localizedNoteIssues.length,
    outputDir,
  };
}

console.log(JSON.stringify(build(), null, 2));
