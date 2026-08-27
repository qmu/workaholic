---
created_at: 2026-08-27T11:25:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-operator-revise-a-live-direction-through-the-loop
merge_policy:
verification_handoff: 
---

# Route the changed announcement to amend.sh

## Overview

PROPOSED. `/specificate` already recognises a lifecycle announcement by explicit slug:
*ended* reaches `close.sh` (step 9c), *created* takes the strategy form (step 9b), and
*changed* is record-only with `strategy_exists_no_update_writer` — a reason that names
the absence this mission removes. This ticket gives the third branch a step of its own,
reaching `amend.sh` inside the publish tree.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/reference/workflow.md` — steps 7, 9b and 9c;
  the *changed* branch becomes step 9d beside them.
- `plugins/workaholic/skills/specificate/SKILL.md` — *Strategy lifecycle announcements*;
  the table's third row and the `strategy_exists_no_update_writer` reason.
- `plugins/workaholic/skills/strategy/scripts/amend.sh` — the writer this routes to.
- `plugins/workaholic/skills/strategy/scripts/list.sh` — step 5b's read; the set the
  slug is matched against.

## Implementation Steps

1. Add step 9d to `reference/workflow.md`: an announcement naming a slug **present in
   step 5b's set** and stating a revision to the Aim, the Schedule/date or the assignee
   runs `amend.sh` inside the publish tree, instead of steps 8, 9, 9b and 9c and never
   alongside them.
2. Keep every existing recognition rule byte-identical: **explicit slug only** (a title
   or a paraphrase never matches), an absent slug is record-only with
   `strategy_not_found` and the slug named, an ask naming no slug is not an announcement
   at all.
3. Add the two new record-only outcomes, each reported by name: `not_active` when the
   named direction is closed, and `no_revision` when the ask names the slug but nothing
   revisable — an announcement that says only "this is going well" is not a revision.
4. Every `amend.sh` refusal falls back to **record-only naming that reason**; never
   retry with a substituted value, exactly as steps 9b and 9c already require.
5. Update the third row of the SKILL's announcement table and retire the
   `strategy_exists_no_update_writer` reason there, stating what replaced it and why the
   two-writer rule's premise survives.
6. Update `/specificate`'s row in `CLAUDE.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A *changed* announcement naming a live slug reaches `amend.sh` and emits no mission,
  no ticket and no second artifact.
- An absent slug, a closed direction and an ask naming nothing revisable are each
  record-only under their own reason.
- The *ended* and *created* branches are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The suite is green and `outputs/` is regenerated.

## Considerations

- The record is still written whatever the branch concludes, and no feedback record ever
  gains a pointer to a strategy: what connects the revision to its ask stays the pull
  request that carries both.
- A run must not amend on its own judgement. The route fires on an explicit announcement
  and on nothing else — never on a run's own reading that a direction looks stale.
