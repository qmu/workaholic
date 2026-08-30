#!/bin/sh -eu
# What does the repository say about its own drills? The ONE reader of the drill register,
# answering three questions and nothing else: can this drill run with no server (`kind`),
# which mission shipped it (`mission`), and — from the mission's side — which drill proves
# that mission's mechanism.
#
# WHY IT EXISTS (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`).
# `scripts/e2e/loop-drill.sh` holds thirty `verify-*` drills, one per mechanism an earlier
# turn of the loop built. Nothing ran them, and nothing could answer which of them a given
# environment was even able to run — the drill file's own header claimed the whole set
# assumed the server's full `gh` and `qfs`, which measurement showed was true of two rows out
# of thirty. The register is that measurement, recorded where a person keeps it current; this
# script is the only thing that reads it.
#
# THE REGISTER IS PROSE THE REPOSITORY OWNS, NOT A FIELD ON AN ARTIFACT. It is a markdown
# table in `docs/loop-drill-runbook.md` (§9). Three deliberate consequences:
#
#   - No artifact gained a field. A mission does not name its drill and a drill does not
#     name its mission; the link is a row in one document, which is the cheapest thing a
#     rename can be corrected in and the only place a human keeps it current.
#   - A repository that has no register is NOT a failure. Every consumer here also ships to
#     repositories with no drill set at all, so an absent register answers `no_register` and
#     each caller reports its own named absence (`no_drill`, `skipped`, …) rather than
#     stopping.
#   - There is exactly one parser. `verify-all`, the `/moderate` tick's drill-health step and
#     the archive gate all compose this script. A second parser is how two readings of one
#     fact start to disagree.
#
# A SLUG IS VALIDATED AGAINST THE TREE, NEVER TRUSTED. A mission can be renamed or archived,
# and an attribution nobody checked is worse than none — so a slug naming no mission under
# `.workaholic/missions/` is reported `mission_resolved: false`, exactly like an empty cell.
# The archive is searched beside the active area: a drill's shipping mission is finished by
# definition far more often than it is in flight.
#
# IT EXITS 0 IN EVERY CASE, INCLUDING EVERY DEGRADATION — `read-base-checks.sh`'s rule, for
# its reason: a caller must be able to say what it could not read rather than die on it.
#
# Usage:
#   drill-register.sh list                # every row
#   drill-register.sh drill <verify-name> # one row
#   drill-register.sh mission <slug>      # the drills a mission shipped
#
# Output: one JSON line.
#   list     {"ok", "register", "count", "drills": [{"drill","kind","mission","mission_resolved"}]}
#   drill    {"ok", "drill", "kind", "mission", "mission_resolved"} | {"ok": false, "reason"}
#   mission  {"ok", "mission", "drills": [...]} | {"ok": false, "reason": "no_drill"}
#
# Reasons: `no_register` (no such file), `empty_register` (the table holds no row),
#          `no_such_drill`, `no_drill` (the mission shipped none), `usage`.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

MODE="${1:-}"
ARG="${2:-}"

emit_err() {
    printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "${2:-}"
    exit 0
}

case "$MODE" in
    list|drill|mission) ;;
    *) emit_err usage "drill-register.sh list|drill <name>|mission <slug>" ;;
esac

# The repository the CALLER is in, never this script's own tree: the plugin is installed
# from a version-addressed cache path that has no `.workaholic/` and no `docs/` of its own.
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$ROOT" ] || ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/../../../../.." 2>/dev/null && pwd || true)

REGISTER="${WORKAHOLIC_DRILL_REGISTER:-${ROOT}/docs/loop-drill-runbook.md}"
[ -f "$REGISTER" ] || emit_err no_register "$REGISTER"

MISSIONS="${ROOT}/.workaholic/missions"

# The table's rows are the only lines in the document that open with a backticked
# `verify-` name in the first cell. Anchoring on that shape rather than on a heading keeps
# the parse independent of where §9 sits in the file and of every other table above it.
rows=$(sed -n 's/^| *`\(verify-[a-z0-9-]*\)` *| *`\{0,1\}\([a-z_]*\)`\{0,1\} *| *\([a-z]*\) *| *\(.*\) *|$/\1\t\2\t\4/p' "$REGISTER" 2>/dev/null || true)
[ -n "$rows" ] || emit_err empty_register "$REGISTER"

# Strip the mission cell's backticks and trailing spaces; an em dash (or an empty cell) is
# the register's way of saying "resolved to nothing, deliberately".
clean_mission() {
    printf '%s' "$1" | sed -e 's/`//g' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' \
        | sed -e 's/^—$//' -e 's/^-$//'
}

mission_exists() {
    [ -n "$1" ] || return 1
    [ -f "${MISSIONS}/active/$1/mission.md" ] && return 0
    [ -f "${MISSIONS}/archive/$1/mission.md" ] && return 0
    return 1
}

row_json() {
    _d="$1"
    _k="$2"
    _m=$(clean_mission "$3")
    _r=false
    if mission_exists "$_m"; then _r=true; else _m=""; fi
    printf '{"drill": "%s", "kind": "%s", "mission": "%s", "mission_resolved": %s}' \
        "$_d" "$_k" "$_m" "$_r"
}

case "$MODE" in
    list)
        out=""
        n=0
        printf '%s\n' "$rows" | while IFS='	' read -r d k m; do
            [ -n "$d" ] || continue
            printf '%s\n' "$(row_json "$d" "$k" "$m")"
        done > "${TMPDIR:-/tmp}/wh-drill-register.$$"
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            n=$((n + 1))
            if [ -z "$out" ]; then out="$line"; else out="${out}, ${line}"; fi
        done < "${TMPDIR:-/tmp}/wh-drill-register.$$"
        rm -f "${TMPDIR:-/tmp}/wh-drill-register.$$"
        printf '{"ok": true, "register": "%s", "count": %s, "drills": [%s]}\n' \
            "$REGISTER" "$n" "$out"
        ;;
    drill)
        [ -n "$ARG" ] || emit_err usage "drill-register.sh drill <verify-name>"
        line=$(printf '%s\n' "$rows" | awk -F'\t' -v d="$ARG" '$1 == d {print; exit}')
        [ -n "$line" ] || emit_err no_such_drill "$ARG"
        k=$(printf '%s' "$line" | cut -f2)
        m=$(printf '%s' "$line" | cut -f3-)
        printf '{"ok": true, %s}\n' "$(row_json "$ARG" "$k" "$m" | sed -e 's/^{//' -e 's/}$//')"
        ;;
    mission)
        [ -n "$ARG" ] || emit_err usage "drill-register.sh mission <slug>"
        out=""
        n=0
        printf '%s\n' "$rows" > "${TMPDIR:-/tmp}/wh-drill-register.$$"
        while IFS='	' read -r d k m; do
            [ -n "$d" ] || continue
            mm=$(clean_mission "$m")
            [ "$mm" = "$ARG" ] || continue
            n=$((n + 1))
            row=$(row_json "$d" "$k" "$m")
            if [ -z "$out" ]; then out="$row"; else out="${out}, ${row}"; fi
        done < "${TMPDIR:-/tmp}/wh-drill-register.$$"
        rm -f "${TMPDIR:-/tmp}/wh-drill-register.$$"
        [ "$n" -gt 0 ] || emit_err no_drill "$ARG"
        printf '{"ok": true, "mission": "%s", "count": %s, "drills": [%s]}\n' "$ARG" "$n" "$out"
        ;;
esac
