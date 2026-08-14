#!/bin/sh -eu
# Living migration: move a ticket's owner out of its PATH and into its FIELD.
#
# `.workaholic/tickets/todo/<user-slug>/X.md` -> `.workaholic/tickets/todo/X.md`,
# stamping `assignees: [<owner>]` derived from the directory it came from (P2,
# 2026-08-06). It follows the `mission/scripts/migrate-strategies.sh` pattern
# exactly: idempotent, run from the seams that already write, never announced as a
# step a human has to remember.
#
# WHERE IT RUNS, AND WHY NOT IN THE SURVEY. The queue's WRITE seams call it —
# create-ticket's publish step (the seat the retired sweep-todo.sh held),
# promote-icebox.sh, and drive's archive.sh (wired 2026-08-14, issue #454: this
# header named the seam from the start and archive.sh was the one that did not
# call it, so an actively driven queue never converged through ordinary use).
# `workaholify/scripts/converge-layout.sh` calls it too, as the manual seam.
# `plan-units.sh` deliberately does NOT:
# it documents itself as side-effect-free and is called inside claim worktrees, so
# a mutating migration there would surprise every other caller. That is affordable
# because **the readers tolerate both layouts** (`-maxdepth 2`), so nothing depends
# on this having run — it converges the tree, it does not gate it.
#
# WHAT IT STAMPS. The directory carries a SLUG, not an email, and the slug rule is
# lossy (a@qmu.jp and a.qmu.jp slug identically), so the email cannot be recovered
# from the path. The ticket's own `author:` can be, and by schema it is always
# there — so the owner is the author's email when its slug matches the directory
# it sat in, and the bare directory slug otherwise. Both forms compare correctly,
# because `gather/scripts/owns.sh` compares by slug rather than by string.
#
# Author is read here as EVIDENCE OF THE MIGRATION'S OWN INPUT, not as a rule that
# author means owner. The path said who owned it; author is only how the email
# behind that path is recovered. After this runs, `assignees` is the owner and
# `author` goes back to being immutable history.
#
# A ticket that ALREADY carries a non-empty `assignees` keeps it untouched and is
# only moved — the field outranks the directory, always, since the field is the
# thing a reassignment edits.
#
# Every move is git-staged (old and new paths), matching promote-icebox.sh and
# archive.sh, so no dangling unstaged deletion is left behind.
#
# Usage: migrate-todo-owners.sh [tickets-root]   (default .workaholic/tickets)
# Output: {"migrated": N, "moves": [{"from": ..., "to": ..., "owner": ...}, ...]}

set -eu

SCRIPT_DIR=$(dirname "$0")
TICKETS_ROOT="${1:-.workaholic/tickets}"
TODO_ROOT="${TICKETS_ROOT}/todo"

moves=""
count=0
sep=""

if [ -d "$TODO_ROOT" ]; then
    for dir in "$TODO_ROOT"/*/; do
        [ -d "$dir" ] || continue
        slug=$(basename "$dir")
        for ticket in "$dir"*.md; do
            [ -f "$ticket" ] || continue

            filename=$(basename "$ticket")
            dest="${TODO_ROOT}/${filename}"

            # A name collision across two developers' directories is not a thing
            # this may guess about: ticket filenames are timestamp-prefixed and
            # unique across the tree by construction (which is what lets the claim
            # reader resolve a stamp by filename at all). If one appears anyway,
            # leave both alone and let a human look.
            if [ -e "$dest" ]; then
                echo "migrate-todo-owners: refusing to overwrite ${dest}; left ${ticket} in place" >&2
                continue
            fi

            existing=$(sh "${SCRIPT_DIR}/read-assignees.sh" "$ticket" 2>/dev/null || true)
            if [ -n "$existing" ]; then
                owner=$(printf '%s\n' "$existing" | head -n 1)
            else
                author=$(sed -n 's/^author:[[:space:]]*//p' "$ticket" | head -n 1)
                owner="$slug"
                if [ -n "$author" ]; then
                    author_slug=$(sh "${SCRIPT_DIR}/user-slug.sh" "$author" 2>/dev/null || true)
                    if [ "$author_slug" = "$slug" ]; then
                        owner="$author"
                    fi
                fi
                # Insert `assignees:` into the frontmatter block. After `author:`
                # when present (owner reads naturally beside author), else directly
                # after the opening fence — never appended to the body, which would
                # put it outside the block every reader is scoped to.
                tmp="${ticket}.migrate.$$"
                awk -v owner="$owner" '
                    NR == 1 { print; if ($0 != "---") { done = 1 } ; next }
                    done { print; next }
                    !placed && /^author:[ \t]*/ { print; print "assignees: [" owner "]"; placed = 1; next }
                    !placed && /^---[ \t]*$/ { print "assignees: [" owner "]"; print; placed = 1; done = 1; next }
                    /^---[ \t]*$/ { print; done = 1; next }
                    { print }
                ' "$ticket" > "$tmp"
                mv "$tmp" "$ticket"
            fi

            mv "$ticket" "$dest"
            git add "$dest" 2>/dev/null || true
            if git ls-files --error-unmatch "$ticket" >/dev/null 2>&1; then
                git add "$ticket" 2>/dev/null || true
            fi

            moves="${moves}${sep}{\"from\":\"${ticket}\",\"to\":\"${dest}\",\"owner\":\"${owner}\"}"
            sep=","
            count=$((count + 1))
        done
        # Remove the now-empty per-user directory. `rmdir` refuses a non-empty one,
        # so a directory still holding something (a stray non-.md file, a refused
        # collision) survives untouched and stays visible.
        rmdir "$dir" 2>/dev/null || true
    done
fi

printf '{"migrated": %d, "moves": [%s]}\n' "$count" "$moves"
