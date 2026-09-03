---
created_at: 2026-09-03T08:59:28+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-a-post-the-transport-refused-or-say-it-reached-nobody
merge_policy:
verification_handoff: 
---

# Say when a directed post paged nobody

## Overview

A directed shape — `🙋`, `🟡 Handoff` — exists to reach one person. The skill's own rule is never
to mention the identity you are posting as, and its answer for the case where the target *is* the
posting identity is that the shape takes the bot identity so the mention becomes real. With
`SLACK_BOT_TOKEN` unset there is no bot identity, so the post falls back to a line addressed to
nobody and nothing says so. Measured 2026-09-02: three `🟡 Handoff` lines delivered, every one
waiting on one person's act, none of them paging anyone.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the directed set, the mention rule and the bot-identity answer
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shapes' catalog copies
- `plugins/workaholic/commands/implement.md` — the ceiling carrying the `🟡 Handoff` shape
- `plugins/workaholic/commands/moderate.md` — the ceiling carrying the `🙋` shape
- `scripts/test-workflow-scripts.mjs` — the byte-identity pinning of the shapes

## Implementation Steps

1. **Reproduce and localize first.** Read the directed-set section of `workaholic:notify` and the
   two command ceilings, and name exactly what a run does today when the mention target resolves
   to the posting identity and no bot token exists. Quote the fallback sentence.
2. Decide what the post must say in that case — the honest fact is that the line reached the
   channel and paged nobody, so an absent answer is not read as silence from the person.
3. Carry the deployment's single-transport reality into the model: with no bot token the
   two-transport model is one transport, and the directed shapes provably reach nobody.
4. Apply the wording byte-identical across the model, the catalog and both ceilings, and extend
   the suite's pinning rows.
5. Update `CLAUDE.md` where the directed-set rule is stated, in the same change.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A directed post made with no mention token states that it paged nobody
- The single-transport reality is written where the transport model is stated
- Model, catalog and both command ceilings carry one wording, pinned by the suite

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The suite passes and no surface carries a second wording

## Considerations

- The ask offers a fork: either a deployment emitting directed shapes *requires* the token, or the
  shapes say plainly that they paged nobody. This ticket takes the second, which is the one a run
  can deliver; requiring a credential is a provisioning act and is recorded as the alternative.
- Changing the shape's text must not re-ask any question: `/moderate`'s `already_asked` keys on
  the step id, never on the text, and that must stay true.
