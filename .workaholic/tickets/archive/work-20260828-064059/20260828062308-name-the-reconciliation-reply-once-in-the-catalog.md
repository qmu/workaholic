---
created_at: 2026-08-28T06:23:08+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: reconcile-a-stale-thread-with-the-unit-s-real-state
merge_policy:
verification_handoff: 
---

# Name the reconciliation reply once, in the catalog

## Overview

`workaholic:notify`'s standing rule is **the prompt is the ceiling — no self-authorized shapes**:
a session may emit only the notification events and post shapes its own routine prompt or
invoking command names, and this skill's catalog "describes the sanctioned wording for events a
session was already instructed to post, it never grants permission to post". So the
reconciliation reply cannot exist until it is named — in the catalog, and in the `[Moderate]`
routine template.

It also has a prior decision to answer by name rather than around. `[Consent]` was retired on
2026-08-06 and the catalog records the consequence: *"a human-merged pull request is announced by
nobody"*, and the purple-circle `Merged by <@U…>` shape was **erased** (qmu/workaholic#317). This
ticket does not reverse that. `[Consent]` announced *every* human merge as its own event; this
corrects a thread whose **last word is false** — the item is still being called in flight when it
is finished. A `review` unit's thread ending at `🟢 Implemented` after a later human merge stays
untouched, which is the same catalog's own words and is what keeps the narrowing checkable.

The ask names two states, and only one has a shape today: **merged** reuses `🟢 Implemented`;
**closed unmerged** has no shape at all and needs one. The operator asked for both in the record
this mission carries, which is the developer confirmation the ceiling rule requires.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/ux-principles.md` — the post is read by a person scanning a thread

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog; the single source for every shape and emoji
- `plugins/workaholic/skills/notify/SKILL.md` — the model, the bright line, and *The prompt is the ceiling*
- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the `[Moderate]` template, which must name the event it may post
- `scripts/test-workflow-scripts.mjs` — the drift pin: a template's copy is byte-identical to the catalog's
- `CLAUDE.md` — the behaviour record

## Implementation Steps

1. Add the reconciliation shape to `notifications.md` under `/moderate`'s entry, as the **single
   source**: the merged form (reusing `🟢 Implemented` with the pull request link) plus one
   sentence naming that it merged outside the loop, by whom and when, and the closed-unmerged
   form. Write the wording once; everything else reads it from there.
2. State in the same section **why the shape earns a post against the bright line**: it corrects a
   false last word in the item's own thread, addressed to whoever follows that item, exactly once
   — the inbound sweep's receipt is the precedent, not `🔧 Needs a decision`.
3. Answer `[Consent]`'s retirement **by name** in that section, and state the narrowing: only a
   thread whose last status reply is `🔵 Proposed` or `🟡 Handoff` is a candidate; a `🟢`-ended
   thread is never touched however it merged.
4. Name the shape in `plugins/workaholic/skills/workaholify/routines/moderate.md`, byte-identical
   to the catalog's copy — the template lists the events the tick may post and this is now one of
   them.
5. Extend the existing drift pin in `scripts/test-workflow-scripts.mjs` so the template's copy and
   the catalog's cannot diverge, exactly as the other shapes are pinned.
6. Update `CLAUDE.md` and `plugins/workaholic/rules/*.md` where they enumerate what the tick posts,
   in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The catalog names both forms (merged, closed unmerged) once, and the template's copy is byte-identical
- The section states why the shape earns a post and answers `[Consent]`'s retirement by name
- The narrowing is written: `🔵` and `🟡` only; a `🟢`-ended thread is never a candidate
- No second copy of the wording or the emoji exists anywhere in the plugin

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the drift pin fails on any divergence
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — `outputs/` regenerated and self-contained

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, including the extended pin
- `outputs/` is regenerated and committed; the `Outputs Freshness` CI diff is empty

## Considerations

- **The template is the ceiling, so this ticket gates the whole mission**: no step may post the
  reply until this lands. Order it before the step and the posting contract.
- Reusing `🟢 Implemented` rather than minting a fifth finish emoji is deliberate — the reader's
  question is *did this finish*, and a second green would make one event two vocabularies. The
  reconciliation is marked by its sentence, not by a new colour.
- A closed-unmerged form is genuinely new. Keep it as quiet as the others: one line, the pull
  request link, no mention token.

## Final Report

Development completed as planned.

`notify/reference/notifications.md` names both forms once, under `/moderate`'s entry: the merged
one **reuses `🟢 Implemented`** and is marked by its sentence rather than a fifth finish colour,
and `⚫ Closed` is genuinely new because *closed* and *merged* ask a reader for different things.
Both name by whom and when, both carry no mention token, and an unresolved author or time is stated
as unresolved rather than guessed. The `[Moderate]` template's copies are byte-identical and the
existing drift pin now covers them; the pin also asserts the exact five shapes the template
authorizes, so a sixth cannot appear in either document alone.

The section states why the shape earns a post against the bright line — it corrects a **false last
word** in the item's own thread, addressed to whoever follows that item, exactly once, on
`/propose`'s receipt precedent and emphatically not `🔧 Needs a decision`'s — and answers
`[Consent]`'s retirement **by name**: that routine announced every human merge as its own event,
while this corrects only a thread still calling the unit in flight. The narrowing is written and
pinned: `🔵 Proposed` and `🟡 Handoff` only, and a `🟢`-ended thread is never touched however it
merged.

### Discovered Insights

- **Insight**: the catalog's block-matching pin keys on a shape's first line, and the merged
  reconciliation reply's first line is byte-identical to `/implement`'s own finish line.
  **Context**: that is the reuse working as intended — one event, one vocabulary — but it means the
  pin must key on the two-line block, not the emoji. It does now, and a later shape that reuses a
  lead line has the same obligation.
- **Insight**: the template's own "one shape" paragraph and its "the one literal format below"
  sentence had already been false since the confirmation reply landed on 2026-08-24.
  **Context**: both were corrected here rather than left to accumulate — an ceiling that
  miscounts its own shapes is the ceiling rule failing quietly.
