#!/bin/sh -eu
# layout-doctor.sh — audit an existing .workaholic/ tree against the canonical
# layout allowlist, and report every non-conforming path with a suggested fix.
#
# The companion of validate-ticket.sh's layout gate: the gate prevents NEW drift
# on Write/Edit, the doctor finds drift that ALREADY exists (including empty dirs
# and dirs made with bare `mkdir`, which never trip a Write/Edit hook).
#
# Reads the SAME single source of truth the hook reads — the sibling
# workaholic-layout-allowlist.txt — so the two never diverge, plus the rename registry
# (skills/gather/scripts/renames.tsv, through its one reader) so a repository still
# holding a renamed area is told WHAT IT BECAME rather than that it is unrecognised.
#
# A RETIREMENT IS NOT A RENAME, and the two classifications stay distinct: `renamed-area`
# has a destination and a mechanical remediation, `retired-area` has neither and its
# content decision belongs to the owner. Folding guides/policies/specs into the registry
# would need a row with an empty destination — a second behaviour inside one kind — so
# they keep the branch below (a fixed historical fact about three names, not a list that
# grows).
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
# The rename registry lives with the skill that owns its scripts, not here: its reader
# and its migration ship to non-Claude agents through the bundle, and build.mjs carries
# a skill's whole scripts/ directory (any extension) while nothing carries hooks/. The
# doctor is the one consumer that reaches ACROSS that boundary, deliberately and in one
# place -- a hook reading a skill's data file -- because the alternative is a second
# copy of the table on this side of it.
RENAMES_READER="${SCRIPT_DIR}/../skills/gather/scripts/list-renames.sh"

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

# Renamed areas, as `old<TAB>new<TAB>since` lines. Best-effort by design: a missing or
# unreadable registry leaves this empty and every classification below falls back to
# what it did before the registry existed. A doctor that failed closed on a data file
# would flag an entire tree because a tab went missing.
RENAMED_AREAS=""
if [ -r "$RENAMES_READER" ]; then
  RENAMED_AREAS=$(sh "$RENAMES_READER" --rows --kind area 2>/dev/null || true)
fi

# Echo "<new>\t<since>" when $1 is a renamed area, nothing otherwise.
renamed_to() {
  [ -n "$RENAMED_AREAS" ] || return 0
  printf '%s\n' "$RENAMED_AREAS" | awk -F '\t' -v want="$1" '$2 == want { print $3 "\t" $4; exit }'
}

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

  renamed=$(renamed_to "$name")

  if in_allowlist "$name" && [ -z "$renamed" ]; then
    : # allowed top-level directory
  elif [ -n "$renamed" ]; then
    # A RENAME, declared in the registry (skills/gather/scripts/renames.tsv). Checked
    # BEFORE the allowlist, because the moment a rename lands the allowlist carries the
    # NEW name and the old one would otherwise fall through to the generic
    # "not in the canonical allowlist" reason -- which is exactly the uninformative
    # answer the registry exists to replace. The remediation is mechanical and safe, so
    # unlike `retired-area` it names a command rather than a decision.
    new_name=$(printf '%s' "$renamed" | cut -f1)
    since=$(printf '%s' "$renamed" | cut -f2)
    add_finding ".workaholic/${name}" "renamed-area" \
      "the ${name}/ area was renamed to ${new_name}/ on ${since}" \
      "bash \${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/migrate-renamed-areas.sh   # git mv ${name}/ -> ${new_name}/, or run /workaholify"
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

# --- Advisory: one slug naming two missions ---------------------------------
# ONE ASK PLANNED TWICE (2026-09-01, ticket `20260901070000-collapse-two-missions-that-plan-the-same-ask.md`).
#
# `/specificate` dedups on the ask's FEEDBACK REFS, so two records written for one ask produce
# two missions — and the slug is derived from the title, so the two collide. Measured
# 2026-09-01, both pairs in this repository:
#
#   deliver-what-the-loop-already-knows-…   records 20260828121729 / 20260828181639, 6h apart
#   say-when-the-loop-has-run-out-of-direction  records 20260826071745 / 20260826081729, 1h apart
#
# In both, the LATER record's mission was driven and archived while the earlier one sat in a
# publication the transport had refused, landing days later with a queue of finished work.
#
# IT IS AN ADVISORY, NOT A FINDING, AND THAT IS THE DECISION. A finding sets
# `conforming: false`, which fails the `Validate Plugins` merge gate — and both pairs are in the
# tree today, so it would turn the base red and block every merge until somebody ruled on
# history that is harming nothing this minute. The collision bites only when something tries to
# move the active copy into an archive that is already occupied.
#
# THE OTHER TWO SEAMS WERE REFUSED, and the reasons belong here beside the check:
#   * PREVENT AT THE SLUG (`/specificate` refuses a slug that already exists) would refuse a
#     legitimate second attempt at an ask whose first was abandoned, and — decisively — it
#     cannot see the two pairs already in the tree, which would then go unreported forever.
#   * REFUSE AT THE CLOSE OR THE MOVE fires at the moment the collision bites, but `archive.sh`
#     runs unattended with no person attached, so it converts a silent collision into a refusal
#     nobody reads.
# The audit is where this repository already puts a structural finding the operator must rule
# on — beside `retired-area`, `renamed-area` and `retired-ticket-state`.
#
# IT DELETES NOTHING AND CHOOSES NOTHING. Both copies are history: one carries the
# implementation changelog and the run hours, the other the verification. Which survives is the
# operator's ruling, and this reports the pair with the decision it needs.
if [ -d "${WH}/missions/active" ] && [ -d "${WH}/missions/archive" ]; then
  for mdir in "${WH}/missions/active"/*; do
    [ -d "$mdir" ] || continue
    mslug=$(basename "$mdir")
    [ -d "${WH}/missions/archive/${mslug}" ] || continue
    add_advisory ".workaholic/missions/active/${mslug}" \
      "one slug names two missions (an archived copy exists); the operator rules which record survives -- delete neither"
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
