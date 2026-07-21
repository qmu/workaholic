#!/bin/sh -eu
# PreToolUse(Bash) working-directory guard for the workaholify ground rule: keep the
# persistent working directory at the repository root. A top-level `cd` that moves the
# cwd is detected; a ( ... ) subshell, an absolute-path command, and a tool prefix
# (npm --prefix <dir>, ...) do NOT move the persistent cwd, so they are not flagged.
#
# Two modes, selected by the WORKAHOLIC_ENFORCE_CWD switch — the ACTION on a match is
# configurable, the match set is not:
#   - unset / empty (DEFAULT): ADVISORY. Emit a PreToolUse additionalContext reminder
#     and exit 0. The command is never blocked, so a deliberate one-off `cd` still runs
#     — the original, intentional design.
#   - non-empty (opt-in): ENFORCE. Emit a PreToolUse permissionDecision "deny" whose
#     reason names the offending command and the sanctioned alternatives, so a stricter
#     operator gets a hard backstop instead of a reminder the model can ignore.
#
# Mirrors guard-git-commit.sh: read .tool_input.command from stdin JSON. Fails open
# (exit 0) when jq is unavailable, so a guard error never blocks unrelated Bash.

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

# Matched a top-level cd. Enforce (block) when the switch is set; otherwise advise.
if [ -n "${WORKAHOLIC_ENFORCE_CWD:-}" ]; then
  reason="workaholify ground rule (enforced): keep the working directory at the repository root. This command moves the persistent cwd: ${cmd} — run it without moving the top-level cwd instead: a ( cd <dir> && ... ) subshell, an absolute path, or a tool prefix (e.g. npm --prefix <dir>). Blocked by WORKAHOLIC_ENFORCE_CWD; unset it to return to advisory mode."
  printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": %s}}\n' \
    "$(printf '%s' "$reason" | jq -Rs .)"
  exit 0
fi

msg='workaholify ground rule: keep the working directory at the repository root. This command moves the persistent cwd — prefer an absolute path or a ( cd <dir> && ... ) subshell, and if you must cd, return to the repo root immediately after. (This is an advisory reminder; the command was not blocked.)'

printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": %s}}\n' \
  "$(printf '%s' "$msg" | jq -Rs .)"
exit 0
