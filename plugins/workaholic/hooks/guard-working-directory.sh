#!/bin/sh -eu
# PreToolUse(Bash) advisory (NON-blocking): the workaholify ground rule is to keep
# the working directory at the repository root. A top-level `cd` that moves the
# persistent cwd is flagged with a steer toward an absolute path or a
# ( cd <dir> && ... ) subshell — but the command is never blocked, so a deliberate
# one-off `cd` still runs. A ( ... ) subshell does not change the persistent cwd,
# so it is not flagged.
#
# Mirrors guard-git-commit.sh: read .tool_input.command from stdin JSON. Unlike the
# blocking git gates, this always exits 0 and, when it has something to say, emits
# a PreToolUse additionalContext reminder for the model. Fails open.

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
# persistent working directory. Anything else (including absolute-path commands and
# subshell cd) passes silently.
case "$cmd" in
  "cd "*|*"&& cd "*|*"&&cd "*|*"; cd "*|*";cd "*|*"|| cd "*) : ;;
  *) exit 0 ;;
esac

msg='workaholify ground rule: keep the working directory at the repository root. This command moves the persistent cwd — prefer an absolute path or a ( cd <dir> && ... ) subshell, and if you must cd, return to the repo root immediately after. (This is an advisory reminder; the command was not blocked.)'

printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": %s}}\n' \
  "$(printf '%s' "$msg" | jq -Rs .)"
exit 0
