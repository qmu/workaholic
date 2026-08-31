---
created_at: 2026-08-31T10:24:24+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: name-the-steps-a-tick-could-not-read
merge_policy:
verification_handoff: 
---

# Read the impairment off the tick's own rows

## Overview

PROPOSED. `run.sh` already classifies every step `ok|filed|skipped|degraded|blocked`
with a stable `reason`, and emits both on each row plus `counts.degraded` /
`counts.blocked`. `render-tick-post.sh` parses each row twice — once for
`step`→`summary` (the diff) and once for `step`→`event` (the rendered line) — and
**never reads `status` at all**. Everything needed to say *which steps could not read*
is already in the renderer's stdin and is discarded there.

This ticket adds the **one derivation** both later consumers read: the set of steps this
tick could not read, with their reasons. The line (`name-the-impaired-steps-on-every-root`)
and the gate (`let-a-changed-impairment-earn-a-root`) then compose it rather than each
re-deriving it from the rows — two parsers of one fact is what this repository refuses by
name everywhere else.

It changes **no output**: after this ticket the renderer emits new fields and posts
exactly what it posts today. That is deliberate, so the reading can be proved before
anything depends on it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the tick is an unattended runtime surface; a reading it could not
  make must be named rather than rendered as a clean one

## Key Files

- `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh` — the renderer; already
  receives `run.sh`'s whole JSON on stdin and already tokenises rows twice with
  `tr '{' '\n' | sed -n`. The third field pattern goes beside the two that exist.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the producer of `status` and
  `reason`; read only, to pin the closed vocabulary. **Not modified by this ticket.**
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the row schema
  (`{"step","status","reason","summary","event",...}`) this reading is written against.

## Implementation Steps

1. **Reproduce the shape first.** Feed `render-tick-post.sh` a captured `run.sh` JSON in
   which several steps carry `"status": "degraded"` with reasons, and confirm the emitted
   object carries no term naming them — and that with `--questions 0` it emits
   `post: false`, `reason: idle` or `no_question`, i.e. total silence. That is the
   measured defect, reproduced.
2. **Localize it** to the two `sed -n` field patterns in `render-tick-post.sh`: neither
   captures `status` or `reason`, so the impairment is dropped at the parse and nothing
   downstream can recover it. (Already localized during discovery; step 1 is what makes
   the fix's effect provable.)
3. Add a third pass over the same tokenised input capturing `step`→`status`→`reason`,
   written to `${TMP}/status` in the same `step<TAB>value` shape the other two use, with
   the same whitespace-tolerant patterns (`": *\""`) for the reason the file's own header
   records.
4. Derive **`impaired`**: the rows whose `status` is `degraded` **or** `blocked`, in
   `STEPS` order, each as `{step, status, reason}`. `skipped` is **not** impairment — it
   is a step declining to run for a stated, healthy reason — and stating that boundary in
   a comment is part of the step.
5. Emit `"impaired": [...]` and `"impaired_count": N` on the renderer's JSON, on **every**
   path including each `emit false ...` early return: a tick that posts nothing is exactly
   the case the operator could not see, so the reading must survive the silent paths.
6. Leave `post`, `reason`, `changes`, `change_count`, `questions`, `previous_tick` and
   `root_text` byte-identical. No gate moves and no line is rendered in this ticket.
7. Handle the degenerate inputs explicitly: no rows (`no_rows`), a row whose `status`
   field is absent, and a `reason` that is empty — none may crash the renderer or invent
   an impairment.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `render-tick-post.sh` emits `impaired[]` and `impaired_count` on every exit path,
  including `idle`, `no_question`, `no_previous_tick`, `no_log` and `no_rows`.
- `impaired[]` contains exactly the `degraded` and `blocked` rows, in `STEPS` order, each
  carrying the step's own `status` and `reason` verbatim.
- A `skipped` row never appears in `impaired[]`.
- For any input, `post`, `reason`, `change_count`, `questions`, `previous_tick` and
  `root_text` are byte-identical to the pre-change renderer.

**Verification method** — the commands/tests/probes that prove them:

- A fixture run over a captured `run.sh` JSON with mixed statuses, asserting the new
  fields and diffing every pre-existing field against the pre-change output.
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The byte-identical diff over the pre-existing fields is demonstrated, not asserted.

## Considerations

- The reporter's proposed fix ("make the post name the degraded steps") is the direction
  this mission takes, and the cause was **verified in discovery** rather than assumed: the
  renderer's two `sed` patterns provably capture neither `status` nor `reason`. It is
  recorded here as a checked diagnosis, not an unexamined hypothesis.
- Reading `counts.degraded` instead of the rows was considered and rejected: a count says
  how many steps were blind and never which, and the ask is for the steps **by name**.
- The renderer parses with `sed`/`awk` rather than `jq` on purpose (its header: every other
  script in this skill runs where `jq` may be absent). Keep the third pass in that idiom.

## Final Report

Development completed as planned.

The defect was reproduced before it was repaired: a captured `run.sh` JSON carrying two
`degraded` steps (`inbound-sweep` / `no_slack_transport`, `merge-conflicts` /
`gh_unavailable`) and one `blocked` step (`stalled-units` / `shallow_history`) rendered an
object with **no term naming any of them**, and with `--questions 0` it emitted
`post: false, reason: idle` — total silence, byte-identical to a tick where everything was
read.

`render-tick-post.sh` gained a third pass over the same tokenised input in the same
`sed`/`awk` idiom, writing `step<TAB>status<TAB>reason` to `${TMP}/status`, and one
derivation of `impaired[]` / `impaired_count` from the rows whose status is `degraded` or
`blocked`. `skipped` is excluded by name and in a comment: a step declining to run for a
stated, healthy reason (`budget`) is not an impairment.

The reading is emitted on **every** exit path. `no_tick` was the one early return that fired
before the rows were parsed, so the `[ -n "$TICK" ]` check moved below the parse; its output
is otherwise unchanged. `TAB` moved to the top of the script and is now defined once.

No output moved. Verified across all eight exit paths (`idle`, `no_question`,
`no_previous_tick`, `no_log`, `no_rows`, `no_tick`, and `ready` at one and three questions)
by diffing the post-change output with the two new fields stripped against output captured
from the pre-change script: **byte-identical on every pre-existing field**, demonstrated
rather than asserted.

### Discovered Insights

- **Insight**: `STEPS` order needs no list in the renderer — `run.sh` walks `STEPS` and emits
  its rows in that order, so preserving input order *is* `STEPS` order.
  **Context**: The ticket asks for `STEPS` order and the obvious reading is to re-declare the
  step list here. That would be a second copy of a list this script has no business owning,
  and it would drift the first time a step is added. The ordering guarantee is structural.

- **Insight**: `run.sh`'s row field order is `step, status, reason, summary, needs_agent,
  logged, event`, so `status` and `reason` sit *between* the two fields the renderer already
  parsed — they were passing under the existing patterns on every tick.
  **Context**: The two `sed` patterns are anchored on `"step"` and then skip forward with
  `.*`, so the impairment was never unreachable, only unasked-for. Any future field between
  `step` and `summary` is readable the same way, with no change to how the input arrives.

- **Insight**: The whitespace-tolerant field patterns (`": *\""`) are load-bearing beyond
  formatting: the new pass was exercised against compact `JSON.stringify` output with no
  spaces at all and reads identically.
  **Context**: The file's header records that a parser written against one producer's
  formatting breaks the first time anything else feeds it. A drill or test that builds its
  fixture with `JSON.stringify` is exactly that other producer.
