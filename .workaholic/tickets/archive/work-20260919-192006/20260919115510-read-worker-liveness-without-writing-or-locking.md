---
created_at: 2026-09-19T11:55:10+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-the-codex-clock-dying-silently-and-writing-the-locks-it-reads
merge_policy:
verification_handoff: 
---

# Read worker liveness without writing or locking

## Overview

`--status` is documented four times over as a surface that "starts nothing, writes nothing, takes
no lock and needs no `codex` CLI". It does all three. `role_state()` opens each role lock with
`exec 8>"$_lock"`, which truncates the file and moves its mtime, then holds `flock -n 8` for the
life of the subshell; `supervisor_lock_state()` does the same to `.supervisor.lock` under a
comment that says in capitals that it must never write.

Two consequences the contract says cannot happen. A read-only status call can lose
`dispatch_claim_role()` its lock and answer a real dispatch `already_running`. And it destroys the
forensics the surface exists to provide: the reporter found this because three `worker-*.lock`
files read one minute old — written by their own earlier `--status` call — in a repository whose
supervisor had been dead for twelve days.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a reading that changes what it reads is not an observation

## Key Files

- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — `role_state()` (the `exec 8>` probe),
  `supervisor_lock_state()` (the `exec 7>` probe), their `--status` callers `show_workers` and
  `show_status_json`, and `dispatch_claim_role()`, which is the legitimate writer and must keep
  its exclusive claim unchanged.
- `plugins/workaholic/skills/work/reference/other-agents.md` — states the contract twice.
- `plugins/workaholic/commands/work.md` — states it a third time.
- `scripts/e2e/drills/verify-codex-clock.sh` — the drill that must carry the proof.

## Implementation Steps

1. Reproduce and localize before changing anything. Stamp a fixture state directory's
   `.supervisor.lock` and three `worker-*.lock` files to a fixed past mtime, run
   `codex-loop.sh --status --json --log <fixture>`, and compare. Measured on 2026-09-19 against
   this tree: all four mtimes moved, from a single read.
2. Establish which probe each site needs. `role_state` answers *is this role's lock held*;
   `supervisor_lock_state` answers *is something turning here*. Neither needs to create, truncate
   or keep a lock.
3. Replace the probes with a reading that does not write. Verified on this machine:
   `( exec 7<"$_lock"; flock -n 7 )` on a read-only descriptor correctly reports a held exclusive
   lock as held and a free one as free, and leaves the mtime byte-identical. Both sites already
   guard on `[ -e ]`, so an absent lock keeps answering before any probe and *absent means never
   started* stays true. `fuser` is the alternative the reporter named; prefer the descriptor form,
   which needs no extra binary on the PATH.
4. Leave `dispatch_claim_role()` and the `--worker` claim untouched: they must truncate and hold,
   and the whole point is that the reader stops competing with them.
5. Keep the `has_flock` fallback path as it is — it reads a pid file and never wrote.
6. Extend `verify-codex-clock.sh` with a row that hashes the state directory's lock mtimes around
   a `--status --json` call and fails when they move, with a breaker that restores the writing
   probe and requires the drill to notice.
7. Re-read the three prose statements and confirm they are now true rather than editing them. If
   any wording is still wider than the code, narrow the wording in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One `--status` and one `--status --json` call leave every file in the state directory
  byte-identical, mtimes included, including `.supervisor.lock`.
- `--status` run concurrently with `--dispatch <role>` never makes the dispatch answer
  `already_running`.
- A role whose worker genuinely holds the lock is still reported `running`, and a free one `idle`.

**Verification method** — the commands/tests/probes that prove them:

- The fixture probe in step 1, run before and after, with the mtime hash compared.
- `sh scripts/e2e/loop-drill.sh verify-codex-clock`, including the new row and its breaker.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- The drill's new row passes and its breaker fails the drill when the writing probe is restored.

## Considerations

- The `supervisor_lock_state()` site is not in the reporter's measurement; it was found here and
  its own comment documents the intent it breaks, which makes it the clearer half of the defect.
- Do not swap the lock for a timestamp file or any other second liveness authority. The lock stays
  the authority; only the way it is read changes.
