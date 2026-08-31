---
created_at: 2026-08-31T04:23:12+00:00
status: done
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

## Final Report

**Outcome:** implemented.

**What the seam turned out to be.** The two templates were in different states, and only one of
them was the state the ticket predicted. `[Moderate]` already carried the `🙋` shape
byte-identically; what was missing was only its **carrier**. `[Implement]` was missing the
`🟡 Handoff` shape **entirely** — `workaholic:drive` §7 has said since 2026-08-14 that a handoff
unit's `🟡` *is* its one finish post, while the prompt named only `🟢 Implemented`, so *the
prompt is the ceiling* meant no session running that routine was ever authorized to emit the
shape its own run contract requires. That gap is older than this mission and is closed here
because this is the change that gives the shape a reason to exist.

**Copied, never paraphrased.** The `🟡 Handoff` block in `[Implement]` is byte-identical to the
catalog's, and the suite proves it rather than the change asserting it — the catalog keeps
`🚀`/`🟡`/`🔴` in **one** fence, so the pin takes the stanza by its blank-line boundaries rather
than by the fence's first line, which is why the existing `block(body, lead)` helper could not be
reused as-is.

**Each template names its carrier and its no-token behaviour**, because a prompt that names one
transport as *the* way to post silently selects it for sessions that do not have it — the
measured 2026-08-12 failure, cited in place. Both say the tokened script is
`workaholic:notify`'s **fallback** transport selected here for its **identity** rather than its
availability, which is the accurate sentence and not a phrasing chosen to pass a check: the
existing *no plugin markdown names notify-slack.sh as the primary finish-line transport* row is
word-level by its own admission, and its comment now records the script's second role so a later
reader does not read a pass there as proof the script is never selected first.

**Nothing else moved, and it is checked rather than claimed.**
`git diff --stat` over `routines/` is **additions only** (11 lines in `implement.md`, 4 in
`moderate.md`), and a grep of the diff for `cron_expression` / `model` / `allowed_tools` / `mcp` /
`autofix_on_pr_create` / `scope` / `name` / `type` / `id` / `trigger` returns nothing. **No
template gained an environment block** — a routine declares no environment variables; they live
on the cloud environment it selects. **`[Propose]` is untouched**: its whole Slack vocabulary is
the inbound sweep's receipt, which is addressed to the message's own author and reaches them
through Slack's thread-participation notice.

**Six pins added**, three per template: the byte-identity of the handoff block, that `[Implement]`
states the token is the unit's assignee and never the runner, that it names the bot carrier, and
the matching carrier pins on `[Moderate]` plus one that its root and other replies stay on the
connector. Naming a shape is half of it — a template that named the shape without saying whom it
names and what carries it would let a session emit it with the poster's own token and reach
nobody again, which is the defect this mission exists to close.

**Convergence, not a rename.** A template edit is a **prompt change** the next
`/setup-repo-routines` and `/setup-dev-routines` run applies and reports per routine. Routines
are converged by rendered **name**, and no `name:` moved, so this creates no second routine and
owes the operator no manual act — unlike a rename, which does.

**Gate.** `node scripts/test-workflow-scripts.mjs` → 5442 passed, 0 failed.
`node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` → all built
skills self-contained, `outputs/` regenerated.
