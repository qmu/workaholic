#!/bin/sh -eu
# Check that required dependency plugins are installed, and surface diagnostics
# that make a stale or partial plugin install detectable.
#
# Workaholic is a single plugin (dependencies: []), so the dependency check is
# trivially satisfied (ok: true). Beyond that, when this script can locate the
# loaded plugin's manifest and hooks (i.e. it is running from the plugin tree on
# Claude Code), it additionally reports:
#   - version          the loaded plugin version, so a stale install is visible
#   - checkout_version the version THIS CHECKOUT wants ("" when not determinable)
#   - version_drift    true when both are known and differ
#   - guards_present   whether the three PreToolUse Bash guards are registered
#   - missing_guards   any expected guard not found in the loaded hooks.json
#
# WHY version ALONE WAS NOT ENOUGH (2026-08-04). The loaded version was already
# reported, but a bare "1.0.112" reads as healthy to anyone who does not happen to
# know what the repository is on. The drift that halted every hourly drive tick for
# two days was exactly this: a cloud image's baked-in v1.0.112 running its pre-K1
# mission migration BACKWARDS against a K1-era repository, dirtying the tree so
# sync-main.sh terminated `dirty_workspace` before the run could survey. Reporting
# both numbers turns "a version string" into "a mismatch a reader can act on".
#
# DRIFT IS A WARNING, NEVER A STOP (the decision, recorded here because the code is
# where it is enforced). A runner that refuses to work because its plugin is old is
# as useless as one that works wrongly, and drift is frequently harmless -- most
# releases touch nothing a given run reaches. The hard stop already exists where the
# drift actually bites: sync-main.sh terminates the run on the dirty tree a bad
# migration leaves. So `ok` stays true and the caller reports the drift.
#
# KNOWN LIMIT: checkout_version is read from the checkout as it is RIGHT NOW, and
# /drive runs this before sync-main.sh fast-forwards. A runner whose clone is itself
# behind the base therefore compares against a stale wanted-version and can agree
# with a stale install -- which is how this container reached a matching pair. That
# is not repaired here: this script is a diagnostic and must not mutate the checkout
# (it is the same reason plan-units.sh reports `current` rather than fixing it). The
# drift surfaces on the following tick, once the fast-forward has landed.
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

# The version THIS CHECKOUT wants. Prefer the harness-provided project dir; fall back
# to the git toplevel, then the cwd. A consuming repository carries no marketplace
# manifest, so an empty result is the normal case there -- and it must read as
# "not determinable", never as drift.
project="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$project" ]; then
  project=$(git rev-parse --show-toplevel 2>/dev/null || printf '.')
fi
checkout_version=""
if [ -f "${project}/.claude-plugin/marketplace.json" ]; then
  checkout_version=$(jq -r '.version // ""' "${project}/.claude-plugin/marketplace.json" 2>/dev/null || printf '')
fi

# Drift needs BOTH numbers. One unknown side is silence, not an accusation.
if [ -n "$checkout_version" ] && [ "$checkout_version" != "$version" ]; then
  version_drift=true
else
  version_drift=false
fi

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

printf '{"ok": true, "version": "%s", "checkout_version": "%s", "version_drift": %s, "guards_present": %s, "missing_guards": %s}\n' \
  "$version" "$checkout_version" "$version_drift" "$guards_present" "$missing_json"
