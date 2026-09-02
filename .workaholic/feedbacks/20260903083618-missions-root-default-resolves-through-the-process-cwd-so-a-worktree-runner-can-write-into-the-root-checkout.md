---
type: Feedback
title: missions_root_default resolves through the process cwd, so a worktree runner can write into the root checkout
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-03T08:36:18+09:00
author: a@qmu.jp
supersedes: 
---

# missions_root_default resolves through the process cwd, so a worktree runner can write into the root checkout

Source: https://github.com/qmu/workaholic/issues/938

`missions_root_default` (`plugins/workaholic/skills/mission/scripts/lib/resolve.sh:46`) resolves
the missions root through `git rev-parse --show-toplevel`, which is evaluated against the
process cwd. The comment at `:42` asserts the opposite — that the derivation is cwd-independent
and a worktree therefore resolves to its own `.workaholic`.

With `CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR: "1"` returning cwd to the project root on every
Bash call, a runner inside a claim worktree that calls a mission writer with a bare slug or a
repository-relative path resolves to the ROOT checkout instead. `missions_root_for_arg` (`:82`)
carries the same exposure through its cwd-relative `[ -f "$1" ]`.

Observed during a three-way implement fan-out: a staged `M .workaholic/missions/active/<slug>/mission.md`
appeared in the caller root checkout while every runner was in its own worktree, and was gone by
the next read. The ask states its own limit — the call was not logged, so the path is identified
rather than proved.

Why it matters with fan-out: the root checkout is the tree every tick reads for `checkout_dirty`
and the tree `sync-main` refuses to run on, so a stray staged file left by one runner is a
`dirty_workspace` stop for another.

The ask names the repair it wants: `missions_root_default` stops depending on cwd — a caller
holding only a slug either receives the root explicitly or derives it from the artifact, which is
the fix `missions_migrate_layout` in the same file already applies to the writer — and the
comment at `:42` is corrected either way.

Judgement of this run: the ask is machine-authored (`subject: observer_ai:a@qmu.jp`,
`ask-origin.sh` -> `machine`) and its subject is the loop own apparatus, so it is recorded and
originates no mission (`self_authored`, `rules/workaholic.md`, What May Originate a Mission).
The finding stays open as knowledge for a human to act on.
