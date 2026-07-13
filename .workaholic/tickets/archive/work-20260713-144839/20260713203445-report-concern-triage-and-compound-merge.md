---
created_at: 2026-07-13T20:34:45+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 4h
commit_hash: 319a185
category: Added
depends_on: 20260713203444-concern-identity-update-in-place.md
mission:
---

# Add a concern triage step to /report with judge-proposed compound merges

## Overview

Once concerns stop cloning (companion ticket), the set still needs a way
to stay *curated*: when there are many concerns, or when two individually
minor concerns combine into a bigger risk (A + B = a security risk), the
developer should be able to **triage** — merge duplicates into one fresh
concern, combine related ones into a compound with an escalated severity,
close the won't-fix ones, or keep the rest. The developer directive: let
the user triage when concerns are a lot or a combined issue is found, so
the set is always fresh rather than an ever-older pile.

This adds a triage decision point **inside `/report`** (reusing the pass
that already judges every concern): when the active count crosses a
threshold **or** the judge proposes a compound, `/report` presents the
developer a triage choice before writing the story, and applies the
decisions through idempotent mutators. Compound detection is
**judge-proposes, user-decides**: the judge surfaces candidate A+B
combinations with a suggested severity; the developer confirms or edits,
and the merged compound supersedes its parts.

## Key Files

- `plugins/workaholic/commands/report.md` — issues the triage
  `AskUserQuestion` (all user interaction stays at the command / main-agent
  level; one-level fan-out).
- `plugins/workaholic/skills/report/SKILL.md` — the Judge Deferred
  Concerns pass gains a `compounds: [...]` proposal; the Run Workflow gains
  the triage step (trigger → present → apply) before Write Story.
- `plugins/workaholic/skills/report/scripts/` (or a shared concern helper
  dir) — new idempotent mutators: `merge-concerns.sh`,
  `close-concern.sh`; both write `superseded_by` / `status` and archive.
- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh`,
  `apply-deferred-concern-verdicts.sh` — must honor `superseded_by` /
  closed status so a superseded or closed concern is never re-surfaced.
- `CLAUDE.md`, `README.md` — document the triage step and the new
  `superseded_by` / `status` values.
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests.

## Implementation Steps

1. **Trigger** — after the judge pass in `/report`, compute the active
   concern count; if it exceeds a threshold (configurable; sensible
   default, e.g. 20) **or** the judge returned any compound proposal,
   enter the triage step. Below threshold with no compound, skip silently.
2. **Judge proposes compounds** — extend the Judge Deferred Concerns
   output with `compounds: [{members:[concern_id,…], suggested_severity,
   rationale}]`: candidate combinations where the interaction raises risk
   above the parts.
3. **Present triage** (`AskUserQuestion`, at command level, each question
   body prefixed `[<project label>]` per the guard) with buckets: **merge
   duplicates** → one fresh concern; **combine A+B** → compound (developer
   confirms/edits the severity and text); **close** → archive as
   `resolved` or `accepted` with a reason; **keep as-is**. Iterate or
   multi-select as the count warrants.
4. **Apply via mutators** (POSIX, idempotent — re-running applies nothing
   new):
   - `merge-concerns.sh <target-id> <member-id…>` — fold members into the
     target (or a new compound id), set the confirmed severity, bump
     `last_seen`, and archive each member with `superseded_by: <target-id>`.
   - `close-concern.sh <id> <resolved|accepted> [reason]` — move to
     `.workaholic/concerns/archive/` with `status` and reason.
5. **Story reflects the fresh set** — section 6 lists the curated,
   merged concerns, not the raw pile.
6. **Rebuild `outputs/`** (report/ship closure) and **update docs** in the
   same change.

## Quality Gate

Approval in `/drive` requires ALL of the following, demonstrated
objectively (hermetic tests in `scripts/test-workflow-scripts.mjs`):

- **Merge collapses and escalates:** merging 3 concerns yields **one**
  file at the developer-confirmed (escalated) severity, with the 3 parts
  archived carrying `superseded_by: <target-id>`; a superseded part is
  never re-surfaced by a subsequent extract/judge pass.
- **Close archives with reason:** `close-concern.sh` moves a concern to
  the archive with `status: resolved|accepted` and its reason, and it
  drops out of `list-active-deferred-concerns.sh`.
- **Trigger is correct:** the triage step fires when the active count
  exceeds the threshold and when a compound is proposed, and stays
  **silent** below threshold with no compound.
- **Labelled prompt:** the triage `AskUserQuestion` passes the
  `guard-askuserquestion-label.sh` gate (each question body opens with
  `[workaholic]`).
- **Idempotent:** re-running a merge/close for an already-applied decision
  is a no-op.
- **Repo gates green:** `build.mjs` leaves no `outputs/` diff, `verify.mjs`
  / `validate-metadata.mjs` pass, the full smoke suite passes, and
  `posix-lint.sh` is conforming.
- **Manual proof:** a real `/report` run on this repo offers triage,
  collapses a compound the judge proposes, and the resulting concern set
  is smaller and fresh.

## Considerations

- **Depends on the identity engine** (`20260713203444`) — merge and
  supersede need the stable `concern_id`; do not start until it lands.
- **One-level fan-out** — the judge (a `general-purpose` leaf) may
  *propose* compounds but must not call `AskUserQuestion`; the command
  presents the triage and applies the mutators.
- **POSIX sh only**, extract logic to bundled scripts, **rebuild
  `outputs/` in lockstep** (report/ship are in the built closure).
- **Idempotent mutators** modeled on the mission skill; a superseded or
  closed concern must be filtered by both the report judge and the ship
  extractor so it cannot resurface.
- **Threshold is a policy knob** — pick a defensible default and document
  it; avoid auto-merging without the developer's confirmation (the A+B
  severity call is the developer's).
- Grill scope: the triage must not silently discard a concern — every
  bucket leaves an auditable trail (`superseded_by`, `status`, reason).

## Related History

Builds directly on `20260713203444-concern-identity-update-in-place.md`.
The judge pass to extend is the report skill's Judge Deferred Concerns
(`list-active-deferred-concerns.sh` + the LLM verdict flow). The
idempotent single-writer mutator pattern and the `active/archive` split to
imitate are the mission skill's mutators and `close.sh`. User-interaction
placement follows the one-level fan-out rule in `CLAUDE.md`.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: the triage step's testable surface is the two mutators
  (`merge-concerns.sh`, `close-concern.sh`); the trigger, the judge's
  `compounds` proposal, and the `AskUserQuestion` are orchestration prose in the
  report SKILL, not scripts.
  **Context**: hermetic smoke tests cover merge/close (collapse, escalation,
  `superseded_by`, idempotency, bad-status rejection); the `[project]`-label
  requirement on the triage prompt is already machine-enforced by the existing
  `guard-askuserquestion-label.sh` hook, so it needs no new test.
- **Insight**: `merge-concerns.sh` can both create a *new* compound (A+B, needs
  `--title`) and fold duplicates into an *existing* target id — one command, two
  triage buckets.
  **Context**: a compound sets `compound: true` and archives its parts with
  `superseded_by`; a superseded/closed concern is filtered by the ship extractor
  and the report judge (via the archived-id skip from ticket #1), so it never
  resurfaces.
- **Insight**: severity merges by *most-severe* and never downgrades; an explicit
  `--severity` (the developer's confirmed A+B escalation) overrides.
  **Context**: this matches the update-in-place escalation rule from ticket #1, so
  a concern's severity is monotonic unless a human deliberately closes it.
