#!/bin/sh -eu
# layout-doctor.sh — audit an existing .workaholic/ tree against the canonical
# layout allowlist, and report every non-conforming path with a suggested fix.
#
# The companion of validate-ticket.sh's layout gate: the gate prevents NEW drift
# on Write/Edit, the doctor finds drift that ALREADY exists (including empty dirs
# and dirs made with bare `mkdir`, which never trip a Write/Edit hook).
#
# Reads the SAME single source of truth the hook reads — the sibling
# workaholic-layout-allowlist.txt — so the two never diverge.
#
# Usage: layout-doctor.sh [path]
#   [path] — a .workaholic directory, or a repo root that contains one.
#            Defaults to the current repo's .workaholic/ (git top-level, else cwd),
#            so it can audit another repo without running from inside it.
# Output: a JSON report on stdout; a short human summary on stderr.
# Read-only: it REPORTS and suggests `git mv`; it never mutates the tree — the
# destructive choice (which branch? merge or keep?) belongs to the repo owner.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ALLOWLIST="${SCRIPT_DIR}/workaholic-layout-allowlist.txt"

# Fail safe: never audit against a list we cannot read (would flag everything).
if [ ! -f "$ALLOWLIST" ]; then
  printf '{"error": "allowlist not found", "expected": "%s"}\n' "$ALLOWLIST"
  exit 1
fi

# Resolve the .workaholic dir to audit.
arg="${1:-}"
if [ -n "$arg" ]; then
  if [ -d "${arg}/.workaholic" ]; then WH="${arg}/.workaholic"
  else WH="$arg"; fi
else
  root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  WH="${root}/.workaholic"
fi

if [ ! -d "$WH" ]; then
  printf '{"error": "no .workaholic directory", "path": "%s"}\n' "$WH"
  exit 1
fi

# Minimal JSON string escaping for embedded paths (backslash + double-quote).
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

in_allowlist() { grep -qxF "$1" "$ALLOWLIST"; }

findings=""
advisories=""

add_finding() {
  _p=$(esc "$1"); _c="$2"; _r=$(esc "$3"); _m=$(esc "$4")
  _sep=""; [ -n "$findings" ] && _sep=","
  findings="${findings}${_sep}{\"path\":\"${_p}\",\"classification\":\"${_c}\",\"reason\":\"${_r}\",\"remediation\":\"${_m}\"}"
}
add_advisory() {
  _p=$(esc "$1"); _r=$(esc "$2")
  _sep=""; [ -n "$advisories" ] && _sep=","
  advisories="${advisories}${_sep}{\"path\":\"${_p}\",\"reason\":\"${_r}\"}"
}

# --- Top-level entries -------------------------------------------------------
for entry in "$WH"/* "$WH"/.*; do
  [ -e "$entry" ] || continue
  name=$(basename "$entry")
  # Skip the . / .. self-references.
  case "$name" in
    .|..) continue ;;
  esac

  if [ -f "$entry" ]; then
    # README.md / index.md and the release-scan config files (scan-allow,
    # leak-denylist) are the allowed root files — same set the layout gate allows.
    # `proposal-cursor` was allowed here until 2026-08-04, when the merged-main
    # window it served was retired; nothing writes or folds it any more, so a
    # surviving git-ignored file is reported for the operator to delete
    # (docs/proposal-loop-runbook.md §7) rather than silently tolerated.
    case "$name" in
      README.md|README_ja.md|index.md|scan-allow|leak-denylist) : ;;
      *) add_finding ".workaholic/${name}" "undesignated-root-file" \
           "only README.md, index.md, scan-allow, and leak-denylist are allowed at the .workaholic/ root" "owner decision required" ;;
    esac
    continue
  fi

  [ -d "$entry" ] || continue

  if in_allowlist "$name"; then
    : # allowed top-level directory
  elif [ "$name" = "guides" ] || [ "$name" = "policies" ] || [ "$name" = "specs" ]; then
    # The three documentation areas retired 2026-08-13 (issue #436). A consuming
    # repository's plugin updates before its tree does, so it meets the de-listed
    # allowlist while still holding the directory — and every later write into it is
    # hard-blocked. Name the retirement rather than let the generic "not in the
    # allowlist" reason describe a shape the repo has had for months. The content
    # decision is the OWNER'S: this repo deleted its own because all 17 substantive
    # files described a retired architecture, and nothing imposes that answer here.
    add_finding ".workaholic/${name}" "retired-area" \
      "the guides/, policies/ and specs/ documentation areas were retired 2026-08-13 (issue #436): an area with no writer in the loop goes stale and then lies" \
      "move what is still true into this repository's own docs/ tree (outside .workaholic/), then remove the directory — owner decision, never applied automatically"
  elif [ "$name" = ".trips" ]; then
    add_finding ".workaholic/.trips" "undesignated" \
      "dotted duplicate of the canonical trips/" \
      "git mv .workaholic/.trips/* .workaholic/trips/   # consolidate into trips/"
  else
    add_finding ".workaholic/${name}" "undesignated" \
      "not in the canonical allowlist" "owner decision required"
  fi
done

# --- tickets/ sub-locations (todo|icebox|archive|abandoned only) -------------
if [ -d "${WH}/tickets" ]; then
  for sub in "${WH}/tickets"/*; do
    [ -d "$sub" ] || continue
    sname=$(basename "$sub")
    case "$sname" in
      todo|archive) : ;;
      icebox|abandoned)
        # Retired 2026-08-13 (issue #436): state is a frontmatter field, the
        # archive is a place. The living migration converges these; the doctor
        # reports them so a tree that has not run it yet says why.
        add_finding ".workaholic/tickets/${sname}" "retired-ticket-state" \
          "tickets/ is two-state since 2026-08-13: todo/ and archive/ only — a ticket's state is its status: frontmatter field, not its directory" \
          "bash \${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-ticket-states.sh   # folds into archive/unbranched/ with status: ${sname}"
        ;;
      *) add_finding ".workaholic/tickets/${sname}" "misplaced-ticket-state" \
           "tickets/ allows only todo and archive" \
           "git mv .workaholic/tickets/${sname}/* .workaholic/tickets/archive/<branch>/" ;;
    esac
  done
fi

# --- Advisory: trip naming + non-standard nested trip internals --------------
if [ -d "${WH}/trips" ]; then
  for trip in "${WH}/trips"/*; do
    [ -d "$trip" ] || continue
    tname=$(basename "$trip")
    case "$tname" in
      work-*) : ;;
      *) add_advisory ".workaholic/trips/${tname}" \
           "trip dir uses legacy naming (canonical is work-<YYYYMMDD-HHMMSS>)" ;;
    esac
    for nested in designs/reviews models/reviews; do
      if [ -d "${trip}/${nested}" ]; then
        add_advisory ".workaholic/trips/${tname}/${nested}" \
          "non-standard nested trip internals (reviews/ lives at the trip root)"
      fi
    done
  done
fi

# --- Emit -------------------------------------------------------------------
conforming=true
[ -n "$findings" ] && conforming=false
wh_rel="$WH"

printf '{"workaholic": "%s", "conforming": %s, "findings": [%s], "advisories": [%s]}\n' \
  "$(esc "$wh_rel")" "$conforming" "$findings" "$advisories"

# Human summary to stderr (the JSON above is the machine contract on stdout).
if [ "$conforming" = true ] && [ -z "$advisories" ]; then
  echo "layout-doctor: ${WH} conforms to the canonical layout." >&2
else
  echo "layout-doctor: reviewed ${WH} (see plugins/workaholic/rules/workaholic.md for the canonical structure)." >&2
  [ -n "$findings" ] && echo "  non-conformances found — apply the suggested git mv, or decide per directory." >&2
  [ -n "$advisories" ] && echo "  advisories present (non-blocking)." >&2
fi

exit 0
