---
created_at: 2026-08-31T18:20:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Rule which ref the tick log lives on

## Overview

PROPOSED. The operator ruled the direction — the tick log moves to a dedicated ref
in this same repository — and left the ref itself to be answered. This ticket
answers it once, in writing, so the six tickets after it implement one decision
rather than each inventing their own: **which ref**, **how it is created on a
repository that has never had one**, **how a fresh container fetches it**, and
what the two mechanisms that already read refs must say about it.

The namespace question is already measured and must not be re-opened by guess:
`drive/reference/claims.md` records that `refs/claims/*` answers `RPC failed; HTTP
403` on create **and** on delete over both transports, and that `refs/heads/*` is
the only writable namespace in a routine's container. A design that needs a
custom namespace is therefore not implementable where it has to run.

Two mechanisms already read `refs/heads/*` and both need an explicit rule about
the new ref, or it will be misread the hour it appears:

- `drive/scripts/list-claims.sh` — **unmerged remote branches are the only claim
  oracle**, so a log ref under `refs/heads/` is a claim candidate unless it is
  excluded by name.
- `hooks/guard-git-branch.sh` — exactly two literal branch patterns are
  permitted (`work-YYYYMMDD-HHMMSS`, `release/YYYYMMDD-HHMMSS`); everything else
  is blocked at the agent's Bash surface.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an operational log is read, not reviewed

## Key Files

- `plugins/workaholic/skills/moderate/SKILL.md` — the tick log's model; the new
  ref's name, creation and fetch are stated here, once, as the mechanism's home.
- `plugins/workaholic/skills/drive/reference/claims.md` — the measured 403
  evidence for `refs/claims/*` and the `refs/heads/*` writability finding.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle
  that must not read the log ref as a claim.
- `plugins/workaholic/hooks/guard-git-branch.sh` — the branch-name gate.
- `plugins/workaholic/rules/workaholic.md`, `CLAUDE.md` — the current statement
  that the tick "commits its own log to the base through the publish tree".

## Implementation Steps

1. **Reproduce the constraint before designing against it.** In this container,
   attempt one push into a non-`refs/heads/` namespace and record the exact
   response beside `claims.md`'s. A design built on a namespace that answers 403
   here is unimplementable, and finding that out in ticket 2 costs the mission.
2. Establish how a routine's container sees refs today: what the clone's
   refspec fetches, whether it is shallow, and what a single named ref costs to
   fetch. Record the commands and their measured output.
3. Decide the ref, and write the decision down with its reason: the name, the
   namespace it sits in, and why a reader that already walks `refs/heads/*`
   (`list-claims.sh`) will not confuse it with a claim.
4. Decide how it is created on a repository that has never carried one — the
   first tick creates it, or `/workaholify` does — and state which, with the
   failure mode of the other named.
5. Decide how a fresh container reaches it, as an exact command with its bound
   and its named failure (a fetch that cannot reach the ref is a degradation the
   tick reports, never a silent empty log).
6. Write the ruling into `workaholic:moderate` as the mechanism's one home, and
   update `CLAUDE.md` and `rules/workaholic.md` in the same change.
7. State, in the same place, what `list-claims.sh` and `guard-git-branch.sh` must
   each say about the ref. Implementing them is ticket 2's; **naming** them is
   this ticket's, so ticket 2 has one specification to satisfy.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:moderate` names the ref, its creation path, and the exact fetch a
  fresh container runs, each with its named failure mode.
- The namespace choice cites the measured response from step 1, not `claims.md`
  alone.
- `CLAUDE.md` and `rules/workaholic.md` no longer say the tick commits its log to
  the base, and say what it does instead.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- Read back the three documents and confirm no surface still describes the
  publish-tree-to-base path for the log.

**Gate** — what must pass before approval:

- The push probe in step 1 was actually run and its output is quoted in the
  ruling. A ruling that only cites an earlier document has not measured anything.

## Considerations

- The ref is not a branch anybody drives, so nothing about the claim protocol,
  the heartbeat or the worktree model changes. Say so explicitly, or a later
  reader will assume it does.
- Ticket 5 rules on the history already on `main`; this ticket rules only on
  where new log writes go. Keep them apart.
