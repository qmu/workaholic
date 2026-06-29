---
created_at: 2026-06-28T00:20:50+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Config]
effort: 2h
commit_hash: 89ce8e7
category: Added
depends_on: [20260628002047-gate-commit-and-branch-via-pretooluse-bash.md, 20260628002049-stop-emitting-claude-coauthor-trailer.md]
---

# Ship an optional git `commit-msg` hook + explicit installer for human-terminal enforcement

## Overview

The `PreToolUse(Bash)` commit gate (`20260628002047`) blocks the agent/harness surface, but it is
structurally blind to a developer's own terminal `git commit` and to nested helper scripts that do
not pass through Claude's Bash tool. The only thing that also catches those is a **git-native
`commit-msg` hook** — git invokes it regardless of who runs the commit. The plugin cannot write
into a consumer's `.git/hooks` automatically (and must not silently mutate consumer repos), so this
layer is **opt-in**: ship the hook plus an explicit installer the repo owner runs once.

This ticket ships that second layer: a POSIX `commit-msg` hook that enforces the same subject policy
(no Conventional-Commit/bracket prefixes, ≤50 chars by character count) and strips Claude co-author
trailers, plus an `install-git-hooks.sh` that wires it via `core.hooksPath` with safe handling of
repos that already use custom hooks.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST** read
each linked policy hard copy before writing code.

- `workaholic:operation` / `policies/ci-cd.md` — **central:** reproducible, opt-in enforcement that runs identically on every developer's machine once installed; document the one install command.
- `workaholic:design` / `policies/least-privilege-or-force.md` — the installer never silently overwrites; it refuses to clobber an existing `core.hooksPath` without `--force` and prints manual-merge guidance.
- `workaholic:implementation` / `policies/coding-standards.md` — the hook and installer are POSIX `#!/bin/sh -eu`, fail-fast, with clear errors pointing at the policy (applies to all code work).
- `workaholic:implementation` / `policies/policy-conformance-audit.md` — the subject rules in the git hook are the **same** rules the Bash gate enforces; factor them so the two layers cannot drift.
- `workaholic:implementation` / `policies/directory-structure.md` — the git hook lives under `plugins/workaholic/hooks/git/`, the installer beside the other hooks (applies to all code work).

Repo-own rules (CLAUDE.md): **POSIX sh** (`rules/shell.md`) — `posix-lint.sh` will scan these;
**Shell Script Principle** (no inline conditional logic); hooks are Claude-Code-irrelevant at
runtime (git runs them) and have no `outputs/` footprint. The subject rule's canonical source is
`skills/commit/SKILL.md`.

## Key Files

- **New** `plugins/workaholic/hooks/git/commit-msg` (`#!/bin/sh -eu`) — git passes the message file as `$1`. Read the first line (subject). **Strip** Claude co-author trailers (`^Co-Authored-By: .*Claude.*<noreply@anthropic.com>$`) by rewriting `$1`, then validate the subject: reject Conventional-Commit prefix `^[A-Za-z][A-Za-z0-9_-]*(\([^)]*\))?!?:[[:space:]]`, bracket tag `^\[[^]]+\]`, and length >50 via `wc -m`. Non-zero exit with an actionable message pointing at `skills/commit/SKILL.md`.
- **New** `plugins/workaholic/hooks/install-git-hooks.sh` (`#!/bin/sh -eu`) — set `git config core.hooksPath "${CLAUDE_PLUGIN_ROOT}/hooks/git"`. Refuse if `core.hooksPath` is already set to a different path unless `--force`; if the repo has classic `.git/hooks/*` hooks, print manual-merge instructions instead of silently shadowing them. Echo what it did and how to undo it.
- **New (optional)** `plugins/workaholic/hooks/lib/check-subject.sh` — a tiny shared validator (`#!/bin/sh -eu`, function-free POSIX: read subject on stdin/arg, exit non-zero + reason) sourced/called by BOTH `guard-git-commit.sh` and the `commit-msg` hook, so the prefix/length rules have one implementation. If sharing is awkward across the Claude-hook vs git-hook boundary, at minimum keep the regexes byte-identical and cross-referenced in comments.
- `plugins/workaholic/hooks/guard-git-commit.sh` (from `20260628002047`) — refactor its subject checks to the shared validator if the lib is introduced.
- `plugins/workaholic/rules/shell.md` / CLAUDE.md `## Local Verification` — document the one-line install (`sh ${CLAUDE_PLUGIN_ROOT}/hooks/install-git-hooks.sh`) and the `--no-verify` caveat.
- `scripts/test-workflow-scripts.mjs` — tests: feed subjects to the `commit-msg` hook via a temp message file (allow plain ≤50-char; block `feat:`, `[x]`, 60-char) and assert the co-author strip rewrites the file. Hermetic temp dir, no real git config mutation.

## Related History

Past tickets that touched similar areas:

- [20260627153248-harden-posix-shell-gate.md](.workaholic/tickets/archive/work-20260627-153246/20260627153248-harden-posix-shell-gate.md) - The "ship the rule's own enforcement command + lock it with a hermetic test" pattern this ticket follows for git hooks.
- [20260624140219-guard-ticket-structure.md](.workaholic/tickets/archive/work-20260624-140219) - Prior art for shipping enforcement that "reaches consumer repos only after release + update" — the same propagation caveat applies here.

## Implementation Steps

1. **Write the `commit-msg` hook** (strip co-author trailers, then validate subject; clear errors).
2. **Write `install-git-hooks.sh`** using `core.hooksPath`, with the no-clobber / `--force` / manual-merge handling.
3. **Factor shared subject validation** (lib) so the Bash gate and git hook enforce identical rules; refactor `guard-git-commit.sh` to use it.
4. **Document** the install command and the `--no-verify`/human-terminal trade-offs in `rules/shell.md` + CLAUDE.md.
5. **Test** the hook hermetically (temp message files) and the installer's refusal path (pre-set `core.hooksPath`).
6. **Verify.** `node scripts/test-workflow-scripts.mjs` green; `posix-lint` clean on the new scripts; `verify.mjs` green. No `outputs/` rebuild (hooks are not bundled).

## Considerations

- **Opt-in by design.** Do NOT auto-install on `SessionStart` — silently setting `core.hooksPath` in a consumer repo can shadow/break existing hooks and is a least-privilege violation. The repo owner runs the installer deliberately.
- **`core.hooksPath` is exclusive.** Setting it disables `.git/hooks/*`. The installer must detect existing classic hooks or a pre-set `core.hooksPath` and refuse/guide rather than overwrite. Absolute `${CLAUDE_PLUGIN_ROOT}` paths can break if the plugin moves — document re-running the installer after a plugin path change.
- **Still bypassable** via `--no-verify` and on GitHub-web/server merges — state this; it is a strong belt, not a vault. The two layers together (Bash gate + git hook) cover agent + human local commits; remote enforcement (branch protection / required status check) is a separate, repo-side control.
- **Single rule source.** The subject regex/length logic must not exist in two drifting copies — share it (lib) or keep them byte-identical with cross-references, per `policy-conformance-audit`.
- **Propagation caveat:** like all plugin-shipped enforcement, this reaches a consumer only after the plugin is released and the consumer updates — then the owner still must run the installer. Note that in the release/rollout step.

## Final Report

Development completed as planned, with one scope narrowing carried from the batch's co-author decision.

### Scope narrowing (recorded)

Settled during this `/drive` (the "Co-Authored-By is ok" decision that also abandoned ticket `20260628002049`): the `commit-msg` hook enforces the **subject** policy only and **does not strip** Claude co-author trailers. The `lib/check-subject.sh` shared validator therefore covers only the subject rules (prefix / `[bracket]` / ≤50 chars). The Bash gate (`guard-git-commit.sh`) was refactored onto the same lib, so the two enforcement layers share one rule source and cannot drift — satisfying `policy-conformance-audit` exactly as the ticket intended, minus the co-author dimension.

### Discovered Insights

- **Insight**: A git hook must be named exactly `commit-msg` (no extension), but `hooks/posix-lint.sh` only scans `*.sh`, so the git hook is invisible to the POSIX gate. It is POSIX `#!/bin/sh -eu` by construction, but a future bashism in it would NOT be caught by CI.
  **Context**: If more git-native hooks are added under `hooks/git/`, either extend `posix-lint.sh` to also scan that directory by name, or keep them trivially POSIX. The shared logic deliberately lives in `lib/check-subject.sh` (which `posix-lint` *does* scan) precisely to keep the lintable surface maximal.
- **Insight**: `set -e` makes `var=$(cmd)` abort the script when `cmd` exits non-zero. Both the gate and the commit-msg hook expect the shared validator to exit 1 on a violation, so the call is wrapped as `if reason=$(... | sh "$LIB"); then exit 0; fi` — the `if` is what suppresses `-e` for that one expected failure.
  **Context**: Any new caller of `check-subject.sh` must use the same `if`-guarded form, or a normal policy violation will crash the caller instead of being handled.
- **Insight**: Documentation for the install command went to `CLAUDE.md` rather than `rules/shell.md` as the ticket suggested. `rules/shell.md` is scoped to POSIX-shell conventions; the commit-subject gate is commit policy, not a shell convention, so it belongs in CLAUDE.md's verification/hooks documentation next to the policy-lens hook.
  **Context**: A reasonable, intentional deviation from the ticket's Key Files list; flagged here so a reviewer expecting a `rules/shell.md` edit knows it was a deliberate placement choice.
