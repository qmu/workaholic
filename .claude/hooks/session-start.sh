#!/bin/sh
# Install the workaholic plugin into a Claude Code **web** session.
#
# Registered as a SessionStart hook (matcher `startup`) in a consuming repository's
# .claude/settings.json. The canonical copy is this file; /workaholify installs it and
# reports drift against it.
#
# WHY THIS IS NEEDED AT ALL. Claude Code on the web starts each session in a fresh,
# ephemeral container. `enabledPlugins` / `extraKnownMarketplaces` in .claude/settings.json
# are NOT fetched and installed automatically there -- the plugin must be installed
# explicitly, before the session's skill registry is built. A local session keeps a
# persistent ~/.claude, so this is a no-op outside the web.
#
# WITHOUT IT, EVERY CLOUD ROUTINE STOPS AT ITS OWN PRECONDITION. The [Drive] routine's
# prompt says "the workaholic plugin must be loaded ... if it is not, post the failure and
# stop" -- so an unbootstrapped repository schedules the routine, fires it on time, and
# does nothing, which looks healthy from the routines list.
#
# ---- The corrections this version carries (qmu/workaholic#126) ----
#
# FAIL OPEN, DELIBERATELY: no `set -e`. This hook must never block a session from
# starting; every failure path exits 0 with a message. It is POSIX `#!/bin/sh` like every
# other script here (a container may have no bash at all), which is why `set -u` stands
# alone rather than the repo's usual `-eu`.
#
# NO `{ ... } || echo FAILED`. In that shape `set -e` is suppressed inside the group
# (errexit is ignored for every command of an `&&`/`||` list except the last), so a failed
# `marketplace add` did not stop the script, the trailing `echo OK` made the group exit 0,
# and the log reported OK on total failure. The verification defeated itself. Each step is
# status-checked explicitly instead.
#
# NO `marketplace add --scope user`. `--scope` is documented for `plugin install`, not for
# `marketplace add` -- and `plugin install` already defaults to user scope, so it is
# redundant there too. The resulting "unknown option" error was exactly what the bug above
# swallowed.
#
# IDEMPOTENT, because SessionStart also fires on resume/clear/compact even with the
# `startup` matcher configured: an already-installed plugin exits before any network call,
# an already-registered marketplace is UPDATED rather than re-added (re-adding errors), and
# the update matters on its own -- `plugin install` does not refresh the local marketplace
# clone before resolving a name, so a stale clone fails with a misleading "not found".
#
# HOME IS RESPECTED, NOT IMPOSED (`: "${HOME:=/root}"`): hardcoding /root breaks the moment
# the hook runs as a non-root user, whose ~/.claude would be unwritable.
#
# THE LOG GOES TO TMPDIR, not /var/log -- not writable as non-root, and unbounded across
# sessions. Output is redirected there rather than to stdout so it never pollutes the
# session context; the single stdout line at the end is deliberate, because a plugin
# installed during SessionStart is not active until /reload-plugins and the developer has
# to be told.

# `set -u` only, and NO `-e`: this hook must never block a session from starting, so every
# failure path is handled explicitly and exits 0. (`pipefail` is dropped with bash — it is
# not POSIX, and nothing here pipes a command whose failure would otherwise be lost.)
set -u

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

: "${HOME:=/root}"; export HOME
LOG="${TMPDIR:-/tmp}/bootstrap-workaholic.log"
MP=workaholic
PLUGIN="workaholic@${MP}"

log() { printf '%s %s\n' "$(date -Is)" "$*" >>"$LOG"; }
run() { log "\$ $*"; "$@" >>"$LOG" 2>&1 || { log "FAILED: $*"; return 1; }; }
die() { echo "workaholic bootstrap: $1 (see $LOG)"; exit 0; }  # exit 0 = fail open

log "=== bootstrap (claude $(claude --version 2>/dev/null || echo unknown)) ==="

# Already installed: skip the network round-trip entirely.
if claude plugin list 2>/dev/null | grep -q "$PLUGIN"; then
  log "already installed; skip"
  exit 0
fi

# 1) Register the marketplace, or refresh it when already registered.
if claude plugin marketplace list 2>/dev/null | grep -q "$MP"; then
  run claude plugin marketplace update "$MP" || true   # try the install regardless
else
  run claude plugin marketplace add qmu/workaholic || die "marketplace add failed"
fi

# 2) Install (user scope is the default).
run claude plugin install "$PLUGIN" || die "install failed"

# 3) Verify.
run claude plugin list || true
echo "workaholic installed. Run /reload-plugins if its commands aren't available yet."
exit 0
