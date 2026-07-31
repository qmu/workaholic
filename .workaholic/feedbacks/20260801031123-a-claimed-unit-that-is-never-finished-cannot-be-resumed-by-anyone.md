---
type: Feedback
title: A claimed unit that is never finished cannot be resumed by anyone
kind: insight
source: discussion
created_at: 2026-08-01T03:11:23+09:00
author: a@qmu.jp
supersedes: 
---

# A claimed unit that is never finished cannot be resumed by anyone

The design record says in-flight state lives on the claim branch and that "the next tick re-claims and resumes from what is pushed" (`docs/loop-engineering-workflow.md` I5, echoed in `mission/SKILL.md` and `CLAUDE.md`). The implementation does the opposite, measured 2026-08-01: `plan-units.sh` drops every claimed unit as `excluded: claimed`, and `claim.sh` refuses `already_claimed`, so no survey ever offers it again — not the same runner on its next tick, not another runner, not a developer typing `/drive` locally. Past `WORKAHOLIC_CLAIM_STALE_HOURS` the claim is only *reported* `stale: true`; nothing acts on it, by design. The gap is survivable for a local runner whose `.worktrees/<unit>` is still on disk, and not survivable for a cloud one: there the worktree lives only inside the sandbox, so when the session ends the pushed branch is the sole surviving copy and nothing routes a person to it. `release-claim.sh` is not the recovery — it deletes the remote branch.
