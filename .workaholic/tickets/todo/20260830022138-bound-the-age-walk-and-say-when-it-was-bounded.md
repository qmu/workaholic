---
created_at: 2026-08-30T02:21:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: say-how-long-the-loop-has-been-stuck
merge_policy:
verification_handoff: 
---

# Bound the age walk and say when it was bounded

## Overview

PROPOSED. The tick log is append-only and **never pruned by a machine** (`log-append.sh`'s own
contract — deleting a day file is the operator's act), so an unbounded walk gets more expensive
forever. Bound it with `WORKAHOLIC_CONDITION_AGE_MAX_DAYS` (default 30), and make a bounded walk
say so: a truncated read reports `first_seen` as **at least** that tick, never as a date it could
not establish. A bound that silently understates an age is worse than one that admits it.

**The bound cannot be a computed date.** `log-read.sh`'s own header refuses date arithmetic by
name — `date -d` is GNU-only and `date -v` is BSD-only, and a reader that behaves differently on
the developer's laptop and the routine's container is worse than one that asks the caller for a
date. So the bound is expressed as **the newest N day files**, selected lexically from names that
sort correctly by construction, and the Nth-newest file's own day is handed to `log-read.sh`'s
existing `--since`. No arithmetic, and `log-read.sh` is untouched.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/condition-age.sh` — extended with the bound.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — read for its `--since` contract and
  its no-date-arithmetic rule; **not modified**, and no `--last-days` option added to it.

## Implementation Steps

1. Read `WORKAHOLIC_CONDITION_AGE_MAX_DAYS` (default 30). A non-numeric or empty value falls back
   to the default rather than failing — the bound is a cost control, not a gate.
2. List `.workaholic/moderations/*.md`, keep names matching the `YYYY-MM-DD` shape `log-read.sh`
   itself validates, sort, and take the Nth from the end. Hand that day to `--since`. Fewer day
   files than the bound means no `--since` at all and the walk is complete.
3. Emit `truncated: true` **exactly when** a day file older than that `--since` exists — the walk
   was cut, rather than merely bounded by a log that is shorter than the bound.
4. When `truncated` is true, `first_seen` is reported as a floor: keep the field's shape and add
   `first_seen_is_floor: true`, so a consumer renders *at least* rather than a false date. Do not
   overload `first_seen` with a prefix string — a consumer parsing prose is how the two readings
   drift.
5. `truncated` is **not** a degradation: `readable` stays absent, the counts stay real numbers,
   and the reading is honest and bounded rather than unreadable.
6. State the bound and its direction of error in the script's header: it can only make an age
   look **younger**, which asks a person to look sooner than the truth would.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With a log spanning more days than the bound and a key first named before the cut, the reading
  is `truncated: true`, `first_seen_is_floor: true`, and `first_seen` is the oldest tick inside
  the bound.
- With a log shorter than the bound, `truncated` is false and the reading is byte-identical to
  the unbounded one.
- `truncated: true` never sets `readable: false` and never nulls a count.
- No `date -d` or `date -v` appears anywhere in the new code.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — rows over a fixture whose day files span past the
  bound, plus a grep row asserting no date arithmetic.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes; `log-read.sh` is byte-identical.

## Considerations

- **Why not add `--last-days` to `log-read.sh`.** It would be the natural home, and it would put
  a second bounding concept beside `--since` in the one reader every other consumer shares — a
  wider change for one caller. Selecting the Nth-newest file name and reusing `--since` needs no
  change to the shared reader at all.
- The day files are keyed by **UTC** day while the loop's notion of a day elsewhere moves in
  `WORKAHOLIC_QUIET_TZ`. That skew is already stated in `ask-question.sh` and is harmless here:
  the bound is a count of files, not a calendar boundary, so at worst it walks one extra day.
