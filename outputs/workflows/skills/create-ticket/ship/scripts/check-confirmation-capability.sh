#!/bin/sh -eu
# Check whether the current ship environment has the tooling a deployment
# target's confirmation_method needs, BEFORE the deploy procedure runs.
#
# The /ship deployment-confirmation gate executes a confirmation by method
# (browser | server-batch | db-query | api-probe | other). In a headless or CI
# ship context the required tooling may be absent, so a target with a declared
# method can still be unconfirmable at run time -- forcing the post-deploy halt.
# This ADVISORY check warns early and steers toward a method executable in the
# current environment. It does NOT replace the §1-4 hard gate and never blocks
# on its own; the caller surfaces the warning and decides.
#
# Usage: bash check-confirmation-capability.sh <method>
# Output: JSON {"method": "...", "capable": <bool>, "missing": "...", "hint": "..."}

METHOD="${1:-}"

if [ -z "$METHOD" ]; then
  echo '{"error": "confirmation method is required"}' >&2
  exit 1
fi

has() { command -v "$1" >/dev/null 2>&1; }
emit() { printf '{"method": "%s", "capable": %s, "missing": "%s", "hint": "%s"}\n' "$METHOD" "$1" "$2" "$3"; }

case "$METHOD" in
  api-probe)
    if has curl || has wget; then
      emit true "" "curl/wget present; api-probe runs headless."
    else
      emit false "curl or wget" "Install curl (or wget), or ship where an HTTP client is available."
    fi
    ;;
  db-query)
    if has psql || has mysql || has sqlite3 || has mongosh || has mongo; then
      emit true "" "A database client is present; db-query runs headless."
    else
      emit false "a database client (psql/mysql/sqlite3/mongosh)" "Install the target database client, or declare a method this environment can run."
    fi
    ;;
  server-batch)
    if has ssh; then
      emit true "" "ssh present; supply credentials transiently at ship time (never persisted)."
    else
      emit false "ssh" "Install/enable ssh, or declare a method this environment can run."
    fi
    ;;
  browser)
    if [ -n "${CI:-}" ]; then
      emit false "an interactive agent with browser tooling" "browser confirmations assume an interactive agent; in CI prefer api-probe or db-query."
    else
      emit true "" "browser confirmations assume an interactive agent with browser tooling."
    fi
    ;;
  other)
    emit true "" "Project-defined method; ensure its ## Confirmation tooling is available in this ship environment."
    ;;
  *)
    emit false "unknown method" "confirmation_method must be one of browser|server-batch|db-query|api-probe|other."
    ;;
esac
