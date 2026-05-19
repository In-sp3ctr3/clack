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

The file is local JSON so the early app is easy to inspect and debug. It can include copied text, rich text representations, copied file paths, image data, pasteboard type names, and source metadata when those items are captured. Storage hardening, such as encryption or automatic sensitive-content filtering, should be considered before a stable release.

## Sensitive Data

Users often copy passwords, tokens, private messages, addresses, financial data, and work material. Clack should assume clipboard data may be sensitive even when it looks ordinary.

## Metadata

Clack may store metadata such as first copied time, last copied time, copy count, pinned state, pasteboard types, source app, bundle identifier, process identifier, source confidence, and source observation time.

Source confidence is explicit because macOS does not expose guaranteed origin metadata for every pasteboard change. Clack records whether the label came from the frontmost application at the time of the pasteboard change, a recently active app fallback, or an unknown source. Universal Clipboard participates through the general pasteboard, but Apple does not provide a public macOS API for its remote-device origin.

## Future Review Areas

- Storage encryption.
- Ignored apps, pasteboard types, and regular expression rules.
- Automatic exclusion of likely secrets.
- Configurable retention limits.
- Crash reporting policy.
- Optional diagnostics with explicit consent.
