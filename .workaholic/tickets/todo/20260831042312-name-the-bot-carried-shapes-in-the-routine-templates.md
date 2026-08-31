---
created_at: 2026-08-31T04:23:12+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notify-the-person-a-directed-question-addresses
merge_policy:
verification_handoff: 
---

# Name the bot-carried shapes in the routine templates

## Overview

PROPOSED. *The prompt is the ceiling*: a session may emit only the events and
post shapes its own routine prompt names, and citing the notify skill is
explicitly not a substitute. So the two preceding tickets change what the model
sanctions and change nothing a routine may actually do until the templates say
so — the same seam the `[Implement]` description root had to cross in 2026-08-22.

Name the bot-carried shapes in the `[Moderate]` and `[Implement]` templates,
byte-identical to the catalog, and pin them against drift.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/moderate.md` — names the
  tick's postable shapes; the question is one of them.
- `plugins/workaholic/skills/workaholify/routines/implement.md` — names the
  finish line, of which the handoff shape is one.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog
  the templates copy from, verbatim.
- `scripts/test-workflow-scripts.mjs` — the drift pin that fails when a
  template's copy and the catalog's diverge.

## Implementation Steps

1. Add to each template the shape it now authorizes and the transport it rides,
   copied **byte-identically** from the catalog — never paraphrased, since the
   pin compares text.
2. State in each template that the bot carries the directed shape only, and that
   with no bot token the post falls back to the connector and is reported: a
   prompt that names one transport as the way to post silently selects it for
   sessions that do not have it, which is the measured 2026-08-12 failure.
3. Leave every other line of both templates alone — `cron_expression`, `model`,
   `allowed_tools`, `mcp`, `autofix_on_pr_create` and `scope` do not move, and no
   template gains an environment block (a routine declares no environment
   variables; they live on the cloud environment it selects).
4. Extend the drift pin to cover the added shapes in both templates.
5. Regenerate `outputs/` and note in the change that a template edit is a
   convergence an operator must apply through `/setup-repo-routines` and
   `/setup-dev-routines`, which is a report line rather than a manual rename.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Each template names the shape it authorizes, byte-identical to the catalog.
- Each names which transport carries it and what happens with no token.
- No other template field moves, and no template declares an environment block.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the drift pins over both templates.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The pins pass, and a diff of each template shows only the added shape lines.

## Considerations

- Templates are converged by name, so this needs no rename and creates no second
  routine: it is a prompt change the next convergence run applies and reports.
- The `[Propose]` template is deliberately untouched — its whole Slack vocabulary
  is the inbound sweep's receipt, which is addressed to the message's own author
  and reaches them through Slack's thread-participation notice.
