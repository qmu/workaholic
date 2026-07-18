#!/bin/sh -eu
# End a mission: flip its `status` frontmatter to achieved, abandoned or carried,
# record the transition as an append-only ## Changelog line (via append-changelog.sh,
# the single changelog writer -- the history survives the close), and move the
# mission dir from active/ into archive/. This is the ONLY sanctioned way to end
# a mission -- never hand-edit `status:` or `mv` a mission dir.
#
# THE THREE OUTCOMES. `achieved` and `abandoned` were the whole set, which left no
# honest answer for the common verdict "most of this landed, the rest is still worth
# doing": `achieved` lies to a progress model whose entire claim is that progress is
# COMPUTED from unchecked ## Acceptance items and never hand-set, and `abandoned` is
# false as well. `carried` is that third outcome -- the mission is done AS FRAMED, and
# its remainder becomes a successor mission that inherits what was not finished.
#
#   carried REQUIRES a successor (--successor-title "<t>" to mint one, or
#   --successor <slug> to carry into an existing active mission). Without one it is
#   rejected like any other invalid input: a carry with nowhere to carry to is just an
#   abandon that avoids saying so.
#
# WHAT THE SUCCESSOR INHERITS, and why:
#   - The UNCHECKED ## Acceptance items, verbatim, with their (#<filename>) ticket
#     markers intact. Checked items stay with the predecessor -- they were achieved
#     THERE, and re-listing them would make the successor's computed progress claim
#     work it did not do. So the successor starts at 0/<n unmet>, which falls out of
#     its own list; no number is ever carried across.
#   - ## Goal / ## Scope and the gate_* fields, verbatim. A carry-over is a
#     CONTINUATION by definition: the mission is done as framed and the remainder
#     pursues the same outcome, so the goal is shared and the gate still applies. A
#     genuine re-framing is a NEW mission, not a carry -- which is also what keeps this
#     independent of the mission interrogation flow rather than duplicating it.
#
# LINEAGE IS RECORDED IN BOTH DIRECTIONS (design/history-structures): the predecessor
# gets a changelog line naming the successor, and the successor records `carried_from`.
# Without both, the archive shows a mission that stopped and a mission that started with
# nothing joining them.
#
# THE WORKTREE IS NOT TOUCHED HERE, and that is not an omission: close.sh never managed
# worktrees -- commands/mission.md tears the mission worktree down AFTER close.sh
# succeeds. A carry deliberately does NOT hand its worktree to the successor. The
# successor has a new slug, and .worktrees/<slug> is keyed 1:1 to the mission slug by
# slug.sh; a successor living in the predecessor's directory silently SILENCES the
# mission lens inside that very worktree (the lens reads a worktree whose basename names
# no active mission as a /drive worktree and says nothing at all). The successor gets a
# fresh worktree through the normal /mission flow instead; in-flight state and the port
# are not carried.
#
# Idempotent: closing an already-archived mission with the same status is a
# no-op ({closed: false, reason: "already_closed"}); the changelog append is
# idempotent on its (event, artifact) pair. Re-closing with the OTHER status
# (achieved -> abandoned or back) flips the status and appends its own line,
# preserving the full transition history. A re-run of the same carry is likewise a
# no-op -- the successor already exists and is not rebuilt.
#
# Usage: close.sh <mission-slug-or-file> <achieved|abandoned|carried> [date]
#          [--successor-title "<title>" | --successor <slug>]
#   date defaults to today (YYYY-MM-DD); pass it explicitly for deterministic tests.
# Output: JSON {closed, slug, status, path[, successor, successor_path, reason]}

set -eu

ARG="${1:-}"
TARGET="${2:-}"
shift 2 2>/dev/null || true

# Positional date stays supported (close.sh <slug> <status> [date]); the successor
# flags may follow it in any order.
DATE=""
SUCCESSOR_TITLE=""
SUCCESSOR_SLUG=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --successor-title) SUCCESSOR_TITLE="${2:-}"; shift 2 || true ;;
        --successor) SUCCESSOR_SLUG="${2:-}"; shift 2 || true ;;
        *) [ -n "$DATE" ] || DATE="$1"; shift ;;
    esac
done

if [ -z "$ARG" ] || [ -z "$TARGET" ]; then
    echo '{"closed": false, "reason": "missing_args"}' >&2
    exit 1
fi
case "$TARGET" in
    achieved|abandoned) : ;;
    carried)
        # A carry with nowhere to carry to is an abandon wearing a nicer name.
        if [ -z "$SUCCESSOR_TITLE" ] && [ -z "$SUCCESSOR_SLUG" ]; then
            echo '{"closed": false, "reason": "carried_needs_successor"}' >&2
            exit 1
        fi
        if [ -n "$SUCCESSOR_TITLE" ] && [ -n "$SUCCESSOR_SLUG" ]; then
            echo '{"closed": false, "reason": "carried_needs_one_successor"}' >&2
            exit 1
        fi
        ;;
    *) printf '{"closed": false, "reason": "invalid_status", "status": "%s"}\n' "$TARGET" >&2; exit 1 ;;
esac

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"closed": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

MISSION_DIR=$(dirname "$FILE")
SLUG=$(basename "$MISSION_DIR")
AREA=$(basename "$(dirname "$MISSION_DIR")")
CURRENT=$(grep -m1 '^status:' "$FILE" 2>/dev/null | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)

if [ "$AREA" = "archive" ] && [ "$CURRENT" = "$TARGET" ]; then
    printf '{"closed": false, "reason": "already_closed", "slug": "%s", "status": "%s", "path": "%s"}\n' "$SLUG" "$TARGET" "$FILE"
    exit 0
fi

# --- carried: build the successor BEFORE archiving the predecessor ---------------
# Order matters. The predecessor is still in active/ here, so its Acceptance list is
# read from a stable path; and if the successor cannot be built we exit without having
# half-closed anything.
SUCCESSOR=""
SUCCESSOR_PATH=""
if [ "$TARGET" = "carried" ]; then
    if [ -n "$SUCCESSOR_SLUG" ]; then
        SUCCESSOR_PATH=$(mission_resolve "$ROOT" "$SUCCESSOR_SLUG")
        [ -f "$SUCCESSOR_PATH" ] || {
            printf '{"closed": false, "reason": "successor_not_found", "successor": "%s"}\n' "$SUCCESSOR_SLUG" >&2
            exit 1
        }
        SUCCESSOR="$SUCCESSOR_SLUG"
    else
        SUCCESSOR=$(sh "${SCRIPT_DIR}/slug.sh" "$SUCCESSOR_TITLE")
        [ -n "$SUCCESSOR" ] || { echo '{"closed": false, "reason": "empty_successor_slug"}' >&2; exit 1; }
        EXISTING_SUCC=$(mission_resolve "$ROOT" "$SUCCESSOR")
        if [ -f "$EXISTING_SUCC" ]; then
            # Re-running the same carry: the successor is already there. Do not rebuild
            # it -- that would re-inherit items the developer may have since ticked.
            SUCCESSOR_PATH="$EXISTING_SUCC"
        else
            # Mint it through create.sh, the single scaffold writer, so the successor is
            # a normal mission (frontmatter, assignee default, OKF index, staging).
            sh "${SCRIPT_DIR}/create.sh" "$SUCCESSOR_TITLE" >/dev/null
            SUCCESSOR_PATH=$(mission_resolve "$ROOT" "$SUCCESSOR")
            [ -f "$SUCCESSOR_PATH" ] || {
                printf '{"closed": false, "reason": "successor_create_failed", "successor": "%s"}\n' "$SUCCESSOR" >&2
                exit 1
            }
            # Inherit from the predecessor: unchecked Acceptance items verbatim (markers
            # intact), Goal/Scope, the gate_* fields, and the carried_from lineage.
            # Checked items are deliberately left behind -- see the header.
            TMP_S="${SUCCESSOR_PATH}.$$.tmp"
            awk -v pred="$SLUG" -v predfile="$FILE" '
                function emit_section(file, name,   line, inside, out) {
                    inside = 0; out = ""
                    while ((getline line < file) > 0) {
                        if (line ~ ("^## " name "$")) { inside = 1; continue }
                        if (inside && line ~ /^## /) break
                        if (inside) out = out line "\n"
                    }
                    close(file)
                    return out
                }
                function unchecked(file,   line, inside, out) {
                    inside = 0; out = ""
                    while ((getline line < file) > 0) {
                        if (line ~ /^## Acceptance$/) { inside = 1; continue }
                        if (inside && line ~ /^## /) break
                        # Carry ONLY unticked items, verbatim. A ticked one was achieved
                        # in the predecessor; re-listing it would inflate the successor.
                        if (inside && line ~ /^- \[ \]/) out = out line "\n"
                    }
                    close(file)
                    return out
                }
                NR == 1 && $0 == "---" { in_fm = 1; print; next }
                in_fm && /^---[ \t]*$/ {
                    in_fm = 0
                    # Lineage: traversable predecessor -> successor (changelog) and
                    # successor -> predecessor (this field).
                    print "carried_from: " pred
                    print
                    next
                }
                in_fm && /^gate_type:/  { print "gate_type: "  gt; next }
                in_fm && /^gate_target:/{ print "gate_target: " gtg; next }
                in_fm && /^gate_assert:/{ print "gate_assert: " gas; next }
                in_fm { print; next }
                /^## Goal$/       { print; printf "%s", goal_body; skip = 1; next }
                /^## Scope$/      { print; printf "%s", scope_body; skip = 1; next }
                /^## Acceptance$/ { print; printf "\n%s\n", acc_body; skip = 1; next }
                /^## /            { skip = 0; print; next }
                skip { next }
                { print }
                BEGIN {
                    goal_body  = emit_section(predfile, "Goal")
                    scope_body = emit_section(predfile, "Scope")
                    acc_body   = unchecked(predfile)
                    while ((getline l < predfile) > 0) {
                        if (l ~ /^gate_type:/)   { gt  = substr(l, 11) }
                        if (l ~ /^gate_target:/) { gtg = substr(l, 13) }
                        if (l ~ /^gate_assert:/) { gas = substr(l, 13) }
                        if (l == "---" && ++c == 2) break
                    }
                    close(predfile)
                    sub(/^[ \t]+/, "", gt); sub(/^[ \t]+/, "", gtg); sub(/^[ \t]+/, "", gas)
                }
            ' "$SUCCESSOR_PATH" > "$TMP_S"
            mv "$TMP_S" "$SUCCESSOR_PATH"
            git add "$SUCCESSOR_PATH" 2>/dev/null || true
        fi
    fi
fi

# Flip the status field inside the frontmatter block only (a `status:` in the
# body -- e.g. inside a code fence -- is never touched).
if [ "$CURRENT" != "$TARGET" ]; then
    TMP="${FILE}.$$.tmp"
    awk -v new="$TARGET" '
        NR == 1 && $0 == "---" { in_fm = 1; print; next }
        in_fm && /^---[ \t]*$/ { in_fm = 0; print; next }
        in_fm && /^status:/ { print "status: " new; next }
        { print }
    ' "$FILE" > "$TMP"
    mv "$TMP" "$FILE"
fi

# Record the transition in the append-only changelog (idempotent on the
# (event, artifact) pair; the artifact is the mission file itself). For a carry the
# event names the successor, so the predecessor's own history says where its remainder
# went -- half of the two-way lineage, and the reason this is not optional
# (design/history-structures). Written via append-changelog.sh, the single changelog
# writer; never hand-edited.
EVENT="mission ${TARGET}"
[ "$TARGET" != "carried" ] || EVENT="mission carried into ${SUCCESSOR}"
if [ -n "$DATE" ]; then
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "$EVENT" "mission.md" "$DATE" >/dev/null
else
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "$EVENT" "mission.md" >/dev/null
fi

# Move the mission into the archive/ area (unless already there). git mv keeps
# history; plain mv + git add covers an untracked mission.
if [ "$AREA" != "archive" ]; then
    MROOT=$(dirname "$MISSION_DIR")
    [ "$AREA" = "active" ] && MROOT=$(dirname "$MROOT")
    DEST="${MROOT}/archive/${SLUG}"
    mkdir -p "${MROOT}/archive"
    # A same-slug dir already in archive/ is a conflicted state a human must
    # resolve -- keep the mission where it is rather than nesting dirs.
    if [ -e "$DEST" ]; then
        printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s", "reason": "archive_slug_conflict"}\n' "$SLUG" "$TARGET" "$FILE"
        exit 0
    fi
    :
    if git mv "$MISSION_DIR" "$DEST" >/dev/null 2>&1; then
        :
    else
        mv "$MISSION_DIR" "$DEST"
        git add -A "$MROOT" >/dev/null 2>&1 || true
    fi
    FILE="${DEST}/mission.md"
fi

# Refresh the OKF bundle indexes so the close commit ships a fresh hierarchy
# (best-effort: an index problem must not block the close).
sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

if [ "$TARGET" = "carried" ]; then
    printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s", "successor": "%s", "successor_path": "%s"}\n' \
        "$SLUG" "$TARGET" "$FILE" "$SUCCESSOR" "$SUCCESSOR_PATH"
else
    printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s"}\n' "$SLUG" "$TARGET" "$FILE"
fi
