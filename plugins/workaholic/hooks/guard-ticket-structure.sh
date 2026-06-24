#!/bin/sh
# PreToolUse(Bash) guard: blocks mutating shell commands that would place a
# ticket into a non-canonical location under .workaholic/tickets/.
#
# Why this exists: validate-ticket.sh is a PostToolUse(Write|Edit) hook, so it
# only sees files written through the Write/Edit tools. The real-world drift —
# an invented tickets/done/ directory, and archives nested inside
# tickets/todo/<user>/archive/ — was produced by `mv` (hand-runs and a stale
# archive.sh), which Write/Edit guards never observe. This guard inspects the
# raw Bash command string for literal non-canonical tickets paths and blocks
# them before they run.
#
# Conservative by design: only LITERAL .workaholic/tickets/<...> paths in a
# mutating command are judged. If a destination is a shell variable or glob
# (e.g. archive.sh's `mv "$TICKET" "$ARCHIVE_DIR/"`), it cannot be resolved here
# and is left alone — the script that owns it is responsible, and the
# Write/Edit guard plus the per-user create-ticket flow cover the rest.
#
# Exit codes: 0 = allow / not applicable, 2 = block (feeds the message back).

set -eu

print_skill_reference() {
  echo "See: plugins/workaholic/skills/drive/SKILL.md" >&2
}

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty')

# Fail-open on anything that is not a tickets-touching command.
[ -z "$cmd" ] && exit 0
case "$cmd" in
  *.workaholic/tickets/*) : ;;
  *) exit 0 ;;
esac

# Only police mutating commands. Read-only references (ls/cat/grep/find/git
# status, the bundled list-todo.sh) to a pre-existing messy tree must pass —
# blocking them would make the repo unusable until cleaned. Match common
# mutators by word boundary, plus output redirection.
if ! echo "$cmd" | grep -qE '(^|[^[:alnum:]_])(mv|cp|mkdir|touch|install|tee|rsync)([^[:alnum:]_]|$)|>'; then
  exit 0
fi

# Pull every literal .workaholic/tickets/<path> token out of the command.
paths=$(echo "$cmd" | grep -oE '\.workaholic/tickets/[A-Za-z0-9_./-]+' || true)
[ -z "$paths" ] && exit 0

bad=""
# Iterate newline-separated matches without bash here-strings (POSIX).
OLDIFS=$IFS
IFS='
'
for p in $paths; do
  IFS=$OLDIFS
  [ -z "$p" ] && continue

  # Path relative to the tickets root, then its top-level segment.
  rel=${p#*.workaholic/tickets/}
  [ -z "$rel" ] && continue
  [ "$rel" = "$p" ] && continue
  first=${rel%%/*}

  # Top-level segment must be one of the four canonical directories.
  case "$first" in
    todo|icebox|abandoned|archive) : ;;
    *)
      bad="${bad}
  - ${p}  (top-level '${first}/' is not a canonical tickets directory)"
      IFS='
'
      continue
      ;;
  esac

  # No 'archive' nested under todo/ — archives belong at archive/<branch>/,
  # never at todo/<user>/archive/ (the stale-archive.sh signature).
  case "/$rel/" in
    /todo/*/archive/*)
      bad="${bad}
  - ${p}  (archive must be tickets/archive/<branch>/, not nested under todo/)"
      ;;
  esac
  IFS='
'
done
IFS=$OLDIFS

if [ -n "$bad" ]; then
  echo "Error: refusing to place a ticket in a non-canonical location under .workaholic/tickets/." >&2
  echo "Offending path(s):${bad}" >&2
  echo "" >&2
  echo "Canonical layout: todo/<user>/  icebox/  abandoned/  archive/<branch>/" >&2
  echo "To complete a ticket, run /drive (its archive.sh moves it to archive/<branch>/)" >&2
  echo "rather than moving it by hand into an invented directory such as done/." >&2
  print_skill_reference
  exit 2
fi

exit 0
