# Security Policy

Clack handles clipboard data, so privacy and security issues matter even while the project is small.

## Supported Versions

Clack is currently in alpha. Alpha builds receive best-effort security and privacy fixes, but they are not long-term-supported releases.

| Version | Support |
| --- | --- |
| `0.1.x-alpha` | Best-effort fixes |
| Earlier preliminary builds | Upgrade to the latest alpha before reporting |

## Reporting a Vulnerability

Please do not open a public issue for vulnerabilities or privacy leaks.

Report security issues through GitHub Security Advisories:

https://github.com/In-sp3ctr3/clack/security/advisories/new

If advisories are unavailable, contact the maintainer directly through the GitHub profile.

Please include:

- The Clack version or release asset used.
- Your macOS version.
- Whether the app was installed from GitHub Releases, Homebrew, or a local build.
- A minimal reproduction that avoids real secrets or private clipboard contents.

## What Counts as Security Sensitive

- Clipboard contents leaving the device unexpectedly.
- Clipboard history being written somewhere undocumented.
- Sensitive entries being exposed in logs, crash reports, screenshots, telemetry, or tests.
- Incorrect handling of passwords, tokens, keys, or private user data.
- Any permission behavior that surprises the user.

## Disclosure Expectations

The maintainer will acknowledge reports as soon as possible, investigate in good faith, and coordinate a fix before public disclosure when a real vulnerability is confirmed.

## Privacy-Sensitive Logs and Artifacts

Do not attach raw `history.json`, crash logs, screenshots, or recordings if they contain private clipboard content. Redact secrets and replace sensitive values with safe examples before sharing.
