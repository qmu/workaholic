---
created_at: 2026-06-30T09:52:32+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash: da33210
category: Changed
depends_on:
---

# Branch guard over-blocks the piped `git branch` list form

## Overview

`hooks/guard-git-branch.sh` wrongly **blocks** a read/list invocation when it is piped or chained, e.g. `git branch | grep foo`. The guard tokenizes the command with `set -- $cmd` (whitespace split only) and has no notion of shell operators, so after it recognizes the `branch` subcommand the next token — the pipe `|` — is fed to `validate`, which rejects it as a non-`work-*` branch name and exits 2.

This is an **over-block** (a least-privilege violation): the list form `git branch` takes no creation argument and must pass. The guard's real job — rejecting bare-name creation like `git branch my-feature` — must stay intact. This was found incidentally while closing the branch-guard misdiagnosis ticket: a routine `git branch | grep …` was refused mid-session.

A correct fix must also keep blocking a *chained* real violation: `git branch ; git checkout -b bad-name` must still be rejected (the `git checkout -b bad-name` after the separator is a genuine off-policy create). So the operator token cannot simply be treated as "allow and stop" — it must **reset the parser state** and keep scanning, so each pipeline/chain segment is inspected independently.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout; the fix stays within the existing `hooks/` script, no new top-level area.
- `workaholic:implementation` / `policies/coding-standards.md` — style/correctness conventions; the guard is a POSIX `#!/bin/sh -eu` script and the repo's `rules/shell.md` (POSIX sh, never bash) governs its concrete shell style.

## Key Files

- `plugins/workaholic/hooks/guard-git-branch.sh` — the guard. The `branch)` arm of the per-subcommand `case` (and the surrounding token loop) is where the pipe is mis-validated as a name.
- `plugins/workaholic/rules/shell.md` — POSIX-sh rule the fix must obey (no bashisms; the guard is `#!/bin/sh -eu`).
- `scripts/test-workflow-scripts.mjs` — hermetic smoke-test harness; the natural home for a stdin-driven regression test of the guard's allow/block decisions (it currently covers branching + drive scripts, not hooks).

## Related History

The over-block was surfaced while closing the branch-guard activation investigation, which proved the guard fires correctly and traced the original report to a stale pre-1.0.66 install.

- [20260630045301-branch-guard-not-enforced-in-session.md](.workaholic/tickets/archive/work-20260630-050446/20260630045301-branch-guard-not-enforced-in-session.md) - Misdiagnosis investigation that incidentally hit this false-positive (same file: `guard-git-branch.sh`).

## Implementation Steps

1. In `guard-git-branch.sh`, treat shell command-separator / pipe tokens (`|`, `||`, `&`, `&&`, `;`, and redirections `>`, `>>`, `<`) as **parser resets**, not as branch names: when one is encountered, set `gitseen=0`, clear `subcmd`, and `continue`. Do this where a name would otherwise be consumed (at minimum the `branch)` bare-name arm; preferably as a single interception near the top of the token loop so it also covers the `checkout`/`switch`/`worktree` arms uniformly).
2. Confirm the bare-create path is unchanged: `git branch my-feature` still reaches `validate` and is blocked (the name token precedes any operator, so `validate` exits first).
3. Confirm a chained violation is still blocked: `git branch ; git checkout -b bad-name` resets on `;`, re-detects `git checkout -b`, and rejects `bad-name`.
4. Add a regression test (stdin JSON → script) asserting: `git branch | grep x` → exit 0 (allow); `git branch` → allow; `git branch foo` → exit 2 (block); `git checkout -b bad` → block; `git branch ; git checkout -b bad` → block; `sh skills/branching/scripts/create.sh`-style `git checkout -b work-YYYYMMDD-HHMMSS` → allow.
5. Re-run `node scripts/build-plugins/verify.mjs` and `node scripts/test-workflow-scripts.mjs`; verify the guard still has no bashisms (the repo's posix-lint).

## Patches

> **Note**: This patch is speculative — verify before applying. It shows the minimal `branch)`-arm form; the preferred top-of-loop interception (covering all subcommands) is described in Step 1.

### `plugins/workaholic/hooks/guard-git-branch.sh`

```diff
     branch)
-      # Bare-name create only. Any flag (-d/-D/-m/--list/--show-current/...) is a
-      # read/delete/rename/list form and is left alone.
-      case "$tok" in
-        -*) exit 0 ;;
-        *) validate "$tok" ;;
-      esac
+      # Bare-name create only. Any flag (-d/-D/-m/--list/--show-current/...) is a
+      # read/delete/rename/list form and is left alone. A shell operator here
+      # means `git branch` was a list/read form (or a pipeline/chain boundary):
+      # reset state and keep scanning so a later `git ...` segment is still
+      # inspected (e.g. `git branch ; git checkout -b bad` must still block).
+      case "$tok" in
+        '|'|'||'|'&'|'&&'|';'|'>'|'>>'|'<') gitseen=0; subcmd=""; continue ;;
+        -*) exit 0 ;;
+        *) validate "$tok" ;;
+      esac
       ;;
```

## Considerations

- The whitespace-only tokenizer is intentional (branch names and paths in these commands are whitespace-free); do not rewrite it into a full shell parser. The fix only needs to stop treating operator tokens as names. (`plugins/workaholic/hooks/guard-git-branch.sh`)
- No-space pipelines like `git branch|grep` are already allowed because `branch|grep` never matches the `branch` subcommand token exactly — only the space-separated `git branch | grep` form is affected. Keep that asymmetry in mind when writing tests. (`plugins/workaholic/hooks/guard-git-branch.sh`)
- Keep it least-privilege: the change must not let any real off-policy creation through, including chained ones after `;`/`&&`/`||`. The reset-and-continue behavior (not allow-and-stop) is what preserves this. (`plugins/workaholic/hooks/guard-git-branch.sh`)
- Stay POSIX `#!/bin/sh -eu` — no bashisms (`rules/shell.md`); Alpine images have no bash.

## Final Report

Development completed as planned. Implemented the **preferred** form from Step 1 (a single operator interception near the top of the token loop, covering every subcommand) rather than the minimal `branch)`-arm patch shown in the speculative Patches section.

`guard-git-branch.sh` now resets parser state (`gitseen=0`, `subcmd=""`, `wantname=0`) on a shell operator token (`|`, `||`, `&`, `&&`, `;`, `;;`, `>…`, `<…`) and continues scanning, so each pipeline/chain segment is inspected independently. Verified:

- `git branch | grep work`, bare `git branch`, and `git branch > file` → allowed (exit 0).
- `git branch ; git checkout -b bad-name` and `git status && git switch -c nope` → still blocked (exit 2).
- `git fetch && git checkout -b work-…` → allowed; all pre-existing block/allow cases unchanged.
- 227/227 smoke tests pass (6 new assertions added to `testGuardGitBranch`); `posix-lint` conforming; `verify.mjs` green.
- **Live in-session**: `git branch | head -3` returned exit 0 — the exact form blocked before the fix.

### Discovered Insights

- **Insight**: The guard scans the **entire** command string and cannot distinguish a real command from text inside an `echo`/quoted argument. After this fix, the literal phrase `git branch <word>` appearing inside an `echo "…"` argument still trips the guard (observed live: an `echo "… git branch piped …"` was blocked on the token `piped`). This is inherent to the whitespace tokenizer, not a regression — but agents should avoid embedding `git branch <word>` in echo/log strings.
  **Context**: The guard receives `tool_input.command` as one opaque string; it has no shell-quoting model, so any `git <subcommand> <word>` substring anywhere in the command line is treated as if it were the real invocation. Widening it to understand quoting would mean a full shell parser, which the script deliberately avoids.
