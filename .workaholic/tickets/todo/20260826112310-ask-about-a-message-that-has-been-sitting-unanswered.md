---
created_at: 2026-08-26T11:23:10+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: answer-what-is-waiting-and-stamp-what-was-accepted
merge_policy:
verification_handoff: 
---

# Ask about a message that has been sitting unanswered

## Overview

PROPOSED. `/moderate`'s question set is bounded by what its own steps found this tick:
`step-stalled-units.sh` reads claims, `step-direction-health.sh` reads strategies, and
nothing reads the channel for a human message nobody has answered. A question, request
or opinion written on `#dev-workaholic` therefore reaches a person only if one of the
tick's own readers happened to produce a row about it — and a message the tick *saw*
in its inbound sweep and did not file produced nothing at all. That is the measured
failure behind this mission's source record: the tick of 19:18 JST found the developer's
message, filed nothing, deferred to the `:40` sweep, and told nobody; the developer
asked in session why it had not been handled.

Add a step that reads what has been sitting unanswered — **whether or not anyone
mentioned the routine** — and hands each row to the existing check-in as a question
addressed to a named person, keyed so it is asked exactly once.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-unanswered-asks.sh` — NEW. The step.
  Follows `step-direction-health.sh`'s shape: emit `needs_agent` rows, contribute one
  report line, write nothing.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — register the step so it runs and
  contributes a report line, in the documented order (before `human-checkin`).
- `plugins/workaholic/skills/moderate/scripts/step-inbound-sweep.sh` — READ ONLY, for its
  precedent: Slack is a connector held by the session, not by a script, so the channel
  read is handed back in `needs_agent` and every surface is named either way.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the ledger the step consults
  so a message an earlier tick already asked about is not asked about again.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the existing gate; the
  step supplies keys to it and does not re-implement the cap, the quiet hours or the
  working-day hold.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step's contract and its refusals.
- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the routine prompt is the
  ceiling for what the tick may emit; the channel read must be within it.
- `CLAUDE.md` — the `/moderate` row's step count and the new step's one-sentence contract.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for the step's gate and keying.

## Implementation Steps

1. Read `step-direction-health.sh` and `step-stalled-units.sh` end to end. They are the
   two steps that already turn a reading into a question addressed to a person; this
   step's shape is theirs, and any divergence should be deliberate.
2. Decide and write down the **unanswered** reading, in the step's own header. The
   mechanical half a script can own: which channel, which window, and which
   `(channel, ts)` keys an earlier tick already asked about (from the tick log via
   `log-read.sh`). The judgement half the agent owns, because Slack is not reachable
   from a shell: whether a message is a question, a request or an opinion, and whether
   anything has answered it.
3. Write `step-unanswered-asks.sh`. It emits `{"step","status","reason","summary",
   "event","needs_agent":[…]}` like every other step, hands the channel probe back in
   `needs_agent` with the already-asked key set, and **writes nothing**.
4. Key each row `unanswered-ask:<channel>:<ts>` and route it through `ask-question.sh`
   so the asked-once gate, the five-a-tick cap, quiet hours and the working-day hold all
   apply unchanged. Do not add a second ledger.
5. Supply an `event` distinct from the `summary` (2026-08-23): the summary is the audit
   line, the event is what a reader of the root sees. A step that found nothing supplies
   **no** event, so no root line is rendered.
6. Register the step in `run.sh`, ahead of `human-checkin`, and confirm every step still
   contributes a report line and the `--deadline-seconds` ordering is unchanged.
7. Name every degradation: no Slack transport, an unreadable channel, an unreadable
   ledger. A step that could not read says so; it never renders as a step that ran and
   found nothing.
8. Update `SKILL.md`, the routine template and `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A message on the channel with nothing answering it produces one `needs_agent` row
  addressed to a named person, with no mention of the routine required anywhere.
- The same message produces no second question on any later tick.
- A tick that cannot read the channel, or cannot read the ledger, reports that by name
  and asks nothing, rather than reporting an empty finding.
- The step writes no file, creates no branch and merges nothing.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic cases for the key shape, the
  asked-once gate against a seeded tick log, and each named degradation.
- `bash plugins/workaholic/skills/moderate/scripts/run.sh --root <fixture>` on a
  throwaway tree: the step appears in the report with its own line.

**Gate** — what must pass before approval:

- The full local verification block in `CLAUDE.md` passes.
- No new `gh issue|pr|repo` call and no `AskUserQuestion` anywhere in the step.

## Considerations

- **Slack is not reachable from a script.** `step-inbound-sweep.sh` settles this already:
  the connector belongs to the session. Do not reach for a token here — the step names
  what it needs and the agent probes it, exactly as the sweep does.
- The ask says "reacted to". The tick's existing way to react to something is to ask a
  named person about it inside its root; adding a second surface would be the status
  line addressed to nobody this repository has retired twice.
- The inbound sweep runs on `[Propose]` at `:40` and this step on `[Moderate]` at `:50`,
  so a message the sweep captured this hour will normally already have an issue. That is
  a reason to read whether anything answered it, not a reason to skip it.
