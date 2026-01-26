---
paths:
  - '.workaholic/**/*'
---

# Work Directory Structure

The `.workaholic/` directory has a fixed structure. Only these subdirectories are allowed:

| Directory       | Purpose                                    |
| --------------- | ------------------------------------------ |
| `specs/`        | Current state reference documentation      |
| `stories/`      | Development narratives per branch          |
| `terminology/`  | Term definitions                           |
| `tickets/`      | Implementation work queue and archives     |

README files at the root level are allowed (`README.md`, `README_ja.md`, etc.).

**Guidelines:**
- Never create directories outside the allowed list
- If a user requests a new directory, explain the structure and suggest the appropriate existing directory
- Map common requests: "docs" → `specs/`, "archive" → `tickets/archive/`, "changelog" → use ticket frontmatter
