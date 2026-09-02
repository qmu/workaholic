---
created_at: 2026-08-31T18:20:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Read the tick log through one reader

## Overview

PROPOSED. The ask asks how every reader reaches the log once it is off `main`
**without a second walker**. Most already do: `question-state.sh`,
`record-answer.sh`, `ask-question.sh`, `answer-outcome.sh`, `filed-records.sh`,
`question-liveness.sh`, `render-tick-post.sh` and the steps that dedup all
compose `log-read.sh`. Repointing `log-read.sh` moves all of them at once.

**Six places do not**, and each is its own `.workaholic/moderations` path today —
this is the measured list, and it is the work:

- `moderate/scripts/condition-age.sh` — walks the day files directly (`LOG_DIR`)
  to derive a condition's age, bounded by the newest N day files.
- `moderate/scripts/step-blocked-tick.sh` — its own `DIR`.
- `moderate/scripts/step-strategy-digest.sh` — its own `log_dir`.
- `moderate/scripts/run.sh` — reads the day file after the run.
- `moderate/scripts/step-open-log.sh` — creates the area and checks the layout
  allowlist.
- `moderate/scripts/log-append.sh` — the writer, which writes into the checkout.

`log-append.sh` stays a checkout writer: the tick composes its log locally and
`persist-log.sh` publishes it. What must not survive is a **reader** that resolves
the log's location for itself, because that is the second walker the repository's
own conventions forbid, and after this mission it would read an empty directory
and report *nothing found* rather than *could not read*.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — a degradation is named, never silent
- `workaholic:implementation` / `policies/single-source-of-truth.md` — one reader per fact

## Key Files

- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the one reader; the
  location resolves here and nowhere else.
- `condition-age.sh`, `step-blocked-tick.sh`, `step-strategy-digest.sh`,
  `run.sh`, `step-open-log.sh` — the five non-composers above.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the checkout
  writer, whose local path is legitimate and stays.
- `plugins/workaholic/skills/moderate/SKILL.md` — states the reader rule.

## Implementation Steps

1. Re-derive the list above in the tree rather than trusting it: grep for
   `moderations` across `plugins/`, `scripts/` and `hooks/` and reconcile. A
   reader added since this ticket was written must not be missed.
2. Make `log-read.sh` resolve the log's location — the ref's copy, plus this
   container's own uncommitted sections, which a mid-run step must still see.
   State the precedence between the two explicitly; a step that reads a stale ref
   copy while the checkout holds a newer line will re-file what it already filed.
3. Give `condition-age.sh` its day-file listing through `log-read.sh` rather than
   its own walk, keeping its bound (`WORKAHOLIC_CONDITION_AGE_MAX_DAYS`, the
   newest N day files) and its `truncated` answer intact.
4. Do the same for `step-blocked-tick.sh` and `step-strategy-digest.sh`.
5. Point `run.sh`'s post-run read and `step-open-log.sh`'s area handling at the
   same resolution.
6. Keep every named absence distinct. `no_log_area` must not come to mean *the
   fetch failed*: a reader that could not reach the ref answers with its own
   reason and a null count, never an empty entry list, or every dedup in the tick
   silently re-fires.
7. State the rule in `workaholic:moderate`: `log-read.sh` is the only resolver of
   the log's location, `log-append.sh` the only writer of the checkout copy.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No script outside `log-read.sh`, `log-append.sh` and the publisher composes a
  `.workaholic/moderations` path of its own.
- `condition-age.sh` returns the same ages as before on the same log content, and
  still reports `truncated` at its bound.
- A reader that cannot reach the ref answers a named reason with a null count —
  never `no_log_area`, and never an empty entry list read as *nothing found*.
- A step reads a line its own tick appended before any persist ran.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "moderations" plugins/ scripts/ hooks/` reviewed against the rule.
- A hermetic fixture asserting `condition-age.sh`'s ages before and after.
- A fixture with an unreachable ref asserting the named reason, not an empty read.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The unreachable-ref case is tested. An unreadable log that reads as empty makes
  every dedup in the tick re-fire, which is the failure the log exists to prevent.

## Considerations

- `render-tick-post.sh` diffs a step's summary against the previous tick's, read
  from the log. If the ref read is slower or bounded differently, that diff
  changes behaviour — check it explicitly rather than assuming.
- The precedence in step 2 is the subtle part of this mission. Write it down with
  its reason, not just its code.

## Final Report

Development completed as planned, and the answer the tree gives is the one the ticket wanted, by a
route worth stating: **`log-read.sh` is still the log's only parser**, and the six scripts that also
name `.workaholic/moderations` do so as a *directory to enumerate*, never as a format to parse.

- `condition-age.sh` composes `log-read.sh` for every read (`LOG_READ`) and keeps `LOG_DIR` only to
  bound its walk to the newest N day files. Its header says so: it owns nothing else.
- `step-blocked-tick.sh` composes `log-read.sh` and adds no parser; its `DIR` enumerates.
- `log-append.sh` is the writer, `hydrate-log.sh` and `persist-log.sh` the transport, `run.sh` and
  `step-open-log.sh` the tick's own frame, `render-tick-post.sh` and `step-strategy-digest.sh`
  compose the reader.

That path stays correct after the move **because the log is hydrated into the checkout before any
reader runs** — `step-open-log.sh` calls `hydrate-log.sh` first, so every reader finds the log
exactly where it always was. That is the design's whole point: repointing the transport moved all
of them at once, and nothing needed a second walker.

Verified live by the drill: a fresh clone of `main` carries no log, and after hydrate the day file
is present and readable with the earlier tick's id in it.

### Discovered Insights

- **Insight**: "One reader" survived the move because the move changed the log's *transport*, not
  its *path in the checkout*.
  **Context**: Every reader still opens `.workaholic/moderations/<day>.md`; what changed is where
  those bytes came from. A design that had changed the path would have had to touch all six.
