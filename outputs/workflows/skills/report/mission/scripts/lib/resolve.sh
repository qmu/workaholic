#!/bin/sh -eu
# Shared mission layout helpers -- the SINGLE source of slug-to-path resolution
# and the living layout migration, sourced by every mission script so the two
# behaviors cannot drift across callers.
#
# Layout: missions live under one of two areas, keyed off the `status`
# frontmatter field (mirroring the tickets todo/archive split):
#   .workaholic/missions/active/<slug>/mission.md    status: active
#   .workaholic/missions/archive/<slug>/mission.md   status: achieved | abandoned
#
# Usage (from a mission script, with SCRIPT_DIR its own scripts/ dir):
#   source this file from the scripts dir: . "<scripts-dir>/lib/resolve.sh"
#   missions_migrate_layout               # heal any legacy flat layout first
#   FILE=$(mission_resolve "$ARG")        # then resolve a slug or path

# Living migration: relocate any legacy flat mission dir (a <slug>/ holding a
# mission.md directly under .workaholic/missions/) into the area its `status`
# selects. Idempotent -- a migrated tree has nothing flat left to move -- and
# best-effort: every failure is swallowed so a calling seam is never blocked
# (the resolver's flat fallback still finds an unmovable mission). `git mv`
# preserves history; plain `mv` + `git add` covers untracked missions.
missions_migrate_layout() {
    _mroot=".workaholic/missions"
    [ -d "$_mroot" ] || return 0
    for _mdir in "$_mroot"/*/; do
        [ -d "$_mdir" ] || continue
        _mdir=${_mdir%/}
        _mslug=$(basename "$_mdir")
        case "$_mslug" in active|archive) continue ;; esac
        [ -f "$_mdir/mission.md" ] || continue
        _mstatus=$(grep -m1 '^status:' "$_mdir/mission.md" 2>/dev/null | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)
        case "$_mstatus" in
            achieved|abandoned) _marea="archive" ;;
            *)                  _marea="active" ;;
        esac
        mkdir -p "$_mroot/$_marea" 2>/dev/null || continue
        [ -e "$_mroot/$_marea/$_mslug" ] && continue
        if git mv "$_mdir" "$_mroot/$_marea/$_mslug" >/dev/null 2>&1; then
            :
        else
            mv "$_mdir" "$_mroot/$_marea/$_mslug" 2>/dev/null || continue
            git add -A "$_mroot" >/dev/null 2>&1 || true
        fi
    done
    return 0
}

# Resolve a mission argument -- a path to a mission.md, or a bare slug -- to the
# mission.md path: active/ first, then archive/, then the legacy flat location
# (a mission the migration could not move). Always echoes a path (the active-
# area default when nothing exists yet) so callers keep their own `[ -f ]`
# not-found handling.
mission_resolve() {
    if [ -f "$1" ]; then
        printf '%s' "$1"
        return 0
    fi
    for _marea in active archive; do
        if [ -f ".workaholic/missions/${_marea}/$1/mission.md" ]; then
            printf '%s' ".workaholic/missions/${_marea}/$1/mission.md"
            return 0
        fi
    done
    if [ -f ".workaholic/missions/$1/mission.md" ]; then
        printf '%s' ".workaholic/missions/$1/mission.md"
        return 0
    fi
    printf '%s' ".workaholic/missions/active/$1/mission.md"
    return 0
}
