---
type: Feedback
title: Path-owned legacy todo tickets are surveyed as team-owned by the unattended routine
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-08-14T10:28:45+00:00
author: a@qmu.jp
supersedes: 
---

# Path-owned legacy todo tickets are surveyed as team-owned by the unattended routine

**Observed (2026-08-13 → 08-14, overnight), in a downstream repository whose ticket queue still uses the pre-P2 layout** — `.workaholic/tickets/todo/<user-slug>/*.md`, with no `assignees:` frontmatter. The hourly `[Implement]` routine, running under developer A's identity, claimed, implemented, and merged (via the review→merge-immediately route) about ten PR-units overnight. Most of their tickets were authored by developers B and C and sat under those developers' own `todo/<their-slug>/` directories. Developer A expected the unattended routine to drive only their own lane; instead it silently executed and merged colleagues' work.

**Why it happens (read from the plugin tree at v1.0.176).**

- Since P2 (2026-08-06), ownership is the `assignees:` field alone: `gather/scripts/owners.sh` reads `assignees` (with a legacy singular `assignee` fallback), `author:` is deliberately not ownership, and empty means team-owned — claimable by anyone.
- `drive/scripts/list-todo.sh` deliberately reads both layouts (`-maxdepth 2`), so unmigrated tickets under `todo/<user-slug>/` are surveyed.
- For such a ticket, `owns.sh` finds no field and answers `unowned`, so `plan-units.sh` offers it to every runner. The owner the path used to encode is silently reinterpreted as team-owned — the exact opposite of the `owned_by_other` exclusion the survey promises.
- The living migration that would carry the path into the field, `gather/scripts/migrate-todo-owners.sh`, documents its call sites as "create-ticket's publish step, promote-icebox.sh, and drive's archive.sh" — but in the current tree the only script that actually calls it is `promote-icebox.sh`. A queue that predates P2 therefore never converges: overnight, several tickets moved straight from `todo/<another-user-slug>/…` into `archive/` without ever being stamped.

**Ask.**

1. Close the tolerance gap: until a ticket is migrated, its directory must still count as ownership. Either give the ownership oracle a third resolution tier (a `todo/<user-slug>/` path resolves to that slug when the field is absent) or have the survey exclude such tickets as `owned_by_other` instead of offering them as unowned.
2. Wire `migrate-todo-owners.sh` into the seams its own header already claims — at least `drive/scripts/archive.sh` — so an actively driven queue actually converges.
3. Revisit, or at least document loudly, "empty `assignees` = claimable by anyone" as it applies to the unattended routine: at minimum, the run report and the finish line should state prominently when a claimed unit's tickets were authored by someone other than the runner's identity.

Source: https://github.com/qmu/workaholic/issues/444
