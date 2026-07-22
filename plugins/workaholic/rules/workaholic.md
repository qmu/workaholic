---
paths:
  - '.workaholic/**/*'
---

# Work Directory Structure

The `.workaholic/` directory has a fixed structure. Only these subdirectories are allowed:

| Directory        | Purpose                                    |
| ---------------- | ------------------------------------------ |
| `concerns/`      | Deferred concerns/ideas (and `concerns/archive/`) |
| `deployments/`   | Deployment/release procedures and their success-confirmation methods |
| `guides/`        | User documentation (project-local docs area) |
| `missions/`      | Long-lived goals spanning many tickets (`active/`, `archive/`) |
| `policies/`      | Project-local policy documentation         |
| `release-notes/` | Per-branch release notes                   |
| `specs/`         | Current state reference documentation      |
| `stories/`       | Development narratives per branch          |
| `strategies/`    | Long-lived direction above missions (`active/`, `archive/`) |
| `terms/`         | Term definitions                           |
| `tickets/`       | Implementation work queue and archives (`todo/`, `archive/`, `icebox/`, `abandoned/`) |
| `trips/`         | Trip design/decision artifacts per trip    |

This list is the single source of truth in `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` (one directory per line), which `hooks/validate-ticket.sh` reads to enforce the layout on every `Write`/`Edit`. Keep the table and that file in lockstep when amending the structure — introducing a new top-level artifact directory is a deliberate amendment that must update **both** in the same change (see CLAUDE.md's closed-layout / lockstep-registration policy). Most entries are plugin-generated; `guides/` and `policies/` are conventional project-local documentation areas.

The `tickets/` queue is partitioned per developer: active tickets live under `tickets/todo/<user>/`, where `<user>` is the slug of `git config user.email` (e.g. `a-qmu-jp`). The icebox (`tickets/icebox/`) and archive (`tickets/archive/<branch>/`) stay as-is.

The `missions/` tree mirrors that working-vs-archived split: an in-progress mission lives at `missions/active/<slug>/mission.md` and an ended one (status `achieved` or `abandoned`) at `missions/archive/<slug>/mission.md`. The mission skill's scripts own the placement — `close.sh` performs the move, and a living migration relocates any legacy flat `missions/<slug>/` dir by its `status` on the next mission-script touch. Never `mv` a mission dir or hand-edit its `status:` field.

Root-level files allowed at the `.workaholic/` root: `README.md`; `index.md` — the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) bundle entry point, regenerated together with each area's `index.md` by `okf/scripts/refresh-index.sh` whenever a workflow commits knowledge documents; and the release-scan config files `scan-allow` and `leak-denylist` that `release-scan/scripts/scan-branch-safety.sh` reads.

**Guidelines:**
- Never create directories outside the allowed list. Enforcement is **blocking and unconditional** — a `Write`/`Edit` into an undesignated `.workaholic/` subdirectory is denied (exit 2) by `validate-ticket.sh` whenever the plugin is installed, with no env-var or marker opt-out (an injectable opt-out fails open exactly when it is not set). The ticket-shape and ticket-location rules are always blocking too. This is why registering a new artifact directory in both sources of truth *before* writing to it is mandatory: a stale allowlist hard-blocks a legitimate write.
- To audit an existing tree for drift without changing anything, run `bash ${CLAUDE_PLUGIN_ROOT}/hooks/layout-doctor.sh [path]` — it reports undesignated directories and misplaced ticket states (with suggested `git mv`s) against this same allowlist, and never mutates the tree. `[path]` defaults to the current repo; pass a repo root to audit another.
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
