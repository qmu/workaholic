---
created_at: 2026-09-18T13:12:55+09:00
status: done
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260918-132835
---

# Keep a raised check-in question askable after its step's window moves

## Overview

A check-in question can be raised, held because nothing could deliver it, and then vanish —
unasked, unanswered, and reported nowhere. Candidacy is derived per tick from the **producing
step's own window**, and the arrears that are supposed to make a hold a delay rather than a loss
are enumerated from **per-key `human-checkin-held-<slug>` log lines the agent writes by hand**.
A question whose step stops offering it, and for which the agent wrote no per-key line, is held
by nothing at all: `step-human-checkin.sh` reads `--step-prefix human-checkin-held` and the
registry only as a slug→key preimage resolver, so a registry row in state `candidate` that no
log line names is enumerated by **no reader in the tick**.

This is the defect PR #1200 (`d80c10a31`) repaired, approached from the other side. #1200 stopped
a question being **retired** on an absence of a reading; this one is a question **evaporating**
because the step that raised it moved on. The repair reuses that vocabulary —
`question-registry.sh`, `question-liveness.sh`, `reconcile-questions.sh`, `question-state.sh` —
and adds no parallel mechanism, no second store and no new script.

**Measured, with the concrete instance.** `blocked-tick:20260904-085918` named the moderate tick
of 2026-09-04 08:59 UTC, whose section in `.workaholic/moderations/2026-09-04.md` stops at
`standing-rulings` with 17 rows and no `human-checkin` close. It became a candidate at all
because the log had a 13-day gap — the newest two day files on 2026-09-17 were `2026-09-04.md`
and `2026-09-17.md`, so `step-blocked-tick.sh`'s *tick before last* resolved to the 09-04 tick —
and it appeared exactly **once**, on line 53 of `.workaholic/moderations/2026-09-17.md`:

```
- `questions-held`: blocked — 4 question(s) held, 0 asked (human-checkin skipped
  quiet_hours, 22-08 Asia/Tokyo): direction-overdue:…, stalled-unit:…,
  blocked-tick:20260904-085918, operator-pull:1180; the ledger is untouched, so every key
  stays held and is offered again when a transport returns inside the window
```

That line's promise did not hold. In the same tick exactly **one** of the four keys got a per-key
held line — `human-checkin-held-inbound-channel-unreadab-3989672039` — and that is the only one
of the four still reachable today. The registry now holds three keys and this is not among them:

```
runtime/scripts/state.sh read --scope instance --id questions
  → inbound-channel-unreadable:dev-workaholic          (candidate, step direction-health)
    direction-arrived:an-autonomous-improvement-loop-…  (candidate, step direction-health)
    blocked-tick:20260917-211754                        (candidate, step direction-health)
```

So the question was never registered (`ask-question.sh` registers before every gate, so an
absent row means the gate was never called for that key), never asked, and the hour after the
09-17 log gained a second tick the 09-04 key left `blocked-tick`'s candidate set for good —
that step reads only the tick before last, by a structural bound its header defends and this
ticket does not touch. Nothing anywhere reports the loss. The tick of 2026-09-18 04:07 named it
once as a `blocked-tick-stale-key` observation written by hand, which is a person noticing, not
a mechanism.

**Note the third field of every registry row above**: all three read `step: direction-health`,
including a `blocked-tick:` key. `question-liveness.sh` is keyed on that field, so it reads the
wrong step's row — it answers about a step that never raised the key. That is part of the same
repair (below) because the enumeration this ticket adds is what makes the field load-bearing.

**The fork the ask names is closed here, not deferred.** An undeliverable question **persists in
the registry independently of its step's window, and the drain enumerates it from there** —
reporting the loss instead would be a sentence about a question nobody can answer any more,
which is the outcome this repository has twice retired posts for. The reporting is added **as
well**, because a repair with no reading behind it is unfalsifiable: each arrear names where it
came from. Do not write an `## Open Decisions` section for it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh` scripts, one reader per fact (all code work)
- `workaholic:implementation` / `policies/type-driven-design.md` — the arrear's source and its first-seen reading are closed, named sets; an unknown age is its own value and never rounds to *today*
- `workaholic:implementation` / `policies/observability.md` — a question the loop raised and could not deliver is visible by mechanism, not by a maintainer noticing
- `workaholic:implementation` / `policies/test.md` — the upgrade path over already-stored registry rows is exercised against a legacy fixture, never a fresh registry
- `workaholic:implementation` / `policies/objective-documentation.md` — the arrears contract is stated where it is read, and the aggregate line is named as a record rather than a mechanism

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` (lines 280-368) — the drain. Its candidate set is `log-read.sh --step-prefix human-checkin-held` and nothing else; the registry is read at line 291 **only** to resolve a slug to its preimage, so a `candidate` row no log line names is invisible here.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` (lines 154-163) — the one registration seam, called by the **agent** per key. Its absence for a key is exactly why `blocked-tick:20260904-085918` has no row.
- `plugins/workaholic/skills/moderate/scripts/reconcile-questions.sh` (lines 30-73) — already takes `{tick, run:{steps:[]}, answers:[]}` and walks the run report once per tick; the natural and only existing home for a mechanical registration.
- `plugins/workaholic/skills/moderate/scripts/question-registry.sh` (lines 47-71) — the `register` event: idempotent, merges only `step`/`coordinate`/`subject`, a no-op over an `answered` or `retired` row. No new event is needed for the persistence half.
- `plugins/workaholic/skills/moderate/scripts/question-liveness.sh` (lines 112-113) — `--step` selects the row whose `needs_agent` is searched; `step_not_in_run` is the honest `unknown` for a step that did not run this tick, and must stay that.
- `plugins/workaholic/skills/moderate/scripts/step-blocked-tick.sh` (lines 120-122) — *the tick before last*, the window whose movement drops the key. **Not widened by this ticket**; its header defends the structural bound against a tunable threshold.
- `plugins/workaholic/skills/moderate/scripts/question-state.sh` — the registry-first reader every consumer sees; unchanged, and the assertion that an answered/retired key is never re-asked stays its job.
- `plugins/workaholic/skills/moderate/reference/question-lifecycle.md` (items 1, 4, 5 and the closing paragraph on draining oldest-held first) — the prose home of the rule being changed.
- `plugins/workaholic/skills/moderate/reference/workflow.md` (§33 `human-checkin`, and the `unanswered-asks` / `blocked-tick` rows of the classification table at lines 2673-2674) — the step contract that states the arrears mechanism.
- `plugins/workaholic/commands/moderate.md` — the tick body that invokes the reconcile before questions are offered, and instructs the agent's per-key ask and held recording.
- `scripts/test-workflow-scripts.mjs` (the `question-liveness` rows near line 30150 and the check-in rows near line 30783) — where the hermetic assertions go.
- `scripts/tests/agentic-loop/repair-contracts.test.mjs` — the registry's contract rows, already exercising `candidate`/`answered`/`retired` transitions.

## Related History

The durable registry exists precisely because the operational log is clone-local, git-ignored
and pruned by nobody but the operator, so a question's identity had to outlive it. It was given
the preimages and the answers and **not** the enumeration: the arrears still ride the log lines
the agent writes, which is the half that failed here. #1200 established the direction one layer
up — a question leaves the open set only on a positive reading — and this closes the other end
of the same pipe.

- [20260918080734-retire-a-check-in-question-only-on-a-positive-reading.md](.workaholic/tickets/archive/work-20260918-081459/20260918080734-retire-a-check-in-question-only-on-a-positive-reading.md) — PR #1200: retirement now needs `resolution == "proved"`, and its `reinstate` event is the model for a bounded registry repair (direct sibling)
- [20260822155250-read-whether-an-asked-question-s-subject-is-still-live.md](.workaholic/tickets/archive/work-20260823-141725/20260822155250-read-whether-an-asked-question-s-subject-is-still-live.md) — introduced `question-liveness.sh`, its three words and the `--step` argument this ticket makes load-bearing
- [20260907063154-scope-the-tick-log-s-one-reader-so-the-loop-s-finish-lines-stop-shadowing-moderation.md](.workaholic/tickets/archive/work-20260907-064247/20260907063154-scope-the-tick-log-s-one-reader-so-the-loop-s-finish-lines-stop-shadowing-moderation.md) — the last repair of a reader whose window silently answered about the wrong tick
- [20260908123303-ask-mature-blockers-in-slack-and-record-the-answer.md](.workaholic/tickets/archive/work-20260908-175401/20260908123303-ask-mature-blockers-in-slack-and-record-the-answer.md) — the asked-once ledger's rule that a withheld question must not spend a ledger line

## Implementation Steps

1. **Reproduce and localize before changing anything.** In a throwaway repository, seed the
   registry with a `candidate` row whose producing step is not in the run report, write **no**
   `human-checkin-held-*` line for it, and record that `step-human-checkin.sh` reports
   `held_count: 0` / `delivery: no_candidates` while the row sits in the registry untouched —
   the question is open, askable by contract, and offered to nobody. Then confirm the live
   readings in this checkout: the single 09-17 `questions-held` line naming four keys, the one
   per-key held line among them, the three registry rows, and the absence of
   `blocked-tick:20260904-085918`. Keep all of it as the regression's starting point.

2. **Make the registry complete without depending on the agent, in the seam that already walks
   the run report.** `reconcile-questions.sh` registers every question key the run report
   carries: for each step row, every string at `.needs_agent[]? | .. | objects | .key` (the
   field the steps already emit — `blocked-tick`, `drill-health`, `operator-pulls`,
   `raced-units` and the rest name it explicitly), through the **existing** `register` event
   with `step` set to the **row's own step id**. It is idempotent, it is a no-op over an
   `answered` or `retired` row, and it writes no new field. Report one result row per key
   (`registered` / `already_known` / `skipped:<state>`), because a seam that names a candidate
   and reports no outcome for it is non-conformant on its face.
   - This repairs the measured `step: direction-health`-for-every-key rows as a by-product:
     `register` merges the provided `step`, and the producing step is the one
     `question-liveness.sh` must read.
   - A step row whose `needs_agent` carries **no** `key` field yields nothing and is counted;
     never guess a key from a summary, and never fabricate one from a log slug
     (`reference/question-lifecycle.md`, closing paragraph).

3. **Add a first-seen reading to the row, written once.** `register` sets `first_seen` on
   **creation only** and never overwrites it (the `+` merge must not move it on a later
   register), in the `YYYY-MM-DD` form the drain's ordering already compares. A legacy row
   carries none, and that is `unknown` — never the tick's own day, which reads as *this just
   started*, the most reassuring thing the field can say for a reading nobody made
   (`step-human-checkin.sh`'s own null rule).

4. **Enumerate the drain's arrears from the registry, unioned with the log.**
   `step-human-checkin.sh` takes the union of (a) the `human-checkin-held-*` slugs it reads
   today and (b) every registry row in state `candidate` or `asked`, deduped on the **content
   key** (the log side already resolves to one through `lib/question-id.sh`, which stays the one
   derivation). Every existing exclusion holds unchanged: a key with an `human-checkin-ask-*`
   line drops out, `answered` and `retired` rows are skipped, and the per-candidate
   `ask-question.sh` probe still supplies each entry's refusal word verbatim.
   - **Order stays total and re-entrant**: dated entries oldest-first on `(first_seen | held
     day, tick, key)` exactly as today, then the undated ones by key. `held_oldest_day` /
     `held_days` are computed over the dated entries only and stay **null** when none is dated.
   - Each entry carries **`source`** (`log` | `registry` | `both`) and **`first_seen`**
     (a day or `null`), and the step's JSON carries `arrears_registry_only` — the count the
     measured incident would have rendered as 3.
   - `max_per_tick` is still `ask-question.sh`'s, per candidate; this step orders and does not
     cap.

5. **Say it where it is read.** Update `reference/question-lifecycle.md` (the registry is the
   durable record of a raised question, and the drain enumerates from it), `reference/workflow.md`'s
   `human-checkin` section (the new fields, the union, the order, and that an aggregate
   `questions-held` line is a **human record and never the mechanism**), and
   `commands/moderate.md` (the reconcile registers the tick's candidates before any question is
   offered). An outdated document is a defect in the same change (`CLAUDE.md`).

6. **Extend the suites**, including the legacy registry (see *Quality Gate*). Keep every
   existing check-in and liveness row byte-identical in behaviour: this ticket adds a candidate
   source and changes no gate, no cap, no window and no refusal word.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A registry row in state `candidate` whose producing step is **absent from the run report**,
  and for which **no** `human-checkin-held-*` log line exists, is offered by
  `step-human-checkin.sh` with `source: "registry"`, and is counted in `held_count` and in
  `arrears_registry_only`.
- The same row's gate probe word is the gate's own, verbatim (`quiet_hours` under a quiet hour),
  and the question is therefore **held, not asked** — held is still not dropped.
- `reconcile-questions.sh` over a run report in which `blocked-tick` raises
  `key: "blocked-tick:<id>"` creates a `candidate` row for that key with `step: "blocked-tick"`;
  a second run over the same report changes the record not at all; an `answered` row and a
  `retired` row named by the same report come out byte-identical.
- A run report whose `needs_agent` carries no `key` field produces **no** row and is counted; no
  key is ever derived from a summary, a slug or a legacy log line.
- `first_seen` is written on creation and is **not** moved by a later `register` for the same
  key; a row without it sorts into the undated group and reports `first_seen: null`, never the
  tick's day.
- Ordering is unchanged for the log-derived set alone (same fixture, byte-identical sequence),
  total over the union, and identical on a re-entered tick.
- Nothing about the gates moves: `ask-question.sh` is untouched — the per-tick cap, the day cap,
  the quiet-hours and working-day holds, `already_asked`, `answered`, `premise_resolved` and the
  one bounded re-ask are byte-identical, and an `answered` or `retired` row is never offered.
- `question-liveness.sh` answers `unknown` / `step_not_in_run` for an offered row whose
  producing step did not run this tick, and `reconcile-questions.sh` therefore retires nothing
  on it (#1200's rule, unchanged and explicitly re-asserted by a test — a step that did not run
  must never look like a step that resolved the key).
- **Legacy upgrade** — a registry seeded **before the new code runs**, at
  `.git/workaholic/runtime/v1/instances/questions` inside a throwaway repository, with
  `schema_version: 1` and `revision` greater than 1, holding rows in the shapes this checkout
  actually carries:
  1. `{"blocked-tick:20260904-085918": {"state": "candidate", "step": "direction-health"}}` —
     the measured shape: no `first_seen`, and a `step` that is **not** the producing step;
  2. a `candidate` row whose producing step does raise it this tick;
  3. an `answered` row and a `retired` row;
  4. and, in the log beside it, the three measured legacy slugs with no recoverable preimage
     (`direction-expiring-an-au-16258524`, `stranded-unit-retire-a-c-731715597`,
     `stuck-634714808-3638566254`).
  Assertions: row 1 is offered with `source: "registry"` and `first_seen: null`; row 2 is
  offered once, not twice; rows 3 are never offered; each unrecoverable slug still reads
  `question_identity_unavailable` and **no key is fabricated for it**; one pass writes at most
  what it must and a second pass is a no-op on the record.
- `layout-doctor.sh` conforming; `outputs/` regenerated with no diff.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — green, with new rows for the registry-sourced
  arrear, the ordering union, the `key`-less report, the `first_seen` write-once rule and the
  `step_not_in_run` non-retirement; every existing check-in, liveness and `ask-question.sh` row
  unchanged.
- `node --test scripts/tests/agentic-loop/*.test.mjs` — green, with the registration contract
  added to `repair-contracts.test.mjs` beside its existing rows.
- **The legacy fixture is a seeded registry record written before the new code runs**, exactly
  as listed above. **A registry created empty and then driven by the new code is not evidence
  for this upgrade** (`plugins/workaholic/rules/general.md`, *A tightened constraint over
  persisted data is verified against legacy rows*): the registry is clone-local runtime state
  under the Git common directory, so no pull request can carry a migration to it and every
  checkout meets the new code holding rows the old code wrote — rows with no `first_seen` and
  with a `step` field naming the wrong step are the normal state, not the exception.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`;
  `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` → no diff.
- A local re-run of the drain against this checkout's live registry, reported in the story: the
  three rows it holds are offered in a stated order with their sources, and nothing is asked
  outside the speaking window.

**Gate** — what must pass before approval:

- Both suites green; `outputs/` clean; layout conforming; every new script path POSIX `sh`
  (`#!/bin/sh -eu`) and every embedded jq program compiling under the suite's own row.
- The three prose surfaces in step 5 updated in the same commit as the code.
- No new store, no new script, no second candidate ledger, and no widening of
  `step-blocked-tick.sh`'s window.
- `Decided: the question persists in the registry and the drain enumerates it from there, rather than only reporting the disappearance — a report of a lost question is still a lost question, and the registry already survives the log it would have to replace (developer may override at /drive).`
- `Decided: the registration is mechanical, in reconcile-questions.sh, rather than a stricter instruction to the agent — the measured incident is precisely an agent that wrote one per-key line out of four, and a rule an unattended run can skip silently is not a rule (developer may override at /drive).`
- `Decided: an unasked candidate stays offered until it is asked once, which will ask a question whose premise resolved before anybody heard it — accepted, and the cost is stated: asking once beats extinguishing a raised question, which is #1200's own ruling one layer up (developer may override at /drive).`
- `Decided: hermetic suites plus one local read of this checkout's registry — the change is script-internal, needs no credential, device or account, and the one live reading is reproduced as a fixture; no verification_handoff is declared (developer may override at /drive).`
- `Decided: merge_policy left empty, which reads review — this changes what the loop considers an open question, and the conservative default is right for that (developer may override at /drive).`

## Considerations

- **`step-blocked-tick.sh`'s window is not widened.** Its header defends *the tick before last*
  as a structural bound chosen over a tunable threshold, and the 09-04 key was a legitimate
  candidate only because a 13-day log gap made a fortnight-old tick the second-newest. Making
  the step remember its own past candidates would give it a store and a second notion of which
  tick it is talking about (`plugins/workaholic/skills/moderate/scripts/step-blocked-tick.sh`
  lines 120-134).
- **Rejected: fix it by instructing the agent to write a per-key held line for every held
  question.** That is what the contract already says, and the measured tick wrote one line out
  of four; a mechanism an unattended run can omit without anything noticing is the failure mode
  this ticket exists to remove (`.workaholic/moderations/2026-09-17.md` lines 53, 95).
- **Rejected: have the check-in step re-invoke the earlier steps to recover their candidates.**
  It is extra clock and network in a container nobody is watching, and it re-reads steps whose
  windows move between invocations — the defect twice, once per reading
  (`plugins/workaholic/skills/moderate/reference/workflow.md`, *What the planned run guarantees
  around the steps*).
- **The aggregate `questions-held` line stays.** It is a good human record and the ticket does
  not remove it; what changes is that nothing depends on it. Say that in the prose rather than
  leaving a reader to assume the line is load-bearing
  (`.workaholic/moderations/2026-09-17.md` line 53).
- **Evidence, not scope: three legacy slugs are stuck at `question_identity_unavailable`** —
  `direction-expiring-an-au-16258524`, `stranded-unit-retire-a-c-731715597`,
  `stuck-634714808-3638566254`, each held on 2026-09-02 before the registry existed and each
  named in every later tick with no recoverable key. That is the same information loss already
  realised, it is why the fixture carries them, and **no key may be fabricated to clear them**
  (`plugins/workaholic/skills/moderate/reference/question-lifecycle.md`, closing paragraph).
- **The cost of registering every candidate key is stated**: up to one revision-checked registry
  write per newly seen key per tick, on a record the tick already reads and writes, bounded by
  the run's own candidate set — four keys on the measured tick. No network, no second store
  (`plugins/workaholic/skills/moderate/scripts/question-registry.sh` lines 26-84).
- **`question-state.sh`'s consumers are untouched.** The reader answers per key and this ticket
  adds no state word; what it changes is who enumerates the open set
  (`plugins/workaholic/skills/moderate/scripts/question-state.sh`).
- **Adjacent, deliberately out of scope**: the queued ticket
  `20260917174439-prove-the-declared-slack-transport-before-retiring-delivery-incidents.md`
  works the delivery half of the same incident — proving the declared Slack route. This ticket
  touches no transport script: an undeliverable question is the input it assumes, not the
  problem it solves.

## Final Report

Development completed as planned. The registry now persists a raised question independently of
its step's window, the drain enumerates from it, and the upgrade path was exercised against a
seeded legacy registry rather than a fresh one.

**Reproduced first.** In a throwaway repository, a registry seeded with the measured row
(`{"blocked-tick:20260904-085918": {"state": "candidate", "step": "direction-health"}}`,
`revision: 7`) and **no** `human-checkin-held-*` line answered:

```
{"status":"ok","held_count":0,"held":[],"delivery":"no_candidates","candidates":0}
```

— the row open in the registry, askable by contract, offered to nobody.

**The live readings confirmed, all four.** This checkout's registry holds exactly three rows,
every one `state: candidate`, `first_seen: null` and **`step: direction-health`** — including
`blocked-tick:20260917-211754`, whose producing step is `blocked-tick`. `2026-09-17.md` line 53
is the single `questions-held` line naming four keys; exactly one per-key held line exists on
that day (`human-checkin-held-inbound-channel-unreadab-3989672039`); and
`blocked-tick:20260904-085918` is absent from the registry.

**After the change**, the same reproduction offers the row with `source: "registry"`,
`first_seen: null`, counted in `held_count` and `arrears_registry_only`, and held with the gate's
own word (`quiet_hours` under a quiet hour). `step-blocked-tick.sh` is byte-identical.

**The legacy upgrade fixture** (planted before the new code ran; `revision: 22`, no `first_seen`
anywhere, a `step` naming a step that never raised the key, a row with no `key` field, an
`answered` row, a `retired` row, and the three unrecoverable slugs in the log beside it) reads:
row 1 offered `source: "registry"` / `first_seen: null`; the answered and retired rows never
offered and byte-identical to the seed; each unrecoverable slug still
`question_identity_unavailable` with **no key fabricated**; and a second pass a no-op on the
record, revision included.

### Discovered Insights

- **Insight**: `question-registry.sh`'s `list` returned the values array and dropped each row's
  **map key**, which is the row's identity. Every row the current code writes carries `key`
  inside it too — so the gap was invisible until a legacy row was read, and
  `reconcile-questions.sh` then reported an outcome for a question named by the literal string
  `"null"`. Found only because the fixture was seeded in the shape the old code actually wrote.
  **Context**: this is exactly what *a tightened reading over persisted data is verified against
  legacy rows* buys. A fresh registry would have passed every assertion, because the new code
  never writes a row without a `key`.
- **Insight**: an unconditional `register` per raised key per tick bumps the record's `revision`
  on a `questions` map that is byte-identical, so *idempotent* has to mean *writes nothing*, not
  *converges*. The write is now conditioned on there being something to change — a newly seen
  key, or a row whose `step` names a step that never raised it, which is the measured
  `step: direction-health`-for-every-key shape and is corrected once and then never again.
  **Context**: the ticket stated the cost as "one write per **newly seen** key per tick"; the
  obvious implementation spends one per **raised** key per tick, forever, and races every other
  writer for nothing.
- **Insight**: the drain's ordering had to move from walk-order string accumulation to one sort
  over the union, because a registry-only entry interleaves by date with the log's entries rather
  than appending after them. A log entry keeps its **held day** as its sort date and a
  registry-only entry takes its `first_seen` — which is what makes the log-derived set's sequence
  byte-identical to what it was, since the held day *is* the first-seen reading on that side.
  **Context**: reading the ticket's `(first_seen | held day, tick, key)` as *first_seen wins
  everywhere* would have reordered existing fixtures the acceptance criteria require unchanged.
