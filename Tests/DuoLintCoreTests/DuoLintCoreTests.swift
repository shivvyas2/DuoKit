import Testing
@testable import DuoLintCore

@Suite struct SwiftRuleTests {
    @Test func flagsMainScreen() {
        let findings = DuoLint.lintSwift("let w = UIScreen.main.bounds.width\n", path: "A.swift")
        #expect(findings.map(\.rule) == [.mainScreen])
        #expect(findings.first?.line == 1)
        #expect(findings.first?.severity == .error)
    }

    @Test func flagsIdiomAndOrientationChecks() {
        let source = """
        if UIDevice.current.userInterfaceIdiom == .pad { }
        let o = UIDevice.current.orientation
        let p = windowScene.interfaceOrientation
        """
        let rules = DuoLint.lintSwift(source, path: "A.swift").map(\.rule)
        #expect(rules == [.idiomLayout, .orientationLayout, .orientationLayout])
    }

    @Test func flagsLargeFixedWidthsOnly() {
        let source = """
        .frame(width: 140, height: 140)
        .frame(width: 375)
        .frame(width: 320, height: 200)
        .frame(maxWidth: 600)
        """
        let findings = DuoLint.lintSwift(source, path: "A.swift")
        #expect(findings.map(\.rule) == [.fixedWidth, .fixedWidth])
        #expect(findings.map(\.line) == [2, 3])
    }

    @Test func ignoresComments() {
        #expect(DuoLint.lintSwift("// UIScreen.main is bad\n", path: "A.swift").isEmpty)
    }

    @Test func ignoresStringAndRegexLiterals() {
        let source = """
        log("avoid UIScreen.main // here")
        if line.contains(#/UIScreen\\.main/#) { }
        if line.contains("userInterfaceIdiom") { }
        let w = UIScreen.main.bounds // "quoted"
        """
        let findings = DuoLint.lintSwift(source, path: "A.swift")
        #expect(findings.map(\.line) == [4])
    }
}

@Suite struct ConfigRuleTests {
    @Test func portraitOnlyPlist() {
        let plist = """
        <key>UISupportedInterfaceOrientations</key>
        <array>
            <string>UIInterfaceOrientationPortrait</string>
        </array>
        """
        #expect(DuoLint.lintConfig(plist, path: "Info.plist").map(\.rule) == [.portraitOnly])
    }

    @Test func plistWithLandscapeIsFine() {
        let plist = """
        <key>UISupportedInterfaceOrientations</key>
        <array>
            <string>UIInterfaceOrientationPortrait</string>
            <string>UIInterfaceOrientationLandscapeLeft</string>
        </array>
        """
        #expect(DuoLint.lintConfig(plist, path: "Info.plist").isEmpty)
    }

    @Test func portraitOnlyYAML() {
        let yaml = """
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        UIUserInterfaceStyle: Dark
        """
        #expect(DuoLint.lintConfig(yaml, path: "project.yml").map(\.rule) == [.portraitOnly])
    }

    @Test func portraitOnlyBuildSetting() {
        let pbx = "INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;"
        #expect(DuoLint.lintConfig(pbx, path: "project.pbxproj").map(\.rule) == [.portraitOnly])
    }

    @Test func requiresFullScreen() {
        let plist = "<key>UIRequiresFullScreen</key>\n<true/>"
        #expect(DuoLint.lintConfig(plist, path: "Info.plist").map(\.rule) == [.requiresFullScreen])
        #expect(DuoLint.lintConfig("INFOPLIST_KEY_UIRequiresFullScreen = YES;", path: "project.pbxproj").map(\.rule) == [.requiresFullScreen])
    }
}

@Suite struct OutputTests {
    @Test func xcodeStyleLine() {
        let f = Finding(path: "A.swift", line: 3, rule: .mainScreen)
        #expect(f.formatted.hasPrefix("A.swift:3: error: [main-screen] "))
    }
}
