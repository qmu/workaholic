#!/bin/sh -eu
# Shared commit-subject policy validator -- the SINGLE source of the subject
# rules. It lives in the commit skill (next to commit.sh, which must run it
# before staging anything) so the outputs/workflows bundle -- which copies
# whole skill scripts/ dirs but never hooks/ -- stays self-contained and
# carries the gate too. The hook layers (the PreToolUse Bash gate
# guard-git-commit.sh and the git-native commit-msg hook) reach these same
# rules through the hooks/lib/check-subject.sh delegator, so all three
# enforcement points share one rule source and cannot drift.
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
#   - 50 characters or fewer

set -eu

# The locale pin must precede any counting: `wc -m` counts characters only
# under a multibyte-aware locale -- in the C locale (glibc's default when
# nothing is set) it counts bytes, so a Japanese subject would measure ~3x
# longer on one host than another. Pin LC_ALL to the first UTF-8 locale the
# host actually provides. Where none is listed (musl decodes UTF-8 regardless
# of locale, and ships no `locale -a`) the environment is left untouched and
# the count is correct anyway.
for utf8_locale in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
  if locale -a 2>/dev/null | grep -qixF -- "$utf8_locale"; then
    LC_ALL="$utf8_locale"
    export LC_ALL
    break
  fi
done

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
