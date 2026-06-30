import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  LOCALES,
  ascDescription,
  getCopy,
  helpUrl,
  loadAppStrings,
  modeLabels,
  pageFile,
  privacyFile,
  whatsNew
} from "./localized-content.mjs";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(SCRIPT_DIR, "../..");
const DOCS = path.join(ROOT, "docs");
const OP_DIR = path.join(ROOT, "Docs/X-Op资料/AppStoreConnect");

function esc(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function lines(value) {
  return esc(value).split(/\s*\|\s*/).map((line) => `<span>${line}</span>`).join("\n          ");
}

function altLinks(kind) {
  return LOCALES.map((locale) => `  <link rel="alternate" hreflang="${esc(locale.htmlLang)}" href="${esc(pageFile(kind, locale))}">`).join("\n");
}

function langSelect(kind, current) {
  const options = LOCALES.map((locale) => {
    const selected = locale.code === current.code ? " selected" : "";
    return `<option value="${esc(pageFile(kind, locale))}"${selected}>${esc(locale.nativeName)}</option>`;
  }).join("");
  return `
      <div class="lang-switch lang-switch--select">
        <label class="sr-only" for="language-${kind}">${esc(getCopy(current.code).language)}</label>
        <select id="language-${kind}" class="language-select" aria-label="${esc(getCopy(current.code).language)}" onchange="if (this.value) window.location.href=this.value">
          ${options}
        </select>
      </div>`;
}

function header(kind, locale, copy) {
  const index = pageFile("index", locale);
  const support = pageFile("support", locale);
  const privacy = privacyFile(locale);
  const help = helpUrl(locale);
  return `  <header class="site-header">
    <div class="layout site-header__bar">
      <a class="brand" href="${esc(index)}">
        <img src="assets/app-icon-256.png" width="34" height="34" alt="">
        TagLauncher
      </a>
      <nav class="site-nav" aria-label="${esc(copy.language)}">
        <a href="${esc(index)}"${kind === "index" ? ' aria-current="page"' : ""}>${esc(copy.home)}</a>
        <a href="${esc(support)}"${kind === "support" ? ' aria-current="page"' : ""}>${esc(copy.support)}</a>
        <a href="${esc(privacy)}">${esc(copy.privacy)}</a>
        <a href="${esc(help)}" rel="noopener" type="application/pdf">${esc(copy.help)}</a>
      </nav>${langSelect(kind, locale)}
    </div>
  </header>`;
}

function footer(locale, copy) {
  return `  <footer class="site-footer">
    <div class="layout">
      <p>
        <a href="mailto:shanghai3168@gmail.com">shanghai3168@gmail.com</a>
        · <a href="${esc(pageFile("support", locale))}">${esc(copy.support)}</a>
        · <a href="${esc(privacyFile(locale))}">${esc(copy.privacy)}</a>
      </p>
      <p>© 2026 TagLauncher · Hainan Wanxing Technology Co., Ltd. (海南万幸科技有限公司)</p>
    </div>
  </footer>`;
}

function homePage(locale) {
  const copy = getCopy(locale.code);
  const app = loadAppStrings(ROOT, locale);
  const modes = modeLabels(app);
  const support = pageFile("support", locale);
  const privacy = privacyFile(locale);
  const viewsLead = copy.siteViewsLead || copy.viewsLead;
  const tagsVisualLine = copy.siteTagsVisualLine
    ? esc(copy.siteTagsVisualLine)
    : `<strong>${esc(app["settings.coloredContainer"] || "Colored Container")}</strong> · ${esc(app["settings.gridContainer"] || "Colorless Grid")}`;
  const tagsDragLine = copy.siteTagsDragLine
    ? esc(copy.siteTagsDragLine)
    : `${esc(app["edit.dragHint"] || "Drag to reorder")} · JSON`;
  return `<!DOCTYPE html>
<html lang="${esc(locale.htmlLang)}" dir="${esc(locale.dir)}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TagLauncher — ${esc(app["app.description"] || "Tag-based Mac app launcher")}</title>
  <meta name="description" content="${esc(copy.heroLead)}">
  <meta property="og:image" content="https://shanghai3168.github.io/taglauncher/assets/hero-visual.jpg">
  <link rel="stylesheet" href="styles.css">
${altLinks("index")}
</head>
<body class="page-home page-locale-${esc(locale.code)}">
${header("index", locale, copy)}

  <section class="hero" aria-label="TagLauncher">
    <div class="layout hero__split">
      <div class="hero__copy">
        <h1 class="hero__headline">
          ${lines(copy.heroTitle)}
        </h1>
        <p class="hero__lead">${esc(copy.heroLead)}</p>
      </div>

      <figure class="hero__art">
        <img src="assets/hero-visual.jpg" alt="TagLauncher App Grid" width="1024" height="908" fetchpriority="high" decoding="async">
      </figure>
    </div>
  </section>

  <section class="views" aria-label="${esc(copy.viewsTitle)}">
    <div class="layout views__split">
      <div class="views__gallery">
        ${[1, 2, 3, 4].map((num, idx) => `<figure class="views__shot"><img src="assets/views/view-0${num}.jpg" alt="${esc(modes[idx])}" width="720" height="468" loading="lazy" decoding="async"></figure>`).join("\n        ")}
      </div>

      <div class="views__copy">
        <h2 class="views__headline">${esc(copy.viewsTitle)}</h2>
        <p class="views__lead">${esc(viewsLead)}</p>
        <hr class="views__rule" aria-hidden="true">
        <div class="views__details">
          <div class="views__modes-block">
            <p class="views__label">${esc(copy.modesTitle)}</p>
            <ul class="views__modes">
              ${modes.map((mode) => `<li>${esc(mode)}</li>`).join("\n              ")}
            </ul>
          </div>
          <div class="views__shortcut">
            <span class="views__shortcut-label">${esc(copy.shortcut)}</span>
            <span class="views__shortcut-keys"><kbd>Option</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd></span>
          </div>
        </div>
      </div>
    </div>
  </section>

  <section class="tags" aria-label="${esc(copy.tagsTitle)}">
    <div class="layout tags__split">
      <div class="tags__copy">
        <h2 class="tags__headline">${esc(copy.tagsTitle)}</h2>
        <ul class="tags__points">
          <li>${esc(copy.tagsLead)}</li>
          <li>${tagsVisualLine}</li>
          <li>${tagsDragLine}</li>
        </ul>
      </div>

      <figure class="tags__art">
        <img src="assets/tags-management.jpg" alt="${esc(copy.tagsTitle)}" width="880" height="572" loading="lazy" decoding="async">
      </figure>
    </div>
  </section>

  <section class="memo" aria-label="${esc(copy.notesTitle)}">
    <div class="layout memo__split">
      <figure class="memo__art">
        <img src="assets/app-memo.png" alt="${esc(copy.notesTitle)}" width="1600" height="1040" loading="lazy" decoding="async">
      </figure>

      <div class="memo__copy">
        <h2 class="memo__headline">${esc(copy.notesTitle)}</h2>
        <p class="memo__lead">${esc(copy.notesLead)}</p>
      </div>
    </div>
  </section>

  <section class="search" aria-label="${esc(copy.searchTitle)}">
    <div class="layout search__split">
      <div class="search__copy">
        <h2 class="search__headline">${esc(copy.searchTitle)}</h2>
        <p class="search__lead">${esc(copy.searchLead)}</p>
        <p class="search__tagline">${esc(app["quickSearch.placeholder"] || "Search apps, tags, and notes")}</p>
        <div class="search__shortcut">
          <span class="search__shortcut-label">${esc(copy.shortcut)}</span>
          <span class="search__shortcut-keys"><kbd>fn</kbd> + <kbd>Space</kbd></span>
        </div>
      </div>

      <figure class="search__art">
        <img src="assets/quick-search.png" alt="${esc(copy.searchTitle)}" width="1809" height="1357" loading="lazy" decoding="async">
      </figure>
    </div>
  </section>

  <section class="backup" aria-label="${esc(copy.backupTitle)}">
    <div class="layout backup__split">
      <figure class="backup__art">
        <img src="assets/backup-restore.jpg" alt="${esc(copy.backupTitle)}" width="1024" height="558" loading="lazy" decoding="async">
      </figure>
      <div class="backup__copy">
        <h2 class="backup__headline">${esc(copy.backupTitle)}</h2>
        <p class="backup__lead">${esc(copy.backupLead)}</p>
      </div>
    </div>
  </section>

  <section class="privacy" aria-label="${esc(copy.privacyTitle)}">
    <div class="layout privacy__split">
      <div class="privacy__copy">
        <h2 class="privacy__headline">${esc(copy.privacyTitle)}</h2>
        <p class="privacy__lead">${esc(copy.privacyLead)}</p>
        <div class="privacy__feature">
          <h3 class="privacy__feature-title"><span class="privacy__feature-icon" aria-hidden="true"></span>${esc(copy.smartTitle)}</h3>
          <p class="privacy__feature-text">${esc(copy.smartLead)}</p>
        </div>
      </div>
      <figure class="privacy__art">
        <img src="assets/shield-check.png" alt="" width="379" height="437" loading="lazy" decoding="async" role="presentation">
      </figure>
    </div>
  </section>

  <section class="features" aria-label="${esc(copy.smartTitle)}">
    <div class="layout">
      <h2 class="features__headline">${esc(copy.smartTitle)}</h2>
      <div class="feature-grid">
        <div class="feature"><strong>App Grid</strong>${esc(viewsLead)}</div>
        <div class="feature"><strong>Quick Search</strong>${esc(copy.searchLead)}</div>
        <div class="feature"><strong>${esc(app["settings.tags"] || "Tags")}</strong>${esc(copy.tagsLead)}</div>
        <div class="feature"><strong>${esc(app["settings.backup"] || "Backup & Restore")}</strong>${esc(copy.backupLead)}</div>
        <div class="feature"><strong>${esc(copy.privacy)}</strong>${esc(copy.privacyLead)}</div>
        <div class="feature"><strong>${esc(copy.smartTitle)}</strong>${esc(copy.smartLead)}</div>
      </div>
      <div class="features__cta">
        <p>${esc(copy.cta)}</p>
        <div class="cta-row">
          <a class="btn btn-primary" href="${esc(support)}">${esc(copy.support)}</a>
          <a class="btn btn-secondary" href="${esc(privacy)}">${esc(copy.privacy)}</a>
        </div>
      </div>
    </div>
  </section>

${footer(locale, copy)}
</body>
</html>
`;
}

function supportPage(locale) {
  const copy = getCopy(locale.code);
  const help = helpUrl(locale);
  return `<!DOCTYPE html>
<html lang="${esc(locale.htmlLang)}" dir="${esc(locale.dir)}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${esc(copy.supportTitle || copy.support)} — TagLauncher</title>
  <meta name="description" content="TagLauncher support, shortcuts, FAQ, contact email, and help PDF.">
  <link rel="stylesheet" href="styles.css">
${altLinks("support")}
</head>
<body>
${header("support", locale, copy)}

  <main class="page-main">
    <div class="layout prose">
      <article class="card">
        <h1>${esc(copy.supportTitle || copy.support)}</h1>
        <p>
          <strong>${esc(copy.version)}:</strong> 7.9.1 (Build 20260613.2020)<br>
          <strong>${esc(copy.requirement)}:</strong> macOS 14.0+
        </p>

        <h2>${esc(copy.contact)}</h2>
        <p>Email: <a href="mailto:shanghai3168@gmail.com">shanghai3168@gmail.com</a></p>
        <p>${esc(copy.supportIntro)}</p>

        <h2>${esc(copy.shortcuts)}</h2>
        <ul>
          <li><kbd>Option</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> — App Grid</li>
          <li><kbd>Space</kbd> — Quick Search inside App Grid</li>
          <li><kbd>Fn</kbd> + <kbd>Space</kbd> — Global Quick Search</li>
          <li><kbd>Esc</kbd> — Close Quick Search or App Grid</li>
          <li><kbd>Command</kbd> + <kbd>,</kbd> — Settings</li>
        </ul>

        <h2>${esc(copy.help)}</h2>
        <p>${esc(copy.helpIntro)}</p>
        <p><a href="${esc(help)}" rel="noopener" type="application/pdf">${esc(copy.help)}</a></p>

        <h2>${esc(copy.faq)}</h2>
        <h3>${esc(copy.faqLoading)}</h3>
        <p>${esc(copy.faqLoadingAnswer)}</p>
        <h3>${esc(copy.faqBackup)}</h3>
        <p>${esc(copy.faqBackupAnswer)}</p>
        <h3>${esc(copy.faqMulti)}</h3>
        <p>${esc(copy.faqMultiAnswer)}</p>
        <h3>${esc(copy.faqCloud)}</h3>
        <p>${esc(copy.faqCloudAnswer)}</p>
      </article>
    </div>
  </main>

${footer(locale, copy)}
</body>
</html>
`;
}

function metadata() {
  const result = {};
  for (const locale of LOCALES) {
    const copy = getCopy(locale.code);
    const app = loadAppStrings(ROOT, locale);
    result[locale.code] = {
      ascLocale: locale.ascLocale,
      ascName: locale.ascName,
      appName: "TagLauncher",
      subtitle: app["app.description"] || "Tag-based app launcher",
      promotionalText: copy.heroLead,
      description: ascDescription(copy, app),
      whatsNew: whatsNew(copy),
      keywords: [
        "TagLauncher",
        "Launchpad",
        app["settings.tags"] || "tags",
        app["quickSearch.title"] || "Quick Search",
        app["settings.backup"] || "backup",
        "Mac"
      ].join(","),
      marketingUrl: `https://shanghai3168.github.io/taglauncher/${pageFile("index", locale)}`,
      supportUrl: `https://shanghai3168.github.io/taglauncher/${pageFile("support", locale)}`,
      screenshotsDir: `/Users/ar/Projects/Taglauncher/Docs/X-Op资料/Screenshots/AppStore-Marketing/${locale.code}`
    };
  }
  return result;
}

function main() {
  for (const locale of LOCALES) {
    fs.writeFileSync(path.join(DOCS, pageFile("index", locale)), homePage(locale), "utf8");
    fs.writeFileSync(path.join(DOCS, pageFile("support", locale)), supportPage(locale), "utf8");
  }

  fs.mkdirSync(OP_DIR, { recursive: true });
  fs.writeFileSync(path.join(OP_DIR, "localized-metadata.json"), `${JSON.stringify(metadata(), null, 2)}\n`, "utf8");

  const markdown = [
    "# App Store Connect Localized Metadata",
    "",
    "Generated from `docs/scripts/localized-content.mjs`.",
    "",
    ...Object.entries(metadata()).flatMap(([code, item]) => [
      `## ${code} — ${item.ascName}`,
      "",
      `- ASC locale: \`${item.ascLocale}\``,
      `- Marketing URL: ${item.marketingUrl}`,
      `- Support URL: ${item.supportUrl}`,
      `- Screenshots: \`${item.screenshotsDir}\``,
      `- Subtitle: ${item.subtitle}`,
      "",
      "### Promotional Text",
      "",
      item.promotionalText,
      "",
      "### What's New",
      "",
      item.whatsNew,
      "",
      "### Description",
      "",
      item.description,
      ""
    ])
  ].join("\n");
  fs.writeFileSync(path.join(OP_DIR, "ASC_LOCALIZED_METADATA.md"), markdown, "utf8");
  console.log(`Generated ${LOCALES.length * 2} localized site pages and ASC metadata draft.`);
}

main();
