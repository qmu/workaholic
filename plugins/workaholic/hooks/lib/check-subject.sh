#!/bin/sh -eu
# Shared commit-subject policy validator -- the SINGLE source of the subject
# rules so the PreToolUse Bash gate (guard-git-commit.sh) and the git commit-msg
# hook (git/commit-msg) enforce byte-identical checks and cannot drift.
#
# Usage:
#   sh check-subject.sh "<subject>"        (subject as the first argument)
#   printf '%s' "<subject>" | sh check-subject.sh   (subject on stdin)
#
# Output: on a violation, a short reason on stdout and exit 1. On a conforming
# (or empty/uninspectable) subject, no output and exit 0.
#
# Rules (plugins/workaholic/skills/commit/SKILL.md):
#   - no Conventional-Commit prefix (feat:/fix(scope):/docs!: ...)
#   - no leading [bracket] tag
#   - 50 characters or fewer (wc -m counts characters, so a multibyte subject is
#     measured by character count, not byte length)

set -eu

if [ "$#" -gt 0 ]; then
  subject="$1"
else
  subject=$(cat)
fi

# Only the first line is the subject.
subject=$(printf '%s\n' "$subject" | sed -n '1p')

# An empty subject is git's problem, not a policy violation.
[ -z "$subject" ] && exit 0

if printf '%s' "$subject" | grep -qE '^[A-Za-z][A-Za-z0-9_-]*(\([^)]*\))?!?:[[:space:]]'; then
  echo "Conventional-Commit prefix"
  exit 1
fi

if printf '%s' "$subject" | grep -qE '^\[[^]]+\]'; then
  echo "leading [bracket] tag"
  exit 1
fi

len=$(printf '%s' "$subject" | wc -m | tr -d '[:space:]')
if [ "$len" -gt 50 ]; then
  echo "subject is ${len} characters (limit 50)"
  exit 1
fi

exit 0
