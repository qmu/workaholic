---
created_at: 2026-06-28T00:20:48+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash: 7a584b9
category: Added
depends_on: [20260628002047-gate-commit-and-branch-via-pretooluse-bash.md]
---

# Ship a real `/commit` command that wraps commit.sh

## Overview

The plugin ships commands `/ticket`, `/drive`, `/report`, `/ship`, `/release` — but **no
`/commit`**. There is a `workaholic:commit` skill and a `commit.sh` script that produces the
structured, policy-conformant message, yet no command surface invokes them for an ad-hoc commit.
Consumer-repo docs that list a `/commit` command therefore point at nothing, and an agent asked to
"commit this" outside `/drive` free-hands a raw `git commit` — picking up Conventional-Commits
prefixes from surrounding history and harness-default trailers, exactly the off-policy output the
commit gate (`20260628002047`) now blocks.

A block with no sanctioned alternative is a dead end. This ticket supplies the alternative: a thin
`/commit` command that orchestrates the existing `workaholic:commit` skill and `commit.sh` so
small, legitimate, non-ticketed changes (docs, config, a one-line fix, an explicit user request)
have a policy-conformant path. `/drive` remains the preferred path for ticketed work; `/commit` is
the escape hatch that keeps the message format intact instead of bypassing it.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST** read
each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/command-scripts.md` — **central:** the command is thin orchestration; it must call `commit.sh`, never re-implement commit/staging logic (one runnable source of truth).
- `workaholic:implementation` / `policies/directory-structure.md` — the command lands at `plugins/workaholic/commands/commit.md`, matching the other command files (applies to all code work).
- `workaholic:design` / `policies/least-privilege-or-force.md` — staging follows `commit.sh`'s existing `git add -u` default; never `git add -A`. Untracked files are staged only by explicit path after asking.
- `workaholic:implementation` / `policies/coding-standards.md` — any inline shell in the command obeys the Shell Script Principle (defer to bundled scripts, no inline conditionals).

Repo-own rules (CLAUDE.md): **Thin commands, comprehensive skills** (the command is ~50 lines of
orchestration; knowledge stays in the skill); **Plugin Boundary Rule** (invoke `workaholic:commit`
by namespace, run `commit.sh` via `${CLAUDE_PLUGIN_ROOT}`, never spelunk); the `commit` skill
carries `metadata.internal: true` (script-bearing) and stays out of cross-agent discovery; commands
are Claude-Code-only (no `outputs/` footprint).

## Key Files

- **New** `plugins/workaholic/commands/commit.md` — frontmatter preloading `workaholic:commit` (and `workaholic:gather` for metadata). Body: gather `git status` + the staged diff, derive a present-tense title ≤50 chars with **no** prefix, derive the `Why`/`Changes`/`Concerns`/`Insights`/`Verify` body, then run `sh ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>" [--category <Added|Changed|Removed>]`. Carry a `**Notice:**` / **Plugin boundary** header like the other commands. If untracked files exist, ask before staging them by explicit path.
- `plugins/workaholic/skills/commit/SKILL.md` — the knowledge the command leans on (title rule, multi-contributor staging, arg order). Do not duplicate it into the command.
- `plugins/workaholic/skills/commit/scripts/commit.sh` — the executor; confirm the command passes args in the exact positional order the script expects.
- `plugins/workaholic/commands/drive.md` — reference for the thin-command shape, `**Notice:**` header, and skill-preload frontmatter.
- `.claude-plugin/marketplace.json` / CLAUDE.md command table — add `/commit` to the documented command list so the plugin advertises what it now ships.

## Related History

Past tickets that touched similar areas:

- [20260128001720](.workaholic/tickets/archive/feat-20260128-001720) - Extracted the `create-ticket`/commit skills and codified the thin-command / comprehensive-skill split this command obeys.
- [24e5b37 restructure-commit-body-for-report](.workaholic/tickets/archive/work-20260627-153246/20260627210216-restructure-commit-body-for-report.md) - Defined the current `commit.sh` arg contract (`why/changes/concerns/insights/verify`) the command must call with.

## Implementation Steps

1. **Author `commands/commit.md`** as thin orchestration: preload `workaholic:commit`, gather status/diff, derive a conformant title + structured body, invoke `commit.sh` with the correct positional args and optional `--category`.
2. **Handle staging safely:** rely on `commit.sh`'s `git add -u`; for untracked files, list them and ask before adding by explicit path (never `git add -A`).
3. **Document it:** add `/commit` to the CLAUDE.md command table and any user-facing command list, with a one-line "for small non-ticketed changes; prefer `/drive` for ticketed work" note.
4. **Cross-check the gate:** confirm a `commit.sh` invocation issued by this command is allowed by `guard-git-commit.sh` (`20260628002047`) — i.e. the gate must whitelist the sanctioned script path, not just bare `git commit`.
5. **Verify.** `node scripts/build-plugins/verify.mjs`; dry-run the command's `commit.sh` call with sample inputs to confirm the message renders with no prefix and a ≤50-char subject. Commands are Claude-only — no `outputs/` rebuild.

## Considerations

- **Escape-hatch risk:** a `/commit` command can invite non-ticket commits. Mitigate in the command copy — state it is for small/explicit changes and that `/drive` is preferred for anything ticketed. It is still strictly better than undocumented free commits, because both the command and the gate preserve the message policy.
- **Don't reimplement staging or message assembly** in the command — `commit.sh` already owns multi-contributor-safe staging and trailer rendering. The command only *derives inputs* and calls it (`command-scripts`).
- **Co-author coupling:** this command must not hand-add any `Co-Authored-By` line — attribution is whatever `commit.sh` emits after ticket `20260628002049` settles the policy. Keep the command trailer-agnostic.
- **Depends on the gate ticket** only for the whitelist coordination in step 4; the command itself is otherwise independent and could be built in parallel.

## Final Report

Development completed as planned. The `/commit` command is a thin orchestration over `workaholic:commit` + `commit.sh`; no staging or message-assembly logic was duplicated into it.

### Discovered Insights

- **Insight**: `commit.sh` parses option flags (`--category`, `--skip-staging`) ONLY at the front of its argument list — the parse loop `break`s on the first non-flag token. A `--category` placed *after* the six positional args is silently consumed as a `[files...]` entry (staged-or-skipped), and the `Category:` trailer goes missing with no error.
  **Context**: Any caller (this command, future commands, CI) must pass flags **before** `title why changes concerns insights verify`. A temp-repo dry-run is the only thing that surfaces this — the missing trailer is invisible to `verify.mjs`. The command doc now states the ordering explicitly.
- **Insight**: The commit gate (`guard-git-commit.sh`, 2047) needs no explicit whitelist for the sanctioned path. `commit.sh` is invoked as `sh …/commit.sh …`, which carries no top-level `git commit`, so the gate's `*git*commit*` relevance filter never matches it. The "whitelist the script path" coordination the ticket anticipated in step 4 was therefore a no-op — the gate is correct by construction, locked by the `guard-commit allows commit.sh invocation` smoke test.
  **Context**: This is the same hook-scope property recorded on 2047: PreToolUse(Bash) only sees the top-level command, so script-wrapped git is invisible to the gate.
