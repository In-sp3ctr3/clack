# Contributing to Clack

Thanks for helping make Clack better. This project is intentionally small, but the workflow should still feel professional and predictable.

## Ground Rules

- Be kind and direct.
- Keep changes focused.
- Prefer small pull requests over broad rewrites.
- Include screenshots or recordings for UI changes once the app exists.
- Do not include real secrets, passwords, tokens, private clipboard data, or personal user content in issues, tests, fixtures, or screenshots.

## Local Development

Run the core checks:

```sh
swift run ClackCoreChecks
```

Build a local app bundle:

```sh
./scripts/build_app.sh
open .build/apple/Clack.app
```

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
4. Keep the diff small enough to review in one sitting.
5. Fill out the pull request template with a short, specific brief.
6. Make sure CI passes.
7. Wait for review before merging unless you are doing an approved maintainer-only housekeeping change.

## PR Size

Default limits:

- No more than 12 changed files.
- No more than 400 changed lines.
- No unrelated cleanup mixed into feature work.
- No drive-by formatting unless the PR is only formatting.

If a PR needs to be larger, explain why in the PR body and ask a maintainer to add `size: approved`.

Good PR shape:

- One behavior change.
- One bug fix.
- One UI slice.
- One documentation update.
- One maintenance task.

Split the rest.

## PR Briefs

Keep the PR body plain and useful. A good brief says:

- what changed,
- why it changed,
- how it was checked,
- anything intentionally left out.

Avoid padded summaries, generic claims, and long checklists that do not add context.

## Commit Style

Use clear, sentence-style commit messages. Each commit should have one reason to exist. Conventional commit prefixes are welcome but not required:

- `feat: add clipboard history storage`
- `fix: avoid saving duplicate clipboard item`
- `docs: explain release process`

Commit guidelines:

- Keep subject lines under 72 characters.
- Prefer 1-5 commits per PR.
- Use the body only when the reason is not obvious from the diff.
- Do not use vague messages like `updates`, `changes`, or `fix stuff`.

## Testing

Run `swift run ClackCoreChecks` before opening a pull request. The repository hygiene workflow also verifies that required project files are present and that merge conflict markers are not committed.

## Security and Privacy

Clipboard tools can expose sensitive data if handled carelessly. Treat privacy bugs as security bugs. See [SECURITY.md](SECURITY.md) for reporting instructions.
