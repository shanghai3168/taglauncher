#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const researchDir = path.resolve(scriptDir, "..");
const projectDir = path.resolve(researchDir, "../..");
const outputDir = path.join(researchDir, "UltimateDefaultCatalog");

const sources = {
  curatedCatalog: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.csv"),
  localizationDir: path.join(projectDir, "Apptag", "Localization"),
};

const outputs = {
  reviewCSV: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.csv"),
  runtimeJSON: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.json"),
  runtimeBaseJSON: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.base.json"),
  runtimeManifestJSON: path.join(outputDir, "SmartStart_UltimateDefaultCatalog.manifest.json"),
  report: path.join(outputDir, "SmartStart_UltimateDefaultCatalog_Report.md"),
  duplicateReview: path.join(outputDir, "SmartStart_UltimateDefaultCatalog_DuplicateReview.csv"),
  translationQA: path.join(outputDir, "SmartStart_UltimateDefaultCatalog_TranslationQA.md"),
  sourceNoteTranslationCache: path.join(outputDir, "SmartStart_UltimateDefaultCatalog_SourceNoteTranslationCache.json"),
};

const resourceFormatVersion = 1;
const catalogContentVersion = 2;
const notesVersion = 1;
const requiredFallbackLanguages = ["en", "zh-Hans", "zh-Hant"];

const stableTagOrder = [
  "browser",
  "communication",
  "GTD",
  "Notes",
  "Meeting",
  "office",
  "PDF",
  "file-management",
  "transfer",
  "ai-tools",
  "api-tools",
  "database-tools",
  "devops",
  "ide",
  "runtime-sdk",
  "terminal-tools",
  "Font",
  "ui-prototyping",
  "3d-cad",
  "diagramming",
  "writing",
  "media",
  "video",
  "audio",
  "picture-photo",
  "utilities",
  "system",
  "system-maintenance",
  "window-management",
  "device-management",
  "input-tools",
  "Automation",
  "network-tools",
  "entertainment",
  "game",
  "finance",
  "education",
  "security",
  "other",
];
const stableTags = new Set(stableTagOrder);
const noteLimit = 80;
const translationProvider = "google-translate-gtx-source-notes-20260520";
const translationBackend = process.env.SMARTSTART_TRANSLATION_BACKEND || "google-gtx";
const lingvaBaseURL = process.env.SMARTSTART_LINGVA_BASE_URL || "https://lingva.ml";
const translationBatchSize = Number(process.env.SMARTSTART_TRANSLATION_BATCH_SIZE || 50);
const translationPauseMS = Number(process.env.SMARTSTART_TRANSLATION_PAUSE_MS || 150);
const translationRetryLimit = Number(process.env.SMARTSTART_TRANSLATION_RETRY_LIMIT || 4);
const equivalentTargetLanguages = new Map(Object.entries({
  "ar-Najdi": ["ar"],
  "nn": ["nb", "no"],
  "no": ["nb", "nn"],
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
  const header = (rows[0] ?? []).map((column, index) =>
    index === 0 ? String(column ?? "").replace(/^\uFEFF/, "") : column,
  );
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
  return meaningful.length > 0 ? meaningful : cleaned;
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

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function smartStartNotesPath(languageCode) {
  return path.join(outputDir, `SmartStart_UltimateDefaultCatalog.notes.${languageCode}.json`);
}

function entryIDFor(row) {
  const baseSource = row.bundleIdentifier || row.normalizedName || row.name || "entry";
  const base = normalizeName(baseSource) || "entry";
  const identity = [
    row.bundleIdentifier ?? "",
    row.normalizedName ?? "",
    row.name ?? "",
  ].join("\u0000");
  return `${base}-${sha256(identity).slice(0, 12)}`;
}

function loadRuntimeSmartCategoryIDs() {
  const filePath = path.join(projectDir, "Apptag", "SmartCategorization", "SmartCategory.swift");
  const source = fs.readFileSync(filePath, "utf8");
  const enumBody = source.match(/enum SmartCategoryID:[\s\S]*?\n}/)?.[0] ?? "";
  const ids = new Set();
  const casePattern = /^\s*case\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*=\s*"([^"]+)")?/gm;
  let match;
  while ((match = casePattern.exec(enumBody)) !== null) {
    ids.add(match[2] ?? match[1]);
  }
  return ids;
}

function normalizedForNoteComparison(value) {
  return String(value ?? "")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9\u3400-\u9fff\u3040-\u30ff\uac00-\ud7af]+/g, "");
}

function noteRepeatsAppName(note, name) {
  const normalizedNameValue = normalizedForNoteComparison(name);
  if (normalizedNameValue.length < 3) return false;
  return normalizedForNoteComparison(note).includes(normalizedNameValue);
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

function stripLeadingPunctuation(value) {
  const clean = String(value ?? "")
    .replace(/\s+/g, " ")
    .trim();

  if (clean.startsWith(".NET")) {
    return `Microsoft .NET${clean.slice(".NET".length)}`.trim();
  }

  return clean
    .replace(/^[\p{P}\s]+/u, "")
    .trim();
}

function truncateNote(value) {
  const clean = stripTerminalPunctuation(stripLeadingPunctuation(value));
  if (charLength(clean) <= noteLimit) return clean;
  let sliced = Array.from(clean).slice(0, noteLimit).join("");
  return stripTerminalPunctuation(sliced);
}

function normalizeTranslatedNote(value) {
  return truncateNote(value);
}

function loadSupportedLanguageCodes() {
  const codes = [];
  for (const fileName of fs.readdirSync(sources.localizationDir).sort()) {
    if (!fileName.endsWith(".json")) continue;
    codes.push(fileName.replace(/\.json$/, ""));
  }
  return codes.sort();
}

function googleLanguageCode(code) {
  switch (code) {
  case "zh-Hans": return "zh-CN";
  case "zh-Hant": return "zh-TW";
  case "pt-BR": return "pt";
  case "sr-Cyrl": return "sr";
  case "ar-Najdi": return "ar";
  case "nb":
  case "nn":
  case "no":
    return "no";
  default:
    return code;
  }
}

function sourceNotesFingerprint(sourceNotes) {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify([...sourceNotes].sort()))
    .digest("hex");
}

function translationCacheKey(targetLanguage, sourceNote) {
  return ["zh-Hans", targetLanguage, sourceNote].join("\u0001");
}

function loadSourceNoteTranslationCache(sourceFingerprint) {
  if (!fs.existsSync(outputs.sourceNoteTranslationCache)) {
    return {
      version: 1,
      provider: translationProvider,
      sourceFingerprint,
      entries: {},
      ignoredExistingCache: false,
    };
  }

  const cache = JSON.parse(fs.readFileSync(outputs.sourceNoteTranslationCache, "utf8"));
  if (
    cache.provider !== translationProvider ||
    cache.sourceFingerprint !== sourceFingerprint ||
    cache.version !== 1
  ) {
    return {
      version: 1,
      provider: translationProvider,
      sourceFingerprint,
      entries: {},
      ignoredExistingCache: true,
    };
  }

  return {
    version: 1,
    provider: translationProvider,
    sourceFingerprint,
    entries: cache.entries ?? {},
    ignoredExistingCache: false,
  };
}

function saveSourceNoteTranslationCache(cache) {
  const sortedEntries = Object.fromEntries(
    Object.entries(cache.entries).sort(([left], [right]) => left.localeCompare(right)),
  );
  fs.writeFileSync(outputs.sourceNoteTranslationCache, `${JSON.stringify({
    version: 1,
    provider: translationProvider,
    sourceFingerprint: cache.sourceFingerprint,
    updatedAt: new Date().toISOString(),
    entries: sortedEntries,
  }, null, 2)}\n`);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function parseGoogleTranslation(payload) {
  return (payload?.[0] ?? [])
    .map((segment) => segment?.[0] ?? "")
    .join("");
}

async function requestGoogleTranslationPayload(params, attempt = 0) {
  const result = spawnSync("curl", [
    "-sS",
    "--fail",
    "--compressed",
    "--max-time",
    "45",
    "--retry",
    "2",
    "--retry-delay",
    "1",
    "-A",
    "TagLauncher-CatalogOps/1.0",
    "-H",
    "content-type: application/x-www-form-urlencoded;charset=UTF-8",
    "--data",
    params.toString(),
    "https://translate.googleapis.com/translate_a/single",
  ], {
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024,
  });

  if (result.status === 0) {
    try {
      return JSON.parse(result.stdout);
    } catch (error) {
      if (attempt < translationRetryLimit) {
        await sleep(2500 * (attempt + 1));
        return requestGoogleTranslationPayload(params, attempt + 1);
      }
      throw new Error(`translation response was not JSON: ${error.message}`);
    }
  }

  if (attempt < translationRetryLimit) {
    await sleep(2500 * (attempt + 1));
    return requestGoogleTranslationPayload(params, attempt + 1);
  }

  throw new Error(`translation request failed: ${result.stderr || result.stdout || result.error?.message}`);
}

async function requestLingvaTranslationBatch(notes, targetLanguage, attempt = 0) {
  const targetCode = googleLanguageCode(targetLanguage);
  const query = encodeURIComponent(notes.map((note) => note.replace(/\//g, "／")).join("\n"));
  const result = spawnSync("curl", [
    "-sS",
    "--fail",
    "--compressed",
    "--max-time",
    "60",
    "--retry",
    "4",
    "--retry-all-errors",
    "--retry-connrefused",
    "--retry-delay",
    "2",
    "-A",
    "TagLauncher-CatalogOps/1.0",
    `${lingvaBaseURL.replace(/\/+$/, "")}/api/v1/zh/${targetCode}/${query}`,
  ], {
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024,
  });

  if (result.status === 0) {
    try {
      const payload = JSON.parse(result.stdout);
      if (payload.error) throw new Error(payload.error);
      const translated = String(payload.translation ?? "")
        .replace(/\r\n/g, "\n")
        .replace(/\r/g, "\n");
      const parts = translated.split("\n").map(normalizeTranslatedNote);
      if (parts.length !== notes.length || parts.some((part) => !part)) {
        throw new Error(`translation batch line mismatch: expected ${notes.length}, got ${parts.length}`);
      }
      return parts;
    } catch (error) {
      if (attempt < translationRetryLimit && isRemoteThrottleError(error)) {
        await sleep(2500 * (attempt + 1));
        return requestLingvaTranslationBatch(notes, targetLanguage, attempt + 1);
      }
      throw error;
    }
  }

  if (attempt < translationRetryLimit) {
    await sleep(2500 * (attempt + 1));
    return requestLingvaTranslationBatch(notes, targetLanguage, attempt + 1);
  }

  throw new Error(`lingva translation request failed: ${result.stderr || result.stdout || result.error?.message}`);
}

async function requestOnlineTranslationBatch(notes, targetLanguage) {
  if (translationBackend === "lingva") {
    return requestLingvaTranslationBatch(notes, targetLanguage);
  }

  const params = new URLSearchParams({
    client: "gtx",
    sl: googleLanguageCode("zh-Hans"),
    tl: googleLanguageCode(targetLanguage),
    dt: "t",
    q: notes.join("\n"),
  });
  const translated = parseGoogleTranslation(await requestGoogleTranslationPayload(params))
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n");
  const parts = translated.split("\n").map(normalizeTranslatedNote);
  if (parts.length !== notes.length || parts.some((part) => !part)) {
    throw new Error(`translation batch line mismatch: expected ${notes.length}, got ${parts.length}`);
  }
  return parts;
}

function isRemoteThrottleError(error) {
  const message = String(error?.message ?? "");
  return message.includes("not JSON") || message.includes("translation request failed");
}

async function translateNotesWithSplit(notes, targetLanguage) {
  try {
    return await requestOnlineTranslationBatch(notes, targetLanguage);
  } catch (error) {
    if (isRemoteThrottleError(error) || notes.length <= 1) {
      throw error;
    }
    const middle = Math.ceil(notes.length / 2);
    const left = await translateNotesWithSplit(notes.slice(0, middle), targetLanguage);
    const right = await translateNotesWithSplit(notes.slice(middle), targetLanguage);
    return [...left, ...right];
  }
}

function reusableTranslation(cache, targetLanguage, sourceNote) {
  const directKey = translationCacheKey(targetLanguage, sourceNote);
  if (cache.entries[directKey]) return cache.entries[directKey];

  for (const equivalentLanguage of equivalentTargetLanguages.get(targetLanguage) ?? []) {
    const equivalentKey = translationCacheKey(equivalentLanguage, sourceNote);
    if (cache.entries[equivalentKey]) return cache.entries[equivalentKey];
  }
  return null;
}

async function translateMissingNotes(uniqueSourceNotes, supportedLanguages, cache) {
  let translatedCount = 0;
  let failedCount = 0;
  let reusedEquivalentCount = 0;
  let cacheHits = 0;

  for (const sourceNote of uniqueSourceNotes) {
    cache.entries[translationCacheKey("zh-Hans", sourceNote)] = normalizeTranslatedNote(sourceNote);
  }

  for (const targetLanguage of supportedLanguages) {
    if (targetLanguage === "zh-Hans" || targetLanguage === "zh-Hant") continue;

    const missing = [];
    for (const sourceNote of uniqueSourceNotes) {
      const key = translationCacheKey(targetLanguage, sourceNote);
      if (cache.entries[key]) {
        cacheHits += 1;
        continue;
      }
      const reusable = reusableTranslation(cache, targetLanguage, sourceNote);
      if (reusable) {
        cache.entries[key] = reusable;
        reusedEquivalentCount += 1;
        continue;
      }
      missing.push({ sourceNote, key });
    }

    if (missing.length > 0) {
      console.warn(`Translating ${missing.length} source notes to ${targetLanguage}...`);
    }

    for (let index = 0; index < missing.length; index += translationBatchSize) {
      const batch = missing.slice(index, index + translationBatchSize);
      try {
        const translations = await translateNotesWithSplit(
          batch.map((item) => item.sourceNote),
          targetLanguage,
        );
        translations.forEach((translation, translationIndex) => {
          cache.entries[batch[translationIndex].key] = translation;
          translatedCount += 1;
        });
      } catch (error) {
        failedCount += batch.length;
        saveSourceNoteTranslationCache(cache);
        throw new Error(`Batch failed for ${targetLanguage}; cached progress saved.\n${error.message}`);
      }
      saveSourceNoteTranslationCache(cache);
      await sleep(translationPauseMS);
    }
  }

  saveSourceNoteTranslationCache(cache);
  return { translatedCount, failedCount, reusedEquivalentCount, cacheHits };
}

function convertSimplifiedNotesToTraditional(sourceNotes) {
  const notes = sourceNotes.map(normalizeTranslatedNote).filter(Boolean);
  if (notes.length === 0) return new Map();

  const swiftCode = `
import Foundation

let inputData = FileHandle.standardInput.readDataToEndOfFile()
let notes = try JSONDecoder().decode([String].self, from: inputData)
let converted = notes.map { note -> String in
    let mutable = NSMutableString(string: note)
    CFStringTransform(mutable, nil, "Simplified-Traditional" as CFString, false)
    return mutable as String
}
let outputData = try JSONEncoder().encode(converted)
FileHandle.standardOutput.write(outputData)
`;
  const result = spawnSync("/usr/bin/swift", ["-e", swiftCode], {
    input: JSON.stringify(notes),
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
  });

  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) {
    throw new Error(`zh-Hant conversion failed:\n${result.stderr}`);
  }

  const converted = JSON.parse(result.stdout);
  if (!Array.isArray(converted) || converted.length !== notes.length) {
    throw new Error("zh-Hant conversion returned an unexpected result shape");
  }

  return new Map(notes.map((note, index) => [note, normalizeTranslatedNote(converted[index])]));
}

function buildLocalizedNotes(sourceNote, supportedLanguages, cache, traditionalNote) {
  const cleanSourceNote = normalizeTranslatedNote(sourceNote);
  if (!cleanSourceNote) return {};

  const notes = {};
  for (const languageCode of supportedLanguages) {
    if (languageCode === "zh-Hans") {
      notes[languageCode] = cleanSourceNote;
      continue;
    }
    if (languageCode === "zh-Hant") {
      const cleanTraditionalNote = normalizeTranslatedNote(traditionalNote);
      if (cleanTraditionalNote) notes[languageCode] = cleanTraditionalNote;
      continue;
    }
    const translatedNote = normalizeTranslatedNote(cache.entries[translationCacheKey(languageCode, cleanSourceNote)]);
    if (translatedNote) notes[languageCode] = translatedNote;
  }
  return Object.fromEntries(
    Object.entries(notes).sort(([left], [right]) => left.localeCompare(right)),
  );
}

function writeJSON(filePath, value) {
  const text = `${JSON.stringify(value, null, 2)}\n`;
  fs.writeFileSync(filePath, text);
  return {
    file: path.basename(filePath),
    sha256: sha256(text),
    bytes: Buffer.byteLength(text),
  };
}

function buildSplitResources({ finalRows, supportedLanguages, generatedAt, noteLimit }) {
  const baseResource = {
    resourceFormatVersion,
    catalogContentVersion,
    generatedAt,
    noteLimit,
    supportedLanguages,
    fallbackLanguages: requiredFallbackLanguages,
    entries: finalRows.map((row) => ({
      entryID: row.entryID,
      rank: row.rank,
      name: row.name,
      normalizedName: row.normalizedName,
      bundleIdentifier: row.bundleIdentifier,
      defaultTag: row.tags,
      sourceEvidence: row.sourceEvidence,
    })),
  };
  const baseInfo = writeJSON(outputs.runtimeBaseJSON, baseResource);

  const notesResources = {};
  for (const languageCode of supportedLanguages) {
    const notesResource = {
      resourceFormatVersion,
      catalogContentVersion,
      notesVersion,
      generatedAt,
      language: languageCode,
      entries: finalRows
        .map((row) => ({
          entryID: row.entryID,
          note: row.notes[languageCode],
        }))
        .filter((entry) => entry.note),
    };
    const notesPath = smartStartNotesPath(languageCode);
    notesResources[languageCode] = {
      ...writeJSON(notesPath, notesResource),
      count: notesResource.entries.length,
    };
  }

  const manifest = {
    resourceFormatVersion,
    catalogContentVersion,
    notesVersion,
    generatedAt,
    noteLimit,
    supportedLanguages,
    fallbackLanguages: requiredFallbackLanguages,
    baseResource: {
      ...baseInfo,
      count: baseResource.entries.length,
    },
    notesResources,
  };
  const manifestInfo = writeJSON(outputs.runtimeManifestJSON, manifest);

  return {
    baseInfo,
    manifestInfo,
    notesResources,
  };
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
    if (!stableTags.has(token)) {
      unknownTokens.push(token);
      continue;
    }
    tags.push(token);
  }

  return {
    tags: orderedTags(tags),
    unknownTokens,
  };
}

const duplicateAliasSuffixes = ["-app", "-desktop", "-mac", "-macos"];

function duplicateAliasBase(normalizedName) {
  const clean = String(normalizedName ?? "").trim();
  for (const suffix of duplicateAliasSuffixes) {
    if (clean.endsWith(suffix)) {
      return clean.slice(0, -suffix.length);
    }
  }
  return clean;
}

function duplicateComparable(row) {
  return JSON.stringify({
    defaultTag: String(row.defaultTag ?? "").trim(),
    tager: String(row.tager ?? "").trim(),
    bundleIdentifier: normalizeBundle(row.bundleIdentifier),
    noteZH: truncateNote(row["defaultNote-ZH"]),
  });
}

function dedupeCuratedRows(rows, stats) {
  const byNormalized = new Map();
  for (const row of rows) {
    const normalizedName = String(row.normalizedName ?? "").trim() || normalizeName(row.Name ?? "");
    if (normalizedName && !byNormalized.has(normalizedName)) {
      byNormalized.set(normalizedName, row);
    }
  }

  const filtered = [];
  for (const row of rows) {
    const normalizedName = String(row.normalizedName ?? "").trim() || normalizeName(row.Name ?? "");
    const aliasBase = duplicateAliasBase(normalizedName);
    const baseRow = aliasBase === normalizedName ? null : byNormalized.get(aliasBase);
    if (baseRow && duplicateComparable(row) === duplicateComparable(baseRow)) {
      stats.aliasDuplicatesRemoved += 1;
      continue;
    }
    filtered.push(row);
  }
  return filtered;
}

async function build() {
  fs.mkdirSync(outputDir, { recursive: true });
  const supportedLanguages = loadSupportedLanguageCodes();
  const runtimeSmartCategoryIDs = loadRuntimeSmartCategoryIDs();
  const missingRuntimeCategories = stableTagOrder.filter((tag) => !runtimeSmartCategoryIDs.has(tag));
  if (missingRuntimeCategories.length > 0) {
    throw new Error(
      `SmartCategoryID is missing generated catalog tags: ${missingRuntimeCategories.join(", ")}`,
    );
  }
  for (const language of requiredFallbackLanguages) {
    if (!supportedLanguages.includes(language)) {
      throw new Error(`required fallback language is missing from Localization: ${language}`);
    }
  }
  const previousRuntimeEntries = fs.existsSync(outputs.runtimeJSON)
    ? new Map(
        (JSON.parse(fs.readFileSync(outputs.runtimeJSON, "utf8")).entries ?? []).map((entry) => [entry.normalizedName, entry]),
      )
    : new Map();
  const rawCuratedRows = readCSVObjects(sources.curatedCatalog);
  const appleRows = rawCuratedRows.filter((row) => {
    const bundleIdentifier = normalizeBundle(row.bundleIdentifier);
    return bundleIdentifier?.toLowerCase().startsWith("com.apple.");
  });
  if (appleRows.length > 0) {
    throw new Error(
      `SmartStart curated catalog contains ${appleRows.length} Apple rows. ` +
      "Move Apple default apps to Research/AppleDefaultApps before rebuilding.",
    );
  }
  const unknownTagerTokens = new Set();
  const stats = {
    curatedRows: rawCuratedRows.length,
    aliasDuplicatesRemoved: 0,
    rowsWithSourceNotes: 0,
    tagChangedVsPrevious: 0,
    zhNoteChangedVsPrevious: 0,
    bundleChangedVsPrevious: 0,
    missingLocalizedNotes: 0,
  };
  const curatedRows = rawCuratedRows;
  const preparedRows = curatedRows.map((row, index) => {
    const name = String(row.Name ?? "").trim();
    const normalizedName = String(row.normalizedName ?? "").trim() || normalizeName(name);
    const bundleIdentifier = normalizeBundle(row.bundleIdentifier);
    const mapping = mapCuratedTags(row.tager);
    for (const token of mapping.unknownTokens) unknownTagerTokens.add(token);

    let noteZH = truncateNote(row["defaultNote-ZH"]);
    if (noteZH) {
      stats.rowsWithSourceNotes += 1;
    }

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
      noteZH,
      sourceEvidence: ["curated_tager_catalog"],
    };
  });

  const uniqueSourceNotes = [
    ...new Set(preparedRows.map((row) => normalizeTranslatedNote(row.noteZH)).filter(Boolean)),
  ].sort((left, right) => left.localeCompare(right));
  const sourceFingerprint = sourceNotesFingerprint(uniqueSourceNotes);
  const translationCache = loadSourceNoteTranslationCache(sourceFingerprint);
  const traditionalNotesBySource = convertSimplifiedNotesToTraditional(uniqueSourceNotes);
  for (const [sourceNote, traditionalNote] of traditionalNotesBySource.entries()) {
    translationCache.entries[translationCacheKey("zh-Hant", sourceNote)] = traditionalNote;
  }
  const translationStats = await translateMissingNotes(uniqueSourceNotes, supportedLanguages, translationCache);
  if (translationStats.failedCount > 0) {
    throw new Error(`translation failed for ${translationStats.failedCount} source-note/language pairs; JSON generation blocked`);
  }

  const finalRows = preparedRows.map((row) => ({
    ...row,
    entryID: entryIDFor(row),
    notes: buildLocalizedNotes(
      row.noteZH,
      supportedLanguages,
      translationCache,
      traditionalNotesBySource.get(normalizeTranslatedNote(row.noteZH)),
    ),
  }));

  const invalidTagRows = finalRows.filter((row) => row.tags.some((tag) => !stableTags.has(tag)));
  const runtimeInvalidTagRows = finalRows.filter((row) => row.tags.some((tag) => !runtimeSmartCategoryIDs.has(tag)));
  const entryIDCounts = new Map();
  for (const row of finalRows) {
    entryIDCounts.set(row.entryID, (entryIDCounts.get(row.entryID) ?? 0) + 1);
  }
  const duplicateEntryIDs = [...entryIDCounts.entries()].filter(([, count]) => count > 1);
  const emptyNormalizedRows = finalRows.filter((row) => !row.normalizedName);
  const exactOtherRows = finalRows.filter((row) => row.tags.length === 1 && row.tags[0] === "other");
  const mixedOtherRows = finalRows.filter((row) => row.tags.length > 1 && row.tags.includes("other"));
  const noteRows = finalRows.filter((row) => row.noteZH);
  const actualLocalizedNoteCount = noteRows.reduce(
    (total, row) => total + Object.keys(row.notes).filter((code) => supportedLanguages.includes(code)).length,
    0,
  );
  const missingLocalizedNotes = noteRows.length * supportedLanguages.length - actualLocalizedNoteCount;
  const missingLocalizedNoteRows = noteRows.filter(
    (row) => supportedLanguages.some((code) => !row.notes[code]),
  );
  if (runtimeInvalidTagRows.length > 0) {
    throw new Error(
      `runtime SmartCategoryID cannot decode ${runtimeInvalidTagRows.length} catalog rows`,
    );
  }
  if (duplicateEntryIDs.length > 0) {
    throw new Error(
      `duplicate Smart Start entryID values: ${duplicateEntryIDs.map(([id]) => id).slice(0, 10).join(", ")}`,
    );
  }
  const noteQualityIssues = [];
  for (const row of noteRows) {
    for (const code of supportedLanguages) {
      if (!row.notes[code]) {
        noteQualityIssues.push({ name: row.name || row.normalizedName, code, issue: "missing_translation" });
      }
    }
    for (const [code, note] of Object.entries(row.notes)) {
      if (charLength(note) > noteLimit) {
        noteQualityIssues.push({ name: row.name || row.normalizedName, code, issue: `over_limit:${charLength(note)}` });
      } else if (stripTerminalPunctuation(note) != note) {
        noteQualityIssues.push({ name: row.name || row.normalizedName, code, issue: "trailing_punctuation" });
      } else if (stripLeadingPunctuation(note) != note) {
        noteQualityIssues.push({ name: row.name || row.normalizedName, code, issue: "leading_punctuation" });
      } else if (noteRepeatsAppName(note, row.name)) {
        noteQualityIssues.push({ name: row.name || row.normalizedName, code, issue: "repeats_app_name" });
      }
    }
  }

  const runtime = {
    version: 2,
    generatedAt: new Date().toISOString(),
    noteLimit,
    supportedLanguages,
    entries: finalRows.map((row) => ({
      entryID: row.entryID,
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
  const splitResources = buildSplitResources({
    finalRows,
    supportedLanguages,
    generatedAt: runtime.generatedAt,
    noteLimit,
  });

  const duplicateRows = [
    ["name", "normalizedName", "previousRuntimeDefaultTag", "runtimeDefaultTag", "bundleIdentifier", "defaultNote-ZH"],
    ...finalRows
      .filter((row) => {
        const previous = previousRuntimeEntries.get(row.normalizedName);
        return previous && JSON.stringify(previous.defaultTag ?? []) !== JSON.stringify(row.tags);
      })
      .map((row) => [
        row.name,
        row.normalizedName,
        (previousRuntimeEntries.get(row.normalizedName)?.defaultTag ?? []).join("|"),
        row.tags.join("|"),
        row.bundleIdentifier ?? "null",
        row.noteZH ?? "",
      ]),
  ];
  fs.writeFileSync(outputs.duplicateReview, `${stringifyCSV(duplicateRows)}\n`);

  const sourceLines = [
    "- curated CSV: `Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog.csv`",
    `- curated rows: ${stats.curatedRows}`,
    `- curated rows used for JSON: ${curatedRows.length}`,
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
- Split base JSON: \`Research/SmartStart/UltimateDefaultCatalog/${splitResources.baseInfo.file}\`
- Split manifest JSON: \`Research/SmartStart/UltimateDefaultCatalog/${splitResources.manifestInfo.file}\`
- Split notes JSON files: ${Object.keys(splitResources.notesResources).length}
- Duplicate review: \`Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog_DuplicateReview.csv\`
- Translation QA: \`Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog_TranslationQA.md\`
- Source-note translation cache: \`Research/SmartStart/UltimateDefaultCatalog/SmartStart_UltimateDefaultCatalog_SourceNoteTranslationCache.json\`

## Summary

- Final rows: ${finalRows.length}
- Rows with Chinese default notes: ${noteRows.length}
- Rows with source Chinese notes from curated CSV: ${stats.rowsWithSourceNotes}
- Supported languages: ${supportedLanguages.length}
- Unique source notes: ${uniqueSourceNotes.length}
- Expected localized notes: ${noteRows.length * supportedLanguages.length}
- Actual localized notes: ${actualLocalizedNoteCount}
- Missing localized notes: ${missingLocalizedNotes}
- Rows missing at least one localized note: ${missingLocalizedNoteRows.length}
- Source note fingerprint: ${sourceFingerprint}
- Existing source-note cache ignored: ${translationCache.ignoredExistingCache ? "yes" : "no"}
- Translation provider: ${translationProvider}
- Translation backend: ${translationBackend}
- Translation cache hits before run: ${translationStats.cacheHits}
- Equivalent-language cache reuses: ${translationStats.reusedEquivalentCount}
- New non-Chinese translations generated: ${translationStats.translatedCount}
- Translation failures: ${translationStats.failedCount}
- zh-Hant generation: macOS CFStringTransform Simplified-Traditional from zh-Hans source notes
- Invalid tag rows: ${invalidTagRows.length}
- Runtime-invalid tag rows: ${runtimeInvalidTagRows.length}
- Duplicate entryID values: ${duplicateEntryIDs.length}
- Empty normalizedName rows: ${emptyNormalizedRows.length}
- Exact \`other\` rows: ${exactOtherRows.length}
- Mixed \`other\` rows after cleanup: ${mixedOtherRows.length}
- Tag changes vs previous runtime JSON: ${stats.tagChangedVsPrevious}
- Chinese note changes vs previous runtime JSON: ${stats.zhNoteChangedVsPrevious}
- Bundle identifier changes vs previous runtime JSON: ${stats.bundleChangedVsPrevious}
- Unknown tager tokens: ${unknownTagerTokens.size}
- Note quality issues: ${noteQualityIssues.length}

## Tag Distribution

${topTagLines}

## Notes

- Runtime JSON is generated strictly from the curated CSV. The generator does not rewrite the source CSV.
- Runtime tags are copied directly from the curated CSV \`tager\` column.
- Runtime notes are generated only from curated CSV \`defaultNote-ZH\`: \`zh-Hans\` is the source note, \`zh-Hant\` is converted from it, and all other supported languages are translated from the same source note.
- The source-note translation cache is only a fingerprint-validated acceleration artifact. Localized tag-summary notes are not valid sources for runtime notes.
`;
  fs.writeFileSync(outputs.report, report);

  const translationReport = `# Smart Start Ultimate Default Catalog Translation QA

Generated: ${runtime.generatedAt}

## Summary

- Supported languages: ${runtime.supportedLanguages.length}
- Rows with source Chinese notes: ${noteRows.length}
- Source notes: ${noteRows.length}
- Required zh-Hant conversions: ${noteRows.length}
- Required non-Chinese machine/reviewed translations: ${noteRows.length * (runtime.supportedLanguages.length - 2)}
- Unique source notes: ${uniqueSourceNotes.length}
- Expected localized notes including source language: ${noteRows.length * runtime.supportedLanguages.length}
- Actual localized notes: ${actualLocalizedNoteCount}
- Missing localized notes: ${missingLocalizedNotes}
- Rows missing at least one localized note: ${missingLocalizedNoteRows.length}
- Source note fingerprint: ${sourceFingerprint}
- Existing source-note cache ignored: ${translationCache.ignoredExistingCache ? "yes" : "no"}
- Translation provider: ${translationProvider}
- Translation backend: ${translationBackend}
- Translation cache hits before run: ${translationStats.cacheHits}
- Equivalent-language cache reuses: ${translationStats.reusedEquivalentCount}
- New non-Chinese translations generated: ${translationStats.translatedCount}
- Translation failures: ${translationStats.failedCount}
- zh-Hant generation: macOS CFStringTransform Simplified-Traditional from zh-Hans source notes
- Generated placeholder translations: 0
- Note quality issues: ${noteQualityIssues.length}
- Note limit: ${noteLimit}

## Issue Sample

${noteQualityIssues.slice(0, 50).map((issue) => `- ${issue.name} / ${issue.code}: ${issue.issue}`).join("\n") || "- None"}
`;
  fs.writeFileSync(outputs.translationQA, translationReport);

  return {
    finalRows: finalRows.length,
    noteRows: noteRows.length,
    splitBaseBytes: splitResources.baseInfo.bytes,
    splitNotesFiles: Object.keys(splitResources.notesResources).length,
    changedVsPrevious: stats.tagChangedVsPrevious,
    invalidTagRows: invalidTagRows.length,
    runtimeInvalidTagRows: runtimeInvalidTagRows.length,
    duplicateEntryIDs: duplicateEntryIDs.length,
    emptyNormalizedRows: emptyNormalizedRows.length,
    exactOtherRows: exactOtherRows.length,
    mixedOtherRows: mixedOtherRows.length,
    supportedLanguages: supportedLanguages.length,
    uniqueSourceNotes: uniqueSourceNotes.length,
    expectedLocalizedNotes: noteRows.length * supportedLanguages.length,
    actualLocalizedNotes: actualLocalizedNoteCount,
    missingLocalizedNotes,
    sourceFingerprint,
    sourceNoteCacheIgnoredExisting: translationCache.ignoredExistingCache,
    translationCacheHitsBeforeRun: translationStats.cacheHits,
    equivalentLanguageCacheReuses: translationStats.reusedEquivalentCount,
    newNonChineseTranslationsGenerated: translationStats.translatedCount,
    translationFailures: translationStats.failedCount,
    noteQualityIssues: noteQualityIssues.length,
    unknownTagerTokens: [...unknownTagerTokens].sort(),
    outputDir,
  };
}

console.log(JSON.stringify(await build(), null, 2));
