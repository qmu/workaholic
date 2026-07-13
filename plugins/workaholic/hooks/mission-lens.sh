#!/bin/sh -eu
# Mission lens -- always-on re-anchoring on the roadmap.
#
# Fires on two events, both NON-FORCING (it never blocks a stop; it informs):
#   - UserPromptSubmit -> model-visible `additionalContext`, so the agent stays
#     oriented to the mission every time it decides "what to do next".
#   - Stop             -> user-visible `systemMessage`, a nudge at the moment the
#     agent finishes a turn.
#
# It surfaces every ACTIVE mission whose `assignee` matches the current
# `git config user.email` (strict gate -- unassigned or others' missions stay
# silent), with derived progress (checked/total over ## Acceptance) and the next
# unchecked acceptance item. Silent no-op when no active mission is assigned to
# the current user, so it costs only a few greps on every other turn/repo.
#
# Claude-Code-only, POSIX sh, no outputs/ footprint (lives in hooks/, not built).

set -eu

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

# hook_event_name from the hook's JSON stdin (UserPromptSubmit | Stop), read
# without jq (not guaranteed present). Any other/absent event falls back to a
# plain stdout print, which is harmless.
INPUT=$(cat 2>/dev/null || true)
EVENT=$(printf '%s' "$INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -e 's/.*"\([^"]*\)"$/\1/' || true)

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$ROOT" ] || exit 0
ACTIVE_DIR="${ROOT}/.workaholic/missions/active"
[ -d "$ACTIVE_DIR" ] || exit 0

ME=$(git config user.email 2>/dev/null || true)
[ -n "$ME" ] || exit 0

LINES=""
for f in "$ACTIVE_DIR"/*/mission.md; do
    [ -f "$f" ] || continue
    assignee=$(grep -m1 '^assignee:' "$f" 2>/dev/null | sed -e 's/^assignee:[ \t]*//' -e 's/[ \t]*$//' || true)
    [ "$assignee" = "$ME" ] || continue

    title=$(grep -m1 '^title:' "$f" 2>/dev/null | sed -e 's/^title:[ \t]*//' -e 's/[ \t]*$//' || true)
    prog=$(sh "${PLUGIN_ROOT}/skills/mission/scripts/progress.sh" "$f" 2>/dev/null || true)
    checked=$(printf '%s' "$prog" | sed -n 's/.*"checked":[ ]*\([0-9][0-9]*\).*/\1/p')
    total=$(printf '%s' "$prog" | sed -n 's/.*"total":[ ]*\([0-9][0-9]*\).*/\1/p')
    [ -n "$checked" ] || checked=0
    [ -n "$total" ] || total=0
    next=$(sh "${PLUGIN_ROOT}/skills/mission/scripts/next-acceptance.sh" "$f" 2>/dev/null || true)

    line="- ${title} — ${checked}/${total} acceptance criteria met"
    [ -z "$next" ] || line="${line}; next: ${next}"

    if [ -n "$LINES" ]; then
        LINES="${LINES}
${line}"
    else
        LINES="$line"
    fi
done

[ -n "$LINES" ] || exit 0

MSG="Active mission(s) assigned to you — stay oriented to the roadmap and steer toward completion:
${LINES}"

# JSON-escape MSG: backslash, double-quote, and newlines -> \n (POSIX awk).
ESCAPED=$(printf '%s' "$MSG" | awk 'BEGIN{ORS=""} { gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); if (NR>1) printf "\\n"; printf "%s", $0 }')

case "$EVENT" in
    Stop)
        printf '{"systemMessage": "%s"}\n' "$ESCAPED"
        ;;
    UserPromptSubmit)
        printf '{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "%s"}}\n' "$ESCAPED"
        ;;
    *)
        printf '%s\n' "$MSG"
        ;;
esac
