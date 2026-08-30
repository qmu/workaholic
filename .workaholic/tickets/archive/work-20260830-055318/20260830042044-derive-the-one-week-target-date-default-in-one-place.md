---
created_at: 2026-08-30T04:20:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: draft-a-dateless-direction-with-the-operator-s-one-week-default
merge_policy:
verification_handoff: 
---

# Derive the one-week target-date default in one place

## Overview

PROPOSED. The operator's ruling — *the default target date is one week from the
ask* — is a date this repository will now compute. Every other date term in the
strategy layer (`days_to_target`, `overdue`, `expiring`) is derived in exactly one
place and read by everything else; this one must be too, before any caller uses it,
or two sessions will each compute "a week" from two different clocks.

The script owns the arithmetic and nothing else: it decides no policy, reads no
strategy, writes nothing, and never says whether a default *should* be taken —
that judgment is the next ticket's.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/strategy/scripts/default-target-date.sh` — new; the one
  derivation
- `plugins/workaholic/skills/propose/scripts/survey-strategies.sh` — the existing
  date arithmetic to match in shape (jq over a `YYYY-MM-DD`, `date -u` for today)
- `plugins/workaholic/skills/strategy/scripts/create.sh` — the consumer's floor:
  it refuses anything but `YYYY-MM-DD`, so this must emit exactly that

## Implementation Steps

1. Write `strategy/scripts/default-target-date.sh [<ask-date>]`: emit
   `{"target_date": "<YYYY-MM-DD>", "basis": "<the date it counted from>", "days": 7}`.
2. Count from the **ask's own date** when one is given (the triggering issue's
   `created_at`, so a tick that ingests an old issue does not date a direction from
   its own clock), else from `date -u +%Y-%m-%d`. Report which in `basis`.
3. Emit a `YYYY-MM-DD` `create.sh` accepts by construction; a `<ask-date>` argument
   that is not `YYYY-MM-DD` is refused `bad_ask_date` with **no** date emitted —
   never silently fallen back to today, which would hide a malformed input behind a
   plausible answer.
4. Pure read, exit 0 on the success path, no file touched anywhere.
5. Keep the number **7** in this script alone and name it in the header as the
   operator's ruling of 2026-08-30, so a later reader finds the ruling rather than a
   bare constant.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The script emits a `YYYY-MM-DD` seven days after its basis date, and names that basis
- A malformed `<ask-date>` is refused `bad_ask_date` with no date emitted
- The constant 7 appears in no other file

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/strategy/scripts/default-target-date.sh 2026-08-30`
  → `2026-09-06`, `basis: 2026-08-30`
- `bash .../default-target-date.sh not-a-date` → `bad_ask_date`, no `target_date`
- `grep -rn` for a second seven-day literal under `plugins/workaholic/skills/strategy/`

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes

## Considerations

- Date arithmetic across BSD and GNU `date` differs; the survey already does its day
  arithmetic in jq over epoch seconds, and matching that shape avoids a `date -d`
  that works on the runner and not on a developer's machine.
