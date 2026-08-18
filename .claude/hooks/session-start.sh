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
# WITHOUT IT, EVERY CLOUD ROUTINE STOPS AT ITS OWN PRECONDITION. The [Implement] routine's
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
# `startup` matcher configured: an already-installed, CURRENT plugin exits before any
# network call, an already-registered marketplace is UPDATED rather than re-added
# (re-adding errors), and the update matters on its own -- `plugin install` does not
# refresh the local marketplace clone before resolving a name, so a stale clone fails
# with a misleading "not found".
#
# THE FAST PATH IS VERSION-GATED, NOT PRESENCE-GATED (2026-08-04). Cloud container
# images bake a marketplace clone in, so "installed" can mean v1.0.112 against a
# v1.0.123 repository -- and presence-only skipping made that permanent: the stale
# copy's pre-K1 mission migration ran K1 backwards on every prompt, dirtied the tree,
# and aborted every hourly drive tick for two days while this hook logged "already
# installed; skip". The wanted version is read from this checkout's own
# .claude-plugin/marketplace.json (fresh by construction -- cloning the repo is how
# the session started). In a consuming repository that manifest is absent, WANTED
# stays empty, and an installed plugin is REFRESHED rather than trusted -- staleness
# is just as real there and only the marketplace knows the current version, so the
# resume/clear/compact refires pay one marketplace fetch instead of risking a
# permanently stale install.
#
# A LONG-LIVED SESSION IS NOT REFRESHED, AND THAT IS THE ANSWER (2026-08-04). This hook
# runs at SessionStart and nowhere else, so a session that outlives a release keeps the
# build it started with for its whole life. That is deliberate rather than unfinished:
# swapping the plugin under a running session would change the code behind already-loaded
# skills and always-on hooks mid-turn, which is a worse failure than being one version
# behind, and there is no signal to hang a mid-session refresh on that is not just "poll".
# The drift is made VISIBLE instead -- check-deps/scripts/check.sh reports `version` beside
# `checkout_version` and flags `version_drift`, and /drive prints it in the run report. So
# the contract is: this hook makes the install correct AT SESSION START; check-deps makes
# it honest afterwards.
#
# WHAT THE VERSION GATE STILL CANNOT SEE. WANTED is read from this checkout, and a cloud
# container's clone can ITSELF be behind the base -- in which case a stale clone and a
# stale baked-in install agree, and this fast path skips exactly when it should not. That
# is how this container reached a matching 1.0.112/1.0.112 pair while origin/main was on
# 1.0.126. Fetching here to resolve it was rejected: SessionStart must stay fast and must
# never block a session on the network. /drive's own sync-main.sh fast-forwards the
# checkout a moment later, so the mismatch becomes visible to check-deps on that tick.
#
# WHY THE SUPERSEDED BINDING IS NOT REPAIRABLE FROM HERE, MEASURED (2026-08-05). The
# obvious candidate repair -- sweep the superseded version directories `plugin update`
# leaves behind -- was investigated and is the WRONG repair, because it misreads where the
# stale binding comes from. Observed on this machine:
# `~/.claude/plugins/cache/workaholic/workaholic/` holds 25 version directories side by
# side (1.0.100 … 1.0.133) while `installed_plugins.json` carries exactly ONE entry for
# the plugin, naming 1.0.133. So the registry is never ambiguous and a session never
# "picks the wrong directory": it binds whatever the registry named AT STARTUP, which is
# strictly before this hook can run. When a container's baked-in image is behind, the
# session binds the stale build, this hook then updates the registry to the current one,
# and check.sh correctly reports `loaded_version_behind_registry` for the rest of that
# session's life -- the update landed ~85s before the 2026-08-04T22:58Z session's first
# commit, which is exactly this ordering.
#
# Two consequences, and the second is the outage. Deleting superseded directories would
# repair nothing (the binding was not a choice among them) and would be actively unsafe,
# since a running session is bound to a directory that becomes "superseded" the instant an
# update lands -- the precise failure the no-mid-session-refresh rule above exists to
# prevent. And because every tick is a FRESH container off the same image, a stale image
# reproduces the condition every hour rather than self-healing: four consecutive ticks on
# 2026-08-05 stopped at /drive's §1 gate with a claimable queue.
#
# So there is no safe repair inside the plugin, and that is the recorded outcome rather
# than a gap. The binding, the cache layout and the registry are all the harness's; a
# plugin editing any of them is reaching outside its own boundary. What would actually fix
# it is a container image whose baked install is not behind, or a harness that rebinds
# after SessionStart -- an ask, not a workaround.
#
# CORRECTION (2026-08-12): TWO SCOPES, AND THE HOOK ONLY UPDATES ONE. The paragraph above
# says installed_plugins.json "carries exactly ONE entry for the plugin". It no longer does,
# and that is the whole outage. Measured live: a `project`-scope entry pinned at v1.0.133
# (image commit 77c462d, 2026-08-06) alongside a `user`-scope entry -- and step 2 below
# reports "√ Plugin updated from 1.0.133 to 1.0.159 **for scope user**", leaving the
# project-scope pin, which is what the session binds, untouched. So the condition is not
# merely "the image is behind"; it is structurally unreachable from here, every hour,
# forever. Twelve consecutive [Implement] ticks stopped at /drive's gate with three
# claimable tickets queued before this was found.
#
# What changed in response is NOT this hook (the ordering above is unfixable from a
# SessionStart hook): the workflows stopped reaching through the binding at all.
# `check-deps/scripts/plugin-src.sh` resolves the newest plugin tree on the machine --
# checkout, registry installPath, clone, binding -- and /drive §1 runs from that, so a
# superseded or absent binding is a reported fact rather than a terminated tick. The gate
# still detects the condition correctly; it just no longer ends the run over it.
#
# THE SESSION GETS THE DEVELOPER'S GIT IDENTITY (2026-08-07). The web container's git
# identity is `noreply@anthropic.com`, and ticket/mission ownership is compared against
# `git config user.email` (gather/scripts/owns.sh) -- so on the first full routine-chain
# day a proposal's ticket carried the developer's own address in `assignees` and the
# developer's own [Implement] routine ended `ticket_owner_mismatch`, unable to claim the
# very ticket it existed to drive. The session pushes and merges AS the developer's GitHub
# account, yet git did not know who it was. Step 0b closes that at the provisioning seam:
# it resolves the session's GitHub login (`gh api user`) through the committed repo-root
# `.claude/git-identities` mapping (`<login>=<email>`, one per line, `#` comments
# tolerated; the emails are already public in git history, so the file discloses nothing
# new) and sets the REPO-LOCAL `git config user.email` and `user.name`. It acts ONLY when
# the current email is empty or an @anthropic.com default -- a developer's real local
# identity is never overwritten -- and, like the `gh` step, every branch is non-fatal with
# one legible log line: an absent mapping file, a missing `gh`, or a failed API call is
# the status quo, not a regression.
#
# THE NAME HALF WAS SHIPPED DEAD (2026-08-18). The `user.name` line above was guarded by
# `[ -z "$(git config user.name)" ]` -- the EFFECTIVE scope, which in a web container is
# the global `Claude` and never empty -- so it never executed once. GitHub renders the
# author NAME, so from outside the repository every routine commit read as Claude's while
# the email underneath was the developer's all along; attributability through the email is
# not what a reader sees. The guard now tests `git config --local user.name`, so a
# container's global default no longer reads as "the developer already chose a name" while
# a real repo-local name is still left alone, and the value prefers `gh api user --jq
# .name` over the login. Forward-only: history already on `main` keeps `Claude`, and a
# session already running keeps the name it started with -- the repair lands at the next
# session start. `user.name` stays cosmetic to every workaholic mechanism (ownership,
# claims and resumption all read `user.email`, which is why this is safe to move).
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

# 0) Provision `gh`, which the web container does not ship (2026-08-06).
# Fourteen plugin scripts shell out to it; the two that decide whether a cloud run can
# finish are publish-tree-pr.sh (pushes the branch, then reports `no_gh` instead of opening
# the pull request) and merge-pr.sh (cannot run at all), so every cloud `auto` unit was
# demoted to the PR path and every routine-published artifact waited for a human to open
# its PR by hand. Measured in the container: `gh` 2.45.0 is in Ubuntu noble universe, the
# session runs as root, and GH_TOKEN/GITHUB_TOKEN are already injected -- so the install is
# a package away and the resulting `gh` has credentials.
#
# EVERY PART OF IT IS NON-FATAL. This hook has no `set -e` and must never block a session
# from starting: `gh` still absent afterwards is exactly the status quo, not a regression,
# which is why the failure path logs one line and falls through rather than calling die().
# The `command -v gh` guard makes an already-provisioned container pay nothing and a
# resume/clear/compact refire a no-op.
if command -v gh >/dev/null 2>&1; then
  log "gh present ($(gh --version 2>/dev/null | head -n 1)); skip"
elif [ "$(id -u)" != "0" ]; then
  log "gh absent and not root; skipping install"
  echo "workaholic bootstrap: gh is not installed and this session is not root (see $LOG)"
else
  log "gh absent; installing from the distro archive"
  if run apt-get update && run apt-get install -y --no-install-recommends gh; then
    log "gh installed ($(gh --version 2>/dev/null | head -n 1))"
  else
    # Named, once, so a container where this cannot work says so here rather than
    # surfacing later as a `no_gh` at the first publish-tree-pr.sh call.
    echo "workaholic bootstrap: gh install failed; PR creation and merge will report no_gh (see $LOG)"
  fi
fi

# 0b) Give the session the developer's git identity (2026-08-07; the header carries the
# measurement). Runs before the version-gated fast path so a resume/clear/compact refire
# still repairs an unset identity; once the email is set the first case arm makes every
# later fire a single `git config` read. Every branch non-fatal, one log line each way.
GIT_EMAIL=$(git config user.email 2>/dev/null || true)
IDMAP="${CLAUDE_PROJECT_DIR:-.}/.claude/git-identities"
case "$GIT_EMAIL" in
""|*@anthropic.com)
  if [ ! -f "$IDMAP" ]; then
    log "git identity: no mapping file at ${IDMAP}; keeping '${GIT_EMAIL:-unset}'"
  elif ! command -v gh >/dev/null 2>&1; then
    log "git identity: gh unavailable; keeping '${GIT_EMAIL:-unset}'"
  else
    LOGIN=$(gh api user --jq .login 2>>"$LOG") || LOGIN=""
    case "$LOGIN" in
    "")
      log "git identity: could not resolve the GitHub login; keeping '${GIT_EMAIL:-unset}'"
      ;;
    *[!A-Za-z0-9-]*)
      # A login is interpolated into the sed lookup below; GitHub logins are
      # alphanumeric-plus-hyphen, so anything else is a malformed answer, not a user.
      log "git identity: unexpected login '${LOGIN}'; keeping '${GIT_EMAIL:-unset}'"
      ;;
    *)
      MAPPED=$(sed -n "s/^${LOGIN}=//p" "$IDMAP" | head -n 1)
      if [ -z "$MAPPED" ]; then
        log "git identity: no entry for '${LOGIN}' in ${IDMAP}; keeping '${GIT_EMAIL:-unset}'"
      elif git config user.email "$MAPPED" 2>>"$LOG"; then
        # The name is set on the same seam and under the same conditions as the email, and
        # its guard reads the LOCAL scope on purpose (2026-08-18): `git config user.name`
        # resolves the container's GLOBAL `Claude`, which is never empty, so this branch
        # never fired and GitHub -- which renders the name, not the email -- showed every
        # web commit as authored by Claude. A developer's own repo-local name is still
        # never overwritten. The value prefers the account's real name (the mapping file
        # carries none, and the login is already being fetched, so the success path costs
        # no extra round trip) and falls back to the login; `--jq` prints `null` for an
        # account that publishes no name, which is not a name either.
        if [ -z "$(git config --local user.name 2>/dev/null || true)" ]; then
          REALNAME=$(gh api user --jq .name 2>>"$LOG") || REALNAME=""
          case "$REALNAME" in ""|null) REALNAME="$LOGIN" ;; esac
          if git config user.name "$REALNAME" 2>>"$LOG"; then
            log "git identity: user.name set to ${REALNAME} (repo-local name was unset)"
          else
            log "git identity: setting user.name failed"
          fi
        else
          log "git identity: repo-local user.name kept"
        fi
        log "git identity: user.email set to ${MAPPED} (login ${LOGIN})"
      else
        log "git identity: git config failed; keeping '${GIT_EMAIL:-unset}'"
      fi
      ;;
    esac
  fi
  ;;
*)
  log "git identity: real local identity '${GIT_EMAIL}' kept"
  ;;
esac

# Already installed at the version this checkout wants: skip the network round-trip.
# Presence alone never skips -- see the header on the version gate.
WANTED=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "${CLAUDE_PROJECT_DIR:-.}/.claude-plugin/marketplace.json" 2>/dev/null | head -n 1)
INSTALLED=$(claude plugin list 2>/dev/null | grep -A 2 "$PLUGIN" | sed -n 's/^ *Version: *\([0-9][0-9.]*\).*/\1/p' | head -n 1)
if [ -n "$INSTALLED" ] && [ -n "$WANTED" ] && [ "$INSTALLED" = "$WANTED" ]; then
  log "already installed at $INSTALLED (matches wanted); skip"
  exit 0
fi
log "installed='${INSTALLED:-none}' wanted='${WANTED:-unknown}'; refreshing"

# 1) Register the marketplace, or refresh it when already registered.
if claude plugin marketplace list 2>/dev/null | grep -q "$MP"; then
  run claude plugin marketplace update "$MP" || true   # try the install regardless
else
  run claude plugin marketplace add qmu/workaholic || die "marketplace add failed"
fi

# 2) Install, or update a stale install (user scope is the default).
if [ -n "$INSTALLED" ]; then
  run claude plugin update "$PLUGIN" || die "update failed"
else
  run claude plugin install "$PLUGIN" || die "install failed"
fi

# 3) Verify.
run claude plugin list || true
echo "workaholic installed. Run /reload-plugins if its commands aren't available yet."
exit 0
