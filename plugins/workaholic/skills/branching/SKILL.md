---
name: branching
description: Context detection and branch pattern matching for unified commands.
allowed-tools: Bash, Read
user-invocable: false
metadata:
  internal: true
---

# Branching

Detect development context from the current git branch, own the two sanctioned branch patterns, and provide the publish tree and worktree machinery the workflows build on. Per-script contracts live in [`reference/worktrees.md`](reference/worktrees.md) (worktree scripts, reclaiming detail, env-carry detail, legacy mode detection) and [`reference/publish-tree.md`](reference/publish-tree.md) (publish-tree outputs, refusals, env vars, design rationale).

## Context Detection

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
```

| Context | Branch pattern | Routing |
| ------- | -------------- | ------- |
| `work` | `work-*` (created); `drive-*`, `trip/*` (legacy, detected only — never created) | run the branch flow (`workaholic:story` / `workaholic:ship`) |
| `worktree` | other branch, worktrees exist | each is a claim worktree — list them, let the user choose which to act on |
| `unknown` | `main`/`master`/other, no worktree resolves | say which branch was detected and stop; do not guess |

The JSON also carries a legacy `mode` field (`drive`/`trip`/`hybrid`); every value routes the same way today ([`reference/worktrees.md`](reference/worktrees.md)).

## Branch patterns — two literals, nothing else

A unit's branch is always named exactly `work-<YYYYMMDD-HHMMSS>` by `create.sh`, the only creator of one. Never name a branch yourself, never append a feature/description suffix, never use another prefix. The one other permitted form is the release tier's `release/<YYYYMMDD-HHMMSS>`, minted only by `cut-release-branch.sh`; `hooks/guard-git-branch.sh` permits those two literal patterns and blocks everything else.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh   # -> {"branch": "work-YYYYMMDD-HHMMSS"}
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh    # -> {"on_main": bool, "branch": "<name>"}
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cut-release-branch.sh [base]
```

A `release/*` branch is the release tier's QA window between merged-onto-the-base and released-to-production (decisions L1/L2 — no `develop`, no `hotfix/*`). `cut-release-branch.sh` output: `{"ok": true, "branch": "release/YYYYMMDD-HHMMSS", "base", "sha", "pushed": true}`; refusals ride stdout with exit 0 (`no_origin`, `origin_unreachable`, `base_unresolved`, `branch_collision`, `branch_creation_failed`, `push_failed`). Four load-bearing properties: cut FROM the base, so structurally post-merge — a batch-level act, never a per-unit ship step; carries no commits of its own (the durable record lives on the base in `.workaholic/releases/`, written by `workaholic:ship`); never checks the branch out; a collision is reported, never overwritten, and a push failure rolls the local ref back.

## The Publish Tree

A publish tree is a checkout of `origin/main` at the fixed, git-ignored `.publish/` on the fixed local branch `publish-main`, independent of the caller's working tree — an artifact is written and published without depending on, or disturbing, whatever the developer is doing (decision J2); the caller's branch, staged set, untracked set, and file contents are left byte-identical. **A publish tree is not a claim worktree**: it holds no unit, is never pushed as a branch, and is disposable at any moment. `create.sh` and `create-mission-worktree.sh` remain branch/worktree creators for claims only; nothing in this lifecycle creates a `work-*` branch or a `.worktrees/` entry.

### Lifecycle: open → write → publish → close

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/open-publish-tree.sh [base]
# write the artifact under <path>/…
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/close-publish-tree.sh [base]
```

Publish has two destinations, and the branch one is the default. Both run `commit.sh` inside the publish tree (a `( cd … && … )` subshell), so the commit inherits the subject gate and the trailers:

| Script | Destination | Use it for |
| ------ | ----------- | ---------- |
| `publish-tree-pr.sh` | a fresh `work-*` branch + an open pull request | every artifact a person should see land (feedback, missions, tickets) — the merge is the event that can be announced. `WORKAHOLIC_AUTO_MERGE=1` (opt-in; `/specificate` and `/implement` only, 2026-08-11) merges the PR immediately after opening it when the release scan passes, reporting `merged`/`merge_reason` — `main` is the continuously auto-merged dev branch, `release/*` the QA boundary; `/ticket`'s and `/mission`'s PRs keep their human merge |
| `publish-tree-commit.sh` | the base branch directly | only seams already downstream of a merge (e.g. ship-time concern extraction) |

Rules that hold across the lifecycle (outputs, refusal reasons, the `WORKAHOLIC_PR_TITLE` env var, and the full rationale: [`reference/publish-tree.md`](reference/publish-tree.md)):

- Nothing recoverable is ever destroyed by a bookkeeping call: `open` and `close` refuse a dirty publish tree, and `close` also refuses `unpublished_commits` — a clean tree whose `publish-main` tip no remote ref contains, the state a `diverged` publish leaves behind. A collision or surviving non-fast-forward is reported, never resolved by overwriting.
- `pr_failed`/`no_gh` still report `branch` and `sha` because the artifact IS pushed — recover by opening the PR by hand, never by re-publishing. Closing after a PR publish leaves the work on the remote `work-*` branch — the intended end state; "published" and "queued" are different states (J4).
- Every write resolves against the reported `path`, never the caller's cwd; write the whole batch, then publish once. The remote `work-*` name is safe for the claim protocol: the claim scan keys on a `Claim <unit-id>` commit subject, which a publication branch never carries.

## Sync Main

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/sync-main.sh [base]
```

Bring the current checkout's base branch up to date with origin's, fast-forward only. Output: `{"ok": true, "base", "sha", "advanced"}`, or `{"ok": false, "reason": "not_on_main" | "dirty_workspace" | "no_origin" | "origin_unreachable" | "diverged"}` — `diverged` carries `detail: local_ahead | both_diverged`, because unpushed commits on `main` and parted histories are different things to act on. It never merges, rebases or stashes; every state it cannot fast-forward is reported, not resolved. **One exception, added 2026-08-12**: a `both_diverged` base whose reflog holds a single creation entry carries no local commits, so the refusal's rationale ("a reset would discard a developer's work") is provably absent — that one is realigned onto origin, reported as `ok: true` with `realigned: true`, `previous_sha` and a `backup_ref` preserving the old tip. It exists because a cloud container's baked clone sat 59 commits off a rewritten upstream and stopped every hourly tick. Two callers: `/specificate`'s guard step and `/drive`'s freshness step before the survey (decision J3).

## Classify residue

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/classify-residue.sh [base]
```

Classify every dirty path in this checkout **by proof**, so a layer above `sync-main.sh` can tell residue that provably discards nothing from residue that does. Pure read: no commit, no index write, no ref, **no fetch** (a fetch writes remote-tracking refs, and the contract is that index, worktree and every ref are byte-identical across a call). Output: `{"ok": true, "base", "paths": [{"path", "class", "reason"}], "counts": {on_base, regenerable, untracked, divergent, unanswerable, total}}`, or `{"ok": false, "readable": false, "reason": "not_on_main" | "no_origin" | "no_base_ref" | "status_unreadable", "paths": null, "counts": null}` — **`readable` is absent on a completed walk** and a failed one answers `null` counts and a `null` `paths`, never an empty array, which reads as a clean tree.

Five classes, none reachable by inference. **`on_base`**: the index entry *and* the working-tree file both exist and are byte-identical to `<base>:<path>` — the proof form is `superseded`'s (`drive/reference/claims.md`, *Proofs and judgements*), and it is deliberately stricter than *either representation matches*, because a path whose two sides disagree has one side that is somebody's work. **`regenerable`**: the repository's own generator rewrites this path and the base holds a version of it — content is deliberately **not** compared, because *restorable by a command* is a weaker proof than content equality and one class holding both would let a generated file whose generator is broken read as proved. **`untracked`**: its own class, always. **`divergent`**: tracked, changed, not equal to the base's blob — a developer's work. **`unanswerable`**: no base blob, a rename or copy, a symlink, a non-regular base entry — an absence of a reading is never a proof, which is why this class exists rather than collapsing into `on_base`.

**Which paths are generated is not listed here.** Two derivations, both owned elsewhere: `ship/scripts/lib/conflict-class.sh`'s `conflict_class_generated_path` (the repository's one home for *this path is generated output*, sourced and never copied), and the marker each generator writes into its own output — `<!-- okf:generated:begin -->` (`okf/scripts/refresh-index.sh`) and `<!-- GENERATED by ` (`build-plugins/build.mjs`, which writes `hooks/policy-index.md` that way). The marker is read off the **base's** blob, never the working copy, so residue cannot declare itself regenerable; it is self-verifying in the shape `conflict_class_append_only` uses.

## Clear proved residue

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/clear-proved-residue.sh [base]
```

The act on the reading above, and the layer `sync-main.sh` never becomes: it clears **only** residue a proof covers and then lets the existing freshen run unchanged. `sync-main.sh` is byte-identical to its pre-change form — its refusal is correct by its own stated rationale, and widening it would loosen the contract for every other caller, including the ones inside claim worktrees.

It re-derives each path's class **through the same one reader** (`classify-residue.sh --path`) in the moment before it touches that path — never from the opening walk, and never from a second copy of the proof (the standing discipline for a bounded act on a proof — `drive/reference/claims.md`, *When a bounded act may read a judgement*) — and it is idempotent: a second call on a tree it already cleared answers `already_clean` and writes nothing. Per class: an **`on_base`** path is restored to `HEAD` (or, where `HEAD` does not carry it — a staged add of content the base already holds, which is the measured shape — dropped from the index and removed), because both discard bytes the base already holds and the freshen that follows brings them straight back; a **`regenerable`** path is restored the same way and then the repository's own generator re-run, never a blind checkout of the base's copy, which would be a guess wearing a proof's clothes; an **`untracked`** path is **left alone, always** — deleting it is the one irreversible act available here and no proof covers a file that is on no ref; **`divergent`** and **`unanswerable`** are untouched and the run refuses.

Output: `{"ok": true, "base", "cleared": [{"path", "class"}], "regenerated": bool, "generators": [...], "untracked_left": [...]}`, `{"ok": true, "already_clean": true, ...}`, or `{"ok": false, "reason": "divergent_residue" | "unanswerable_residue" | "untracked_present" | "generator_failed" | "classify_unreadable" | "not_a_repository", "paths": [...], "detail"}` — each refusal naming every path that caused it. A reader refusal is passed through **by the reader's own word** (`not_on_main`, `no_origin`, `no_base_ref`, `status_unreadable`) rather than normalised, because a normalised word sends a reader to a string no script printed.

**Every refusal that can precede its writes does**, so a refusal leaves the tree byte-identical rather than half-cleared — `untracked_present` included, because an untracked file keeps the tree dirty however much else is cleared, so clearing the rest would be writes that buy the caller nothing (`--allow-untracked` is for a caller that does not need a clean tree; it clears the proved paths and names what it left). **The one refusal that cannot is `generator_failed`**, and that is stated rather than hidden: running a generator is what a `regenerable` restore *is*, so it is reachable only after the proved restores were made. Those restores stand — each was individually re-derived and each discarded content the base holds — and the path is left where the restore put it, never filled in from the base's copy.

**`/drive` §1 wires it once, never in a loop**: on `sync-main.sh` answering `dirty_workspace`, call the act once and, on `cleared`, re-run `sync-main.sh` once. A freshen that still refuses after a successful clear is reporting something the proof does not cover, and retrying would turn a report into a spin.

## Worktree management

Scripts live at `${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/<name>`. This table is a locator, not a contract — arguments, JSON outputs, and error cases are in [`reference/worktrees.md`](reference/worktrees.md).

| Script | What it does |
| ------ | ------------ |
| `check-worktrees.sh` | fast worktree-existence guard (`has_worktrees`, counts); no GitHub calls |
| `check-workspace.sh` | workspace cleanliness (`clean`, per-kind counts, `summary`) |
| `list-all-worktrees.sh` | all worktrees with `type` (`work`/`mission`/`other`); no GitHub calls |
| `list-worktrees.sh` | work worktrees with PR status (queries GitHub, slower) |
| `adopt-worktree.sh <branch>` | move an existing branch into `.worktrees/<branch>/` |
| `eject-worktree.sh <path>` | collapse a worktree back to a plain branch (preserves the branch) |
| `ensure-worktree.sh <branch>` | create a new branch + worktree |
| `cleanup-worktree.sh <branch>` | remove worktree and local branch after a PR merge |
| `create-mission-worktree.sh <slug> [base]` | claim-side creator: fresh `work-*` branch in `.worktrees/<slug>/`, unique port base, env files carried |
| `allocate-worktree-port.sh` | next free port base across live worktrees |
| `cleanup-mission-worktree.sh <slug>` | remove a claim worktree; refuses a dirty one, idempotent when gone |
| `reset-mission-worktree.sh <slug> [base]` | fresh `work-*` branch inside a persisting worktree after a merge (`/ship` uses this, not `cleanup-worktree.sh`, for a mission worktree) |
| `check-version-bump.sh [base]` | `{ok, already_bumped, base, reason}` — is a `Bump version …` commit already on this branch, matched on the **subject** and measured against the **resolved** base (`gather/scripts/base-ref.sh`), never a local `main` a checkout pinned stale. Offline: it reads, it never fetches. An unresolvable base is `ok: false` + `reason` and **always** `already_bumped: false` — the caller bumps (`workaholic:story` Phase 0) |

A mission runs in a persistent worktree keyed by its slug directory — `.worktrees/<mission-slug>/`, not a `work-*` directory — while the branch checked out inside is still an ordinary `work-*` branch (the branch-name invariant holds); only the directory carries the mission's name. Each worktree gets a unique local port base (`WORKAHOLIC_PORT_BASE`/`WORKAHOLIC_DEV_PORT`/`WORKAHOLIC_DOCS_PORT`) so several can run dev/docs servers at once without colliding.

## Reclaiming worktrees

Every teardown (`/ship`, `/drive`'s auto path, claim release) needs a run to reach its end; the sweep catches what those structurally cannot — the interrupted run, the hand-driven branch, the mission open for weeks:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/survey-worktrees.sh [base]              # read-only
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/reap-worktrees.sh [--apply] [base]      # dry run by default
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/prune-worktree-artifacts.sh [--apply] <path>
```

**Reclaimable is two conditions and both are required: `merged` AND `clean`** — either alone is not enough, and every skip is named with its reason. Reap applies exactly the survey's predicate (one rule, one implementation, so the reaper can never disagree with the reader a human just looked at) and is a dry run by default. Prune reclaims build output without removing the worktree; its target must be git-ignored **and** in the named artifact set (`WORKAHOLIC_ARTIFACT_DIRS`) — ignored-ness alone would take `.env` and the leak denylist, exactly what `git clean -Xdf` would destroy.

**`.worktrees/` and `.publish/` sit inside the repository root — add both to `.dockerignore`** and to the ignore list of any archiver or indexer rooted at the repository; the scripts add them to `.git/info/exclude`, which covers git and nothing else.

## Credentials — carry every env file the project reads

`git worktree add` never brings a git-ignored file along, and env loaders fail silently on a missing file — a worktree missing the real env file looks fine and reports "no credentials" as a plausible, durable, wrong finding. Both worktree creators call one shared carrier (`lib/carry-worktree-env.sh`, so they cannot drift), which **copies** each env file the project reads (a copy, not a symlink — worktrees diverge credentials independently) and reports `env_files_carried`. A project declares its env layout in a repo-root `.worktree-env` (one repo-relative path per line; authoritative when present); absent, the default is the root `.env` plus any git-ignored subdirectory `.env`. An empty `env_files_carried` is a provisioning finding, not a fact: confirm the files exist where the project reads them before recording any "missing credentials" conclusion ([`reference/worktrees.md`](reference/worktrees.md), *Credentials*).

## Caveats

- The trip↔branch association is read narrowly — the `trip/<name>` naming convention or a plan's `branch:` field, nothing else (a repo-wide `find` once made one stray trip dir report every later branch as `trip`/`hybrid` forever).
- `create-mission-worktree.sh` resolves the base to a concrete SHA before `git worktree add` and reads `branch` back from the worktree's real HEAD (git's remote-tracking DWIM once silently dropped `-b` on a fresh clone and landed the worktree on the base itself).
- The survey finds the main tree as the first record of `git worktree list`, never `git rev-parse --show-toplevel` (inside a linked worktree the latter answers "the tree I am standing in", which once reported the main checkout as reclaimable).
