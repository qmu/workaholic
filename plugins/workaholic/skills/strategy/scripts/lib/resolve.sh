#!/bin/sh -eu
# Shared strategy layout helpers -- the SINGLE source of slug-to-path resolution for
# the strategy tree, sourced by every strategy script so the behavior cannot drift
# across callers. Modeled on mission/scripts/lib/resolve.sh at smaller scale: there is
# NO living migration here because strategies are a new artifact with no legacy layout.
#
# RESOLUTION IS A FUNCTION OF (ROOT, arg) WITH NO AMBIENT INPUT — same doctrine as the
# mission resolver: the root is the `.workaholic` directory that owns the strategy tree,
# derived from a domain fact (the artifact's own location, or the repo the script runs
# in), never from the process cwd, and every path returned is ABSOLUTE so a caller/log/
# test can see WHICH strategy.md was read.
#
# Layout: strategies live under one of two areas, keyed off the `status` field:
#   <root>/strategies/active/<slug>/strategy.md    status: active
#   <root>/strategies/archive/<slug>/strategy.md   status: retired

# Absolutize a path against the current directory (a leading-slash path is echoed
# unchanged).
_strategies_abs() {
    case "$1" in
        /*) printf '%s' "$1" ;;
        *)  printf '%s/%s' "$(pwd)" "$1" ;;
    esac
}

# The default root for a caller that holds only a slug and no artifact (create.sh,
# list.sh, retire.sh from a bare slug): the `.workaholic` of the repository/worktree the
# script is invoked in, resolved through git so a worktree resolves to its OWN
# .workaholic. Falls back to cwd only outside a git repo. Always absolute.
strategies_root_default() {
    _stop="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$_stop" ]; then
        printf '%s/.workaholic' "$_stop"
    else
        _strategies_abs ".workaholic"
    fi
}

# Derive the `.workaholic` root that OWNS an artifact from the artifact's own path
# (the segment up to and including ".workaholic"). Falls back to the repo root for a
# path with no .workaholic segment. Always absolute.
strategies_root_from_artifact() {
    case "$1" in
        *.workaholic/*) _swh="${1%%.workaholic/*}.workaholic" ;;
        *) strategies_root_default; return 0 ;;
    esac
    _strategies_abs "$_swh"
}

# Choose the root for an ARG that is EITHER a strategy.md path OR a bare slug.
strategies_root_for_arg() {
    if [ -f "$1" ]; then
        strategies_root_from_artifact "$1"
    else
        strategies_root_default
    fi
}

# Resolve a strategy argument -- a path to a strategy.md, or a bare slug -- to an
# ABSOLUTE strategy.md path under <root>: an existing path is absolutized and returned
# as-is; a slug is tried active/ then archive/, and finally defaults to the active-area
# path (which need not exist, so create.sh can resolve a slug that should not exist yet).
strategy_resolve() {
    _sroot="$1"
    _sarg="$2"
    if [ -f "$_sarg" ]; then
        _strategies_abs "$_sarg"
        return 0
    fi
    for _sarea in active archive; do
        if [ -f "${_sroot}/strategies/${_sarea}/${_sarg}/strategy.md" ]; then
            printf '%s' "${_sroot}/strategies/${_sarea}/${_sarg}/strategy.md"
            return 0
        fi
    done
    printf '%s' "${_sroot}/strategies/active/${_sarg}/strategy.md"
    return 0
}
