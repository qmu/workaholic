#!/bin/sh -eu
# spawn-loops.sh — START THE LOCAL LOOPS: one tmux session per loop, each a Claude Code
# session running `/loop <interval> <prompt>` inside its own clone of this repository.
#
# Usage: spawn-loops.sh [--dry-run] [--only <loop>[,<loop>]] [--repo-url <url>]
#   --dry-run   plan everything, run nothing: prints one JSON line per loop naming the
#               clone path, the tmux session and the exact command, and exits 0.
#   --only      spawn a subset (default: every loop the table declares).
#   --repo-url  the clone source (default: this checkout's `origin`).
#
# Output: one JSON object
#   {ok, repo_name, home, loops: [{loop, interval, prompt, session, path,
#                                  state: spawned|already_running|planned|refused, reason}]}
#
# THE PREMISE THIS REPLACES (2026-09-02, the developer's instruction). The loop used to run
# as Claude Code Web routines — [Propose] :15, [Implement] :30, [Moderate] :50 — and the
# API's floor is one fire an hour, so one turn of the loop was one hour and a change to the
# loop could not be seen working for most of a day. The loops now run HERE, on the
# developer's own server, as ordinary interactive Claude Code sessions kept alive in tmux
# and driven by `/loop`; the interval is minutes, and a turn of the loop is a turn of the
# loop. The Web routines survive as the fallback for a machine that has no tmux
# (`/setup-dev-routines`, `/setup-repo-routines`), unchanged.
#
# ONE CLONE PER LOOP, AND THAT IS THE WHOLE ISOLATION. The propose loop and the implement
# loop fire minutes apart and would otherwise share one checkout: `/implement` fetches and
# resets the base, `/ship` checks it out after a merge, and `/specificate` opens a publish
# tree at `<root>/.publish` — three writers on one working tree. Each loop therefore runs in
# its own clone under `$WORKAHOLIC_LOOPS_HOME/<repo>/<loop>` (default `~/.workaholic/loops`),
# so its claim worktrees (`.worktrees/<unit>`) and its publish tree are its own; across
# loops, the remote is the only shared state, and the claim protocol already arbitrates
# that. Within one loop, `/loop` turns are sequential, so a loop never overlaps itself.
#
# THE LOOP TABLE IS DECLARED ONCE, HERE, AND READ BY THE OTHER TWO SCRIPTS. A cadence, a
# prompt and a name; nothing else. `moderate` stays in the loop at a slower beat rather than
# leaving it or folding into propose: its acts (retirement, closable missions, standing
# rulings, findings) are hourly by nature, and a 30-minute local tick reaches them with full
# `gh` and full `git` — none of the session-type refusals a Web container pays.
#
# THE SESSION RUNS WITH PERMISSION PROMPTS OFF. An unattended run never waits for a person
# (`rules/interaction.md`); on this server the sessions are the developer's own, in clones
# the developer owns, so `--dangerously-skip-permissions` is the honest spelling of that
# contract rather than an allowlist that has to enumerate every read the run will make.

LOOPS_HOME="${WORKAHOLIC_LOOPS_HOME:-${HOME}/.workaholic/loops}"
DRY=0
ONLY=""
REPO_URL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --only) ONLY="${2:-}"; shift ;;
    --repo-url) REPO_URL="${2:-}"; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) printf '{"ok": false, "reason": "bad_argument", "detail": "%s"}\n' "$1"; exit 0 ;;
  esac
  shift
done

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/loop-table.sh"

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

[ -n "$REPO_URL" ] || REPO_URL="$(git config --get remote.origin.url 2>/dev/null || true)"
if [ -z "$REPO_URL" ]; then
  printf '{"ok": false, "reason": "no_repo_url", "detail": "no origin remote and no --repo-url"}\n'; exit 0
fi
repo_name="$(printf '%s' "$REPO_URL" | sed -e 's|/*$||' -e 's|\.git$||' -e 's|.*[/:]||')"
[ -n "$repo_name" ] || { printf '{"ok": false, "reason": "no_repo_name", "detail": "%s"}\n' "$(json_escape "$REPO_URL")"; exit 0; }

if [ "$DRY" -eq 0 ] && ! command -v tmux >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "no_tmux", "detail": "tmux is not on PATH; the Web routines are the fallback (/setup-dev-routines)"}\n'; exit 0
fi
if [ "$DRY" -eq 0 ] && ! command -v claude >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "no_claude", "detail": "claude is not on PATH"}\n'; exit 0
fi

# THE TRUST DIALOG IS THE SECOND PROMPT AN UNATTENDED SESSION MUST NEVER SEE. A fresh clone
# whose `.claude/settings.json` carries permission rules makes Claude Code open "do you trust
# this folder?" before anything runs, and `--dangerously-skip-permissions` does not answer it
# (measured 2026-09-02: all three loops parked on it at their first spawn). Claude Code records
# the answer per project in `~/.claude.json` under `projects.<path>.hasTrustDialogAccepted`, so
# the spawn records it for the clone it is about to launch into — the developer's own clone on
# the developer's own server, which is the trust the dialog asks about. A `~/.claude.json` that
# cannot be read or written refuses the spawn (`trust_unwritable`) rather than park a session.
pre_trust() {
  _cfg="${HOME}/.claude.json"
  [ -f "$_cfg" ] || printf '{}\n' > "$_cfg" 2>/dev/null || return 1
  _tmp="${_cfg}.spawn.$$"
  jq --arg p "$1" '.projects = (.projects // {}) | .projects[$p] = ((.projects[$p] // {}) + {hasTrustDialogAccepted: true})' "$_cfg" > "$_tmp" 2>/dev/null || { rm -f "$_tmp"; return 1; }
  mv "$_tmp" "$_cfg"
}

# The plugin the session loads: this checkout's own tree when the repository IS the plugin
# (self-development), else whatever the harness binds (`plugin-src.sh` resolves the newest).
plugin_dir_arg() {
  if [ -d "$1/plugins/workaholic/.claude-plugin" ]; then
    printf -- "--plugin-dir '%s/plugins/workaholic' " "$1"
  fi
}

rows=""
loop_table | while IFS='|' read -r loop interval prompt; do
  [ -n "$loop" ] || continue
  if [ -n "$ONLY" ]; then
    case ",$ONLY," in *",$loop,"*) ;; *) continue ;; esac
  fi
  path="${LOOPS_HOME}/${repo_name}/${loop}"
  session="wh-${repo_name}-${loop}"
  state="planned"; reason=""
  cmd="cd '${path}' && claude --dangerously-skip-permissions $(plugin_dir_arg "$path")'/loop ${interval} ${prompt}'"
  if [ "$DRY" -eq 0 ]; then
    if tmux has-session -t "$session" 2>/dev/null; then
      state="already_running"
    else
      if [ ! -d "${path}/.git" ]; then
        mkdir -p "$(dirname "$path")"
        if ! git clone -q "$REPO_URL" "$path" 2>/dev/null; then
          state="refused"; reason="clone_failed"
        fi
      else
        ( cd "$path" && git fetch -q origin && git checkout -q main 2>/dev/null && git reset -q --hard origin/main ) 2>/dev/null \
          || { state="refused"; reason="fetch_failed"; }
      fi
      if [ "$state" = planned ] && ! pre_trust "$path"; then
        state="refused"; reason="trust_unwritable"
      fi
      if [ "$state" = planned ]; then
        cmd="cd '${path}' && claude --dangerously-skip-permissions $(plugin_dir_arg "$path")'/loop ${interval} ${prompt}'"
        if tmux new-session -d -s "$session" -c "$path" "$cmd" 2>/dev/null; then
          state="spawned"
        else
          state="refused"; reason="tmux_failed"
        fi
      fi
    fi
  fi
  printf '{"loop": "%s", "interval": "%s", "prompt": "%s", "session": "%s", "path": "%s", "state": "%s", "reason": "%s", "command": "%s"}\n' \
    "$loop" "$interval" "$(json_escape "$prompt")" "$session" "$(json_escape "$path")" "$state" "$reason" "$(json_escape "$cmd")"
done > "${TMPDIR:-/tmp}/spawn-loops.$$"

rows="$(paste -sd, "${TMPDIR:-/tmp}/spawn-loops.$$")"
rm -f "${TMPDIR:-/tmp}/spawn-loops.$$"
printf '{"ok": true, "repo_name": "%s", "home": "%s", "dry_run": %s, "loops": [%s]}\n' \
  "$(json_escape "$repo_name")" "$(json_escape "$LOOPS_HOME")" "$([ "$DRY" -eq 1 ] && echo true || echo false)" "$rows"
