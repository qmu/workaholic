---
created_at: 2026-08-22T17:51:31+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-root-earn-its-hour
merge_policy:
verification_handoff: 
---

# Diff the tick's steps on a stable form

## Overview

`render-tick-post.sh` defines a change as a step whose summary differs from the same step's
summary in the previous tick, and implements it as a raw string compare
(`[ "$was" = "$summary" ] && continue`).

Two steps embed a value that moves on its own inside that summary: `inbound-sweep` carries an
ISO8601 timestamp (`GitHub read since <ts>`) and `doc-drift` carries a sha
(`no new documentation drift since <sha>`). Both therefore differ on every tick by
construction, so both are always "changed" and the root always posts.

This is the load-bearing failure. The header of the script itself names the property being
lost: `📦 Release Preparation` was retired for restating an unchanged answer ten hours running,
and the diff derivation is what made an hourly root admissible in its place — *a diff cannot
do that by construction*. As shipped, it can and does.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the comparison (~line 137)
  and the header stating the property to restore. Read the header before changing it.
- `plugins/workaholic/skills/moderate/scripts/step-inbound-sweep.sh` — writes the timestamped
  summary.
- `plugins/workaholic/skills/moderate/scripts/step-doc-drift.sh` — writes the sha-bearing
  summary.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` / `log-read.sh` — the summaries'
  writer and reader; whether normalization happens at write or at compare is decided against
  these.
- `plugins/workaholic/skills/moderate/SKILL.md` — states the derivation; must match whatever
  is implemented.

## Implementation Steps

1. **Reproduce first.** Run two consecutive ticks against an unchanged repository and confirm
   from the log that `inbound-sweep` and `doc-drift` differ between them, and that the
   difference is only the timestamp and the sha. Establish this from the log and the scripts,
   not from the report.
2. **Localize.** Confirm the raw compare in `render-tick-post.sh` is the only place a change is
   decided, and enumerate every step whose summary carries a self-moving value — do not assume
   the two named here are all of them.
3. Choose where to fix it and record the reason: normalize at compare (strip timestamps, shas
   and other monotonic runs before comparing) or keep the moving value out of the summary text
   at write. Prefer whichever leaves the log's own lines still readable by a human, since the
   log is the audit trail.
4. Apply it, and keep the existing exclusion of the check-in step — a precedent that a step may
   be excluded from the diff deliberately; state whether any new exclusion is added and why.
5. Restore the property in words in `SKILL.md`: an hour whose steps found the same thing as the
   hour before produces no change.
6. Update `CLAUDE.md` and the moderate `reference/workflow.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two consecutive ticks over an unchanged repository produce `change_count: 0` and post nothing
  (`idle`).
- A step whose finding genuinely changed is still reported as changed.
- Every step carrying a self-moving value is handled; the set is enumerated, not assumed.
- The log's lines remain readable to a human.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-moderate`
- A two-tick hermetic run over an unchanged tree asserting `idle`, and a second pair with one
  step's finding changed asserting exactly one change.

**Gate** — what must pass before approval:

- All four criteria hold and the suite plus the moderate drill are clean.

## Considerations

- Normalizing too aggressively re-creates the opposite defect: a real change hidden because it
  looked like noise. Strip only values that move without the repository moving.
- This ticket alone makes the root rare. It does not make it useful — that is the other two
  tickets in this mission.
