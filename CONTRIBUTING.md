# Contributing to Clack

Thanks for helping make Clack better. This project is intentionally small, but the workflow should still feel professional and predictable.

## Ground Rules

- Be kind and direct.
- Keep changes focused.
- Prefer small pull requests over broad rewrites.
- Include screenshots or recordings for UI changes once the app exists.
- Do not include real secrets, passwords, tokens, private clipboard data, or personal user content in issues, tests, fixtures, or screenshots.

## Development Status

Clack is not implemented yet. Until the first app scaffold lands, contributions should focus on project setup, product direction, docs, and issue triage.

## Branching

The default branch is `main`.

Use short-lived branches for work:

- `feature/<short-name>` for new behavior.
- `fix/<short-name>` for bug fixes.
- `docs/<short-name>` for documentation.
- `chore/<short-name>` for maintenance.

Maintainers may also use `codex/<short-name>` for assisted maintenance work.

## Pull Requests

1. Open an issue first for larger changes.
2. Branch from the latest `main`.
3. Keep the PR scoped to one idea.
4. Fill out the pull request template.
5. Make sure CI passes.
6. Wait for review before merging unless you are doing an approved maintainer-only housekeeping change.

## Commit Style

Use clear, sentence-style commit messages. Conventional commit prefixes are welcome but not required:

- `feat: add clipboard history storage`
- `fix: avoid saving duplicate clipboard item`
- `docs: explain release process`

## Testing

Testing instructions will be added with the app scaffold. Until then, the repository hygiene workflow verifies that required project files are present and that merge conflict markers are not committed.

## Security and Privacy

Clipboard tools can expose sensitive data if handled carelessly. Treat privacy bugs as security bugs. See [SECURITY.md](SECURITY.md) for reporting instructions.
