#!/bin/sh -eu
# Discover the asks a clock-fired /specificate run has in hand: the open GitHub
# issues on THIS repository assigned to the session's own identity.
#
#   list-inbound-issues.sh [feedbacks-dir]     # default: .workaholic/feedbacks
#
# Output (one JSON line, always exit 0 for a reported outcome):
#   {"ok": true, "identity": "<login>", "limit": N,
#    "issues":   [{"number", "title", "url", "updated_at"}...],   oldest first
#    "excluded": [{"number", "reason": "already_captured"|"captured_on_branch"|"self_originated"}...]}
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
# AND THE RECORD MAY BE ON A BRANCH (2026-09-01, ticket 20260901042313). The
# paragraph above always named the in-flight case — "its proposal PR open" — and
# the implementation could not see it: the grep read `$FEEDBACKS_DIR` in the
# caller's checkout, which at the propose seam is a checkout of the base, so a
# record living only on an unmerged proposal branch was invisible and its issue
# was offered again every hour. Measured: issue #812's record sat on
# `work-20260901-022335` behind pull request #813 (`Closes #812`) from 02:23, and
# #812 was re-offered at 03:28 and again at 04:21 — each re-take writing a
# duplicate record and opening a fresh publish-tree pull request that then
# conflicted on the generated feedbacks index with every other open proposal.
# The dedup half of the run (`list-proposed-refs.sh`) had learned to read
# unmerged branches for exactly this reason a month earlier; the discovery half
# had not. Both now read them through ONE walk (`lib/unmerged-branches.sh`).
#
# TWO REASON WORDS, NOT ONE, decided rather than defaulted: `already_captured`
# means the record is on the base and the ask is settled, `captured_on_branch`
# means it is on an unmerged branch and the ask is waiting on that pull request.
# The two send a reader to different places — one to the record, one to a pull
# request that may need settling — and collapsing them would make the output say
# less than it did before the walk existed. Neither is a gate: nothing keys on
# the word, and both exclude the issue identically.
#
# DEGRADE TOWARD EXCLUDING, AND SAY SO. Ambiguity inside the walk (a shallow
# clone, an unanswerable ancestry test) resolves toward counting the branch, so
# toward EXCLUDING the issue — the direction `list-proposed-refs.sh` states and
# for its reason: a suppressed take is silence, a duplicate take is a duplicate
# record and a conflicting pull request. A walk that cannot run at all (no git
# repository, no base ref) warns on stderr and leaves the base grep alone; it
# never turns a readable inbox into `list_failed`, because an inbox that reads is
# an inbox this run can serve.
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
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"

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
# read below is unambiguous (title deliberately last). The `origin` field reads the
# body's own header line: `source: moderate` is the tick's finding about the loop itself.
rows="$(sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
  "repos/${slug}/issues?state=open&assignee=${login}&per_page=${LIMIT}" \
  --jq 'map(select(.pull_request | not)) | sort_by(.number) | .[]
        | [(.number|tostring), .html_url, .updated_at,
           (if ((.body // "") | test("^kind: [a-z_]+ / source: moderate"; "m")) then "self" else "human" end),
           .title] | @tsv' 2>&1)" \
  || emit_err "list_failed" "$rows"

TAB="$(printf '\t')"

# ---- the feedback records the open proposal branches add --------------------
# Materialised once, before the issue loop: the walk's cost is the BRANCH count, so
# doing it per issue would pay it up to LIMIT times to answer the same question.
BRANCH_RECORDS=""
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "list-inbound-issues: not a git repository; records on open proposal branches not covered" >&2
else
  UNMERGED_BRANCHES_LABEL="list-inbound-issues"
  . "${SCRIPT_DIR}/lib/unmerged-branches.sh"
  base="$(unmerged_branches_base)"
  if [ -z "$base" ]; then
    echo "list-inbound-issues: no base ref resolved; records on open proposal branches not covered" >&2
  else
    unmerged_branches_warn_shallow
    BRANCH_RECORDS="$(mktemp -d "${TMPDIR:-/tmp}/inbound-branch-records.XXXXXX")"
    trap 'rm -rf "$BRANCH_RECORDS"' EXIT INT TERM
    n=0
    # The pathspec already bounds the walk to the feedbacks area, so the only filter
    # left is the extension — matching a prefix here would disagree with git's
    # repository-root-relative paths whenever the caller is not at the root.
    while IFS="$TAB" read -r ref path; do
      [ -n "$path" ] || continue
      case "$path" in *.md) ;; *) continue ;; esac
      n=$((n + 1))
      git show "${ref}:${path}" >"${BRANCH_RECORDS}/${n}.md" 2>/dev/null || continue
    done <<EOF
$(unmerged_branches_added_paths "$base" "$FEEDBACKS_DIR")
EOF
  fi
fi

issues=""
excluded=""
while IFS="$TAB" read -r number url updated origin title; do
  [ -n "$number" ] || continue
  captured=""
  # THE LOOP'S OWN FINDING IS NOT AN ASK (2026-09-02, issue #864). `file-inbound-ask.sh
  # --finding` stamps `source: moderate` on every issue the tick files about the loop's own
  # artifacts. Measured: five consecutive such issues in one day, each proposed, ticketed,
  # implemented and merged by the next ticks, every link refining the link before it, while
  # the operator's development stopped entirely. Only a human's ask, or a strategy a human
  # authored, originates a mission; the finding stays open as knowledge and is never taken.
  if [ "$origin" = self ]; then
    captured="self_originated"
  elif [ -d "$FEEDBACKS_DIR" ] && grep -rqE "/issues/${number}([^0-9]|\$)" "$FEEDBACKS_DIR" 2>/dev/null; then
    captured="already_captured"
  elif [ -n "$BRANCH_RECORDS" ] && grep -rqE "/issues/${number}([^0-9]|\$)" "$BRANCH_RECORDS" 2>/dev/null; then
    captured="captured_on_branch"
  fi
  if [ -n "$captured" ]; then
    row="{\"number\": ${number}, \"reason\": \"${captured}\"}"
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
