#!/bin/sh -eu
# Validates .workaholic/feedbacks/ files after Write/Edit — the feedback analogue
# of validate-story.sh. Exit codes: 0 = success / not a feedback / grandfathered,
# 2 = validation failed (blocks the operation).
#
# Why: feedback is the unified inbound stream of project context (see
# feedback/SKILL.md) and the raw material later planning reads. A record with no
# type, an unknown kind, or an off-pattern filename would silently corrupt the
# stream every consumer trusts, so the same write-time floor tickets, missions,
# and stories carry applies here. Like them it checks PRESENCE, never quality.
#
# The `subject` axis (2026-08-13, issue #436) is enforced here on NEW writes only:
# it says WHOSE opinion the record carries, which `source` (the channel) and
# `author` (who ran the capture) never answered. Records written before it exists
# are grandfathered by the same tracked-file rule below.
#
# Grandfathering: a file already TRACKED in git is history — feedback files are
# immutable by convention (SKILL.md), and this hook cannot distinguish a
# forbidden mutation from a legitimate correction, so tracked files are never
# retro-blocked (the convention, not the hook, owns immutability). Only an
# UNTRACKED (freshly written) file is held to the floor. Outside a git repo the
# hook fails open, exactly like validate-story.sh.
#
# Scope: *.workaholic/feedbacks/*.md, excluding the reserved index.md and README*.

set -eu

print_skill_reference() {
  echo "See: plugins/workaholic/skills/feedback/SKILL.md" >&2
}

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] || exit 0

filename=$(basename "$file_path")

# Only .md files directly under .workaholic/feedbacks/, excluding reserved names.
case "$file_path" in
  *.workaholic/feedbacks/*.md) : ;;
  *) exit 0 ;;
esac
case "$filename" in
  index.md|README|README.md) exit 0 ;;
esac

[ -f "$file_path" ] || exit 0

# Grandfather history: an already-tracked feedback is not a new write.
_dir=$(dirname "$file_path")
_base=$(basename "$file_path")
if git -C "$_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$_dir" ls-files --error-unmatch -- "$_base" >/dev/null 2>&1; then
    exit 0
  fi
fi

# Filename: the chronological, collision-free <YYYYMMDDHHMMSS>-<slug>.md shape.
case "$filename" in
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-*.md) : ;;
  *)
    echo "Error: feedback filename must match YYYYMMDDHHMMSS-*.md" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

content=$(cat "$file_path")
frontmatter=$(printf '%s\n' "$content" | awk '/^---$/{if(++c==2)exit}c==1')

if [ -z "$frontmatter" ]; then
  echo "Error: feedback must start with YAML frontmatter (---)" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

fm_value() {
  printf '%s\n' "$frontmatter" | grep -m1 "^$1:" | sed -e "s/^$1:[ \t]*//" -e 's/[ \t]*$//' || true
}

type_val=$(fm_value type)
if [ "$type_val" != "Feedback" ]; then
  echo "Error: feedback must carry 'type: Feedback' (the OKF conformance floor); got '${type_val:-<absent>}'" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

kind_val=$(fm_value kind)
case "$kind_val" in
  insight|instruction|concern|material|answer) : ;;
  *)
    echo "Error: feedback kind must be one of: insight, instruction, concern, material, answer; got '${kind_val:-<absent>}'" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

source_val=$(fm_value source)
case "$source_val" in
  meeting|slack|discussion|development) : ;;
  *)
    echo "Error: feedback source must be one of: meeting, slack, discussion, development; got '${source_val:-<absent>}'" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

# `subject` — whose opinion this is. Required on NEW writes only; every record
# written before 2026-08-13 predates the axis and is grandfathered by the
# tracked-file check above, exactly as the OKF `type:` floor was introduced.
# The KIND prefix is a closed set (so the field stays readable years later); the
# identity after the colon is free text (so "etc." in the ask stays open).
subject_val=$(fm_value subject)
if [ -z "$(printf '%s' "$subject_val" | tr -d '[:space:]')" ]; then
  echo "Error: feedback must name the subject that formed it (subject: <kind>[:<identity>])" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi
case "${subject_val%%:*}" in
  person|meeting|observer_ai|customer|team|other) : ;;
  *)
    echo "Error: feedback subject kind must be one of: person, meeting, observer_ai, customer, team, other; got '${subject_val%%:*}'" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

created_at=$(fm_value created_at)
case "$created_at" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]*) : ;;
  *)
    echo "Error: created_at must be ISO 8601 format (e.g., 2026-07-28T19:00:00+09:00)" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

author=$(fm_value author)
case "$author" in
  *@*.*) : ;;
  *)
    echo "Error: author must be an email address" >&2
    echo "Got: $file_path" >&2
    print_skill_reference
    exit 2
    ;;
esac

exit 0
