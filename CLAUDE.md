# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.
## Build & Test

_Add your build and test commands here_

```bash
# Example:
# npm install
# npm test
```

## Architecture Overview

_Add a brief overview of your project architecture_

## Conventions & Patterns

### Authoring posts

- **Frontmatter `date` is authoritative.** Hugo uses it for ordering and for the permalink (`/:year/:month/:day/:slug/` per `hugo.toml`). When creating a new post by copying an old one, always update `title`, `date`, and `lastmod` — the filename's date prefix is purely for humans and is ignored by the build.
- **Image size limit: 1024 KB** (enforced by the `check-added-large-files` pre-commit hook). Prefer WebP for screenshots/photos — `convert input.png -quality 85 -define webp:method=6 output.webp` typically gets a 1–2 MB PNG well under the limit. Do not bypass with `--no-verify`.
