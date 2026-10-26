# Changelog

All notable changes to DuoKit are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-26

The first release: the components an app needs to feel native on iPhone Duo, and a linter for what keeps it from feeling that way.

### Added

- **`.duoReady()`.** One modifier at the root publishes the posture (compact, expanded, book, tent), the hinge, and the bar edge to every component, and opts system tab views into a sidebar on the inner display. On iOS before 27.1 and on phones without a hinge it reports size classes only.
- **`DuoTabShell`.** A custom tab bar that keeps its look and moves: along the bottom folded, a rail on the system's bar edge, and a sidebar when open. Held like a book, the sidebar fills the left page so navigation and content each get a page. Tabs are created on first view and kept, so state survives tab switches and folding. `bottomBar: .overlaysContent` and `duoTabPlacement` support apps whose pages pad themselves.
- **`DuoGrid`.** A card grid that reflows between displays, rounds to an even column count when open, and lays out each side of the crease separately so the fold never cuts a card. `.duoGridSpan(.full)` for hero rows.
- **`DuoSplit`.** A primary and secondary pair on Apple's `ArrangementView` split style, with a side-by-side or stacked fallback before iOS 27.1.
- **`DuoBar` and `.duoBarInset`.** Icon bars that turn into a column on the system's vertical bar edge.
- **`.avoidsFold()` and `DuoTentLayout`.** Displacement away from the crease, and the tent posture's content-up, controls-down layout.
- **`.duoDebugOverlay()` and `.duoSimulate(_:)`.** Draw the crease, camera, and safe area; fake any posture on any simulator or preview.
- **`duo-lint`.** Six rules for Swift sources and app configuration, in Xcode's warning format, exiting 1 on errors.
- **Demo app.** A health dashboard, a mail split view, a tent-mode player, and a posture lab.

### Fixed

- `DuoGrid` no longer traps when a stack measures it with an infinite width proposal.

[Unreleased]: https://github.com/shivvyas2/DuoKit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/shivvyas2/DuoKit/releases/tag/v0.1.0
