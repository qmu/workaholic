#!/bin/sh -eu
# Living migration: fold the retired tickets/abandoned/ and tickets/icebox/
# directories into the archive, carrying their state in FRONTMATTER instead of in
# a path (2026-08-13, issue #436). Sibling to migrate-todo-owners.sh, run at the
# same seams, with the same contract: idempotent, best-effort, git-staged, and a
# clean no-op in a repository that never had either directory.
#
# The move it makes, once:
#   tickets/abandoned/X.md  ->  tickets/archive/unbranched/X.md  + `status: abandoned`
#   tickets/icebox/X.md     ->  tickets/archive/unbranched/X.md  + `status: icebox`
#
# `archive/unbranched/` and not `archive/<branch>/`, because the archive is keyed
# by the branch that DROVE a ticket and neither of these was ever driven. Inventing
# a branch (the commit that abandoned it, say) would assert a drive that never
# happened; putting them at the archive root would break the `archive/*/` shape
# every reader globs. One named bucket states what is true: archived, never driven.
#
# The body is NEVER touched — only a `status:` line is inserted into the
# frontmatter block. A ticket that already carries a `status:` is left completely
# alone (it has been through this migration, or a human set it deliberately), which
# is what makes a second run a no-op.
#
# `status:` on a ticket is the ONE axis, and it is ABSENT on a queued ticket:
# absent means "in todo/, waiting" exactly as an empty `assignees` means team-owned
# and an absent `merge_policy` means review. Vocabulary: done | abandoned | icebox.
# `icebox` deliberately survives as a distinct state rather than folding into
# `abandoned` — an iceboxed ticket is DEFERRED and promotable (promote-icebox.sh
# exists to bring one back), an abandoned one is DECIDED AGAINST, and the icebox is
# developer-curated in both directions. Erasing that distinction would quietly
# convert deferrals into rejections.
#
# Usage: migrate-ticket-states.sh [tickets-root]   (default .workaholic/tickets)
# Output: {"migrated": N, "moves": [{"from": ..., "to": ..., "status": ...}, ...]}

set -eu

TICKETS_ROOT="${1:-.workaholic/tickets}"
ARCHIVE_DIR="${TICKETS_ROOT}/archive/unbranched"

moves=""
count=0
sep=""

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

# Insert `status: <state>` into the frontmatter block, after `created_at:` when
# present (it reads naturally beside the other stamps) and otherwise directly
# after the opening fence. Never appended to the body, which would put it outside
# the block every reader is scoped to. A file with no frontmatter is left alone:
# stamping one onto a ticket nobody wrote frontmatter for is a content change.
stamp_status() {
    _f="$1"; _s="$2"
    head -n 1 "$_f" 2>/dev/null | grep -q '^---$' || return 1
    grep -qE '^status:' "$_f" 2>/dev/null && return 1
    _tmp="${_f}.migrate.$$"
    awk -v state="$_s" '
        NR == 1 { print; if ($0 != "---") { fin = 1 }; next }
        fin { print; next }
        !placed && /^---[ \t]*$/ { print "status: " state; placed = 1; fin = 1; print; next }
        !placed && /^created_at:[ \t]*/ { print; print "status: " state; placed = 1; next }
        { print }
    ' "$_f" > "$_tmp" 2>/dev/null || { rm -f "$_tmp" 2>/dev/null || true; return 1; }
    mv "$_tmp" "$_f" 2>/dev/null || { rm -f "$_tmp" 2>/dev/null || true; return 1; }
    return 0
}

for legacy in abandoned icebox; do
    src="${TICKETS_ROOT}/${legacy}"
    [ -d "$src" ] || continue
    for ticket in "$src"/*.md; do
        [ -f "$ticket" ] || continue
        filename=$(basename "$ticket")
        dest="${ARCHIVE_DIR}/${filename}"

        # Ticket filenames are timestamp-prefixed and unique across the tree by
        # construction. If a collision appears anyway, leave both alone and let a
        # human look — the same ruling migrate-todo-owners.sh makes.
        if [ -e "$dest" ]; then
            echo "migrate-ticket-states: refusing to overwrite ${dest}; left ${ticket} in place" >&2
            continue
        fi

        # Stamp BEFORE moving, so a failure to stamp leaves the ticket where it
        # was rather than in the archive with no state.
        stamp_status "$ticket" "$legacy" || continue

        mkdir -p "$ARCHIVE_DIR" 2>/dev/null || continue
        if git mv "$ticket" "$dest" >/dev/null 2>&1; then
            :
        else
            mv "$ticket" "$dest" 2>/dev/null || continue
            git add "$dest" >/dev/null 2>&1 || true
            git rm --cached -q "$ticket" >/dev/null 2>&1 || true
        fi
        git add "$dest" >/dev/null 2>&1 || true

        moves="${moves}${sep}{\"from\": \"$(json_escape "$ticket")\", \"to\": \"$(json_escape "$dest")\", \"status\": \"${legacy}\"}"
        sep=", "
        count=$((count + 1))
    done
    # The emptied directory goes with its last ticket; a directory that still holds
    # something (a README a human wrote, a ticket the collision check skipped) stays.
    rmdir "$src" 2>/dev/null || true
    git add -A "$src" >/dev/null 2>&1 || true
done

printf '{"migrated": %s, "moves": [%s]}\n' "$count" "$moves"
