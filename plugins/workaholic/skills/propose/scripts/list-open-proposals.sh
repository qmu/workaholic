#!/bin/sh -eu
# list-open-proposals.sh — the OPEN proposals this loop has already opened, per strategy.
#
# Usage: list-open-proposals.sh
# Output: {"ok": true, "identity": "<login>", "slug": "<owner/name>",
#          "proposals": [{"number": N, "url": "...", "strategy": "<slug>",
#                         "move": "depth|breadth|contraction", "title": "..."}]}
#      or {"ok": false, "reason": "...", "detail": "..."} — exit 0 either way.
#
# THIS IS ONE HALF OF THE BRAKE, and it is the half that has to be read over the network,
# so its failure mode is the one that matters. `/propose` deliberately drops the
# repository's standing *when unsure, record only* bar (`workaholic:specificate`, *The
# judgment bar*) — it is the first unattended routine to do so — and what replaces the bar
# is a set of MECHANICAL gates, not a softer judgment. A gate that cannot be read is not a
# gate, so a caller that cannot list its own open proposals must propose NOTHING rather
# than propose blind: `ok: false` is a refusal of the whole tick, never a permissive
# default. That asymmetry is the entire reason this is a separate script from the local
# survey — the local half cannot fail, the remote half can, and mixing them would hide
# which one went quiet.
#
# WHY OPEN ISSUES ARE ENOUGH, and no date arithmetic is needed. The two gates hand off
# with no window between them:
#
#   * From the moment this script opens an issue until `[Specificate]` ingests it and its
#     pull request merges, the issue is OPEN and this gate holds.
#   * From that merge onward the tickets it produced are QUEUED, so the survey's
#     `waiting_count` gate holds instead (`survey-strategies.sh`).
#
# So "one proposal per strategy in flight at a time" is enforced continuously without a
# cursor, a stored timestamp or a per-day bound. A per-day bound was considered and
# REFUSED: the ask is explicitly for three routines turning an HOURLY loop, and a daily
# cap on the only routine that originates work would cap the loop itself at one turn a day.
# The `deploy-day:` bound it would have been copied from answers a different question — an
# unchanging status restated hourly — and this is not a status.
#
# REST, NOT `gh issue list` (`rules/shell.md`): the subcommand is GraphQL-backed and a
# Claude Code Web session may serve only the pinned pull-request set. The list endpoint
# returns pull requests alongside issues; rows carrying `.pull_request` are dropped, or a
# routine would read its own pull requests as proposals.
#
# THE MARKER IS VISIBLE, NOT AN HTML COMMENT. The second line of every proposal body is
# `strategy: <slug> / move: <move>`, in the same shape `/fb` already puts `kind: … /
# source: … / subject: …` on its first line. A hidden marker would be a fact the loop
# depends on that no human reading the issue can see, and the one thing this loop must
# never become is a machine conversation a person cannot follow.

set -eu

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' -e 's/\r//g'
}

emit_err() {
  detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
  printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
  exit 0
}

command -v gh >/dev/null 2>&1 || emit_err "gh_unavailable" "gh is not on PATH"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"

LIMIT="${WORKAHOLIC_PROPOSE_ISSUE_LIMIT:-50}"
case "$LIMIT" in
  ''|*[!0-9]*) LIMIT=50 ;;
esac

login="$(gh api user --jq .login 2>&1)" || emit_err "identity_unresolved" "$login"
[ -n "$login" ] || emit_err "identity_unresolved" "gh api user returned an empty login"

repo_slug="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>&1)" || emit_err "list_failed" "$repo_slug"

# Every open issue, not only this identity's: an operator may have opened, edited or
# reassigned a proposal by hand, and a gate that only saw its own writes would step over
# a human's. The marker decides membership, never the author.
rows="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
  "repos/${repo_slug}/issues?state=open&per_page=${LIMIT}" \
  --jq 'map(select(.pull_request | not)) | .[]
        | [(.number|tostring), .html_url, ((.body // "") | split("\n") | map(select(test("^strategy: ")))[0] // ""), .title] | @tsv' 2>&1)" \
  || emit_err "list_failed" "$rows"

TAB="$(printf '\t')"
proposals=""
while IFS="$TAB" read -r number url marker title; do
  [ -n "$number" ] || continue
  [ -n "$marker" ] || continue
  slug=$(printf '%s' "$marker" | sed -n 's|^strategy: *\([^ /]*\) */ *move: *\([A-Za-z]*\).*$|\1|p')
  move=$(printf '%s' "$marker" | sed -n 's|^strategy: *\([^ /]*\) */ *move: *\([A-Za-z]*\).*$|\2|p')
  [ -n "$slug" ] || continue
  row="{\"number\": ${number}, \"url\": \"$(json_escape "$url")\", \"strategy\": \"$(json_escape "$slug")\", \"move\": \"$(json_escape "$move")\", \"title\": \"$(json_escape "$title")\"}"
  proposals="${proposals:+${proposals}, }${row}"
done <<EOF
$rows
EOF

printf '{"ok": true, "identity": "%s", "slug": "%s", "proposals": [%s]}\n' \
  "$(json_escape "$login")" "$(json_escape "$repo_slug")" "$proposals"
