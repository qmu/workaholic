---
created_at: 2026-09-02T04:26:30+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Let the tick merge what it resolved

## Overview

PROPOSED. Resolving a conflict and stopping there leaves the pull request open, which is the
stagnation the operator is describing. The instruction is to bring every conflicted pull
request into a mergeable state **and merge it**.

`/moderate` today states, as a bound, that it never merges a pull request. The operator has
ruled otherwise for this class. This ticket carries the merge and rewrites the bound to say
what is now true.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — delivery is part of the act, not a separate hope

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-method.sh` — the one derivation of the
  merge method; the new call site reads it and never spells it (the suite fails on a literal).
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one transport; the merge is a
  REST `PUT .../merge`, never `gh pr merge`.
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` and
  `plugins/workaholic/skills/drive/scripts/retry-undelivered.sh` — existing merge call
  sites whose refusal vocabulary (`merge_reason`) this reuses rather than inventing.
- `plugins/workaholic/skills/branching/scripts/settle-stranded-publication.sh` — already
  merges after settling; the shape to follow.
- `plugins/workaholic/skills/moderate/SKILL.md`, `CLAUDE.md` — the "never merges" bound.
- `plugins/workaholic/skills/release-scan/scan-branch-safety.sh` — the gate that runs
  before any merge and is not widened by this.

## Implementation Steps

1. After a successful resolution and push, run the release-safety scan and merge only on
   `pass` or `override_only` — the existing tier policy through `gate-decision.sh`. A
   `secret` finding hard-stops and is never overridden; a `leak` finding holds the pull
   request open. Resolving does not lower a gate.
2. Merge through the existing REST seam, reading the method from `merge-method.sh`, and
   report the outcome in the existing merge vocabulary (`merged` / `merge_refused: <word>`).
3. Handle `session_type_cannot_merge` as the one retryable refusal, through
   `mcp__github__merge_pull_request`, once, reporting both outcomes by name — the same
   qualification every other merge call site holds.
4. Report what the tick did, per pull request, in the step's summary and in the channel
   line: resolved and merged, resolved and refused with the word, or not attempted with the
   reason. The operator's standing expectation is that the tick reports what it **did**.
5. Rewrite the bound in `workaholic:moderate` and `CLAUDE.md`: the tick merges the pull
   requests it resolved, and here is what it still never does. A stale "never merges"
   sentence beside a merging tick is worse than no sentence.
6. Add a hermetic assertion that the scan runs before the merge and that a `secret` finding
   leaves the pull request open.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A pull request the tick resolved is merged by the tick, or refused with a named word.
- The release-safety scan runs before every such merge and is never overridden.
- The bounds prose states what the tick now does.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

**Gate** — what must pass before approval:

- The suite still fails on a literal merge method at the new call site.
- The scan-before-merge assertion fails when the order is reversed.

## Considerations

- This is the largest widening in the mission: an unattended hourly tick that merges. The
  brakes that stay are the scan, the fast checks from the sibling ticket, and the named
  refusal vocabulary. State them together in the bounds prose so the widening is legible
  rather than discovered.
