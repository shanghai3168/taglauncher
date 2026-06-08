#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_LAYER="$ROOT_DIR/Apptag/DataLayer.swift"
SUNLOGIN_APP="${1:-/Applications/贝锐向日葵被控.app}"

rg -Fq 'localizedNames.first' "$DATA_LAYER"
rg -Fq '.localizedNameKey' "$DATA_LAYER"
rg -Fq 'isNestedInsideAppBundle' "$DATA_LAYER"
rg -Fq '.skipsPackageDescendants' "$DATA_LAYER"

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

func isNestedInsideAppBundle(_ url: URL) -> Bool {
    let components = url.standardizedFileURL.pathComponents
    guard let lastAppIndex = components.lastIndex(where: { $0.lowercased().hasSuffix(".app") }) else {
        return false
    }
    return components[..<lastAppIndex].contains { $0.lowercased().hasSuffix(".app") }
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

func displayName(name: String, localizedNames: [String], localizedNamesByLanguage: [String: String], languageCode: String) -> String {
    var candidates = [languageCode]
    if languageCode == "zh-Hans" { candidates.append("zh-Hant") }
    if languageCode == "zh-Hant" { candidates.append("zh-Hans") }
    candidates.append("en")
    var seen = Set<String>()
    for code in candidates where seen.insert(code).inserted {
        if let localizedName = localizedNamesByLanguage[code], !localizedName.isEmpty {
            return localizedName
        }
    }
    if let localizedName = localizedNames.first, !localizedName.isEmpty {
        return localizedName
    }
    return name
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
    guard bundleDisplayName(for: nestedURL) == expectedDisplayName else {
        fail("nested helper bundle display name did not expose localized name")
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
let helperDisplayName = displayName(
    name: "isunclient",
    localizedNames: helperLocalizedNames,
    localizedNamesByLanguage: [:],
    languageCode: "zh-Hans"
)
guard helperDisplayName == expectedDisplayName else {
    fail("displayName fallback returned \(helperDisplayName) instead of \(expectedDisplayName)")
}

print("PASS quick search app-name QA: \(expectedDisplayName) wrapper wins over nested isunclient")
SWIFT
