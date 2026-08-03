#!/bin/sh -eu
# Resolve which repository a routine question is about. Pure read, no API call.
#
#   resolve-repo-url.sh [name-or-url]
#
# Output (one JSON line):
#   {"repo","repo_name","source":"current_checkout"|"same_org_as_checkout"|"given_url"[,"note"]}
#   {"error":"no_remote"}
#
# A bare NAME resolves inside the current checkout's own organisation — `workaholic` from
# a checkout of `qmu/workaholic` means `qmu/workaholic`, and `qfs` means `qmu/qfs`. That
# is a guess, and it says so in `source`, because a routine survey that silently answered
# about the wrong organisation's repository would be worse than one that could not answer.
# A full URL is taken verbatim; nothing here contacts the network to verify either.

set -eu

ARG="${1:-}"

clean() { printf '%s' "$1" | sed -e 's#/$##' -e 's#\.git$##'; }

emit() {
  printf '{"repo": "%s", "repo_name": "%s", "source": "%s"}\n' \
    "$1" "$(printf '%s' "$1" | sed -e 's#.*/##')" "$2"
}

case "$ARG" in
  *://*|git@*)
    emit "$(clean "$ARG")" given_url
    exit 0
    ;;
esac

# The remote is read directly rather than through `gather/git-context.sh`, which refuses
# to answer at all when no remote-tracking ref exists to derive a base branch from. That
# refusal is right for a workflow that is about to diff against a base; a question about
# which repository's routines to list has nothing to do with a base branch, and a fresh
# clone that has not fetched must still be able to ask it.
CURRENT=$(git remote get-url origin 2>/dev/null || true)
[ -n "$CURRENT" ] || { echo '{"error": "no_remote"}'; exit 1; }
CURRENT=$(clean "$CURRENT")

if [ -z "$ARG" ]; then
  emit "$CURRENT" current_checkout
  exit 0
fi

# A bare name: keep the checkout's host and org, swap the last segment.
emit "$(printf '%s' "$CURRENT" | sed -e "s#[^/]*\$#${ARG}#")" same_org_as_checkout
