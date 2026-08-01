---
created_at: 2026-08-01T18:48:02+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on: [20260801184801-survey-ship-and-record-the-release-tier-decision.md]
mission: adopt-a-git-flow-branching-model-with-durable-ship-records
merge_policy: auto
---

# Cut and promote a release branch as a staging window

## Overview

Today a unit's merge into `main` **is** the production release: there is no window in
which a batch of merged units can be verified together before it reaches production. This
ticket adds that window, and only that — `release/*` cut from `main` at promotion time,
held open for QA, and confirmed.

The per-unit path is untouched by construction: a unit still claims, drives, reports and
merges into `main` exactly as today. There is still exactly one merge target for a unit,
which is why the two hardest questions from the original draft (the claim protocol against
a second base, and what `merge_policy` means under two targets) do not arise.

`hooks/guard-git-branch.sh` currently blocks any branch name that is not
`work-YYYYMMDD-HHMMSS`, so it will block the release cut until its allowlist recognizes
the new tier. That gate is why this cannot be worked around by hand.

## Policies

- `workaholic:operation` / `policies/deployment-pipeline.md` — a staging tier is a delivery-path change and must be reproducible from a script, not a habit.
- `workaholic:operation` / `policies/rollback.md` — an unconfirmed release branch is the rollback boundary; state what happens when confirmation fails.
- `workaholic:implementation` / `policies/command-scripts.md` — the cut and the promotion are scripts, never inline shell in command markdown.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`.

## Key Files

- `plugins/workaholic/hooks/guard-git-branch.sh` - blocks off-pattern branch creation; must learn `release/*`
- `plugins/workaholic/skills/branching/scripts/create.sh` - the canonical branch creator and the model to follow
- `plugins/workaholic/skills/ship/SKILL.md` - where the promotion step is documented
- `plugins/workaholic/skills/ship/scripts/publish-release.sh` - may be re-pointed at the release branch, never removed
- `scripts/test-workflow-scripts.mjs` - hermetic coverage

## Implementation Steps

1. Add a `release/*` form to `hooks/guard-git-branch.sh`'s allowlist, alongside the
   unchanged `work-YYYYMMDD-HHMMSS` pattern. Keep the gate closed to everything else.
2. Add the cut script under `branching/scripts/` — cut from `origin/main` at a named
   commit, refuse if the name already exists, emit JSON. Follow `create.sh`'s shape.
3. Add the promotion/confirmation step to `ship`, documented in `ship/SKILL.md`: the
   window opens at the cut, confirmation is the existing evidence-gated doctrine, and the
   confirmed branch is what gets deployed/tagged.
4. State the failure path explicitly: a release branch whose confirmation fails is **not**
   deleted — it is the rollback boundary, and `main` is unaffected because the units are
   already merged there.
5. Never prompt: the flow runs unattended like the rest of `/ship`.

## Quality Gate

**Acceptance criteria**

- `guard-git-branch.sh` permits `release/*` and still blocks every other off-pattern name; the `work-*` pattern is unchanged.
- A release branch can be cut from `main` by script, and the script refuses a name that already exists.
- `ship/SKILL.md` documents the cut, the staging window, the confirmation, what is deployed/tagged, and what happens when confirmation fails.
- Per-unit claim/drive/ship behavior is observably unchanged: the existing claim and ship tests stay green **without modification**.
- No `AskUserQuestion` anywhere in the flow.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with new cases for: the guard accepting `release/*` and still rejecting a random name, the cut script's refusal on a duplicate, and the existing claim/ship suites unmodified.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no residual `outputs/` diff.

**Gate**

- The existing claim and ship tests pass **unmodified**. If they needed editing, the per-unit path was changed, which this mission puts out of scope.

Decided: the cut is a separate script rather than a flag on `create.sh` — `create.sh` mints the `work-*` name the claim protocol depends on, and overloading it with a second naming scheme would put the claim's branch invariant one bug away from a release branch (developer may override at /drive).

## Considerations

- `claims_scan` keys on a `Claim <unit-id>` commit subject rather than a branch name, so a `release/*` branch is never mistaken for a claim. Verify that rather than assuming it (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).
