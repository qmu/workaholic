---
created_at: 2026-08-10T08:53:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: move-the-propose-and-implement-routines-to-a-fixed-interval-schedule
merge_policy:
---

# Revive /set-routines to provision the routines' fixed-interval trigger

## Overview

FB `20260810085032` (from GitHub issue #336) asks to "revive `/set-routines`"
alongside moving `[Propose]`/`[Implement]` to a fixed-interval schedule. The
account-management surface that once inspected/changed routine records
(`plan-routine-change.sh`, `authorize-routine-change.sh`,
`compare-routines.sh`, `list-routines.sh`) was retired 2026-08-06 in favor of
`render-setup-sheet.sh`, a read-only copy-paste sheet — because a routine's
GitHub *event* trigger is UI-only and unreadable from the API
(`docs/proposal-loop-runbook.md`; `CLAUDE.md`, `/setup-routines` row). A
schedule trigger is different: routine records already carry
`cron_expression`/`run_once_at` as genuine, API-visible fields (`CLAUDE.md`,
`/workaholify` row, *"the whole trigger surface is `cron_expression`,
`run_once_at`, and an API token"*). This ticket investigates whether that
field is actually settable through the session's `RemoteTrigger`-family
tooling and, if so, revives a `/set-routines`-shaped command that provisions
(or at minimum verifies) the fixed-interval schedule for a repository's
`[Propose]`/`[Implement]` routines — scoped strictly to the schedule field,
not a reintroduction of the retired event-management surface.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/managing-change-history.md` — distributing a command/skill change as a plugin update

## Key Files

- `plugins/workaholic/commands/setup-routines.md` — the current, read-only `/setup-routines` command this ticket may extend or sit beside
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — today's setup-sheet renderer; the reference for what is/isn't readable from here
- `plugins/workaholic/skills/workaholify/SKILL.md` — the account-management-surface retirement rationale (2026-08-06) this ticket must not blindly reverse
- `docs/proposal-loop-runbook.md` — history of the routine-management retirement
- `CLAUDE.md` (`/setup-routines`, `/workaholify` command rows) — needs updating with whatever this ticket lands

## Implementation Steps

1. Confirm, against the session's actual `RemoteTrigger`-family tooling
   (not assumed from prior documentation), whether a routine's
   `cron_expression`/schedule is genuinely readable and settable from a
   Claude Code session — the retirement of the old management surface was
   about the *event* trigger being API-invisible, which may not hold for a
   schedule trigger.
2. If it is settable: design and implement a `/set-routines`-shaped command
   (or extend `/setup-routines`) that provisions the fixed-interval
   `cron_expression` ticket 1 declares, for the current repository's
   `[Propose]`/`[Implement]` routines, asking for developer confirmation
   before any write (per `rules/interaction.md`).
3. If it is not settable: do not fabricate a management surface — instead
   revive `/set-routines` as a copy-paste-sheet extension (same shape as
   `render-setup-sheet.sh`) that tells the developer exactly what
   `cron_expression` to enter by hand, and update the docs to say plainly
   that scheduling remains a developer act, same as the current
   `/setup-routines` stance for event triggers.
4. Update `CLAUDE.md`'s command table and `skills/workaholify/SKILL.md`
   with whichever outcome was implemented.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The repository states, correctly and without guessing, whether a routine's fixed-interval schedule is settable from a session — and if so, provides a working way to set it; if not, provides an accurate copy-paste sheet.
- `CLAUDE.md` and the workaholify skill describe the resulting command truthfully (no "manages nothing" claim left standing if it now does).

**Verification method** — the commands/tests/probes that prove them:

- Exercise the revived command against a real or test routine record and confirm its reported result matches the routine's actual configuration.
- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- Whichever path (2) or (3) above is taken, the docs and the account-management-retirement rationale in `skills/workaholify/SKILL.md` stay consistent with what the code actually does.

## Considerations

- Directly revisits the 2026-08-06 ruling that routine management "manages nothing" — this ticket's first step is to re-verify that premise for the schedule field specifically, not to assume the old retirement fully applies.
- If step 1 finds scheduling is still not settable from a session, this ticket still delivers value as an accurate, revived setup sheet — it must not silently become a no-op.

## Final Report

Step 1 (re-verify, not assume): `ToolSearch` was run against this session's entire
tool surface, first by name (`RemoteTrigger`) and then by keyword (`routine`, `cron`,
`trigger`, `schedule`, "create trigger routine schedule webhook code session"). No
`RemoteTrigger`-family tool exists at all. The only scheduling-shaped tools present are
`CronCreate`/`CronList`/`CronDelete`, and their own descriptions rule them out: "Jobs
live only in this Claude session — nothing is written to disk, and the job is gone
when Claude exits." That is a session-local, in-memory mechanism, unrelated to an
account-level routine record that persists across sessions/devices and is what
actually fires `[Propose]`/`[Implement]`. So although `cron_expression` **is** a
genuine, API-visible field on a routine record (unlike a GitHub event's trigger,
which the 2026-08-06 retirement found has no field at all) — the 2026-08-06 "manages
nothing" ruling's *conclusion* still holds for a schedule trigger, for a related but
distinct reason: the field exists, but no tool in this session's surface reads or
writes it.

Step 3 (not settable → accurate copy-paste sheet, not a fabricated management
surface): `render-setup-sheet.sh` already derived a **Schedule** trigger step from a
template's `cron_expression` field before this ticket (the branch predates it), so
reviving "`/set-routines`" required no new command — `/setup-routines` already is that
sheet, and ticket `20260810085347`'s template change is what makes it render a real
schedule step for `[Implement]` for the first time. Writing a second, near-identical
command would repeat exactly the mistake the 2026-08-06 retirement corrected (a tool
managing what it cannot verify) and would violate this repository's own "one
behaviour per command" (`CLAUDE.md`, P5) posture toward duplicate command surfaces.

Docs updated to state the finding rather than let the "manages nothing" claim read as
an unchecked assumption: `CLAUDE.md`'s `/setup-routines` row, `workaholify/SKILL.md`
§5, and `reference/routines.md`'s new *The schedule field, re-verified for a session*
section.

**Scope of the finding, stated explicitly rather than left implicit**: this was
checked from an unattended, routine-fired session — the exact class `[Implement]`
runs in. It does not by itself establish what tooling a developer's own interactive
`claude.ai` session carries; that would need its own re-verification from inside such
a session, not an assumption in either direction. This limit is recorded in
`reference/routines.md` and `CLAUDE.md` so a future reader does not read "no
`RemoteTrigger` tool" as a universal claim broader than what was actually checked.

### Discovered Insights

- **Insight**: `CronCreate`/`CronList`/`CronDelete` look, by name, like exactly the
  tool this ticket was hoping to find — and are not it.
  **Context**: worth flagging for any future investigation of "can a session manage
  X account-level resource": these tools are session-scoped and in-memory by explicit
  design (their own docs state jobs vanish when the session ends), so a name match
  alone is not evidence of capability. The distinguishing test is persistence across
  sessions, which only an account-level API-backed tool would have.
