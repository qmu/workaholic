---
paths:
  - '**/*'
---

# General Rules

- **Never commit without explicit user request** - Only create git commits when executing a command that has commit steps (`/drive`, `/report`)
- **Never use `git -C`** - Run git commands from the working directory, not with `-C` flag
- **Link markdown files when referenced** - When mentioning `.md` files in documentation, use markdown links: `[filename.md](path/to/file.md)` not just backticks. Especially important for stable docs (specs, terms, stories).
