import fsSync from "node:fs";
import fs from "node:fs/promises";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import {
  LOCALES,
  getCopy,
  loadAppStrings,
  modeLabels
} from "../../../docs/scripts/localized-content.mjs";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(SCRIPT_DIR, "../../..");
const ASSETS = path.join(ROOT, "docs/assets");
const OUT_ROOT = path.join(ROOT, "Docs/X-Op资料/Screenshots/AppStore-Marketing");
const W = 2880;
const H = 1800;

function esc(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

const DATA_URL_CACHE = new Map();

function dataUrl(file) {
  const absolute = path.isAbsolute(file) ? file : path.join(ASSETS, file);
  if (DATA_URL_CACHE.has(absolute)) return DATA_URL_CACHE.get(absolute);
  const ext = path.extname(absolute).toLowerCase();
  const mime = ext === ".jpg" || ext === ".jpeg" ? "image/jpeg" : "image/png";
  const value = `data:${mime};base64,${fsSync.readFileSync(absolute).toString("base64")}`;
  DATA_URL_CACHE.set(absolute, value);
  return value;
}

function keycaps(keys) {
  return `<span class="key-row">${keys.map((key) => `<span class="key">${esc(key)}</span>`).join("<span class=\"plus\">+</span>")}</span>`;
}

function baseHtml(locale, body) {
  const copy = getCopy(locale.code);
  return `<!doctype html>
<html lang="${esc(locale.htmlLang)}" dir="${esc(locale.dir)}">
<head>
  <meta charset="utf-8">
  <style>
    * { box-sizing: border-box; }
    html, body { width: ${W}px; height: ${H}px; margin: 0; overflow: hidden; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", Arial, "PingFang SC", "Hiragino Sans", "Noto Sans", sans-serif;
      color: #111318;
      background: #f7f9ff;
      -webkit-font-smoothing: antialiased;
    }
    .slide {
      width: ${W}px;
      height: ${H}px;
      position: relative;
      overflow: hidden;
      padding: 132px;
      background:
        radial-gradient(circle at 16% 10%, rgba(108, 160, 255, 0.20), transparent 28%),
        radial-gradient(circle at 82% 20%, rgba(255, 128, 168, 0.16), transparent 30%),
        radial-gradient(circle at 52% 92%, rgba(90, 215, 152, 0.14), transparent 28%),
        linear-gradient(180deg, #fbfcff 0%, #f7faff 48%, #f8fbf8 100%);
    }
    .hero-slide {
      background: #ffffff;
    }
    .hero-slide .floating-visual img {
      filter: none;
    }
    .brand {
      position: absolute;
      left: 132px;
      top: 112px;
      display: inline-flex;
      align-items: center;
      gap: 18px;
      min-width: 310px;
      height: 82px;
      padding: 12px 24px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.76);
      border: 1px solid rgba(255, 255, 255, 0.8);
      box-shadow: 0 20px 50px rgba(30, 45, 90, 0.10);
      font-size: 28px;
      font-weight: 800;
    }
    .brand img { width: 52px; height: 52px; border-radius: 12px; }
    .grid2 {
      position: absolute;
      inset: 260px 132px 132px;
      display: grid;
      grid-template-columns: 0.95fr 1.05fr;
      align-items: center;
      gap: 92px;
    }
    .grid2.reverse { grid-template-columns: 1.08fr 0.92fr; }
    .rtl .grid2 { direction: rtl; }
    .copy { max-width: 1050px; }
    .eyebrow {
      display: inline-block;
      margin-bottom: 34px;
      font-size: 34px;
      color: #6c7382;
      font-weight: 750;
    }
    h1 {
      margin: 0;
      font-size: 112px;
      line-height: 1.06;
      letter-spacing: 0;
      font-weight: 900;
      text-wrap: balance;
      overflow-wrap: anywhere;
    }
    .hero-title { font-size: 124px; }
    p {
      margin: 44px 0 0;
      font-size: 47px;
      line-height: 1.38;
      color: #454b58;
      overflow-wrap: anywhere;
    }
    .visual img, .card img { display: block; width: 100%; height: 100%; object-fit: contain; }
    .floating-visual {
      width: 100%;
      height: 1220px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .floating-visual img { max-width: 100%; max-height: 100%; object-fit: contain; filter: drop-shadow(0 44px 68px rgba(22, 34, 60, 0.12)); }
    .shot-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 36px;
    }
    .shot-card, .glass-card {
      border-radius: 42px;
      overflow: hidden;
      background: rgba(255, 255, 255, 0.76);
      border: 1px solid rgba(255, 255, 255, 0.84);
      box-shadow: 0 32px 74px rgba(30, 45, 90, 0.14);
    }
    .shot-card { height: 390px; }
    .shot-card img { width: 100%; height: 100%; object-fit: cover; object-position: center bottom; }
    .mode-list {
      display: grid;
      gap: 34px;
      margin-top: 56px;
      padding: 0;
      list-style: none;
      font-size: 44px;
      font-weight: 850;
    }
    .mode-list li { display: flex; align-items: center; gap: 24px; }
    .mode-list li::before {
      content: "";
      width: 24px;
      height: 24px;
      border-radius: 999px;
      background: #0071e3;
      flex: 0 0 auto;
    }
    .shortcut {
      display: inline-flex;
      flex-direction: column;
      gap: 26px;
      margin-top: 58px;
      padding: 34px 46px;
      border-radius: 34px;
      background: rgba(255, 255, 255, 0.68);
      border: 1px solid rgba(215, 220, 232, 0.84);
    }
    .shortcut-label { color: #8a909d; font-size: 32px; font-weight: 800; }
    .key-row { display: inline-flex; align-items: center; gap: 18px; direction: ltr; }
    .key {
      min-width: 112px;
      height: 66px;
      padding: 12px 22px;
      border-radius: 14px;
      border: 2px solid #d8dde8;
      background: #f6f8fc;
      font: 800 32px SFMono-Regular, Menlo, Consolas, monospace;
      text-align: center;
    }
    .plus { font-size: 38px; font-weight: 900; color: #2b2f38; }
    .tag-cloud { display: flex; flex-wrap: wrap; gap: 26px; margin-top: 64px; }
    .tag {
      padding: 18px 34px;
      border-radius: 999px;
      color: #fff;
      font-size: 34px;
      font-weight: 900;
      box-shadow: 0 18px 36px rgba(30, 45, 90, 0.12);
    }
    .memo-visual, .search-visual { height: 1160px; padding: 58px; }
    .search-visual img, .memo-visual img { object-fit: contain; border-radius: 34px; }
    .privacy-layout {
      position: absolute;
      inset: 260px 132px 132px;
      display: grid;
      grid-template-columns: 0.94fr 1.06fr;
      gap: 86px;
      align-items: center;
    }
    .privacy-visual {
      position: relative;
      height: 1120px;
    }
    .privacy-visual .main { position: absolute; left: 0; top: 0; width: 1180px; height: 620px; }
    .privacy-visual .settings { position: absolute; right: 0; bottom: 80px; width: 860px; height: 520px; }
    .privacy-visual .shield { position: absolute; right: 35px; top: 0; width: 420px; height: 420px; object-fit: contain; filter: drop-shadow(0 24px 44px rgba(60, 80, 170, 0.18)); }
    .privacy-pills { display: grid; gap: 24px; margin-top: 68px; max-width: 620px; }
    .pill {
      display: inline-flex;
      width: max-content;
      max-width: 100%;
      padding: 18px 30px;
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.72);
      border: 1px solid rgba(255, 255, 255, 0.8);
      font-size: 32px;
      font-weight: 850;
      color: #2f3644;
    }
    .contact-sheet {
      width: 1500px;
      height: 1450px;
      padding: 40px;
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      grid-auto-rows: 450px;
      gap: 34px 40px;
      background: #f6f8fc;
    }
    .contact-sheet img { width: 690px; height: 431px; object-fit: cover; border-radius: 10px; box-shadow: 0 12px 30px rgba(30,45,90,.12); }
    .contact-item span { display: block; margin-top: 8px; font: 700 16px -apple-system, BlinkMacSystemFont, sans-serif; color: #52596a; }
  </style>
</head>
<body class="${locale.dir === "rtl" ? "rtl" : ""}">
  ${body}
</body>
</html>`;
}

function brand() {
  return `<div class="brand"><img src="${dataUrl("app-icon-256.png")}" alt="">TagLauncher</div>`;
}

function slideHero(locale, copy) {
  const languageBadge = locale.code === "zh-Hans"
    ? "macOS 14.0+ · 29 种界面语言"
    : locale.code === "zh-Hant"
      ? "macOS 14.0+ · 29 種介面語言"
      : "macOS 14.0+ · 29 UI languages";
  return baseHtml(locale, `
    <section class="slide hero-slide">
      ${brand()}
      <div class="grid2">
        <div class="copy">
          <h1 class="hero-title">${esc(copy.heroTitle)}</h1>
          <p>${esc(copy.heroLead)}</p>
          <div class="shortcut"><span class="shortcut-label">${esc(languageBadge)}</span>${keycaps(["Option", "Shift", "Space"])}</div>
        </div>
        <div class="floating-visual"><img src="${dataUrl("hero-visual.jpg")}" alt=""></div>
      </div>
    </section>`);
}

function slideViews(locale, copy, modes) {
  return baseHtml(locale, `
    <section class="slide">
      ${brand()}
      <div class="grid2 reverse">
        <div class="shot-grid">
          ${[1, 2, 3, 4].map((num) => `<div class="shot-card"><img src="${dataUrl(`views/view-0${num}.jpg`)}" alt=""></div>`).join("")}
        </div>
        <div class="copy">
          <span class="eyebrow">${esc(copy.modesTitle)}</span>
          <h1>${esc(copy.viewsTitle)}</h1>
          <p>${esc(copy.viewsLead)}</p>
          <ul class="mode-list">${modes.map((mode) => `<li>${esc(mode)}</li>`).join("")}</ul>
        </div>
      </div>
    </section>`);
}

function slideTags(locale, copy, modes, app) {
  const tags = [
    app["tag.writing"] || "Writing",
    app["tag.development"] || "Development",
    "AI",
    app["tag.design"] || "Design"
  ];
  const colors = ["#54c567", "#b165cf", "#53a0ee", "#ff635d"];
  return baseHtml(locale, `
    <section class="slide">
      ${brand()}
      <div class="grid2">
        <div class="copy">
          <h1>${esc(copy.tagsTitle)}</h1>
          <p>${esc(copy.tagsLead)}</p>
          <div class="tag-cloud">${tags.map((tag, i) => `<span class="tag" style="background:${colors[i]}">${esc(tag)}</span>`).join("")}</div>
        </div>
        <div class="glass-card memo-visual"><img src="${dataUrl("tags-management.jpg")}" alt=""></div>
      </div>
    </section>`);
}

function slideSearch(locale, copy) {
  return baseHtml(locale, `
    <section class="slide">
      ${brand()}
      <div class="grid2">
        <div class="copy">
          <h1>${esc(copy.searchTitle)}</h1>
          <p>${esc(copy.searchLead)}</p>
          <div class="shortcut"><span class="shortcut-label">${esc(copy.shortcut)}</span>${keycaps(["Fn", "Space"])}</div>
        </div>
        <div class="glass-card search-visual"><img src="${dataUrl("quick-search.png")}" alt=""></div>
      </div>
    </section>`);
}

function slideNotes(locale, copy) {
  return baseHtml(locale, `
    <section class="slide">
      ${brand()}
      <div class="grid2">
        <div class="copy">
          <h1>${esc(copy.notesTitle)}</h1>
          <p>${esc(copy.notesLead)}</p>
        </div>
        <div class="glass-card memo-visual"><img src="${dataUrl("app-memo.png")}" alt=""></div>
      </div>
    </section>`);
}

function slidePrivacy(locale, copy) {
  return baseHtml(locale, `
    <section class="slide">
      ${brand()}
      <div class="privacy-layout">
        <div class="copy">
          <h1>${esc(copy.privacyTitle)}</h1>
          <p>${esc(copy.privacyLead)}</p>
          <div class="privacy-pills">
            <span class="pill">Local data</span>
            <span class="pill">JSON backup</span>
            <span class="pill">No ads</span>
          </div>
        </div>
        <div class="privacy-visual">
          <div class="shot-card main"><img src="${dataUrl("backup-restore.jpg")}" alt=""></div>
          <div class="shot-card settings"><img src="${dataUrl("screenshot-settings.jpg")}" alt=""></div>
          <img class="shield" src="${dataUrl("shield-check.png")}" alt="">
        </div>
      </div>
    </section>`);
}

const SLIDES = [
  ["01-hero-launcher-2880x1800.png", slideHero],
  ["02-four-views-2880x1800.png", slideViews],
  ["03-multi-tag-system-2880x1800.png", slideTags],
  ["04-quick-search-2880x1800.png", slideSearch],
  ["05-app-notes-2880x1800.png", slideNotes],
  ["06-private-offline-2880x1800.png", slidePrivacy]
];

async function cleanGeneratedPngs(dir) {
  await fs.mkdir(dir, { recursive: true });
  for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
    if (entry.isFile() && entry.name.endsWith(".png")) {
      await fs.rm(path.join(dir, entry.name));
    }
  }
}

async function renderLocale(browser, locale) {
  const copy = getCopy(locale.code);
  const app = loadAppStrings(ROOT, locale);
  const modes = modeLabels(app);
  const outDir = path.join(OUT_ROOT, locale.code);
  await cleanGeneratedPngs(outDir);

  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  for (const [name, renderer] of SLIDES) {
    const html = renderer(locale, copy, modes, app);
    await page.setContent(html, { waitUntil: "load" });
    await page.evaluate(() => document.fonts && document.fonts.ready);
    await page.screenshot({ path: path.join(outDir, name), type: "png" });
    console.log(path.join(outDir, name));
  }
  await page.close();
  await renderContactSheet(browser, outDir);
}

async function renderContactSheet(browser, outDir) {
  const items = SLIDES.map(([name]) => {
    const p = path.join(outDir, name);
    return `<div class="contact-item"><img src="${dataUrl(p)}"><span>${esc(name)}</span></div>`;
  }).join("");
  const html = `<!doctype html><html><head><meta charset="utf-8"><style>${contactSheetCss()}</style></head><body><div class="contact-sheet">${items}</div></body></html>`;
  const page = await browser.newPage({ viewport: { width: 1500, height: 1450 }, deviceScaleFactor: 1 });
  await page.setContent(html, { waitUntil: "load" });
  await page.screenshot({ path: path.join(outDir, "_contact-sheet.png"), type: "png" });
  await page.close();
  console.log(path.join(outDir, "_contact-sheet.png"));
}

function contactSheetCss() {
  return `
    * { box-sizing: border-box; }
    html, body { margin: 0; width: 1500px; height: 1450px; overflow: hidden; }
    body { background: #f6f8fc; font-family: -apple-system, BlinkMacSystemFont, sans-serif; }
    .contact-sheet { width: 1500px; height: 1450px; padding: 40px; display: grid; grid-template-columns: repeat(2, 1fr); grid-auto-rows: 450px; gap: 34px 40px; }
    .contact-item img { width: 690px; height: 431px; object-fit: cover; border-radius: 10px; box-shadow: 0 12px 30px rgba(30,45,90,.12); display: block; }
    .contact-item span { display: block; margin-top: 8px; font: 700 16px -apple-system, BlinkMacSystemFont, sans-serif; color: #52596a; }
  `;
}

async function main() {
  const browser = await chromium.launch({ executablePath: chromium.executablePath(), headless: true });
  try {
    for (const locale of LOCALES) {
      await renderLocale(browser, locale);
    }
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
