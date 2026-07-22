#!/bin/sh -eu
# Validates .workaholic/stories/<branch>.md files after Write/Edit — the story
# analogue of validate-ticket.sh / validate-mission.sh. Exit codes: 0 =
# success / not a story / grandfathered, 2 = validation failed (blocks).
#
# Why: a story is the PR description and the OKF concept document for a branch's
# work, but nothing checked its shape — a cross-repo audit found only ~21% of
# stories carried the OKF `type: Story` floor (a few even used lowercase
# `story`). This hook gives the story the same write-time `type` floor tickets
# and missions have. Like them it checks PRESENCE, never quality.
#
# Grandfathering (the crux): most existing stories predate the `type`
# convention, so a blocking validator must judge only NEW writes, never history
# it cannot fix. Stories have no todo/-vs-archive split to key on, so newness is
# read from git: a file already TRACKED is history (an edit to fix an old story
# is never retro-blocked); only an UNTRACKED (freshly written) story is held to
# the floor. Outside a git repo the hook fails open.
#
# Scope: *.workaholic/stories/*.md, excluding the reserved index.md and any
# README* (those are navigation/prose, not concept documents).

set -eu

print_skill_reference() {
  echo "See: plugins/workaholic/skills/report/SKILL.md (Story Frontmatter)" >&2
}

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] || exit 0

filename=$(basename "$file_path")

# Only .md story files under .workaholic/stories/, excluding reserved names.
case "$file_path" in
  *.workaholic/stories/*.md) : ;;
  *) exit 0 ;;
esac
case "$filename" in
  index.md|README|README.md) exit 0 ;;
esac

[ -f "$file_path" ] || exit 0

# Grandfather history: an already-tracked story is not a new write. Run git from
# the file's own directory and match on its basename, so an absolute or a
# repo-relative file_path both resolve. Fail open outside a git repo.
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
if [ "$type_val" != "Story" ]; then
  echo "Error: a story must carry frontmatter with 'type: Story' (the OKF concept-document floor)" >&2
  echo "Got: $file_path (type: '${type_val}')" >&2
  print_skill_reference
  exit 2
fi

exit 0
