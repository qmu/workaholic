---
created_at: 2026-08-28T03:20:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Read the answer in a question's own thread

## Overview

**PROPOSED.** A step owns the mechanical half — which question keys are in state `asked`,
and each one's recorded coordinate — and hands the read back in `needs_agent`, because
**Slack is a connector held by the session and not by a script**. That split is not new
here: it is exactly what `step-inbound-sweep.sh` and `step-unanswered-asks.sh` already do,
and their headers record why (neither half is guessable from the other side).

The read is **one `slack_read_thread` per outstanding question, on a known coordinate**:
no search, no channel-history read, and `workaholic:notify`'s two-query bound untouched
because no query is made — the same case-1 property the sweep's receipt relies on.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/bounded-external-calls.md` — a per-candidate bound, named degradations

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` — the precedent
  for the mechanical/judgement split and for handing a Slack read back in `needs_agent`.
- `plugins/workaholic/skills/moderate/scripts/step-inbound-sweep.sh` — the same split,
  and the source of the "connector held by the session" rule.
- `plugins/workaholic/skills/moderate/scripts/question-state.sh` — the reader that names
  which keys are `asked`.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — how the step enumerates the
  ask lines and their coordinates.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — where the new step is registered
  and contributes its report line.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's contract.

## Implementation Steps

1. **Read the two precedent steps in full before writing anything** — the split, the
   `needs_agent` shape, the `event`/`summary` distinction and the named-degradation rule
   are all already decided there, and this step must not invent a second vocabulary.
2. **Derive the candidate set**: every question key whose state is `asked` (never
   `answered`, never `never_asked`) that has a recorded coordinate. A question in state
   `asked` with **no** coordinate is counted and named, not read and not dropped silently
   — the previous ticket makes that a real state, and this is where it becomes visible.
3. **Hand the read back in `needs_agent`**, one entry per candidate carrying the key and
   its coordinate. The step makes no Slack call itself.
4. **Bound it explicitly**: one thread read per outstanding candidate, on a coordinate
   already in hand. State in the header that no search and no channel history is read, so
   a later change cannot widen this into the surface the notify bound protects.
5. **Decide `event` deliberately**, following `step-unanswered-asks.sh`: at the moment
   `run.sh` reads this step's line nobody has looked at any thread yet, so any event would
   be a claim about a reading not yet made. Record the decision in the header either way.
6. **Degrade by name, never as silence**: no coordinate, no transport, an unreadable log
   and a thread read that failed are four different facts and are reported as four.
7. **Register the step in `run.sh`** so every step still contributes a report line, and
   document it in `reference/workflow.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step names every question in state `asked` with a coordinate, and hands each back in
  `needs_agent` with that coordinate.
- It makes **no** Slack call itself, and reads no channel history — one thread read per
  candidate, on a known coordinate, is the whole external surface it asks for.
- A candidate with no coordinate is counted and named rather than searched for.
- Every degradation is reported by name; a step that could not read reports that, never
  an empty finding.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including a test over a fixture log with a
  mix of `asked`-with-coordinate, `asked`-without and `answered` keys.
- A grep-level assertion that the step contains no Slack invocation.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

## Considerations

- **The judgement is deliberately not here.** Which replies are a person's answer is the
  next ticket's question; this step decides only *which threads to look at*. Splitting it
  the other way would put a model judgement inside a script.
- The per-tick cost is one read per outstanding question. If that set can grow unbounded,
  say so in the header and name the bound rather than discovering it in production — the
  check-in's own caps are the obvious reference point.
