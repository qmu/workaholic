#!/bin/sh
# Resolve the plugin tree THIS RUN should execute its scripts from, and say why.
#
# WHY THIS EXISTS. Every workflow reached its own scripts through `${CLAUDE_PLUGIN_ROOT}` --
# the root the harness bound at session start -- so a session whose binding was stale or
# absent could not run the workflow at all, and `/drive` §1 turned that into a terminal
# `pending`. Measured on 2026-08-12: twelve consecutive `[Implement]` ticks stopped at that
# gate with three claimable tickets queued, because the cloud container binds a project-scope
# install baked into an image (v1.0.133, 2026-08-06) while the SessionStart bootstrap updates
# the *user* scope (v1.0.159) -- `claude plugin update` says "for scope user" and the
# project-scope pin is never touched. Every tick is a fresh container off that same image, so
# the condition reproduces hourly and never self-heals. The developer's ruling (2026-08-12):
# the harness binding is not something the loop may depend on. A current copy of the plugin is
# present on the VM in every one of these failures; the run must find it and use it.
#
# THE RULE: pick the NEWEST source available, ties going to the checkout. That is what makes
# this safe rather than merely permissive -- the gate it replaces existed to stop a run from
# executing *stale* scripts (a stale `claims.sh` once called five already-driven tickets fresh
# backlog and claimed one, 2026-08-04), and choosing the newest tree can only move a run
# forward on that axis, never back. Preferring the checkout on a tie keeps the source the
# developer can actually inspect and edit.
#
# Sources, in tie-break order:
#   checkout - <project>/plugins/workaholic. This repository IS the plugin; after the run's own
#              sync-main.sh it is the tip by construction. Absent in a consuming repository.
#   registry - the installPath of the newest entry in the harness's installed_plugins.json.
#              Requires no network: the cloud bootstrap has already downloaded it (that is what
#              makes the binding "behind" in the first place), it just is not what got bound.
#   clone    - $WORKAHOLIC_SRC_HOME (default ~/.workaholic-src), a plain git clone this script
#              creates only when asked (--clone) and refreshes only when asked (--refresh).
#              This is the consuming-repository path when the harness knows nothing usable.
#   bound    - ${CLAUDE_PLUGIN_ROOT}, or this script's own location inside the plugin cache.
#              Still the answer whenever it is the newest thing present.
#
# WHAT THIS DOES NOT REPAIR, AND MUST NOT CLAIM TO. Hooks and the Skill/Command tool bindings
# come from whatever the harness bound; nothing here changes them mid-session. A run degraded
# to another source keeps the bound build's PreToolUse guards (older, but registered -- check.sh
# reports `guards_present`), and loses the UserPromptSubmit policy lens entirely when nothing is
# bound, which is why the callers are told to load the policy index from `src` explicitly. The
# canonical validators are scripts the workflows call directly (commit.sh runs check-subject.sh
# itself), so the guard layer is a second line, not the only one.
#
# Output (single JSON line, always exit 0 unless no source exists at all):
#   {"ok":true,"src":"<abs path>","source":"checkout|registry|clone|bound","version":"…",
#    "degraded":true|false,"bound_root":"…","bound_version":"…","registry_version":"…",
#    "candidates":[{"source":"…","version":"…","path":"…"}]}
set -eu

usage() {
  cat <<'EOF'
Usage: plugin-src.sh [--clone] [--refresh]

  --clone    create $WORKAHOLIC_SRC_HOME (default ~/.workaholic-src) by cloning
             qmu/workaholic when no other source is present. Network + git required.
  --refresh  git pull --ff-only an existing clone before considering it. Best effort:
             a failed refresh uses the clone as it stands rather than dropping it.
EOF
}

want_clone=false
want_refresh=false
for arg in "$@"; do
  case "$arg" in
    --clone) want_clone=true ;;
    --refresh) want_refresh=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf '{"ok": false, "reason": "unknown_argument", "argument": "%s"}\n' "$arg"; exit 2 ;;
  esac
done

# A plugin tree is identified by its manifest, never by its name on disk: the cache holds one
# directory per version and a clone holds the repository, so "does this path carry the plugin"
# is the only question with a stable answer.
tree_version() {
  # $1 = candidate plugin root. Prints the version, or nothing when this is not a plugin tree.
  [ -n "${1:-}" ] || return 0
  [ -f "${1}/.claude-plugin/plugin.json" ] || return 0
  [ -d "${1}/skills" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r '.version // empty' "${1}/.claude-plugin/plugin.json" 2>/dev/null || printf ''
  else
    sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "${1}/.claude-plugin/plugin.json" 2>/dev/null | head -n 1
  fi
}

abspath() {
  ( cd "$1" 2>/dev/null && pwd ) || printf ''
}

# --- candidate: checkout -------------------------------------------------------------------
project="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$project" ]; then
  project=$(git rev-parse --show-toplevel 2>/dev/null || printf '')
fi
checkout_path=""
checkout_version=""
if [ -n "$project" ]; then
  cand="${project}/plugins/workaholic"
  v=$(tree_version "$cand")
  if [ -n "$v" ]; then
    checkout_path=$(abspath "$cand")
    checkout_version="$v"
  fi
fi

# --- candidate: registry -------------------------------------------------------------------
# The newest install the harness knows about. This is deliberately read for its *installPath*
# rather than compared as a version number: check.sh already reports the comparison, and what
# a degraded run needs is the tree, which is sitting on disk fully downloaded.
registry="${CLAUDE_PLUGIN_REGISTRY:-${HOME}/.claude/plugins/installed_plugins.json}"
registry_path=""
registry_version=""
if [ -f "$registry" ] && command -v jq >/dev/null 2>&1; then
  registry_path=$(jq -r '
      (.plugins["workaholic@workaholic"] // [])
      | sort_by(.version) | last | .installPath // empty
    ' "$registry" 2>/dev/null || printf '')
  v=$(tree_version "$registry_path")
  if [ -n "$v" ]; then
    registry_path=$(abspath "$registry_path")
    registry_version="$v"
  else
    registry_path=""
  fi
fi

# --- candidate: clone ----------------------------------------------------------------------
src_home="${WORKAHOLIC_SRC_HOME:-${HOME}/.workaholic-src}"
clone_path=""
clone_version=""
if [ ! -d "${src_home}/.git" ] && [ "$want_clone" = true ] && command -v git >/dev/null 2>&1; then
  git clone --depth 1 https://github.com/qmu/workaholic "$src_home" >/dev/null 2>&1 || true
fi
if [ -d "${src_home}/.git" ]; then
  if [ "$want_refresh" = true ]; then
    git -C "$src_home" pull --ff-only >/dev/null 2>&1 || true
  fi
  v=$(tree_version "${src_home}/plugins/workaholic")
  if [ -n "$v" ]; then
    clone_path=$(abspath "${src_home}/plugins/workaholic")
    clone_version="$v"
  fi
fi

# --- candidate: bound ----------------------------------------------------------------------
# Same fallback check.sh uses: without the env var, this script's own resolved location inside
# the harness cache IS the binding, because the caller reached it through the expanded token.
bound_root="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$bound_root" ]; then
  self_dir=$(abspath "$(dirname -- "$0")/../../..")
  cache_prefix="${CLAUDE_PLUGIN_CACHE:-${HOME}/.claude/plugins/cache}"
  case "$self_dir" in
    "${cache_prefix}"/*) bound_root="$self_dir" ;;
  esac
fi
bound_path=""
bound_version=""
if [ -n "$bound_root" ]; then
  v=$(tree_version "$bound_root")
  if [ -n "$v" ]; then
    bound_path=$(abspath "$bound_root")
    bound_version="$v"
  fi
fi

# --- choose ---------------------------------------------------------------------------------
# Highest version wins; equal versions fall to the declared order (checkout, registry, clone,
# bound). `sort -V` is the same comparator check.sh uses for the behind/ahead decision, so the
# two scripts can never disagree about which of two versions is newer.
chosen_source=""
chosen_path=""
chosen_version=""
consider() {
  # $1 = source name, $2 = path, $3 = version
  [ -n "$2" ] || return 0
  [ -n "$3" ] || return 0
  if [ -z "$chosen_version" ]; then
    chosen_source="$1"; chosen_path="$2"; chosen_version="$3"
    return 0
  fi
  newer=$(printf '%s\n%s\n' "$chosen_version" "$3" | sort -V 2>/dev/null | tail -n 1)
  if [ "$newer" = "$3" ] && [ "$3" != "$chosen_version" ]; then
    chosen_source="$1"; chosen_path="$2"; chosen_version="$3"
  fi
}
consider checkout "$checkout_path" "$checkout_version"
consider registry "$registry_path" "$registry_version"
consider clone    "$clone_path"    "$clone_version"
consider bound    "$bound_path"    "$bound_version"

if [ -z "$chosen_path" ]; then
  # No tree anywhere. This is the only genuine stop left: the run cannot read its own workflow.
  printf '{"ok": false, "reason": "no_plugin_source", "src": "", "source": "none", "hint": "clone qmu/workaholic and re-run with WORKAHOLIC_SRC_HOME set, or pass --clone"}\n'
  exit 0
fi

degraded=true
if [ -n "$bound_path" ] && [ "$chosen_path" = "$bound_path" ]; then
  degraded=false
fi

candidates=""
add_candidate() {
  [ -n "$2" ] || return 0
  [ -n "$3" ] || return 0
  entry=$(printf '{"source": "%s", "version": "%s", "path": "%s"}' "$1" "$3" "$2")
  candidates="${candidates:+$candidates, }$entry"
}
add_candidate checkout "$checkout_path" "$checkout_version"
add_candidate registry "$registry_path" "$registry_version"
add_candidate clone    "$clone_path"    "$clone_version"
add_candidate bound    "$bound_path"    "$bound_version"

printf '{"ok": true, "src": "%s", "source": "%s", "version": "%s", "degraded": %s, "bound_root": "%s", "bound_version": "%s", "registry_version": "%s", "candidates": [%s]}\n' \
  "$chosen_path" "$chosen_source" "$chosen_version" "$degraded" \
  "$bound_path" "$bound_version" "$registry_version" "$candidates"
