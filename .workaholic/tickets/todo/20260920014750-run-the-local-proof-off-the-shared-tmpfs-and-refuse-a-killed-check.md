---
created_at: 2026-09-20T01:47:50+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: [https://github.com/qmu/workaholic/issues/1248]
claim: work-20260920-020459
---

# Run the local proof off the shared tmpfs and refuse a killed check

## Overview

A check in the local proof set a `main`-bound merge stands on can be **killed part-way and reported as `ok: true`**. That is the defect, and it is reproduced exactly. The machine's shared, RAM-backed `/tmp` is the measured condition that produces it, and — this is the part the originating report did not establish — **moving `TMPDIR` off that filesystem does not prevent it.**

**The report, and what reproducing it showed.** The report behind this ticket is that a runner's `node scripts/test-workflow-scripts.mjs` exited part-way, three times, at three different points, with **zero failing assertions**, and completed only once `TMPDIR` pointed at local disk. Run here, 2026-09-20, **with `TMPDIR` already on local disk** (`/home/ec2-user/.cache/…`, `/dev/nvme0n1p1`, 40 G free), the suite ended after **5,225 passing assertions, 0 failing**, with **no `N passed, N failed` summary line** — that line is the last statement in the file, so it was never reached — and the wrapping shell produced **no output at all**, not even the `echo` that followed the command. A process group that is killed behaves exactly like that. So the remedy in the report was **not sufficient on this machine**, and the honest reading is that the temp directory is one contributing pressure rather than the cause.

**Why, measured in the same minutes.** `/tmp` is **tmpfs**, so its blocks are RAM, and this machine has no swap:

- `free -m` → total **7,767**, used 4,593, **shared 2,146**, **available 825**, **swap 0**. The 2.1 G sitting in `/tmp` is 2.1 G of the machine's 7.7 G of memory, permanently, for every process on it.
- `df -h /tmp` → `tmpfs 3.8G 2.1G 1.7G 56%`; `df -i /tmp` → `1.0M inodes, 415K used, 41%` — two bounds, and a suite that creates hundreds of small git repositories pushes on both.
- `ls /tmp | wc -l` → **89,959** top-level entries, of which `/tmp/claude-1000` alone holds 970 MB.
- `pgrep -cf test-workflow-scripts.mjs` → **5**, then **7**, concurrent runs of the same multi-minute suite, on one machine, at one moment.

So the pressure is memory, and a large part of the memory is the temp filesystem. Pointing `TMPDIR` elsewhere stops a run *adding* to it; it does nothing about the 2.1 G already held, and nothing about the concurrency.

**Nothing declares `TMPDIR`, and that is still worth repairing.** `scripts/test-workflow-scripts.mjs` (line 19, `import { tmpdir } from "node:os"`), every file under `scripts/tests/agentic-loop/`, and `scripts/e2e/loop-drill.sh` (`mktemp -d`, `"${TMPDIR:-/tmp}"`) all create throwaway repositories under the OS temp directory, and a tree walk found no declaration anywhere — not in `.claude/settings.json`, not in `branching/scripts/local-proof.sh`, not in any `.github/workflows/` file. `local-proof.sh` already carries a clean-environment ruling (it unsets `WORKAHOLIC_CLAIM_STALE_HOURS`, `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES` and `WORKAHOLIC_CLAIM_MERGED_LOOKUP` before each check, because a caller's environment had turned 16 claim-protocol assertions red). The temp directory is the same class of fact: the set runs in a clean *variable* environment on a filesystem it does not choose, and it costs the machine RAM to do so.

**And here is the part that makes a killed check invisible.** `local-proof.sh` classifies a check's exit status:

```
0)        ran=true; ok=true
124|137)  reason="timeout:${timeout_s}s"      # ran stays FALSE
*)        ran=true; reason="exit:${status}"
```

`137` is `128 + SIGKILL` — the status a check killed by the kernel under memory pressure produces, and the status the abort above is consistent with. It is mapped to `timeout`, recorded `ran: false`, landed in `not_run` rather than `failed`, and `SET_OK` never goes false.

**Reproduced here, 2026-09-20** — a throwaway repository whose `scripts/build-plugins/verify.mjs` is `process.kill(process.pid, "SIGKILL")`, run as `local-proof.sh --repo <that> --only verify.mjs`:

```json
{"ok": true, "complete": false,
 "not_run": ["verify.mjs: timeout:0s", ...], "failed": [],
 "row": {"name":"verify.mjs","required":true,"ran":false,"ok":false,
         "seconds":0,"reason":"timeout:0s"}}
```

`verify.mjs` declares `timeout 0` — **no timeout at all** — and its reason reads `timeout:0s`. And `drive/scripts/catch-up-claim.sh:397-409` refuses only on `ok: false`; its own header states the split in as many words: *`ok: false` is what refuses; `complete: false` is REPORTED and never refuses*. A required check that the kernel killed therefore leaves the run reporting a pass and pushing.

That is the same failure that turned `main` red seven consecutive times on 2026-09-19 (ticket `20260919230700`, this issue's sibling), arriving by a different road: not *a check nobody declared*, but *a declared check nobody noticed did not run*.

**The direction of the repair, in priority order.** Both changes are inside `local-proof.sh`, which PR #1251 established as the one declaration and the one runner:

1. **Tell a kill from a timeout, and make a killed required check refuse.** This is the repair; the rest is mitigation. `124` is `timeout`'s own exit status and keeps that reading. `137` is a signal and must not be folded into it — a check that declares no timeout cannot have timed out, and the `timeout:0s` string above is that contradiction printed. A killed required check is a **failure** (`ok: false`, a refusal) or a `not_run` state of its own that a consumer must read — see `## Open Decisions`. Under this machine's real conditions a run can be killed however clean its temp directory is, so this is what stands between a killed check and a push that claims it passed.
2. **Run the set somewhere it owns.** `LOG_DIR` already resolves to `$(git rev-parse --absolute-git-dir)/workaholic` — inside the git directory, never committed, present for a worktree and a main checkout alike. Export `TMPDIR` pointing at a per-run directory beneath it for the duration of each check, and remove it afterwards. Stated honestly: this **reduces pressure rather than removing it** — the reproduction above ran with `TMPDIR` already on local disk and was still killed. What it buys is that the proof set stops adding to a RAM-backed filesystem that every process on the machine pays for, and that a check which leaks its fixtures leaks them somewhere a reader can find.

**Not in scope.** Raising a check's declared timeout (the sibling ticket's ruling — *the bound is NOT raised past CI's own* — stands unchanged). Changing what is in the proof set. Cleaning `/tmp`, which holds other agents' live state and is not this repository's to delete. CI is unaffected: a GitHub Actions runner's `/tmp` is local disk, not a shared tmpfs, so the `Validate Plugins` job's behaviour must be byte-identical after this change.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — the change is entirely inside a POSIX `sh` script
- `workaholic:implementation` / `policies/test.md` — what a local proof is, and why a check that was killed has proved nothing
- `workaholic:implementation` / `policies/observability.md` — `not_run` is a reported state with its own reason, and a reason that contradicts the declaration (`timeout:0s` on a check with no timeout) is a defect in the report
- `workaholic:operation` / `policies/ci-cd.md` — the relationship between the local proof and the CI job it substitutes for
- `workaholic:development` / `policies/parallel-long-running-agents.md` — the measured condition is many concurrent agents sharing one machine's resources

## Key Files

- `plugins/workaholic/skills/branching/scripts/local-proof.sh` - the one declaration and the one runner; both halves of the repair land here (the clean-environment `unset` block at lines ~236-246, the exit-status `case` at lines ~249-253, `LOG_DIR` resolution at lines ~196-208)
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` - lines 397-409: the consumer that refuses on `ok: false` and reports `complete: false`; the `validation_failed:<check>` spelling must not move
- `plugins/workaholic/skills/branching/scripts/prepare-publication.sh` - line 237: the second consumer, same contract
- `scripts/test-workflow-scripts.mjs` - line 19 `tmpdir()`, and the `local-proof.sh` assertion block at lines ~43700-43733 where the new behaviour is pinned
- `scripts/tests/agentic-loop/*.test.mjs` - `mkdtemp(tmpdir(), …)` in every file; the 300s-bounded check most exposed to load
- `scripts/e2e/loop-drill.sh` - `mktemp -d` and `"${TMPDIR:-/tmp}"` at lines 911, 1157, 1313, 1432, 1463, 1483, 1515, 1587, 1693, 1822
- `CLAUDE.md` - *Local Verification*, which states that the hermetic tests create throwaway repositories under the OS temp dir; update it in the same change

## Related History

The sibling ticket in this issue's first batch established the proof set itself and its three-field contract; this one is about the ground that set runs on and the one exit status that escapes its refusal.

- [20260919230700-declare-the-local-proof-set-a-main-bound-merge-stands-on.md](.workaholic/tickets/archive/work-20260919-231306/20260919230700-declare-the-local-proof-set-a-main-bound-merge-stands-on.md) - created `local-proof.sh`, `ok` / `complete` / `not_run`, and the rule that a check which did not run is never a soft pass (direct predecessor; merged as PR #1251)

## Implementation Steps

1. **Reproduce and localize before changing anything.** Re-run the `--only` probe in this ticket's Overview against a throwaway repository (one-line `verify.mjs` that SIGKILLs itself) and confirm `ok: true`, `complete: false`, `reason: timeout:0s`, `failed: []`. Then confirm the consumer side: read `catch-up-claim.sh:397-409` and establish that nothing on that path refuses on `complete`. Re-read `free -m` and `pgrep -cf test-workflow-scripts.mjs` at the same time, since both readings move with the machine's load and this ticket's numbers are one moment's.
2. Split `137` out of the `124` arm — the repair. `124` keeps `timeout:<n>s`. Implement the `137` reading chosen in `## Open Decisions`, and make the reason carry the signal (`killed:SIGKILL`, or `exit:137`) rather than a timeout the check never declared. Do this before the `TMPDIR` work, so that if the second half is descoped the run still refuses rather than claiming a pass.
3. Keep the log. The kept-output ruling is the whole reason a resource failure is diagnosable at all; a killed check's log must survive exactly as a failed check's does.
4. Confirm by reading — not by assumption — which checks honour `TMPDIR`: `os.tmpdir()` reads `TMPDIR` on POSIX, and `mktemp -d` reads it too. Name in the change any check that would *not* pick up an exported `TMPDIR`.
5. In `local-proof.sh`, create a per-run scratch directory beneath the already-resolved `LOG_DIR` (e.g. `${LOG_DIR}/tmp.$$`), export `TMPDIR` to it around each check's subshell beside the existing `unset` block, and remove it when the run ends — including on the `unreadable` early-exit paths, which must stay byte-identical in their output. If the directory cannot be created, that is its own named `unreadable` reason; it is never a silent fall-back to `/tmp`.
6. Add assertions to `scripts/test-workflow-scripts.mjs`'s `local-proof.sh` block: (a) a check that SIGKILLs itself does not answer `ok: true`; (b) its reason does not contain the string `timeout` when the check declares `timeout 0`; (c) the runner exports `TMPDIR` beside the clean-environment `unset`; (d) the existing three — `ok`/`complete` separated, `checks: null` on unreadable, the `unset` line — still hold.
7. Update `CLAUDE.md`'s *Local Verification* section and `local-proof.sh`'s own header in the same change, stating the memory measurement, the `TMPDIR` behaviour and the `137` reading. State in the header that the `TMPDIR` change reduces pressure and does not remove it, so a later reader does not take it for a fix.

## Quality Gate

**Acceptance criteria**

- A required check killed with SIGKILL does not produce `"ok": true`. Proved by the `--only` probe in Step 1 re-run after the change.
- No check whose declaration is `timeout 0` ever reports a reason containing `timeout`.
- `local-proof.sh` run from the main checkout with `TMPDIR` unset creates no `workaholic-*` / `wh-*` fixture directory directly under `/tmp`. A bare `ls /tmp | wc -l` comparison is **not** the test — the count moves for other agents' reasons — so the criterion is the absence of those prefixes, listed before and after.
- `catch-up-claim.sh` and `prepare-publication.sh` keep the `validation_failed:<check>` refusal spelling byte-identical; no caller's `case` arm moves.
- The `unreadable` early-exit output shapes are byte-identical (`{"readable": false, …, "checks": null, …}`).

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with the four new assertions of Step 6 present and covering the criteria above. **Run it with `TMPDIR` pointed at local disk** — see Considerations.
- `sh plugins/workaholic/skills/branching/scripts/local-proof.sh --list` still renders the six declared rows unchanged.
- `sh plugins/workaholic/skills/branching/scripts/local-proof.sh` on this repository answers `ok: true, complete: true` with an empty `not_run`, proving the change did not break the ordinary path.
- The SIGKILL probe of Step 1, re-run, as the direct before/after evidence.
- `bash plugins/workaholic/hooks/posix-lint.sh` conforming for the edited script.

**Gate**

- The suite green, posix-lint conforming, and the before/after probe output quoted in the branch story.
- The change is confined to `local-proof.sh`, its tests, and the documentation that states its contract. No consumer's refusal vocabulary changes.

## Open Decisions

- **Is a SIGKILLed required check a failure (`ok: false`, which refuses the push) or a `not_run` state that refuses on its own term?** — consulted: `plugins/workaholic/skills/branching/scripts/local-proof.sh`'s own header says *`complete` — every REQUIRED check ran. An incomplete set is REPORTED, never a refusal*, and gives the reason: the two retired lists skipped an absent check silently, and *a consuming repository that carries none of these files must keep pushing exactly as it did*. `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh:393` states the same split from the consumer side. Both were written for `check_absent` and `interpreter_unavailable` — reasons that mean *this repository does not have this check* — and a kill is not that: the check is present, it started, and something ended it. Options: **(A)** treat `137` as `ran: true, ok: false`, so it joins `failed` and refuses through the existing `validation_failed:<check>` word with no new vocabulary and no consumer change — at the cost that `ran: true` for a process that produced no verdict is a small lie, and that a consuming repository on a constrained machine now gets refusals it did not get before. **(B)** keep it `ran: false` with a reason of its own and add a third refusing term (`killed`) that consumers must read — honest about what happened, at the cost of a new field or a new consumer contract in two scripts and the risk that a consumer forgets to read it, which is the failure mode this whole ticket is about. Neither is clearly recommendable: (A) trades accuracy of the record for a refusal that cannot be forgotten; (B) trades a refusal that cannot be forgotten for accuracy of the record. The operator's ruling would settle it; absent one, the driving session decides and records which and why in the branch story.

## Considerations

- **The implementing session should point `TMPDIR` at local disk for its own runs**, and should not expect that to be enough: measured here, a run with `TMPDIR` on local disk was still killed part-way under seven concurrent copies of the same suite. Budget for the suite needing more than one attempt, and read `free -m` and the concurrent-run count beside any run that ends without its summary line (`scripts/test-workflow-scripts.mjs`, line 19 and the runner loop at ~43735).
- **What was and was not established.** Reproduced: the abort itself (5,225 passing assertions, 0 failing, no summary line, the wrapping shell silent) **with `TMPDIR` already on local disk**; the memory and filesystem readings; and the classification defect, exactly, by the `--only` SIGKILL probe. **Not** established: that the abort was an OOM kill specifically — `dmesg` and the kernel journal are not readable without root on this machine, so no kill record was read, and the reading rests on the shape of the failure plus `free -m` (available 825 MB, swap 0, 2.1 G of RAM held by `/tmp`). **Not** established either: that `137` is the status such an abort delivers to `local-proof.sh` — the suite was run directly, not through the runner. Step 1 should treat both as open, and if the implementing session can read a kill record it should quote it. **Not attempted, deliberately**: filling the tmpfs to force the condition, which would damage other agents' live state on this machine.
- One thing the report *does* rule out: `scripts/test-workflow-scripts.mjs`'s runner loop wraps every row in `try { await fn(); } catch (e) { fail(label, …) }` (lines ~43735-43739), so an `ENOSPC` raised inside a test row becomes a **counted failure**, not an abort. An abort with zero failures therefore means the process itself was ended from outside, which is what makes the signal reading the load-bearing part of this ticket.
- `scripts/tests/agentic-loop/*.test.mjs` is the check most exposed here: it is the only row carrying a timeout (300s, CI's own bound), and `local-proof.sh`'s header already records it being killed at that bound under ~20 concurrent runners while the same suite alone took 115s. With `124` and `137` separated, that row's reports become legible for the first time (`plugins/workaholic/skills/branching/scripts/local-proof.sh`, the declaration comment).
- `.git/workaholic/` is inside the git directory and is never committed, so a scratch directory there needs no `.gitignore` entry — but it does need removing, or a long-lived checkout accumulates one fixture tree per proof run on local disk (`plugins/workaholic/skills/branching/scripts/local-proof.sh` lines ~196-208).
