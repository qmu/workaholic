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

# Bound the day count to the quiet-hours day

## Overview

PROPOSED. Make `asked_today` mean today. `ask-question.sh` computes it as
`count_log_prefix human-checkin-ask ""`, which calls `log-read.sh --step-prefix
human-checkin-ask` with **no day bound**, so the reader walks every day file under
`.workaholic/moderations/` and returns the all-time total. The log is append-only and a
machine never prunes it, so the count only ever grows: once it crosses `max_per_day` every
question is refused `day_cap` forever.

The repair is a bound passed to a reader that already accepts one — `log-read.sh --since
<YYYY-MM-DD>` — using the `WORKAHOLIC_QUIET_TZ` day the `quiet_hours` and working-day gates
in the same script already derive. **One derivation of "today"**: no second reader, no new
notion of a day, no stored cursor, no field on any artifact.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-source.md` — one derivation of a fact, read by every consumer

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the whole change:
  `count_log_prefix` (line 190), the `asked_today` call site (line 320), and the
  `outstanding` re-ask printf (lines 309–310), which uses the same unbounded expression for
  **both** `asked_this_tick` and `asked_today`.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — read only; it already carries
  `--since` and must not change.
- `scripts/test-workflow-scripts.mjs` — the previous ticket's case turns green here.

## Implementation Steps

1. **Derive the day once, beside the gates that already derive it.** `ZONE` is read at line
   160 and `HOUR`/`WEEKDAY` are derived from it below; derive `TODAY` in the same block.
   Prefer the **tick id**'s `YYYYMMDD` where present, falling back to `TZ="$ZONE" date
   +%Y-%m-%d` — the `outstanding` branch already reads the day from the tick for a stated
   reason (a re-entered tick must answer the same way twice, and reading the wall clock made
   a tick dated yesterday re-ask itself on its own first run). Normalise to `log-read.sh`'s
   `YYYY-MM-DD` form.
2. **Pass the bound through `count_log_prefix`.** Give it a third parameter (the `--since`
   value, empty for none) rather than reading a global, so the two existing call sites stay
   explicit about which of them is bounded.
3. **Bind the `asked_today` call site** (line 320) to `TODAY`. Leave `count_log_step` and the
   `asked_tick` block untouched — the latter already passes `--tick`.
4. **Fix the `outstanding` branch's two values** (lines 309–310): `asked_this_tick` must
   report the *tick* count (the `asked_tick` value, not a prefix count) and `asked_today` the
   *day-bounded* count. Both currently report the same unbounded number, which is the same
   defect twice in one printf.
5. **Change nothing else.** `already_asked`, `answered`, `tick_cap`, `quiet_hours`,
   `off_day`, `hold: true`, the `--record-ask` ledger half, the question-id derivation and
   every refusal's JSON shape stay byte-identical.
6. Run the suite and confirm the previous ticket's case is green and its four pinned cases
   still pass.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A question is refused `day_cap` only when `max_per_day` `human-checkin-ask` lines exist on
  the tick's own `WORKAHOLIC_QUIET_TZ` day.
- The day is derived in exactly one place in the script and passed to `log-read.sh`'s
  existing `--since`; no second reader and no new day derivation is introduced.
- `already_asked`, `answered`, `tick_cap`, `quiet_hours`, `off_day` and `hold: true` are
  unchanged in behaviour and in JSON shape.
- The `outstanding` branch reports the tick count in `asked_this_tick` and the day-bounded
  count in `asked_today`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the pinning case from the previous ticket passes
  and every pinned case still does.
- Against the live tree: `ask-question.sh --root . --tick <today>-HHMMSS --key <fresh> --hour
  14 --weekday 3` answers `ask: true` where it previously answered `day_cap`.

**Gate** — what must pass before approval:

- `log-read.sh` is unmodified.
- No stored cursor, no new file, no field on any artifact.

## Considerations

- **The cap is kept; only its arithmetic is wrong.** A spent day must still hold, and the
  next ticket's ordering is what keeps the unbound count from landing the arrears as one
  wall. Do not raise `max_per_day` as part of this.
- The day boundary moves in `WORKAHOLIC_QUIET_TZ`, not UTC, while the log's **files** are
  keyed by UTC day. Near the boundary a `--since` of the local day can therefore include a
  UTC file whose later entries belong to the local next day. This over-counts rather than
  under-counts (it holds a question rather than asking a duplicate), which is the safe
  direction; state it in the header rather than adding per-entry timestamp filtering.
- Reading the day from the tick id keeps the drill deterministic, which the next-but-one
  ticket depends on.

## Final Report

Development completed as planned. `asked_today` now means today.

- **The day is derived once**, beside the gates that already derive the hour and the weekday
  (`ask-question.sh`, after the `off_day` computation): `TODAY` is the tick id's `YYYYMMDD`
  rendered as `log-read.sh`'s own `YYYY-MM-DD`, falling back to `TZ="$ZONE" date +%Y-%m-%d`
  when the caller passed no tick. The tick supplies it for the reason the `outstanding`
  branch already reads its day from the tick: both sides are then ids minted by the same
  script on the same axis, a re-entered tick answers the same way twice, and the arithmetic
  is testable at all.
- **The bound is a parameter of `count_log_prefix`**, not a global, so the two call sites
  stay explicit about which of them is asking about a day and which about all time. It is
  passed to `log-read.sh --since`, which already accepted it; **`log-read.sh` is unmodified**.
- **`count_log_tick` was lifted out** of the inline `asked_tick` block so the `outstanding`
  branch can report the tick count without re-deriving it. That branch printed the *same*
  unbounded number into both `asked_this_tick` and `asked_today` — the defect twice in one
  `printf`; it now prints the tick count and the day-bounded count.
- **Nothing else moved.** `already_asked`, `answered`, `tick_cap`, `quiet_hours`, `off_day`,
  `hold: true`, the `--record-ask` ledger half, the question-id derivation and every
  refusal's JSON shape are byte-identical, and the cap itself was not raised.

Verification — `node scripts/test-workflow-scripts.mjs`: the previous ticket's case is green
and its four pinned cases still pass. Against a fixture built through `log-append.sh`:

```
--- unbounded history:  {"read": true, "count": 9, "days": 5
--- fresh key on the tick's own day:
{"ask": true, "key": "q:fresh", ... "asked_this_tick": 0, "asked_today": 0, ...}
--- ten asks on the tick's own day, then the eleventh:
{"ask": false, "reason": "day_cap", "hold": true, "key": "q:over", "asked_today": 10, "max_per_day": 10}
```

The header now states the cap's contract: which day it counts, whose zone, that a spent cap
holds rather than drops, that a held question is re-offered oldest-first, the measured
failure, the repair, and the rejected alternatives (a raised cap, a second reader, a stored
cursor, a second notion of a day).

### Discovered Insights

- **Insight**: the day boundary moves in `WORKAHOLIC_QUIET_TZ` while the log's **files** are
  keyed by UTC day, so near the boundary a `--since` of the local day can include a UTC file
  whose later entries belong to the local next day.
  **Context**: this over-counts rather than under-counts — it holds a question rather than
  asking a duplicate — which is the safe direction. It is stated in the script header rather
  than repaired with per-entry timestamp filtering, precisely so a later reader does not
  "fix" it the other way.
- **Insight**: `log-read.sh` compares `--since` **lexically** against file names because
  `date -d` is GNU-only and `date -v` BSD-only.
  **Context**: that is why the derivation has to normalise to `YYYY-MM-DD` and why the tick
  id (which is `YYYYMMDD-HHMMSS`) cannot be handed over unchanged.
