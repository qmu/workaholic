#!/bin/sh -eu
# Validates .workaholic/strategies/ files after Write/Edit — the strategy analogue
# of validate-feedback.sh / validate-mission.sh. Exit codes: 0 = success / not a
# strategy / grandfathered, 2 = validation failed (blocks the operation).
#
# Why: the strategy layer was retired on 2026-07-28 because an open-ended
# `## Direction` artifact with no completion condition drifted against the feedback
# stream, and it was re-introduced on 2026-08-13 with a shape that cannot drift the
# same way: bounded (target_date), owned (non-empty assignees), closable (status).
# Those three properties are the whole difference between the two artifacts, so
# they are the floor — a strategy missing any of them is the retired artifact
# wearing the new name. Like every sibling validator this checks PRESENCE, never
# quality.
#
# Note the deliberate inversion: `assignees` is empty-means-team-owned everywhere
# else in this repository, and here it may NOT be empty. That is the Assignee the
# artifact is defined by, not an ownership hint.
#
# Grandfathering: a file already TRACKED in git is history and is never
# retro-blocked; only an UNTRACKED (freshly written) file is held to the floor.
# Outside a git repo the hook fails open, exactly like validate-feedback.sh.
#
# THIS HOOK DOES NOT COVER AN AMENDMENT, AND THE WRITER CARRIES THE FLOOR INSTEAD
# (2026-08-27). Every strategy `strategy/scripts/amend.sh` revises is by definition
# already git-tracked, so the grandfathering above makes this hook silent on exactly
# that class of write — the one class where the file was NOT freshly authored by a
# human looking at it. Do not read "the hook validates strategies" as covering it.
# `amend.sh` therefore evaluates the three properties below over its POST-REVISION
# candidate before touching the artifact, using create.sh's refusal names verbatim
# (`bad_target_date` / `no_assignees` / `empty_schedule` / `empty_aim`), so a breach
# is refused with nothing written rather than written and reverted.
#
# Scope: *.workaholic/strategies/*.md, excluding the reserved index.md and README*.

set -eu

print_skill_reference() {
  echo "See: plugins/workaholic/skills/strategy/SKILL.md" >&2
}

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] || exit 0

filename=$(basename "$file_path")

case "$file_path" in
  *.workaholic/strategies/*.md) : ;;
  *) exit 0 ;;
esac
case "$filename" in
  index.md|README|README.md) exit 0 ;;
esac

[ -f "$file_path" ] || exit 0

_dir=$(dirname "$file_path")
_base=$(basename "$file_path")
if git -C "$_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$_dir" ls-files --error-unmatch -- "$_base" >/dev/null 2>&1; then
    exit 0
  fi
fi

content=$(cat "$file_path")
frontmatter=$(printf '%s\n' "$content" | awk '/^---$/{if(++c==2)exit}c==1')

if [ -z "$frontmatter" ]; then
  echo "Error: strategy must start with YAML frontmatter (---)" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

fm_value() {
  printf '%s\n' "$frontmatter" | grep -m1 "^$1:" | sed -e "s/^$1:[ \t]*//" -e 's/[ \t]*$//' || true
}

type_val=$(fm_value type)
if [ "$type_val" != "Strategy" ]; then
  echo "Error: strategy must carry 'type: Strategy' (the OKF conformance floor); got '${type_val:-<absent>}'" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

status_val=$(fm_value status)
case "$status_val" in
  active|achieved|abandoned) : ;;
  *)
    echo "Error: strategy status must be one of: active, achieved, abandoned; got '${status_val:-<absent>}'" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

# The Schedule, made checkable: a strategy is bounded or it is the retired artifact.
target_date=$(fm_value target_date)
case "$target_date" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;;
  *)
    echo "Error: strategy target_date must be YYYY-MM-DD (the Schedule's bound); got '${target_date:-<absent>}'" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

# The declared stage, when one is present. PRESENCE IS NEVER REQUIRED (2026-08-29, mission
# `make-a-direction-s-lifecycle-a-declared-stage`): an absent field means 進行中, so absence is
# a valid and meaningful state and every strategy written before the field existed still
# passes. What is checked is only that a value, if written, is in the closed set — the
# operator's own three words, kept verbatim.
stage=$(fm_value stage)
if [ -n "$stage" ]; then
  case "$stage" in
    進行中|改良中|観察中) : ;;
    *)
      echo "Error: strategy stage must be one of: 進行中, 改良中, 観察中 (absent means 進行中); got '${stage}'" >&2
      echo "Got: $file_path" >&2
      print_skill_reference
      exit 2
      ;;
  esac
fi

# The Assignee. Empty means team-owned on every OTHER artifact; on a strategy it
# is a refusal — an unowned direction is not a strategy.
assignees=$(fm_value assignees | sed -e 's/^\[//' -e 's/\]$//' -e 's/[ \t,]//g')
if [ -z "$assignees" ]; then
  echo "Error: strategy assignees must name at least one owner (the Assignee); an unowned direction is not a strategy" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

# The Aim and the Schedule prose: present AND non-empty (a bare heading is absent).
section_nonempty() {
  printf '%s\n' "$content" | awk -v want="## $1" '
    $0 == want { inside = 1; next }
    inside && /^## / { exit }
    inside && NF { found = 1; exit }
    END { exit(found ? 0 : 1) }
  '
}

for section in Aim Schedule; do
  if ! section_nonempty "$section"; then
    echo "Error: strategy must carry a non-empty '## ${section}' section" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
  fi
done

exit 0
