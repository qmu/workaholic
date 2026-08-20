# Worktree scripts — reference

Companion reference for [`../SKILL.md`](../SKILL.md)'s **Worktree management**, **Reclaiming
worktrees**, and **Credentials** sections. The SKILL carries the rules and the locator table;
below is each script's full contract — arguments, emitted JSON, error cases — plus the
mode-detection legacy and the env-carry detail.

## Legacy mode detection

`detect-context.sh`'s `mode` field is legacy, and every value routes the same way today. It distinguished two workflow styles inside the `work` context until the design/build session workflow was retired (2026-07-28); the script still computes it so branches created before then keep reporting what they are:

| Mode | Condition |
| ---- | --------- |
| `drive` | no trip artifacts for this branch — every branch created since the retirement |
| `trip` | trip artifacts for this branch, no tickets in this user's todo (adds the rationale link to `.workaholic/trips/<name>/designs/` in `workaholic:story`) |
| `hybrid` | both exist (same flow; `workaholic:story` collapses all three) |

"For this branch" is narrow, and deliberately so: `branch_trip_dir()` reads exactly the two associations ever recorded — the legacy naming convention (branch `trip/<name>` owns `.workaholic/trips/<name>`) and the `branch:` field a trip's `plan.md` carries. Anything else reports `drive`, whatever exists under `.workaholic/trips/`. Before that narrowing, `has_trips` was a repo-wide `find`, so one stray trip dir on `main` made every later branch report `trip`/`hybrid` forever — a property of the repository masquerading as a property of the branch. Nothing writes a new association; `trips/` is read-only history. Legacy `drive-*` and `trip/*` branches are detected as `work` context for backward compatibility only — never created.

## Guards

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh
```

Fast, non-blocking worktree-existence guard: `{"has_worktrees": bool, "count": N, "work_count": N}` (`work_count` counts `work-*`/`drive-*`/`trip/*` worktrees). No GitHub API calls, unlike `list-worktrees.sh`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

Workspace cleanliness only (no branch inspection): `{"clean": bool, "untracked_count": N, "unstaged_count": N, "staged_count": N, "summary": "3 unstaged, 2 untracked"}` (`summary` empty when clean).

## Listing

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh
```

All active worktrees, no GitHub calls: `{"count": N, "worktrees": [{"name", "branch", "worktree_path", "type"}]}`. A `.worktrees/<slug>` mission worktree is tagged `"type": "mission"` (ordinary `work-*` dirs stay `"type": "work"`), so `/ship` and the mission lens can distinguish a mission's claim worktree from an ordinary branch worktree.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh
```

Active work worktrees with PR status — queries the GitHub API per worktree, so slower: `{"count": N, "worktrees": [{"name", "branch", "worktree_path", "has_pr", "pr_number", "pr_url"}]}`.

## Create / adopt / eject / cleanup

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/adopt-worktree.sh <branch-name>
```

Take an existing branch and create a worktree for it at `.worktrees/<branch-name>/`; switches to `main` first when the caller is on that branch. Output: `{"worktree_path", "branch", "switched_from": bool}`. Errors: branch not found, worktree already exists, uncommitted changes.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/eject-worktree.sh <worktree-path>
```

Collapse a worktree back to a regular branch in the main working tree; preserves the branch (unlike `cleanup-worktree.sh`, which deletes it). Output: `{"ejected": true, "branch", "main_repo"}`. Errors: not a valid worktree, main tree has uncommitted changes.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/ensure-worktree.sh <branch-name>
```

Create an isolated worktree and a new branch at `.worktrees/<branch-name>/`. Output: `{"worktree_path", "branch"}`. Errors: branch name missing, worktree already exists, branch already exists.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh <branch-name>
```

Remove a worktree and its local branch after PR merge (force-removes the directory, prunes stale entries, deletes the local branch). Output: `{"cleaned": true, "worktree_path", "branch", "worktree_removed": bool, "branch_removed": bool}`.

## Mission (claim) worktrees

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create-mission-worktree.sh <slug> [base-branch]
```

Cut a fresh `work-*` branch off the base (default `main`) into `.worktrees/<slug>/` and carry every env file the project reads (see *Credentials* below). The base is resolved to a concrete commit SHA (local ref, else `origin/<base>`) before it reaches `git worktree add`, so git's remote-tracking DWIM can never silently discard the `-b` and land the worktree on the base branch itself (the fresh-clone state where no local `main` exists); the reported `branch` is read back from the worktree's real HEAD — an observation, not a restatement of intent. Output: `{"worktree_path", "branch": "work-YYYYMMDD-HHMMSS", "slug", "port_base", "dev_port", "docs_port", "env_files_carried": [...], "port_env_file": ".env"|".env.worktree", "size_bytes"}`. `env_files_carried` names every env file copied in — an empty array says "no project env file was found" explicitly, the provisioning tell a caller reads at creation rather than inferring hours later from a failed run. Errors on a missing/invalid slug, a non-git dir, an existing worktree, a base resolving to no commit, or a created worktree whose HEAD disagrees with the minted branch (never exit-0 JSON on a wrong-branch worktree). Also adds `.worktrees/` to `.git/info/exclude` so a linked worktree is never embedded as a gitlink by a main-tree `git add -A`.

The port vars (`WORKAHOLIC_PORT_BASE`/`WORKAHOLIC_DEV_PORT`/`WORKAHOLIC_DOCS_PORT`) let several worktrees run dev/docs servers at once without colliding on `localhost`. They go into the carried root `.env` when the project has one; when the project keeps no root `.env`, into a separate `.env.worktree` — never a fabricated bare root `.env`, the artifact that once made a credential-less worktree look provisioned. The project's serve scripts read the variables; workaholic supplies the numbers and the convention, not the servers.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/allocate-worktree-port.sh
```

Next free port base (`{port_base, dev_port, docs_port}`), scanning bases already assigned in existing `.worktrees/*/.env` — a removed worktree's base is reusable (allocation tracks live worktrees, not a counter).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-mission-worktree.sh <slug>
```

Remove a claim worktree — never discards uncommitted work: refuses a dirty worktree and reports it; idempotent when already gone. Called from the claim-release and ship paths.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/reset-mission-worktree.sh <slug> [base-branch]
```

Reset a persisting worktree for its next batch after a merge — cuts a fresh `work-*` branch off `main` inside the same worktree (only the branch is renewed). `/ship` calls this instead of `cleanup-worktree.sh` for a mission worktree.

## Reclaiming — survey / reap / prune detail

**Survey** reports every worktree with `size_bytes`/`size_human`, `ahead`, `dirty`, `merged`, `reclaimable`, and a `skip_reason`, plus repository totals; it excludes the main tree and `.publish/`. `skip_reason` names which condition failed (`unmerged`, `dirty`, `unmerged_and_dirty`, `current_worktree`, `base_unresolved`), because a skip nobody can explain is indistinguishable from a bug. The measurement that motivated the sweep: 53 GB held across four repositories, 31 GB of it fully merged and clean, one repository holding 29 worktrees of which 22 were merged — and six worktrees correctly skipped on the two-condition rule, which a one-condition reaper would have destroyed.

**Reap** applies the survey's predicate and nothing of its own — one rule, one implementation, so the reaper can never disagree with the reader a human just looked at. Dry run by default; `--apply` removes. Run it from the main checkout: a worktree cannot remove itself, and the current one is reported `skipped` with `current_worktree` rather than failing the run.

**Prune** reclaims build output without removing the worktree — a merged desk someone wants to keep still does not need 13 GB of build output. Default artifact set: `node_modules target dist build .next …` (`WORKAHOLIC_ARTIFACT_DIRS`).

The `.dockerignore` rule exists because a container build actually failed on it: with no ignore file the build context was the repository root, 6.2 GB of which 5.7 GB was `.worktrees/`, copied into an image layer. Backups and indexers have the same exposure.

## Credentials — the carry detail

Do not assume credentials live only at the repository root — many projects keep the runnable unit in a subdirectory whose tooling loads `<package>/.env` relative to that package. Example `.worktree-env`, one repo-relative path per line (blank lines and `#` comments ignored; authoritative when present — a declaration cannot be wrong the way a heuristic can):

```
# the env files this project actually reads
app/.env
config/secrets.env
```

Both creators — `create-mission-worktree.sh` and `ensure-worktree.sh` — call the one shared carrier (`lib/carry-worktree-env.sh`, so they cannot drift). A branch created in the main tree via `create.sh` sits beside the project's env files already, so no copy is needed there. A worktree predating the convention, or created outside the creators, may need a manual copy before it can serve or authenticate. Before recording any "missing credentials" conclusion from inside a worktree, confirm the env files exist where the project reads them (declare them in `.worktree-env` if the default did not find them) — a credential-shortfall claim from an unprovisioned worktree is the false finding this convention exists to prevent (`workaholic:drive` §3a). The cleanup side is symmetric: `cleanup-mission-worktree.sh` refuses a dirty worktree, so a teardown cannot take a git-ignored `.env` with it.
