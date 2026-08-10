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
# THE SECOND DRIFT AXIS: LOADED vs REGISTRY (2026-08-05). The paragraph above was
# written when the only known drift was loaded-vs-checkout, and it left a blind spot in
# exactly the case it was designed for. A session can bind ${CLAUDE_PLUGIN_ROOT} to a
# SUPERSEDED cache directory: `plugin update` unpacks the new version beside the old one
# and does not delete the old one, so both exist and an already-bound session keeps the
# one it has. The SessionStart bootstrap cannot help -- it is decided that it never
# refreshes a running session.
#
# Measured on the 2026-08-04T22:58Z hourly tick: the registry recorded 1.0.129, updated
# ~85 seconds before the session's first commit, and the session nonetheless ran 1.0.112.
# That version's claims.sh predates the rename-following resolution and the
# `queue_drained` verdict, so the survey called five already-driven tickets fresh backlog
# and the tick CLAIMED one of them -- a double-pick reaching a pushed ref, which is the
# precise failure the claim protocol exists to prevent. It was caught only because the
# runner cross-checked by hand.
#
# THE REPORTER MUST NOT BE THE THING IT REPORTS ON, so neither operand is plugin content:
# the loaded version comes from ${CLAUDE_PLUGIN_ROOT} (what this session actually bound)
# and the wanted version from ~/.claude/plugins/installed_plugins.json (what the harness
# installed). Both are environment facts, so the comparison is as trustworthy as the
# reader's own age allows.
#
# Note what changed and why it matters: `version` used to be read from the manifest
# beside THIS SCRIPT, which answers "where is this file" and not "what did the session
# load". Running check.sh from a checkout while the session ran a stale cache reported a
# confident, matching pair -- the reporter agreeing with itself. When
# ${CLAUDE_PLUGIN_ROOT} is set it is now authoritative for `version`.
#
# UNLIKE checkout drift, THIS ONE IS A STOP, not a warning (see drive/SKILL.md §1). The
# distinction is what the drift can do: a checkout that moved means the run may be
# missing a fix, while a superseded binding silently changes the SURVEY'S ANSWER, and the
# run's next action on that answer is a push. `ok` stays true here -- this script is a
# diagnostic and does not decide the run's fate -- but the caller must refuse to survey.
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

# ...EXCEPT when the harness tells us what it actually bound. The script's own location
# answers "where is this file", which is a different question from "what is this session
# running", and the two diverge in precisely the case worth catching.
#
# THE ENV VAR IS NOT HOW THE SANCTIONED CALLER ARRIVES, and reading only it left the
# gate LOCAL-ONLY SILENT (2026-08-06). The harness expands ${CLAUDE_PLUGIN_ROOT} inside
# plugin markdown at load time -- a literal path in the command body, not an exported
# variable -- and in a LOCAL session no variable reaches the Bash tool's environment, so
# /drive's own step-0 invocation landed in the silent branch and the one pre-flight stop
# never fired locally. (The cloud container DOES export it: the 2026-08-06 02:59 JST
# tick fired this exact gate.) The repair: when the env var is absent but this script's
# own resolved path sits inside the harness's plugin cache, that path IS the binding --
# the caller reached it through the expanded token, so "where is this file" and "what is
# this session running" are the same answer. A checkout or bundle invocation matches
# neither and stays silent, which keeps the false-accusation case answered:
# a non-Claude agent or a developer running an old checkout is still never accused of
# drift it cannot have. `loaded_root_source` reports which case decided.
loaded_root="${CLAUDE_PLUGIN_ROOT:-}"
loaded_root_source="none"
if [ -n "$loaded_root" ] && [ -d "$loaded_root" ]; then
  root="$loaded_root"
  loaded_root_source="env"
else
  cache_prefix="${CLAUDE_PLUGIN_CACHE:-${HOME}/.claude/plugins/cache}"
  case "$root" in
    "${cache_prefix}"/*)
      loaded_root="$root"
      loaded_root_source="cache_path"
      ;;
  esac
fi

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

# --- Loaded vs registry -------------------------------------------------------------
# Only meaningful when the harness bound a plugin root. Without one (a non-Claude agent,
# the generated bundle, a direct checkout invocation) there is no "what the session
# loaded" to compare, so the whole axis stays silent rather than inventing a verdict.
registry_version=""
registry_unreadable=false
loaded_version_behind_registry=false

if [ -n "$loaded_root" ]; then
  registry="${CLAUDE_PLUGIN_REGISTRY:-${HOME}/.claude/plugins/installed_plugins.json}"
  if [ -f "$registry" ]; then
    # The scope array can hold more than one install; take the newest version present,
    # because that is what an update would have left and what the session ought to bind.
    registry_version=$(jq -r '
        (.plugins["workaholic@workaholic"] // [])
        | map(.version // empty) | max // ""
      ' "$registry" 2>/dev/null || printf '')
    [ -n "$registry_version" ] || registry_unreadable=true
  else
    registry_unreadable=true
  fi

  # "Behind" is ordered, not merely different: a loaded version AHEAD of the registry is
  # a developer running a local build, which is deliberate and must not be reported as
  # the failure this exists to catch.
  if [ "$registry_unreadable" = false ] && [ "$version" != "$registry_version" ]; then
    older=$(printf '%s\n%s\n' "$version" "$registry_version" | sort -V 2>/dev/null | head -n 1)
    if [ "$older" = "$version" ]; then
      loaded_version_behind_registry=true
    fi
  fi
fi

# --- Unbound in a genuine Claude Code session (the fresh-install/no-reload gap, FB
# 20260807104046) ------------------------------------------------------------------
# SessionStart may install/update the plugin, but nothing makes that binding
# effective for the REST of that session: Claude Code exposes no supported mechanism
# to hot-load a plugin mid-session (only a human-typed /reload-plugins does, per
# https://code.claude.com/docs/en/plugins-reference.md#plugin-updates-and-caching --
# hooks, MCP servers and LSP servers keep the previous binding until reload), and an
# unattended routine never types that command. The measured symptom is total: no
# plugin root is EVER bound (loaded_root_source stays "none" above), so every
# skill/command/hook the plugin ships is invisible for the whole run -- not merely
# stale, as the two axes above cover, but entirely absent.
#
# This runs INDEPENDENTLY of loaded_root_source's value (rather than nested inside
# the "when a root IS bound" branch above), because the whole question is "was this
# genuinely a Claude Code session that should have bound one, but did not" -- which
# only arises when nothing was bound.
#
# Three facts, none of them plugin content, distinguish the fresh-install gap from a
# session that legitimately has no root bound (a non-Claude agent, a developer's bare
# checkout invocation):
#   1. This IS a Claude Code session (CLAUDE_CODE_SESSION_ID is a harness-set env var
#      present on both local and cloud sessions, present regardless of plugin state).
#   2. No plugin root was bound (loaded_root_source == "none", computed above).
#   3. The harness's OWN registry confirms an install exists for this plugin -- so the
#      gap is "installed but never bound this session", not "never installed".
#
# KNOWN LIMIT, same shape as every diagnostic in this script: a developer who runs
# this script directly via its literal path in an otherwise-healthy, fully-bound
# session ALSO shows loaded_root_source == "none" for that one invocation (the
# ${CLAUDE_PLUGIN_ROOT} substitution happens in command-body text, not as a process
# env var), so this can false-positive there. Over-reporting is the accepted
# direction throughout this script's registry axis (a stale reader over-reports
# claims elsewhere in the project for the identical reason) -- the run pays a
# possibly-unnecessary `pending` rather than proceeding on a broken assumption.
claude_session_detected=false
[ -n "${CLAUDE_CODE_SESSION_ID:-}" ] && claude_session_detected=true

registry_has_install=false
probe_registry="${CLAUDE_PLUGIN_REGISTRY:-${HOME}/.claude/plugins/installed_plugins.json}"
if [ -f "$probe_registry" ]; then
  probe_count=$(jq -r '(.plugins["workaholic@workaholic"] // []) | length' "$probe_registry" 2>/dev/null || printf '0')
  case "$probe_count" in
    ''|*[!0-9]*) probe_count=0 ;;
  esac
  [ "$probe_count" -gt 0 ] && registry_has_install=true
fi

unbound_in_claude_session=false
if [ "$loaded_root_source" = "none" ] && [ "$claude_session_detected" = true ] && [ "$registry_has_install" = true ]; then
  unbound_in_claude_session=true
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

printf '{"ok": true, "version": "%s", "checkout_version": "%s", "version_drift": %s, "loaded_root_source": "%s", "registry_version": "%s", "registry_unreadable": %s, "loaded_version_behind_registry": %s, "claude_session_detected": %s, "registry_has_install": %s, "unbound_in_claude_session": %s, "guards_present": %s, "missing_guards": %s}\n' \
  "$version" "$checkout_version" "$version_drift" "$loaded_root_source" "$registry_version" "$registry_unreadable" \
  "$loaded_version_behind_registry" "$claude_session_detected" "$registry_has_install" "$unbound_in_claude_session" \
  "$guards_present" "$missing_json"
