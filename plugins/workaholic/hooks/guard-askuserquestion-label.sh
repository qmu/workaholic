#!/bin/sh -eu
# PreToolUse(AskUserQuestion) guard: blocks an AskUserQuestion whose question
# body is missing the mandatory [<project label>] prefix, so a developer running
# many parallel Claude sessions can always tell WHICH repository is asking.
#
# Why this exists: the [project]-prefix convention lives only as prose in the
# create-ticket / drive / report / ship / catch / trip-protocol / explain skills
# and their commands (deferred concerns #67 / #69: "prompt phrasing is prose, not
# machine-checked"). Nothing rejected an unlabeled prompt, so the label was
# repeatedly dropped and parallel-session prompts became unidentifiable. This
# converts the written convention into an automated rejection gate.
#
# Scope: fires on every AskUserQuestion. Labeling any prompt with its repository
# is a net good, so the over-fire onto ad-hoc questions is intentional, not a bug
# (there is no command-origin signal in tool_input to scope by, and none is
# wanted). Mirrors guard-git-commit.sh: read tool_input from stdin JSON, exit 2
# to block (the message is fed back so Claude re-issues with the prefix), 0 to
# allow. Fails open when jq is unavailable or no question bodies are present.

set -eu

# Fail open if jq is missing (never wedge the tool because a dependency is absent).
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

# Emit the body of any question that does NOT begin with a [..] label (leading
# whitespace tolerated). One offending body per line.
unlabeled=$(printf '%s' "$input" | jq -r '
  (.tool_input.questions // [])
  | .[]?.question // empty
  | select((test("^\\s*\\[") | not))
')

# All questions labeled (or none present) -> allow.
[ -z "$unlabeled" ] && exit 0

{
  echo "Error: AskUserQuestion prompt is missing the [<project label>] prefix."
  echo ""
  echo "Every question body MUST begin with the owning repository's label, e.g."
  echo "  \"[myrepo] <the actual question>\""
  echo "so a developer running several Claude sessions in parallel can tell which"
  echo "repository is asking. Get the label from its \"project\" value:"
  echo '  bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/project-label.sh'
  echo ""
  echo "Unlabeled question(s):"
  printf '%s\n' "$unlabeled" | sed 's/^/  - /'
  echo ""
  echo "Re-issue the AskUserQuestion with each question body prefixed by [<project label>]."
} >&2
exit 2
