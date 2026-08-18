---
created_at: 2026-08-18T20:20:56+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-draft-release-note-an-agent-s-release-plan
merge_policy:
verification_handoff: 
---

# Recover the substance of story-less merges

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

A plan is only as good as its input, and the most common input is the thinnest.
`draft-release-note.sh` prefers a branch story and falls back to the merge commit
body's pull request title when no story joined the merge. Issue #512 names why that
fallback is not rare: a `/propose` pull request is published through the publish
tree and auto-merges without ever running `/report`, so it **structurally** never
has a story — and proposal merges are this repository's most frequent merge kind.
The 2026-08-18 fix (issue #496) replaced a bare placeholder with the PR title,
which is a real improvement and stays; a title is still one clamped line where a
story is a paragraph of *why*.

The substance exists. A proposal merge carries a feedback record, and usually a
mission or a ticket, all of them on the base and all of them naming what the change
is for. This ticket makes those reachable to the planner for merges with no story.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/delivery.md` — the release path this note describes

## Key Files

- `plugins/workaholic/skills/ship/scripts/draft-release-note.sh` — the fallback
  chain lives in its header and its code; both are load-bearing records.
- `plugins/workaholic/skills/propose/scripts/read-feedback-relation.sh` — the one
  reader of `feedback:` lists; two parsers of one field eventually disagree.
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the one reader of
  the `mission:` relation.
- `plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` — owns the merge
  range; this ticket reads detail inside it, never re-derives it.

## Implementation Steps

1. **Reproduce and localize before designing.** Render the current draft for each
   target on the live base and count the lines whose only content is a pull request
   title with no story behind it. Record the measured ratio in the branch story —
   the ask asserts it is the most common path, and a measured number is what a
   later reader can act on.
2. Establish, from the merge range alone, what a story-less merge can be resolved
   to on the base: the `Closes #<N>` / `[Proposal]` shape of the merge body, the
   feedback record the proposal wrote, the mission or ticket it published. Use the
   existing single readers (`propose/scripts/read-feedback-relation.sh`,
   `mission/scripts/read-relation.sh`) — never a second parser of either field.
3. Add the resolved substance to what `draft-release-note.sh` hands the plan seam,
   as **additional detail on the same merge row**, not as a new selection rule: the
   renderer performs no selection today and this ticket introduces none (the
   reordering and capping readings were both refused on 2026-08-18 — do not revive
   them).
4. Keep it local git data plus base-tree reads wherever possible. Network enrichment
   stays behind the existing `--enrich` flag and off by default; a fallback that
   needs the network would make the CI render depend on it.
5. Preserve the idempotency contract: the same base state must still render the
   same detail.
6. Update `ship/SKILL.md` and `draft-release-note.sh`'s header with what the
   fallback chain now is, in order, and why each rung exists.

## Quality Gate

<!-- Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A merge with no branch story contributes more than its pull request title when
  the base carries a feedback record, mission or ticket that names its purpose.
- No merge is dropped, reordered or capped by this change.
- The same base state still renders byte-identical detail with `--enrich` off.
- The measured story-less ratio is recorded in the branch story.

**Verification method** — the commands/tests/probes that prove them:

- Render the draft twice on an unchanged base and `diff`.
- Render across a range containing at least one `[Proposal]` merge and confirm the
  resolved substance appears on that row.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Line count of the rendered `## Key Changes` is unchanged for a fixed range, the
  double-render diff is empty, and the smoke tests pass.

## Considerations

- The honest limit: a proposal's feedback record states what someone *asked for*,
  which is not always what the merge *did*. Label the resolved substance for what
  it is rather than presenting it as a story; a wrong summary is worse than a thin
  one.
- Resist widening this into "make `/propose` run `/report`". Proposal pull requests
  auto-merge by a 2026-08-11 decision that this mission does not reopen.
