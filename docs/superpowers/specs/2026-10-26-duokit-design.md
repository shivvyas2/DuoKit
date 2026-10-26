# DuoKit design

Date: 2026-10-26 · Status: accepted

## Why

On iPhone Duo, apps built before the iOS 27.1 SDK run letterboxed in a
phone-shaped box on the inner display. Rebuilding with the 27.1 SDK fixes
the box, and Apple's standard containers (TabView, NavigationSplitView,
toolbars, sheets) then adapt on their own. Custom UI does not: hand-built tab
bars, dashboards, card grids, and fixed-width layouts still look like a
stretched phone. That custom UI is what makes most apps feel non-native on
the Duo. Users cannot fix this from outside the app; iOS has no
force-full-screen switch and no way to restyle another app.

DuoKit is a free, MIT-licensed Swift package that gives developers the
custom pieces, already adapted to Apple's iPhone Duo guidelines.

## Goals

- An app adopts DuoKit in an afternoon: one root modifier, then swap two or
  three custom pieces.
- Every component looks right folded (compact), open (regular), open in
  landscape (vertical bars), and partially folded (book and tent), with no
  per-pose code in the app.
- Supports iOS 17+. Duo-specific behaviour switches on only when iOS 27.1
  APIs exist; elsewhere components behave like ordinary iPhone/iPad UI.
- Built on Apple's real 27.1 APIs, not reimplementations of them.

## Non-goals

- Changing other apps from outside (impossible on iOS).
- The web-app "Duo shell" for services whose apps are letterboxed:
  a separate, later project.
- UIKit components in v1 (SwiftUI first; UIKit later).

## Anti-goals

- Anything that makes an app look worse on a regular iPhone.
- A design language of its own. DuoKit takes the app's styling; it only
  decides placement.

## Apple guidance this encodes (HIG + Tech Talk 111461)

- Lay out by size class, never by orientation, idiom or screen size.
  Outer display: compact width; inner display: regular/regular.
- Bars go vertical on the outer display and on the inner display in
  landscape. Icon-only items stand vertically; text-only items stay
  horizontal. Back/Close on top, prominent action next.
  SDK: `EnvironmentValues.toolbarVerticalEdge: HorizontalEdge?` (27.1).
- Inner display patterns: split view, reflow (one column → two), sidebar.
  SDK: `defaultTabBarPlacement(.sidebar)`, `ArrangementView` with
  `.split` / `.overlay` styles (27.1).
- Fold avoidance: displace, don't redesign; scrolling content is exempt;
  grids keep outer margins, prefer an even column count, add space at the
  hinge. Tent: glanceable content up, controls down.
  SDK: `GeometryProxy.reservedRegions(kind: .division / .occlusion)`,
  `onHingeChange` → `DeviceHinge.status` / `.angle` (27.1).
- Asymmetric safe areas: inset each side independently.

## Components

| Piece | What it does |
| --- | --- |
| `.duoReady()` | Root modifier. Publishes a `DuoLayout` (posture, bar edge, hinge) into the environment. Opts TabViews into sidebar placement when open. |
| `DuoLayout` / `DuoPosture` | `.compact`, `.expanded`, `.book`, `.tent`, resolved from size classes, hinge status and the fold's orientation. Pure function, unit-tested. |
| `DuoBar` | Container for a custom bar. Lays items in a row, or a column on the system's vertical edge. |
| `DuoTabShell` | For apps with a custom tab bar: bottom bar when compact, vertical rail on the side when bars are vertical, sidebar list when open. App supplies tabs and its own item styling. |
| `DuoGrid` | `Layout` that reflows cards: column count from width, rounded to even when open, extra gutter where the fold crosses. |
| `DuoSplit` | Primary/secondary pair. `ArrangementView(.split)` on 27.1; HStack-or-stack by size class before. |
| `.avoidsFold()` | Nudges a view out of the fold line when partially folded. |
| `DuoTentLayout` | Top (glanceable) and bottom (controls) halves either side of a horizontal fold. |
| `.duoDebugOverlay()` | Draws fold, camera cutout and safe area while developing. |
| `duo-lint` | CLI that flags Duo blockers in a project: `UIScreen.main`, portrait-only orientation lists, `UIRequiresFullScreen`, large fixed widths, layout by `userInterfaceIdiom` or orientation. |

## Repo layout

```
Package.swift            DuoKit library, DuoLintCore library, duo-lint executable
Sources/DuoKit/          SwiftUI components
Sources/DuoLintCore/     lint rules (pure, tested)
Sources/duo-lint/        CLI entry point
Tests/                   DuoKitTests, DuoLintCoreTests
Demo/                    xcodegen demo app showing every component
```

## Proof

1. Demo app runs on the iPhone Duo simulator in every pose.
2. A production app (Astrya, SwiftUI, iOS 17+) adopts DuoKit: `.duoReady()` at
   the root and `BrutTabBar` moved into `DuoTabShell`. Done on a branch,
   never pushed without the owner's go-ahead.

## Decisions open to change

- Name "DuoKit", MIT, iOS 17 minimum, Swift tools 6.0.
- Posture detection: no hinge data → size classes only (compact/expanded).
- Even-column rounding only applies when the container is regular width.
