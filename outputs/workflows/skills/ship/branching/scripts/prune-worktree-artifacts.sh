#!/bin/sh -eu
# Reclaim a worktree's BUILD OUTPUT without removing the worktree. DRY RUN BY DEFAULT.
#
#   prune-worktree-artifacts.sh <worktree-path>            # report what WOULD be pruned
#   prune-worktree-artifacts.sh --apply <worktree-path>    # actually delete it
#
# Output (one JSON line):
#   {"applied": true|false, "path": "<abs>", "pruned": [{"dir","size_bytes"}],
#    "bytes_reclaimed": N, "human": "<n>", "skipped": [{"dir","reason"}]}
#
# WHY THIS IS SEPARATE FROM THE REAPER. A merged worktree someone deliberately keeps still
# does not need 13 GB of build output — that figure is measured, from one single worktree
# whose branch had already merged; another held 3 GB. Nothing prunes it, and it is not
# what anyone means by "keep the worktree around in case I need it". Each worktree also
# carries its own dependency install (250–620 MB observed), which is the bulk of a
# multi-worktree footprint. Keeping the desk and dropping the sawdust must be one action.
#
# THE SAFETY RULE IS TWO CONDITIONS, AND A DIRECTORY MUST MEET BOTH:
#
#   1. git ignores it   (`git check-ignore` says so — it is not tracked content)
#   2. its name is in the build-artifact set (WORKAHOLIC_ARTIFACT_DIRS, default below)
#
# Ignored-ness alone is NOT sufficient and that is the important half. `.env`,
# `.workaholic/leak-denylist`, local credentials, and a developer's scratch notes are all
# ignored and all precious — `git clean -Xdf` would take every one of them. Requiring a
# named build directory keeps the blast radius to things a build can regenerate. The name
# alone is not sufficient either: a repository that actually TRACKS a `dist/` would have
# it deleted, and tracked content is never this script's to remove.
#
# ONLY TOP-LEVEL DIRECTORIES ARE CONSIDERED, deliberately. A recursive hunt would find
# nested `node_modules` inside an ignored parent that is already being pruned, and would
# turn a bounded, auditable list into a walk whose result nobody can predict before
# running it.

set -eu

APPLY=false
if [ "${1:-}" = "--apply" ]; then APPLY=true; shift; fi
TARGET="${1:-}"

# The default set covers the ecosystems this workflow actually meets. It is an env
# override rather than a config file because the list is a property of the PROJECT the
# worktree belongs to, and a caller that knows better should not have to edit a script.
ARTIFACT_DIRS="${WORKAHOLIC_ARTIFACT_DIRS:-node_modules target dist build .next .nuxt .turbo .venv vendor __pycache__ .gradle .cargo-target coverage}"

if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  printf '{"error": "worktree path not found", "path": "%s"}\n' "$TARGET" >&2
  exit 1
fi

human() {
  b="$1"
  if [ "$b" -ge 1073741824 ]; then printf '%s.%sG' "$((b / 1073741824))" "$(((b % 1073741824) * 10 / 1073741824))"
  elif [ "$b" -ge 1048576 ]; then printf '%s.%sM' "$((b / 1048576))" "$(((b % 1048576) * 10 / 1048576))"
  elif [ "$b" -ge 1024 ]; then printf '%sK' "$((b / 1024))"
  else printf '%sB' "$b"; fi
}

pruned=""; p_sep=""
skipped=""; s_sep=""
bytes=0

for d in $ARTIFACT_DIRS; do
  dir="${TARGET}/${d}"
  [ -d "$dir" ] || continue

  # Condition 1: git must ignore it. A tracked build directory is somebody's decision and
  # is never this script's to delete.
  if ! git -C "$TARGET" check-ignore -q "$d" 2>/dev/null; then
    skipped="${skipped}${s_sep}{\"dir\": \"${d}\", \"reason\": \"not_ignored\"}"
    s_sep=", "
    continue
  fi

  size_kb=$(du -sk "$dir" 2>/dev/null | awk '{print $1}')
  [ -n "$size_kb" ] || size_kb=0
  size_bytes=$((size_kb * 1024))

  if [ "$APPLY" = "true" ]; then
    rm -rf "$dir"
  fi
  pruned="${pruned}${p_sep}{\"dir\": \"${d}\", \"size_bytes\": ${size_bytes}}"
  p_sep=", "
  bytes=$((bytes + size_bytes))
done

printf '{"applied": %s, "path": "%s", "pruned": [%s], "bytes_reclaimed": %s, "human": "%s", "skipped": [%s]}\n' \
  "$APPLY" "$TARGET" "$pruned" "$bytes" "$(human "$bytes")" "$skipped"
