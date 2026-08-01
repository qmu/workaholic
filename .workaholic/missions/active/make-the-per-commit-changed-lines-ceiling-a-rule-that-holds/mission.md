---
type: Mission
title: Make the per-commit changed-lines ceiling a rule that holds
slug: make-the-per-commit-changed-lines-ceiling-a-rule-that-holds
status: active
merge_policy:
created_at: 2026-07-30T10:19:42+00:00
author: noreply@anthropic.com
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [20260730190749-a-pure-relocation-cannot-fit-under.md, 20260730185714-the-foundation-commit-is-772-changed.md, 20260730111600-the-ticket-batch-convention-structurally-collides.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260801-210440
---

# Make the per-commit changed-lines ceiling a rule that holds

## Goal

Three feedback records, from three different pull requests, all say the same thing about the
same rule: `too-large-commit` is now overridden as a matter of routine, and one of them states
the conclusion outright — *"A rule that is always overridden stops measuring anything, and this
is now the pattern rather than the exception."*

The three instances, in order:

- **PR #103** ([fa8033d3](https://github.com/qmu/workaholic/commit/fa8033d3), 502 lines) — a
  four-ticket **spec** commit with no executable line in it. `create-ticket` caps a split at 2-4
  tickets and a ticket at this repository's density runs 110-140 lines, so *any* full ticket
  batch breaches the ceiling by construction.
- **PR #108** ([1179d916](https://github.com/qmu/workaholic/commit/1179d916), 772 lines) — an
  **implementation** commit (four scripts plus ~200 lines of hermetic tests). Here the ceiling
  measured what it was built to measure and the commit genuinely exceeded it; the named remedy
  is splitting at the scripts/tests seam, not changing the rule.
- **PR #109** ([044a3f8b](https://github.com/qmu/workaholic/commit/044a3f8b), 701 lines) — a pure
  **relocation**. `MAX_COMMIT_CHANGED_LINES` sums added *plus* deleted lines, so moving 260 lines
  costs 520 before any real work: a refactor-by-relocation cannot pass however well-scoped it is.

The rule's stated purpose (`release-scan/SKILL.md`) is to make commit count a comparable
throughput unit — a claim about implementation commits. Two of the three breaches are commits
that add no throughput at all (a spec batch, a move), so the metric is being distorted by exactly
the commits it was never meant to count. The direction the feedback asks for is to **decide the
rule once, deliberately, and record the reason** — not to override it a fourth time.

## Scope

Proposed: change what `too-large-commit` counts, in `release-scan/scripts/scan-branch-safety.sh`
and its `lib/`, so the ceiling stops firing on commits that add no throughput while still firing
on PR #108's implementation commit. The candidate answers the feedback names, to be chosen at
approval rather than here:

- discount pure renames/moves, which git already detects (`--find-renames`);
- count **added** lines only, rather than added+deleted;
- add an explicit spec-commit exemption with the reason recorded in `lib/`;
- or keep the rule and raise the ceiling with a stated reason.

Also in scope: whatever documentation states the rule (`release-scan/SKILL.md`, `CLAUDE.md`'s
release-safety section) updated in the same change, hermetic coverage in
`scripts/test-workflow-scripts.mjs` pinning the chosen semantics against the three real commits
above, and an `outputs/` rebuild since `release-scan` ships in the generated bundle.

Out of scope: the other `size` sub-rules (`MAX_FILES`, `MAX_FILE_ADDED_LINES`, `MAX_FILE_BYTES`),
the `secret` and `leak` tiers, and the separate question of whether a long `depends_on` chain
should be capped at one PR-unit — that is its own concern in the stream, not this rule.

## Experience

A developer shipping a ticket batch, a pure relocation, or a genuinely large implementation
commit gets three different, correct answers from one scan: the first two pass without an
override, and the third is still flagged. `/ship`'s deployment evidence stops accumulating
override records for commits nobody intended the rule to catch, so an override in the evidence
means something again.

## Acceptance

PROPOSED sketch for discussion — not a plan. `/mission approve` replans this to drive-ready.

- [ ] The chosen semantics for `too-large-commit` are decided and the reason is recorded in the
      scan's `lib/`, not only in a commit message
- [ ] `scan-branch-safety.sh` implements the chosen semantics
- [ ] Re-scanning [fa8033d3](https://github.com/qmu/workaholic/commit/fa8033d3) (spec batch) and
      [044a3f8b](https://github.com/qmu/workaholic/commit/044a3f8b) (pure relocation) yields no
      `too-large-commit` finding
- [ ] Re-scanning [1179d916](https://github.com/qmu/workaholic/commit/1179d916) (implementation,
      772 lines) still yields one
- [ ] `release-scan/SKILL.md` and `CLAUDE.md`'s release-safety paragraph describe the rule as
      implemented
- [ ] `node scripts/test-workflow-scripts.mjs` covers the new semantics hermetically
- [ ] `node scripts/build-plugins/build.mjs` rebuilt and `outputs/` committed in the same change

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
- 2026-08-01 — ticket archived — 20260801185101-decide-what-too-large-commit-counts.md
