#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const researchDir = path.resolve(scriptDir, "..");
const projectDir = path.resolve(researchDir, "../..");
const outputDir = path.join(researchDir, "UltimateDefaultCatalog");

const sources = {
  curatedCatalog: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.csv"),
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

const tagerToStableTags = new Map(Object.entries({
  "3d-cad": ["design"],
  "Automation": ["productivity", "system-enhancement"],
  "Font": ["design", "utilities"],
  "GTD": ["productivity"],
  "Meeting": ["communication", "productivity"],
  "Notes": ["productivity", "writing"],
  "PDF": ["writing", "utilities"],
  "ai-tools": ["ai-tools"],
  "api-tools": ["development"],
  "audio": ["media", "audio"],
  "browser": ["browser"],
  "communication": ["communication"],
  "database-tools": ["development"],
  "design": ["design"],
  "device-management": ["utilities", "system-enhancement"],
  "devops": ["development"],
  "diagramming": ["design"],
  "education": ["education"],
  "entertainment": ["entertainment"],
  "file-management": ["file-management", "utilities"],
  "finance": ["finance"],
  "game": ["entertainment", "game"],
  "ide": ["development"],
  "input-tools": ["utilities", "system-enhancement"],
  "media": ["media"],
  "network-tools": ["utilities"],
  "office": ["productivity", "writing"],
  "picture-photo": ["media", "picture-photo"],
  "runtime-sdk": ["development"],
  "security": ["security"],
  "system": ["system", "utilities"],
  "system-maintenance": ["utilities", "system-enhancement"],
  "terminal-tools": ["development"],
  "transfer": ["transfer", "utilities"],
  "ui-prototyping": ["design"],
  "utilities": ["utilities"],
  "video": ["media", "video"],
  "window-management": ["utilities", "system-enhancement"],
  "writing": ["writing"],
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

function stripTerminalPunctuation(value) {
  return String(value ?? "")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/[。．\.!！\?？;；:：,，、]+$/u, "")
    .trim();
}

function truncateNote(value) {
  const clean = stripTerminalPunctuation(value);
  if (charLength(clean) <= noteLimit) return clean;
  let sliced = Array.from(clean).slice(0, noteLimit).join("");
  return stripTerminalPunctuation(sliced);
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
  const full = `${name}${separator}${labels.join(joiner)}`;
  if (charLength(full) <= noteLimit) return full;

  const compact = `${name}${separator}${labels[0] ?? "App"}`;
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

function mapCuratedTags(value) {
  const tags = [];
  const unknownTokens = [];
  for (const token of splitTags(value)) {
    const mapped = tagerToStableTags.get(token);
    if (!mapped) {
      unknownTokens.push(token);
      continue;
    }
    tags.push(...mapped);
  }

  return {
    tags: orderedTags(tags.length > 0 ? tags : ["other"]),
    unknownTokens,
  };
}

function build() {
  fs.mkdirSync(outputDir, { recursive: true });
  const translations = loadCategoryTranslations();
  const appleNotes = parseAppleNotes();
  const previousRuntimeEntries = fs.existsSync(outputs.runtimeJSON)
    ? new Map(
        (JSON.parse(fs.readFileSync(outputs.runtimeJSON, "utf8")).entries ?? []).map((entry) => [entry.normalizedName, entry]),
      )
    : new Map();
  const curatedRows = readCSVObjects(sources.curatedCatalog);
  const unknownTagerTokens = new Set();
  const stats = {
    curatedRows: curatedRows.length,
    rowsWithSourceNotes: 0,
    appleNotesAttached: 0,
    tagChangedVsPrevious: 0,
    zhNoteChangedVsPrevious: 0,
    bundleChangedVsPrevious: 0,
    missingLocalizedNotes: 0,
  };
  const finalRows = curatedRows.map((row, index) => {
    const name = String(row.Name ?? "").trim();
    const normalizedName = String(row.normalizedName ?? "").trim() || normalizeName(name);
    const bundleIdentifier = normalizeBundle(row.bundleIdentifier);
    const legacyTags = orderedTags(splitTags(row.defaultTag));
    const mapping = mapCuratedTags(row.tager);
    for (const token of mapping.unknownTokens) unknownTagerTokens.add(token);

    let noteZH = truncateNote(row["defaultNote-ZH"]);
    let usedAppleFallback = false;
    if (!noteZH) {
      const bundleNote = bundleIdentifier ? appleNotes.byBundle.get(bundleIdentifier.toLowerCase()) : null;
      const nameNote = appleNotes.byName.get(name);
      if (bundleNote || nameNote) {
        noteZH = truncateNote(bundleNote ?? nameNote);
        usedAppleFallback = true;
        stats.appleNotesAttached += 1;
      }
    } else {
      stats.rowsWithSourceNotes += 1;
    }

    const notes = buildLocalizedNotes(name, mapping.tags, noteZH, translations);
    const previous = previousRuntimeEntries.get(normalizedName);
    if (previous) {
      if (JSON.stringify(previous.defaultTag ?? []) !== JSON.stringify(mapping.tags)) {
        stats.tagChangedVsPrevious += 1;
      }
      if (((previous.notes ?? {})["zh-Hans"] ?? "") !== (noteZH ?? "")) {
        stats.zhNoteChangedVsPrevious += 1;
      }
      if ((previous.bundleIdentifier ?? null) !== bundleIdentifier) {
        stats.bundleChangedVsPrevious += 1;
      }
    }

    return {
      rank: index + 1,
      name,
      normalizedName,
      bundleIdentifier,
      tags: mapping.tags,
      legacyTags,
      noteZH,
      notes,
      sourceEvidence: usedAppleFallback
        ? ["curated_tager_catalog", "apple_default_notes"]
        : ["curated_tager_catalog"],
    };
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
        stats.missingLocalizedNotes += 1;
      } else if (charLength(note) > noteLimit) {
        localizedNoteIssues.push({ name: row.name, code, issue: `over_limit:${charLength(note)}` });
      } else if (stripTerminalPunctuation(note) != note) {
        localizedNoteIssues.push({ name: row.name, code, issue: "trailing_punctuation" });
      }
    }
  }

  const cleanedCuratedRows = [
    ["Name", "normalizedName", "defaultTag", "tager", "bundleIdentifier", "defaultNote-ZH"],
    ...curatedRows.map((row) => [
      String(row.Name ?? "").trim(),
      String(row.normalizedName ?? "").trim() || normalizeName(row.Name ?? ""),
      String(row.defaultTag ?? "").trim(),
      String(row.tager ?? "").trim(),
      normalizeBundle(row.bundleIdentifier) ?? "null",
      truncateNote(row["defaultNote-ZH"]),
    ]),
  ];
  fs.writeFileSync(outputs.reviewCSV, `${stringifyCSV(cleanedCuratedRows)}\n`);

  const runtime = {
    version: 2,
    generatedAt: new Date().toISOString(),
    noteLimit,
    supportedLanguages: [...translations.keys()].sort(),
    entries: finalRows.map((row) => ({
      rank: row.rank,
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
    ["name", "normalizedName", "tager", "legacyDefaultTag", "runtimeDefaultTag", "bundleIdentifier", "defaultNote-ZH"],
    ...finalRows
      .filter((row) => row.legacyTags.join("|") !== row.tags.join("|"))
      .map((row) => [
        row.name,
        row.normalizedName,
        (curatedRows[row.rank - 1]?.tager ?? ""),
        row.legacyTags.join("|"),
        row.tags.join("|"),
        row.bundleIdentifier ?? "null",
        row.noteZH ?? "",
      ]),
  ];
  fs.writeFileSync(outputs.duplicateReview, `${stringifyCSV(duplicateRows)}\n`);

  const sourceLines = [
    "- curated CSV: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.csv`",
    `- curated rows: ${stats.curatedRows}`,
    `- unknown tager tokens: ${unknownTagerTokens.size}`,
  ].join("\n");
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
- Rows with source Chinese notes from curated CSV: ${stats.rowsWithSourceNotes}
- Rows with Apple note fallback attached: ${stats.appleNotesAttached}
- Invalid tag rows: ${invalidTagRows.length}
- Empty normalizedName rows: ${emptyNormalizedRows.length}
- Exact \`other\` rows: ${exactOtherRows.length}
- Mixed \`other\` rows after cleanup: ${mixedOtherRows.length}
- Tag changes vs previous runtime JSON: ${stats.tagChangedVsPrevious}
- Chinese note changes vs previous runtime JSON: ${stats.zhNoteChangedVsPrevious}
- Bundle identifier changes vs previous runtime JSON: ${stats.bundleChangedVsPrevious}
- Unknown tager tokens: ${unknownTagerTokens.size}
- Localized note issues: ${localizedNoteIssues.length}

## Tag Distribution

${topTagLines}

## Notes

- Runtime tags are generated from the curated CSV \`tager\` column, not the legacy \`defaultTag\` column.
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
    changedVsPrevious: stats.tagChangedVsPrevious,
    invalidTagRows: invalidTagRows.length,
    emptyNormalizedRows: emptyNormalizedRows.length,
    exactOtherRows: exactOtherRows.length,
    mixedOtherRows: mixedOtherRows.length,
    localizedNoteIssues: localizedNoteIssues.length,
    unknownTagerTokens: [...unknownTagerTokens].sort(),
    outputDir,
  };
}

console.log(JSON.stringify(build(), null, 2));
