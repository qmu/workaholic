---
created_at: 2026-08-27T23:22:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-reproduce-the-refused-branch-delete-and-name-it.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Give a refused delete its own reported word

## Overview

`retire-claim.sh` collapses three unrelated failures into one word. Its closing
branch reports `partial_retirement` whenever `PR_STATE`, `REMOTE_STATE` or
`WORKTREE_STATE` went wrong — so a refused pull-request close, a refused branch
delete and a dirty worktree all read alike, and only the first has a `pr_note`
that survives. Measured: three units reported `partial_retirement` for a **branch
delete**, and nothing in the tick log said so.

The `session_type_cannot_merge` precedent (2026-08-23, the same shape one act over)
is what this follows: a refusal the transport made gets its own word, so the reader
learns *which act is blocked* rather than that something was.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a refusal names itself

## Key Files

- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the closing branch
  that emits `partial_retirement`; each act's own state already rides the row, so
  the word is derivable with no new field.
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the caller
  whose per-row `summary` line renders the reason.

## Implementation Steps

1. Split the closing branch so each blocked act reports its own reason word, derived
   from the three states already on the row: a refused delete, a refused close and a
   refused worktree stop sharing one word. `pull_request_close_failed` already
   exists; the other two gain their counterparts.
2. Carry the **measured** refusal from ticket 1 into the word's granularity — if the
   diagnosis distinguished session-type from protection from scope, the word says
   which; if it named one cause only, one word is correct and a speculative
   three-way split is not added.
3. Keep every existing success word untouched: `already_closed`, `already_gone`,
   `none` and `absent` are successes, not degradations, and this ticket does not
   touch them.
4. Keep `retired` meaning the whole retirement, and keep the always-exit-0 contract.
5. Update `step-retire-claims.sh` only where the reason is rendered — the step
   already prints `.reason`, so a new word flows through without a second mapping.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A refused branch delete reports a word distinct from a refused pull-request close
  and from a refused worktree reap.
- The word derives from state already on the row; no artifact gains a field.
- A fully successful retirement and every idempotent success report exactly as before.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire`

**Gate** — what must pass before approval:

- Both commands pass, and the diff adds no field to any `.workaholic/` artifact.

## Considerations

- Ticket 1 is a hard dependency: the word's granularity is only honest once the
  refusal has been measured. Splitting on a guess would ship three words where the
  world has one, which is the same defect one layer down.
- The temptation is to make the reason a free-text passthrough of the transport's
  message. Resist it for the machine-read field — the message belongs in the
  summary; the reason stays a closed vocabulary the caller can key on.
