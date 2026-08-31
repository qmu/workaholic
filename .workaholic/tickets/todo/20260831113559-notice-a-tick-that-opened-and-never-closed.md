---
created_at: 2026-08-31T11:35:59+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# Notice a tick that opened and never closed

## Overview

An opening on the base with no closing is the signature of a tick that stopped. Nothing
reads for it today, so make the next tick do it: one reading over the log the tick already
keeps, one question, keyed so a stopped hour costs one question and not one per tick.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the log's one parser. Read,
  never duplicated.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the `STEPS` list.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the gate. Called, never
  modified.
- `plugins/workaholic/skills/moderate/scripts/step-undrivable-units.sh` — the precedent
  for a repository-scoped finding where the running identity is never consulted.


## Implementation Steps

1. Read the previous tick's section through `log-read.sh` and answer whether it carries
   an opening and no closing. No second parser, no cursor, no store, no field anywhere.
2. Bound it: the **previous** tick only, or a small named number of them — never the whole
   log, whose size grows without limit.
3. Hand each such tick to the check-in keyed on the **tick id**, so one stopped hour costs
   exactly one question however many later ticks see it.
4. Say what is known and no more: *this tick opened and never closed*. The reason it
   stopped is not on the base by construction, so the question must not guess one.
5. Supply an `event` only when such a tick is found; a healthy hour renders no line. An
   unreadable log is `degraded` by name and asks nothing.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A log whose previous section has an opening and no closing produces exactly one
  question, keyed on that tick id, across repeated ticks.
- A complete previous section produces no question and no event.
- An unreadable log is `degraded` by name and asks nobody.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-blocked-tick`

**Gate** — what must pass before approval:

- `log-read.sh` and `ask-question.sh` are byte-identical; the step writes nothing but its
  own log line.


## Considerations

- A tick still **running** when the next one starts also has an opening and no closing.
  The two are distinguishable only by time, and this must not turn a slow hour into an
  hourly false alarm — decide the bound explicitly (the tick before last, say) and record
  the reasoning rather than tuning a threshold.
- This depends on the early persist landing first; drive the two in order.


## Final Report

Development completed as planned. `step-blocked-tick.sh` composes `log-read.sh` — no second parser,
no cursor, no store, no field on any artifact — groups its entries by the tick id that reader
already returns, and answers whether the subject tick has an opening and no closing. It is
registered second in `STEPS`, after `open-log`, because it is a fact about the tick machinery
rather than the repository's work and because the deadline cuts steps in order: the reading that
says the loop stopped must not be the first to go. `log-read.sh` and `ask-question.sh` are
byte-identical.

**Two decisions the ticket asked to be made explicitly and recorded.**

*What "closed" means.* Not the closing persist's `persist-log` line — `run.sh` writes that line
**after** the push, so it never reaches the base on the tick that wrote it, and a healthy tick
would read as stopped. The signal is a **`human-checkin` line**: last in `STEPS` and exempt from
the deadline by design, so a tick that reached the end always logged it. The coupling is stated in
the header rather than derived by reading `run.sh`'s `STEPS`, which would be an inspection read of
a plugin script and a second definition of the tick's closing step.

*Which tick.* The **tick before last**, not the previous one — a tick still running when the next
starts also has an opening and no closing, and the two differ only by time. The bound is structural
rather than a threshold: the subject has had a full extra hour to finish. The cost is stated — a
stopped tick is named an hour later than the earliest possible moment, and the measured failure
lasted hours.

Keyed `blocked-tick:<tick-id>`, addressed to nobody, with an `event` only when a stopped tick is
found; an unreadable log is `degraded` by name and asks nobody, and a repository with no log area
is `skipped`. The question says what is known and no more: the reason is not on the base by
construction, so it is never guessed.

### Discovered Insights

- **Insight**: the step's summary deliberately carries no tick id.
  **Context**: the moderation root calls a step changed when its summary differs from an hour ago,
  and a tick id moves every tick — the summary would mark this step changed hourly by construction,
  the retired `📦 Release Preparation` shape. The tick id rides `needs_agent` instead.
