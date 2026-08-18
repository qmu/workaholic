---
created_at: 2026-08-18T06:52:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: []
merge_policy:
verification_handoff: 
---

# check-version-bump reads a stale local main

## Overview

<!-- MINTED MID-RUN by an /implement unit (branch `work-20260818-063646`), under the failure
     contract's "an observation outside the current ticket's scope becomes a ticket". -->

`branching/scripts/check-version-bump.sh` answers "has this branch already bumped the version?"
with `git log main..HEAD --grep="Bump version"`. It reads the **local** `main` ref, which in a
claim worktree is whatever the container's checkout happened to have — the claim branch is cut
from `origin/main`, and nothing on the drive path updates local `main`.

**Measured, not hypothesised.** On 2026-08-18 in worktree `batch-20260818063646`, local `main`
stood at `6e0cb9e9` while `origin/main` was `a871103d` — hundreds of commits apart. The branch
carried **no** version bump, and the script returned `{"already_bumped": true}`, because the
stale range swept up every `Bump version to vX` commit that had landed on the base since. The
run noticed only because it read the version files directly; a run that trusted the answer would
have shipped plugin changes on an unbumped version, silently.

The failure mode is one-directional and silent: a stale local `main` can only ever produce a
**false** `already_bumped: true` — the answer that skips the bump. There is no symmetric case
where it wrongly forces one.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a workflow check that answers wrongly
  and silently is worse than one that refuses

## Key Files

- `plugins/workaholic/skills/branching/scripts/check-version-bump.sh` — the whole defect is its
  one `git log main..HEAD` line. Every other branching script that needs the base resolves it
  properly; compare `sync-main.sh` and `drive/scripts/plan-units.sh`, which use `origin/main`
  and report `current`/`fetched` rather than assuming.
- `plugins/workaholic/skills/report/SKILL.md` — Phase 0 is the caller ("bump the version unless
  `check-version-bump.sh` says `already_bumped`"), so the caller's contract may need to say what
  a degraded read means.
- `scripts/test-workflow-scripts.mjs` — the hermetic harness already builds throwaway repos with
  a divergent local base (see the `mission worktree starts from the merged base (fetch-first)`
  block), which is the fixture shape this needs.

## Implementation Steps

1. Reproduce first, before changing anything: build a fixture whose local `main` trails
   `origin/main` across a `Bump version to vX` commit, with **no** bump on the branch, and assert
   the current script answers `already_bumped: true`. The test must fail before the fix.
2. Resolve the base the way the rest of the drive path does — `origin/main`, not `main` — and
   decide explicitly what happens when it cannot be resolved (no origin, an unfetched remote).
   **Do not silently fall back to local `main`**: that is the current behaviour and the defect.
   A read the script cannot make should be reported as such, in the JSON, with its reason named.
3. Give the output a field the caller can act on (the branching scripts' existing convention:
   an `ok`/reason pair, or a `base` naming what was actually compared against), so a degraded
   read is distinguishable from a genuine `already_bumped: true`.
4. State in `report/SKILL.md` Phase 0 what the caller does with a degraded read. Bumping when
   unsure is the safe direction — a redundant bump is a no-op commit a human can drop, while a
   skipped one ships plugin changes on a stale version.
5. Re-run the step-1 fixture and the full smoke suite.

## Open Decisions

<!-- Recorded, not resolved: this run minted the ticket while driving something else. -->

1. **Should the script fetch, or only read?** `sync-main.sh` fetches; this is a pure predicate
   called from inside a worktree, and a network call in a predicate is a new failure mode for
   every caller. Reading `origin/main` as-last-fetched is probably right — the drive path has
   already fetched by the time `/report` runs — but that makes the answer depend on a caller's
   earlier act, which should be stated rather than assumed.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A branch with no version bump reports `already_bumped: false` even when local `main` is
  arbitrarily stale relative to `origin/main`.
- A branch that genuinely carries a `Bump version` commit still reports `already_bumped: true`.
- A base the script cannot resolve is reported by name in the JSON, never answered as
  `already_bumped: true`.
- `report/SKILL.md` Phase 0 states what the caller does with a degraded read.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the new stale-local-`main` fixture, which
  must be demonstrated failing against the unfixed script before the fix lands
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`

**Gate** — what must pass before approval:

- All of the above, plus the Final Report naming which direction the script errs in when the
  base is unresolvable, and why.

## Considerations

- **The blast radius is every plugin-touching branch driven in a container.** A cloud session's
  checkout is cloned fresh and the harness may hand it its own branch, so a stale local `main`
  is the normal state there, not an edge case. How many past branches shipped unbumped is
  answerable from git history and worth a look while fixing this.
- **Do not "fix" this by having `/report` bump unconditionally.** The predicate exists so a
  re-run of `/report` on the same branch does not stack a second bump commit; removing it trades
  one silent wrong answer for a different one.
- This ticket was minted by a run driving an unrelated rename, which is why it carries no
  `feedback:` reference — nobody reported it; a run tripped over it.
