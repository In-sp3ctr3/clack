# Clack Website

This folder contains the Vercel-ready download page for Clack.

The site is intentionally static for now. GitHub Releases remain the source of truth for downloadable app artifacts; the website should point people to the latest release or Homebrew install command.

## Local Build

```sh
npm run build
```

The build copies `index.html`, `styles.css`, and `assets/` into `dist/`.

## Deployment

The repository includes `vercel.json` at the root. Vercel can build this folder as a static site using the `site/package.json` build script.

## Content Rules

- Keep install instructions aligned with `README.md`.
- Do not promise signed or notarized builds until release artifacts are actually signed and notarized.
- Link to GitHub Releases for version history and checksums.
