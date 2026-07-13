#!/bin/sh -eu
# Read a mission's quality-gate declaration and resolve the worktree port the gate
# is verified against. The gate is the mission-level "is the outcome good?" check,
# distinct from per-ticket gates:
#   gate_type    documentation | live-app | (empty = no live gate)
#   gate_target  a route served on the mission worktree's port to check (e.g. /docs)
#   gate_assert  one line: what must hold for the mission to pass
# A live check runs the project's dev/docs server on the worktree's assigned port
# (see .worktrees/<slug>/.env) and drives gate_target with Playwright.
#
# Usage: gate.sh <mission-slug-or-file>
# Output: {"type","target","assert","valid","slug","port_base","dev_port","docs_port"}
#   valid=false when gate_type is set but not one of the allowed values; the port
#   fields are "" when the mission has no worktree.

set -eu

ARG="${1:-}"
[ -n "$ARG" ] || { echo '{"error": "no_mission"}' >&2; exit 1; }

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
missions_migrate_layout

if [ -f "$ARG" ]; then
    f="$ARG"
else
    f=$(mission_resolve "$ARG")
fi
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
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
env_file="${repo_root}/.worktrees/${slug}/.env"
port_base=""
dev_port=""
docs_port=""
if [ -f "$env_file" ]; then
    port_base=$(grep -m1 '^WORKAHOLIC_PORT_BASE=' "$env_file" | sed -e 's/^WORKAHOLIC_PORT_BASE=//' || true)
    dev_port=$(grep -m1 '^WORKAHOLIC_DEV_PORT=' "$env_file" | sed -e 's/^WORKAHOLIC_DEV_PORT=//' || true)
    docs_port=$(grep -m1 '^WORKAHOLIC_DOCS_PORT=' "$env_file" | sed -e 's/^WORKAHOLIC_DOCS_PORT=//' || true)
fi

printf '{"type": "%s", "target": "%s", "assert": "%s", "valid": %s, "slug": "%s", "port_base": "%s", "dev_port": "%s", "docs_port": "%s"}\n' \
    "$gtype" "$gtarget" "$gassert" "$valid" "$slug" "$port_base" "$dev_port" "$docs_port"
