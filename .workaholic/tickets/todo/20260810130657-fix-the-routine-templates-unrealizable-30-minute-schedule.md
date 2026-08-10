---
created_at: 2026-08-10T13:06:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: configure-routines-automatically-via-remotetrigger
merge_policy:
---

# Fix the routine templates' unrealizable 30-minute schedule

## Overview

Both routine templates declare `cron_expression: 0,30 * * * *` — two fires an hour. FB `20260810214929` reports a live `RemoteTrigger` check found the minimum realizable interval is one hour, and that a `:00` minute is silently rewritten server-side to a jittered minute. The templates are therefore currently asking for a schedule the API cannot honor. Rewrite both to a realizable hourly cadence with distinct, non-zero minutes (the FB's own live example: `[Propose]` at `:15`, `[Implement]` at `:30`), and correct every doc that states the `0,30`/"fixed 30-minute schedule" claim.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` — `[Propose]` template; carries `cron_expression: 0,30 * * * *`
- `plugins/workaholic/skills/workaholify/routines/implement.md` — `[Implement]` template; same unrealizable value
- `plugins/workaholic/skills/workaholify/reference/routines.md` — states the "fixed 30-minute schedule" rationale
- `plugins/workaholic/skills/workaholify/SKILL.md` — restates the same schedule in *Scheduled routines*
- `CLAUDE.md` — `/workaholify` and `/setup-routines` rows quote `0,30 * * * *`

## Implementation Steps

1. Change `cron_expression` in `fb.md` and `implement.md` to distinct, non-zero-minute hourly values (e.g. `15 * * * *` / `30 * * * *`), so the two routines never collide.
2. Update `reference/routines.md`, `SKILL.md`, and `CLAUDE.md` wherever they quote `0,30 * * * *` or describe it as "the same fixed 30-minute schedule," replacing with the corrected hourly cadence and a note on the minimum-interval and `:00`-jitter constraints.
3. Check `render-setup-sheet.sh`'s derived Schedule step still reads `cron_expression` generically (no hardcoded `0,30` assumption) so it renders the corrected value without a code change; fix if it does hardcode.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `fb.md` and `implement.md` declare realizable hourly `cron_expression` values with distinct non-zero minutes.
- No doc in the repo still claims `0,30 * * * *` or "two fires an hour" for either routine.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn '0,30 \* \* \* \*'` over `plugins/` and `CLAUDE.md` returns nothing.
- Manual read of the two updated templates and `reference/routines.md`.

**Gate** — what must pass before approval:

- The mission's reviewer confirms the chosen minute values match what a developer will actually configure in the routines UI (this ticket only changes the templates the setup sheet renders from).

## Considerations

This ticket only fixes what the templates *declare*; per the existing `/setup-routines` "manages nothing" ruling, a developer must still re-enter the corrected schedule in the web UI unless the sibling ticket in this mission lands the direct-apply path first.
