#!/bin/sh -eu
# loop-status.sh — WHICH LOCAL LOOPS ARE RUNNING. Pure read: one row per declared loop with
# its tmux session's state and the last lines of its pane, so a person can see at a glance
# whether the loop is turning. Writes nothing.
#
# Usage: loop-status.sh [--repo-name <name>] [--lines <n>]
# Output: {ok, repo_name, loops: [{loop, session, path, running, exists, tail}]}

LOOPS_HOME="${WORKAHOLIC_LOOPS_HOME:-${HOME}/.workaholic/loops}"
REPO_NAME=""; LINES=5
while [ $# -gt 0 ]; do
  case "$1" in
    --repo-name) REPO_NAME="${2:-}"; shift ;;
    --lines) LINES="${2:-5}"; shift ;;
    *) printf '{"ok": false, "reason": "bad_argument", "detail": "%s"}\n' "$1"; exit 0 ;;
  esac
  shift
done
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/loop-table.sh"
json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {print}' | sed -e 's/\\n$//'; }

if [ -z "$REPO_NAME" ]; then
  url="$(git config --get remote.origin.url 2>/dev/null || true)"
  REPO_NAME="$(printf '%s' "$url" | sed -e 's|/*$||' -e 's|\.git$||' -e 's|.*[/:]||')"
fi
[ -n "$REPO_NAME" ] || { printf '{"ok": false, "reason": "no_repo_name"}\n'; exit 0; }

have_tmux=0; command -v tmux >/dev/null 2>&1 && have_tmux=1
rows=""
for spec in $(loop_table | tr ' ' '\001'); do
  loop="$(printf '%s' "$spec" | cut -d'|' -f1)"
  session="wh-${REPO_NAME}-${loop}"
  path="${LOOPS_HOME}/${REPO_NAME}/${loop}"
  running=false; tail=""
  exists=false; [ -d "${path}/.git" ] && exists=true
  if [ "$have_tmux" -eq 1 ] && tmux has-session -t "$session" 2>/dev/null; then
    running=true
    tail="$(tmux capture-pane -p -t "$session" 2>/dev/null | sed -e '/^[[:space:]]*$/d' | tail -n "$LINES" || true)"
  fi
  row="{\"loop\": \"${loop}\", \"session\": \"${session}\", \"path\": \"$(json_escape "$path")\", \"running\": ${running}, \"exists\": ${exists}, \"tail\": \"$(json_escape "$tail")\"}"
  rows="${rows:+${rows}, }${row}"
done
printf '{"ok": true, "repo_name": "%s", "tmux": %s, "loops": [%s]}\n' "$(json_escape "$REPO_NAME")" "$([ "$have_tmux" -eq 1 ] && echo true || echo false)" "$rows"
