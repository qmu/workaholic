#!/bin/sh -eu
# PreToolUse(Bash) working-directory guard for the workaholify ground rule: keep the
# persistent working directory at the repository root. A top-level `cd` that moves the
# cwd is detected; a ( ... ) subshell, an absolute-path command, and a tool prefix
# (npm --prefix <dir>, ...) do NOT move the persistent cwd, so they are not flagged.
#
# Single enforced mode — no env-var toggle. A matched top-level `cd` is DENIED
# (PreToolUse permissionDecision "deny") whose reason names the offending command and
# the sanctioned alternatives. Enforcement is unconditional in the plugin code, so
# "plugin installed = guard active": zero per-machine/per-shell prerequisite, identical
# on every machine and fresh clone. There is no injectable opt-out, by design — an
# env-var switch fails open exactly when it is not set (a fresh clone, another machine,
# a differently-launched session, a forgotten export), which is precisely when the
# guard is needed, and an advisory reminder is text an LLM agent ignores.
#
# The MATCH SET is unchanged from the former advisory design: a ( cd <dir> && ... )
# subshell, an absolute-path command, and a tool prefix (npm --prefix <dir>) still pass
# silently, so correct usage is never blocked.
#
# Mirrors guard-git-commit.sh: read .tool_input.command from stdin JSON. Fails open
# (exit 0) when jq is unavailable, so a guard error never blocks unrelated Bash. This
# is an availability safeguard, not an opt-out — no cwd relaxation rides on it.

set -eu

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# A whole-command ( ... ) subshell does not change the persistent cwd -> allow silently.
case "$cmd" in
  \(*) exit 0 ;;
esac

# Flag only a leading `cd ` or a top-level chained `cd` (&&/;/||), which move the
# persistent working directory. Anything else (including absolute-path commands, a
# tool prefix like --prefix, and subshell cd) passes silently.
case "$cmd" in
  "cd "*|*"&& cd "*|*"&&cd "*|*"; cd "*|*";cd "*|*"|| cd "*) : ;;
  *) exit 0 ;;
esac

# Matched a top-level cd. Deny it, unconditionally.
reason="workaholify ground rule: keep the working directory at the repository root. This command moves the persistent cwd: ${cmd} — run it without moving the top-level cwd instead: a ( cd <dir> && ... ) subshell, an absolute path, or a tool prefix (e.g. npm --prefix <dir>)."
printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": %s}}\n' \
  "$(printf '%s' "$reason" | jq -Rs .)"
exit 0
