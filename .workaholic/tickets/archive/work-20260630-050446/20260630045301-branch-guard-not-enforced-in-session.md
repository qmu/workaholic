---
created_at: 2026-06-30T04:53:01+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.5h
commit_hash: ef23890
category: Changed
depends_on:
---

# PreToolUse branch/commit guards don't actually fire in live sessions

## Overview

`hooks/guard-git-branch.sh` is a PreToolUse(Bash) gate meant to block creation of any branch whose name is not `work-YYYYMMDD-HHMMSS`, routing the caller to `skills/branching/scripts/create.sh`. It is registered in `hooks/hooks.json` alongside `guard-git-commit.sh` and `guard-ticket-structure.sh`. The hook logic is correct, but it **did not run** in a live Claude Code session, so an agent free-handed an off-convention branch and nothing stopped it.

Repro from the qmu-co-jp session (2026-06-30): the agent ran `git checkout -b chore-deployment-contract` and it succeeded — the branch was created, pushed, and PR-opened before the violation was noticed and manually unwound (redone as `work-20260630-044229` via `create.sh`).

The guard itself is not the problem. Tested standalone it behaves exactly as intended:

- `printf '{"tool_input":{"command":"... git checkout -b chore-deployment-contract ..."}}' | sh hooks/guard-git-branch.sh` → prints the refusal and exits `2` (block).
- Same with `git checkout -b work-20260630-044229` → exits `0` (allow).
- `jq` (the hook's only external dep) is present at `/usr/bin/jq`.

So the gap is **activation/wiring**, not the script: the plugin's PreToolUse Bash hooks in `hooks/hooks.json` are not taking effect in sessions where the plugin is loaded from the dev path (`/home/ec2-user/projects/workaholic/plugins/workaholic`). The `UserPromptSubmit` policy-lens hook is referenced by the workflow commands, but there is no evidence the PreToolUse guards (branch/commit/ticket-structure) execute in-session. The same gap means `guard-git-commit.sh` (off-policy commit subjects) is likely also inert.

**Narrowing clue (same session):** in the very session that wrote this ticket, the **PostToolUse(Write)** hook `validate-ticket.sh` DID fire and block (it rejected a `type: bug` frontmatter value), while the **PreToolUse(Bash)** `guard-git-branch.sh` did NOT fire on the `git checkout -b chore-deployment-contract` call. Both are registered in the same `hooks/hooks.json`, so plugin hooks are loading in general — the failure is specific to the **PreToolUse `Bash` matcher entry** (or how PreToolUse-on-Bash is registered/allowed), not to plugin hooks as a whole. Start the diagnosis there: compare why the `PostToolUse` `Write|Edit` matcher takes effect but the `PreToolUse` `Bash` matcher does not.

Goal: make the registered PreToolUse Bash guards actually run and block in live sessions, so the branch-naming and commit-subject conventions are enforced by the harness rather than relying on agent memory.

**Out of scope (explicitly rejected):** the native git-hook layer (`install-git-hooks.sh` / `core.hooksPath` / `.git/hooks`). Do not solve this by installing git-level hooks. The fix must make the plugin's *Claude Code PreToolUse* hooks effective.

## Key Files

- `hooks/hooks.json` — registers the three PreToolUse(Bash) hooks + PostToolUse + UserPromptSubmit. Confirm this is the schema/shape Claude Code actually loads for a plugin, and that nothing about its structure makes the PreToolUse block silently ignored.
- `hooks/guard-git-branch.sh` — the (correct) branch-creation gate. No change expected unless diagnosis points here.
- `hooks/guard-git-commit.sh` — parallel commit-subject gate; same activation gap likely applies.
- `.claude-plugin/plugin.json` — plugin manifest (`name: workaholic`, v1.0.68). Check whether hooks need an explicit reference here or a particular install/enable step for hooks (vs skills/commands, which clearly load).
- How the plugin is enabled in a consumer repo / user settings — determine why skills+commands+UserPromptSubmit load but PreToolUse Bash guards do not. The wiring that enables the plugin's hooks is the thing to fix or document.

## Implementation Steps

1. Reproduce: in a session with the plugin loaded, attempt `git checkout -b some-bad-name` and confirm whether the PreToolUse guard fires. Capture the effective hook configuration the harness sees (e.g. `/hooks` view or settings dump) to confirm whether the workaholic PreToolUse entries are present at all.
2. Diagnose the activation gap: is it (a) plugin hooks not registered when loaded via the dev path, (b) a settings/enable step the consumer repo never ran, (c) a `hooks.json` schema/matcher detail Claude Code silently drops, or (d) PreToolUse Bash hooks needing explicit allow/enable? Narrow to the actual cause with evidence.
3. Fix so the three PreToolUse Bash guards execute and block in-session — whichever of: correct `hooks.json` registration, document/automate the required enable step, or adjust how the plugin surfaces hooks. Verify `guard-git-commit.sh` is enforced by the same fix.
4. Add a regression check that the guards are active (e.g. a self-test command or a documented verification: trigger a bad branch name and observe the block) so a future silent regression is caught.
5. Verify end to end: a live session can no longer create a non-`work-*` branch or commit an off-policy subject; a `work-YYYYMMDD-HHMMSS` branch via `create.sh` still passes.

## Considerations

- The guards passing a standalone stdin test is **not** proof they are wired into sessions — that false sense of safety is exactly what failed here. The acceptance criterion is an in-session block, observed live, not a unit test of the script.
- Keep the guards least-privilege (they already let read/list/delete/rename and existing-branch checkout through); the fix is about activation, not broadening what they block.
- If activation requires a per-repo enable step, prefer making it discoverable/automatic (e.g. surfaced by `check-deps` or a session-start notice) rather than silent, since a disabled guard looks identical to an absent one.

## Final Report

**Resolution: closed as a misdiagnosis — no code change. The PreToolUse Bash guards are not broken; they fire and block correctly. The qmu-co-jp incident was a stale plugin install, not an activation gap.**

Reproduced live in a session loaded from the dev path (`--plugin-dir .../plugins/workaholic`, v1.0.68). All three off-policy branch-creation forms were blocked by `guard-git-branch.sh` at the PreToolUse(Bash) stage:

- `git branch zzz-guard-probe` → blocked (exit 2)
- `git checkout -b chore-probe-test` → blocked
- `git switch -c chore-probe-test2` → blocked

So the ticket's stated premise — "the plugin's PreToolUse Bash hooks are not taking effect in sessions where the plugin is loaded from the dev path" — does not hold. The PreToolUse `Bash` matcher works.

### Root cause (the real one)

The reported asymmetry — PostToolUse `validate-ticket.sh` fired while PreToolUse `guard-git-branch.sh` did not — is a **version** artifact, not a matcher defect:

- `guard-git-branch.sh` (and `guard-git-commit.sh`) were **introduced in v1.0.66** (commit `24a3096`, "Gate off-policy commits and branches via Bash hooks").
- `validate-ticket.sh` was added far earlier (commit `a8aee9e`).
- The qmu-co-jp session ran a workaholic install **older than v1.0.66**, whose `hooks.json` contained the PostToolUse validator but **no branch guard at all** — it had not been written yet. An absent hook cannot fire.

This machine's cached installs corroborate it: every cached/marketplace copy is pre-1.0.66 (`workaholic@1.0.64`, plus obsolete-name `work@1.0.51`, `standards@1.0.51`, `drivin@1.0.38`, `core@1.0.37`). This is exactly the "stale marketplace copy runs obsolete logic" trap CLAUDE.md warns against — a session running a stale install sees an *absent* guard, which is indistinguishable from a *broken* one. That indistinguishability is what produced the misdiagnosis.

### Discovered Insights

- **Insight**: A stale plugin install presents as a "hook that doesn't fire," because the loaded `hooks.json` simply lacks the newer hook. There is no code fix that makes an absent hook appear — the only durable mitigation is to surface the **loaded plugin version** so staleness is visible (Considerations bullet 3 / Step 4). Deferred here by developer decision; left for a future ticket if recurrence warrants.
  **Context**: Whenever a workaholic hook "isn't firing," check the loaded plugin version against the commit that introduced the hook *before* suspecting the matcher or wiring.
- **Insight**: `guard-git-branch.sh` over-blocks a piped list form: `git branch | grep ...` is rejected because the whitespace tokenizer treats the pipe `|` as a bare branch name to validate. The read/list form should pass. Out of scope for this ticket (which is activation, not block-surface), but worth a dedicated fix.
  **Context**: The guard tokenizes with `set -- $cmd` and has no notion of shell metacharacters, so any `git branch`-prefixed pipeline trips the bare-name path.
