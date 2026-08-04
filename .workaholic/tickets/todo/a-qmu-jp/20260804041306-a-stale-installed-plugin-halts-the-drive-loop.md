---
created_at: 2026-08-04T04:13:06+00:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-085951
---

# A session that outlives a plugin version bump runs stale always-on hooks, dirties the workspace, and halts `/drive` before it can survey

## Overview

Observed live in the hourly cloud runner on 2026-08-04. The container was provisioned when `main` carried plugin **v1.0.112** and has outlived thirteen releases:

```
$ node -e "console.log(require('.claude-plugin/marketplace.json').version)"
1.0.125
$ ls /root/.claude/plugins/cache/workaholic/workaholic/
1.0.112
```

`hooks/mission-lens.sh` is registered on `UserPromptSubmit` **and** `Stop`, so it runs on essentially every turn — and it runs from the **installed plugin**, not from the checkout. v1.0.112 predates decision K1, so its `mission/scripts/lib/resolve.sh` still carries the *old* living migration:

```
# resolve.sh:166 (v1.0.112)
#   status: active + drive_authorized: true  ->  status: approved
#   status: active without the stamp         ->  status: draft
```

K1 reversed that direction — `draft`/`approved` fold **into** `active`. So the stale lens rewrites every active mission `active` → `draft` on every turn, **and stages the result**:

```
$ git status --porcelain
M  .workaholic/missions/active/adopt-a-git-flow-branching-model-with-durable-ship-records/mission.md
M  .workaholic/missions/active/make-scheduled-routines-a-configurable-inspectable-part-of-a-repository/mission.md
M  .workaholic/missions/active/make-the-branch-story-concise-by-default/mission.md
M  .workaholic/missions/active/make-the-per-commit-changed-lines-ceiling-a-rule-that-holds/mission.md
```

## Why this is loop-stopping, not cosmetic

`/drive` step 0 fast-forwards before surveying, and a dirty workspace is a **terminal** condition:

```
$ bash plugins/workaholic/skills/branching/scripts/sync-main.sh
{"ok": false, "reason": "dirty_workspace", "branch": "main", "summary": "4 staged"}
```

Per `commands/drive.md` step 0, `dirty_workspace` **terminates `pending` rather than surveying**. So once the drift exists, every subsequent tick of the routine halts *before it learns what is queued* — firing on time, doing nothing, and reporting `pending` forever. That is the same "reads as healthy while doing nothing" failure mode `check-bootstrap.sh` exists to prevent, arriving by a different route.

Two aggravating properties:

- **The rewrite is staged, not merely modified.** Any commit made in the main checkout with `git add -A` would sweep a K1 reversal into an unrelated change. The run that found this escaped only because its commits named explicit files and its ticket work happened inside a claim worktree.
- **It is invisible without `git status`.** The lens prints its normal roster line either way; nothing announces that it just rewrote four artifacts.

Confirmed *not* the cause: `plan-units.sh` and the other scripts invoked from the checkout leave the tree clean — a survey was run immediately after a restore and the tree stayed clean. The writer is the hook, running installed code.

## Policies

- `workaholic:operation` / `policies/deployment-pipeline.md` — the installed plugin is the deployed artifact of this repository; a deployment that silently serves a thirteen-version-old build against current data is a delivery defect, not a user error
- `workaholic:implementation` / `policies/observability.md` — a migration running backwards, staging its output, and announcing nothing is the masked failure this policy forbids; the loop then reports `pending` with no indication why
- `workaholic:implementation` / `policies/error-handling.md` — a living migration that can run in reverse against newer data needs a guard, not just a comment describing the intended direction

## Key Files

- `plugins/workaholic/hooks/mission-lens.sh` — the always-on writer; runs installed, fires twice per turn
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` — the living migration whose direction K1 reversed
- `plugins/workaholic/skills/branching/scripts/sync-main.sh` — where the dirty tree becomes terminal
- `plugins/workaholic/skills/check-deps/scripts/check.sh` — already reports the installed `version`; it is the natural place to notice drift, and today it returns `ok: true` regardless
- `plugins/workaholic/skills/workaholify/bootstrap/session-start.sh` — installs the plugin at session start; the question of whether it refreshes a long-lived session belongs here
- `docs/drive-loop-runbook.md` — needs the diagnosis row

## Related History

`check-bootstrap.sh` exists because a cloud session with no bootstrap hook made every routine stop at its own precondition while reading as healthy. This is the same class one layer down: the bootstrap *did* run, but at a version that has since been superseded.

Decision K1 (2026-07-31) reversed the migration direction. Nothing at the time asked what an *already-installed* older plugin would do to a K1-era repository — the transition window was reasoned about for data (readers tolerate both spellings), not for code.

## Implementation Steps

1. **Make the drift visible where it is already measurable.** `check-deps/scripts/check.sh` reads the installed `version`; have it compare against the checkout's `.claude-plugin/marketplace.json` and report a `version_drift` field with both values. `/drive` §1 already prints `check.sh`'s message and continues on a warning — this fits that seam exactly.
2. **Decide whether drift is a warning or a stop**, and record the reason. Recommend **warning plus a named report line**, not a hard stop: a runner that refuses to work because its plugin is old is as useless as one that works wrongly, and the drift is not always harmful. The stop is already provided by `dirty_workspace` when it *is* harmful.
3. **Guard the living migration against running backwards.** `resolve.sh`'s status fold should be a no-op when the file's vocabulary is *newer* than the code's — concretely, an installed build that does not know `active` as a valid in-flight status must not rewrite it. A migration that cannot tell "older than me" from "newer than me" will do this again on the next vocabulary change.
4. **Answer whether a long-lived session should refresh its plugin.** `session-start.sh` installs at session start; a session that outlives a release keeps the old build for its whole life. Either refresh on a later signal, or state plainly that it does not and rely on step 1 to surface it. Record whichever is chosen.
5. **Add the runbook row**: symptom (`sync-main.sh` → `dirty_workspace`, staged mission files nobody edited), cause (installed plugin older than the checkout), action.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `check-deps/scripts/check.sh` reports the installed version *and* the checkout's, and names the mismatch when they differ.
- A `/drive` run against a drifted install reports the drift in its run report rather than only in the terminal token.
- `resolve.sh`'s status migration is a no-op on a status word the running build does not recognize as legacy — proven by a test that runs the *old* fold over an `active` mission and asserts the file is unchanged.
- `docs/drive-loop-runbook.md` carries the diagnosis row.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` green, with a case that fixtures a mission at `status: active` and asserts the migration leaves it alone.
- A manual check on this container: with the 1.0.112 cache in place, a turn no longer leaves four staged mission files.

**Gate** — what must pass before approval:

- The suite is green, and the drift-versus-stop decision plus the session-refresh answer are both written down.

## Considerations

- **Do not fix this by editing the plugin cache.** It is outside the repository, so repository confinement forbids it, and a fix that lives in one container is not a fix. The run that found this deliberately restored the four files with a targeted `git restore` and left the cache alone.
- **The staging is the dangerous half.** Even if the rewrite were harmless, a hook that leaves changes *staged* in the developer's checkout can contaminate an unrelated commit. Whether an always-on lens should ever `git add` is worth asking separately.
- Step 3 is the durable fix and step 1 is the visible one; step 1 alone would leave the next vocabulary change to rediscover this.
