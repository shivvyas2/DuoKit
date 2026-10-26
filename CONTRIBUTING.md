# Contributing to DuoKit

Thanks for looking. DuoKit is small on purpose: it encodes Apple's iPhone Duo guidance as components, and every rule below keeps it that way.

## Before you start

- **Open an issue first for anything bigger than a fix.** Say what you want to change and why. Features start as a short design note in `docs/superpowers/specs/`, and it is much cheaper to agree on the note than on a finished pull request.
- **Point at the guidance.** A new behaviour should cite the Human Interface Guidelines, an Apple Tech Talk, or an SDK symbol. DuoKit follows Apple; it does not invent a design language.

## How the repo works

**One branch per change.** Never commit to `main`. Branch from it, open a pull request, and let CI run.

**Conventional commits.** `feat(grid): ...`, `fix(tabs): ...`, `docs(readme): ...`, `test(core): ...`, `refactor(...)`, `chore(...)`, `ci: ...`. The subject is a sentence in plain words about what changed for someone using DuoKit.

**No em dashes.** In code comments, commit messages, docs, and strings. Use a comma, a period, or a colon.

**Decisions go in the core.** If a component decides something (how many columns, where a bar goes, how far to move), that decision is a pure function in `DuoKitCore` with a test beside it. `DuoKit` reads the environment and applies it. This keeps `swift test` fast and runnable on any Mac.

**Use Apple's APIs where they exist.** On iOS 27.1, prefer `ArrangementView`, `ReservedRegion`, `onHingeChange`, and `toolbarVerticalEdge` over reimplementing them. Fallbacks are for older iOS only.

**Never worse on a regular iPhone.** Every component must look and behave like ordinary iPhone UI when there is no hinge.

## Tests

Run these before you push. They are what CI runs.

```sh
swift test
xcodebuild -scheme DuoKit -destination 'generic/platform=iOS Simulator' build
swift run duo-lint Sources Demo
```

Write the failing test first when you can. For anything visual, run the demo with `-duoSimulate closed|open|book|tent` and attach screenshots to the pull request.

## Pull requests

- One change per pull request.
- Fill in the template: what changed, why, and how you verified it.
- Add a line to `CHANGELOG.md` under Unreleased.

## Code of conduct

Be kind and be direct. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
