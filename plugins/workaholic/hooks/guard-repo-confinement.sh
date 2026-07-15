#!/bin/sh -eu
# PreToolUse(Write|Edit) BLOCKING gate: a write must land inside the current repository
# or one of its own worktrees. A path resolving outside every one of them is refused and
# the caller is routed to /request, the only sanctioned way to raise work against another
# repository.
#
# This runs PreToolUse on purpose. validate-ticket.sh is PostToolUse, so by the time it
# speaks the file already exists in the foreign repo; refusing after the write is not
# confinement. This gate is the one that can actually say no.
#
# Scope, stated honestly: this is a SYNTACTIC check. It answers "does this path point
# outside the repo", which is exactly what a matcher is good at. It does NOT and cannot
# recognise a client's vocabulary carried into a legitimate in-repo write — that is
# semantic, and it belongs to the rule in rules/general.md and to /request's masking
# confirmation, where a person decides. Do not grow this hook toward content matching.
#
# Mirrors guard-git-commit.sh: read .tool_input.file_path from stdin JSON, exit 2 to
# block, exit 0 to allow. Fails open on anything it cannot resolve — it never blocks a
# write it does not understand.

set -eu

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -z "$file_path" ] && exit 0

# Not in a git repo -> nothing to confine against. Fail open.
top=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -z "$top" ] && exit 0

# Resolve the target to an absolute, symlink-free path. The file usually does not exist
# yet (this is PreToolUse), so resolve its parent directory and re-attach the basename.
case "$file_path" in
  /*) abs="$file_path" ;;
  *)  abs="$(pwd)/$file_path" ;;
esac

dir=$(dirname -- "$abs")
base=$(basename -- "$abs")
# Walk up to the nearest existing ancestor so `..` segments collapse against reality.
while [ ! -d "$dir" ] && [ "$dir" != "/" ]; do
    base="$(basename -- "$dir")/$base"
    dir=$(dirname -- "$dir")
done
real_dir=$(cd -- "$dir" 2>/dev/null && pwd -P || true)
[ -z "$real_dir" ] && exit 0
abs="${real_dir}/${base}"

# Allowed roots: this repo's toplevel plus every worktree of the SAME repository.
# Worktrees are not optional — missions run in .worktrees/<slug>, and a naive
# "must be under the toplevel" test would break the mission model.
roots=$(cd -- "$top" 2>/dev/null && pwd -P || true)
[ -z "$roots" ] && exit 0
wt=$(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' || true)
if [ -n "$wt" ]; then
    for w in $wt; do
        rw=$(cd -- "$w" 2>/dev/null && pwd -P || true)
        [ -n "$rw" ] && roots="${roots}
${rw}"
    done
fi

for r in $roots; do
    case "$abs" in
        "$r"|"$r"/*) exit 0 ;;
    esac
done

cat >&2 <<EOF
Error: refusing to write outside this repository.

  target: $abs
  repo:   $roots

Every write must land inside the current repository or one of its worktrees. To raise
work against another repository, use /request — it is the only sanctioned route, and it
masks this project's customer context before anything is filed.

See: plugins/workaholic/rules/general.md ("Never modify another repository")
EOF
exit 2
