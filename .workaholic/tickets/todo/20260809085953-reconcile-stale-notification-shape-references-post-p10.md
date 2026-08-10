---
created_at: 2026-08-09T08:59:53+00:00
author: a@qmu.jp
assignees:
depends_on:
mission:
merge_policy:
claim: work-20260810-163619
---

# Reconcile stale notification-shape references left behind by P10

## Overview

While erasing the 🟣 purple-circle shape (this run's own ticket,
`20260809080408-erase-the-purple-circle-notification-format.md`), several files were found still
describing two *other* notification shapes as current that P10 (2026-08-07, per
`workaholic:notify`'s SKILL.md) already retired: the `🟢 Merge Requested` line (retired in favor of
`🛠️ Implemented`) and the `🟠 drive started` line (retired in favor of `🛠️ Implementing`). The 🟣
edit only touched the parts of these lines that named the purple shape; the adjacent 🟢/🟠
references were left as-is, out of that ticket's scope, and are recorded here instead of being
fixed opportunistically.

Affected, as of this writing:

- `plugins/workaholic/skills/drive/SKILL.md` — `(🟢/🚀/🟡/🔴)` in the §6 finish-line parenthetical
  still lists 🟢 as a live finish shape.
- `plugins/workaholic/skills/drive/reference/routing.md` — "one finish line per thread, shape
  following the outcome — 🟢 merge requested, 🚀 merge, …" — same issue.
- `outputs/workflows/skills/drive/SKILL.md` and
  `outputs/workflows/skills/drive/reference/routing.md` — generated mirrors of the above; fix the
  source and rebuild, never hand-edit.
- `CLAUDE.md`'s `/implement` architecture paragraph (the `## Development Workflow` /
  claim-protocol prose naming "the session posts the 🟠 start … the finish's shape following the
  outcome (🟢 merge requested, 🚀 merge, …)") — still describes the pre-P10 shapes.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — the §6 finish-line parenthetical
- `plugins/workaholic/skills/drive/reference/routing.md` — the finish-line enumeration in *The threaded Slack posts are `/implement`'s only*
- `plugins/workaholic/skills/notify/SKILL.md` and `plugins/workaholic/skills/notify/reference/notifications.md` — already reconciled by P10 for the start/finish base shapes; use as the source of truth for correct current wording
- `outputs/workflows/skills/drive/SKILL.md` and `outputs/workflows/skills/drive/reference/routing.md` — generated; fix via `node scripts/build-plugins/build.mjs`, never by hand
- `CLAUDE.md` — the `/implement` claim-protocol paragraph under `## Development Workflow`

## Implementation Steps

1. Re-grep the repository for `🟢 merge requested`, `🟢 Merge Requested`, `🟠 start`, and `🟠 drive started` against current `main`, since more may have landed since this ticket was written.
2. In `drive/SKILL.md` and `drive/reference/routing.md`, replace the stale `🟢`/`🟠` finish/start references with the P10 shapes (`🛠️ Implemented` for the review-stop finish, `🛠️ Implementing` for the start), matching the wording already reconciled in `notify/SKILL.md` and `notify/reference/notifications.md`.
3. Update `CLAUDE.md`'s corresponding paragraph the same way.
4. Regenerate `outputs/workflows` (`node scripts/build-plugins/build.mjs`) and run `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs` / `layout-doctor.sh` per the repository's Local Verification list.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No file under `plugins/workaholic/`, `outputs/`, or `CLAUDE.md` describes `🟢 Merge Requested` or `🟠 drive started` as a shape `/implement` currently posts.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "🟢 [Mm]erge [Rr]equested\|🟠 drive started\|🟠 start" plugins/workaholic/ outputs/ CLAUDE.md` returns no hits describing them as current (historical/decision-log mentions naming them as *retired* are fine).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs && node scripts/test-workflow-scripts.mjs` all clean; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- The grep above is clean and the local verification suite passes before this ticket's PR is opened for review.

## Considerations

- Low severity, cosmetic doc drift — not blocking, hence minted rather than fixed opportunistically inside the 🟣-removal ticket per the drive skill's failure contract ("inside the current ticket's scope → implement it; outside it → write a ticket, continue").
- Found while implementing `20260809080408-erase-the-purple-circle-notification-format.md` (qmu/workaholic#317).
