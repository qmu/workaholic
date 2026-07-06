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
  # Skip the . / .. self-references and the strict-layout marker.
  case "$name" in
    .|..|.strict-layout) continue ;;
  esac

  if [ -f "$entry" ]; then
    case "$name" in
      README.md|README_ja.md|index.md) : ;;
      *) add_finding ".workaholic/${name}" "undesignated-root-file" \
           "only README.md and index.md are allowed at the .workaholic/ root" "owner decision required" ;;
    esac
    continue
  fi

  [ -d "$entry" ] || continue

  if in_allowlist "$name"; then
    : # allowed top-level directory
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
      todo|icebox|archive|abandoned) : ;;
      *) add_finding ".workaholic/tickets/${sname}" "misplaced-ticket-state" \
           "tickets/ allows only todo, icebox, archive, abandoned" \
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
