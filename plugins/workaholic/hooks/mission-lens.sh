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
# SUMMARIZE ON CHANGE: the full roster is injected only when it CHANGED since the last
# turn of this session (or on the first turn, or when session_id is absent). On an
# unchanged turn — the common case under a long /goal run — it emits a single compact
# line (count + the one next action + a `/mission summary` pointer) instead of the whole
# block, so the developer's own message is not buried under redundant context every turn.
# The change-detector is per session and per event, cksum-compared under TMPDIR, and
# fails open to the full roster. It never blocks a stop; /goal's gating is untouched.
#
# Claude-Code-only, POSIX sh, no outputs/ footprint (lives in hooks/, not built).

set -eu

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

# hook_event_name from the hook's JSON stdin (UserPromptSubmit | Stop), read
# without jq (not guaranteed present). Any other/absent event falls back to a
# plain stdout print, which is harmless.
INPUT=$(cat 2>/dev/null || true)
EVENT=$(printf '%s' "$INPUT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -e 's/.*"\([^"]*\)"$/\1/' || true)
# session_id keys the per-session change-detector below (SUMMARIZE-ON-CHANGE). It is
# always present in a real Claude Code hook invocation; when absent (e.g. a bare test
# harness) we simply cannot dedupe, so the full roster is emitted every time.
SID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -e 's/.*"\([^"]*\)"$/\1/' || true)

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

MSG_FULL="Active mission(s) that are your business — stay oriented to the roadmap and steer toward completion:
${LINES}"

# SUMMARIZE ON CHANGE. The roster rarely changes within a session, yet a /goal Stop
# condition re-fires this hook on essentially every turn; re-injecting the full block
# each time buries the developer's own message under many lines that carry no new
# information. So the FULL roster is emitted only when it CHANGED since the last turn
# (or on the first turn, or when we cannot tell — no session_id); on an unchanged turn
# we emit a compact one-liner instead — the count plus the single next action, with a
# pointer to `/mission summary` — so the active goal and next step stay visible without
# the volume. State is per session AND per event (UserPromptSubmit vs Stop dedupe apart),
# keyed under TMPDIR and cksum-compared; it is best-effort and fails open to the full
# roster. Gating behavior of /goal is untouched — this hook never blocks a stop.
MSG="$MSG_FULL"
if [ -n "$SID" ]; then
    STATE_DIR="${TMPDIR:-/tmp}/workaholic-mission-lens"
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    SAFE_SID=$(printf '%s' "$SID" | sed 's/[^A-Za-z0-9._-]/_/g')
    STATE_FILE="${STATE_DIR}/${SAFE_SID}.${EVENT:-none}"
    SIG=$(printf '%s' "$MSG_FULL" | cksum | sed 's/ .*//')
    PREV=$(cat "$STATE_FILE" 2>/dev/null || true)
    printf '%s' "$SIG" > "$STATE_FILE" 2>/dev/null || true
    if [ -n "$PREV" ] && [ "$PREV" = "$SIG" ]; then
        # Roster unchanged since last turn: compact reminder rather than the full block.
        COUNT=$(printf '%s\n' "$LINES" | grep -c '^- ' || true)
        LEAD=$(printf '%s\n' "$LINES" | sed -n '1s/^- //p')
        if [ "$COUNT" -le 1 ]; then
            MSG="Roadmap unchanged — 1 active mission is your business: ${LEAD}"
        else
            MSG="Roadmap unchanged — ${COUNT} active missions are your business; next: ${LEAD} (+ $((COUNT - 1)) more — /mission summary for the full list)"
        fi
    fi
fi

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
