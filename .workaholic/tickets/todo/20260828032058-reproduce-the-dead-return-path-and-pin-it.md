---
created_at: 2026-08-28T03:20:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Reproduce the dead return path and pin it

## Overview

**PROPOSED.** The measurement first, as this direction's missions have done throughout.
Before anything is built, pin the current behaviour with a hermetic test that walks
question → thread reply → **nothing**, and that starts passing only once an answer
reaches a writer.

The claim to reproduce, not to assume: an answer typed into the `🔎 Moderation` thread
reaches no writer in this plugin. It is not a channel message, so `step-unanswered-asks.sh`
(which reads `WORKAHOLIC_INBOUND_SLACK_CHANNEL` over a window) never sees it, and the
`:40` inbound sweep excludes answers to the tick's own questions by rule
(`plugins/workaholic/skills/propose/SKILL.md`, *What is FB-worthy*). `record-answer.sh`
exists and is the only writer of the answered line, but nothing in `run.sh` or any step
calls it — its documented flow is the developer opening the session link and answering
inside the moderator's own session (`moderate/reference/workflow.md`, *A question has
three states*).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testable-boundaries.md` — the seam under test is the one that ships

## Key Files

- `scripts/test-workflow-scripts.mjs` — where the pin lives; the suite that already
  pins the ask → reader → scaffold → floor chain and the proofs-and-judgements tables.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — writes
  `human-checkin-ask-<slug>` through `log-append.sh`; the start of the walk.
- `plugins/workaholic/skills/moderate/scripts/record-answer.sh` — the one writer of the
  answered line; the end of the walk, currently unreached.
- `plugins/workaholic/skills/moderate/scripts/question-state.sh` — the reader; its only
  caller today is `ask-question.sh`'s gate.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the step list the walk must
  cross, and where the absence is provable.
- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` — the step that
  reads the channel and, by construction, not a question's own thread.

## Implementation Steps

**Diagnosis first — reproduce and localize before designing anything.**

1. **Reproduce the dead path.** Over a hermetic fixture repository, ask a question
   through `ask-question.sh`, then assert `question-state.sh` reads `asked`. Simulate the
   person's reply as a thread reply (fixture data, no network) and run the tick's step
   set. Assert the state is **still** `asked` — nothing recorded it.
2. **Localize the break.** Assert mechanically what the reproduction shows: that no
   script under `plugins/workaholic/skills/` other than the suite itself invokes
   `record-answer.sh`, and that `question-state.sh`'s only caller is `ask-question.sh`.
   These two assertions are what make "the words survive and nothing acts on them" a
   checkable fact rather than a reading of the prose.
3. **Pin the exclusion that keeps the sweep out of it**, so a later change cannot quietly
   route answers through the `:40` sweep instead: assert `propose/SKILL.md` still states
   that answers to the tick's own questions belong to `record-answer.sh`.
4. **Make the test fail forward.** Write the walk so it is one test with a named
   expectation that flips: today it asserts the state stays `asked`, and the ticket that
   wires the read changes that single expectation to `answered`. Leave the flip point
   commented by name so the later ticket does not have to find it.
5. **Record the measurement** in the test's own header — the four facts above, with the
   file and line each was read from, so a later reader can re-check rather than re-derive.

**Considerations, not step 1's design**: the ask proposes recording the coordinate on the
existing log line and reading one thread per outstanding question. That is the hypothesis
this ticket measures the need for; it is implemented by the tickets after it, not here.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A hermetic test walks ask → reply → state and asserts the answer reaches no writer.
- The two localization assertions hold: no step calls `record-answer.sh`, and
  `question-state.sh` has exactly one caller.
- The test names its flip point, so wiring the read is a one-expectation change.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — passes, with the new walk included.
- The walk creates its fixture under the OS temp dir, touches no working tree, and makes
  no `gh` or network call.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green.
- The test fails when `record-answer.sh` is wired into a step, proving it measures the
  gap rather than restating it.

## Considerations

- The reproduction must not depend on a live Slack connector. The reply is fixture data;
  what is under test is which script sees it, not the transport.
- Assertions on prose (step 3) are weaker than assertions on scripts and are labelled as
  such — they catch a rule being deleted, not a rule being misapplied.
