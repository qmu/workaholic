---
created_at: 2026-08-06T14:40:06+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission: retire-routine-management-into-a-setup-sheet
merge_policy:
---

# Render copy-paste setup sheets from structured trigger declarations

## Overview

PROPOSED. A routine's trigger wiring is web-UI-only — unreadable and unwritable from a
session (measured 2026-08-06; docs: *GitHub triggers are configured from the web UI
only*) — so the plugin's job is to make the human's UI setup as cheap as possible. Each
template gains a **structured trigger declaration** (kind, event, filters), and
`/setup-routines` renders, per template, a **copy-paste setup sheet**: routine name,
model, the prompt body verbatim in one block, the trigger's exact UI steps generated
from the declaration, the connectors, and the `dev-<repo>` channel to have ready. The
developer opens claude.ai/code/routines beside the sheet, pastes and clicks, done.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/*.md` — the three templates; `trigger:`
  becomes a structured block (e.g. `kind: github`, `event: pull_request.closed`,
  `filters: {is_merged: true, title_contains: "[Proposal]"}`)
- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh` — already renders a
  template against a repo URL; the sheet renderer builds on it
- `plugins/workaholic/commands/setup-routines.md` — the command becomes the sheet renderer
- `plugins/workaholic/skills/workaholify/SKILL.md` — §5, where the sheet contract is stated

## Implementation Steps

1. Extend the template frontmatter with the structured trigger declaration; keep a
   one-word `trigger:` summary for humans skimming the file.
2. Add a sheet renderer (script, not prose) that takes a template id and repo URL and
   emits the full sheet: name, model, prompt in one copy block, numbered UI steps derived
   from the declaration (Add another trigger → GitHub event → repo/event/filters → save),
   connectors, channel.
3. Rewrite `commands/setup-routines.md` around it: render sheets for all templates (or
   one, by id), and nothing else — no `RemoteTrigger` call anywhere in the command.
4. `/workaholify` points at the sheets in its routine section.
5. Docs in the same commit; rebuild `outputs/` if a built skill changes.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Each template carries a structured trigger declaration, and the sheet renderer derives
  the UI steps from it — no hand-written per-template steps that can drift.
- `/setup-routines` output is a sheet a developer can complete the UI setup from without
  reading anything else; the command makes no `RemoteTrigger` call.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with assertions on the rendered sheet
- `node scripts/build-plugins/build.mjs` + `verify.mjs`

**Gate** — what must pass before approval:

- No live routine is read or touched by the command.

## Considerations

- The `[Propose]` trigger fires on an assigned **issue**, which the docs' supported-event
  list (Pull request / Release) does not name; the sheet for `fb` states what the UI
  actually offers at render time and must not pretend the docs are complete.
- The sheet is advice, not verification: whether a human completed the steps is
  observable only through behavior (a matching event producing a session), never through
  the API.

## Final Report

Development completed as planned. The three templates carry a structured trigger
declaration (`trigger_kind` / `trigger_event` / `trigger_filters`); `render-setup-sheet.sh`
derives the UI steps from it and emits the prompt verbatim through the existing
`render-routine.sh`, so a sheet can never disagree with the template it came from.
`/setup-routines` is now the sheet renderer plus the two preconditions, with no
`RemoteTrigger` call and no confirmation prompt.

### Discovered Insights

- **Insight**: The one-word `trigger:` summary was kept beside the structured block rather
  than replaced. Two live pins read it (`list-routine-templates.sh`'s cadence assertion and
  the `/setup-routines` report row), and a human skimming the file wants one line, not
  three.
  **Context**: Adding a structured form without removing the summary is what let this land
  as an additive change with no test churn beyond the new section.

- **Insight**: Pinning "the command makes no `RemoteTrigger` call" as a bare
  `!/RemoteTrigger/` was wrong on the first attempt — the command legitimately *names* it
  to say it does not call it. The pin now forbids the two invocation forms the retired
  command actually used (`Call \`RemoteTrigger\``, and a `RemoteTrigger … action:` line).
  **Context**: An absence-pin over prose has to distinguish mentioning from doing, or the
  honest sentence explaining the constraint trips the guard meant to enforce it.
