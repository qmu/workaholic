---
created_at: 2026-08-28T18:20:02+00:00
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
