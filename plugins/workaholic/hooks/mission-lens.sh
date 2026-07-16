#!/bin/sh -eu
# Mission lens -- always-on re-anchoring on the roadmap.
#
# Fires on two events, both NON-FORCING (it never blocks a stop; it informs):
#   - UserPromptSubmit -> model-visible `additionalContext`, so the agent stays
#     oriented to the mission every time it decides "what to do next".
#   - Stop             -> user-visible `systemMessage`, a nudge at the moment the
#     agent finishes a turn.
#
# It surfaces an ACTIVE mission only when it passes THREE gates -- the lens is an
# orientation aid, not a nag, so a line that cannot tell the developer what to do next
# does not get printed above the agent's answer:
#
#   1. assignee -- the mission is the developer's business: `assignee` matches the
#      current `git config user.email` (shown as theirs), or the mission is UNASSIGNED
#      (shown as claimable). Only a mission assigned to SOMEONE ELSE stays silent.
#      Unassigned missions used to be silent too, which meant unclaimed work was
#      invisible to everybody -- the lens skipped it and only `list.sh` ever showed it.
#      This follows summary.sh, which makes the same "not somebody else's" judgement.
#      The line invites claiming rather than reporting an error: it is printed on every
#      prompt, so it has to read as an offer, not a defect.
#   2. location -- see the worktree-focus rule below. Inside a mission's own worktree,
#      only that mission. Inside a worktree that owns NO mission (a /drive worktree),
#      nothing at all. In the main tree, only missions that own no worktree.
#   3. signal -- the mission has at least one acceptance criterion. A mission whose
#      ## Acceptance is empty renders as `0/0` with no next step: a technical condition
#      reported with nothing to act on. It stays silent here; `/mission summary` is the
#      on-demand view that still shows it. The two thresholds differ on purpose -- an
#      always-on nudge and a list you asked for should not have the same bar.
#
# Each surfaced mission shows derived progress (checked/total over ## Acceptance) and its
# next unchecked item. Silent no-op when nothing passes all three, so it usually costs
# only a few greps per turn.
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

# Worktree focus: a mission runs in its own worktree (.worktrees/<slug>). Inside
# a mission worktree, surface ONLY that mission — you are already focused on it,
# so other worktrees' missions are noise. In the main tree (or a non-mission
# worktree), surface only missions that do NOT own a dedicated worktree (a
# worktree-owned mission stays silent everywhere but its own worktree).
CURRENT_MISSION=""
IN_WORKTREE=""
case "$ROOT" in
    */.worktrees/*)
        IN_WORKTREE=yes
        cand="${ROOT##*/}"
        [ -f "${ACTIVE_DIR}/${cand}/mission.md" ] && CURRENT_MISSION="$cand"
        ;;
esac
# A worktree that names no mission is a /drive worktree (.worktrees/work-*): it is
# focused on a single ticket, and the roadmap is not its business. Say nothing rather
# than falling through to the main tree's list — a session that asked for one ticket
# should not be handed the whole map. (Basename-matching is sound because slug.sh is the
# single source deriving both the mission dir name and the .worktrees/<slug> name.)
[ -z "$IN_WORKTREE" ] || [ -n "$CURRENT_MISSION" ] || exit 0

# Slugs that own a registered .worktrees/<slug> worktree (one per line).
WT_SLUGS=$(git worktree list --porcelain 2>/dev/null | sed -n 's|^worktree .*/\.worktrees/\(.*\)$|\1|p' || true)

LINES=""
FREE_LINES=""
for f in "$ACTIVE_DIR"/*/mission.md; do
    [ -f "$f" ] || continue
    # Mine, or unclaimed. Someone else's stays silent. ($ME is non-empty, guarded
    # above, so an unassigned mission cannot match it by accident.) Absent and empty
    # assignee are the same thing, as they are everywhere else in the schema.
    assignee=$(grep -m1 '^assignee:' "$f" 2>/dev/null | sed -e 's/^assignee:[ \t]*//' -e 's/[ \t]*$//' || true)
    if [ -n "$assignee" ] && [ "$assignee" != "$ME" ]; then
        continue
    fi

    slug=$(basename "$(dirname "$f")")
    if [ -n "$CURRENT_MISSION" ]; then
        # Inside a mission worktree: only that worktree's mission.
        [ "$slug" = "$CURRENT_MISSION" ] || continue
    else
        # Main tree (a non-mission worktree exited above): skip worktree-owned missions.
        if printf '%s\n' "$WT_SLUGS" | grep -Fqx "$slug"; then
            continue
        fi
    fi

    title=$(grep -m1 '^title:' "$f" 2>/dev/null | sed -e 's/^title:[ \t]*//' -e 's/[ \t]*$//' || true)
    prog=$(sh "${PLUGIN_ROOT}/skills/mission/scripts/progress.sh" "$f" 2>/dev/null || true)
    checked=$(printf '%s' "$prog" | sed -n 's/.*"checked":[ ]*\([0-9][0-9]*\).*/\1/p')
    total=$(printf '%s' "$prog" | sed -n 's/.*"total":[ ]*\([0-9][0-9]*\).*/\1/p')
    [ -n "$checked" ] || checked=0
    [ -n "$total" ] || total=0

    # No acceptance criteria written yet: progress is 0/0 and next-acceptance.sh has
    # nothing to offer, so the line would report a technical condition — the section was
    # never filled in — with no next step and nothing to act on. Say nothing; a line that
    # cannot tell the developer what to do next has not earned its place above the
    # agent's answer. `/mission summary` is the on-demand view where an unfilled mission
    # is still visible (deliberately a different threshold from this always-on nudge).
    # Checked before next-acceptance.sh so a silenced mission costs one subshell, not two.
    [ "$total" -gt 0 ] || continue

    next=$(sh "${PLUGIN_ROOT}/skills/mission/scripts/next-acceptance.sh" "$f" 2>/dev/null || true)

    line="- ${title} — ${checked}/${total} acceptance criteria met"
    [ -z "$next" ] || line="${line}; next: ${next}"

    # An unassigned mission is an offer, not a defect: say it is unclaimed and how to
    # take it, rather than reporting a missing field at someone every single prompt.
    if [ -z "$assignee" ]; then
        line="${line} [unclaimed — yours to take]"
        if [ -n "$FREE_LINES" ]; then
            FREE_LINES="${FREE_LINES}
${line}"
        else
            FREE_LINES="$line"
        fi
    elif [ -n "$LINES" ]; then
        LINES="${LINES}
${line}"
    else
        LINES="$line"
    fi
done

# Mine first, unclaimed after — the developer's own work is never crowded out by an
# offer. Same ordering summary.sh makes, for the same reason.
if [ -n "$LINES" ] && [ -n "$FREE_LINES" ]; then
    LINES="${LINES}
${FREE_LINES}"
elif [ -n "$FREE_LINES" ]; then
    LINES="$FREE_LINES"
fi

[ -n "$LINES" ] || exit 0

MSG="Active mission(s) that are your business — stay oriented to the roadmap and steer toward completion:
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
