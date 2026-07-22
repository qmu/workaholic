#!/bin/sh -eu
# Validates .workaholic/trips/**/*.md artifacts after Write/Edit — the trip
# analogue of validate-story.sh. Exit codes: 0 = success / not a trip artifact /
# grandfathered, 2 = validation failed (blocks).
#
# Why: trip sub-artifacts are the least conformant of all (~4% carried an OKF
# type in a cross-repo audit — most had no frontmatter at all). They are
# heterogeneous — Direction / Model / Design / Review / Rollback / Trip Plan /
# Event Log — so this hook does NOT hardcode a role->type map (fragile); it
# requires a NON-EMPTY `type` drawn from that allowed set, and lets the trip
# workflow decide which. Presence, never quality.
#
# Grandfathering: as with stories, most existing trip artifacts predate the
# convention, so newness is read from git — an already-TRACKED file is history
# and never retro-blocked; only an UNTRACKED (freshly written) trip artifact is
# held to the floor. Outside a git repo the hook fails open.
#
# Scope: *.workaholic/trips/**/*.md, excluding reserved index.md / README*.

set -eu

print_skill_reference() {
  echo "See: plugins/workaholic/skills/trip-protocol/SKILL.md" >&2
}

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] || exit 0

filename=$(basename "$file_path")

case "$file_path" in
  *.workaholic/trips/*.md) : ;;
  *) exit 0 ;;
esac
case "$filename" in
  index.md|README|README.md) exit 0 ;;
esac

[ -f "$file_path" ] || exit 0

# Grandfather history: skip an already-tracked artifact; fail open without git.
# Run git from the file's directory and match its basename so absolute or
# repo-relative file_path both resolve.
_dir=$(dirname "$file_path")
_base=$(basename "$file_path")
if git -C "$_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$_dir" ls-files --error-unmatch -- "$_base" >/dev/null 2>&1; then
    exit 0
  fi
fi

content=$(cat "$file_path")
frontmatter=$(printf '%s\n' "$content" | awk '/^---$/{if(++c==2)exit}c==1')

type_val=$(printf '%s\n' "$frontmatter" | grep -m1 '^type:' | sed -e 's/^type:[ \t]*//' -e 's/[ \t]*$//' || true)

case "$type_val" in
  Direction|Model|Design|Review|Rollback|"Trip Plan"|"Event Log") exit 0 ;;
  "")
    echo "Error: a trip artifact must carry a non-empty 'type:' (one of: Direction, Model, Design, Review, Rollback, Trip Plan, Event Log)" >&2
    echo "Got: $file_path (no type)" >&2
    print_skill_reference
    exit 2
    ;;
  *)
    echo "Error: trip artifact 'type: ${type_val}' is not an allowed trip type (Direction, Model, Design, Review, Rollback, Trip Plan, Event Log)" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac
