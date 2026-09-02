#!/bin/sh -eu
# Shared mission layout helpers -- the SINGLE source of slug-to-path resolution
# and the living layout migration, sourced by every mission script so the two
# behaviors cannot drift across callers.
#
# RESOLUTION IS A FUNCTION OF (ROOT, arg) WITH NO AMBIENT INPUT. The root is the
# `.workaholic` directory that owns the mission tree; the caller derives it from a
# DOMAIN FACT -- the ticket/mission artifact's own location, or (for a caller that
# holds only a slug and no artifact) the repository it is invoked in -- never from
# the process cwd. Resolving a bare slug against a cwd-relative path answered "is
# there a mission named <slug> HERE?" instead of "which mission does THIS artifact
# name?": the same ticket read a different mission.md from a different cwd, and
# because the returned path was relative it could not even reveal which file was
# read. Two same-slug missions in two worktrees were indistinguishable in the
# output. Every helper here therefore takes an explicit root and returns an
# ABSOLUTE path, so a caller, a log, or a test can see WHICH mission.md was read.
#
# Layout: missions live under one of two areas, keyed off the `status` frontmatter
# field (mirroring the tickets todo/archive split), where <root> is a `.workaholic`
# directory:
#   <root>/missions/active/<slug>/mission.md    status: active (in flight)
#   <root>/missions/archive/<slug>/mission.md   status: achieved | abandoned | carried
#
# Usage (from a mission script, with SCRIPT_DIR its own scripts/ dir):
#   . "<scripts-dir>/lib/resolve.sh"
#   ROOT=$(missions_root_for_arg "$ARG")     # or missions_root_from_artifact <ticket>
#   missions_migrate_layout "$ROOT"          # heal any legacy flat layout first
#   FILE=$(mission_resolve "$ROOT" "$ARG")   # then resolve a slug or path

# Absolutize a path against the current directory (a leading-slash path is echoed
# unchanged). Used only to root-qualify a chosen `.workaholic` directory so the
# resolved mission path is absolute and names WHICH tree unambiguously.
_missions_abs() {
    case "$1" in
        /*) printf '%s' "$1" ;;
        *)  printf '%s/%s' "$(pwd)" "$1" ;;
    esac
}

# The default root for a caller that holds only a slug and no artifact (create.sh,
# close.sh, gate.sh from a bare slug): the `.workaholic` of the repository/worktree the
# script is invoked in. This is NOT cwd path-arithmetic -- it is "operate on the repo I
# am part of", resolved through git so a worktree resolves to its OWN .workaholic and a
# sibling worktree's same-slug mission is never selected. Falls back to cwd only outside
# a git repo. Always absolute.
missions_root_default() {
    _mtop="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$_mtop" ]; then
        printf '%s/.workaholic' "$_mtop"
    else
        _missions_abs ".workaholic"
    fi
}

# Derive the `.workaholic` root that OWNS an artifact from the artifact's own path.
# Every workflow artifact lives under <root>/.workaholic/... (a ticket, a mission.md),
# so the segment up to and including ".workaholic" is the mission tree's root -- the
# same derivation hooks/validate-ticket.sh uses (`${file_path%%.workaholic/*}.workaholic`).
# This is the domain-fact root: the tree is fixed by WHERE the artifact lives, not by
# where the process stands. Falls back to the repo root for a path with no .workaholic
# segment. Always absolute.
missions_root_from_artifact() {
    case "$1" in
        # THE LAST `.workaholic/`, NEVER THE FIRST (2026-09-02, ticket
        # `20260902110551`). `%%` removes the LONGEST suffix, so it cuts at the
        # EARLIEST occurrence — which is the artifact's own tree only while no
        # directory above the repository root is called `.workaholic`. The loops run in
        # clones under `~/.workaholic/loops/<repo>/<loop>`, so an artifact there resolved
        # to `/home/<user>/.workaholic` and every mission lookup for it read a tree that
        # is not a repository at all. `%` cuts at the LAST occurrence, which is the
        # artifact's own; for a path with one occurrence the two are identical, so no
        # ordinary checkout changes behaviour.
        *.workaholic/*) _mwh="${1%.workaholic/*}.workaholic" ;;
        *) missions_root_default; return 0 ;;
    esac
    _missions_abs "$_mwh"
}

# Choose the root for an ARG that is EITHER a mission.md path OR a bare slug: a path
# names its own tree (derive from it); a bare slug names no tree, so it resolves against
# the repo the script runs in. The one place the slug-vs-path split is decided.
missions_root_for_arg() {
    if [ -f "$1" ]; then
        missions_root_from_artifact "$1"
    else
        missions_root_default
    fi
}

# Living migration: relocate any legacy flat mission dir (a <slug>/ holding a
# mission.md directly under <root>/missions/) into the area its `status` selects.
# Idempotent -- a migrated tree has nothing flat left to move -- and best-effort:
# every failure is swallowed so a calling seam is never blocked (the resolver's
# flat fallback still finds an unmovable mission). `git mv` preserves history; plain
# `mv` + `git add` covers untracked missions. Takes the root explicitly so it moves
# the tree the CALLER chose (the artifact's / the repo's), never whatever tree the
# process cwd happens to point at -- the same fix as mission_resolve, on the writer.
missions_migrate_layout() {
    _mroot="${1:-}"
    [ -n "$_mroot" ] || return 0
    # NOTE: the strategy-layer retirement used to ride this seam, folding any
    # .workaholic/strategies/ tree into feedbacks and removing the directory. It was
    # unwired on 2026-08-13 when the artifact was re-introduced with a bounded,
    # dated, owned shape (rules/workaholic.md; mission/SKILL.md, "The strategy
    # layer: retired, then redefined"). Leaving it wired would have deleted every
    # revived strategy on the next mission-script touch. Do not re-add it: an
    # erasing living migration and a live artifact area cannot share a directory.
    _mroot="${_mroot}/missions"
    [ -d "$_mroot" ] || return 0
    for _mdir in "$_mroot"/*/; do
        [ -d "$_mdir" ] || continue
        _mdir=${_mdir%/}
        _mslug=$(basename "$_mdir")
        case "$_mslug" in active|archive) continue ;; esac
        [ -f "$_mdir/mission.md" ] || continue
        _mstatus=$(grep -m1 '^status:' "$_mdir/mission.md" 2>/dev/null | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)
        case "$_mstatus" in
            achieved|abandoned|carried) _marea="archive" ;;
            *)                          _marea="active" ;;
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
    # The status-axis unification rides the same seam: a legacy `status: draft`
    # or `status: approved` mission is normalized to `active` on the next
    # mission-script touch (see missions_migrate_status below), after the area
    # relocation above has put every mission in the area its status selects.
    missions_migrate_status "${1:-}" || true
    return 0
}

# Living migration: fold every in-flight mission onto the ONE in-flight status
# (2026-07-31 -- docs/loop-engineering-workflow.md K1). `draft` is retired: J4 put
# every mission behind a pull request, so the merge IS the approval, and a second
# status-word gate only re-asks a question the PR already answered. `approved`
# goes with it -- with nothing left to approve, the word names no distinction.
#
#   status: draft     ->  status: active
#   status: approved  ->  status: active
#
# and the long-retired `drive_authorized:` key line is DROPPED from the rewritten
# file, so the field stops existing rather than lingering as a stale authority
# (it was folded into `status: approved` by I2, 2026-07-28; a checkout old enough
# to still carry it lands here in one hop).
#
# Area keying is untouched: the one in-flight state lives in active/, the three end
# states in archive/, so nothing moves here. Archived missions are history and are
# never rewritten.
#
# Idempotent (a migrated file says `active`, which matches nothing below) and
# best-effort: every failure is swallowed so a calling seam is never blocked -- an
# unmigrated mission is still read correctly, because every reader keeps a
# legacy-tolerance branch for the pre-migration shape until the touch lands.
#
# ---- DIRECTIONAL SAFETY: the fold is a WHITELIST, and must stay one ----
#
# The `case` below names the retired words explicitly and `continue`s on everything
# else. That is the guard, not a stylistic choice: a build can only ever rewrite
# vocabulary it already knows is legacy, so a status word it does not recognise --
# which is exactly what a NEWER repository's vocabulary looks like to an OLDER
# installed build -- is left untouched.
#
# The inverse shape is what caused the 2026-08-04 outage. The pre-K1 build folded in
# the other direction (`active` -> `draft`), and because that rule was written as
# "normalize whatever I find" rather than "fold these two known-dead words", an
# install thirteen versions behind happily rewrote every active mission on every
# prompt -- and `git add`ed the result, so the drive loop's own freshness step saw a
# dirty tree and terminated before it could survey. A migration that cannot tell
# "older than me" from "newer than me" will do this again on the next vocabulary
# change; a whitelist can tell, because unknown means newer.
#
# So when a future decision retires another word: ADD it to the case. Never invert
# the direction, and never widen the match to a catch-all.
missions_migrate_status() {
    _msroot="${1:-}"
    [ -n "$_msroot" ] || return 0
    _msroot="${_msroot}/missions"
    [ -d "$_msroot" ] || return 0
    # active/ plus any legacy flat dir the relocation above could not move.
    for _msf in "$_msroot"/active/*/mission.md "$_msroot"/*/mission.md; do
        [ -f "$_msf" ] || continue
        _msfm() {
            awk -v key="$1" '
                NR==1 { if ($0 != "---") exit; next }
                /^---[ \t]*$/ { exit }
                index($0, key ":") == 1 {
                    sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit
                }
            ' "$_msf" 2>/dev/null || true
        }
        _mscur=$(_msfm status)
        # Only the two retired in-flight words are folded. An end state in active/
        # is a placement problem, not a status problem, and is left alone.
        case "$_mscur" in
            draft | approved) : ;;
            *) continue ;;
        esac
        _mstmp="${_msf}.status.$$"
        awk '
            NR == 1 && $0 == "---" { in_fm = 1; print; next }
            in_fm && /^---[ \t]*$/ { in_fm = 0; print; next }
            in_fm && /^status:/ { print "status: active"; next }
            in_fm && /^drive_authorized:/ { next }
            { print }
        ' "$_msf" > "$_mstmp" 2>/dev/null && mv "$_mstmp" "$_msf" 2>/dev/null || {
            rm -f "$_mstmp" 2>/dev/null || true
            continue
        }
        git add "$_msf" >/dev/null 2>&1 || true
    done
    return 0
}

# Resolve a mission argument -- a path to a mission.md, or a bare slug -- to an
# ABSOLUTE mission.md path under <root>: an existing path is absolutized and returned
# as-is (the absolute-safe fast path, which is why an absolute-path caller like
# drive/scripts/plan-units.sh was never cwd-dependent); a slug is tried active/ then
# archive/ then the legacy flat location (a mission the migration could not move), and
# finally defaults to the active-area path (which need not exist). ALWAYS echoes a
# path so callers keep their own `[ -f ]` not-found handling; create.sh DEPENDS on
# that -- it resolves a slug that is supposed not to exist yet. The returned path is
# absolute, so two different missions in two different trees can never yield the same
# string.
mission_resolve() {
    _mroot="$1"
    _marg="$2"
    if [ -f "$_marg" ]; then
        _missions_abs "$_marg"
        return 0
    fi
    for _marea in active archive; do
        if [ -f "${_mroot}/missions/${_marea}/${_marg}/mission.md" ]; then
            printf '%s' "${_mroot}/missions/${_marea}/${_marg}/mission.md"
            return 0
        fi
    done
    if [ -f "${_mroot}/missions/${_marg}/mission.md" ]; then
        printf '%s' "${_mroot}/missions/${_marg}/mission.md"
        return 0
    fi
    printf '%s' "${_mroot}/missions/active/${_marg}/mission.md"
    return 0
}
