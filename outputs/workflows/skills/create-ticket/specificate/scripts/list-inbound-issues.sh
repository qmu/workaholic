#!/bin/sh -eu
# Discover the asks a clock-fired /specificate run has in hand: the open GitHub
# issues on THIS repository assigned to the session's own identity.
#
#   list-inbound-issues.sh [feedbacks-dir]     # default: .workaholic/feedbacks
#
# Output (one JSON line, always exit 0 for a reported outcome):
#   {"ok": true, "identity": "<login>", "limit": N,
#    "issues":   [{"number", "title", "url", "updated_at"}...],   oldest first
#    "excluded": [{"number", "reason": "already_captured"}...]}
#   {"ok": false, "reason": "gh_unavailable" | "identity_unresolved" | "list_failed",
#    "detail": "..."}
#
# WHY THIS EXISTS (2026-08-12, developer's instruction). [Specificate] moved from a
# GitHub issue trigger to an hourly schedule (FB 20260810085032), and that
# migration moved only the trigger: a pure clock tick carried nothing in hand
# and reported `nothing_in_hand` every hour, while the developer's stated
# expectation was that the schedule INCLUDED discovery — sweep the repository's
# open issues assigned to me and treat each as an inbound ask. This script is
# that discovery. It is NOT the retired [Propose Batch] sweep: that read the
# repository's own backlog for something to propose; this reads the INBOUND ask
# channel — the issues people (and /fb's cross-repository mode) opened — which
# is exactly the input the retired event trigger used to hand over one at a
# time. Feedback remains the only input that can originate a proposal.
#
# ASSIGNED TO ME, NOT UNASSIGNED (decided, not omitted): every developer's copy
# of [Specificate] fires hourly, so an unassigned issue offered to every copy would
# have N runners race to propose it — the measured failure P8 exists for, with
# only the after-the-fact branch dedup to catch the collision. An unassigned
# issue still reaches /specificate by hand (`/specificate #<N>`), where a human chose
# the one session that acts. The server-side assignee filter also makes the
# P8 `not_mine` verdict impossible on this path by construction.
#
# NO TITLE FILTER (decided, not omitted), because of what arrives rather than
# what we send: issues are filed here by humans in the GitHub UI and by other
# tools, and neither carries an "[FB]"-style prefix — measured 2026-08-12, 1 of
# 9 human-filed issues did — so a title filter would drop exactly the asks this
# loop exists to ingest. Assignment is the routing signal; the title is prose.
# (This once rested on /fb's own crossing adding no prefix; since issue #411 it
# stamps "[FB] " via feedback/scripts/fb-title.sh. The boundary is unaffected —
# the crossing was never the only sender.)
#
# ALREADY-CAPTURED EXCLUSION: a merged proposal auto-closes its issue
# (`Closes #<N>`), so an OPEN issue whose number a feedback record already
# names is in flight — captured, its proposal PR open or its record-only merge
# pending — and re-taking it would duplicate the record. The match is the
# issue URL's `/issues/<N>` form, which the propose workflow's capture step
# requires the record to carry. Excluded rows are reported with their reason,
# never silently dropped.
#
# PURE READ, NEVER LOAD-BEARING: a missing gh, a failed auth, or an unreachable
# API is {"ok": false, ...} with exit 0 — the caller then reports the reason
# beside `nothing_in_hand` rather than inventing an empty inbox. An unreadable
# inbox must never render as an empty one.

set -eu

FEEDBACKS_DIR="${1:-.workaholic/feedbacks}"
LIMIT="${WORKAHOLIC_PROPOSE_ISSUE_LIMIT:-20}"
case "$LIMIT" in
  ''|*[!0-9]*) LIMIT=20 ;;
esac

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit_err() {
  detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
  printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
  exit 0
}

command -v gh >/dev/null 2>&1 || emit_err "gh_unavailable" "gh is not on PATH"

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

login="$(gh api user --jq .login 2>&1)" || emit_err "identity_unresolved" "$login"
[ -n "$login" ] || emit_err "identity_unresolved" "gh api user returned an empty login"

# REST, NOT `gh issue list` (2026-08-12, feedback 20260812172522). The subcommand is
# GraphQL-backed and a Claude Code Web session is not guaranteed to serve that surface:
# measured HTTP 403 "only the pinned set of PR-review operations is served" in this
# repository's own routine tick, 80 minutes after the same path had worked. The
# capability is per-session, so this reads through the one REST transport
# (`gather/scripts/gh-rest.sh`) and a restricted session ingests its inbox normally
# instead of reporting `list_failed` and going quiet for the hour.
slug="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>&1)" || emit_err "list_failed" "$slug"

# `per_page` IS the cap, deliberately and not by inheritance: the REST endpoint paginates
# where `--limit` truncated, so asking for exactly LIMIT on a single page reproduces the
# old ceiling rather than quietly walking every page.
#
# THE ONE BEHAVIORAL DIFFERENCE THE CONVERSION MUST NOT LOSE: `GET /issues` returns pull
# requests as well as issues (they share the numbering space); `gh issue list` did not.
# Rows carrying `.pull_request` are dropped here, or a routine would start proposing
# against its own pull requests.
#
# Oldest first: the ask that has waited longest is served first, so a busy hour never
# starves an early report. @tsv escapes tabs/newlines inside the title, so the 4-field
# read below is unambiguous (title deliberately last).
rows="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
  "repos/${slug}/issues?state=open&assignee=${login}&per_page=${LIMIT}" \
  --jq 'map(select(.pull_request | not)) | sort_by(.number) | .[]
        | [(.number|tostring), .html_url, .updated_at, .title] | @tsv' 2>&1)" \
  || emit_err "list_failed" "$rows"

TAB="$(printf '\t')"
issues=""
excluded=""
while IFS="$TAB" read -r number url updated title; do
  [ -n "$number" ] || continue
  captured="false"
  if [ -d "$FEEDBACKS_DIR" ] && grep -rqE "/issues/${number}([^0-9]|\$)" "$FEEDBACKS_DIR" 2>/dev/null; then
    captured="true"
  fi
  if [ "$captured" = "true" ]; then
    row="{\"number\": ${number}, \"reason\": \"already_captured\"}"
    excluded="${excluded:+${excluded}, }${row}"
  else
    row="{\"number\": ${number}, \"title\": \"$(json_escape "$title")\", \"url\": \"$(json_escape "$url")\", \"updated_at\": \"$(json_escape "$updated")\"}"
    issues="${issues:+${issues}, }${row}"
  fi
done <<EOF
$rows
EOF

printf '{"ok": true, "identity": "%s", "limit": %s, "issues": [%s], "excluded": [%s]}\n' \
  "$(json_escape "$login")" "$LIMIT" "$issues" "$excluded"
