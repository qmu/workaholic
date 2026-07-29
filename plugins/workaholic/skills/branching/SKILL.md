---
name: branching
description: Context detection and branch pattern matching for unified commands.
allowed-tools: Bash, Read
user-invocable: false
metadata:
  internal: true
---

# Branching

Detect development context from the current git branch pattern to route unified commands to the appropriate workflow.

## Context Detection

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/detect-context.sh
```

### Output Format

| Context | Branch Pattern | JSON |
| ------- | -------------- | ---- |
| `work` | `work-*` (created); `drive-*`, `trip/*` (legacy, detected only) | `{"context": "work", "branch": "<branch>", "mode": "<mode>"}` |
| `worktree` | Other (with worktrees) | `{"context": "worktree", "branch": "<branch>"}` |
| `unknown` | `main`, `master`, or other | `{"context": "unknown", "branch": "<branch>"}` |

### Mode Detection

The `mode` field is **legacy**, and every value routes the same way today. It distinguished two workflow styles inside the `work` context until the design/build session workflow was retired (2026-07-28); `detect-context.sh` still computes it so branches created before then keep reporting what they are.

| Mode | Condition | Routing |
| ---- | --------- | ------- |
| `drive` | No trip artifacts **for this branch** — every branch created since the retirement | Story generation, version bump, PR |
| `trip` | Trip artifacts **for this branch**, no tickets in this user's todo | Same flow, plus the rationale link to `.workaholic/trips/<name>/designs/` |
| `hybrid` | Both this branch's trip artifacts and this user's tickets exist | Same flow (`workaholic:report` collapses all three) |

**"For this branch" is narrow, and deliberately so.** Only two trip↔branch associations were ever recorded, and `branch_trip_dir()` in `detect-context.sh` reads exactly those: the legacy naming convention (branch `trip/<name>` owns `.workaholic/trips/<name>`) and the `branch:` field a trip's `plan.md` carries. Anything else reports `drive`, whatever exists under `.workaholic/trips/`. Before that narrowing, `has_trips` was a repo-wide `find` for *any* trip directory, so one March 2026 trip dir on `main` made every branch after it report `trip` or `hybrid` forever — a property of the repository masquerading as a property of the branch. Nothing writes a new association now; `trips/` is read-only history.

### Context Routing

- **work**: Run the branch flow (`workaholic:report` / `workaholic:ship`). The `mode` value does not change the route.
- **worktree**: Not on a work branch, but worktrees exist — each is a claim worktree. List them and let the user choose which claim to act on.
- **unknown**: Neither a work branch nor a resolvable worktree. Say which branch was detected and stop; do not guess.

### Backward Compatibility

Legacy `drive-*` and `trip/*` branches are **detected** as `work` context. They are recognized for backward compatibility only — **never created**. New branches are always `work-<timestamp>` (see Create Topic Branch).

## Worktree Guard

Lightweight check for the existence of worktrees. Used by commands that should warn the user before proceeding when worktrees are available.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-worktrees.sh
```

### Output Format

```json
{
  "has_worktrees": true,
  "count": 2,
  "work_count": 2
}
```

- `has_worktrees`: Boolean indicating if any worktrees exist
- `count`: Total number of worktrees found
- `work_count`: Number of work branch worktrees (`work-*`, `drive-*`, `trip/*`)

Unlike `list-worktrees.sh`, this script does not query GitHub API for PR status. It is designed for fast, non-blocking guard checks.

## Workspace Guard

Check whether the working directory has unstaged, untracked, or staged changes. Used by commands that should warn the user before proceeding when the workspace is not clean.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-workspace.sh
```

### Output Format

```json
{
  "clean": false,
  "untracked_count": 2,
  "unstaged_count": 3,
  "staged_count": 0,
  "summary": "3 unstaged, 2 untracked"
}
```

- `clean`: Boolean indicating if the workspace has no changes
- `untracked_count`: Number of untracked files
- `unstaged_count`: Number of unstaged modifications or deletions
- `staged_count`: Number of staged changes
- `summary`: Human-readable description of changes (empty string when clean)

Unlike context detection, this script does not inspect branch patterns. It only reports workspace cleanliness.

## Worktree Management

### Adopt

Take an existing branch and create a worktree for it at `.worktrees/<branch-name>/`. Handles the case where the user is currently on that branch by switching to `main` first.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/adopt-worktree.sh <branch-name>
```

Output: `{"worktree_path": "<path>", "branch": "<branch>", "switched_from": true|false}`

Error cases: branch not found, worktree already exists, uncommitted changes.

### Eject

Collapse a worktree back to a regular branch in the main working tree. Preserves the branch (unlike `cleanup-worktree.sh` which deletes it).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/eject-worktree.sh <worktree-path>
```

Output: `{"ejected": true, "branch": "<branch>", "main_repo": "<path>"}`

Error cases: not a valid worktree, main tree has uncommitted changes.

### List All Worktrees

List all active worktrees with type detection (`work`, `other`). No GitHub API calls.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-all-worktrees.sh
```

Output:
```json
{
  "count": 2,
  "worktrees": [
    {"name": "work-20260404-014400", "branch": "work-20260404-014400", "worktree_path": "/path/.worktrees/work-20260404-014400", "type": "work"},
    {"name": "work-20260403-230430", "branch": "work-20260403-230430", "worktree_path": "/path/.worktrees/work-20260403-230430", "type": "work"}
  ]
}
```

### List Worktrees with PR Status

List active work worktrees with PR status. Queries GitHub API for each worktree, so slower than `list-all-worktrees.sh`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/list-worktrees.sh
```

Output:
```json
{
  "count": 1,
  "worktrees": [
    {"name": "work-20260404-014400", "branch": "work-20260404-014400", "worktree_path": "/path/.worktrees/work-20260404-014400", "has_pr": true, "pr_number": 42, "pr_url": "https://github.com/..."}
  ]
}
```

### Ensure Worktree

Create an isolated worktree and branch. Creates `.worktrees/<branch-name>/` directory and a new branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/ensure-worktree.sh <branch-name>
```

Output: `{"worktree_path": "<path>", "branch": "<branch-name>"}`

Error cases: branch name missing, worktree already exists, branch already exists.

### Cleanup Worktree

Remove a worktree and its local branch after PR merge. Force-removes the worktree directory, prunes stale entries, and deletes the local branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh <branch-name>
```

Output: `{"cleaned": true, "worktree_path": "<path>", "branch": "<branch-name>", "worktree_removed": true, "branch_removed": true}`

### Mission Worktrees

A **mission** runs in a dedicated, persistent worktree keyed by a **descriptive slug directory** — `.worktrees/<mission-slug>/` (e.g. `.worktrees/real-time-notifications/`), *not* a `work-*` directory. The branch checked out inside is still an ordinary `work-YYYYMMDD-HHMMSS` branch (the branch-name invariant is preserved); only the directory carries the mission's name. The worktree persists across many branches (each cut from `main`, merged, and re-cut) and is removed only when the mission is closed.

Create a mission worktree — cuts a fresh `work-*` branch off the base (default `main`) into `.worktrees/<slug>/` and carries **every env file the project reads** in (see *Credentials* below — not the root `.env` by assumption). The base is **resolved to a concrete commit SHA** (local ref, else `origin/<base>`) before it reaches `git worktree add`, so git's remote-tracking DWIM can never silently discard the `-b` and land the worktree on the base branch itself (the desk / fresh-clone state where no local `main` exists); the reported `branch` is then **read back from the worktree's real HEAD**, so it is an observation, not a restatement of intent:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create-mission-worktree.sh <slug> [base-branch]
```

Output: `{"worktree_path": "<path>", "branch": "work-YYYYMMDD-HHMMSS", "slug": "<slug>", "port_base": N, "dev_port": N, "docs_port": N+1, "env_files_carried": ["<rel path>", …], "port_env_file": ".env"|".env.worktree"}`. `env_files_carried` names every env file copied in (an **empty** array says "no project env file was found" explicitly — the provisioning tell a caller reads at creation time rather than inferring hours later from a failed run); `port_env_file` names where the port vars landed. Errors on a missing/invalid slug, a non-git dir, an existing worktree, a base that resolves to no commit, or a created worktree whose HEAD disagrees with the minted branch (never an exit-0 JSON on a wrong-branch worktree).

Each mission worktree is assigned a **unique local port base** (via `allocate-worktree-port.sh` below) written as `WORKAHOLIC_PORT_BASE`/`WORKAHOLIC_DEV_PORT`/`WORKAHOLIC_DOCS_PORT`, so several worktrees can run dev/docs servers at once without colliding on `localhost` (and each can be driven/verified independently, e.g. via Playwright). The port vars go into the carried **root** `.env` when the project has one (so its serve scripts read them with their own env precedence, as before); when the project keeps **no** root `.env`, they go into a separate `.env.worktree` — **never** a fabricated bare root `.env`, which is the artifact that once made a credential-less worktree look provisioned. A project's serve scripts read these variables; workaholic supplies the unique numbers and the convention, not the servers.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/allocate-worktree-port.sh
```

Returns the next free port base (`{port_base, dev_port, docs_port}`), scanning the bases already assigned in existing `.worktrees/*/.env` — so a removed worktree's base is reusable (allocation tracks live worktrees, not an ever-growing counter).

Remove a mission worktree (only sanctioned at `/mission close`) — **never discards uncommitted work**: refuses a dirty worktree and reports it; idempotent when already gone:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-mission-worktree.sh <slug>
```

Reset a mission worktree for its next batch after a merge — cuts a fresh `work-*` branch off `main` inside the same worktree (the worktree persists; only the branch is renewed). `/ship` calls this instead of `cleanup-worktree.sh` for a mission worktree:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/reset-mission-worktree.sh <slug> [base-branch]
```

`list-all-worktrees.sh` tags a `.worktrees/<slug>` worktree with `"type": "mission"` (ordinary `work-*` dirs stay `"type": "work"`), so `/ship` and the mission lens can distinguish a mission's claim worktree from an ordinary branch worktree. `create-mission-worktree.sh` also adds `.worktrees/` to `.git/info/exclude` so a linked worktree is never accidentally embedded as a gitlink by a main-tree `git add -A`.

## Credentials — carry every env file the project reads

Development credentials live in git-ignored env file(s). **Do not assume they live only at the repository root** — many projects keep the runnable unit in a subdirectory whose tooling loads `<package>/.env` *relative to that package*, so the file the project actually reads is not `<repo-root>/.env`. Worktree creation must carry the files the project reads, because `git worktree add` alone never brings a git-ignored file along, and env loaders (e.g. `node --env-file-if-exists`) **fail silently** on a missing file — a worktree missing the real env file looks fine and reports "no credentials" as a plausible, durable, wrong finding.

**A project declares its env layout in a repo-root `.worktree-env` file** — one repo-relative path per line (blank lines and `#` comments ignored). When present it is authoritative (a declaration cannot be wrong the way a heuristic can). When **absent**, the default is backward-compatible: the root `.env` **plus** any git-ignored file basenamed `.env` in a subdirectory (discovered so a subdir-env project works without a declaration). Example `.worktree-env`:

```
# the env files this project actually reads
app/.env
config/secrets.env
```

- **New worktrees carry them automatically.** Both creators — `create-mission-worktree.sh` (a claim's `.worktrees/<unit-id>/`) and `ensure-worktree.sh` (any other branch worktree) — call the **one shared carrier** (`lib/carry-worktree-env.sh`, so they cannot drift), which **copies** each declared/discovered env file to the same relative path in the new worktree (a *copy*, not a symlink — worktrees diverge credentials independently) and reports `env_files_carried`. A branch created in the main tree via `create.sh` already sits beside the project's env files, so no copy is needed there.
- **An empty carry is a provisioning finding, not a fact.** When `env_files_carried` is empty, the worktree holds none of the project's credentials — before recording any "missing credentials" conclusion, confirm the env files exist where the project reads them (declare them in `.worktree-env` if the default did not find them). A credential-shortfall claim from inside a worktree that was never provisioned is the false finding this convention exists to prevent (`workaholic:drive` §3a, `workaholic:development` / `overnight-ai`).
- **Pre-existing / externally-created worktrees may need a manual copy.** A worktree that predates this convention, or was created outside the creators, may hold none of the env files — before it can serve or authenticate, copy the project's env file(s) in as a matter of judgment.

The cleanup side is symmetric: `cleanup-mission-worktree.sh` refuses a dirty worktree and never discards uncommitted work, so a teardown cannot take a git-ignored `.env` with it (`workaholic:drive` §6).

## Branch State Check

Check if the current branch is main/master or a topic branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh
```

### Output Format

```json
{
  "on_main": true,
  "branch": "main"
}
```

- `on_main`: Boolean indicating if on main/master branch
- `branch`: Current branch name

Topic branch patterns: `work-*`

## Create Topic Branch

Create a new timestamped topic branch from the current branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh
```

**Sole branch-name format (mandatory):** branches are **always** named exactly `work-<YYYYMMDD-HHMMSS>` by `create.sh`. This is the only branch-creation path. Never name a branch yourself, never append a feature/description suffix, and never use another prefix. The `drive-*` and `trip/*` forms below are **legacy, detection-only** — recognized for backward compatibility, never created anew.

### Output Format

```json
{
  "branch": "work-20260404-014400"
}
```

## Check Version Bump

Check if a "Bump version" commit already exists in the current branch.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check-version-bump.sh
```

### Output Format

```json
{
  "already_bumped": true
}
```

- `already_bumped`: Boolean indicating if a version bump commit exists in the branch
