---
created_at: 2026-06-28T00:20:47+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 2h
commit_hash: f79f1a3
category: Changed
---

# Gate off-policy `git commit` and branch creation with PreToolUse Bash hooks

## Overview

The plugin's commit-message format and branch-naming rule are **prose-in-skills**, not gates. The
commit body/title (`Why`/`Changes`/`Concerns`/`Insights`/`Verify`, present-tense ≤50-char subject,
"No prefixes like `feat:`") is produced **only** by `skills/commit/scripts/commit.sh`, which is
invoked only from the `drive`/`trip`/`ship` flows. The branch rule (`work-<YYYYMMDD-HHMMSS>` via
`skills/branching/scripts/create.sh`, "Never name a branch yourself") is likewise documented and
implemented only by `create.sh`. Nothing **rejects** a violation: there is no `commit-msg` git hook
and no branch-creation gate. The only `PreToolUse(Bash)` hook today (`guard-ticket-structure.sh`)
inspects ticket-path `mv/cp/mkdir` and never looks at `git commit` or `git checkout -b`.

The result, observed live: any session that commits or branches outside the three workflow skills
falls back to (a) the surrounding git log — which prior sessions polluted with Conventional-Commits
prefixes — and (b) harness defaults, producing `feat:`/`docs:`/`chore:`-prefixed subjects,
off-pattern branch names, and unwanted co-author trailers. Pollution begets pollution because the
model mirrors the noisy history it sees.

This ticket adds the **zero-opt-in** layer: two `PreToolUse(Bash)` hooks that block the
agent/harness failure path before it executes, routing the caller to the sanctioned scripts. It is
the highest-leverage fix and requires no consumer setup (the plugin's `hooks.json` ships active).

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST** read
each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/coding-standards.md` — the hooks are POSIX `#!/bin/sh -eu`, fail-fast, no silent fall-through (applies to all code work).
- `workaholic:implementation` / `policies/directory-structure.md` — new hooks land in `plugins/workaholic/hooks/` beside the existing guards (applies to all code work).
- `workaholic:implementation` / `policies/policy-conformance-audit.md` — **central:** this converts two written conventions into automated rejection gates rather than letting drift re-accrete.
- `workaholic:implementation` / `policies/observability.md` — block messages are structured and actionable: which rule, what was wrong, and the exact sanctioned command to use instead.
- `workaholic:design` / `policies/least-privilege-or-force.md` — the gate must block *only* the violating surface (commit / branch-create) and never read/delete/inspect commands, so it does not obstruct legitimate work.
- `workaholic:operation` / `policies/ci-cd.md` — the same hooks are exercised by the smoke harness so dev and CI verify identically.

Repo-own rules (CLAUDE.md): **Shell Script Principle** (all logic in bundled scripts, no inline
conditionals); **POSIX sh** per `rules/shell.md` (the new hooks are themselves linted by
`posix-lint.sh`); hooks are Claude-Code-only and never ship into `outputs/` (no rebuild). The
subject/branch rules enforced here are the canonical source: `skills/commit/SKILL.md` (title rule)
and `skills/branching/SKILL.md` (branch pattern).

## Key Files

- **New** `plugins/workaholic/hooks/guard-git-commit.sh` (`#!/bin/sh -eu`) — read `.tool_input.command` from stdin JSON via `jq -r` (mirror `guard-ticket-structure.sh`). Detect a direct `git commit` (allow `git -C <path> commit`). Block with exit `2` and route to `/commit` or `sh ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh`. When the command carries an inline message (`-m`/`-F`/heredoc), additionally report the specific subject violation when detectable: Conventional-Commit prefix `^[A-Za-z][A-Za-z0-9_-]*(\([^)]*\))?!?:[[:space:]]`, bracket tag `^\[[^]]+\]`, or subject length >50 measured with `wc -m` (NOT `${#var}` — Japanese subjects must count characters, not bytes).
- **New** `plugins/workaholic/hooks/guard-git-branch.sh` (`#!/bin/sh -eu`) — read `.tool_input.command`. Detect branch-creation surfaces: `git checkout -b <name>`, `git switch -c|--create <name>`, `git branch <name>` (a bare name, not a flag), and `git worktree add -b <name>`. Extract the literal name; block (exit `2`) if it is missing/variable-derived or not `^work-[0-9]{8}-[0-9]{6}$`, routing to `sh ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/create.sh`. Must NOT match read/delete forms (`git branch`, `--show-current`, `-d`, `-D`, `-a`, `--list`).
- `plugins/workaholic/hooks/hooks.json` — register both new commands under the existing `PreToolUse` → matcher `"Bash"` `hooks` array (alongside `guard-ticket-structure.sh`), `timeout: 10`. Update the top-level `description` to mention the two new git gates.
- `plugins/workaholic/hooks/guard-ticket-structure.sh` — the reference implementation for stdin-JSON parsing, conservative command matching, and exit-2 blocking. Copy its shape.
- `plugins/workaholic/skills/branching/scripts/ensure-worktree.sh` — defends itself: validate its `branch_name` argument against the same `work-…` pattern before `git worktree add -b`, so the script surface is gated even if the hook is bypassed.
- `scripts/test-workflow-scripts.mjs` — add hermetic tests (see Steps): feed crafted `tool_input.command` JSON to each guard and assert allow/block + exit code, the way existing guard tests work.

## Related History

The repo already ships exactly this shape of gate; this ticket extends the pattern to two new
command surfaces.

Past tickets that touched similar areas:

- [20260624140219-guard-ticket-structure.md](.workaholic/tickets/archive/work-20260624-140219) - Added `guard-ticket-structure.sh`, the `PreToolUse(Bash)` blocking hook this ticket mirrors for git commit/branch.
- [20260627153248-harden-posix-shell-gate.md](.workaholic/tickets/archive/work-20260627-153246/20260627153248-harden-posix-shell-gate.md) - Established the "convention → automated rejection gate" pattern (lint + regression-lock test) this ticket follows.

## Implementation Steps

1. **Write `guard-git-commit.sh`.** Parse stdin JSON. If the command is not a `git commit`, exit 0 (allow). If it is, by default block and route to the sanctioned commit path; when an inline message is present and parseable, include the precise reason (prefix / bracket tag / >50 chars via `wc -m`). Keep matching conservative — when in doubt that it is a commit, block and explain, never silently allow.
2. **Write `guard-git-branch.sh`.** Parse stdin JSON. Match only branch-creation forms; extract the literal name; allow iff `^work-[0-9]{8}-[0-9]{6}$`; otherwise exit 2 routing to `create.sh`. Explicitly skip read/delete/list forms.
3. **Register both** in `hooks.json` under `PreToolUse`/`Bash`, and refresh the `description`.
4. **Harden `ensure-worktree.sh`** to validate its branch-name arg with the same regex before creating a branch.
5. **Add smoke tests** in `scripts/test-workflow-scripts.mjs`: a battery of `tool_input.command` strings per guard — allow (`work-20260628-002047`, `git branch --show-current`, a clean `commit.sh` invocation) and block (`feat: x`, `[fix] y`, a 60-char subject, `git checkout -b watchtower-foo`, `git switch -c main2`, variable-named branch). Assert exit codes and that the block message names the sanctioned command.
6. **Verify.** `node scripts/test-workflow-scripts.mjs` green; `node scripts/build-plugins/verify.mjs`; confirm `posix-lint` flags nothing in the two new hooks. No `outputs/` rebuild (hooks are excluded from the bundle).

## Considerations

- **Un-gateable, state it plainly:** a human's terminal `git commit` / `git checkout -b`, `--no-verify`, GitHub-web/server merge commits, and any agent path that does not go through Bash are NOT caught here. Closing the human-terminal gap is the separate git-`commit-msg` ticket (`20260628002050`); this hook covers the agent/harness surface only. Do not over-claim coverage in the block text.
- **Conservative matching is correct.** A computed/variable branch name or an unparolder commit message should **block and route**, not guess. False-block routes the caller to the right script; false-allow re-pollutes history. Prefer the former.
- **Character vs byte length.** Subjects are routinely Japanese; measure the 50-char cap with `wc -m`, never `${#var}` (bytes), or every multibyte subject false-trips.
- **Don't fight `git -C`.** Allow `git -C <path> commit` to be matched as a commit (it is one); just parse past the `-C <path>` tokens. The plugin's own workflows sometimes use it.
- **Block copy is the UX.** The whole point is to teach the next session the sanctioned path — every block must name `/commit` / `commit.sh` / `create.sh` explicitly (`observability`).

## Final Report

Development completed as planned, with one scope refinement settled with the developer during the drive.

### Scope decision (recorded)

The ticket's Implementation Steps said the commit gate should *"by default block"* every direct `git commit`. That collides with `/report` Phase 4 (`report/SKILL.md:148`), which commits the branch story with a **raw, policy-conformant** `git commit` through the Bash tool — a block-all gate would break `/report` on first ship. The developer chose **"off-policy subjects only"**: the commit gate blocks only an inspectable `-m`/`-am` subject that carries a Conventional-Commit prefix, a `[bracket]` tag, or exceeds 50 chars. Co-Authored-By trailers are **explicitly allowed** (this also redirected tickets 2049/2050 — see those). This matches the `least-privilege-or-force` design policy the ticket itself cites ("block only the violating surface … so it does not obstruct legitimate work").

### Discovered Insights

- **Insight**: PreToolUse(Bash) hooks only see the agent's *top-level* Bash command, not subprocesses a script spawns. So `commit.sh`, `archive.sh`, and `trip-commit.sh` (which emits an intentional `[Agent]` bracket subject) all run their inner `git commit` invisibly to the gate — the sanctioned wrappers are immune by construction, no whitelist needed.
  **Context**: This is why the gate can be strict about raw `git commit -m "..."` without touching any workflow that goes through a script. It also means the gate's coverage is exactly "free-handed git in a single Bash call," nothing nested.
- **Insight**: A block-all commit gate would have silently broken `/report`'s story commit, which is a deliberately *bodyless* conformant commit (no Why/Changes/Category). The repo's only raw-`git commit`-via-Bash sites are `report/SKILL.md:148`; everything else wraps `commit.sh`.
  **Context**: When tightening an enforcement gate, grep the command/skill markdown for the raw operation first — a documented workflow step is easy to miss and the gate fires before the step can run.
- **Insight**: `wc -m` measures bytes under a C/POSIX locale, characters only under a UTF-8 locale. The gate uses `wc -m` per the ticket, so character-accurate 50-char enforcement of Japanese subjects depends on the runtime locale being UTF-8.
  **Context**: A future tightening (or the 2050 `commit-msg` hook sharing this logic) should be aware the cap is byte-based in CI's default locale.
