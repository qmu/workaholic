---
created_at: 2026-07-13T20:34:44+09:00
author: a@qmu.jp
type: refactoring
layer: [Infrastructure]
effort: 2h
commit_hash: 7fe1afe
category: Changed
depends_on:
mission:
---

# Give deferred concerns a stable identity and update them in place

## Overview

Deferred concerns accumulate without bound. A concern that stays
`still_active` is re-written into the next story's section 6 with a
`(carried from PR #N)` prefix, then re-extracted on `/ship` as a **new**
file with a new `<pr>-` prefix — so one concern becomes
`59-carried-from-58-carried-from...` chains, and the set only grows. A
recent triage found 65 concern files collapse to ~32 real concerns: a 2×
inflation that is pure re-cloning. The developer directive: **concerns
should be updated, not appended — old ones must not just get older;
always keep a fresh set.**

The root cause is that extraction is create-only and keyed on the PR that
surfaced the concern, not on the concern itself. This ticket gives each
concern a **stable identity** and turns extraction into
**update-or-create**: a still-active concern is refreshed in its existing
file, never cloned. This is the freshness engine the triage step
(companion ticket) builds on, and it is independently valuable — it stops
the accumulation at the source.

## Key Files

- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` —
  parses a shipped story's section 6 and writes one file per concern;
  today create-only, keyed on PR number. Becomes update-or-create keyed on
  concern identity.
- `plugins/workaholic/skills/report/scripts/list-active-deferred-concerns.sh`,
  `apply-deferred-concern-verdicts.sh` — the report-side lifecycle
  (list/judge/resolve); must read/write the new identity fields.
- `plugins/workaholic/skills/report/SKILL.md`,
  `plugins/workaholic/skills/review-sections/SKILL.md` — own the
  `(carried from PR #N)` re-emission; stop re-cloning still-active
  concerns into a fresh section-6 block that gets re-extracted.
- `plugins/workaholic/skills/ship/SKILL.md` — documents extraction.
- `CLAUDE.md` — the `.workaholic/` OKF paragraph lists the `Concern`
  frontmatter; add the new identity fields.
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests.

## Implementation Steps

1. **Define concern identity** in the `Concern` frontmatter (keep
   `type: Concern`, the OKF floor): add `concern_id` (a stable kebab slug
   derived from the canonical title with any leading `(carried from …)`
   prefix stripped), `first_seen` (ISO date of first extraction) and
   `last_seen` (ISO date, bumped on every re-sighting). `origin_pr` /
   `origin_commit` stay pinned to the first sighting; the numeric `<pr>-`
   filename prefix is dropped in favor of `<concern_id>.md`.
2. **Rework `extract-deferred-concerns.sh` into update-or-create**: for
   each section-6 concern compute its `concern_id`; if an **active** file
   with that id exists, update it in place (bump `last_seen`; refresh
   `severity` / description / how-to-fix if they changed; keep
   `first_seen` and origin), writing **no** new file and appending **no**
   `carried-from` lineage. Only a genuinely new id creates a file. Keep
   the idempotency contract of the mission mutators as the model.
3. **Stop the re-cloning in report/review-sections**: a `still_active`
   concern is no longer re-emitted as a new `(carried from PR #N)`
   section-6 block. Reference the carried set compactly in the PR body
   (id + count + one line) so visibility is preserved without minting a
   new file each cycle.
4. **Living migration** (idempotent, best-effort, scoped strictly to
   `.workaholic/concerns/`): collapse each existing `carried-from` chain
   into one file per `concern_id` — earliest `first_seen`, latest
   `last_seen`, most-severe `severity` — archiving the redundant clones.
   A failure must never block the calling seam.
5. **Rebuild `outputs/`** (`report` and `ship` are in the built
   workflows closure) and **update docs** (`report`/`ship` SKILL.md,
   `CLAUDE.md` OKF paragraph) in the same change.

## Quality Gate

Approval in `/drive` requires ALL of the following, demonstrated
objectively (hermetic tests in `scripts/test-workflow-scripts.mjs`, in a
throwaway repo):

- **No re-clone:** extracting the same `still_active` concern twice yields
  **exactly one** file, with `last_seen` bumped and `first_seen`
  unchanged — the second extraction creates **zero** new files.
- **Migration collapses chains:** a fixture of a 3-file `carried-from`
  chain migrates to **one** file carrying the earliest `first_seen`, the
  latest `last_seen`, and the most-severe `severity`; the two redundant
  clones are archived.
- **New concerns still land:** a genuinely new concern (unseen
  `concern_id`) still creates its file.
- **Count stays flat on the real backlog:** running `/report` twice over
  this repo's concern set does not increase the file count in
  `.workaholic/concerns/`.
- **Repo gates green:** `node scripts/build-plugins/build.mjs` leaves no
  `outputs/` diff, `verify.mjs` and `validate-metadata.mjs` pass, the full
  `test-workflow-scripts.mjs` suite passes, and `hooks/posix-lint.sh`
  reports conforming.

## Considerations

- **POSIX sh only** (`#!/bin/sh -eu`) — the plugin runs on Alpine where
  `/bin/sh` is not bash; extract all logic to bundled scripts, no inline
  conditionals in markdown (`rules/shell.md`).
- **Rebuild `outputs/` in lockstep** — `extract-deferred-concerns.sh` and
  the report scripts are in the `report`/`ship` built closure; a source
  edit without a rebuild leaves the public copy stale (a recurring
  concern). `hooks/` changes, if any, need no rebuild.
- **Idempotency** — the update-or-create and the migration must be safe to
  re-run (retry, re-report), never double-applying, mirroring the mission
  skill's shared mutators.
- **Forward-safety of the migration** — an existing concern already flags
  that automatic file migration departs from the forward-only stance;
  scope it strictly to concern files holding a concern body, document the
  scoping, and be ready to add a `--skip-migration` escape.
- **Keep `type: Concern`** on every file so the OKF bundle stays
  conformant; `refresh-index.sh` must still resolve the tree.

## Related History

The re-cloning mechanism is the `(carried from PR #N)` prepend documented
in `report`/`review-sections`/`carry`. The idempotent, single-writer
mutator pattern to imitate is the mission skill's `append-changelog.sh` /
`tick-acceptance.sh`. The migration-scoping precedent (and its recorded
caution) is the mission living-layout migration in `mission/lib/resolve.sh`.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: `extract-deferred-concerns.sh` already carried a filename-based
  `canon()` dedup (added PR #82) that *skipped* re-clones but never updated them
  and left the historical carried-from files intact.
  **Context**: The accumulation was two problems, not one — a create-only
  extractor AND a pile of legacy clones. The fix needed both an update-in-place
  engine (frontmatter `concern_id`, not filename-based) and a collapsing
  migration; either alone would have left the corpus growing or stale.
- **Insight**: `extracted` in the output JSON is deliberately kept as the
  *created* count (new files), with `updated` added alongside.
  **Context**: The existing smoke test asserts `extracted == 0` on a same-concern
  re-run as the no-clone signal; defining `extracted` as created preserves that
  contract and makes "no new file" the machine-checkable freshness invariant.
- **Insight**: the living migration is wired into `extract` and `list-active`
  (the write and read entry points) but deliberately NOT into `apply-verdicts`.
  **Context**: `apply` consumes paths that `list-active` already migrated;
  migrating again would rename files out from under those paths. Entry-point-only
  migration keeps the tree fresh without path races.
- **Scope note**: the ticket's step-3 "reference carried concerns compactly in
  the PR body" is delivered as a *guideline* in `review-sections` (summarize
  low-severity carried concerns at scale) rather than a hard behavior change,
  because update-in-place already kills the accumulation at the engine level and
  the PR-body curation is where the companion triage ticket (#2) operates.
