---
created_at: 2026-08-01T18:51:02+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 2h
commit_hash:
category: Changed
depends_on: [20260801185101-decide-what-too-large-commit-counts.md]
mission: make-the-per-commit-changed-lines-ceiling-a-rule-that-holds
merge_policy: auto
---

# Implement the chosen commit-size semantics

## Overview

Implements whatever the decision ticket settled, and pins it against the real commits so
the semantics cannot drift back. The five instances are the test corpus, and they are
deliberately heterogeneous: a spec batch, an implementation commit, a pure relocation, and
two catch-up merges.

The implementation half is small; the test half is the ticket. A hermetic case must
reproduce each shape — a commit that only moves lines, a commit that only adds spec prose,
a merge commit, and a genuinely large implementation commit — and assert the verdict for
each. Pinning against the shapes rather than the SHAs is what keeps the corpus alive after
those commits age out of anyone's memory.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`; the scan is a script because a merge gate must be reproducible, not a model judgment.
- `workaholic:implementation` / `policies/command-scripts.md` — the rule lives in the scan's `lib/` and every consumer reads it there.
- `workaholic:development` / `policies/review.md` — the ceiling's purpose is reviewability; the tests must encode that, not the number.

## Key Files

- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` - the rule
- `plugins/workaholic/skills/release-scan/scripts/lib/` - shared rule internals and the recorded reason
- `scripts/test-workflow-scripts.mjs` - the hermetic corpus
- `plugins/workaholic/skills/release-scan/SKILL.md` and `CLAUDE.md` - the two places the rule is described

## Implementation Steps

1. Implement the decided semantics in `scan-branch-safety.sh` / its `lib/`.
2. Build the hermetic corpus by **shape**, in throwaway repositories: a pure relocation, a
   spec-only batch, a merge commit, and an oversized implementation commit. Assert the
   verdict for each.
3. Re-scan the five real commits as a sanity check, and record the outcomes in the ticket's
   Final Report. Do not make the suite depend on them — a hermetic test may not reach into
   this repository's history.
4. Update `release-scan/SKILL.md` and `CLAUDE.md`'s release-safety paragraph to describe
   the rule **as implemented**. The current text describes the old behavior and would
   become a lie in the same commit that changes it.
5. Rebuild `outputs/` — `release-scan` ships in the generated bundle.

## Quality Gate

**Acceptance criteria**

- `scan-branch-safety.sh` implements the decided semantics.
- Re-scanning `fa8033d3` (spec batch) and `044a3f8b` (pure relocation) yields no `too-large-commit` finding.
- Re-scanning `1179d916` (implementation, 772 lines) still yields one.
- A catch-up merge commit yields no finding.
- `release-scan/SKILL.md` and `CLAUDE.md`'s release-safety paragraph describe the rule as implemented.
- The other `size` sub-rules (`MAX_FILES`, `MAX_FILE_ADDED_LINES`, `MAX_FILE_BYTES`) and the `secret`/`leak` tiers are unchanged.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with hermetic cases per shape (relocation / spec-only / merge / oversized implementation) built in throwaway repositories.
- Manual re-scan of the five real commits, outcomes recorded in the Final Report.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no residual `outputs/` diff.

**Gate**

- The oversized implementation case still fires. A change that silences all five has not fixed the rule, it has removed it.

Decided: the hermetic corpus is built by shape rather than by referencing this repository's SHAs — the suite runs in throwaway repositories and may not depend on local history, and a shape survives the commits ageing out (developer may override at /drive).

## Considerations

- This mission's own implementation commit is a candidate for the ceiling it is changing. If it breaches, that is worth recording in the Final Report as evidence either way.

## Final Report

Implemented as decided. Re-scan of the real corpus, with the scan's own exclusions applied:

| commit | shape | added implementation | verdict | expected |
| --- | --- | ---: | --- | --- |
| `fa8033d3` | spec batch | 0 | passes | passes |
| `1179d916` | implementation | 702 | **fires** | fires |
| `044a3f8b` | relocation/split | 402 | passes | passes |
| catch-up merges | merge | — | skipped | passes |

All five instances now get the intended answer.

### Discovered Insights

- **Insight**: The hermetic corpus caught something the paper check could not. A relocation
  where git's rename detection *does* match (a 600-line file split with one part above the
  50% similarity threshold) is charged only for the genuinely new part — so it passes where
  the paper analysis predicted it would still fire. Rename detection and added-only overlap,
  and the overlap moves the boundary. The corpus now pins both shapes: the split `-M` can
  match, and the split it cannot.
  **Context**: This is why the corpus is built by shape rather than by SHA — the shapes
  disagree with each other in ways a single real commit never revealed.

- **Insight**: The existing suite had a case asserting *"deletions count toward the
  per-commit total"* — it pinned the old semantics precisely and correctly. Inverting it was
  the right move and worth doing loudly: the comment now names the decision and says the
  assertion was flipped deliberately, so a future reader does not "restore" it as a
  regression.
  **Context**: A test that encodes a decision should cite where the decision lives, or the
  next person to read it cannot tell a deliberate inversion from a bug.

- **Insight**: The finding's field is `evidence`, not `detail`. Worth noting only because
  the assertion that checked it passed the *count* and failed the *content* — the rule fired
  correctly while the test looked at a field that does not exist, which reads as a rule
  defect for as long as it takes to check the serializer.
