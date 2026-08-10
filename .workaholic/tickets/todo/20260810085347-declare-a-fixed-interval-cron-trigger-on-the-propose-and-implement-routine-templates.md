---
created_at: 2026-08-10T08:53:47+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: move-the-propose-and-implement-routines-to-a-fixed-interval-schedule
merge_policy:
---

# Declare a fixed-interval cron trigger on the Propose and Implement routine templates

## Overview

FB `20260810085032` (from GitHub issue #336) asks that `[Propose]` and
`[Implement]` stop relying on immediate webhook-triggered execution and
instead run on a fixed interval (e.g. every 30 minutes, at :00/:30) —
returning to the loop-engineering cadence over instant reaction. Today the
templates (`plugins/workaholic/skills/workaholify/routines/fb.md` and
`implement.md`) declare `trigger_kind: github` / `trigger_event:
issues.assigned` (or the merged-`[Proposal]`-PR equivalent), and
`render-setup-sheet.sh` derives its UI-step instructions from that
declaration. This ticket changes the declared trigger shape to a
schedule (`trigger_kind: schedule`, a `cron_expression` at :00/:30) and
updates the setup-sheet rendering and docs accordingly, so a developer
following `/setup-routines` wires a fixed-interval trigger instead of a
GitHub event one.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/managing-change-history.md` — distributing policy/template changes as plugin updates

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` — `[Propose]` template frontmatter (`trigger_kind`/`trigger_event`/`trigger_filters`)
- `plugins/workaholic/skills/workaholify/routines/implement.md` — `[Implement]` template frontmatter
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — derives UI steps from the trigger declaration
- `plugins/workaholic/skills/workaholify/reference/routines.md` — routine reference documentation
- `CLAUDE.md` (`/setup-routines`, `/workaholify` command rows) — describes the current trigger model

## Implementation Steps

1. Change `fb.md`'s and `implement.md`'s frontmatter from an event-based
   `trigger_kind`/`trigger_event` to a schedule-based declaration
   (`trigger_kind: schedule`, a `cron_expression` covering every 30 minutes
   at :00/:30), keeping `trigger_filters` where it still applies.
2. Update `render-setup-sheet.sh` to derive its UI steps from a schedule
   declaration (how to enter a `cron_expression` in the routines UI) rather
   than a GitHub event.
3. Update `reference/routines.md`, `CLAUDE.md`'s `/setup-routines` and
   `/workaholify` rows, and any other doc naming the current
   webhook-triggered behaviour, so the docs match the new default.
4. Note the tradeoff this reintroduces (the `[Implement]` routine no longer
   starts the instant a `[Proposal]` PR merges) and where that is now
   documented, since it revisits the "routines are never cron" framing this
   repository had settled on.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `[Propose]` and `[Implement]` templates declare a fixed-interval schedule trigger, not an immediate GitHub webhook trigger.
- `render-setup-sheet.sh`'s output and `CLAUDE.md` describe the schedule-based wiring, not the retired event-based one.

**Verification method** — the commands/tests/probes that prove them:

- Read the two templates' frontmatter and confirm `trigger_kind: schedule`.
- Run `render-setup-sheet.sh` and inspect the rendered UI steps.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs` pass; docs updated in the same change per `CLAUDE.md`'s *Update the docs in the same change*.

## Considerations

- This proposal deliberately revisits a settled decision (`/setup-routines` "manages nothing", "routines are never cron") — the interrogation should confirm whether a schedule trigger is genuinely configurable through the routines API/UI before this is marked drive-ready.
- Overlaps with ticket 2 (reviving `/set-routines`): that ticket may be what actually provisions the `cron_expression` this one only declares.
