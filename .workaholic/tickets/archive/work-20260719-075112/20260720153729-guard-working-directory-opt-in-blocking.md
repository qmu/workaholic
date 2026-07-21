---
created_at: 2026-07-20T15:37:29+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash:
category: Added
depends_on:
mission:
---

# Give the working-directory guard an opt-in blocking mode so a project can enforce, not just advise

## Overview

`hooks/guard-working-directory.sh` is a `PreToolUse(Bash)` **advisory**: it parses
`.tool_input.command`, detects a leading `cd ` or a top-level chained `cd`
(`&& cd`, `; cd`, `|| cd`), and emits an `additionalContext` reminder to steer
toward an absolute path or a `( cd <dir> && … )` subshell — but it **always**
`exit 0`, so the command is never blocked. The header comment states this is
deliberate: "the command is never blocked, so a deliberate one-off `cd` still
runs."

In practice this advisory is **insufficient to hold an agent to the ground rule**.
An operator observed a long working session in which the agent, needing to run
build/test commands inside a subpackage directory, repeatedly issued top-level
`cd <subdir>` and ignored the reminder on every call — the persistent cwd drifted
away from the repository root for the rest of the session, exactly the failure the
ground rule exists to prevent (`skills/workaholify/SKILL.md` §2: "Stay at the
repository root"; `rules/general.md`: "Never use `git -C`", which presumes the cwd
*is* the repo root). Because the hook only warns, nothing in the toolchain stops
the drift; the model is the sole control, and when it slips there is no backstop.

The request is to add an **opt-in enforcement (blocking) mode** to this same hook,
so a project or operator that wants the ground rule *enforced* can get a hard
`deny` on a top-level `cd`, while the **default stays advisory** to preserve the
existing "deliberate one-off `cd` still runs" intent. The subshell / absolute-path
escape hatch the hook already recognizes (a leading `(` passes silently) remains
the sanctioned way to run a command in another directory, so correct usage is
never blocked in either mode.

**Scope decisions (developer, at ticket time):**
- Reach = one hook file (`hooks/guard-working-directory.sh`) plus its documentation
  in `skills/workaholify/SKILL.md` §2. No change to any other guard.
- The default behavior is **unchanged** (advisory `additionalContext`); enforcement
  is opt-in via a single, explicit switch (env var or settings toggle — owner's
  choice of mechanism).
- The existing detection logic (leading `cd`, top-level chained `cd`, silent pass
  for a leading `(` subshell and for absolute-path commands) is reused verbatim;
  only the *action taken on a match* becomes configurable.

## Policies

- `workaholic:implementation` / `observability` — an enforced ground rule must fail
  **loudly and legibly**: in blocking mode the `deny` reason names the offending
  `cd` and points at the sanctioned alternative (`( cd <dir> && … )` subshell,
  absolute path, or `--prefix`), so the agent can correct in one step rather than
  guessing why the call was refused.
- `workaholic:operation` — the change must be **backward-compatible**: with the
  switch unset the hook behaves exactly as today (advisory, `exit 0`), so no
  existing project's flow breaks silently by upgrading the plugin.
- `workaholic:design` — the enforcement is **opt-in, explicit, and discoverable**:
  a single documented switch, not an ambient behavior change; a reader of
  `skills/workaholify/SKILL.md` §2 can see both modes and how to select one.

## Implementation Steps

1. **`hooks/guard-working-directory.sh` — add a blocking branch.** Keep the current
   detection unchanged (leading `(` passes silently; then the `cd ` / `&& cd` /
   `; cd` / `|| cd` case). On a match, read a single enforcement switch (e.g.
   `WORKAHOLIC_ENFORCE_CWD=1`, or a settings-derived value — owner's choice) and:
   - **unset / advisory (default):** emit the existing `additionalContext`
     reminder and `exit 0` — behavior identical to today.
   - **enforce (blocking):** emit a `PreToolUse` `permissionDecision: "deny"` with a
     `permissionDecisionReason` that names the offending `cd` and the sanctioned
     alternative (subshell / absolute path / `--prefix`). Keep `jq -Rs` JSON
     encoding, as the advisory branch already does. Continue to **fail open** if
     `jq` is unavailable (`exit 0`).
2. **Document both modes in `skills/workaholify/SKILL.md` §2.** Extend the existing
   ground-rule bullets so the reader sees the hook has an advisory default and an
   opt-in blocking mode, and how to select enforcement. Keep the statement that the
   default warns rather than blocks.
3. **Verify the detection matrix by hand-running the hook** on representative
   commands: `cd packages/tech && npm test` (matched → advisory reminder unset,
   `deny` when enforced), `( cd packages/tech && npm test )` (leading `(` → silent
   pass in both modes), `npm --prefix packages/tech test` and an absolute-path
   command (no top-level `cd` → silent pass in both modes). Confirm the enforce
   switch flips only the action, never the match set.
4. **Rebuild generated artifacts if this hook/skill is built.** If
   `skills/workaholify/SKILL.md` feeds `outputs/`, run the plugin build/verify
   (`node scripts/build-plugins/build.mjs`, then `verify.mjs`,
   `validate-metadata.mjs`) and confirm the `outputs/` diff is confined to this
   change.

## Quality Gate

**Method:** hand-run the hook against the command matrix in step 3 with the switch
both unset and set; plus the plugin build/verify suite if the touched skill is
built. Approve only when every item below holds:

- With the switch **unset**, the hook is behaviorally identical to today: a matched
  top-level `cd` yields the `additionalContext` reminder and `exit 0`; nothing is
  blocked.
- With the switch **set**, a matched top-level `cd` yields a `PreToolUse`
  `permissionDecision: "deny"` whose reason names the offending `cd` and the
  sanctioned alternative; the tool call is refused.
- A leading `(` subshell (`( cd … )`), an absolute-path command, and a
  `--prefix`-style command all pass **silently in both modes** — the enforce switch
  changes only the action on a match, never the match set.
- The hook still **fails open** when `jq` is absent (`exit 0`).
- `skills/workaholify/SKILL.md` §2 documents both modes and how to select
  enforcement; the default-advisory statement remains accurate.
- If the skill is built, the plugin verify suite passes and the `outputs/` diff is
  confined to this change.

## Considerations

- **Preserve the intentional escape hatch.** The hook was made advisory on purpose
  so a deliberate one-off `cd` runs. Do not remove that — make enforcement opt-in
  and default-off, so the current design intent is the default and hard blocking is
  a choice a stricter operator makes.
- **Blocking must not strand correct usage.** The sanctioned patterns
  (`( cd <dir> && … )` subshell, absolute path, `--prefix`) already pass the
  detection silently; verify they still do under enforcement, or the blocking mode
  would punish the very patterns the ground rule recommends.
- **Fail open, not closed.** A guard that hard-denies on its own internal error
  (e.g. missing `jq`) would block unrelated Bash commands; keep the `jq`-absent and
  parse-failure paths at `exit 0`.
- **One switch, one hook.** Keep enforcement to this single guard and a single
  documented switch; do not couple it to the other `PreToolUse` guards
  (`guard-git-commit.sh`, `guard-git-branch.sh`, `guard-repo-confinement.sh`),
  which have their own blocking semantics.

## Final Report

Development completed as planned. Added `WORKAHOLIC_ENFORCE_CWD` to
`hooks/guard-working-directory.sh` (advisory default unchanged; non-empty →
`permissionDecision: "deny"` naming the offending command and the subshell /
absolute-path / `--prefix` alternatives), and documented both modes in
`skills/workaholify/SKILL.md` §2. Verified the detection matrix by hand-running
the hook: advisory when unset, deny when set, and `( cd … )` / `npm --prefix …` /
absolute-path commands pass silently in both modes.

### Discovered Insights

- **Insight**: The switch flips only the *action* on a match, never the match set —
  the `case` detection runs first and unchanged, then a single `if
  [ -n "${WORKAHOLIC_ENFORCE_CWD:-}" ]` chooses deny-JSON vs advisory-JSON.
  **Context**: This is what keeps enforce mode from punishing the very patterns the
  ground rule recommends (subshell, `--prefix`, absolute path) — they never reach
  the action branch because they never match. A future change that gates detection
  on the switch would reintroduce that risk.
- **Insight**: The hook already emitted structured JSON (`additionalContext`), so
  the block path uses the JSON `permissionDecision: "deny"` form rather than the
  `exit 2` + stderr convention the git guards use.
  **Context**: Both are valid PreToolUse block mechanisms; matching the hook's
  existing JSON shape keeps one encoding path (`jq -Rs`) and one fail-open point.
