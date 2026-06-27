---
paths:
  - '.workaholic/**/*'
---

# Work Directory Structure

The `.workaholic/` directory has a fixed structure. Only these subdirectories are allowed:

| Directory        | Purpose                                    |
| ---------------- | ------------------------------------------ |
| `concerns/`      | Carry-over concerns/ideas (and `concerns/archive/`) |
| `deployments/`   | Deployment/release procedures and their success-confirmation methods |
| `release-notes/` | Per-branch release notes                   |
| `specs/`         | Current state reference documentation      |
| `stories/`       | Development narratives per branch          |
| `terms/`         | Term definitions                           |
| `tickets/`       | Implementation work queue and archives (`todo/`, `archive/`, `icebox/`, `abandoned/`) |
| `trips/`         | Trip design/decision artifacts per trip    |

This list is the single source of truth in `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` (one directory per line), which `hooks/validate-ticket.sh` reads to enforce the layout on every `Write`/`Edit`. Keep the table and that file in lockstep when amending the structure.

The `tickets/` queue is partitioned per developer: active tickets live under `tickets/todo/<user>/`, where `<user>` is the slug of `git config user.email` (e.g. `a-qmu-jp`). The icebox (`tickets/icebox/`) and archive (`tickets/archive/<branch>/`) stay as-is.

README files at the root level are allowed (`README.md`).

**Guidelines:**
- Never create directories outside the allowed list. Enforcement is **warn by default** (a `Write`/`Edit` into an undesignated `.workaholic/` subdirectory is allowed but flagged on stderr by `validate-ticket.sh`). To make it **blocking** for a repo, set `WORKAHOLIC_STRICT_LAYOUT=1` or commit an empty `.workaholic/.strict-layout` marker. The ticket-shape and ticket-location rules are always blocking, regardless of this toggle.
- If a user requests a new directory, explain the structure and suggest the appropriate existing directory
- Map common requests: "docs" → `specs/`, "archive" → `tickets/archive/`, "changelog" → use ticket frontmatter, "deploy steps" / "release procedure" / "how to verify a deploy" → `deployments/`

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
| `terms/`  | `title`, `description`, `category`                     |
| `tickets/`      | See `/ticket` command for full schema                  |
| `deployments/`  | `title`, `environment`, `confirmation_method` (one of `browser` / `server-batch` / `db-query` / `api-probe` / `other`); optional **non-secret** locators `url` / `endpoint` / `command` |

Each `deployments/<target>.md` file describes one deployment target and MUST carry two body sections:

- `## Procedure` — the deploy/release steps, written at copy-paste-executable granularity (a concrete command, not "deploy it").
- `## Confirmation` — the exact, executable way to confirm the deployment succeeded in production (a URL to open and the signal to look for, a batch command to run on the server, a DB query and its expected result, an API probe, …). This is the method `/ship` requires before it will complete a deployment.

> **Never commit secrets.** `deployments/*.md` is version-controlled. Credentials, tokens, and session cookies are NEVER written here — the locator fields hold only a URL, an endpoint name, or a command *template*. Actual credentials are supplied transiently at ship time.

**Exceptions:**
- README files are exempt from the `author` requirement
- Existing files without frontmatter don't need immediate migration

# Timestamp Field Convention

All timestamp fields MUST:
- Use `_at` suffix (e.g., `created_at`, not `created` or `creation_date`)
- Use ISO 8601 datetime with timezone (e.g., `2026-01-26T14:30:00+09:00`)
- Be generated with `date -Iseconds`

**Standard timestamp fields:**

| Field        | Purpose                              |
| ------------ | ------------------------------------ |
| `created_at` | When the file was created            |
| `modified_at`| When the file was last modified      |
| `started_at` | When work began (stories)            |
| `ended_at`   | When work completed (stories)        |

**Migration:** Files with legacy `last_updated` are updated to `modified_at` when edited.
