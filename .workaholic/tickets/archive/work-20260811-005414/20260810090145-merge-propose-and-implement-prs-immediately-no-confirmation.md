---
created_at: 2026-08-10T09:01:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split
merge_policy:
---

# Merge propose and implement PRs immediately, no confirmation

## Overview

FB `20260810090035` asks that `/propose`'s and `/implement`'s own pull
requests stop waiting for human confirmation — merge immediately once
created. Today this is not a small flag flip: `publish-tree-pr.sh` (used by
`/propose`) deliberately never merges what it pushes — "merging that pull
request is the approval" (decision K1) is the load-bearing sentence behind
the entire `merge_policy`/claim-protocol trust model, and `/implement`'s
`review` route (`effective-policy.sh`, absent = review) exists specifically
to stop at the PR. This ticket changes both seams to merge their own PR
right after opening it (subject to the release-scan gates, which stay
non-overridable/overridable exactly as documented) and updates the routine
templates and `workaholic:notify` post shapes to the simplified form the
developer specified: no separate "started" post, one finish line per PR
(`🔵 Proposed` / `🟢 Implemented`).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/deployment-and-release.md` — what changes when merge-to-main is no longer human-gated
- `workaholic:development` / `policies/managing-change-history.md` — distributing this policy/template change as a plugin update

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — never merges today; needs an opt-in immediate-merge path for these two callers only
- `plugins/workaholic/skills/propose/SKILL.md` and `reference/workflow.md` — step 9's "one pull request... for humans to discuss and accept" framing
- `plugins/workaholic/skills/drive/SKILL.md` — `effective-policy.sh`'s `review` route ("absent = review", "stop at the PR")
- `plugins/workaholic/skills/notify/SKILL.md` and `reference/notifications.md` — post shapes; drop the 🟠/📐 "started" post for these two flows, add the simplified `🔵 Proposed` / `🟢 Implemented` finish shapes
- `plugins/workaholic/skills/workaholify/routines/fb.md`, `implement.md` — the routine prompts, matched to the developer's two example templates
- `CLAUDE.md` (K1's statement, the `/propose` and `/implement` command rows, `merge_policy` description) — every place that currently says "merging the PR is the approval" for these two flows needs to say what replaces it

## Implementation Steps

1. Decide and record the mechanism precisely: does `/propose`'s emitted
   mission/ticket set now default to `merge_policy: auto` (so `/implement`
   later ships it through the existing evidence-gated `/ship` doctrine), or
   does `/propose` itself merge its own capture PR immediately (separate
   from the mission/ticket's own later `merge_policy`)? These are different
   claims — the developer's message says "once a pull request is created,
   merge it immediately," which reads as the PR-immediate-merge form, not a
   `merge_policy` default change; confirm which before writing code, since
   conflating them changes what "the developer reviews before it merges"
   still means for driven work.
2. Add the immediate-merge step: after a successful push in
   `publish-tree-pr.sh` (or a thin wrapper only `/propose`/`/implement` use,
   to avoid silently changing every other publish-tree caller such as
   `/ticket` and `/mission`), run the release-scan gate and merge via the
   GitHub API/`gh`, non-overridable on a `secret` finding exactly as today.
3. Update `workaholic:notify`'s shapes and the two routine templates to the
   developer's simplified form (drop the start post; one finish line).
4. Update every doc that currently states K1 ("merging the PR is the
   approval") for `/propose`/`/implement` specifically, without disturbing
   `/ticket`'s and `/mission`'s own PRs, which this ticket does not touch.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `/propose`- or `/implement`-produced pull request merges automatically once pushed, with no human confirmation step, unless a `secret` finding blocks it.
- The `🔵 Proposed` / `🟢 Implemented` notify shapes replace the current start+finish pair for these two flows, matching the developer's example templates.
- `/ticket`'s and `/mission`'s own publish-tree PRs are unaffected — this ticket is scoped to `/propose` and `/implement` only.

**Verification method** — the commands/tests/probes that prove them:

- Run `/propose` against a real feedback ask end to end and confirm the PR is merged without a manual step.
- `node scripts/test-workflow-scripts.mjs` and `node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The mechanism decision in step 1 is confirmed with the developer before merging this ticket, since it changes a foundational trust decision (K1) — this ticket's own Considerations flag that it should not be treated as self-evidently safe to auto-merge under the very policy it is proposing.

## Considerations

- This ticket removes the human review gate from exactly the seam that currently provides it for AI-authored missions/tickets — the developer's own stated justification (a not-yet-existing QA loop, release-planning loop, and post-release quality-check loop) is the actual safety net; this ticket should not land ahead of at least a credible plan for those loops (see the companion ticket that scopes them).
- Decide whether `/ticket`'s and `/mission`'s own PRs (developer-authored specs, not AI proposals) stay human-reviewed — the feedback only asked about "the proposal's increment," which this ticket reads as `/propose`/`/implement` specifically, not every publish-tree writer.
- The release-scan gate (`secret` hard block, `size`/`leak` overridable) is the only mechanical check left standing once human review is removed here — confirm its coverage is adequate for this new role before relying on it as the sole automated backstop.
