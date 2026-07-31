#!/bin/sh -eu
# Nudge the developer to re-run /workaholify when this repository's declared routines are
# not provisioned on this machine. Non-blocking on both events; silent when there is
# nothing to act on.
#
# Registered on UserPromptSubmit (model-visible additionalContext) and Stop
# (user-visible systemMessage), the same two-event shape as mission-lens.sh and for the
# same reason: a Stop hook cannot inject model-visible context without `decision: block`,
# which would force the agent to keep working.
#
# WHY A NUDGE AT ALL. Provisioning drifts in one direction that nobody notices: a routine
# added to the repository after a developer set up their machine never reaches that
# machine, and nothing fails — the routine simply does not run, which looks exactly like
# a quiet week. The repository knows what it wants (`.workaholic/routines/`) and the
# machine knows what it has (the crontab); only something that compares them can say so.
#
# SILENCE IS THE DEFAULT, AND THE SILENCE CONDITION IS THE DESIGN. This line prints
# unasked, directly above the agent's answer. It says nothing when the survey reports no
# drift, when the repository declares no routines, and when the survey cannot run at all.
# The mission lens's signal gate is the precedent: say nothing rather than say something
# with no action attached.
#
# ONCE PER SESSION PER EVENT. A nudge that repeats every turn is one a developer learns
# to skip, which is worse than not nudging: the drift stops being information. The marker
# lives under TMPDIR keyed by session and event, mirroring mission-lens.sh's dedupe. With
# no session_id (bare harness, tests) it emits every time rather than never — a missing
# id must not silence a real warning.
#
# IT NEVER PROVISIONS ANYTHING. This hook reads; `install-routine.sh` writes, and refuses
# outside an interactive context. A hook that installed a crontab would be the exact
# unattended standing-schedule write both runbooks prohibit.

set -eu

PLUGIN_ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
SURVEY="${PLUGIN_ROOT}/skills/workaholify/scripts/survey-routines.sh"

payload=$(cat 2>/dev/null || true)
event=$(printf '%s' "$payload" | sed -n 's/.*"hook_event_name"[ ]*:[ ]*"\([^"]*\)".*/\1/p')
session=$(printf '%s' "$payload" | sed -n 's/.*"session_id"[ ]*:[ ]*"\([^"]*\)".*/\1/p')
[ -n "$event" ] || event="UserPromptSubmit"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null || exit 0)
[ -d "${root}/.workaholic/routines" ] || exit 0
[ -x "$SURVEY" ] || [ -f "$SURVEY" ] || exit 0

report=$(sh "$SURVEY" "$root" 2>/dev/null || true)
[ -n "$report" ] || exit 0

drift=$(printf '%s' "$report" | sed -n 's/.*"drift"[ ]*:[ ]*\([0-9]*\).*/\1/p')
count=$(printf '%s' "$report" | sed -n 's/.*"count"[ ]*:[ ]*\([0-9]*\).*/\1/p')
[ -n "$drift" ] || exit 0
[ "$drift" -gt 0 ] || exit 0
[ -n "$count" ] || count="$drift"

# Name the first drifting routine and its reason, so the line carries an action rather
# than only a count.
first=$(printf '%s' "$report" | tr '{' '\n' | grep '"matches": false' | head -1 || true)
name=$(printf '%s' "$first" | sed -n 's/.*"name"[ ]*:[ ]*"\([^"]*\)".*/\1/p')
reason=$(printf '%s' "$first" | sed -n 's/.*"drift_reason"[ ]*:[ ]*"\([^"]*\)".*/\1/p')
[ -n "$name" ] || name="a declared routine"
[ -n "$reason" ] || reason="not_installed"

msg="${drift} of ${count} declared routine(s) are not provisioned on this machine (${name}: ${reason}). Run /workaholify to review and install them."

# Once per session per event.
if [ -n "$session" ]; then
  marker_dir="${TMPDIR:-/tmp}/workaholic-routines-lens"
  mkdir -p "$marker_dir" 2>/dev/null || true
  marker="${marker_dir}/${session}.${event}"
  if [ -f "$marker" ]; then exit 0; fi
  : > "$marker" 2>/dev/null || true
fi

escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

if [ "$event" = "Stop" ]; then
  printf '{"systemMessage": "%s"}\n' "$(escape "$msg")"
else
  printf '{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "%s"}}\n' "$(escape "$msg")"
fi
exit 0
