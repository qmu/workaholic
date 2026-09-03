---
created_at: 2026-09-03T08:59:28+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-a-post-the-transport-refused-or-say-it-reached-nobody
merge_policy:
verification_handoff: 
---

# Name a refused connector post as its own degradation

## Overview

The notification model has three branches — connector primary, tokened script as the fallback
for a caller with no connector, neither available means the post does not exist — and no branch
for a connector call that was *refused*. Measured 2026-09-02: with `SLACK_BOT_TOKEN` unset, a run
whose every `slack_send_message` was denied by the harness reported the third branch and stopped,
while a run minutes later in the same session posted three lines of the same shape. This ticket
gives the refusal its own word, `post_refused`, so a per-call denial is never reported as
*this session cannot post*.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the transport model and its three branches; where the fourth outcome belongs
- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog copy the command ceilings are pinned against
- `plugins/workaholic/commands/implement.md` — the ceiling that names the notification outcome a run reports
- `plugins/workaholic/commands/moderate.md` — the same, for the tick's own posts
- `plugins/workaholic/skills/drive/SKILL.md` §7 — the run report's notification-outcome contract
- `scripts/test-workflow-scripts.mjs` — the suite that pins the ceilings byte-identical

## Implementation Steps

1. **Reproduce and localize first.** Establish where a refused connector call is currently
   classified: read `workaholic:notify`'s transport section and the notification-outcome wording
   in `commands/implement.md` and `skills/drive/SKILL.md` §7, and name the exact sentence a run
   follows when a call is denied rather than absent. Record what the current model says, verbatim.
2. Decide where the word belongs — the model in `notify/SKILL.md` is the one home; the catalog and
   the command ceilings carry copies pinned by the suite.
3. Add `post_refused` as a named outcome distinct from `no_slack_transport`, saying in one
   sentence what each means and that a refusal is per call while an absence is per session.
4. Carry the same wording into every surface that reports a notification outcome, byte-identical,
   and update the suite's pinning rows so a drift between them fails the build.
5. Update `CLAUDE.md`'s publish-tree/notification paragraph in the same change.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `post_refused` appears in the notify model and in every command ceiling that reports a notification outcome, with one wording
- The word is distinct from `no_slack_transport` and each is defined in one sentence
- The documentation this change alters is updated in the same commit

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the ceiling-pinning rows pass)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The suite passes, and no surface carries a second wording of the outcome

## Considerations

- The ask's proposed mechanism — a distinct `post_refused` word — is the reporter's hypothesis and
  is recorded here as such; step 1 establishes the current classification before it is adopted.
- Naming the outcome does not by itself deliver anything. The retry lives in the sibling ticket,
  and this one must not grow into it.
