---
paths:
  - '.workaholic/**/*'
---

# Work Directory Structure

The `.workaholic/` directory has a fixed structure. Only these subdirectories are allowed:

| Directory        | Purpose                                    |
| ---------------- | ------------------------------------------ |
| `deployments/`   | Deployment/release procedures and their success-confirmation methods |
| `feedbacks/`     | The inbound feedback stream — one immutable record per entry (`kind`: insight/instruction/concern/material/answer) |
| `guides/`        | User documentation (project-local docs area) |
| `missions/`      | Optional, epic-equivalent groupings of **two or more** tickets — the ticket floor; a bare direction is a feedback record and a single unit of work is a ticket (`active/`, `archive/`) |
| `policies/`      | Project-local policy documentation         |
| `release-notes/` | Per-branch release notes — one per shipped unit branch, written pre-merge; each also carries the prospective `## Deployment Plan` and the append-only `## Deployment Verification` |
| `releases/`      | Per-`release/*`-branch ship records — which base commits a release carried, when it was cut, when it was confirmed or failed. **Not** `release-notes/`: that is one note per shipped unit, this is one record per production release |
| `specs/`         | Current state reference documentation      |
| `stories/`       | Development narratives per branch          |
| `terms/`         | Term definitions                           |
| `tickets/`       | Implementation work queue and archives (`todo/`, `archive/`, `icebox/`, `abandoned/`) |
| `trips/`         | **Legacy, read-only history** — design/decision artifacts from the retired trip workflow; no writer since 2026-07-28 |

This list is the single source of truth in `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` (one directory per line), which `hooks/validate-ticket.sh` reads to enforce the layout on every `Write`/`Edit`. Keep the table and that file in lockstep when amending the structure — introducing a new top-level artifact directory is a deliberate amendment that must update **both** in the same change (see CLAUDE.md's closed-layout / lockstep-registration policy). Most entries are plugin-generated; `guides/` and `policies/` are conventional project-local documentation areas.

The `tickets/` queue is **flat**: active tickets live directly under `tickets/todo/`, and **who a ticket belongs to is its `assignees` frontmatter field**, not its location (P2, 2026-08-06). `assignees` is plural (a ticket can be co-owned) and **empty means team-owned** — claimable by anyone — exactly as on a mission; every consumer reads it through the one oracle, `gather/scripts/owners.sh` (and `owns.sh` for the mine/unowned/other/unresolved verdict). Reassignment is therefore a frontmatter edit rather than a file move. The queue was partitioned per developer as `tickets/todo/<user>/` until that change; readers still tolerate that shape and the living migration `gather/scripts/migrate-todo-owners.sh` converges it at the write seams, so a checkout mid-migration is never blocked. The icebox (`tickets/icebox/`) and archive (`tickets/archive/<branch>/`) are unchanged.

The `missions/` tree mirrors that working-vs-archived split, keyed off the mission's single `status` axis: an **in-flight** mission (`active`) lives at `missions/active/<slug>/mission.md` and an **ended** one (`achieved`, `abandoned` or `carried`) at `missions/archive/<slug>/mission.md`. The mission skill's scripts own both the placement and the status — `close.sh` is the only flip left (to an end state) and performs the move, and living migrations relocate any legacy flat `missions/<slug>/` dir and fold the retired `status: draft`/`status: approved` spellings (plus the long-retired `drive_authorized` stamp) onto `active` on the next mission-script touch. Never `mv` a mission dir or hand-edit its `status:` field.

**A mission is created with two or more tickets, or it is not a mission** (`workaholic:mission`, *Granularity → The ticket floor*). The count is the tickets naming it in their `mission:` relation, judged by `mission/scripts/check-floor.sh` at the seam that publishes the mission and its ticket set together — never at the write of `mission.md`, which happens before any ticket exists. A refusal names what to write instead: a feedback record for a bare direction, a plain ticket for a single unit of work. The floor is a rule about **creation**, so it is audited over `missions/active/` only; the single pre-rule one-ticket mission in `missions/archive/` is history and stays untouched.

Every mission write — creation, replan, and close alike — is **published to `main`** through a publish tree (`workaholic:branching`'s *The Publish Tree*; decision J1). Creation makes **no worktree and no branch**: a worktree is claim-born and ship-torn, so `.worktrees/<slug>` exists only while a runner holds the mission as a PR-unit. A mission living on an unmerged branch is a mission `/drive` cannot survey, which is the failure this rule exists to prevent.

The `releases/` tree is **written by the promotion pipeline, never by hand**: `ship/scripts/record-release-cut.sh` creates a record when a `release/*` branch is cut, and `ship/scripts/confirm-release.sh` appends each confirmation attempt to it. Records are **append-only in substance** — a failed confirmation is recorded, not erased, and the next attempt cuts a fresh release branch with its own record, because a release branch's identity is "the commits confirmed, or not, at that moment". Every field is derived from git at cut and confirm time (see decision L3), so the record answers "what did this deploy carry, and when" from the filesystem with `grep` and `git log` alone.

Root-level files allowed at the `.workaholic/` root: `README.md`; `index.md` — the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) bundle entry point, regenerated together with each area's `index.md` by `okf/scripts/refresh-index.sh` whenever a workflow commits knowledge documents; and the release-scan config files `scan-allow` and `leak-denylist` that `release-scan/scripts/scan-branch-safety.sh` reads. A fourth, `proposal-cursor`, was allowed until 2026-08-04: it was the proposal batch's processed-commit cursor (git-ignored, never committed), and it left the list with the merged-main window it served. Nothing writes or folds it any more, so a surviving file in an old checkout is reported by `layout-doctor.sh` for its owner to delete (`docs/proposal-loop-runbook.md` §7).

**Guidelines:**
- Never create directories outside the allowed list. Enforcement is **blocking and unconditional** — a `Write`/`Edit` into an undesignated `.workaholic/` subdirectory is denied (exit 2) by `validate-ticket.sh` whenever the plugin is installed, with no env-var or marker opt-out (an injectable opt-out fails open exactly when it is not set). The ticket-shape and ticket-location rules are always blocking too. This is why registering a new artifact directory in both sources of truth *before* writing to it is mandatory: a stale allowlist hard-blocks a legitimate write.
- To audit an existing tree for drift without changing anything, run `bash ${CLAUDE_PLUGIN_ROOT}/hooks/layout-doctor.sh [path]` — it reports undesignated directories and misplaced ticket states (with suggested `git mv`s) against this same allowlist, and never mutates the tree. `[path]` defaults to the current repo; pass a repo root to audit another.
- If a user requests a new directory, explain the structure and suggest the appropriate existing directory
- Map common requests: "docs" → `specs/`, "archive" → `tickets/archive/`, "changelog" → use ticket frontmatter, "deploy steps" / "release procedure" / "how to verify a deploy" → `deployments/`

# Frontmatter Requirements

Every knowledge document under `.workaholic/` carries a non-empty **`type:`** (the OKF
conformance floor, enforced on new writes by `validate-story.sh` / `validate-feedback.sh` /
`validate-mission.sh`); **tickets are the exception** — the queue is not index-managed and a
ticket carries no `type:`. All markdown files under `.workaholic/` also require YAML
frontmatter with minimum fields:

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
| `feedbacks/`    | `type: Feedback`, `title`, `kind`, `source`, optional `supersedes` |
| `missions/`     | `type: Mission`, `title`, `slug`, `status`, `merge_policy`, `assignees` |
| `release-notes/`| `type: Release Note`; `targets` (the deploy-target slugs the note plans for) is **stamped by `draft-deploy-plan.sh`**, never hand-written |
| `releases/`     | `type: Release`, `release_branch`, `status` (`staging` / `confirmed` / `failed`), `base`, `cut_at`, `cut_sha`, `since_ref`, `since_reason`, `carried_count`; filled at confirmation: `confirmed_at`, `confirmation_method`, `confirmation_status`, `tag` |
| `specs/`        | `title`, `description`, `category`, `commit_hash`      |
| `stories/`      | `type: Story`, `branch`, `started_at`, `ended_at`, metrics fields |
| `terms/`  | `title`, `description`, `category`                     |
| `tickets/`      | See `/ticket` command for full schema                  |
| `deployments/`  | `title`, `environment`, `confirmation_method` (one of `browser` / `server-batch` / `db-query` / `api-probe` / `other`); optional **non-secret** locators `url` / `endpoint` / `command`; optional `deploy_model` (`deploy-on-merge` / `deploy-from-branch`, otherwise read from the body's own wording) and `paths` (the subtree this target ships — absent means the plan attributes it the whole unreleased range and says so) |

Each `deployments/<target>.md` file describes one deployment target and MUST carry two body sections:

- `## Procedure` — the deploy/release steps, written at copy-paste-executable granularity (a concrete command, not "deploy it").
- `## Confirmation` — the exact, executable way to confirm the deployment succeeded in production (a URL to open and the signal to look for, a batch command to run on the server, a DB query and its expected result, an API probe, …). This is the method `/ship` requires before it will complete a deployment — and the verification its drafted deployment plan names for this target.

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
