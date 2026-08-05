---
created_at: 2026-08-05T13:14:32+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: scope-each-user-s-routine-to-the-fb-issues-assigned-to-them
merge_policy:
---

# Decide how a routine trigger scopes to its assignee

## Overview

PROPOSED. The repository's routine model has no representation of an event
trigger *condition* at all: `trigger` is the bare enum `cron|event`, derived in
`list_routines.py` from nothing more than whether a schedule exists, and the
body `/setup-routines` sends on create/update carries only `name`, `trigger`,
`cron_expression`, `model`, `enabled` and `prompt`. Neither title matching nor
assignee matching is expressible today. So before anything can be scoped, it
must be established what the routines API can actually express for a GitHub
issue event — a per-assignee condition, a label, a title match, or nothing.
That answer selects the mechanism for the rest of the mission: a trigger-level
filter if the API supports one, otherwise a session-level check that exits
early when the issue's assignee is not this routine's developer.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a standing outward-facing process changes deliberately, not by inference

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh` — builds the create/update body; where a scope field would be emitted
- `plugins/workaholic/skills/workaholify/scripts/lib/routine_change.py` — `CONTENT_FIELDS` and the confirm digest
- `plugins/workaholic/skills/workaholify/scripts/lib/list_routines.py` — derives `trigger` from schedule presence alone
- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` template whose trigger this scopes
- `docs/proposal-loop-runbook.md` — where the decision is recorded

## Implementation Steps

1. Inspect a live event-triggered routine through `RemoteTrigger get` and record the full shape of its trigger configuration.
2. Establish whether that shape admits a per-assignee condition on an issues event, and whether it can be set at create/update time or only in the web UI.
3. Record the answer and the chosen mechanism, with its rationale, in `docs/proposal-loop-runbook.md`.
4. If the API cannot express it, state the session-level fallback explicitly and what it costs, so the follow-on tickets are written against a decided mechanism rather than a hope.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The live trigger shape is recorded verbatim, and one mechanism is named
- A reader can tell whether the scope is enforced at the trigger or in the session

**Verification method** — the commands/tests/probes that prove them:

- The recorded shape matches a `RemoteTrigger get` response for a live event routine, quoted in the ticket's Final Report

**Gate** — what must pass before approval:

- The two follow-on tickets can be written against the decision without further discovery

## Considerations

The proposing session could not inspect `RemoteTrigger` — the tool was not in
its tool set — so the capability is genuinely unknown rather than assumed
absent. If the API has no per-assignee condition, the session-level fallback
still wakes one session per developer per FB issue: cheaper than N proposals,
but not free, and that cost belongs in the decision rather than after it.
