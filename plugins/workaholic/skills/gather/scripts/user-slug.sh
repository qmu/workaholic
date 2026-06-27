#!/bin/sh -eu
# Derive a filesystem-safe user slug from an email address.
# Usage: user-slug.sh [email]
#   - With no argument, defaults to `git config user.email`.
# The slug is the full email, lowercased, with every non-[a-z0-9] character
# replaced by '-' (e.g. a@qmu.jp -> a-qmu-jp). Using the full email rather than
# the local part avoids collisions between a@qmu.jp and a@example.com.
#
# This is the single canonical slug rule. Every todo-routing script
# (ticket-metadata.sh, sweep-todo.sh, list-todo.sh, promote-icebox.sh,
# check-todo.sh, detect-context.sh) derives the slug through this script so the
# layout stays consistent across the whole workflow.

set -eu

EMAIL="${1:-}"
if [ -z "$EMAIL" ]; then
    EMAIL=$(git config user.email || true)
    [ -n "$EMAIL" ] || { echo 'git user.email is not set; run: git config user.email you@example.com' >&2; exit 1; }
fi

SLUG=$(printf '%s' "$EMAIL" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-')
printf '%s\n' "$SLUG"
