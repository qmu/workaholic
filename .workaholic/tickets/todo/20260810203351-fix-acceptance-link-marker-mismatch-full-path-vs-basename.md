---
created_at: 2026-08-10T20:33:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: configure-routines-automatically-via-remotetrigger
merge_policy:
---

# Fix acceptance-link marker mismatch: full path vs. basename

## Overview

Driving ticket `20260810130657` under the `configure-routines-automatically-via-remotetrigger` mission, `archive.sh` reported `tick-acceptance: no_unchecked_match` even though the mission's `## Acceptance` carries an unchecked item that names exactly that ticket. The cause: the mission's acceptance items are linked with the **full relative path** as the marker — `(#.workaholic/tickets/todo/20260810130657-fix-the-routine-templates-unrealizable-30-minute-schedule.md)` — but `archive.sh` passes `tick-acceptance.sh` the ticket's **basename only** (`TICKET_FILENAME=$(basename "$TICKET")`), and `tick-acceptance.sh`'s marker is built as `"(#" artifact ")"` from that basename. `index(text[i], marker)` therefore never finds the basename-only marker as a substring of the full-path marker actually written, so every ticket in this mission will report `no_unchecked_match` on archive and the mission's checklist can never progress past `0/3` even once every member ticket lands.

`link-acceptance.sh`'s own header states the marker is `"(#<artifact-filename>)"` (a filename, not a path), so this mission's `## Acceptance` items were stamped inconsistently with that contract at creation time — this is a marker-writing defect (whatever wrote `mission.md`'s Acceptance links), not a `tick-acceptance.sh` defect; `tick-acceptance.sh` and `archive.sh` are behaving exactly as documented.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/mission/scripts/link-acceptance.sh` — the sole writer of the `(#<artifact-filename>)` marker; audit every caller for whether it passes a bare filename or a path
- `plugins/workaholic/skills/mission/scripts/tick-acceptance.sh` — the reader; matches on `(#<basename>)` as passed by `archive.sh`
- `plugins/workaholic/skills/drive/scripts/archive.sh` — passes `basename "$TICKET"` to `tick-acceptance.sh`
- `.workaholic/missions/active/configure-routines-automatically-via-remotetrigger/mission.md` — the live instance carrying the mismatched full-path markers (fix by hand once the root cause is found, or via a one-time repair script if other missions carry the same defect)
- Whatever calls `link-acceptance.sh` at mission-creation / `/propose` time (the Creation Interrogation seam) — find where it passes a path instead of a basename

## Implementation Steps

1. Grep every caller of `link-acceptance.sh` and determine which one(s) pass a full relative path (`.workaholic/tickets/todo/<file>.md`) instead of a bare filename as the third argument.
2. Fix the caller(s) to pass `basename` of the artifact path, matching `link-acceptance.sh`'s own documented contract and `tick-acceptance.sh`'s expectation.
3. Repair this mission's already-mismatched markers (and audit other active missions for the same defect) so their unchecked items become tickable again — either a one-off hand edit or a small idempotent repair script, whichever the codebase's conventions favor for a live-data fix.
4. Add regression coverage (or extend `test-workflow-scripts.mjs`) asserting `link-acceptance.sh` writes and `tick-acceptance.sh` reads the same marker shape end-to-end.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A ticket archived under a mission whose acceptance item was linked via `link-acceptance.sh` ticks that item (`tick-acceptance.sh` returns `ticked: true`), not `no_unchecked_match`.
- This mission's remaining two acceptance items tick correctly once their tickets land, without a repeat of this defect.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, extended to cover the link-then-tick round trip.
- Manual: archive one of this mission's own remaining tickets and confirm its acceptance box flips.

**Gate** — what must pass before approval:

- No other active mission is left with the same mismatched marker shape (or the ones that are get a follow-up ticket, not silent omission).

## Considerations

Discovered mid-drive while archiving ticket `20260810130657`; scoped narrowly to the marker-format mismatch. Does not block the mission's own remaining tickets from being *driven* — only from having their acceptance box auto-ticked — so the mission continues under `configure-routines-automatically-via-remotetrigger` while this ticket tracks the repair separately.
