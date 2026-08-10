---
created_at: 2026-08-10T13:07:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: configure-routines-automatically-via-remotetrigger
merge_policy:
---

# Apply routine wiring directly via RemoteTrigger in /setup-routines

## Overview

`/setup-routines`'s "manages nothing" ruling (2026-08-06, re-verified 2026-08-10) was based on no `RemoteTrigger`-family tool being exposed to a session. FB `20260810214929` reports a live interactive session finding the tool *is* exposed there (list/get/create/update/run), and used it to read this repo's two routines, discover both had an empty `cron_expression`, and write working schedules onto both. Give `/setup-routines` (and `/workaholify`'s routine step) a path that detects the tool via `ToolSearch`, and when present: lists the account's routines, diffs each against its template (name/prompt/model/schedule/connectors), and applies create/update calls to converge them — reporting exactly what changed. When the tool is absent, behavior is byte-identical to today's sheet-only render.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/setup-routines.md` — states "manages nothing: no `RemoteTrigger` call"; needs the conditional path
- `plugins/workaholic/skills/workaholify/SKILL.md` — §5 *Scheduled routines* / *What the command does with all this*
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — the existing sheet renderer, kept as fallback
- `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` — the two templates to diff against
- `plugins/workaholic/skills/workaholify/reference/routines.md` — where the account-management-surface retirement (2026-08-06) and the re-verified "no tool" finding (2026-08-10) are recorded

## Implementation Steps

1. Detect `RemoteTrigger`-family tool availability via `ToolSearch` at the start of the flow; branch on the result rather than assuming absence.
2. When present: list the account's routines, match each against its template by name, diff name/prompt/model/schedule/connectors, and apply `create`/`update` calls to converge; report every field changed per routine.
3. When absent: fall through unchanged to `render-setup-sheet.sh --all <repo-url>` (today's behavior).
4. Update `setup-routines.md` and `SKILL.md` §5 to state the conditional behavior instead of the unconditional "manages nothing," and record why the 2026-08-06/2026-08-10 findings were scoped to the *unattended, routine-fired* session class (per `render-setup-sheet.sh`'s own header) rather than every session.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A session with `RemoteTrigger` exposed converges the account's routines to the templates and reports the diff applied.
- A session without it renders the setup sheet exactly as before — no regression to the sheet-only path.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (hermetic smoke coverage, extended for this flow if it gains a bundled script).
- Manual run of `/setup-routines` in an interactive session, and a diff of the resulting routine records against the templates.

**Gate** — what must pass before approval:

- The applied wiring never writes a schedule the API rejects — confirmed against the sibling schedule-fix ticket in this mission.
- No `AskUserQuestion` is introduced (the command stays unattended-safe per `rules/interaction.md`); a mismatch it cannot resolve is reported, not asked.

## Considerations

The prior ruling's "no tool" finding was measured for the *unattended, routine-fired* session class specifically (`render-setup-sheet.sh`'s header); this ticket must not silently broaden that scope claim beyond what a fresh interactive-session check confirms. Depends on the schedule fix ticket landing first (or in the same mission unit) so nothing applies the still-unrealizable `0,30 * * * *` value.
