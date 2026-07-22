---
name: workaholify
description: Gateway skill a repo's /workaholify setup refers to — reaches the engineering policies (the pillar policies/ directories) and states the working-directory ground rules, instead of duplicating rules into CLAUDE.md.
allowed-tools: Bash, Read, Glob, Grep
user-invocable: false
skills:
  - workaholic:planning
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
metadata:
  internal: true
---

# Workaholify

The single **gateway** a repository refers to in order to work under the workaholic engineering standards. `CLAUDE.md` stays thin and points here; the rules themselves live in the policy skills' `policies/` directories and are reached **by reference, never by duplication** (`workaholic:development` / `policy-as-plugin`). Referring to this one skill is what gives a session access to the whole rule set.

## 1. The rules live in the policies

The engineering rules are the pillar policy skills — read the relevant ones for the work at hand; do not copy them into a project's `CLAUDE.md`:

- `workaholic:planning` — 企画: business, market, and legal grounding before design/implementation.
- `workaholic:design` — 設計: interaction/experience, security design, data sovereignty, API reach.
- `workaholic:implementation` — 実装: code structure, correctness, runtime, recovery, `directory-structure` + `coding-standards` (always apply to code work).
- `workaholic:operation` — 運用: delivery paths, runtime behavior, recovery.
- `workaholic:development` — how the team develops: AI utilization, review, commit history, and working conventions.
- `workaholic:safety` — incident response, risk management, privacy, and security standards.

Each links English hard copies under its `policies/<slug>.md`. This gateway is the referral point; the always-on `hooks/policy-lens.sh` injects the same lens on the workflow commands. To read a rule, open the pillar skill and its `policies/` hard copy — that is the source of truth, kept in sync from qmu.co.jp.

## 2. Working-directory ground rules

Two operational rules a session keeps while working in a repository:

- **Stay at the repository root.** Do not move the working directory away from the repo root; treat the root as home.
- **If you must `cd`, return immediately.** Prefer an **absolute path** or a `( cd <dir> && … )` **subshell** (which never changes the persistent working directory) over a bare `cd` that strands the session outside the root.

These are enforced by `hooks/guard-working-directory.sh` (a `PreToolUse(Bash)` guard that detects a top-level `cd` moving the persistent cwd; a `( cd <dir> && … )` subshell, an absolute-path command, and a tool prefix like `npm --prefix <dir>` are not flagged). A matched top-level `cd` is **denied** (`permissionDecision: "deny"`), with a reason naming the offending command and the sanctioned alternatives — **unconditionally, with no env-var toggle**: enforcement is built into the plugin code, so "plugin installed = guard active", identical on every machine and fresh clone. (An injectable opt-in switch fails open exactly when it is not set, which is when the guard is needed, and an advisory reminder is text an agent ignores.) The subshell / absolute-path / `--prefix` patterns still pass silently, so correct usage is never blocked.

## 3. CLAUDE.md audit

`/workaholify` checks that the repository's `CLAUDE.md` meets the documentation standard — it exists at the root and **refers to this gateway** (rather than embedding the rules). Run the audit and report the checklist:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/workaholify/scripts/audit-claude-md.sh
```

It returns `{file, conformant, checks:{claude_md_present, refers_workaholify_gateway}, missing:[...]}`. When `conformant` is `false`, report the `missing` checks self-explanatorily (`workaholic:design` / `self-explanatory-ui`) and offer to add the missing content — a reference to this gateway, not a copy of the rules. The checklist is intentionally small and extends as the documentation standard grows; keep every check a **verifiable** condition (`workaholic:implementation` / `objective-documentation`).
