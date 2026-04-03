#!/bin/bash
# Validate development environment readiness inside a worktree.
# Usage: bash validate-dev-env.sh <worktree_path>
# Output: JSON with ready status and per-check results.
#
# Checks:
#   env_files    - .env or .env.local exists
#   dependencies - node_modules exists (if package.json present)
#   ports        - configured ports are not already in use
#   shared_state - no shared lock/state files that conflict across worktrees

set -euo pipefail

worktree_path="${1:-}"

if [ -z "$worktree_path" ]; then
  echo '{"error": "worktree path is required"}' >&2
  exit 1
fi

if [ ! -d "$worktree_path" ]; then
  echo '{"error": "worktree path does not exist", "path": "'"$worktree_path"'"}' >&2
  exit 1
fi

checks="[]"
ready=true

add_check() {
  local name="$1" status="$2" details="$3" action="$4"
  checks=$(echo "$checks" | sed 's/]$//')
  if [ "$checks" != "[" ]; then
    checks="${checks},"
  fi
  checks="${checks}{\"name\":\"${name}\",\"status\":\"${status}\",\"details\":\"${details}\",\"action\":\"${action}\"}]"
  if [ "$status" != "ok" ]; then
    ready=false
  fi
}

# --- Check 1: Environment files ---
if [ -f "${worktree_path}/.env" ] || [ -f "${worktree_path}/.env.local" ]; then
  add_check "env_files" "ok" "environment files found" ""
elif [ -f "${worktree_path}/.env.example" ]; then
  add_check "env_files" "missing" ".env not found but .env.example exists" "copy and configure .env.example to .env in worktree"
else
  # Check if the main repo root has .env files to copy
  repo_root="$(git -C "$worktree_path" rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [ -n "$repo_root" ] && [ -f "${repo_root}/.env" ]; then
    add_check "env_files" "missing" ".env not found in worktree" "copy .env from repository root to worktree"
  else
    add_check "env_files" "ok" "no .env files required (none found in project)" ""
  fi
fi

# --- Check 2: Dependencies ---
if [ -f "${worktree_path}/package.json" ]; then
  if [ -d "${worktree_path}/node_modules" ]; then
    add_check "dependencies" "ok" "node_modules found" ""
  else
    add_check "dependencies" "missing" "package.json exists but node_modules not found" "run npm install in worktree"
  fi
elif [ -f "${worktree_path}/requirements.txt" ] || [ -f "${worktree_path}/pyproject.toml" ]; then
  if [ -d "${worktree_path}/venv" ] || [ -d "${worktree_path}/.venv" ]; then
    add_check "dependencies" "ok" "python virtual environment found" ""
  else
    add_check "dependencies" "missing" "python project but no venv found" "create venv and install dependencies in worktree"
  fi
elif [ -f "${worktree_path}/Gemfile" ]; then
  if [ -d "${worktree_path}/vendor/bundle" ]; then
    add_check "dependencies" "ok" "bundled gems found" ""
  else
    add_check "dependencies" "missing" "Gemfile exists but vendor/bundle not found" "run bundle install in worktree"
  fi
else
  add_check "dependencies" "ok" "no dependency manifest detected" ""
fi

# --- Check 3: Port conflicts ---
port_conflict=false
port_details=""

# Extract ports from .env files if they exist
ports_to_check=""
for envfile in "${worktree_path}/.env" "${worktree_path}/.env.local"; do
  if [ -f "$envfile" ]; then
    # Look for PORT= or *_PORT= patterns
    found_ports=$(grep -oE '(^|_)PORT=([0-9]+)' "$envfile" 2>/dev/null | grep -oE '[0-9]+' || true)
    if [ -n "$found_ports" ]; then
      ports_to_check="${ports_to_check} ${found_ports}"
    fi
  fi
done

if [ -n "$ports_to_check" ]; then
  for port in $ports_to_check; do
    # Check if port is in use (works on both Linux and macOS)
    if command -v ss >/dev/null 2>&1; then
      in_use=$(ss -tlnp 2>/dev/null | grep -c ":${port} " || true)
    elif command -v lsof >/dev/null 2>&1; then
      in_use=$(lsof -i -P -n 2>/dev/null | grep -c ":${port} " || true)
    else
      in_use=0
    fi
    if [ "$in_use" -gt 0 ]; then
      port_conflict=true
      port_details="port ${port} is already in use"
    fi
  done
  if [ "$port_conflict" = true ]; then
    add_check "ports" "conflict" "$port_details" "modify port values in worktree .env to use non-conflicting ports"
  else
    add_check "ports" "ok" "no port conflicts detected" ""
  fi
else
  add_check "ports" "ok" "no port configuration detected" ""
fi

# --- Check 4: Shared state / lock files ---
shared_issues=""
for lockfile in "${worktree_path}/.lock" "${worktree_path}/tmp/pids" "${worktree_path}/.cache/lock"; do
  if [ -e "$lockfile" ]; then
    shared_issues="stale lock/state file found: ${lockfile}"
  fi
done

if [ -n "$shared_issues" ]; then
  add_check "shared_state" "conflict" "$shared_issues" "remove stale lock files from worktree"
else
  add_check "shared_state" "ok" "no shared state conflicts detected" ""
fi

# --- Output ---
echo "{\"ready\": ${ready}, \"checks\": ${checks}}"
