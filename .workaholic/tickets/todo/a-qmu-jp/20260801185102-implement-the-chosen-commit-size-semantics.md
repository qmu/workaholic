---
created_at: 2026-08-01T18:51:02+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
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
