#!/bin/sh -eu
# list-open-rulings.sh — the RULING PULL REQUESTS this loop has already opened and that the
# operator has not yet ruled on.
#
# Usage: list-open-rulings.sh
# Output: {"ok": true, "slug": "<owner/name>",
#          "rulings": [{"number": N, "url": "...", "title": "...",
#                       "subjects": [{"kind": "...", "subject": "..."}]}]}
#      or {"ok": false, "reason": "...", "detail": "..."} — exit 0 either way.
#
# ═══ IT IS A BRAKE, AND A BRAKE THAT CANNOT BE READ IS NOT A BRAKE ═══════════════════
# `list-open-proposals.sh`'s shape and its rule, one artifact over: a caller that cannot list
# what it already has in flight must draft NOTHING rather than draft blind. Handing the
# operator two competing diffs about the same subjects is the failure this exists to prevent,
# so `ok: false` is a refusal of the whole act and never a permissive default.
#
# ═══ NO CURSOR AND NO STORED STATE ═══════════════════════════════════════════════════
# The two states hand off with no window between them: from the moment a ruling pull request
# opens until the operator merges or closes it, it is OPEN and this gate holds; the moment
# they merge it, the subject leaves `list-standing-rulings.sh`'s candidate set, because it is
# no longer unattributed or uncovered. So *one open ruling at a time* is enforced continuously
# with nothing stored anywhere — the same property the proposal brake has.
#
# ═══ THE MARKER IS VISIBLE, NOT AN HTML COMMENT ══════════════════════════════════════
# `draft-standing-rulings.sh` writes one `ruling: <kind> / subject: <subject>` line per drafted
# subject into the pull-request body, in the same shape `/propose` puts `strategy: … / move: …`
# on an issue. A hidden marker would be a fact the loop depends on that no human reading the
# pull request can see, and the one thing this loop must never become is a machine
# conversation a person cannot follow.
#
# THE TITLE DECIDES MEMBERSHIP, THE MARKER DECIDES SUBJECTS. A pull request the operator
# edited, retitled by hand, or opened themselves is still theirs to rule on; keying membership
# on the `[Ruling] ` prefix the drafter sets keeps the gate readable by a person.
#
# REST, NOT `gh pr list` (`rules/shell.md`): the subcommand is GraphQL-backed and a Claude
# Code Web session may 403 mid-run.

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
command -v jq >/dev/null 2>&1 || emit_err "jq_unavailable" "jq is not on PATH"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

LIMIT="${WORKAHOLIC_RULING_PR_LIMIT:-50}"
case "$LIMIT" in
  ''|*[!0-9]*) LIMIT=50 ;;
esac

repo_slug="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>&1)" || emit_err "list_failed" "$repo_slug"

rows="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
  "repos/${repo_slug}/pulls?state=open&per_page=${LIMIT}" \
  --jq '.[] | select(.title | startswith("[Ruling] "))
        | [(.number|tostring), .html_url, .title,
           ((.body // "") | split("\n") | map(select(test("^ruling: "))) | join(";"))] | @tsv' 2>&1)" \
  || emit_err "list_failed" "$rows"

TAB="$(printf '\t')"
rulings=""
while IFS="$TAB" read -r number url title markers; do
  [ -n "$number" ] || continue
  subjects=""
  old_ifs="$IFS"; IFS=';'
  for m in $markers; do
    kind=$(printf '%s' "$m" | sed -n 's|^ruling: *\([a-z_]*\) */ *subject: *\(.*\)$|\1|p')
    subj=$(printf '%s' "$m" | sed -n 's|^ruling: *\([a-z_]*\) */ *subject: *\(.*\)$|\2|p')
    [ -n "$subj" ] || continue
    subjects="${subjects:+${subjects}, }{\"kind\": \"$(json_escape "$kind")\", \"subject\": \"$(json_escape "$subj")\"}"
  done
  IFS="$old_ifs"
  rulings="${rulings:+${rulings}, }{\"number\": ${number}, \"url\": \"$(json_escape "$url")\", \"title\": \"$(json_escape "$title")\", \"subjects\": [${subjects}]}"
done <<EOF
$rows
EOF

printf '{"ok": true, "slug": "%s", "rulings": [%s]}\n' "$(json_escape "$repo_slug")" "$rulings"
