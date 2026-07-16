#!/bin/sh -eu
# PreToolUse(Bash) guard: blocks a direct `git commit` whose inline subject
# violates the Workaholic commit-message policy, and routes the caller to the
# sanctioned path (/commit or commit.sh).
#
# Why this exists: the subject rule (present-tense, <=50 chars, no
# Conventional-Commit prefix, no [bracket] tag) lives only as prose in
# skills/commit/SKILL.md and is produced only by commit.sh. Nothing rejected a
# violation, so any session that free-handed `git commit` mirrored the noisy
# surrounding history (feat:/docs:/chore: prefixes). This converts the written
# convention into an automated rejection gate for the agent/harness Bash surface.
#
# Scope (deliberately narrow, per least-privilege): this blocks ONLY an
# inspectable, off-policy `-m`/`-am` subject. A conformant subject, an editor
# commit, and `-F file`/heredoc messages (whose subject cannot be read from the
# command string) all pass — the gate obstructs the violation, not the act of
# committing. Co-Authored-By trailers are explicitly allowed.
#
# Mirrors guard-ticket-structure.sh: read .tool_input.command from stdin JSON,
# match conservatively, exit 2 to block (feeds the message back), 0 to allow.

set -eu

# Shared subject validator (lib/check-subject.sh, a stable delegator to the
# canonical skills/commit/scripts/check-subject.sh) -- the single source of
# the subject rules, also used by the git commit-msg hook and by commit.sh
# itself so the layers cannot drift. Resolve it relative to this hook's own
# directory.
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LIB="${SCRIPT_DIR}/lib/check-subject.sh"

block() {
  echo "Error: refusing off-policy commit subject ($1)." >&2
  echo "  Subject: \"$2\"" >&2
  echo "" >&2
  echo "Subject policy (plugins/workaholic/skills/commit/SKILL.md):" >&2
  echo "  - present-tense, 50 characters or fewer" >&2
  echo "  - no Conventional-Commit prefix (feat:/fix:/docs:/chore: ...)" >&2
  echo "  - no leading [bracket] tag" >&2
  echo "" >&2
  echo 'Use the sanctioned path instead:' >&2
  echo '  /commit' >&2
  echo '  sh ${CLAUDE_PLUGIN_ROOT}/skills/commit/scripts/commit.sh "<title>" "<why>" "<changes>" "<concerns>" "<insights>" "<verify>"' >&2
  exit 2
}

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Fail-open on anything that is not plausibly a git commit.
[ -z "$cmd" ] && exit 0
case "$cmd" in
  *git*commit*) : ;;
  *) exit 0 ;;
esac

# Confirm `commit` is really the git subcommand (a standalone word), so
# `commit.sh`, `git commit-graph`, and `git commit-tree` are not matched.
printf '%s' "$cmd" | grep -qE '(^|[^[:alnum:]_./-])git([[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' || exit 0

# Extract the first inline -m/-am subject (double- or single-quoted). The
# leading [^"'] anchor stops the match at the first quoted region so the FIRST
# message (the subject) is captured, not a later -m body paragraph.
subject=$(printf '%s' "$cmd" | sed -nE "s/^[^\"']*-[A-Za-z]*m[[:space:]]+\"([^\"]*)\".*/\1/p")
if [ -z "$subject" ]; then
  subject=$(printf '%s' "$cmd" | sed -nE "s/^[^\"']*-[A-Za-z]*m[[:space:]]+'([^']*)'.*/\1/p")
fi

# No inspectable inline subject (editor commit, -F file, heredoc) -> allow.
[ -z "$subject" ] && exit 0

# Delegate the subject checks to the shared validator. A conforming subject ->
# lib exits 0 -> allow; a violation -> lib prints the reason and exits non-zero.
# The `if` keeps `set -e` from tripping on the expected non-zero exit.
if reason=$(printf '%s\n' "$subject" | sh "$LIB"); then
  exit 0
fi

block "$reason" "$subject"
