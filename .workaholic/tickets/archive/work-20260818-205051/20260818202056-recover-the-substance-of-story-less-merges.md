---
created_at: 2026-08-18T20:20:56+00:00
status: done
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

## Final Report

Development completed as planned.

**Measured first.** Over `v1.0.170..origin/main` this repository carries **68 merges, 38
of which (56%) have no branch story** — the ask's assertion holds, and the majority of
them are `[Proposal]` merges, which structurally never run `/report`. That is the number a
later reader can act on, and it is why a thin rung on this path is expensive.

**What a story-less merge resolves to.** `resolve-merge-substance.sh` takes the merge's
own diff against its first parent — the files that merge brought in — and reads the base
checkout for their titles, exactly as the story rung already reads
`.workaholic/stories/`. Three rungs of detail, each labelled for what it actually is:
`Asked for: <feedback title> (feedback \`<stem>\`)`, `Planned as: mission "<title>", N
ticket(s) queued`, or `Queued: N ticket(s)`. The labels answer the Considerations' warning
directly: a feedback record states what somebody *asked for*, which is not always what the
merge *did*, so nothing here presents itself as a summary of the change.

**No selection was introduced.** The detail renders as sub-bullets on the merge's own row.
The top-level row count is unchanged, order is unchanged, nothing is capped, a merge that
published no artifact renders byte-identically to before, and a merge that *has* a story is
never asked — a second summary beside a story would only compete with it. Neither the
`feedback:` nor the `mission:` relation is parsed: the script discovers paths from a diff
and reads a `title:` field, so each relation keeps its single reader.

The detail also reaches the plan seam. The facts a plan arranges carry it after the line
(RS-separated), so a planned note and a planless one carry the same rows and the same
detail — the plan decides only where each row sits.

Verification: the suite passes at **3128 assertions**, of which 8 are the new `release
note: a story-less merge keeps its substance` fixture — a proposal merge publishing a
record, a mission and two tickets; a merge publishing nothing; a story-bearing merge; the
row count; and a double render proving byte-identical output. `posix-lint.sh`, `build.mjs`,
`verify.mjs` and `layout-doctor.sh` are clean.

### Discovered Insights

- **Insight**: the merge sha was not available where the substance is needed — the
  renderer's per-merge record carried only the subject and the body.
  **Context**: adding `%H` as a first field was the whole enabling change; without it the
  detail would have needed a second traversal of the range, which the header explicitly
  forbids ("the unreleased set comes from `read-deploy-state.sh` and is not re-derived").
- **Insight**: reading the artifact's title from the **base checkout** rather than from the
  merge commit is what keeps this consistent with the story rung.
  **Context**: both then answer the same way when a file was later renamed or deleted —
  the rung simply falls silent — instead of one rung describing a tree the reader cannot
  see any more.
- **Insight**: a proposal merge's diff is a reliable index of what it published, because
  `/propose` publishes the record, the mission and the tickets in **one** pull request.
  **Context**: that is a property of the publish tree, not a coincidence, so the resolution
  is as stable as the publish seam itself — and a merge that published nothing simply
  yields no lines.
