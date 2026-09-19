---
created_at: 2026-09-20T01:04:51+09:00
status: done
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy: auto
verification_handoff:
feedback:
claim: work-20260920-010451
---

# Supply the runner-advance drill the claim oracle its reader now reads

## Overview

`scripts/e2e/loop-drill.sh verify-runner-advance` is red on the base at `7a6db3d7b`, and
`loop-drills.yml` runs the hermetic drill set on every push, so the whole loop is building on a
red base. Measured:

```
$ sh scripts/e2e/loop-drill.sh verify-runner-advance
{"ok": false, "verdict": "fail", "load_bearing": {"passed": 5, "failed": 4}, "breakers": 1}
```

The four failing rows are `runner_advance_reads_the_worktree`,
`runner_advance_names_a_frozen_runner`, `runner_advance_refuses_the_binding` and
`runner_advance_frees_the_slot`. Every unit comes back
`verdict: unreadable, reason: claim_unresolved`, every name
`unreadable, reason: claim_evidence_incomplete`, with `frozen_count: 0` and
`residue_worktrees: 0`.

**The reader is not the defect.** Ticket `20260919230800` (PR #1250) bounded
`loops/scripts/read-runner-advance.sh` to worktrees a claim can stand behind — a worktree is
weighed only when its branch exists under `refs/remotes/origin/`, the claim oracle's own test —
and that repair is correct and load-bearing. It removed a measured harm: four worktrees idle
15.2–16.7 days made `no_claim_evidence` unreachable and read two working runners
`not_advancing`.

**The drill's fixture is the defect.** It is built by `mkdir -p` and `touch -d`, so each fixture
root is a bare directory tree and not a git repository at all. Both of the reader's new git
reads fail there — `git worktree list --porcelain` and
`git for-each-ref refs/remotes/origin/**` — so `claim_standing` answers `unresolved` for every
unit and the reader, correctly refusing rather than guessing, answers nothing about anybody.
The fixture stopped supplying a premise the reader now requires and the real loop always has.

Until `20260919230800` the newest mtime under `.worktrees/<unit>/` was the reader's only
premise, and a directory tree with chosen mtimes supplied all of it. The reader gained a second,
git-native premise; the fixture did not.

## Approach

**The repair is the fixture's, not the reader's** — a decision, not the cheaper road, and it is
recorded in the drill beside the fixture so it is not re-argued.

The reader's answer for a root with no claim oracle is `unreadable`, which frees nothing. That
is the direction this repository requires of it everywhere else (*an absence of a reading is
never a proof*). Teaching it that "no origin remote" means "weigh every worktree as before"
would add a code path whose only caller is a fixture, and would hand back the
pre-`20260919230800` reading in exactly the repository where nothing could contradict it. So
`read-runner-advance.sh` stays **byte-identical** and the fixture supplies the premise instead.

Each fixture root becomes a throwaway git repository with real claim worktrees: `git init` under
the drill's own temp directory, one empty commit, `git worktree add -b work-YYYYMMDD-HHMMSS`
per unit, and `git update-ref refs/remotes/origin/<branch>` by hand for a **live** claim. It
stays hermetic — no remote, no fetch, no network, nothing written outside the temp tree.

Two details the shape forces:

* **The worktree's own `.git` file is aged with the rest of the fixture.** `git worktree add`
  writes it at creation and nothing rewrites it, so in the real loop it carries the claim's
  birth and ages with the claim; in a fixture built this second it is the newest file under the
  worktree and would read every claim `advancing`.
* **The `no_files` case is reached by making a live worktree unreadable** (mode 000), not by
  leaving it empty: `git worktree add` always writes a `.git` file, so an empty registered
  worktree does not exist. The mode is restored before cleanup.

## Implementation Steps

1. Replace the drill's `_mkwt` with `_repo` + `_mkwt <fixture> <unit> <branch> <age> <live|residue>`,
   building real repositories and real worktrees.
2. Age the whole worktree subtree, `.git` file included.
3. Reach `no_files` by `chmod 000` on a live worktree; restore it before `rm -rf`.
4. Add the coverage `20260919230800` shipped without: a `residue` fixture (one live claim beside
   one worktree whose branch stands on no origin ref) and an `abandoned` fixture (residue only).
5. Add a second breaker, written against the behaviour: force `standing=live` and assert the
   abandoned fixture then frees both slots on claims nobody holds — the 2026-09-19 defect itself.

## Key Files

- `scripts/e2e/drills/verify-runner-advance.sh` — the fixture and the new rows
- `plugins/workaholic/skills/loops/scripts/read-runner-advance.sh` — read, **not modified**

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — the change is POSIX `sh` in the drill harness
- `workaholic:development` / `policies/qa-ownership.md` — a drill whose fixture no longer supplies its reader's premise is a test defect, and the repair belongs to the test

## Quality Gate

- `sh scripts/e2e/loop-drill.sh verify-runner-advance` reports `verdict: pass` with zero
  load-bearing failures and both breakers breaking.
- `plugins/workaholic/skills/loops/scripts/read-runner-advance.sh` is byte-identical to the base.
- The drill leaves the checkout byte-identical and removes its own temp tree.
- `node --test scripts/tests/agentic-loop/*.test.mjs` passes.

## Considerations

The new fixture costs one `git init`, one commit and two `git worktree add` calls per fixture —
five repositories, offline, under the drill's own temp directory. `reap-worktrees.sh`'s
`reclaimable` predicate, `branch-checks.sh` and `merge-gate-policy.sh` are untouched.
