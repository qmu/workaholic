#!/bin/sh -eu
# stop-loops.sh — END THE LOCAL LOOPS: kill each declared loop's tmux session. The clones
# are left standing (a claim worktree mid-drive is the claim protocol's to reason about, and
# the next spawn fetches and resets the base). Idempotent: a session already gone reports
# `already_stopped`.
#
# Usage: stop-loops.sh [--only <loop>[,<loop>]] [--repo-name <name>]
# Output: {ok, repo_name, loops: [{loop, session, state: stopped|already_stopped|refused, reason}]}

REPO_NAME=""; ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY="${2:-}"; shift ;;
    --repo-name) REPO_NAME="${2:-}"; shift ;;
    *) printf '{"ok": false, "reason": "bad_argument", "detail": "%s"}\n' "$1"; exit 0 ;;
  esac
  shift
done
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/loop-table.sh"
if [ -z "$REPO_NAME" ]; then
  url="$(git config --get remote.origin.url 2>/dev/null || true)"
  REPO_NAME="$(printf '%s' "$url" | sed -e 's|/*$||' -e 's|\.git$||' -e 's|.*[/:]||')"
fi
[ -n "$REPO_NAME" ] || { printf '{"ok": false, "reason": "no_repo_name"}\n'; exit 0; }
command -v tmux >/dev/null 2>&1 || { printf '{"ok": false, "reason": "no_tmux"}\n'; exit 0; }

rows=""
for spec in $(loop_table | tr ' ' '\001'); do
  loop="$(printf '%s' "$spec" | cut -d'|' -f1)"
  if [ -n "$ONLY" ]; then case ",$ONLY," in *",$loop,"*) ;; *) continue ;; esac; fi
  session="wh-${REPO_NAME}-${loop}"
  if tmux has-session -t "$session" 2>/dev/null; then
    if tmux kill-session -t "$session" 2>/dev/null; then state=stopped; reason=""; else state=refused; reason=kill_failed; fi
  else
    state=already_stopped; reason=""
  fi
  row="{\"loop\": \"${loop}\", \"session\": \"${session}\", \"state\": \"${state}\", \"reason\": \"${reason}\"}"
  rows="${rows:+${rows}, }${row}"
done
printf '{"ok": true, "repo_name": "%s", "loops": [%s]}\n' "$REPO_NAME" "$rows"
