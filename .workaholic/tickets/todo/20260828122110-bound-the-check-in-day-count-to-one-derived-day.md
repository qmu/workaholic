---
created_at: 2026-08-28T12:21:10+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-what-the-loop-already-knows-to-the-person-who-can-act
merge_policy:
verification_handoff: 
---

# Bound the check-in day count to one derived day

## Overview

Turn ticket 1's red test green: `asked_today` must count **today's** asks, through
the day bound `log-read.sh` already accepts. One derivation of "today", no second
reader, no new field, no stored cursor.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testability.md` — machine-checkable gaps caught early

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — `count_log_prefix`
  gains the bound; the `asked_today` call site is the only one that needs it
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — `--since <YYYY-MM-DD>`,
  the existing lexical bound; do not add a second filter to it

## Implementation Steps

1. Derive the day **once**, beside the zone the `quiet_hours` and working-day gates
   already read (`WORKAHOLIC_QUIET_TZ`). Prefer the **tick id's own** day where one was
   passed — the re-ask branch already does exactly this
   (`today=$(printf '%s' "$TICK" | sed -n 's/^\([0-9]\{8\}\)-.*/\1/p')`), it needs no
   `date` call, and a re-entered tick then answers the same way twice.
2. Pass that day to `count_log_prefix` for the `asked_today` read, and through to
   `log-read.sh --since`. Format it `YYYY-MM-DD`; the bound is a lexical string compare
   over day filenames, so no date arithmetic is introduced anywhere.
3. **Leave every other read alone.** `count_log_step` (the `already_asked` and re-ask
   lookups) must stay unbounded — those ask *ever*, not *today*, and bounding them would
   re-ask every question daily.
4. Fix the re-ask branch's two `asked_this_tick`/`asked_today` values, which both print
   the same unbounded prefix count today; they are reporting only, but they are wrong.
5. Run ticket 1's test to green, then the whole suite.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Ticket 1's test passes; a log carrying only earlier days' asks no longer refuses `day_cap`.
- `already_asked`, `answered`, `tick_cap`, `off_day`, `quiet_hours` and `hold: true` are
  byte-identical in behaviour.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — green, including ticket 1's case.

**Gate** — what must pass before approval:

- No new reader, no new field on any artifact, no stored cursor, no `date -d`/`date -v`.

## Considerations

- **The log's day files are UTC-named and the tick id is UTC** (`tick-id.sh` uses
  `date -u`), while `WORKAHOLIC_QUIET_TZ` defaults to `Asia/Tokyo`. Reading the tick's own
  day keeps both sides on one axis and is recommended; deriving a JST day and comparing it
  against UTC-named files would under-count the first nine hours of the JST day. Either way,
  state in the code which day is counted — ticket 6 documents it.
- The one-off cost is visible and acceptable: bounding the count re-opens questions the
  jam had been refusing, which is the point. Ticket 3 orders that drain.
