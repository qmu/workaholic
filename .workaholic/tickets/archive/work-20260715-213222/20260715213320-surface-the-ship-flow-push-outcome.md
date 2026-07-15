---
created_at: 2026-07-15T21:33:20+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# The ship flow's push can fail silently and still report success

## Motivation

`extract-deferred-concerns.sh` ends the ship flow with:

```sh
git push >/dev/null 2>&1 || true
```

It then prints `{"status":"ok", ...}` whether or not that push happened. Observed on the ship of PR #86 (2026-07-15): the push did **not** run — local `main` had no upstream configured — and the script reported `status:ok, created:11, updated:10` regardless, leaving local `main` two commits ahead of `origin/main`. That is precisely the divergence the script's own header says it exists to prevent:

> Commits the new files **and pushes**, so you end on `main` level with `origin/main` (the commit lands on local `main` post-merge; the push prevents a one-commit-ahead divergence).

**`|| true` is not the defect, and must not be removed.** It was specified deliberately: the archived ticket that added this line (`.workaholic/tickets/archive/work-20260706-182705/20260706182653-push-deferred-concerns-in-ship.md`) records under Considerations that a push failure "must not fail the ship", and `scripts/test-workflow-scripts.mjs:2404` asserts the same in prose: *"A push failure must never fail the post-merge ship."* That reasoning still holds — the merge has already landed; a failed push is not worth aborting on.

The defect is the **`2>&1`**, which throws the diagnosis away, and the **JSON**, which claims success without evidence. The script knows whether it pushed; it just refuses to say. A non-fatal failure that reports nothing is indistinguishable from a success, so nothing downstream — not `/ship`'s step-9 summary, not the developer — can tell.

**The general victim is not a missing upstream.** `git clone` writes `branch.main.remote=origin`, so a fresh clone pushes fine; this repository's upstream-less `main` is an anomaly. The failure this swallow hides in normal use is a **rejected** push — a non-fast-forward when `origin/main` moved during the ship, a protected branch, or no network. Those are exactly the cases where a silent divergence matters most, because someone else's commit is involved.

`commit-release-note.sh:33` carries the byte-identical swallow and has **no push test at all**. It is the same defect in the same skill and is in scope.

## Policies

- `implementation/directory-structure` — the script stays in its role-named `scripts/` slot; placement is readable from structure.
- `implementation/coding-standards` — `|| true` is the shell analogue of `@ts-ignore`: the failure guarantee silently falls away and the caller cannot detect it.
- `implementation/observability` — a step that fails without emitting anything is the state this policy forbids; the failure must be surfaced, not discarded.
- `operation/ci-cd` — a green result absent evidence of what was verified is not proof of a successful push.
- `implementation/objective-documentation` — the header must describe actual behavior, not the divergence prevention it does not deliver.
- `implementation/test` — a regression test asserting the push failure surfaces instead of passing green.

## Implementation Steps

1. In `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh`, keep the non-fatal exit but capture the outcome: run the push, record success/failure, and stop discarding stderr into the void. Emit a **`pushed`** field in the JSON (`true`/`false`), plus a short non-secret `push_error` (or equivalent) naming the cause when it fails. Adding a field is the idiomatic way this codebase surfaces a soft failure — every script emits one JSON line and the caller parses it.
2. Apply the same treatment to `plugins/workaholic/skills/ship/scripts/commit-release-note.sh:33`, which has the identical swallow. Its JSON already returns `{"committed": true, ...}`; add the push outcome alongside.
3. Correct both script headers so they describe what the code does — a best-effort push whose outcome is reported — rather than promising a divergence that is prevented.
4. Update `plugins/workaholic/skills/ship/SKILL.md` so the Ship Flow's step 8 (and step 5 for the release note) tells the caller to read the new field and surface it in the step-9 summary. A field nothing reads is not observability.
5. `node scripts/build-plugins/build.mjs` — both scripts are bundled into `outputs/workflows/skills/ship/ship/scripts/`. Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria** (each is an assertion in `scripts/test-workflow-scripts.mjs`, driven against the real scripts in a temp repo):

| case | must hold |
| --- | --- |
| Push succeeds (bare origin, upstream set) | JSON reports `pushed: true`; `origin/main == main`. The existing `testExtractDeferredConcernsPush` assertion stays green. |
| **Push is REJECTED by a reachable remote** (non-fast-forward: advance the bare origin behind the script's back) | exit **0**, `status: ok`, extraction still succeeded, **`pushed: false`** with a cause named. This is the case nothing covers today and the one that matters. |
| No remote at all | exit 0, `pushed: false`, local commit still made. The existing no-remote assertion keeps passing, now also asserting the field. |
| No upstream configured on `main` (today's observed case) | exit 0, `pushed: false` — not silently `true`. |
| `commit-release-note.sh` push rejected | same shape; this script has **no** push test today, so this is net-new coverage. |

**Verification method:** hermetic temp repos with a real bare `origin`, as the existing push test already does — no network, no `gh`. Reject a push by committing to the bare origin's ref (or by pushing from a second clone) so the remote genuinely refuses.

**The gate:**

1. **Watch each new assertion fail first.** Revert the single script with `git checkout HEAD -- <path>` (never `git stash`, which takes the tests away with the fix and passes vacuously), confirm the new cases go RED, restore.
2. Full suite green (648+ passing, 0 failed); `posix-lint.sh` conforming; `verify.mjs` and `validate-metadata.mjs` pass.
3. `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/` is **empty** — both scripts are bundled and the Outputs Freshness CI gate fails on any diff.

**Do not make the push fatal to satisfy a test.** If an assertion pushes you toward `exit 1` on push failure, the assertion is wrong: the post-merge ship must not abort. The bar is *reported*, not *enforced*.

## Findings

- The prior ticket `20260706182653-push-deferred-concerns-in-ship.md` had an acceptance criterion of "`origin/main == main` after extraction" — and it passes, because the test provisions a bare origin **with an upstream configured**. The provisioning is what hid the defect: the idealised repo never exercises the failure path. This is a concrete instance of the active concern `hermetic-tests-prove-migration-not-local`.
- That same ticket's Discovered Insight reads: *"the missing regression test is what let a commit-without-push ship silently."* It now reads as the mechanism that let a push-that-never-runs ship silently — the same gap, one level up.
- Only two scripts in the repo push (`extract-deferred-concerns.sh`, `commit-release-note.sh`) and both carry this swallow. The only `push -u` is prose in `report/SKILL.md:193`, executed by the model rather than a script.

## Considerations

- Keep the JSON single-line and non-secret: `push_error` must carry a cause (`non-fast-forward`, `no upstream`, `network`), never a remote URL with credentials. `record-evidence.sh`'s secret guard is a reminder of the standard, not a substitute for judgement.

## Final Report

Development completed as planned. Both pushing scripts now report their outcome (`pushed` plus a classified `push_error`) while staying non-fatal, and the shared logic lives in one new same-skill helper, `ship/scripts/lib/push-outcome.sh`, rather than being written twice. All five gate rows are covered by measured assertions; the suite went 648 → 667 passing, 0 failed.

### Discovered Insights

- **Insight**: The old script already behaved correctly — it exited 0 on a rejected push — and the fail-first run proved it: of the 11 new assertions that went red, *none* were about exit status or extraction. Only the reporting assertions failed.
  **Context**: This is the cleanest possible evidence that the change is observability and not a behavior change, and it is exactly what the ticket demanded ("the bar is *reported*, not *enforced*"). It also means the prior ticket's `|| true` reasoning was right all along and survives untouched; the defect was never the non-fatality, only the silence. A fail-first run is not just proof the test works — the *shape* of what fails tells you whether you changed what you meant to.

- **Insight**: `push_error` is a classified token, never git's stderr. A remote URL can embed a credential, and this value is printed to stdout and read by `/ship`, so echoing raw stderr would have piped a possible secret into a field the release path reads.
  **Context**: The natural implementation — `push_error=$(git push 2>&1)` — is the one that leaks. The classification `case` is not defensive styling; it is the boundary. Worth preserving if anyone later wants "more detail" in the error.

- **Insight**: The shared helper cost the bundle nothing, and the prioritizer caught that my own ticket said otherwise. This ticket's Considerations warned "the fix must not widen the bundled closure", implying a same-skill helper might. It cannot: `lib/` sits inside `ship/scripts/`, and `build.mjs`'s `computeClosure()` only follows cross-skill `${SCRIPT_DIR}/../../<skill>/` references. Confirmed by rebuilding — the ship closure is unchanged at `[branching, gather, mission, okf, release-scan, report, ship]`.
  **Context**: The same correction applies to the next ticket, which carries a stronger version of the same warning: `extract-deferred-concerns.sh` *already* calls `../../report/scripts/migrate-concern-identity.sh`, so the ship→report edge exists today and a shared slugify under `report/scripts/` is free. Both warnings were written from caution rather than measurement.

- **Insight**: `commit-release-note.sh`'s push failing is worse than the concern push failing, and nothing said so. If the concern push fails, `main` is briefly ahead of `origin/main` — untidy, recoverable. If the release-note push fails, the note is committed locally but **is not on the branch the PR merges**, so the merge silently drops it and the release ships without its note.
  **Context**: It carried the identical swallow with zero push tests. The SKILL.md step-5 note now says to push before step 6 on `pushed: false`, because unlike step 8 this one is not merely untidy — it changes what reaches production.
- The fix must not widen the bundled closure: solve it inside the script rather than by calling another skill's script (`build.mjs`'s `computeClosure()` detects cross-skill `${SCRIPT_DIR}/../../<skill>/` references and would pull that skill in).
