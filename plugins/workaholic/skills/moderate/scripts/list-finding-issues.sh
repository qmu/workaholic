#!/bin/sh -eu
# list-finding-issues.sh — the FINDING ISSUES this loop has already filed: the brake's half and
# the dedup's half, out of one read of one ledger.
#
# Usage: list-finding-issues.sh
# Output: {"ok": true, "slug": "<owner/name>", "any_open": true|false,
#          "open": [{"number": N, "url": "...", "step": "...", "finding_id": "..."}],
#          "filed": [{"number": N, "url": "...", "step": "...", "finding_id": "...", "state": "..."}],
#          "filed_ids": ["<finding id>", ...],
#          "scanned": N, "limit": N, "list_capped": true|false}
#      or {"ok": false, "reason": "...", "detail": "..."} — exit 0 either way.
#   PURE READ: it writes nothing and creates nothing.
#
# ═══ A NEW SCRIPT, NOT A MODE OF `list-open-proposals.sh` ════════════════════════════
# Reported rather than assumed, because a third near-copy of one lookup is how three drift
# (`lib/claims.sh`'s live-row rule records exactly that failure). What is shared with the
# proposal brake and with `list-open-rulings.sh` is the SHAPE — a visible marker, read off
# GitHub, no cursor, `ok: false` refusing the whole act. What is NOT shared is the MARKER:
# `list-open-proposals.sh` is keyed on `strategy: … / move: …`, and a finding issue is not a
# proposal. One brake holding two unrelated flows is worse than two brakes.
#
# ═══ ONE READER FOR BOTH HALVES, FOR THE SAME REASON ═════════════════════════════════
# The brake asks *is one open?* and the dedup asks *which findings are already filed?* — two
# questions about ONE ledger, and two readers of one ledger drift. So this reads once and
# answers both: `any_open`/`open` for the brake, `filed_ids` for the dedup.
#
# ═══ A BRAKE THAT CANNOT BE READ IS NOT A BRAKE ══════════════════════════════════════
# `ok: false` is a refusal of the whole act and never a permissive default — the proposal
# brake's rule, one artifact over. The caller files NOTHING on it, and names that reason
# distinctly from `any_open`, because *one is already in flight* and *I could not look* are
# different facts about the loop.
#
# ═══ THE MARKER IS VISIBLE, NOT AN HTML COMMENT ══════════════════════════════════════
# `file-inbound-ask.sh` — still the one writer of a marker — puts one
# `finding: <step id> / id: <finding id>` line in the body. A hidden marker would be a fact
# the loop depends on that no human reading the issue can see, and the one thing this loop
# must never become is a machine conversation a person cannot follow. It rides the BODY, not
# the title, so it survives a person retitling the issue.
#
# ═══ THE BOUND IS THE LISTING, NOT A DATE ════════════════════════════════════════════
# `state=all` so a finding stays deduped after its repair merged and auto-closed the issue —
# the whole point of the dedup half. The window is the most recent `WORKAHOLIC_FINDING_ISSUE_LIMIT`
# issues (default 100, newest first), which is `list-swept-slack-refs.sh`'s own bound and its
# own reason: no date arithmetic, because `date -d` is GNU-only and `date -v` BSD-only and a
# reader that answers differently on a laptop and in a container is worse than one bounded by
# a number both can read. `list_capped` says when the page bound rather than the repository
# ended the read, so a truncated answer is never mistaken for a complete one.
#
# REST, NOT `gh issue list` (`rules/shell.md`): the subcommand is GraphQL-backed and a Claude
# Code Web session may 403 mid-run. The list endpoint returns pull requests alongside issues;
# rows carrying `.pull_request` are dropped, or the loop would read its own pull requests as
# findings.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"

LIMIT="${WORKAHOLIC_FINDING_ISSUE_LIMIT:-100}"
case "$LIMIT" in
  ''|*[!0-9]*) LIMIT=100 ;;
esac
[ "$LIMIT" -gt 0 ] || LIMIT=100

emit_err() {
  detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
  printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
  exit 0
}

command -v gh >/dev/null 2>&1 || emit_err "gh_unavailable" "gh is not on PATH"
command -v jq >/dev/null 2>&1 || emit_err "jq_unavailable" "jq is not on PATH"

slug="$(sh "$GH_REST" slug 2>&1)" || emit_err "slug_unresolved" "$slug"
[ -n "$slug" ] || emit_err "slug_unresolved" "gh-rest.sh slug returned empty"

rows="$(sh "$GH_REST" api \
  "repos/${slug}/issues?state=all&per_page=${LIMIT}" \
  --jq 'map(select(.pull_request | not))
        | map({number, url: .html_url, state,
               marker: ((.body // "") | split("\n")
                        | map(select(startswith("finding: "))) | first // "")})
        | map(select(.marker != ""))
        | .[] | [(.number|tostring), .state, .url, .marker] | @tsv' 2>&1)" \
  || emit_err "list_failed" "$rows"

scanned="$(sh "$GH_REST" api \
  "repos/${slug}/issues?state=all&per_page=${LIMIT}" \
  --jq 'map(select(.pull_request | not)) | length' 2>/dev/null || printf '0')"
case "$scanned" in ''|*[!0-9]*) scanned=0 ;; esac
capped=false
[ "$scanned" -ge "$LIMIT" ] && capped=true

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' -e 's/\r//g'
}

TAB="$(printf '\t')"
open_rows=""
filed_rows=""
ids=""
while IFS="$TAB" read -r number state url marker; do
  [ -n "$number" ] || continue
  step=$(printf '%s' "$marker" | sed -n 's|^finding: *\([a-z-]\{1,\}\) */ *id: *\(.*\)$|\1|p')
  fid=$(printf '%s' "$marker" | sed -n 's|^finding: *\([a-z-]\{1,\}\) */ *id: *\(.*\)$|\2|p')
  [ -n "$fid" ] || continue
  ids="${ids}${fid}
"
  row="{\"number\": ${number}, \"url\": \"$(json_escape "$url")\", \"step\": \"$(json_escape "$step")\", \"finding_id\": \"$(json_escape "$fid")\""
  # `filed` carries every finding issue with its state; `open` is the subset the brake and the
  # suppression read. Both come out of one walk, because *has this been filed* and *is it in
  # flight* are two questions about one ledger and two walks would drift.
  filed_rows="${filed_rows:+${filed_rows}, }${row}, \"state\": \"$(json_escape "$state")\"}"
  if [ "$state" = "open" ]; then
    open_rows="${open_rows:+${open_rows}, }${row}}"
  fi
done <<EOF
$rows
EOF

json_ids="$(printf '%s' "$ids" | sed '/^$/d' | sort -u \
  | while IFS= read -r r; do printf '"%s",' "$(json_escape "$r")"; done \
  | sed 's/,$//')"

any_open=false
[ -n "$open_rows" ] && any_open=true

printf '{"ok": true, "slug": "%s", "any_open": %s, "open": [%s], "filed": [%s], "filed_ids": [%s], "scanned": %s, "limit": %s, "list_capped": %s}\n' \
  "$(json_escape "$slug")" "$any_open" "$open_rows" "$filed_rows" "$json_ids" "$scanned" "$LIMIT" "$capped"
