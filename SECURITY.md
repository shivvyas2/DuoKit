# Security

DuoKit is a UI library and a linter. It makes no network calls and stores nothing. Still, if you find a vulnerability, please report it privately.

## Reporting

Use GitHub's private vulnerability reporting: open the **Security** tab of this repository and choose **Report a vulnerability**. Do not open a public issue for security problems.

Include what you found and how to reproduce it. You will get an acknowledgement within a few days.

## What counts

- `duo-lint` reading, writing, or executing anything outside the paths it is given.
- Secrets in the repo or in release artifacts.

## Supported versions

Only the latest release receives fixes.
