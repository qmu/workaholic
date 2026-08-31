---
created_at: 2026-08-31T18:20:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Justify or drop each persist the tick makes

## Overview

PROPOSED. The ask names the count directly: `persist-log.sh` runs three times per
tick, and that is what puts two or three `Log the ... tick <id>` commits on `main`
per tick id. Each of the three exists for a stated reason, and the ask requires
each to be **justified by name or dropped by name** once the log is off `main`.

The three, with the reason each was added:

1. **The opening persist** — `run.sh` persists immediately after `open-log`,
   reported under `opening_persist` and logged as `persist-log-opening`. Added
   2026-08-31 with `blocked-tick`: the record that would show a stopped tick was
   the record the stop prevented, so an opening had to reach the base before the
   tick could die. Its whole purpose is *reaching the remote early*.
2. **The closing act** — `run.sh`'s last step. Guarantees that a tick dying
   part-way still publishes every probe line it recorded. Moving the agent's
   filing before it was refused for exactly this reason.
3. **The agent's persist** — after the agent records what it filed. Added
   2026-08-18 with the `(tick, step)` union: `<step>-filed` lines are appended
   after `run.sh` returns, so without a second persist they can never land.

None of the three is redundant *as designed*. What changes is the **cost**: three
commits to `main` per tick was the objection, and three writes to a ref that is
not the product's history may be free. This ticket answers whether the cost
changed enough to keep all three, and writes the answer down.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an operational log is read, not reviewed
- `workaholic:implementation` / `policies/error-handling.md` — a degradation is named, never silent

## Key Files

- `plugins/workaholic/skills/moderate/scripts/run.sh` — the opening persist and
  the closing act, and the `opening_persist` reporting key.
- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the publisher and
  its `already_current` idempotence.
- `plugins/workaholic/skills/moderate/scripts/step-blocked-tick.sh` — the consumer
  the opening persist exists for; it reads for an opening with no closing, where
  *closed* means a `human-checkin` line.
- `plugins/workaholic/skills/moderate/SKILL.md`, `plugins/workaholic/commands/moderate.md`
  — where the count and its reasons are stated.

## Implementation Steps

1. Measure the cost after tickets 2 and 3 land: what three ref writes per tick
   cost in wall time and in remote round-trips, against what three base commits
   cost. Record the numbers; this ticket's answer is a measurement, not a taste.
2. Take each persist in turn and write one paragraph: what it buys, what breaks
   without it, and whether that still holds with the log on a ref. Name it kept
   or name it dropped — a persist left in place with no paragraph is a defect
   this ticket exists to remove.
3. If any is dropped, prove its consumer still works: `blocked-tick` must still
   distinguish a stopped tick from a healthy one, and the `<step>-filed` lines
   must still reach the ref.
4. Preserve the two structural properties whatever the count: `run.sh` keeps its
   closing act (a tick that dies part-way still publishes what it recorded), and
   a persist with nothing to carry stays idempotent (`already_current`).
5. Preserve the one asymmetry already recorded: the last persist's own log line
   is known only after the push, so it is written to the checkout and not to the
   remote. Do not "fix" it — the fix does not terminate.
6. Write the resulting count and its per-persist justification into
   `workaholic:moderate`, and update `CLAUDE.md` where it states the count.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every persist the tick makes is named in `workaholic:moderate` with what it
  buys; the documented count matches `run.sh`.
- `blocked-tick` still names a stopped tick and does not name a healthy one.
- A late `<step>-filed` line still reaches the ref.
- A persist with nothing to carry reports `already_current` and writes nothing.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-blocked-tick`
- A hermetic fixture asserting the late `<step>-filed` line lands.
- `node scripts/test-workflow-scripts.mjs`
- The measurement from step 1, quoted in the change.

**Gate** — what must pass before approval:

- `verify-blocked-tick` passes, and it fails against a build with the opening
  persist removed. If it passes both ways it is not proving the thing this ticket
  is allowed to change.

## Considerations

- The honest outcome may be *all three stay, and here is why the objection no
  longer applies*. That is a complete answer to the ask and must be written as
  one, not treated as having done nothing.
- Do not turn a persist into a conditional on some notion of "did anything
  change" — `already_current` is that condition, derived at the seam, and a second
  copy of it in `run.sh` is how two readings of one fact start to disagree.

## Final Report

Development completed as planned. **All three persists are kept, each justified by name**,
and the count and its reasons are written into `workaholic:moderate` and `commands/moderate.md`.

**The measurement first** (hermetic fixture, local bare `origin`, 2026-08-31): a persist that
carries something takes **~120 ms**, a persist with nothing to carry **~62 ms**, each costing
two remote round-trips — one `fetch` of a single ref, one `push` of one commit. A full tick's
three writes leave **3 commits on the log ref and 0 on `main`**, verified with
`git log --oneline main -- .workaholic/moderations/` returning empty.

**One paragraph each, and none is dropped:**

1. **The opening** — a dead tick cannot write its own closing act, so without it the record
   that would show a stop is the record the stop prevents. `step-blocked-tick.sh` reads it.
2. **The closing** — the guarantee that a tick dying between the ninth step and the agent's
   filing still publishes every probe line it recorded. Moving the filing earlier was
   refused for exactly this.
3. **The agent's** — the `<step>-filed` lines do not exist until `run.sh` has returned.

**The objection is answered by the move, not by a drop.** It was never *three publishes*; it
was three commits a tick on `main`. That is now zero. The old path was also more expensive
per persist — it materialized a whole `.publish/` checkout before appending a line — so the
count got cheaper at the same time as it stopped being visible in the product's history.

**Both structural properties preserved**: `run.sh` keeps its closing act, and a persist with
nothing to carry stays idempotent (`already_current`, no commit). **The one asymmetry stays**:
the last persist's own line is written to the checkout and never published, because the fix
does not terminate. **No persist was made conditional** on a second notion of "did anything
change" — `already_current` is that condition, derived once at the seam.

Nothing was dropped, so step 3's "prove its consumer still works" had no subject; but
`verify-blocked-tick` was run and passes, and its breaker was repaired (below).

### Discovered Insights

- **Insight**: `verify-blocked-tick`'s breaker had been passing for an unrelated reason since
  it shipped. The breaker copies the script directory to a temp path, where the old
  publish-tree seam resolved `../../branching/scripts` to nothing, so **every** persist in
  the breaker failed — with or without the opening one. Repointing the log at a ref removed
  that dependency and the breaker immediately stopped breaking.
  **Context**: this is the drill register's own premise landing on a live row. The gate asked
  for `verify-blocked-tick` to fail against a build with the opening persist removed, and it
  did not: it failed against a build with a broken relative path.

- **Insight**: the deeper half of the same defect is that `--only open-log` stops the **steps**,
  not the run — `run.sh` still reaches its closing persist, which carries the very section
  row 1 looks for. So row 1 was satisfied whether or not the opening persist existed.
  **Context**: repaired by running row 1 and its breaker against a build with the **closing
  act** disabled, which is what a tick that died actually looks like. The two builds now
  differ in exactly one thing: whether the opening persist is there.
