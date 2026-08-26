---
type: Feedback
title: question-liveness reads an array run.sh never emits, so every asked question reads settled
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T06:57:31+00:00
author: a@qmu.jp
supersedes: 
---

# question-liveness reads an array run.sh never emits, so every asked question reads settled

Measured on tick `20260826-065129`, on this repository.

`question-liveness.sh` decides `live` vs `settled` by matching the question's key as
an exact string inside the owning step's **`needs_agent` payload** in the tick's run
report:

    (.needs_agent // []) | tostring | contains($k)   -> live, else settled

`run.sh` does not emit that payload. Its report renders each step as
`"needs_agent": <count>` — an integer, by design ("`needs_agent` is an array of flat
objects; the report only needs its length"). So `tostring` on an integer can never
contain a key, and **every already-asked question whose owning step returned `ok`
reads `settled`**, whether or not the step raised it again.

Reproduced both ways in the same tick:

- `--run` = `run.sh`'s own report → `stalled-unit:batch-20260818215156` reads
  **`settled`**.
- `--run` = the same report with `stalled-units`' real `needs_agent` array spliced in
  → the same key reads **`live`**.

`stalled-units` raised that unit again on that tick. The `settled` reading is false.

The consequence is a wrong post, not a missing one: a question in state `asked`
whose liveness reads `settled` earns one `✅ 解消を確認` reply into the thread where
it was asked, logged `human-checkin-confirmed-<slug>` so it can never be corrected by
a later tick. The tick therefore tells a person a blocker cleared while the blocker is
in that same tick's own findings. The re-ask rule fails the same way, in the safe
direction: `settled` is never re-asked, so a question outstanding across days is
silently dropped instead of being asked once more.

Two things happen to be masking it today. `stuck-prs` returns `blocked`, which is
`unknown` before `needs_agent` is ever consulted, and the only confirmation posted so
far (`batch-20260819063000`, 13:57 JST) was genuinely settled, so the output looked
right.

The two halves are one skill and disagree about one field. Either `run.sh` carries the
arrays it already has (they exist in each step's own output and are discarded when the
row is rendered), or `question-liveness.sh` takes the step's output rather than the
run report. Whichever is chosen, a hermetic test should assert that a key a step
raised this tick reads `live` when the reader is given exactly what `run.sh` emits —
the coupling is invisible from either side alone.
