# Privacy Model

Clack's core job is to remember clipboard contents. That makes privacy part of the product, not an afterthought.

## Default Position

- Clipboard history is local-first.
- Clipboard contents should not be transmitted to a server by default.
- Logs should not contain clipboard contents.
- Tests and fixtures should not contain real user clipboard data.
- Users should be able to clear history.

## Sensitive Data

Users often copy passwords, tokens, private messages, addresses, financial data, and work material. Clack should assume clipboard data may be sensitive even when it looks ordinary.

## Metadata

Clack may store metadata such as first copied time, last copied time, copy count, pinned state, and best-effort source app. Exact source attribution is limited by macOS APIs and privacy constraints.

## Future Review Areas

- Storage encryption.
- Ignored apps.
- Automatic exclusion of likely secrets.
- Configurable retention limits.
- Crash reporting policy.
- Optional diagnostics with explicit consent.
