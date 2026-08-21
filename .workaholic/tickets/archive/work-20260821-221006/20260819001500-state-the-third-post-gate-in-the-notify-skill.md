---
created_at: 2026-08-19T00:15:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818202549-make-the-housekeep-notification-reflect-the-tick-s-actual-findings.md]
merge_policy: auto
verification_handoff: 
---

# State the third post gate in the notify skill

## Overview

<!-- MINTED MID-RUN by the /implement run that drove
     `20260818214615-measure-and-bound-the-prepare-release-post-rate.md` (PR #522).
     That run added a third posting gate to the `📦 Release Preparation` line and
     updated `notify/reference/notifications.md`, the routine template, the command,
     `ship/SKILL.md` and `CLAUDE.md` — but not `notify/SKILL.md`, which still states
     the gate as two conditions. Filed rather than fixed because PR #522 had already
     merged when it was noticed. -->

`plugins/workaholic/skills/notify/SKILL.md`, *The repository tick's status line*, still
reads **"Two conditions, both required, or the tick posts nothing"** and names only
`actionable || doubtful` and the `` `deploy:<digest>` `` search. Since PR #522 there are
**three**: the `` `deploy-day:<day_token>` `` search is required too, and it is the one
that bounds the rate.

The two documents disagree, and the shorter one is the one a session reads first.
`SKILL.md` is the model stated once; `reference/notifications.md` carries the detail. A
session that loads only the skill would post hourly again — which is exactly the defect
#522 was filed to remove.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/runtime-behavior.md` — the tick's reporting contract

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — *The repository tick's status line*: the
  "Two conditions, both required" paragraph and the sentence naming the key.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the detail copy, already
  correct; the two must agree.
- `plugins/workaholic/skills/ship/SKILL.md` — §7, *The rate the digest did not bound*, the
  reasoning both should defer to.

## Implementation Steps

1. In `notify/SKILL.md`, change "Two conditions, both required" to three and name the
   `` `deploy-day:<day_token>` `` search beside the digest search. Keep it to the model —
   the measurement and the rejected alternatives stay in `ship/SKILL.md` §7 and the
   reference; do not restate them here.
2. Keep the sentence "**The key is `` `deploy:<digest>` ``, never the heading**" true by
   saying there are now two keys and that neither is the heading.
3. Do not touch the shapes: they are pinned byte-for-byte between
   `notify/reference/notifications.md` and `skills/workaholify/routines/prepare-release.md`
   by `test-workflow-scripts.mjs`, and this ticket changes prose only.
4. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `notify/SKILL.md` names all three gates for the `📦` line.
- No post shape changes; the byte-identical pin still passes.
- `outputs/` is regenerated and CI's `Outputs Freshness` is clean.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs` and `verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The tests pass and the two notify documents state the same number of gates.

## Considerations

- This is prose only. Resist widening it into a second pass over the rate bound — the
  gate itself shipped in #522, was measured, and is covered by a 13-assertion suite.
- The same paragraph is a good place to check for the inverse defect later: a gate added
  to the reference and never to the skill is how this one happened.
