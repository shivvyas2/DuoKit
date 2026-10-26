## What changed

<!-- One or two sentences in plain words. What does someone using DuoKit get? -->

## Why

<!-- Link the issue, the design note in docs/superpowers/specs/, or the Apple guidance this follows. -->

## How I verified it

- [ ] `swift test`
- [ ] `xcodebuild -scheme DuoKit -destination 'generic/platform=iOS Simulator' build`
- [ ] `swift run duo-lint Sources Demo`
- [ ] Ran the demo in the postures this touches (`-duoSimulate closed|open|book|tent`, or the iPhone Duo simulator)

<!-- Screenshots for anything visual: folded and open at least. -->

## Checklist

- [ ] One change per pull request
- [ ] Conventional commit messages, no em dashes
- [ ] Decisions live in DuoKitCore with a test
- [ ] Nothing looks worse on a regular iPhone
- [ ] CHANGELOG.md updated under Unreleased
