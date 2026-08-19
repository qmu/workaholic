---
created_at: 2026-08-19T06:20:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260819061902-fix-the-housekeep-check-in-s-already-asked-gate.md]
merge_policy:
verification_handoff: 
claim: work-20260819-063001
---

# Fix the housekeep check-in's already-asked gate

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it from a
     proposal into queued work. -->

`/housekeep`'s check-in claims a **mechanical** already-asked gate — `ask-question.sh`'s
own header states that whether a question may be asked "again, or at all this tick is
mechanical, and mechanical is what a five-questions-an-hour ceiling needs, because a model
asked to police its own volume will do it inconsistently". The reporter measured that the
gate does not hold: tick `20260819-045108` asked `ask:issue-524-unassigned-never-ingested`,
and one hour later the same key answered `{"ask": true, ..., "asked_today": 3}` while the
question still sat unanswered in `#dev-workaholic`. Only the prose contract
(`housekeep/reference/workflow.md` §9, "An unanswered question is never re-posted") stopped
the repost, and `day_cap` (10) is the only mechanical backstop left — ten copies of one
question a day at five questions a tick.

The ask is to make the gate do what the contract says it does. It is scoped to that gate;
the `❓` post shape, the quiet-hours gate, the caps and §9's contract are untouched.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — the tick log is the loop's memory; a dedup that reads it wrongly is unobservable until it nags
- `workaholic:implementation` / `policies/test.md` — the regression that keeps a gate documented as mechanical from silently becoming caller discipline again
- `workaholic:implementation` / `policies/command-scripts.md` — the gate is a POSIX skill script with a JSON envelope

## Key Files

- `plugins/workaholic/skills/housekeep/scripts/ask-question.sh` — the gate. `SLUG` is
  `cut -c1-32`; `LOG_STEP="human-checkin-ask-${SLUG}"`; the gate is
  `already=$(count_log_prefix human-checkin-ask "$KEY")`, which passes the **key** as
  `--contains`.
- `plugins/workaholic/skills/housekeep/scripts/log-read.sh` — the reader. Its header states
  `--contains` is "a plain substring match over the **summary**"; the awk confirms
  `index(summary, needle)`. It **already carries `--step <slug>`, an exact step-id
  match** (`if (want_step != "" && step != want_step) next`) alongside `--step-prefix`.
- `plugins/workaholic/skills/housekeep/scripts/step-human-checkin.sh` — the caller; its
  `NEEDS` envelope tells the agent to run the gate per question and record under the
  returned `log_step`.
- `plugins/workaholic/skills/housekeep/scripts/log-append.sh` — the only writer; what the
  agent records the step id under.
- `scripts/test-workflow-scripts.mjs` — already exercises `ask-question.sh` (the `ASK`
  block); the regression belongs beside it.
- `plugins/workaholic/skills/housekeep/reference/workflow.md` §9 and
  `plugins/workaholic/skills/housekeep/SKILL.md` — the prose that describes this gate;
  update in the same change if the behaviour's description moves.

## Implementation Steps

1. **Reproduce the miss before changing anything.** In a throwaway tree, write one
   `.workaholic/housekeeping/<day>.md` entry through `log-append.sh` for a long key (>32
   characters) with an agent-composed summary that does **not** contain the raw key, then
   run `ask-question.sh --tick <a later tick> --key <the same key>` and record that it
   answers `ask: true`. Repeat with a short key and a summary that happens to contain it,
   and record that it answers `already_asked` — the pass is what shows the gate is
   wording-dependent rather than mechanical.
2. **Localize both causes against that reproduction**, separately: (a) the `--contains`
   needle is matched against the summary, so the gate's answer is a property of the
   agent's wording; (b) `cut -c1-32` truncates `SLUG`, so for a long key the step id does
   not contain its own key even if the match had been over the step id. Confirm each by
   varying one input at a time.
3. **Decide the query the gate should make**, from what `log-read.sh` already offers —
   `--step` is an exact step-id match and needs no new flag (see Considerations). Whatever
   is chosen, the write side and the read side must derive the step id from the key by the
   **same** code path, so that the match is an identity rather than a search over prose.
4. **Handle the truncation's remaining consequence**, which the reproduction in step 1
   makes visible: two keys sharing a 32-character prefix collide into one step id, so an
   identity match would suppress a question that was never asked. Add a length check or a
   short digest suffix so distinct keys keep distinct step ids; keep the id readable.
5. **Re-run the step-1 reproduction** and record that the long-key case now answers
   `already_asked` and the two-keys-sharing-a-prefix case does not.
6. **Add the regression to `scripts/test-workflow-scripts.mjs`**, beside the existing
   `ASK` block: a long key asked in one tick is `already_asked` in a later tick regardless
   of the summary's wording, and two keys sharing a 32-character prefix stay independent.
   Hermetic — a throwaway tree, no `gh`, no network.
7. **Update the prose in the same change** if the gate's description moves — the
   `ask-question.sh` header's four-gates block, `housekeep/reference/workflow.md` §9,
   `SKILL.md` — and `node scripts/build-plugins/build.mjs` to regenerate `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A question key asked in an earlier tick answers `{"ask": false, "reason":
  "already_asked"}` in a later tick **whatever the recorded summary says**, including a key
  longer than 32 characters.
- Two distinct keys sharing a 32-character prefix are not conflated: asking the first does
  not suppress the second.
- A key never asked still answers `ask: true` — the gate did not become a blanket refusal.
- `already_asked` is decided by a step-id identity derived from the key by one code path on
  both the write and the read side, not by a substring search over agent-composed prose.

**Verification method** — the commands/tests/probes that prove them:

- The step-1 reproduction, re-run: same commands, both cases recorded before and after.
- `node scripts/test-workflow-scripts.mjs` — the new regression plus the existing suite.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` —
  `outputs/` regenerated and self-contained.

**Gate** — what must pass before approval:

- The reproduction is recorded as failing **before** the fix and passing after; a fix
  landed without that record does not satisfy this ticket.
- The full hermetic suite passes; `outputs/` shows no drift.
- No change to the `❓` post shape, the quiet-hours gate, `tick_cap`/`day_cap`'s values, or
  §9's never-re-post contract.

## Considerations

- **The reporter's suggested direction is a hypothesis, and discovery found most of it
  already built.** The ask proposes giving `log-read.sh` an exact step-id query and having
  `ask-question.sh` query its own `LOG_STEP`. `log-read.sh` **already has** that query —
  `--step <slug>`, matched exactly against the step id — so the change may reduce to one
  caller line (`--step "$LOG_STEP"` in place of `--step-prefix human-checkin-ask --contains
  "$KEY"`). Confirm this against the reproduction rather than assuming it; the step-1
  measurement is what decides.
- **The reporter's two rejected alternatives are recorded and not re-litigated here**:
  widening `--contains` to match the step id (fixes cause 1 only, and changes a reader
  every step's dedup shares for one caller's benefit), and lengthening `cut -c1-32` (fixes
  cause 2 only, to whatever the new bound is).
- **`asked_today` and `day_cap` count across every day file in the log area**, not across
  today — `count_log_prefix human-checkin-ask ""` passes no `--since` and no `--tick`, so
  the "10 per day" backstop is in fact an all-time ceiling that tightens as the log grows.
  Observed during discovery; **not** part of this ask, and left to a separate ticket unless
  the driver finds it blocks an acceptance criterion above. Report it either way.
- **Do not widen the gate into a judgment.** What is worth asking stays the agent's call
  under the Recommended-label test; this ticket only makes the *was it already asked*
  half mechanical, which is what the script's own header already claims.

## Final Report

Development completed as planned, reproduction-first.

### Step 1 — the miss, reproduced before anything changed

In a throwaway tree, three probes against the shipped script (`ask-question.sh` before the fix):

- A **long key** (`issue-524-unassigned-never-ingested`, 35 characters) logged in an earlier tick
  under `human-checkin-ask-issue-524-unassigned-never-inges`, with the agent-style summary
  *"asked whether the unassigned issue should be ingested"* → a later tick answered
  `{"ask": true, ..., "asked_today": 2}`. **The reporter's measurement, reproduced.**
- A **short key** (`issue-99`) whose summary happened to read *"asked about issue-99 directly"* →
  `already_asked`. Same script, same log, opposite answer, decided by wording alone — which is
  what shows the gate was not mechanical.
- A **distinct key sharing the same 32-character prefix** → the *same* `log_step`
  (`human-checkin-ask-issue-524-unassigned-never-inges`), the collision step 4 warned about.

### Step 2 — the two causes, each confirmed by varying one input

- **(a) The needle was matched against the summary.** `already=$(count_log_prefix
  human-checkin-ask "$KEY")` passes the key as `--contains`, and `log-read.sh`'s awk is
  `index(summary, needle)`. Holding the key fixed and changing only the summary flips the answer
  (probes 1 and 2).
- **(b) `cut -c1-32` truncated the slug.** Holding the summary fixed and changing only the key's
  length changes whether the step id contains its own key, and two long keys collapse to one id
  (probe 3).

### Step 3 — the query, and step 4's remaining consequence

`log-read.sh` already had the exact-step-id query the reporter proposed (`--step`, matched with
`if (want_step != "" && step != want_step) next`), so **no reader changed** — the ticket's
Considerations predicted this and the reproduction confirmed it. The gate now calls
`count_log_step "$LOG_STEP"`; the write side records under the same `log_step` the script returns
(`step-human-checkin.sh`'s `NEEDS` envelope), so the match is an identity through one code path.

Truncation's remaining consequence is answered with a **digest suffix, not a longer bound**: the id
keeps a readable 22-character slug and gains `cksum` of the **full key** *only when the truncation
actually happened*, so a short key's id does not move at all and two long keys keep distinct ids.
Lengthening `cut` was the alternative the reporter already rejected, and it only moves the
collision to a new bound.

**One thing the ticket did not ask for and the reproduction demanded**: entries written before the
digest existed sit under the plain 32-character truncation, so an identity match alone would have
asked the reporter's own measured question exactly one more time on the way to fixing it. A
**bounded legacy tolerance** matches the old id when — and only when — truncation occurred. It
reintroduces the prefix collision for pre-existing entries alone, strictly smaller than the
collision that existed everywhere before, and it is commented as a branch to delete once no live
log carries a truncated id.

### Step 5 — the reproduction, re-run

- Legacy log, the reporter's exact case → `already_asked`.
- Fresh log, summary containing nothing of the key → `already_asked`.
- Distinct key sharing a 32-character prefix → `ask: true`, with its own `log_step`.
- A key merely mentioned in an unrelated entry's prose → `ask: true` (the inverse miss closed).
- A never-asked key → `ask: true` (the gate did not become a blanket refusal).

### Reported, not fixed — the `day_cap` observation

The ticket's Considerations flagged that `asked_today` counts across **every** day file in the log
area, not across today: `count_log_prefix human-checkin-ask` passes no `--since` and no `--tick`,
so the "10 per day" backstop is an all-time ceiling that tightens as the log grows. **Confirmed
still true after this change** — the volume gates were left exactly as they were, because they are
not this ask and because narrowing them would change how many questions a tick may ask, which is
the developer's dial. It did not block any acceptance criterion here (the regression passes
`--max-per-day 99` for the same reason the existing block does). Reported as the ticket required;
it needs its own ticket.

### Discovered Insights

- **Insight**: the two bugs were independent and each alone would have looked fixed. Matching the
  step id without the digest suffix would have suppressed unrelated questions sharing a prefix;
  adding the digest without moving off `--contains` would have left the gate wording-dependent.
  **Context**: the ticket's step 2 asked for them to be confirmed *separately, one input at a
  time*, and that is what made both visible — a single end-to-end "does the gate hold" probe
  passes or fails without telling you which half is wrong.
- **Insight**: a dedup keyed on an agent-composed summary is unobservable until it nags. Nothing
  errored, no test failed, and the only thing that surfaced it was a human noticing the same
  question twice in a channel.
  **Context**: when a script's header claims a decision is "mechanical", the test for that claim is
  whether varying the *prose* can change the answer — and that is now a regression rather than a
  reading.
