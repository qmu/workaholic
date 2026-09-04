#!/bin/sh -eu
# Plugin-owned external clock for Codex CLI/IDE. Repository entrypoints are thin shims.

INTERVAL=300
ONCE=false
DRY_RUN=false
LOG_DIR=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --interval) INTERVAL="${2:-300}"; shift 2 ;;
        --once) ONCE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --log) LOG_DIR="${2:-}"; shift 2 ;;
        -h|--help)
            printf '%s\n' \
                'Usage: sh <installed-launcher> [--interval <seconds>] [--once] [--dry-run] [--log <dir>]' \
                '  --interval  seconds between completed ticks (default 300)' \
                '  --once      execute one tick and exit' \
                '  --dry-run   print the command without executing it' \
                '  --log       transcript directory (default <repository>/.codex-loop)'
            exit 0 ;;
        *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done

case "$INTERVAL" in ''|*[!0-9]*) printf 'interval must be whole seconds\n' >&2; exit 2 ;; esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/../../.." && pwd)
TICK_PROMPT="${PLUGIN_ROOT}/skills/work/SKILL.md"
COMMAND_BODY="${PLUGIN_ROOT}/commands/infinite-development.md"

if [ ! -f "$TICK_PROMPT" ]; then
    printf 'plugin_skill_missing: %s\n' "$TICK_PROMPT" >&2
    printf 'Update or reinstall the Workaholic plugin; its work skill is incomplete.\n' >&2
    exit 2
fi
if [ ! -f "$COMMAND_BODY" ]; then
    printf 'plugin_command_missing: %s\n' "$COMMAND_BODY" >&2
    printf 'Update or reinstall the Workaholic plugin; its tick command body is incomplete.\n' >&2
    exit 2
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$REPO_ROOT" ] || { printf 'repository_missing: run the launcher inside a git repository\n' >&2; exit 2; }
[ -z "$LOG_DIR" ] && LOG_DIR="${REPO_ROOT}/.codex-loop"
command -v codex >/dev/null 2>&1 || { printf 'codex_cli_missing: the codex CLI is not on PATH\n' >&2; exit 2; }

SETTINGS="${REPO_ROOT}/.claude/settings.json"
ENV_SOURCE="none"
if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
    if _pairs=$(jq -r '(.env // {}) | to_entries[] | "\(.key)=\(.value)"' "$SETTINGS" 2>/dev/null); then
        ENV_SOURCE="settings"
        for _pair in $_pairs; do
            _k=${_pair%%=*}
            _v=${_pair#*=}
            case "$_k" in CLAUDE_*) continue ;; esac
            case "$_k" in [A-Za-z_][A-Za-z0-9_]*) ;; *) continue ;; esac
            eval "_cur=\${${_k}:-}"
            [ -n "${_cur}" ] || export "${_k}=${_v}"
        done
    else
        ENV_SOURCE="unreadable"
    fi
fi

mkdir -p "$LOG_DIR"

run_tick() {
    _stamp=$(date -u +%Y%m%dT%H%M%SZ)
    _out="${LOG_DIR}/${_stamp}.md"
    _prompt="Read ${TICK_PROMPT} in full and execute exactly one tick of the development loop as it specifies, applying its substitutions for an agent with no interval feature and no background subagents. Do not loop; end after one tick. Report the tick's own report block as your final message."
    if [ "$DRY_RUN" = true ]; then
        printf 'codex exec -C %s --dangerously-bypass-approvals-and-sandbox --output-last-message %s <prompt>\n' "$REPO_ROOT" "$_out"
        return 0
    fi
    codex exec -C "$REPO_ROOT" --dangerously-bypass-approvals-and-sandbox \
        -c shell_environment_policy.inherit=all --output-last-message "$_out" "$_prompt" ||
        printf 'tick exited non-zero; the supervisor continues\n' >&2
}

printf 'codex loop: interval=%ss once=%s env=%s log=%s\n' "$INTERVAL" "$ONCE" "$ENV_SOURCE" "$LOG_DIR" >&2
LOCK="${LOG_DIR}/.supervisor.lock"
if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK"
    flock -n 9 || { printf 'another codex loop already holds %s\n' "$LOCK" >&2; exit 3; }
else
    printf 'flock is not installed: a second supervisor would not be refused\n' >&2
fi

while :; do
    run_tick
    [ "$ONCE" = true ] && break
    sleep "$INTERVAL"
done
