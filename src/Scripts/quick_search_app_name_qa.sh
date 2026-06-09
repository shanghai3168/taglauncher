#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_LAYER="$ROOT_DIR/Apptag/DataLayer.swift"
QUICK_SEARCH="$ROOT_DIR/Apptag/QuickSearch.swift"
SUNLOGIN_APP="${1:-/Applications/贝锐向日葵被控.app}"

rg -Fq 'AppDisplayNameResolver.displayName' "$DATA_LAYER"
rg -Fq 'systemDisplayNames' "$DATA_LAYER"
rg -Fq 'bundleDisplayNames' "$DATA_LAYER"
rg -Fq '.localizedNameKey' "$DATA_LAYER"
rg -Fq 'isNestedInsideAppBundle' "$DATA_LAYER"
rg -Fq 'isInternalHelperAppPath' "$DATA_LAYER"
rg -Fq '.skipsPackageDescendants' "$DATA_LAYER"
rg -Fq 'AppDisplayNameResolver.searchAliases' "$QUICK_SEARCH"
rg -Fq 'AppIndexer.isInternalHelperAppPath($0.path)' "$QUICK_SEARCH"

swift - "$SUNLOGIN_APP" <<'SWIFT'
import Foundation
import CoreServices

let appPath = CommandLine.arguments[1]
let appURL = URL(fileURLWithPath: appPath)
let expectedDisplayName = "贝锐向日葵被控"
let nestedURL = appURL
    .appendingPathComponent("Wrapper")
    .appendingPathComponent("isunclient.app")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
    exit(1)
}

func trim(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value
        .replacingOccurrences(of: ".app", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

func normalized(_ value: String) -> String {
    value
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        .lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func uniqueLocalizedNames(_ values: [String?], excluding excludedValue: String) -> [String] {
    let excluded = normalized(excludedValue)
    var seen = Set<String>()
    var result: [String] = []
    for value in values {
        guard let trimmed = trim(value) else { continue }
        let key = normalized(trimmed)
        guard key != excluded, seen.insert(key).inserted else { continue }
        result.append(trimmed)
    }
    return result
}

func uniqueDisplayNames(_ values: [String], excluding excludedValue: String) -> [String] {
    let excluded = normalized(excludedValue)
    var seen = Set<String>()
    var result: [String] = []
    for value in values {
        guard let trimmed = trim(value) else { continue }
        let key = normalized(trimmed)
        guard key != excluded, seen.insert(key).inserted else { continue }
        result.append(trimmed)
    }
    return result
}

struct NameProfile {
    let name: String
    let localizedNames: [String]
    let localizedNamesByLanguage: [String: String]
    let systemDisplayNames: [String]
    let bundleDisplayNames: [String]
}

let supportedLanguages = [
    "en", "fr", "it", "de", "es", "pt-BR", "zh-Hans", "zh-Hant", "ko", "ja",
    "ru", "sr-Cyrl", "uk", "th", "vi", "ar", "ar-Najdi", "tr", "id", "cs",
    "da", "nl", "no", "nn", "nb", "ms", "pl", "ro", "sv"
]

func uniqueLanguageCodes(_ codes: [String]) -> [String] {
    var seen = Set<String>()
    return codes.filter { seen.insert($0).inserted }
}

func displayLanguageFallbacks(for languageCode: String, includeEnglish: Bool = false) -> [String] {
    var candidates = [
        languageCode,
        languageCode.replacingOccurrences(of: "_", with: "-")
    ]

    switch languageCode {
    case "zh-Hans":
        candidates.append("zh-Hant")
    case "zh-Hant":
        candidates.append("zh-Hans")
    case "pt-BR":
        candidates.append("pt")
    case "sr-Cyrl":
        candidates.append("sr")
    case "ar-Najdi":
        candidates.append("ar")
    case "nb":
        candidates.append(contentsOf: ["no", "nn"])
    case "nn":
        candidates.append(contentsOf: ["no", "nb"])
    case "no":
        candidates.append(contentsOf: ["nb", "nn"])
    default:
        if let base = languageCode.split(separator: "-").first.map(String.init) {
            candidates.append(base)
        }
    }

    if includeEnglish {
        candidates.append("en")
    }
    return uniqueLanguageCodes(candidates)
}

func firstDisplayCandidate(_ values: [String]) -> String? {
    values.lazy.compactMap(trim).first
}

func firstLocalizedName(for languageCodes: [String], in localizedNamesByLanguage: [String: String]) -> String? {
    firstDisplayCandidate(languageCodes.compactMap { localizedNamesByLanguage[$0] })
}

func displayName(_ profile: NameProfile, languageCode: String) -> String {
    let languageFallbacks = displayLanguageFallbacks(for: languageCode)

    if let localizedName = firstLocalizedName(
        for: languageFallbacks,
        in: profile.localizedNamesByLanguage
    ) {
        return localizedName
    }

    if languageCode == "en",
       let englishBaseName = firstDisplayCandidate([profile.name] + profile.bundleDisplayNames) {
        return englishBaseName
    }

    if let systemDisplayName = firstDisplayCandidate(profile.systemDisplayNames) {
        return systemDisplayName
    }

    if let englishName = firstLocalizedName(for: ["en"], in: profile.localizedNamesByLanguage) {
        return englishName
    }

    if let bundleDisplayName = firstDisplayCandidate(profile.bundleDisplayNames) {
        return bundleDisplayName
    }

    let skippedLanguageCodes = Set(languageFallbacks + ["en"])
    let remainingLocalizedNames = supportedLanguages.compactMap { languageCode -> String? in
        guard !skippedLanguageCodes.contains(languageCode) else { return nil }
        return profile.localizedNamesByLanguage[languageCode]
    }
    if let localizedName = firstDisplayCandidate(remainingLocalizedNames) {
        return localizedName
    }

    if let alias = firstDisplayCandidate(profile.localizedNames) {
        return alias
    }

    return profile.name
}

func searchAliases(_ profile: NameProfile) -> [String] {
    uniqueDisplayNames(
        supportedLanguages.compactMap { profile.localizedNamesByLanguage[$0] }
            + profile.systemDisplayNames
            + profile.bundleDisplayNames
            + profile.localizedNames
            + [displayName(profile, languageCode: "zh-Hans")],
        excluding: profile.name
    )
}

func isNestedInsideAppBundle(_ url: URL) -> Bool {
    isNestedInsideAppBundlePath(url.standardizedFileURL.path)
}

func isInternalHelperAppPath(_ url: URL) -> Bool {
    let path = url.standardizedFileURL.path
    let lowercasedPath = path.lowercased()
    return isNestedInsideAppBundlePath(path)
        || lowercasedPath.contains("/contents/helpers/")
        || lowercasedPath.contains("/contents/xpcservices/")
        || lowercasedPath.contains("/wrapper/")
}

func isNestedInsideAppBundlePath(_ path: String) -> Bool {
    let lowercasedPath = path.lowercased()
    guard lowercasedPath.hasSuffix(".app") else { return false }
    let components = lowercasedPath.split(separator: "/", omittingEmptySubsequences: true)
    guard let lastAppIndex = components.lastIndex(where: { $0.hasSuffix(".app") }) else {
        return false
    }
    if components[..<lastAppIndex].contains(where: { $0.hasSuffix(".app") }) {
        return true
    }
    return lowercasedPath.range(of: ".app/", options: .caseInsensitive) != nil
}

func spotlightDisplayName(for url: URL) -> String? {
    guard let item = MDItemCreate(nil, url.path as CFString),
          let value = MDItemCopyAttribute(item, kMDItemDisplayName) as? String
    else { return nil }
    return trim(value)
}

func resourceLocalizedName(for url: URL) -> String? {
    let values = try? url.resourceValues(forKeys: [.localizedNameKey])
    return trim(values?.localizedName)
}

func bundleDisplayName(for url: URL) -> String? {
    guard let bundle = Bundle(url: url) else { return nil }
    return trim(bundle.infoDictionary?["CFBundleDisplayName"] as? String)
}

func makeDocumentPaths(appPaths: [URL]) -> [String] {
    appPaths
        .filter { !isInternalHelperAppPath($0) }
        .map(\.path)
}

let multilingualProfile = NameProfile(
    name: "InternalRunner",
    localizedNames: [],
    localizedNamesByLanguage: [
        "en": "English Name",
        "de": "Deutscher Name",
        "ja": "日本語名",
        "zh-Hans": "简体名"
    ],
    systemDisplayNames: ["System Visible"],
    bundleDisplayNames: ["Bundle Visible"]
)
guard displayName(multilingualProfile, languageCode: "de") == "Deutscher Name" else {
    fail("German localized display name was not preferred")
}
guard displayName(multilingualProfile, languageCode: "ja") == "日本語名" else {
    fail("Japanese localized display name was not preferred")
}
guard displayName(multilingualProfile, languageCode: "zh-Hant") == "简体名" else {
    fail("Chinese language fallback did not use paired Chinese localization")
}

let systemFallbackProfile = NameProfile(
    name: "internal-helper",
    localizedNames: [],
    localizedNamesByLanguage: [:],
    systemDisplayNames: ["Nom système"],
    bundleDisplayNames: ["Bundle Visible"]
)
guard displayName(systemFallbackProfile, languageCode: "fr") == "Nom système" else {
    fail("system/Finder display name was not used before bundle/internal names")
}

let englishBaseProfile = NameProfile(
    name: "AweSun",
    localizedNames: [],
    localizedNamesByLanguage: [:],
    systemDisplayNames: ["贝锐向日葵"],
    bundleDisplayNames: []
)
guard displayName(englishBaseProfile, languageCode: "en") == "AweSun" else {
    fail("English users should keep a presentable English base app name")
}
guard displayName(englishBaseProfile, languageCode: "zh-Hans") == "贝锐向日葵" else {
    fail("non-English users should still get system-localized display fallback")
}

let englishFallbackProfile = NameProfile(
    name: "inner-name",
    localizedNames: [],
    localizedNamesByLanguage: ["en": "Official English"],
    systemDisplayNames: [],
    bundleDisplayNames: []
)
guard displayName(englishFallbackProfile, languageCode: "sv") == "Official English" else {
    fail("official English display name was not used as cross-language fallback")
}

guard FileManager.default.fileExists(atPath: appPath) else {
    print("SKIP Sunlogin wrapper app not installed at \(appPath)")
    exit(0)
}

guard appURL.deletingPathExtension().lastPathComponent == expectedDisplayName else {
    fail("outer wrapper file name is not the localized app name: \(appURL.lastPathComponent)")
}

if FileManager.default.fileExists(atPath: nestedURL.path) {
    guard isNestedInsideAppBundle(nestedURL) else {
        fail("nested helper app was not classified as nested: \(nestedURL.path)")
    }
    guard isInternalHelperAppPath(nestedURL) else {
        fail("nested helper app was not classified as internal helper: \(nestedURL.path)")
    }
    guard bundleDisplayName(for: nestedURL) == expectedDisplayName else {
        fail("nested helper bundle display name did not expose localized name")
    }
}

let helperPathFixtures = [
    "/Applications/Outer.app/Contents/Helpers/Inner.app",
    "/Applications/Outer.app/Contents/XPCServices/Inner.app",
    "/Applications/Outer.app/Wrapper/Inner.app"
]
for helperPath in helperPathFixtures {
    guard isInternalHelperAppPath(URL(fileURLWithPath: helperPath)) else {
        fail("helper path fixture was not filtered: \(helperPath)")
    }
}

var enumeratedHits: [String] = []
if let enumerator = FileManager.default.enumerator(
    at: URL(fileURLWithPath: "/Applications"),
    includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
    options: [.skipsHiddenFiles, .skipsPackageDescendants]
) {
    for case let url as URL in enumerator {
        if url.path.contains(expectedDisplayName) || url.path.contains("isunclient") {
            enumeratedHits.append(url.path)
        }
    }
}

guard enumeratedHits.contains(appPath) else {
    fail("outer wrapper app was not visible to the scanner")
}
guard !enumeratedHits.contains(nestedURL.path) else {
    fail("scanner enumerated nested helper app: \(nestedURL.path)")
}

let outerNames = uniqueLocalizedNames(
    [
        resourceLocalizedName(for: appURL),
        spotlightDisplayName(for: appURL),
        FileManager.default.displayName(atPath: appURL.path)
    ],
    excluding: appURL.deletingPathExtension().lastPathComponent
)
guard appURL.deletingPathExtension().lastPathComponent == expectedDisplayName ||
      outerNames.contains(expectedDisplayName) else {
    fail("outer wrapper localized display name was not discoverable")
}

let helperLocalizedNames = uniqueLocalizedNames(
    [
        bundleDisplayName(for: nestedURL),
        resourceLocalizedName(for: nestedURL),
        spotlightDisplayName(for: nestedURL),
        FileManager.default.displayName(atPath: nestedURL.path)
    ],
    excluding: "isunclient"
)
let helperProfile = NameProfile(
    name: "isunclient",
    localizedNames: helperLocalizedNames,
    localizedNamesByLanguage: [:],
    systemDisplayNames: helperLocalizedNames,
    bundleDisplayNames: []
)
let helperDisplayName = displayName(helperProfile, languageCode: "zh-Hans")
guard helperDisplayName == expectedDisplayName else {
    fail("displayName fallback returned \(helperDisplayName) instead of \(expectedDisplayName)")
}

let documentPaths = makeDocumentPaths(appPaths: [appURL, nestedURL])
guard documentPaths.contains(appPath) else {
    fail("Quick Search document fixture dropped outer wrapper app")
}
guard !documentPaths.contains(nestedURL.path) else {
    fail("Quick Search document fixture included nested helper app: \(nestedURL.path)")
}
guard searchAliases(helperProfile).contains(expectedDisplayName) else {
    fail("display aliases did not retain localized helper name for search")
}

print("PASS quick search app-name QA: \(expectedDisplayName) wrapper wins over nested isunclient")
SWIFT
