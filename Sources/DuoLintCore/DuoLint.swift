import Foundation

public enum Severity: String, Sendable {
    case error, warning
}

/// Things that keep an app from feeling native on iPhone Duo, from Apple's
/// "Prepare your app for iPhone Duo" guidance.
public enum Rule: String, Sendable, CaseIterable {
    case mainScreen = "main-screen"
    case idiomLayout = "idiom-layout"
    case orientationLayout = "orientation-layout"
    case fixedWidth = "fixed-width"
    case portraitOnly = "portrait-only"
    case requiresFullScreen = "requires-full-screen"

    public var severity: Severity {
        self == .mainScreen ? .error : .warning
    }

    public var message: String {
        switch self {
        case .mainScreen:
            "UIScreen.main is ambiguous on a two-display device and is being deprecated. Use the window scene's screen, or traitCollection.displayScale for scale."
        case .idiomLayout:
            "Laying out by device idiom treats the Duo as a phone even when it is open. Use horizontal and vertical size classes."
        case .orientationLayout:
            "The inner display does not honor supported orientations, so orientation says little about available space. Use size classes or the container's size."
        case .fixedWidth:
            "A fixed width of a phone's size leaves the inner display looking like a stretched phone. Use maxWidth, a flexible layout, or DuoGrid."
        case .portraitOnly:
            "Portrait-only is ignored on the inner display, and people prop the Duo open in landscape. Make sure layouts adapt instead of assuming portrait."
        case .requiresFullScreen:
            "UIRequiresFullScreen is a compatibility mode Apple says will be ignored in a future release. Remove it once the app adapts to any size."
        }
    }
}

public struct Finding: Equatable, Sendable {
    public var path: String
    public var line: Int
    public var rule: Rule

    public var severity: Severity { rule.severity }

    /// `path:line: severity: [rule] message`, which Xcode shows inline when
    /// run from a build phase.
    public var formatted: String {
        "\(path):\(line): \(severity.rawValue): [\(rule.rawValue)] \(rule.message)"
    }
}

public enum DuoLint {
    /// A fixed width at or above this is a phone-sized column.
    static let fixedWidthThreshold: Double = 300

    public static func lintSwift(_ source: String, path: String) -> [Finding] {
        var findings: [Finding] = []
        for (index, rawLine) in source.components(separatedBy: "\n").enumerated() {
            let line = codeOnly(rawLine)
            func flag(_ rule: Rule) { findings.append(Finding(path: path, line: index + 1, rule: rule)) }

            if line.contains(#/UIScreen\.main(?![A-Za-z0-9_])/#) { flag(.mainScreen) }
            if line.contains("userInterfaceIdiom") { flag(.idiomLayout) }
            if line.contains(#/UIDevice\.current\.orientation(?![A-Za-z0-9_])|(?:^|[^A-Za-z0-9_])interfaceOrientation(?![A-Za-z0-9_])/#) { flag(.orientationLayout) }
            if let match = line.firstMatch(of: #/\.frame\(\s*width:\s*(\d+(?:\.\d+)?)/#),
               let width = Double(match.1), width >= fixedWidthThreshold {
                flag(.fixedWidth)
            }
        }
        return findings
    }

    /// Info.plist, xcodegen project.yml, or project.pbxproj build settings.
    public static func lintConfig(_ text: String, path: String) -> [Finding] {
        let lines = text.components(separatedBy: "\n")
        var findings: [Finding] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let following = lines.dropFirst(index + 1)
            func flag(_ rule: Rule) { findings.append(Finding(path: path, line: index + 1, rule: rule)) }

            // Info.plist
            if trimmed == "<key>UISupportedInterfaceOrientations</key>" {
                let values = following
                    .prefix { !$0.contains("</array>") }
                    .compactMap { $0.firstMatch(of: #/<string>(.*?)</string>/#).map { String($0.1) } }
                if isPortraitOnly(values) { flag(.portraitOnly) }
            }
            if trimmed == "<key>UIRequiresFullScreen</key>",
               following.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?.contains("<true/>") == true {
                flag(.requiresFullScreen)
            }

            // project.yml
            if let match = trimmed.wholeMatch(of: #/UISupportedInterfaceOrientations:\s*(.*)/#) {
                let inline = String(match.1).trimmingCharacters(in: CharacterSet(charactersIn: "[] "))
                let values = inline.isEmpty
                    ? following
                        .prefix { $0.trimmingCharacters(in: .whitespaces).hasPrefix("-") }
                        .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "- ")) }
                    : inline.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if isPortraitOnly(values) { flag(.portraitOnly) }
            }
            if trimmed.wholeMatch(of: #/UIRequiresFullScreen:\s*(true|YES)/#) != nil { flag(.requiresFullScreen) }

            // project.pbxproj
            if let match = trimmed.firstMatch(of: #/INFOPLIST_KEY_UISupportedInterfaceOrientations(?:_iPhone)?\s*=\s*"?([^";]*)"?;/#) {
                if isPortraitOnly(match.1.split(separator: " ").map(String.init)) { flag(.portraitOnly) }
            }
            if trimmed.contains(#/INFOPLIST_KEY_UIRequiresFullScreen\s*=\s*YES/#) { flag(.requiresFullScreen) }
        }
        return findings
    }

    static func isPortraitOnly(_ orientations: [String]) -> Bool {
        !orientations.isEmpty && orientations.allSatisfy { $0.contains("Portrait") }
    }

    /// The line with its comment and the insides of string and regex literals
    /// removed, so a log message or a pattern that mentions `UIScreen.main` is
    /// not mistaken for a use of it. Single-line literals only; good enough
    /// for a linter.
    static func codeOnly(_ line: String) -> String {
        var code = ""
        var chars = line[...]
        while let c = chars.first {
            if chars.hasPrefix("//") { break }
            if chars.hasPrefix("#/"), let end = chars.dropFirst(2).range(of: "/#") {
                chars = chars[end.upperBound...]
                continue
            }
            if c == "\"" {
                var rest = chars.dropFirst()
                while let d = rest.first, d != "\"" {
                    rest = rest.dropFirst(d == "\\" ? 2 : 1)
                }
                chars = rest.dropFirst()
                continue
            }
            code.append(c)
            chars = chars.dropFirst()
        }
        return code
    }
}
