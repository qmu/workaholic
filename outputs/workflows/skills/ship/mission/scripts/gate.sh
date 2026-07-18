#!/bin/sh -eu
# Read a mission's quality-gate declaration and resolve the worktree port the gate
# is verified against. A mission gate is OPTIONAL and normally EMPTY -- a mission's
# substance is its ## Experience section plus its ticket plan, not a check fixed at
# kickoff before the work exists. This reads the gate when one is declared,
# distinct from per-ticket gates:
#   gate_type    documentation | live-app | (empty = no live gate)
#   gate_target  a route served on the mission worktree's port to check (e.g. /docs)
#   gate_assert  one line: what must hold for the mission to pass
# A live check runs the project's dev/docs server on the worktree's assigned port
# (see .worktrees/<slug>/.env) and drives gate_target with Playwright.
#
# Usage: gate.sh <mission-slug-or-file>
# Output: {"type","target","assert","valid","driveable","reason","slug",
#          "port_base","dev_port","docs_port"}
#   valid     -- the DECLARATION is well-formed: gate_type is empty or one of the
#                allowed words. It says nothing about whether the gate can be run.
#                Deliberately unchanged in meaning; callers already depend on it.
#   driveable -- the gate can actually be exercised: a gate is declared AND its
#                worktree ports resolved. This exists because `valid: true` with empty
#                ports was reporting success for a gate that could not be addressed at
#                all -- the gate silently degraded to unverifiable while claiming to
#                pass validation. `reason` names why not:
#                  ""              driveable, or nothing to drive
#                  "no_gate"       no gate declared (the NORMAL case, not an error)
#                  "no_worktree"   a gate is declared but the mission has no worktree,
#                                  so there is no port to serve its target on
#   The port fields are "" when the mission has no worktree.

set -eu

ARG="${1:-}"
[ -n "$ARG" ] || { echo '{"error": "no_mission"}' >&2; exit 1; }

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"

f=$(mission_resolve "$ROOT" "$ARG")
[ -f "$f" ] || { echo '{"error": "not_found"}' >&2; exit 1; }

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
fm() { grep -m1 "^$1:" "$f" 2>/dev/null | sed -e "s/^$1:[ \t]*//" -e 's/[ \t]*$//' || true; }

gtype=$(fm gate_type)
gtarget=$(json_escape "$(fm gate_target)")
gassert=$(json_escape "$(fm gate_assert)")
slug=$(basename "$(dirname "$f")")

valid=true
case "$gtype" in
    ""|documentation|live-app) : ;;
    *) valid=false ;;
esac

# Resolve the mission worktree's assigned ports (empty when no worktree exists).
#
# The worktrees live under the MAIN checkout's root, so that is what must be resolved --
# and `git rev-parse --show-toplevel` is the wrong primitive for it. Inside a worktree it
# returns THE WORKTREE, so the lookup became <worktree>/.worktrees/<slug>/.env: a
# .worktrees dir nested inside a worktree, which nothing ever creates. The ports came back
# empty for every mission in the prescribed layout -- a mission lives in its own worktree,
# and /drive auto-routes there, so that is exactly where this runs.
#
# `--git-common-dir` is the primitive that answers "where is the main checkout": inside a
# linked worktree it points at the main .git, while --git-dir points at
# .git/worktrees/<name>. Its dirname is the main root. Git returns it relative to CWD when
# convenient (".git" at the toplevel, "../../.git" from a subdir), so it is resolved
# through `cd`+`pwd` rather than string surgery -- verified from a worktree, the main
# root, and a main-checkout subdir.
common_dir="$(git rev-parse --git-common-dir 2>/dev/null || echo "")"
if [ -n "$common_dir" ] && [ -d "$common_dir" ]; then
    repo_root="$(cd "$(dirname "$common_dir")" && pwd)"
else
    repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
fi
env_file="${repo_root}/.worktrees/${slug}/.env"
port_base=""
dev_port=""
docs_port=""
if [ -f "$env_file" ]; then
    port_base=$(grep -m1 '^WORKAHOLIC_PORT_BASE=' "$env_file" | sed -e 's/^WORKAHOLIC_PORT_BASE=//' || true)
    dev_port=$(grep -m1 '^WORKAHOLIC_DEV_PORT=' "$env_file" | sed -e 's/^WORKAHOLIC_DEV_PORT=//' || true)
    docs_port=$(grep -m1 '^WORKAHOLIC_DOCS_PORT=' "$env_file" | sed -e 's/^WORKAHOLIC_DOCS_PORT=//' || true)
fi

# Can the gate actually be exercised? `valid` only ever meant "the declaration is
# well-formed", so a live-app gate with no resolvable port reported valid: true while
# being impossible to address -- silently unverifiable. Keep valid's meaning (callers
# depend on it) and say the other thing separately.
driveable=false
reason=""
if [ -z "$gtype" ]; then
    reason="no_gate"          # the NORMAL case: nothing to drive, not an error
elif [ -z "$dev_port" ]; then
    reason="no_worktree"      # a gate is declared but has no port to serve its target on
else
    driveable=true
fi

printf '{"type": "%s", "target": "%s", "assert": "%s", "valid": %s, "driveable": %s, "reason": "%s", "slug": "%s", "port_base": "%s", "dev_port": "%s", "docs_port": "%s"}\n' \
    "$gtype" "$gtarget" "$gassert" "$valid" "$driveable" "$reason" "$slug" "$port_base" "$dev_port" "$docs_port"
