---
created_at: 2026-09-01T08:32:37+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-where-the-work-stands-not-only-what-is-wrong
merge_policy:
verification_handoff: 
---

# Read the plan's shape at the mission grain

## Overview

The operator's question — "so how many todos are left?" — is answered today by four ad-hoc
git commands over the bundle. Every reader the loop needs already exists and none of them
is composed at the grain the question asks: `digest.sh` reports per **strategy** what
moved and what waits, `attributed-work.sh` already counts `waiting_missions` and names
`waiting_mission_slugs`, `progress.sh` computes a mission's `checked`/`total`, and
`queue-size.sh` counts a mission's queued tickets. What is missing is a reading that puts
them together: per direction its missions, per mission its acceptance progress and queued
count, and the repository's total queued.

This ticket adds that reading and nothing else — no post, no render, no new relation and no
field on any artifact. `digest.sh` is a pure read and stays one.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a degraded read is named, never rendered as an empty one
- `workaholic:implementation` / `policies/command-scripts.md` — one derivation, many consumers

## Key Files

- `plugins/workaholic/skills/standup/scripts/digest.sh` — the one derivation `/standup` and
  `/moderate`'s `strategy-digest` both read; its per-strategy record is what gains the
  mission grain. Read its header first: the caps, the honesty line and the null-on-degraded
  rule are all load-bearing.
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — already answers which
  missions belong to a direction (`waiting_mission_slugs`); the only attribution reader.
- `plugins/workaholic/skills/mission/scripts/progress.sh` — `checked` / `total` / `unlinked`,
  computed and never stored.
- `plugins/workaholic/skills/mission/scripts/queue-size.sh` — a mission's queued count.
- `plugins/workaholic/skills/drive/scripts/list-todo.sh` — the queue, for the repository total.
- `scripts/test-workflow-scripts.mjs` — the hermetic assertions.

## Implementation Steps

1. **Reproduce the reading by hand first**, on this repository: list the active strategies,
   their attributed active missions, each mission's `progress.sh` and `queue-size.sh`, and
   the total queued. Write the numbers down — they are the fixture the assertion checks
   against and the proof the composition needs no new walker.
2. **Localize** where the grain belongs: `digest.sh`'s per-strategy record already carries
   `waiting_count` and a capped `waiting[]` of tickets. Add a sibling `missions[]` block
   rather than reshaping either — the existing fields have two consumers and a render each.
3. Compose `attributed-work.sh`'s `waiting_mission_slugs` into one entry per mission
   carrying its slug, title, `checked`/`total` and queued count; add the repository's
   `queued_total` beside the existing top-level counts.
4. Hold the header's three standing rules: the render caps (`STANDUP_MAX_STRATEGIES`,
   `STANDUP_MAX_ITEMS`) apply to the new block too and every cut is counted in an
   `*_omitted` field; a mission whose progress or queue could not be read is named with its
   reason and **null** counts, never a zero; a degraded attribution walk already makes the
   whole strategy record `readable: false` and must keep doing so.
5. Add no reader and no relation. `mission-strategy.sh` stays the inverse reader,
   `attributed-work.sh` stays the only walker, and no artifact gains a field.
6. Add hermetic assertions: a fixture repository with two strategies, three missions and a
   queue produces the expected `missions[]` and `queued_total`; a mission whose progress
   read fails is named with null counts rather than dropped; the existing `digest.sh` rows
   still pass unchanged.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `digest.sh` reports, per strategy, its active missions with each mission's acceptance
  `checked`/`total` and queued count, plus a repository-level `queued_total`.
- Every existing field of `digest.sh`'s output is unchanged in name and meaning.
- A mission grain that could not be read is named with its reason and null counts.
- No new attribution reader, relation or artifact field is introduced.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new rows plus the existing `digest.sh` rows)
- `bash plugins/workaholic/skills/standup/scripts/digest.sh` on this repository, compared
  against the step-1 hand reading

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes and `digest.sh` remains a pure read: no
  file, commit, branch, pull request, merge, deployment or network call.

## Considerations

- The composition is O(missions × 2 script calls). On a repository with many active
  missions that is the cost worth watching; the caps bound the *render*, not the walk, so
  if the walk itself needs bounding, bound it by name and count what was cut.
- `attributed-work.sh` is transitive and lossy by design (`exhaustive: false`). A mission
  no direction claims is `unattributed-work.sh`'s subject and must not be invented into a
  direction here.

## Final Report

Development completed as planned.

The hand reading came first, on this repository: one active direction
(`an-autonomous-improvement-loop-run-by-the-routines`), seven attributed active missions,
each mission's `progress.sh` and `queue-size.sh`, and 42 queued tickets. `digest.sh` now
reproduces exactly those numbers — the top three missions read 0/3 with 6, 3 and 3 queued,
and `queued_total` is 42, matching `plan-units.sh`'s own `backlog_size`.

The grain is a sibling `missions[]` block on the per-strategy record plus a top-level
`queued_total`, composed from readers that already existed: `attributed-work.sh` supplies
`waiting_mission_slugs` and, in `artifacts[]`, each mission's title and path;
`progress.sh` gives `checked`/`total`; `queue-size.sh` gives the queued count;
`list-todo.sh` is the repository's queue. No relation is parsed here, no second walker was
added, and no artifact gained a field.

### Discovered Insights

- **Insight**: `attributed-work.sh`'s `artifacts[]` already carries every attributed
  mission with its `title`, `path` and `state`, so the mission grain needs no frontmatter
  parse and no call to `mission/scripts/list.sh`.
  **Context**: `mission/scripts/list.sh` hardcodes a cwd-relative `.workaholic/missions`,
  so it could not have honoured `digest.sh`'s own root argument. Composing off the reader's
  existing payload is both cheaper and the only root-correct option.

- **Insight**: `progress.sh` derives its mission root from the artifact path it is handed
  (`missions_root_from_artifact`), and only falls back to the repository root for a bare
  slug — so passing the path from `artifacts[]` is what keeps a worktree's mission from
  being read out of a sibling worktree.
  **Context**: the same slug exists in several worktrees during a normal drive; a bare-slug
  read there is silently wrong rather than an error.

- **Insight**: `waiting_mission_slugs` names every attributed **active** mission, not only
  those with queued tickets — the name reads narrower than the derivation is.
  **Context**: it is what makes the block answer "the missions serving this direction"
  rather than "the missions with something left", which is the question the operator asked.
