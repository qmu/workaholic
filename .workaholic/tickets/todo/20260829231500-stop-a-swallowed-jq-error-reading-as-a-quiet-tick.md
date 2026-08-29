---
created_at: 2026-08-29T23:15:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-direction-s-lifecycle-a-declared-stage
merge_policy:
feedback: [20260829211659-make-the-strategy-lifecycle-staged.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
verification_handoff: 
---

# Stop a swallowed jq error reading as a quiet tick

## Overview

MINTED MID-RUN, from a defect this mission's own work reproduced rather than predicted.

`moderate/scripts/step-direction-health.sh` composes its subjects with

```sh
subjects=$(printf '%s' "$STATE" | jq -c '…' 2>/dev/null || echo '[]')
```

so a jq **compile** error — one apostrophe in a comment, a missing parenthesis around an
object value — is discarded and the step emits `[]`. Measured while shipping *Show a
direction's stage where directions are read*: the step reported

```
"status": "ok", "summary": "… 1 overdue, 0 expiring, 1 dormant …; 0 to ask", "needs_agent": []
```

A tick that found two directions needing a person, could not compile the expression that
would name them, and reported itself **healthy with nothing to ask**. That is precisely the
collapse this step's own header forbids everywhere else: *a read we could not make must never
render as a reading we made*.

The failure is invisible for two further reasons. `sh -n` passes — the shell parses fine, it
is the embedded jq that does not — and the fallback is **legitimate** for a *data* problem, so
it cannot simply be deleted.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a degraded read is named, never rendered as an answer
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one derivation of "this step could not read"

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the measured case;
  its `|| echo '[]'` and the `2>/dev/null` that hides the reason.
- `plugins/workaholic/skills/moderate/scripts/` — every sibling step using the same shape;
  the fix is worth nothing if it is applied to one script only.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the contract that a degraded
  step reports `degraded` **by name** rather than `ok` with an empty finding.
- `scripts/test-workflow-scripts.mjs` — where `every shipped shell script parses` was added in
  this mission; the jq analogue belongs beside it.

## Implementation Steps

1. **Reproduce first**, on a copy: break one embedded jq program (an apostrophe in a comment
   is enough) and confirm the step still reports `status: ok` with an empty `needs_agent`.
2. Survey which `moderate/scripts/step-*.sh` share the shape. Count them before deciding —
   the repair is worth doing once, in a form every one of them can adopt.
3. Distinguish the two cases the single fallback currently merges: a jq **compile** error
   (our own defect — the step cannot run at all) from a jq **runtime/data** result (an honest
   empty answer). Only the first may reach `degraded`.
4. Report the first as `degraded` with its own reason, so `run.sh` counts it and the tick log
   names it. A step that cannot compile its own reading has found nothing and must not say so
   in the vocabulary of a step that looked.
5. Consider a suite-level guard beside `every shipped shell script parses`: extract each
   embedded jq program and compile it (`jq -n '<program>'` or `jq --args`), so a compile error
   fails the suite rather than one hourly tick. State the limits — a program built by string
   interpolation may not be extractable, and those are named rather than skipped silently.
6. Do **not** simply drop `2>/dev/null`: the stderr of a legitimately degraded read is noise on
   an hourly unattended run, and the fix is to classify, not to shout.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A step whose embedded jq fails to compile reports `degraded` with a named reason, never `ok`.
- An honestly empty reading still reports `ok` with an empty finding, unchanged.
- Every step sharing the shape is covered, or the ones deliberately left are named with why.
- No step's questions, keys, caps or holds move.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-direction-health`
- A deliberate one-character break in one embedded program must fail the suite.

**Gate** — what must pass before approval:

- The suite passes on the unmodified tree and fails on the deliberate break above.

## Considerations

- The tempting minimal fix is to remove `|| echo '[]'` from the one measured script. That
  turns a swallowed error into an unhandled one for that script and leaves every sibling
  exactly as it was — the defect is the **shape**, not the file.
- `every shipped shell script parses` (added 2026-08-29) catches the shell half of this class
  and provably does not catch the jq half: the measured break passed `sh -n` and still
  produced an empty, healthy-looking tick.
