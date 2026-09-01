#!/bin/sh -eu
# The dedup half of the inbound Slack sweep: which channel messages have ALREADY been
# turned into an issue, read from the issues themselves.
#
#   list-swept-slack-refs.sh
#
# Output (one JSON line, always exit 0 for a reported outcome):
#   {"ok": true, "refs": ["<channel>:<ts>", ...], "scanned": N}
#   {"ok": false, "reason": "gh_unavailable" | "slug_unresolved" | "list_failed",
#    "detail": "..."}
#
# WHY THE ISSUES ARE THE LEDGER (2026-08-23, the developer's instruction to drop the
# Claude Tag dependency). The sweep runs on `/propose`, a pure reader of this repository:
# it may write nothing into the tree, so it cannot keep a cursor or a swept-list file.
# What it DOES write is the issue itself, on GitHub — so the issue body carries the
# message's identity as a visible `slack-ref: <channel>:<ts>` line (stamped by the one
# writer, file-inbound-ask.sh), and this script reads those lines back. No new store, no
# cursor, and two concurrent ticks converge: both read the same ledger, and the loser of
# a race files a duplicate issue at worst — repairable by closing one, where a missed ask
# is not.
#
# STATE=ALL, BOUNDED: a captured message must stay captured after its issue closes
# (a merged proposal auto-closes it), so closed issues count. The read is bounded to the
# most recent pages rather than the whole history because the sweep's own window is a day
# or two — a ref older than the listing bound is also older than any message the sweep
# can see.
#
# PURE READ, NEVER LOAD-BEARING: an unreadable ledger is {"ok": false} with exit 0, and
# THE CALLER MUST SKIP THE SWEEP on it — filing against an unreadable dedup is how the
# same ask arrives twice an hour. Same rule as the propose brake: a gate that cannot be
# read is not a gate.

set -eu

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

emit_err() {
  detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
  printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
  exit 0
}

command -v gh >/dev/null 2>&1 || emit_err "gh_unavailable" "gh is not on PATH"

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts//gh-rest.sh"

slug="$(sh "$GH_REST" slug 2>&1)" || emit_err "slug_unresolved" "$slug"
[ -n "$slug" ] || emit_err "slug_unresolved" "gh-rest.sh slug returned empty"

# Two pages of 100, newest first: bounded, and wider than any sweep window.
refs=""
scanned=0
for page in 1 2; do
  body="$(sh "$GH_REST" api "repos/${slug}/issues?state=all&per_page=100&page=${page}" 2>&1)" \
    || emit_err "list_failed" "$body"
  page_refs="$(printf '%s' "$body" \
    | tr ',' '\n' \
    | sed -n 's/.*slack-ref: \([A-Z0-9][A-Z0-9]*:[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')" || true
  page_count="$(printf '%s' "$body" | grep -c '"number"' 2>/dev/null || true)"
  scanned=$((scanned + ${page_count:-0}))
  refs="$refs
$page_refs"
  # A short page ends the listing.
  [ "${page_count:-0}" -lt 100 ] && break
done

json_refs="$(printf '%s\n' "$refs" | sed '/^$/d' | sort -u \
  | while IFS= read -r r; do printf '"%s",' "$(json_escape "$r")"; done \
  | sed 's/,$//')"

printf '{"ok": true, "refs": [%s], "scanned": %d}\n' "$json_refs" "$scanned"
