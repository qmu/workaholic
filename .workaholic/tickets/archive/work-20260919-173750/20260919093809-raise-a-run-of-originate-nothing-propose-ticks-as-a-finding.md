---
created_at: 2026-09-19T09:38:09+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: never-let-the-routine-that-originates-work-converge-on-silence
merge_policy:
verification_handoff:
---

# Raise a run of originate-nothing propose ticks as a finding

## Overview

Operator's ask: **issue #907**, item 1 — *a zero-proposal tick is a finding, not an outcome*.
Measured on a consuming repository, 2026-09-02: 64 consecutive `/propose` ticks each ended
`{"proposed": 0}` beside eight open inbound items and an empty queue, and every one of them was
reported as "no change".

**The claim was re-established against this tree before the ticket was written, and it holds.**
`/propose`'s own outcome for a tick that originates nothing is a line in its run report
(`skills/propose/reference/loop.md` step 1), and that skill says three separate times why the
report cannot carry a finding: *this report is read by nobody on the day it matters, which is why
nothing here is ever a brake*. The seam that does reach a person is `/moderate`. Its registry
(`skills/moderate/scripts/steps.json`) carries **no** step that reads whether propose ticks are
producing anything. The nearest one, `step-blocked-tick.sh`, has a **propose arm** — and it asks
exactly one question: did a `propose-open` line ever get a matching `propose-close`
(`step-blocked-tick.sh:139-176`). A tick that opened, surveyed, refused every direction and closed
cleanly is the healthy case by that reading. **Sixty-four of them read identically to sixty-four
idle hours.**

So the gap is not that the routine is silent about it — it is that the one surface carrying the
answer is a report nobody opens, and the surface a person reads never asks the question.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` for the new step
- `workaholic:implementation` / `policies/observability.md` — the governing policy: a routine that
  has stopped and a routine with nothing to do must not produce the same observable output
- `workaholic:implementation` / `policies/test.md` — the reading and its refusals are pinned by
  hermetic fixtures over a fabricated log, never by reading the step

## Key Files

- `plugins/workaholic/skills/moderate/scripts/steps.json` — the registry; a step absent here does
  not run. The new entry sits beside `blocked-tick`, whose subject it is nearest.
- `plugins/workaholic/skills/moderate/scripts/step-blocked-tick.sh` (lines 93-176) — the model and
  the boundary: its propose arm already reads the log under `--owner propose` and already reasons
  about `propose-open`/`propose-close`. This ticket must not widen that step; *never closed* and
  *closed having originated nothing* are two questions, and one step answering both is how the two
  drift (the repository's own recorded rule for `overdue` versus `pace`).
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the one reader, scoped `--owner
  propose`; `readable: false` is a named degradation and never an empty set.
- `plugins/workaholic/skills/propose/scripts/open-proposal.sh` — the only writer of a proposal, and
  the place a per-tick outcome line would have to be recorded if the log does not already carry
  one. Establish which before designing the reading.
- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — how long the condition has been
  standing, for the question body; nothing derives an age twice.
- `plugins/workaholic/skills/moderate/scripts/lib/jq-guard.sh` — sourced by every step in this
  skill that embeds a jq program.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the per-step reference.
- `scripts/test-workflow-scripts.mjs` — `moderateSteps()` consumes the registry directly.

## Implementation Steps

1. **Reproduce first, design second** (`workaholic:discover`, Diagnosis-First Rule). Run
   `sh plugins/workaholic/skills/moderate/scripts/log-read.sh --owner propose` in this checkout and
   record which step ids a propose tick actually writes and whether any of them carries the tick's
   **outcome**. The reading in step 2 depends on this answer and must not assume it.
2. **Establish the propose tick's outcome in the log, if it is not already there.** A finding
   about *originating nothing* needs the outcome per tick, not only that the tick ran. Record it as
   one additional `propose-close` field or one additional line written by the same writer that
   already writes `propose-open`/`propose-close`; add no second store, no cursor and no field on
   any artifact. If the log already carries enough, write nothing here and say so in the story.
3. **Write `step-propose-yield.sh`** beside its siblings: `--tick <tick-id> [--root <repo-root>]`,
   one JSON line `{step, status, reason, summary, needs_agent, event}`, always exit 0, sourcing
   `lib/jq-guard.sh`. It reads the propose-owned log and answers, over the ticks it can see, how
   many closed having originated nothing and how many originated something.
4. **The finding is the gating, not the silence.** A run of originate-nothing ticks is reported
   with **what refused them** — the refusal words the survey already emits — so the person reads
   *four directions held by `open_proposal`, inbox not draining* rather than *propose is quiet*.
   The step composes `propose/scripts/survey-strategies.sh` for the current refusal set; it derives
   no refusal of its own and adds no word to that vocabulary.
5. **A degraded read is never a finding.** An unreadable or unparseable log, or a survey that could
   not be run, answers `status: "degraded"` with its own reason (`log_unreadable`,
   `survey_unreadable`) and raises nothing — `readable: false` is not zero ticks, exactly as
   `log-read.sh`'s own header requires.
6. **Bound what earns a question.** A single originate-nothing tick is the ordinary case and must
   raise nothing; the finding is a *run* of them. Derive the bound from a reading rather than
   picking a constant — the tick count the log itself holds for the window the step already reads
   is available, and a fresh tunable number is refused by this repository by name. State the
   derivation in the step's own header.
7. **`needs_agent` and `event`.** Supply an `event` phrase only when the finding fires, carrying
   counts and refusal words and no strategy slug (the 2026-09-01 rule: a root line carries counts,
   a question carries identifiers). Ask the question once through the existing ask seam, keyed on
   its own subject so `condition-age.sh` can age it, and let the asked-once gate work unchanged.
8. **Register** the step in `steps.json` (`id: "propose-yield"`, `script:
   "step-propose-yield.sh"`, cadence `3600`), beside `blocked-tick`. `run.sh` needs no edit.
9. **Document** it as the next free numbered section in `moderate/reference/workflow.md`: the
   invocation, what it reads, the derivation of the bound, and the two things it never does (it
   never proposes, and it never lifts a gate).
10. **Hermetic rows in `scripts/test-workflow-scripts.mjs`** over a fabricated log: a run of
    originate-nothing ticks fires once with the refusal words named; a single such tick fires
    nothing; a tick that originated something fires nothing; an unreadable log answers `degraded`
    and raises nothing; two ticks over an unchanged reading produce byte-identical summaries.
11. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`,
    `node scripts/build-plugins/verify.mjs`, `node scripts/test-workflow-scripts.mjs`,
    `bash plugins/workaholic/hooks/layout-doctor.sh .`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `steps.json` carries a `propose-yield` entry and `step-propose-yield.sh` emits the six-key
  envelope on every path, including every refusal.
- Given a fabricated log holding a run of propose ticks that all originated nothing, one tick
  raises exactly one finding whose summary names the **refusal words** that held the directions.
- Given a log holding one such tick, or one holding a tick that originated something, the step
  raises nothing.
- Given an unreadable or unparseable log, the step answers `status: "degraded"` with its own
  reason and raises nothing — never `ok` with a zero count.
- `survey-strategies.sh`, its refusal ladder and its vocabulary are **byte-identical to
  `origin/main`**: this ticket adds no refusal word and lifts no gate.
- `step-blocked-tick.sh` is **byte-identical to `origin/main`**.
- Two ticks over an unchanged reading produce byte-identical summaries.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green and the new rows fail when reverted.
- `git diff origin/main -- plugins/workaholic/skills/propose/scripts/survey-strategies.sh plugins/workaholic/skills/moderate/scripts/step-blocked-tick.sh` is empty.
- `sh plugins/workaholic/skills/moderate/scripts/step-propose-yield.sh --tick verify-local --root .`
  run twice in this checkout emits identical summaries and exits 0 both times.
- `sh scripts/e2e/loop-drill.sh verify-all` is green.

**Gate** — what must pass before approval:

- The suite is green, the bundle rebuild is diff-clean, and `layout-doctor.sh` reports
  `conforming: true`.
- Every new script line is POSIX `sh`, not bash.
- The bound that separates one tick from a run has a stated derivation in the step's own header.
  A bare number with no derivation does not pass, whatever else is green.

## Considerations

- **This step reports; it never originates.** The temptation is to let the finding open the
  proposal the gates refused. That is refused by name: `rules/workaholic.md`, *What May Originate a
  Mission* — only a human's ask or a human-authored strategy may.
- **It must not become an hourly status line.** Two keyed roots have already been retired here for
  exactly that. Keep clock-derived values out of `summary` and out of `event`, so an unchanged
  condition renders no new root line.
- **The ask's own wording — "emit that rather than a silent line" — is read as *report*, not
  *queue*.** Filing a ticket for a stalled ingest stage would be the loop writing itself work, and
  `self_authored` forbids it.

## Final Report

Development completed as planned.

Step 1 (reproduce first) was run against this checkout and changed the design:
`log-read.sh --owner propose` answers **zero** entries here — nothing in the plugin writes the
documented `propose-open`/`propose-close` pair, which exists only in `step-blocked-tick.sh`'s
reader, the drill fixture and the rules table. What *does* carry the propose tick's outcome is
`log-read.sh --owner loop --step-prefix loop-finish-propose`: 16 entries whose summary is the
worker's structured result (`{"executed":true,"outcome":"propose:proposed_0:past_target_date",…}`),
written by the one writer (`log-append.sh`) through the finish seam. So step 2's conditional
applied — **the log already carries enough and nothing new is written**.

`step-propose-yield.sh` reads those lines, classifies each tick by a **declared, closed token
set** spelled in its own header, and treats an outcome outside that set as `unclassified`, which
**holds** the finding (`degraded` / `outcome_unclassified`) rather than letting *every tick
originated nothing* stand as a claim it did not establish. Run against the live log here it
answers exactly that, because `completed` is a live outcome value.

The bound has a stated derivation and no constant: the **window** is `step-blocked-tick.sh`'s own
newest-two-day-files bound, and a **run** is *every propose finish that window holds, and more
than one* — the same structural *outlived a further tick* bound the sibling applies to its own
subject. The finding composes `survey-strategies.sh` for the refusal words and derives none.

### Discovered Insights

- **Insight**: the `propose-open`/`propose-close` producer contract is documented in
  `rules/workaholic.md`, in `log-read.sh`'s header and in the drill fixture, and **no script in
  the plugin writes it**. `/propose`'s command body forbids writing into the repository, and its
  only script seam (`open-proposal.sh`) runs solely on a tick that *did* originate — so the
  zero-proposal case has no writer at all.
  **Context**: a reader scoped `--owner propose` returns nothing in this repository, so anything
  built on that owner is inert here. The coordinator's `loop-finish-<role>` line is the real
  carrier of a propose tick's outcome, and it lives under owner `loop`.
