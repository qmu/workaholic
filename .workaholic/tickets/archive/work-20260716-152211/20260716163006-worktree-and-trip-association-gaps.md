---
created_at: 2026-07-16T16:30:06+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
---

# ensure-worktree.sh lacks the exclude guard its mission sibling has, and the trip↔branch association is undefined

## Overview

Promoted from two triaged deferred concerns (2026-07-16 triage-to-zero;
verdicts verified against source):

1. **`ensure-worktree-sh-lacks-the-git`** — `create-mission-worktree.sh` writes
   `.worktrees/` and `.env` into `.git/info/exclude` so a stray `git add -A` in
   the main tree never embeds a linked worktree as a gitlink;
   `ensure-worktree.sh` (trip/drive worktrees) has no such block, so the risk
   remains latent for non-mission worktrees.
2. **`the-trip-branch-association-does-not`** — `detect-context.sh` resolves
   `trip_name` only for legacy `trip/*` branches; a `work-*` branch emits no
   trip association, so report's Trip Mode is unreachable end-to-end from the
   branches the flow actually creates. The gap is documented but the
   association itself was never defined.

## Key Files

- `plugins/workaholic/skills/branching/scripts/ensure-worktree.sh` — missing the exclude block
- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` — the block to port
- `plugins/workaholic/skills/branching/scripts/detect-context.sh` — `branch_trip_dir` (trip/* only)
- `plugins/workaholic/skills/report/SKILL.md` (~80) — the Trip Mode consumer
- `scripts/test-workflow-scripts.mjs` — `testEnsureWorktreeGuard`, `testDetectContext`

## Implementation Steps

1. Port the `.git/info/exclude` block from `create-mission-worktree.sh` into `ensure-worktree.sh` (git-common-dir-relative, idempotent), with a test that a stray `git add -A` in the main tree stages no gitlink.
2. Decide and document the trip↔branch association as its own recorded decision (e.g. the trip dir names the branch it drove in its Event Log, or `detect-context.sh` maps a `work-*` branch to a trip via `.workaholic/trips/*/`), then make `detect-context.sh` answer `has_trips` **and** `trip_name` together for the chosen association. Until decided, `mode: trip` staying reachable only from `trip/*` is the honest state — do not fake the link.
3. Rebuild `outputs/` (branching scripts are bundled).

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — the exclude guard is copied logic; extract or port it verbatim so the two creators cannot drift.
- `workaholic:planning` / `policies/modeling-centric-design.md` — the trip↔branch association is a model decision (what relates a session to a branch), to be decided and recorded before code encodes a guess.

## Quality Gate

- After `ensure-worktree.sh` creates a worktree, `git add -A` in the main tree stages nothing under `.worktrees/`; pinned by test.
- The trip↔branch association is recorded (decision + rationale) and `detect-context.sh` emits `trip_name` for whichever branches the decision covers; report's Trip Mode is reachable from a branch the current flow actually creates, or the decision explicitly retires Trip Mode.
- `node scripts/test-workflow-scripts.mjs` green; `build.mjs`/`verify.mjs` green after rebuild.

## Considerations

- Step 2 may legitimately conclude "retire legacy Trip Mode" — the deliverable is the recorded decision and matching code, not necessarily a new association.

## Final Report

Development completed as planned. The exclude guard was extracted into `branching/scripts/lib/ensure-git-excludes.sh` (both creators source it — extraction rather than a verbatim copy, per the coding-standards policy note). For step 2 the decision is to **define** the association, not retire Trip Mode: a trip's `plan.md` names the branch it drives via a `branch:` frontmatter field, stamped by `init-trip.sh` from its working directory's checkout; `detect-context.sh` resolves `work-*` branches through that field and now emits `trip_name` alongside `mode`, making report's Trip Mode reachable end-to-end. Trips predating the field carry no `branch:` line and never match a `work-*` branch — the detector still refuses to guess. The decision and rationale are recorded in `trip-protocol/SKILL.md`'s Plan Document section.

### Discovered Insights

- **Insight**: The trip artifacts live inside the branch's own checkout, so the branch "contains" its trip dir — but containment is not an association: a trip dir inherited from main is indistinguishable from one authored on this branch without either a diff query or a recorded field. The recorded field is strictly simpler and survives merges.
  **Context**: When relating a session artifact to a branch, record the relation in the artifact at creation time; deriving it later from git topology is where the previous repo-wide-find defect came from.
