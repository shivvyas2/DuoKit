import DuoLintCore
import Foundation

// duo-lint [path ...]
// Scans Swift sources and app configuration for things that keep an app from
// feeling native on iPhone Duo. Exits 1 when any finding is an error, so it
// can gate CI or run as an Xcode build phase.

let skippedDirectories: Set<String> = [
    ".build", ".git", "build", "build.noindex", "DerivedData", "Pods", "Carthage",
    "SourcePackages", "node_modules", "checkouts",
]

func files(under root: URL) -> [URL] {
    let keys: [URLResourceKey] = [.isDirectoryKey]
    guard (try? root.resourceValues(forKeys: Set(keys)))?.isDirectory == true,
          let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys) else {
        return [root]
    }
    var found: [URL] = []
    for case let url as URL in walker {
        if (try? url.resourceValues(forKeys: Set(keys)))?.isDirectory == true {
            if skippedDirectories.contains(url.lastPathComponent) { walker.skipDescendants() }
            continue
        }
        found.append(url)
    }
    return found
}

func lint(_ url: URL, displayPath: String) -> [Finding] {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    switch url.pathExtension {
    case "swift": return DuoLint.lintSwift(text, path: displayPath)
    case "plist", "pbxproj": return DuoLint.lintConfig(text, path: displayPath)
    case "yml", "yaml":
        // xcodegen's project.yml; other YAML (CI, configs) is not ours to judge.
        return url.lastPathComponent.hasPrefix("project") ? DuoLint.lintConfig(text, path: displayPath) : []
    default: return []
    }
}

let roots = CommandLine.arguments.dropFirst().isEmpty ? ["."] : Array(CommandLine.arguments.dropFirst())
let cwd = FileManager.default.currentDirectoryPath + "/"
var findings: [Finding] = []
for root in roots {
    for url in files(under: URL(fileURLWithPath: root)) {
        let path = url.path.hasPrefix(cwd) ? String(url.path.dropFirst(cwd.count)) : url.path
        findings += lint(url, displayPath: path)
    }
}

findings.forEach { print($0.formatted) }
let errors = findings.filter { $0.severity == .error }.count
print("duo-lint: \(errors) error(s), \(findings.count - errors) warning(s)")
exit(errors > 0 ? 1 : 0)
