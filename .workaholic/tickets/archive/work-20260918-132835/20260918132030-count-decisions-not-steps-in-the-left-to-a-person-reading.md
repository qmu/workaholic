---
created_at: 2026-09-18T13:20:30+09:00
status: done
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
claim: work-20260918-132835
---

# Count decisions, not steps, in the left-to-a-person reading

## Overview

`file-findings` reports how much of a tick's debt is **left to a person**, and the number is a
count of **steps** rather than of things anybody must decide — with no member named anywhere.
`step-file-findings.sh` derives it as the count of step rows the classification table does not
call `repairable` which either supplied an `event` or reported `degraded`/`blocked`. A step that
produces no finding at all therefore enters the count as long as it has something to say.

**Measured.** Four consecutive `/moderate` ticks reported `file-findings: ok — no repairable
finding this tick; N left to a person` with N as 2, 2, 3 and 3, and named none of them.
Enumerated by hand on the 2026-09-18 04:07 tick, the three were:

```
issue-triage      21 open, 10 never ingested        — a real needs_ruling decision
direction-health  direction-arrived group           — a real decision
strategy-digest   morning digest ready … 1 strategy — a render
```

`strategy-digest` is `ok` and supplies an event by design — the digest **is** its output — and
the classification table's own row for it reads *A render; it produces no finding to file.* It
waits on nobody. So the honest reading of that hour is **two decisions plus one render**, while a
reader of the count takes it as three things a person must answer, and has no way to find out
which three: `left` is a count and the members are nowhere in the step's output.

The defect is narrow and is exactly that: **a count mixes decisions with renders and names none
of its members.** The step's filing behaviour, its brake, its dedup, its `needs_agent` payload
and the `repairable` set are all correct and are not touched.

**The fork is closed here, not deferred:** the fix is **both** halves — render-class steps leave
the count, and the members are named beside it — because either alone leaves the reader where
they were. Excluding the render without naming the members still gives a bare number nobody can
follow; naming the members without excluding the render still tells a person three things are
owed when two are. Do not write an `## Open Decisions` section for it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `sh`, one derivation per fact (all code work)
- `workaholic:implementation` / `policies/type-driven-design.md` — the classification is a closed set of words; a third value is added to the one table rather than inferred at a call site
- `workaholic:implementation` / `policies/objective-documentation.md` — a reported number states what it counts, and its members are followable
- `workaholic:implementation` / `policies/observability.md` — a degraded step stays counted whatever its class, so a broken render cannot hide behind its own exemption
- `workaholic:implementation` / `policies/test.md` — the classification pin fails in both directions, and the new word is exercised rather than assumed

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` (lines 90-96, 119-132) — the `repairable` extraction out of the table, and the `left` derivation: every non-repairable step row with an `event` or a `degraded`/`blocked` status, as a count.
- `plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` (lines 68-85) — the header's standing rule that `filed`, `held` and `left` must never render alike, and that `left` is *a COUNT, never a list*; the reason given is the root addressed to nobody, which is why the members go in the step's own JSON and summary and **not** on the root.
- `plugins/workaholic/skills/moderate/reference/workflow.md` (lines 2617-2692) — *Repairable, or needing a ruling*: the one home of the classification, its stated default, and `strategy-digest`'s row at line 2671.
- `plugins/workaholic/skills/moderate/reference/workflow.md` (lines 2513-2565) — the `file-findings` contract stating what counts as a finding and what `left` is.
- `scripts/test-workflow-scripts.mjs` (lines 35625-35675, `testFindingClassification`) — the pin: the row regex at line 35639 accepts `repairable|needs_ruling` only, the table is asserted against `moderateSteps()` in both directions, and lines 35666-35673 ban a step id sitting beside a classification word inside any moderate script.
- `scripts/test-workflow-scripts.mjs` (lines 35691-35760, `testFileFindingsStep`) — the behavioural fixture: one repairable step with an event, one repairable degraded, one repairable quiet, one `needs_ruling` shouting. It has no render-class row yet.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — `STEPS`, the whole domain the table is pinned against; unchanged.

## Related History

`left` was introduced with the three-outcome split whose whole point was that *filed*, *held* and
*left* must never render alike — and it was given a count with no members deliberately, so the
tick would not re-list findings that reach a person through their own questions. That reasoning
is about the **root**, which this step never renders a line on (its `event` is always empty); it
was read as a rule about every surface, and the run report and tick log inherited a number nobody
can follow. The classification table's default — an unclassified step is `needs_ruling` — is what
put a render in the count, since `needs_ruling` is *not repairable* and nothing finer existed.

- [20260829042145-report-what-was-filed-held-and-left.md](.workaholic/tickets/archive/work-20260829-044056/20260829042145-report-what-was-filed-held-and-left.md) — introduced `filed`/`held`/`left` and the three surfaces, including `left` as a count (direct predecessor)
- [20260829042145-dedup-the-filing-structurally-on-the-step-id.md](.workaholic/tickets/archive/work-20260829-044056/20260829042145-dedup-the-filing-structurally-on-the-step-id.md) — the step-id key this step's identity rests on, untouched here
- [20260901122448-say-what-the-tick-repairs-on-what-proof-and-who-does-the-rest.md](.workaholic/tickets/archive/work-20260901-123859/20260901122448-say-what-the-tick-repairs-on-what-proof-and-who-does-the-rest.md) — the last repair of a tick-facing number that did not say what it counted

## Implementation Steps

1. **Reproduce and localize before changing anything.** Drive `step-file-findings.sh` through a
   stubbed reports file holding the measured hour: `issue-triage` (`ok`, event),
   `direction-health` (`ok`, event), `strategy-digest` (`ok`, event) and no repairable candidate.
   Record that it answers `left: 3` with no member anywhere in its output, and that
   `strategy-digest` is in the count solely because the derivation counts every non-repairable
   step that supplied an event. Keep that reading as the regression's starting point.

2. **Add `render` as a third classification word in the one table**, in
   `reference/workflow.md`'s *Repairable, or needing a ruling* section — the table is the single
   home and no script may restate it. `strategy-digest`'s row moves from `needs_ruling` to
   **`render`**, keeping its existing *Why* text, which already states the ground exactly. State
   in the section's prose that:
   - `render` means *this step produces no finding to file and owes nobody a decision*; it is
     **not** repairable, so the filing gate is unchanged — only `repairable` may become work with
     no person asked;
   - the default for an unclassified step id is still `needs_ruling`, the safe side, unchanged;
   - a row moves to `render` only deliberately, one at a time. **This ticket moves exactly one**;
     every other row stays where it is.

3. **Make the count what its name says.** In `step-file-findings.sh`, derive the left-to-a-person
   count from the same table, over the non-repairable rows, as:
   - a row that supplied an `event` **and is not `render`-classified** — a finding awaiting a
     ruling; **plus**
   - any non-repairable row that reported `degraded` or `blocked`, **whatever its class** —
     our own machinery failing is the loop's debt, and a render that broke must not hide behind
     an exemption that exists for its findings and not for its failures.
   The `repairable` extraction, the candidate set, the brake, the dedup and every emitted reason
   word stay byte-identical. Read the new word out of the table exactly as `repairable` is read;
   add no classifier function and no second copy (`there is no classify.sh`).

4. **Name the members beside the count.** The step's JSON gains
   `left_steps: [{"step","status","reason"}]` — the rows the count is made of, in the reports
   file's own order — and its `summary` names those step ids. Both are safe and neither
   re-opens the *count, never a list* rule:
   - this step's `event` is **always empty**, so it renders **no root line** at all; the rule's
     stated reason is the root addressed to nobody, and the run report and tick log are read by a
     maintainer diagnosing the tick, which is the audience the measured hour left with nothing;
   - the summary stays **stable** — a function of the candidate set and the classification alone,
     with no timestamp, clock or moving count — so the root's hour-to-hour diff still suppresses
     an unchanged hour, which is the property `left` was written to preserve.
   Keep `left` as the count it is today (the name and the number's meaning change, the field does
   not move), and leave `held` and `already_filed` untouched.

5. **Update the prose in the same change** (`CLAUDE.md`, *Update the docs in the same change*):
   the `file-findings` contract in `reference/workflow.md` (what `left` counts and that its
   members are named in the step's own output), the classification section (the new word, its
   meaning and the unchanged default), and the step script's own header rule, which currently
   states *`left` as a COUNT, never a list* without naming the surface that rule is about.

6. **Extend the suite** (see *Quality Gate*), including the row regex, which accepts two words
   today and would silently drop every `render` row — a table row nothing parses is worse than no
   row, since the both-direction pin would then report the step as unclassified.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `render`-classified step reporting `ok` with a non-empty `event` is **not** in the
  left-to-a-person count, **not** a filing candidate, and **is** listed nowhere in `needs_agent`.
- A `render`-classified step reporting `degraded` or `blocked` **is** in the count and is named
  in `left_steps`.
- The measured hour's fixture (`issue-triage`, `direction-health`, `strategy-digest`, all `ok`
  with events, no repairable candidate) answers **2**, and `left_steps` names exactly
  `issue-triage` and `direction-health`.
- Every `needs_ruling` step with an event is still counted, and every `repairable` candidate
  still reaches `needs_agent` with its `finding_id`; `testFileFindingsStep`'s existing
  assertions pass unchanged, including *a needs_ruling finding never reaches the filer*.
- The summary names each counted step id and carries no timestamp, clock value or transport-
  derived term; two identical readings produce byte-identical summaries.
- The classification table parses **all three** words, classifies every `STEPS` entry exactly
  once, and classifies no step id `run.sh` does not name — the existing both-direction pin,
  extended rather than relaxed.
- The table still states its own default sentence — *An unclassified step id is `needs_ruling`* —
  and `strategy-digest` is the only row that moved.
- No moderate script carries a hand-copied classification row; there is still no `classify.sh`.
- `layout-doctor.sh` conforming; `outputs/` regenerated with no diff.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — green, with: the row regex at
  `testFindingClassification` widened to the three-word set; a new row asserting a `render` step
  with an event is neither counted nor filed while a `degraded` one is counted; and a new row
  over the measured three-step fixture asserting `left == 2` and the two named members. The
  script-copy ban at lines 35666-35673 is extended to the new word **only if it does not
  false-positive** — moderate scripts legitimately mention `render-tick-post.sh` on non-comment
  lines — and is otherwise keyed on the backticked classification token, with the choice stated
  in the test's comment.
- `sh scripts/e2e/loop-drill.sh verify-all` — the classified drill set green; no drill asserts
  the old count.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — `outputs/`
  regenerated with no diff (`Outputs Freshness` fails the merge otherwise).
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`.
- A local run of the step against this checkout's own latest reports file, quoted in the story:
  the count and the named members, beside the four measured tick lines it replaces.

**Gate** — what must pass before approval:

- Suite green; drills green; `outputs/` clean; layout conforming; POSIX `sh` throughout
  (`#!/bin/sh -eu`) and every embedded jq program compiling under the suite's own row.
- The three prose surfaces in step 5 updated in the same commit as the code.
- Exactly one table row moved, no step script changed except `step-file-findings.sh`, and no new
  script, store or field on any artifact.
- `Decided: both halves ship together — exclude the render class AND name the members. Either alone leaves a reader unable to act on the number, which is the whole defect (developer may override at /drive).`
- `Decided: the class is a third word in the existing classification table rather than a new marker, list or script — the table is already the one home keyed on the step id and is already pinned against STEPS in both directions, so a new home would be the second derivation that table exists to prevent (developer may override at /drive).`
- `Decided: a degraded or blocked step stays counted whatever its class — the exemption is about findings a render does not produce, not about a render that failed; exempting a broken render is how a silent degradation becomes invisible (developer may override at /drive).`
- `Decided: the members are named in the step's JSON and summary and NOT on the Slack root — this step's event is always empty, so no root line exists to lengthen, and the count-never-a-list rule is about the root addressed to nobody (developer may override at /drive).`
- `Decided: only strategy-digest moves to render in this ticket; any further row is a deliberate act of its own, and the default stays needs_ruling (developer may override at /drive).`
- `Decided: hermetic suite and drills only — the change is script and table internal, needs no credential, device or account, and no verification_handoff is declared (developer may override at /drive).`
- `Decided: merge_policy left empty, which reads review — this changes a number a person reads to decide what they owe (developer may override at /drive).`

## Considerations

- **`strategy-digest` keeps its `event`, and its step script is not touched.** The event is the
  digest itself and the root line it renders is the step's whole purpose; removing it to fix a
  count would trade a misleading number for a missing report, and it would change the root's
  change-diff behaviour, which is a different ask
  (`plugins/workaholic/skills/moderate/scripts/step-strategy-digest.sh`,
  `plugins/workaholic/skills/moderate/scripts/render-tick-post.sh`).
- **Rejected: name the members on the root instead of in the step's output.** The root is
  addressed to nobody and this repository has twice retired a post for exactly that; and this
  step supplies no event, so it has no root line to put them on
  (`plugins/workaholic/skills/moderate/scripts/step-file-findings.sh` lines 68-75).
- **Rejected: drop the `degraded`/`blocked` term from the count.** It would make the number
  purely *decisions owed*, at the cost of hiding the loop's own machinery failing in the one
  place that aggregates it; the impairment clause on the root covers a degraded step but says
  nothing about what remains owed (`plugins/workaholic/skills/moderate/reference/workflow.md`,
  *A refused action is reported, never silently skipped*).
- **The row regex is the sharp edge.** `testFindingClassification` matches
  `(repairable|needs_ruling)` and the both-direction pin then asserts every `STEPS` entry is
  classified: a `render` row added without widening the regex makes the suite report
  `strategy-digest` as unclassified rather than quietly passing — a loud failure, and the reason
  the regex is named in the steps rather than left to be discovered
  (`scripts/test-workflow-scripts.mjs` line 35639).
- **Whether any other row is really a render is deliberately not decided here.**
  `thread-reconcile`'s row already reads *its repair is the tick's own reply, already taken; it
  owes the queue nothing*, which is arguable — and arguing it is a separate act with its own
  evidence. The default stays `needs_ruling`, so leaving such a row where it is costs at most one
  over-count and never a lost finding
  (`plugins/workaholic/skills/moderate/reference/workflow.md` line 2665).
- **The filing gate is untouched, and that is the safety property.** Only `repairable` may become
  work with no person asked; `render` is not repairable, so no render can ever reach
  `file-inbound-ask.sh`. Assert it as a behaviour rather than a shape, as the existing test does
  for `needs_ruling` (`scripts/test-workflow-scripts.mjs` lines 35742-35746).

## Final Report

Development completed as planned. Both halves shipped together, exactly one classification row
moved, and the reproduction was recorded before anything changed.

**Reproduced first.** Driven against a stubbed reports file holding the measured hour
(`issue-triage`, `direction-health`, `strategy-digest`, all `ok` with events, no repairable
candidate), `step-file-findings.sh` answered:

```
{"reason": "no_candidates", "summary": "no repairable finding this tick; 3 left to a person",
 "left": 3, ...}
```

— no member anywhere in the output, and `strategy-digest` in the count solely because the
derivation counted every non-repairable step that supplied an event. After the change the same
fixture answers `left: 2`, `left_steps: [issue-triage, direction-health]`, and a summary naming
both.

**The row regex was the sharp edge, as the ticket predicted.** It accepted two words and is
pinned against `STEPS` in both directions, so the `render` row had to be parsed or
`strategy-digest` would have reported as unclassified.

### Discovered Insights

- **Insight**: the script-copy ban's word boundary was the real false-positive risk, not the
  word itself. `\brender\b` matches `render-tick-post.sh` and
  `render_the_morning_digest_at_the_top_of_the_root`, because `-` and `_` are non-word
  characters — so the ban would fire on any future line carrying one of those *and* a step id.
  Measured over every moderate script at the time of writing: **no line false-positives today**,
  so the word set was extended rather than moved to the backticked token (which no shell script
  would ever write, so keying on it would make the ban stop firing for the shape it guards).
  The boundary was tightened by one character instead — `-` joins the word characters on both
  sides, so only a standalone `render` counts.
  **Context**: the ticket offered two branches and said to state the choice; the third option
  (narrow the boundary) preserves the ban's strength for all three words and removes the
  fragility, and nothing in the tree relied on the wider match.
- **Insight**: `strategy-digest` already carried the right *Why* text — *A render; it produces no
  finding to file* — under the wrong classification, for two weeks. The table's stated default
  (`needs_ruling` for anything unclassified) is what put it there: `needs_ruling` is *not
  repairable*, which was the only distinction the count could read.
  **Context**: a row whose prose and whose classification disagree is the shape worth grepping
  for when a classification table gains a value.
