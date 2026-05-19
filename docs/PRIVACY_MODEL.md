# Privacy Model

Clack's core job is to remember clipboard contents. That makes privacy part of the product, not an afterthought.

## Default Position

- Clipboard history is local-first.
- Clipboard contents should not be transmitted to a server by default.
- Logs should not contain clipboard contents.
- Tests and fixtures should not contain real user clipboard data.
- Users should be able to clear history.

## Current Storage

Clack stores clipboard history in the user's Application Support directory:

```text
~/Library/Application Support/Clack/history.json
```

The file is local JSON so the early app is easy to inspect and debug. It can include copied text, copied file paths, image data, pasteboard type names, and best-effort source app metadata when those items are captured. Storage hardening, such as encryption or automatic sensitive-content filtering, should be considered before a stable release.

## Sensitive Data

Users often copy passwords, tokens, private messages, addresses, financial data, and work material. Clack should assume clipboard data may be sensitive even when it looks ordinary.

## Metadata

Clack may store metadata such as first copied time, last copied time, copy count, pinned state, pasteboard types, best-effort source app, bundle identifier, and process identifier. Exact source attribution is limited by macOS APIs and privacy constraints; Clack uses the frontmost application reported by macOS at the time the pasteboard change is observed.

## Future Review Areas

- Storage encryption.
- Ignored apps, pasteboard types, and regular expression rules.
- Automatic exclusion of likely secrets.
- Configurable retention limits.
- Crash reporting policy.
- Optional diagnostics with explicit consent.
