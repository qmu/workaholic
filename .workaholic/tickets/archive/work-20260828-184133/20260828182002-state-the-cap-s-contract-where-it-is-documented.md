---
created_at: 2026-08-28T18:20:02+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# State the cap's contract where it is documented

## Overview

PROPOSED. The day cap's contract was implicit and therefore unmaintainable: nothing said
**which day** it counts, that the day is the quiet-hours zone's, that a spent cap **holds**
rather than drops, or that a held question is re-offered on the next tick. `ask-question.sh`'s
header documents four gates in detail and gives `day_cap` one line — *the bound the per-tick
cap must not aggregate past (default 10)* — which says what it is for and nothing about how
it is counted. That is precisely the gap the defect lived in for the eleven days nobody could
see it.

State it where the step is documented, in the same change as the behaviour, per this
repository's own rule that outdated documentation is a defect.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — behaviour and its documentation move together

## Key Files

- `plugins/workaholic/skills/moderate/SKILL.md` — the step's contract: which day, whose
  zone, hold-not-drop, re-offer, and the delivery reading.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the header's `day_cap` line
  and the four-gate block, where the arithmetic now belongs beside the gate it governs.
- `plugins/workaholic/skills/moderate/scripts/step-human-checkin.sh` — the header's account of
  what it reports and what it deliberately does not decide.
- `CLAUDE.md` — the `/moderate` row, if the reading or the event changes what that row states.
- `plugins/workaholic/rules/workaholic.md` — only if a rule stated there moves; likely not.

## Implementation Steps

1. **State the cap's four properties** where the step is documented: it counts the
   `human-checkin-ask` lines for the **current `WORKAHOLIC_QUIET_TZ` day**; a spent cap
   **holds** the question rather than dropping it; a held question is **re-offered on the next
   eligible tick**, oldest-held first; and the count is bounded by the same day derivation the
   `quiet_hours` and working-day gates use, so the loop has one notion of a day.
2. **Record the measured failure and its reason**, in this repository's own style: the value
   named `asked_today` was the all-time total (12 across 5 days against a cap of 10), the log
   is append-only and never pruned, so the count only ever grew and every question was refused
   `day_cap` forever; eight consecutive ticks reported `ok` and posted nothing while a red
   base, a 31-hour declared handoff, three undeletable branches and seven undrivable units sat
   held. Say what the repair was (**a bound passed to a reader that already accepted one**)
   and what it deliberately was **not** (a raised cap, a second reader, a stored cursor, a
   second notion of a day).
3. **Note the UTC-file / local-day boundary** the repair carries, and that it over-counts
   rather than under-counts — holding a question rather than asking a duplicate — so a later
   reader does not "fix" it in the unsafe direction.
4. **Document the delivery reading and the event** from the two previous tickets: the reason
   words, that `cap_spent` and `cap_unbounded` are named separately on purpose, and that a
   delivery failure supplies an event while a quiet hour does not.
5. **Update the `/moderate` row in `CLAUDE.md`** to state current behaviour only, in the
   file's established voice, if the reading or the event changes what that row says.
6. Run the build so any generated copy stays in sync: `node scripts/build-plugins/build.mjs`
   then `node scripts/build-plugins/verify.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The step's documentation states which day the cap counts, whose zone it is, that a spent cap
  holds, and that a held question is re-offered oldest-first.
- The measured failure, the repair and the rejected alternatives are recorded.
- The UTC-file / local-day boundary and its safe direction are stated.
- Every document the change touches is updated in the same commit; no document still describes
  the unbounded count.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — generated
  outputs are in sync.
- `node scripts/test-workflow-scripts.mjs` — any prose pin over these files passes.
- A read of the diff confirms no document still describes the all-time count.

**Gate** — what must pass before approval:

- No behaviour changes in this ticket — documentation only.
- `CLAUDE.md` states current behaviour only; the history goes in the skill and the record.

## Considerations

- This ticket is deliberately last-but-one rather than first: the contract can only be stated
  once the three behaviour tickets have settled what it is. If the driving run lands them
  together, fold this into the same commit rather than deferring it.
- Resist restating the whole incident in `CLAUDE.md` — that file states current behaviour, and
  the narrative belongs in the skill and the feedback record.

## Final Report

Development completed as planned. Documentation only — no behaviour changed in this ticket.

**Four documents, all in this branch's change**, each in its own voice and audience:

- **`plugins/workaholic/skills/moderate/SKILL.md`** — the cap's four properties (which day it
  counts, whose zone, that a spent cap holds, that a held question is re-offered oldest-first
  and that the bound rides `log-read.sh`'s existing `--since`), the measured failure and its
  numbers, the repair and the four rejected alternatives (a raised cap, a second reader, a
  stored cursor, a second notion of a day), the UTC-file/local-day boundary and its safe
  direction, the ordering rule, the delivery reading with its five reason words, and the
  root's third gate.
- **`plugins/workaholic/skills/moderate/reference/workflow.md`** §13 — the same contract at
  the depth this reference carries, including the `delivery` reason table, what `delivered`
  honestly is and why (there is no post-agent seam in `run.sh`), and the event's bounds.
- **`plugins/workaholic/skills/notify/reference/notifications.md`** — the `/moderate` root's
  gate paragraph.
- **`CLAUDE.md`** — the `/moderate` row, current behaviour only, with the narrative left to
  the skill.

**Two live documentation defects were found and fixed in passing**, both predating this
mission and both stating a gate that was retired on 2026-08-22: the workflow reference's
*"The gates are `questions >= 1` or `changes >= 1`"* and the notify catalog's *"Two gates …
at least one question **or** at least one changed step"*. Both now state the one gate and the
two narrow conditions beside it (the morning digest, and a check-in that reached nobody).

Verification — `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
(the policy index is in sync, all built skills self-contained, the OKF bundle fresh; the
moderate skill is script-bearing and internal, so `outputs/` is unchanged by construction);
`node scripts/build-plugins/validate-metadata.mjs`; `node scripts/test-workflow-scripts.mjs`
(the catalog↔template drift pins pass); and a read of the diff confirming no document still
describes the all-time count.

### Discovered Insights

- **Insight**: the gate's own header documented four gates in detail and gave `day_cap` a
  single clause about what it is *for*, saying nothing about how it is counted.
  **Context**: that is the shape of gap the defect lived in for eleven days. A gate whose
  arithmetic is undocumented is a gate nobody re-derives when they touch the reader beneath
  it.
- **Insight**: two documents were describing a gate retired six days earlier.
  **Context**: this repository's rule is that outdated documentation is a defect, and both
  survived because the 2026-08-22 change updated the SKILL and the script header but not the
  reference or the catalog. A change that touches a gate should grep the gate's *wording*,
  not only its file.
