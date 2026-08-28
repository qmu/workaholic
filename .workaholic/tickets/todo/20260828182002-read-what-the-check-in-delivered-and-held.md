---
created_at: 2026-08-28T18:20:02+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Read what the check-in delivered and held

## Overview

PROPOSED. The step reports a **permission**, not a **delivery**: `up to 5 questions may be
asked this tick; 22 held from an earlier tick`, with `status: ok`. That sentence is true on
a tick that asked five and on a tick that asked none, so eight consecutive delivering-nothing
ticks were indistinguishable from eight healthy ones in the only record that survives the
container.

Make the step read back what it actually delivered and what it held, with the reason each was
held — and distinguish by name a cap **genuinely spent today** from a mechanism that has
stopped. This ticket produces the reading; the next one makes it visible in the channel.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a degraded read is named, never rendered as a healthy one

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the summary and the
  JSON line at lines 100–117.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the source of the per-key
  refusal reasons; **read only**, it is not modified by this ticket.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the `human-checkin-ask-*` lines
  for the tick, which are what "delivered" is read from.
- `scripts/test-workflow-scripts.mjs` — the reading's cases.

## Implementation Steps

1. **Read delivery from the log, after the fact.** The agent asks and records under
   `human-checkin-ask-<slug>` via `--record-ask`, so the count of those lines **for this
   tick** is what was delivered. The step runs before the agent asks, so it cannot report
   this on its own first pass: have `run.sh` invoke the reading where the tick already
   re-reads its own state, or add a second, read-only invocation after the agent's turn —
   whichever the driving run finds already exists. **Do not invent a second store**; the
   lines are already written.
2. **Report the three numbers**: `delivered` (asked this tick), `held` (the count already
   computed), and `candidates` (delivered + held). Keep the existing `held` array.
3. **Name why the tick delivered nothing**, from the refusals the gate already emits, and
   distinguish these by name rather than folding them into one:
   - `cap_spent` — `max_per_day` questions were asked **on this day**. The mechanism worked;
     the attention budget is spent.
   - `cap_unbounded` — the day count could not be bounded (an unreadable log, a tick id with
     no day and an unresolvable zone). **This is our own degradation and must never render as
     `cap_spent`**, which is the whole point of the distinction.
   - `all_held` — every candidate was refused by `quiet_hours` or `off_day`.
   - `all_asked_before` — every candidate was refused `already_asked` or `answered`.
   - `no_candidates` — the genuinely quiet hour.
4. **A degraded read is named, never rendered as a delivery.** When the log cannot be read,
   report `status: degraded` with the reader's own reason; do not report `delivered: 0`, which
   would be a claim about a reading that was not made.
5. Keep the existing `summary` a log-facing sentence and put the numbers in it; the root-facing
   `event` is the next ticket's job.
6. Add cases per reason word, including `cap_unbounded` and the degraded read.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step reports `delivered`, `held` and `candidates` for the tick.
- A tick that delivered nothing names one of `cap_spent` / `cap_unbounded` / `all_held` /
  `all_asked_before` / `no_candidates`, and `cap_spent` is never reported for a count that
  could not be bounded.
- An unreadable log is `status: degraded` with the reader's reason and **no** `delivered`
  claim.
- The questions asked, the caps, the holds and every `ask-question.sh` refusal are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — one case per reason word plus the degraded case.
- Against the live tree: the step reports 22 held and names its reason.

**Gate** — what must pass before approval:

- `ask-question.sh` is unmodified by this ticket.
- No new store, no cursor, no field on any artifact; every number is derived from the tick log.

## Considerations

- **The step runs before the agent asks**, which is why step 1 exists. If no post-agent seam
  exists, the honest reading is "candidates and holds now, delivery from the log", and the
  ticket should say so rather than report a delivery it could not observe. The driving run
  should record which it found.
- `cap_unbounded` should be unreachable once the previous ticket lands. It is specified
  anyway, because a reason that only exists while the bug exists is exactly the reason that
  gets dropped and then silently reintroduced.
- Do not let this become a status report addressed to nobody — this repository has retired
  two of those. The reading's audience is the tick log and the next ticket's single event
  line, not a standing channel post.

## Final Report

Development completed as planned. The step reports a delivery, not a permission.

**Which seam was found, as the ticket's Consideration asked the driving run to record: there
is no post-agent seam in `run.sh`.** The run invokes each step once and then runs
`persist-log.sh`; the agent acts on `needs_agent` only after `run.sh` returns, and the only
thing re-invoked afterwards is the persist. So the honest reading was taken — *candidates and
holds now, delivery from the log* — and it is stated in the script header rather than dressed
up as an observation the step could not make. `delivered` is read from the log (the
`human-checkin-ask` lines carrying this tick's id) rather than assumed, which is precisely
what makes a second, read-only invocation after the agent's turn report the real number.

- **Three numbers**: `delivered`, `held_count` and `candidates` (`delivered + held_count`),
  on every branch. The existing `held` array is unchanged in shape.
- **Five reason words**, each named rather than folded together: `cap_spent`,
  `cap_unbounded`, `all_held`, `all_asked_before`, `no_candidates`. `cap_spent` and
  `cap_unbounded` are deliberately separate — one says the budget worked, the other says the
  loop has stopped, and rendering the second as the first is the whole failure being
  repaired.
- **Whether the tick could deliver is asked of the gate**, not re-derived: one
  `ask-question.sh` probe with a key unique to the tick, recorded nowhere (recording is
  `--record-ask`'s separate mode), so the day's arithmetic keeps one home and the step cannot
  disagree with the gate the agent is about to run. A gate that cannot be read leaves the
  count unbounded as far as the step can tell, which is `cap_unbounded` and never
  `cap_spent`. **`ask-question.sh` is not modified by this ticket.**
- **A degraded read is named**: an unreadable tick log is `status: degraded` with the
  reader's own reason and **no `delivered` field at all**. An *absent* log area is a
  **readable** answer — nothing has ever been held — the split `step-unanswered-asks.sh`
  already draws.
- **The summary carries the numbers and nothing that moves on its own.** The old
  `HH:00 local` prefix is gone: the root's hour-to-hour diff normalises `14:00` but not
  `9:00`, so an hour in the summary would have made the step "changed" by construction on
  half the day's ticks — which matters because the next ticket makes this summary the thing
  the root's diff reads.

Verification — `node scripts/test-workflow-scripts.mjs`, the new case
`moderate/step-human-checkin.sh: what it delivered, and why it delivered none`: one case per
reason word including `cap_unbounded` (run against a copy of the scripts directory with the
gate removed) and the degraded read (a copy with `log-read.sh` removed, asserting
`status: degraded`, `reason: no_reader` and no `delivered` claim), plus pins that the day
bound is never recomputed in the step and that the step composes the gate.

### Discovered Insights

- **Insight**: `all_asked_before` is only reachable because the step counts held keys
  *before* the asked-drop as well as after it.
  **Context**: the drop rule empties `held` for a key that has since been asked, so without
  the pre-drop count the state would be indistinguishable from `no_candidates` — a tick that
  never held anything. The two answer different questions and a reader needs both.
- **Insight**: the probe cannot collide with a real question, because its key carries the
  tick id and is never recorded.
  **Context**: `ask-question.sh` reads the log for a key's own step id, so a probe key that
  repeated across ticks would eventually answer `already_asked` and be misread as a
  degradation.
