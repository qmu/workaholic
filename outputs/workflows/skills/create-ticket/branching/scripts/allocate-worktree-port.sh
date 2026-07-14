#!/bin/sh -eu
# Allocate the next free local port base for a new worktree, so several worktrees
# can run their dev/docs servers at once without colliding on localhost. Scans the
# WORKAHOLIC_PORT_BASE values already assigned in existing .worktrees/*/.env and
# returns the lowest PORT_START + k*STRIDE not in use (so a removed worktree's base
# becomes allocatable again — allocation is based on live worktrees, not a counter).
#
# Usage: allocate-worktree-port.sh
# Output: {"port_base": N, "dev_port": N, "docs_port": N+1}

set -eu

PORT_START=4100
STRIDE=10

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

# Bases already assigned across existing worktree .env files (one per line).
used=$(grep -hoE '^WORKAHOLIC_PORT_BASE=[0-9]+' "${repo_root}/.worktrees"/*/.env 2>/dev/null \
    | sed -e 's/^WORKAHOLIC_PORT_BASE=//' || true)

base=$PORT_START
while printf '%s\n' "$used" | grep -qx "$base"; do
    base=$((base + STRIDE))
done

printf '{"port_base": %s, "dev_port": %s, "docs_port": %s}\n' "$base" "$base" "$((base + 1))"
