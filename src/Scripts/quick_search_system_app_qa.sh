#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_LAYER="$ROOT_DIR/Apptag/DataLayer.swift"
KEYCHAIN_APP="/System/Library/CoreServices/Applications/Keychain Access.app"
MODULE_CACHE_DIR="${MODULE_CACHE_DIR:-${TMPDIR:-/tmp}/taglauncher-quick-search-qa-cache}"
mkdir -p "$MODULE_CACHE_DIR"

rg -Fq 'URL(fileURLWithPath: "/System/Library/CoreServices/Applications")' "$DATA_LAYER"
rg -Fq '"/System/Library/CoreServices/Applications/"' "$DATA_LAYER"

swift -module-cache-path "$MODULE_CACHE_DIR" - "$KEYCHAIN_APP" <<'SWIFT'
import Foundation
import CoreServices

let appPath = CommandLine.arguments[1]
let appURL = URL(fileURLWithPath: appPath)

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
    exit(1)
}

guard FileManager.default.fileExists(atPath: appPath) else {
    fail("Keychain Access app is missing at \(appPath)")
}

let indexedSearchPaths = [
    "/Applications",
    "/System/Applications",
    "/System/Library/CoreServices/Applications",
    "/System/Cryptexes/App/System/Applications",
    "/System/Volumes/Preboot/Cryptexes/App/System/Applications",
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications")
        .path
]

guard indexedSearchPaths.contains(where: { appPath.hasPrefix($0 + "/") }) else {
    fail("Keychain Access is not under a configured app search path")
}

var names: [String] = [
    appURL.deletingPathExtension().lastPathComponent
]

if let item = MDItemCreate(nil, appPath as CFString),
   let displayName = MDItemCopyAttribute(item, kMDItemDisplayName) as? String {
    names.append(displayName)
}

if let bundle = Bundle(url: appURL),
   let loctableURL = bundle.url(forResource: "InfoPlist", withExtension: "loctable"),
   let loctable = NSDictionary(contentsOf: loctableURL) as? [String: Any],
   let zhTable = loctable["zh_CN"] as? [String: Any] {
    if let value = zhTable["CFBundleDisplayName"] as? String { names.append(value) }
    if let value = zhTable["CFBundleName"] as? String { names.append(value) }
}

func normalize(_ value: String) -> String {
    value
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        .lowercased()
}

func pinyinCandidates(for value: String) -> [String] {
    let mutable = NSMutableString(string: value)
    CFStringTransform(mutable, nil, kCFStringTransformToLatin, false)
    CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)
    let spaced = normalize(mutable as String)
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    let compact = spaced.replacingOccurrences(of: " ", with: "")
    let initials = spaced
        .split(separator: " ")
        .compactMap(\.first)
        .map(String.init)
        .joined()
    var seen = Set<String>()
    return [spaced, compact, initials].filter { !$0.isEmpty && seen.insert($0).inserted }
}

let searchable = names.flatMap { name in
    [normalize(name)] + pinyinCandidates(for: name)
}

let queries = ["keychain", "钥匙串", "yaoshichuan", "ysc"]
for query in queries {
    let token = normalize(query)
    guard searchable.contains(where: { $0 == token || $0.hasPrefix(token) || $0.contains(token) }) else {
        fail("query \(query) did not match Keychain Access candidates: \(searchable)")
    }
}

print("PASS Keychain Access indexed search candidates: \(names.joined(separator: " | "))")
SWIFT
