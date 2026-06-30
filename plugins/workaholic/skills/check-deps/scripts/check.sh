#!/bin/sh -eu
# Check that required dependency plugins are installed, and surface diagnostics
# that make a stale or partial plugin install detectable.
#
# Workaholic is a single plugin (dependencies: []), so the dependency check is
# trivially satisfied (ok: true). Beyond that, when this script can locate the
# loaded plugin's manifest and hooks (i.e. it is running from the plugin tree on
# Claude Code), it additionally reports:
#   - version        the loaded plugin version, so a stale install is visible
#   - guards_present whether the three PreToolUse Bash guards are registered
#   - missing_guards any expected guard not found in the loaded hooks.json
#
# These are DIAGNOSTICS, never a hard gate: a missing guard warns, ok stays true.
# A stale install is the failure mode this catches -- an absent hook (old build)
# looks identical to a broken one, so the loaded version + guard presence are
# surfaced rather than left silent. Activation (does the PreToolUse hook actually
# fire?) cannot be proven from a script -- it fires on the Bash *tool* call, not
# on nested `sh` -- so that is verified by the in-session probe documented in
# SKILL.md, not here.
#
# When the manifest/hooks are not found (e.g. the generated cross-agent bundle,
# where hooks do not exist) or jq is absent, the script degrades to {"ok": true}.

set -eu

# Locate the loaded plugin root relative to this script, without relying on the
# plugin-root path expansion (so the source and the generated bundle copy stay
# byte-identical). This script sits three directory levels under the plugin root,
# so three parent hops reach it.
script_dir=$(cd -- "$(dirname -- "$0")" && pwd)
root=$(cd -- "${script_dir}/../../.." && pwd)
manifest="${root}/.claude-plugin/plugin.json"
hooks="${root}/hooks/hooks.json"

# Without the manifest (or jq) there is nothing to diagnose -> trivially ok.
if [ ! -f "$manifest" ] || ! command -v jq >/dev/null 2>&1; then
  echo '{"ok": true}'
  exit 0
fi

version=$(jq -r '.version // "unknown"' "$manifest")

# Assert the three PreToolUse Bash guards are registered in the loaded hooks.json.
expected="guard-ticket-structure.sh guard-git-commit.sh guard-git-branch.sh"
missing=""
if [ -f "$hooks" ]; then
  registered=$(jq -r '[.hooks.PreToolUse[]?.hooks[]?.command] | join("\n")' "$hooks" 2>/dev/null || printf '')
  for g in $expected; do
    case "$registered" in
      *"$g"*) : ;;
      *) missing="${missing:+$missing }$g" ;;
    esac
  done
else
  missing="$expected"
fi

if [ -n "$missing" ]; then
  guards_present=false
else
  guards_present=true
fi

# Emit missing_guards as a JSON array (jq handles quoting; empty -> []).
missing_json=$(printf '%s\n' $missing | jq -R . | jq -sc 'map(select(length > 0))')

printf '{"ok": true, "version": "%s", "guards_present": %s, "missing_guards": %s}\n' \
  "$version" "$guards_present" "$missing_json"
