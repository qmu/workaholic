---
created_at: 2026-09-19T23:08:00+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: [https://github.com/qmu/workaholic/issues/1248]
claim: work-20260919-231254
---

# Bound the runner-advance reading to live claim worktrees

## Overview

`loops/scripts/read-runner-advance.sh` decides whether a running loop subagent is still advancing from the newest mtime under **every** directory in `.worktrees/`, with no test that a live claim stands behind any of them. Abandoned worktrees are therefore read as flat runners, and because the reader's escape hatch is keyed on the *count* of worktrees rather than on their liveness, residue does not merely add noise — it **disables the escape hatch** and turns the answer deterministic in the wrong direction.

The arms are at lines 183-208. With at least one worktree on disk (`claim_count > 0`), `no_claim_evidence` is unreachable; if every worktree is flat and every one was readable (`advancing == 0 && unreadable_claims == 0`), every `implement` name is answered `not_advancing`.

**Measured live at `daff53802`, 2026-09-19:**

```
$ sh plugins/workaholic/skills/loops/scripts/read-runner-advance.sh --names implement-18,implement-19 .
{"stale_minutes":30,"running":2,"advancing":0,"frozen_count":2, … }
  announce-an-ask-that-landed-outside-a-unit-route-in-its-own-thread  not_advancing  idle 1430141s
  batch-20260903013910                                                not_advancing  idle 1442580s
  relay-codex-slack-through-the-owning-chat                           not_advancing  idle 1313829s
  stop-a-routine-tick-from-parking-on-a-permission-prompt             not_advancing  idle 1442456s
  implement-18  not_advancing    implement-19  not_advancing
```

Four worktrees, idle 15.2 to 16.7 days, and both running runners read frozen. That every one of the four is residue rather than a claim is provable **offline**: `git worktree list --porcelain` gives their branches as `refs/heads/work-20260903-054004`, `work-20260903-013925`, `work-20260904-143455` and `work-20260903-014343`, while `git for-each-ref refs/remotes/origin/work-*` holds exactly one ref, `origin/work-20260908-124122`, which matches none of them. The claim oracle reads unmerged **remote** branches (`drive/scripts/list-claims.sh`), so no claim row can stand behind any of the four, and the evidence the reader is weighing belongs to nobody.

**The harm is not hypothetical.** `commands/infinite-development.md:437` says a non-advancing runner may free a fanout slot **only** when this reader proves it. On 2026-09-19 the coordinator freed a slot on this reading and dispatched a second runner onto a ticket another runner was already driving.

**The aggravating factor, stated and deliberately not repaired here.** `branching/scripts/survey-worktrees.sh` computes `merged` as `ahead == 0` — ancestry — and every pull request this loop merges is squash-merged, so a landed branch is permanently `merged: false` and `reap-worktrees.sh --apply`'s `reclaimable` predicate can never free these four. That predicate is **deliberately not loosened** (`CLAUDE.md`, the operator's ruling), so this ticket does not touch it: the four worktrees stay on disk and remain the operator's to remove. What changes is that they stop corrupting a liveness reading they were never evidence for.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — the change is a POSIX `sh` reader's evidence set and its refusal words
- `workaholic:implementation` / `policies/observability.md` — an absence of a reading must answer `unreadable`, never a verdict
- `workaholic:implementation` / `policies/test.md` — the fixtures must cover residue, a live claim, and both together

## Key Files

- `plugins/workaholic/skills/loops/scripts/read-runner-advance.sh` lines 130-160 — the evidence walk over `.worktrees/*/`, which is where the filter belongs; lines 183-208 — the four arms whose two exact cases the residue defeats.
- `plugins/workaholic/commands/infinite-development.md` line 437 — the one consumer, and the rule that a slot is freed only on a proof.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the claim oracle's contract: an unmerged **remote** branch is the only claim oracle. Read its header; do **not** call it from here (it fetches, and this reader makes no network call).
- `plugins/workaholic/skills/branching/scripts/survey-worktrees.sh` — where `merged`/`reclaimable` live. Unchanged by this ticket.

## Related History

The reader was written 2026-09-06 (mission `see-a-frozen-runner-and-give-back-its-slot`) after a runner held a fan-out slot for 38m29s while `ListAgents` reported it `running`. Its own header records the localization that chose worktree mtime as the evidence and rejected the heartbeat, the tick log and the archived tickets — that choice is sound and is kept. What it never asked is **whose** worktree it is reading.

## Implementation Steps

1. Reproduce the reading above at the branch head, together with the `git worktree list --porcelain` and `git for-each-ref refs/remotes/origin/work-*` output that proves the four are residue, and record all three verbatim in the change (`workaholic:discover`, *Diagnosis-First Rule*).
2. Bound the evidence walk to worktrees a claim can stand behind, **offline**. For each `.worktrees/<unit>/`, resolve its branch from `git worktree list --porcelain` (one local call, already used by `survey-worktrees.sh`) and keep the row only when `refs/remotes/origin/<branch>` exists in the local ref store. No fetch, no `ls-remote`, no call into `list-claims.sh` — the reader's stated contract that it makes no network call does not move.
3. A worktree whose branch cannot be resolved, or whose ref store cannot be read, is `unreadable` with its own reason (`claim_unresolved`) and counts toward `unreadable_claims`. It is never flat: an absence of a reading is never a proof, and the direction of this reader's error is the dangerous one.
4. A worktree the filter excludes is **not** a claim row at all — it must not appear in `claims[]` as flat, or the same arithmetic returns under a new name. Report the count of excluded directories beside the rows (`residue_worktrees`) so an operator can see the disk is holding them without the reading spending them.
5. Confirm the arms then behave: with four residue worktrees and no live claim, `claim_count == 0` and every name reads `unreadable: no_claim_evidence`; with one live claim beside the residue, only that claim's mtime decides.
6. Read `commands/infinite-development.md` §2's accounting with the bounded reader in hand and confirm the slot-freeing rule is sound against it. A duplicate dispatch keyed on this reading is the same defect's other half and is in scope for this unit; if the consumer frees a slot on anything weaker than a per-name `not_advancing`, fix it here rather than recording it for later.
7. Add fixtures: residue only; a live claim only; both together; an unresolvable branch; an unreadable ref store. Each asserts the verdict **and** the reason word.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Run in this repository as it stands (four residue worktrees, no live claim of this identity), `--names implement-18,implement-19` answers `advancing: 0`, `frozen_count: 0`, and both names `unreadable` with reason `no_claim_evidence`. `frozen_count` must be 0, not 2.
- In a fixture with one live claim worktree (a branch present under `refs/remotes/origin/`) whose newest file is fresh, plus arbitrary residue, one running `implement` name reads `advancing`.
- In the same fixture with that live worktree's newest file backdated past the window, the name reads `not_advancing` and `frozen_count` is 1 — the reader's original purpose is intact.
- A worktree whose branch cannot be resolved yields `unreadable` with reason `claim_unresolved`, counts toward `unreadable_claims`, and never yields `not_advancing` for any name.
- The reader makes no network call: proved by running it with `GIT_ALLOW_PROTOCOL=` set to an empty value and with no network route, and by the absence of `fetch` / `ls-remote` / `list-claims.sh` in its text.
- `survey-worktrees.sh` and `reap-worktrees.sh` are byte-identical; the `reclaimable` predicate is not loosened and no worktree is removed by this change.
- `readable` remains **absent** on a successful read (the repository's absent-means-completed convention); no consumer test may read `readable // true`.

**Verification method** — the commands/tests/probes that prove them:

- The live reading above, before and after, pasted into the change's `verify`.
- New fixtures in `scripts/test-workflow-scripts.mjs` covering the five cases in step 7, each asserting the reason word and not only the verdict.
- `node scripts/test-workflow-scripts.mjs`.
- `node --test scripts/tests/agentic-loop/*.test.mjs`.
- `sh scripts/e2e/loop-drill.sh verify-observation-during-work` — the drill that asserts on the recorded event sequence rather than on elapsed time.
- `git diff --stat` showing `survey-worktrees.sh` and `reap-worktrees.sh` untouched.

**Gate** — what must pass before approval:

- All of the above green, the before/after live readings in the pull-request body, and the body stating explicitly that the reaper's predicate was not loosened and that the four residue worktrees remain on disk.

## Considerations

- **A remaining limitation, stated rather than designed around.** A runner whose current work is a hermetic test suite writes only into the OS temp directory, so its claim worktree is genuinely flat while it is working. After this change such a runner still reads `not_advancing` once it passes the 30-minute window. The filter removes the residue-driven false positive; it does not make mtime a complete liveness signal, and the consumer must keep treating a single `not_advancing` as licence to free a slot and never as licence to stop an agent (`plugins/workaholic/commands/infinite-development.md` line 437).
- The filter must read the **local** ref store only. Calling `list-claims.sh` would fetch, which this reader may not do (its own header, lines 62-66), and would also make a liveness reading depend on a network round trip inside a tick.
- A claim pushed a moment ago but whose remote-tracking ref is not yet written excludes that worktree, so the tick reads `no_claim_evidence` — unreadable, which is the safe direction and matches what the reader already does for a runner still in its survey (`plugins/workaholic/skills/loops/scripts/read-runner-advance.sh` line 56).
- `WORKAHOLIC_RUNNER_ADVANCE_STALE_MINUTES` and every other tunable stay exactly as they are; this change moves which rows are weighed, never the window.
