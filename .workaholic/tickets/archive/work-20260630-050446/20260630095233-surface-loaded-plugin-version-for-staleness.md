---
created_at: 2026-06-30T09:52:33+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash: 19c4b35
category: Changed
depends_on:
---

# Surface the loaded workaholic version so a stale install is detectable

## Overview

A stale plugin install presents an **absent** hook identically to a **broken** one: when a session loads an old workaholic version, a hook added in a newer version simply isn't in the loaded `hooks.json`, so it never fires — and that is indistinguishable from a wiring bug. This is exactly the trap that produced the branch-guard misdiagnosis: a session running a pre-1.0.66 install (which had the PostToolUse validator but not the PreToolUse branch guard, born in v1.0.66) looked like "the PreToolUse matcher is broken" when in fact the guard didn't exist in that build.

Make the loaded plugin version **discoverable**, and assert that the expected PreToolUse Bash guards are present in the loaded `hooks.json`, so an old/partial install is caught instead of mistaken for a code defect. The pre-flight `check-deps` script — already called by `/ticket` and `/drive` — is the natural carrier: it runs from `${CLAUDE_PLUGIN_ROOT}`, so it can read the *loaded* plugin's own version and hooks. This is the residual the misdiagnosis ticket's Step 4 / Considerations called for.

**Scope honesty:** a script running from `${CLAUDE_PLUGIN_ROOT}` knows *its own* loaded version and hooks, but cannot know the "latest" version without a network fetch (and must not fetch). So this surfaces the loaded version + asserts guard *presence*; it does not compute remote freshness. Separately, presence in `hooks.json` is not proof of *activation* — a PreToolUse hook only fires on the Bash *tool* call, not on nested `sh`, so activation must still be verified by an in-session probe, which this ticket documents.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout; the change extends the existing `check-deps` skill, no new top-level area.
- `workaholic:implementation` / `policies/coding-standards.md` — style/correctness conventions; `check.sh` is POSIX `#!/bin/sh -eu` and the repo's `rules/shell.md` (POSIX sh, never bash) governs its concrete shell style.

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/check.sh` — today a trivial `{"ok": true}` stub; extend it to also emit the loaded plugin version and a guard-presence assertion.
- `plugins/workaholic/skills/check-deps/SKILL.md` — document the new output fields, the "absent guard ≠ broken guard" caveat, and the canonical in-session activation probe.
- `plugins/workaholic/.claude-plugin/plugin.json` — source of the loaded `version` the script reads.
- `plugins/workaholic/hooks/hooks.json` — source of truth for which PreToolUse Bash guards should be present (`guard-ticket-structure.sh`, `guard-git-commit.sh`, `guard-git-branch.sh`).
- `plugins/workaholic/commands/drive.md`, `plugins/workaholic/commands/ticket.md` — the callers whose pre-check consumes `check.sh`; they may surface the version line to the user.

## Related History

Direct successor of the branch-guard activation investigation, which closed as a misdiagnosis precisely because staleness was invisible.

- [20260630045301-branch-guard-not-enforced-in-session.md](.workaholic/tickets/archive/work-20260630-050446/20260630045301-branch-guard-not-enforced-in-session.md) - Root-caused the silent-staleness problem this ticket addresses.

## Implementation Steps

1. Extend `check-deps/scripts/check.sh` (keep POSIX sh + `jq`, already a dependency) to read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` `version` and read `${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json`, then emit JSON **additively** (preserve the existing `ok` field so caller parsing is unaffected): add `"version": "<x.y.z>"`, `"guards_present": true|false`, and `"missing_guards": [..]` listing any of the three expected PreToolUse Bash guard commands not found in the loaded `hooks.json`.
2. Keep `ok: true` for the dependency check itself (workaholic has no external plugin deps); use the new fields for diagnostics, not to fail the pre-check. Decide and document whether a missing guard downgrades `ok` or only warns — prefer a non-blocking warning surfaced to the user, to avoid breaking flows on partial installs.
3. Update `check-deps/SKILL.md` to document the new fields and add a short **Activation probe** subsection: the canonical in-session verification is to attempt an off-policy branch (`git branch zzz-probe`) through the Bash tool and observe the PreToolUse block — a shell-only test cannot confirm the tool hook is wired.
4. Have the `/drive` and `/ticket` pre-check surface the loaded `version` (and any `missing_guards`) in the user-visible output, so a stale/partial install is noticed at the start of a flow rather than after an incident.
5. If `check-deps` is part of the built `outputs/workflows` closure, run `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs`; the `Outputs Freshness` CI fails on any uncommitted `outputs/` diff. Re-run `node scripts/test-workflow-scripts.mjs`.

## Considerations

- A script running from `${CLAUDE_PLUGIN_ROOT}` cannot determine the *latest* version without network access; do not add a remote fetch. Scope is surfacing the *loaded* version + guard presence, not absolute freshness. (`plugins/workaholic/skills/check-deps/scripts/check.sh`)
- Hook *presence* in `hooks.json` is checkable from a script, but hook *activation* is not — a PreToolUse hook fires on the Bash tool call, not on nested `sh`. Keep both signals and document the manual activation probe so neither is mistaken for the other. (`plugins/workaholic/skills/check-deps/SKILL.md`)
- Output is parsed by the command pre-checks for the `ok` field; add fields additively and keep `ok` semantics so `/ticket` and `/drive` pre-checks don't break. (`plugins/workaholic/commands/ticket.md`, `plugins/workaholic/commands/drive.md`)
- Stay POSIX `#!/bin/sh -eu` — no bashisms (`rules/shell.md`); `jq` is already the hooks' external dependency, so reusing it is fine.
- This is intentionally non-blocking diagnostics, not a hard gate: a partial install should be *visible*, not a flow-breaker. (`plugins/workaholic/skills/check-deps/scripts/check.sh`)

## Final Report

Development completed as planned, with one deliberate refinement to the approach: the script locates the plugin root **relative to its own path** (three parent hops) rather than via the plugin-root path expansion. This keeps the source and the generated bundle copy byte-identical, so the build copies it verbatim and there is nothing for the build's self-containment rewrite to touch.

`check-deps/scripts/check.sh` now emits, additively, `version`, `guards_present`, and `missing_guards` when it can locate the manifest/hooks (Claude Code, running from the plugin tree), and degrades to `{"ok": true}` otherwise (the cross-agent bundle, where hooks do not exist, or when `jq` is absent). `ok` semantics are unchanged. The `check-deps` SKILL.md documents the fields and an **Activation probe** subsection; the `/drive` SKILL.md and `/ticket` command pre-checks surface `version` and warn (non-blocking) on a non-empty `missing_guards`.

Verified:

- Real plugin tree → `{"ok": true, "version": "1.0.68", "guards_present": true, "missing_guards": []}`.
- Fabricated root with a guard removed from `hooks.json` → `guards_present: false`, `missing_guards: ["guard-git-branch.sh"]`.
- No manifest (bundle) → `{"ok": true}`.
- 232/232 smoke tests pass (5 new `check-deps` assertions); `posix-lint` conforming; `build.mjs` + `verify.mjs` ("all built skills self-contained") + `validate-metadata.mjs` green; `outputs/` rebuilt and the bundled `check.sh` is byte-identical to source (`cmp` exit 0).

### Discovered Insights

- **Insight**: The build's self-containment verifier scans script **comment text**, not just executable lines: a literal `${CLAUDE_PLUGIN_ROOT}` token and even a literal `skills/<x>/scripts/` path inside a comment are both flagged (the former as an unresolved reference, the latter as a non-build-detectable cross-skill ref). A bundled script must keep such path/token forms out of its comments entirely.
  **Context**: `scripts/build-plugins/verify.mjs` greps the raw file bytes for these patterns to prove the generated bundle is self-contained, so prose explaining *why* a path form is avoided must paraphrase rather than quote it.
- **Insight**: A script that needs the plugin root but must stay identical between source and the generated bundle should derive the root from `$0`/`dirname` (its own location), not from the plugin-root path expansion — the latter is rewritten by the build and diverges between trees.
  **Context**: `check.sh` is copied into the `drive` skill's `outputs/` closure; deriving the root from its own path is what lets the same bytes work in both the plugin tree and the bundle (degrading cleanly in the bundle, where no manifest exists).
