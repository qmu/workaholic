#!/bin/sh -eu
# The machine the tick is about to start runners on.
#
# WHY IT EXISTS (2026-09-03, mission `decide-each-tick-s-allocation-from-what-the-tick-just-read`).
# The tick decides how many runners to start and read nothing about the machine it starts them
# on: `commands/infinite-development.md` §2 read `ListAgents` and three cadences, and core count
# and load appeared nowhere. Measured mid-fan-out on the machine the loop runs on: three
# concurrent `implement` runners on a **four-core** machine at loadavg `7.99 / 6.42 / 5.60`. The
# fifteen-minute figure says it had been over capacity for a while rather than spiking.
#
# THE OTHER TWO RESOURCES ARE NAMED SO THE READING IS NOT OVER-CLAIMED. In that same measurement
# memory was half free (8090 MB available of 16218) and the SoC was not throttling (64.2 °C,
# `throttled=0x0`), so **CPU was the binding resource**. This reader answers about CPU alone and
# says so, rather than pretending to a general verdict about the machine's health.
#
# THIS TICKET ADDS THE READING AND NOTHING ELSE. No consumer reads it; it changes no decision, so
# it can land and be wrong about nothing. The bound that will read it is declared separately, in
# `.claude/settings.json`, by the operator who measured `7.99` on four cores — this file picks no
# number for any machine.
#
# A READING THAT COULD NOT BE MADE ANSWERS `null`, NEVER `0`. A zero load reads as *an idle
# machine*, which is the one answer that would make a consumer fan out hardest at exactly the
# moment it must not. Reasons: `no_loadavg`, `no_core_count`, `unparseable`.
#
# `readable` IS ABSENT ON A SUCCESSFUL READ — the `merge_policy` / `status:` convention this
# repository already holds: absent means it completed, so a consumer tests `readable == false`
# and never `readable // true`.
#
# Usage: read-machine-load.sh
#   WORKAHOLIC_LOADAVG_PATH  the file `load1` is read from (default `/proc/loadavg`); it exists
#                            so the failure path is exercisable rather than only argued about.
# Output: one JSON line
#   {"cores": n, "load1": f, "load_per_core": f}
#   {"cores": null, "load1": null, "load_per_core": null, "readable": false, "reason": "<word>"}
#
# PURE READ. It runs no command outside `nproc` / `getconf`, opens no network connection, writes
# nothing anywhere, and exits 0 in every case.

set -eu

LOADAVG="${WORKAHOLIC_LOADAVG_PATH:-/proc/loadavg}"

emit_unreadable() {
    printf '{"cores": null, "load1": null, "load_per_core": null, "readable": false, "reason": "%s"}\n' "$1"
    exit 0
}

cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || true)
case "${cores:-}" in
    ''|*[!0-9]*) emit_unreadable no_core_count ;;
    0) emit_unreadable no_core_count ;;
esac

[ -r "$LOADAVG" ] || emit_unreadable no_loadavg
line=$(cat "$LOADAVG" 2>/dev/null || true)
[ -n "$line" ] || emit_unreadable no_loadavg

load1=$(printf '%s' "$line" | awk '{print $1}')
# A load average is a decimal with one leading integer part; anything else is not one, and
# guessing at it would put a fabricated number in front of a bound.
case "$load1" in
    ''|*[!0-9.]*|*.*.*) emit_unreadable unparseable ;;
esac

per_core=$(awk -v l="$load1" -v c="$cores" 'BEGIN { if (c <= 0) exit 1; printf "%.2f", l / c }' 2>/dev/null) \
    || emit_unreadable unparseable
[ -n "$per_core" ] || emit_unreadable unparseable

printf '{"cores": %s, "load1": %s, "load_per_core": %s}\n' "$cores" "$load1" "$per_core"
