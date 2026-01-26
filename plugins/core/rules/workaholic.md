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

# Frontmatter Requirements

All markdown files under `.workaholic/` require YAML frontmatter with minimum fields:

```yaml
---
author: <git user.email>
created_at: <ISO 8601 timestamp>
modified_at: <ISO 8601 timestamp>
---
```

**When creating or editing files:**
- Use `git config user.email` for `author` field
- Use `date -Iseconds` for timestamps (ISO 8601 datetime with timezone)
- Set `created_at` only on initial creation
- Update `modified_at` on every edit

**Additional fields per subdirectory:**

| Directory       | Additional Fields                                      |
| --------------- | ------------------------------------------------------ |
| `specs/`        | `title`, `description`, `category`, `commit_hash`      |
| `stories/`      | `branch`, `started_at`, `ended_at`, metrics fields     |
| `terminology/`  | `title`, `description`, `category`                     |
| `tickets/`      | See `/ticket` command for full schema                  |

**Exceptions:**
- README files are exempt from the `author` requirement
- Existing files without frontmatter don't need immediate migration
