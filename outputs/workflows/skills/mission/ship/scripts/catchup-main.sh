#!/bin/sh -eu
# Catch the current work branch up with origin/<base> before deploy, so the
# artifact that gets deployed and confirmed equals what will land on merge.
# Fetches origin and merges origin/<base> into the current branch.
#
# Catching up is MANDATORY before any deploy step (a stale branch either reverts
# merged work or, for an idempotent deploy-on-merge release, silently no-ops it).
# On conflict this classifies the conflict so the ship flow can act deterministically:
#   - resolved here: a conflict under .workaholic/ whose SHAPE proves both sides
#     only appended (see below). Kept-both, so it never reaches the classifier.
#   - "mechanical": every remaining conflicted path is a version/lockstep manifest
#     or under outputs/ — routine reconciliation the agent performs itself (merge,
#     resolve, re-run the pre-merge proof, re-bump the version past any collision).
#   - "content": some other path conflicts — a human must judge it; halt and ask.
# The merge is aborted whenever anything remains, so the caller acts from a clean tree.
#
# WHY APPEND-ONLY .workaholic/ CONFLICTS ARE RESOLVED HERE. The .workaholic/ tree is an
# append-only knowledge log: a mission's ## Changelog, and the OKF index.md files, are
# extended by every seam that archives a ticket, reports a story or records a run. Two
# branches that each land work therefore always conflict at the same tail, and the
# resolution is never a judgement — it is "keep both". Classing that as "content" cost
# the merge rather than a prompt: /drive's unattended routing demotes an `auto` unit to
# the PR path, and it recurred on EVERY concurrent pair of units. Measured once: seven
# conflicted files, five version manifests already classed mechanical and two
# .workaholic/ append-only files, and those two alone forced the whole catch-up to
# "content".
#
# THE SCOPE RULE IS SHAPE, BOUNDED BY PATH — decided, not incidental:
#   - Shape, not a path list: the test is that the merge base is an exact LINE-PREFIX of
#     both sides (nothing existing was modified or removed, both sides only added at the
#     tail). That is self-verifying, so it covers files added to the tree later and can
#     never be wrong about a file it accepts, where a hand-maintained path list drifts.
#   - Bounded to .workaholic/ anyway: appending is only EVIDENCE OF INDEPENDENCE in a
#     log. Two branches each appending a function to the end of a source file have the
#     same shape and a genuine content decision behind it, so the shape test is not let
#     loose on the code.
# Anything that is not a pure append — a modified or removed line, a file added on both
# sides with no merge base, an ancestor with no trailing newline — falls through to the
# ordinary classifier. Every failure mode of the test is conservative by construction.
#
# ORDERING OF THE MERGED TAIL. Changelog lines are date-led and read oldest-first, so
# the appended lines are sorted when EVERY one of them (both sides) starts with a date.
# When any does not — an index entry, a prose line — they are concatenated in merge
# order (ours, then theirs), which is the honest fallback rather than a sort key
# assumed onto lines that do not carry one. A line both sides appended verbatim is kept
# once: for these files the line IS the event id (see mission/scripts/append-changelog.sh,
# which is idempotent on exactly that key), so keeping both would duplicate a record.
#
# What this reports is HONEST about scope: it reconciles the current WORK BRANCH with
# origin/<base>. It does NOT touch — and makes no claim about — the local `main` ref
# (on the desk layout a worktree cannot move the `main` another worktree pins, and
# catch-up does not try to). So the "already up to date" answer below is named for the
# work branch, not for `main`: `branch_up_to_date` is true iff merging origin/<base>
# into the branch was a no-op. It deliberately does NOT say "main is current" — an
# earlier `already_current` field did, and read as a currency it never verified.
#
# Usage: bash catchup-main.sh [base-branch] [--resolve-mechanical]   (default base: main)
# Output: JSON
#   {"caught_up": true,  "base": "main", "branch_up_to_date": true|false,
#    "resolved_append_only": ["..."], "resolved_mechanical": ["..."]}
#     -- `resolved_mechanical` is non-empty only under `--resolve-mechanical`, and it is what
#        tells the caller which generated paths its regeneration still owes.
#   {"caught_up": false, "base": "main", "conflict": true,
#    "conflict_class": "mechanical"|"content", "conflicted_files": ["..."],
#    "append_only_files": ["..."]}
#   {"caught_up": false, "base": "main", "conflict": false, "reason": "merge_failed"}
#     -- the merge did not start (e.g. local changes would be overwritten). This is NOT
#        a conflict: there are no unmerged paths to classify, and reporting it as an
#        empty "mechanical" conflict (which this script used to do) told the caller to
#        reconcile a list of nothing.

set -eu

# THE CLASSIFICATION RULE LIVES IN ONE PLACE (2026-08-29). The scope test, the append-only
# shape proof and the mechanical allowlist below are shared verbatim with
# `drive/scripts/claim-mergeability.sh`, which predicts this script's outcome from
# `git merge-tree` without touching a worktree. Two copies of the rule is how a reader starts
# calling `content` what this writer would have resolved; see the library's own header.
CATCHUP_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${CATCHUP_SCRIPT_DIR}/lib/conflict-class.sh"

# `--resolve-mechanical` IS OPT-IN, AND ITS CONTRACT BINDS THE CALLER (2026-08-29, mission
# `land-the-loop-s-own-work-when-the-base-moves-under-it`). Without it this script classifies
# a mechanical remainder and aborts, because "the agent performs it itself" was written for a
# caller with an agent in it. `drive/scripts/catch-up-claim.sh` has no agent and no human, so
# it passes the flag and takes on the two obligations the resolution rests on:
#   * a GENERATED path (`outputs/*`) is resolved by taking either side — which side is
#     immaterial, because its content is derived — and THE CALLER MUST REGENERATE before it
#     pushes. `catch-up-claim.sh` runs `build.mjs` immediately afterwards and the repository's
#     own `Outputs Freshness` CI is the backstop.
#   * a VERSION MANIFEST is resolved by raising BOTH sides to the higher semver and merging
#     normally, so a side that also added a plugin keeps that addition. Taking one side
#     wholesale is the tempting shortcut and it silently drops the other side's edits.
# Anything the pre-pass does not make merge cleanly falls through to `content`, unresolved.
base="main"
resolve_mechanical=false
for arg in "$@"; do
  case "$arg" in
    --resolve-mechanical) resolve_mechanical=true ;;
    *) base="$arg" ;;
  esac
done

git fetch origin "$base" --quiet 2>/dev/null || git fetch origin --quiet

before=$(git rev-parse HEAD)

# Render a newline-separated list as a JSON array body (line-based, so any path works).
json_list() {
  awk 'NF{ printf "%s\"%s\"", sep, $0; sep="," }' "$1"
}

# Resolve one conflicted path iff its shape proves both sides only appended.
# Writes the kept-both result and stages it. Returns non-zero (resolving nothing)
# for every case it cannot prove, so the caller falls back to classification.
resolve_append_only() {
  p="$1"
  d="$2"

  conflict_class_append_scope "$p" || return 1

  # All three stages must exist: a missing merge base is an add/add (two independent
  # files, not an append), and a missing side is a delete/modify.
  git show ":1:$p" > "$d/anc" 2>/dev/null || return 1
  git show ":2:$p" > "$d/ours" 2>/dev/null || return 1
  git show ":3:$p" > "$d/theirs" 2>/dev/null || return 1

  # THE PROOF, from the shared rule: the merge base is an exact line-prefix of both sides,
  # and an empty merge base is refused (every line would be an "append", concatenating two
  # independently written files). The reader applies this same call to the same three blobs.
  conflict_class_append_only "$p" "$d/anc" "$d/ours" "$d/theirs" || return 1

  n=$(wc -l < "$d/anc" | tr -d ' ')
  tail -n +"$((n + 1))" "$d/ours"   > "$d/ours_tail"
  tail -n +"$((n + 1))" "$d/theirs" > "$d/theirs_tail"
  # Drop any line both sides appended verbatim — for these files the line is the event id.
  # grep's exit status is read explicitly: 1 means "every line was a duplicate" (an empty
  # result is correct), anything above means grep failed, and treating THAT as an empty
  # result would silently drop the other side's work while reporting a clean catch-up.
  if [ -s "$d/ours_tail" ]; then
    set +e
    grep -Fxv -f "$d/ours_tail" "$d/theirs_tail" > "$d/theirs_new" 2>/dev/null
    gs=$?
    set -e
    [ "$gs" -le 1 ] || cp "$d/theirs_tail" "$d/theirs_new"
  else
    cp "$d/theirs_tail" "$d/theirs_new"
  fi
  cat "$d/ours_tail" "$d/theirs_new" > "$d/tail"

  # Chronological only when every appended line is date-led; else merge order.
  if [ -s "$d/tail" ] && ! grep -qvE '^-[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}' "$d/tail"; then
    sort "$d/tail" > "$d/tail_sorted"
    mv "$d/tail_sorted" "$d/tail"
  fi

  cat "$d/anc" "$d/tail" > "$d/merged"
  cp "$d/merged" "${root}/${p}" || return 1
  git add -- "$p" >/dev/null 2>&1 || return 1
  return 0
}

# Materialise a conflicted path's three index stages, so a shared predicate can be handed the
# same blobs the reader hands it. All three must exist: a missing one is an add/add or a
# delete/modify, which every proof in the shared library refuses by construction.
stage_files() {
  git show ":1:$1" > "$2/manc" 2>/dev/null || return 1
  git show ":2:$1" > "$2/mours" 2>/dev/null || return 1
  git show ":3:$1" > "$2/mtheirs" 2>/dev/null || return 1
  return 0
}

# Resolve one conflicted path whose correct content needs no judgement. Only ever reached
# under `--resolve-mechanical`; returns non-zero (resolving nothing) for everything it cannot
# make merge cleanly, so an unresolvable path still falls through to the classifier.
resolve_mechanical_path() {
  p="$1"
  d="$2"

  # A flat area's index is generated INSIDE its markers only, so it is admitted by proof rather
  # than by path: both sides must have left everything outside the region alone. Proved here,
  # then resolved exactly as any other generated path — take a side, let the caller re-derive.
  if stage_files "$p" "$d" && conflict_class_generated_region "$p" "$d/manc" "$d/mours" "$d/mtheirs"; then
    git show ":2:$p" > "${root}/${p}" 2>/dev/null || return 1
    git add -- "$p" >/dev/null 2>&1 || return 1
    return 0
  fi

  if conflict_class_generated_path "$p"; then
    # Derived content: whichever side is taken, the caller's regeneration overwrites it.
    git show ":2:$p" > "${root}/${p}" 2>/dev/null \
      || git show ":3:$p" > "${root}/${p}" 2>/dev/null \
      || return 1
    git add -- "$p" >/dev/null 2>&1 || return 1
    return 0
  fi

  conflict_class_version_manifest "$p" || return 1
  stage_files "$p" "$d" || return 1

  # The higher of the two semvers, by version sort. Both files carry the same value on every
  # `"version"` key by the repository's own rule, so raising both sides to it removes the
  # collision and leaves every other difference to merge normally.
  vers=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' \
           "$d/mours" "$d/mtheirs" | sort -V -u)
  [ -n "$vers" ] || return 1
  top=$(printf '%s\n' "$vers" | tail -n 1)

  for side in mours mtheirs; do
    sed -e 's/\("version"[[:space:]]*:[[:space:]]*\)"[0-9][0-9.]*"/\1"'"${top}"'"/g' \
      "$d/${side}" > "$d/${side}.norm" || return 1
  done
  sed -e 's/\("version"[[:space:]]*:[[:space:]]*\)"[0-9][0-9.]*"/\1"'"${top}"'"/g' \
    "$d/manc" > "$d/manc.norm" || return 1

  git merge-file -p "$d/mours.norm" "$d/manc.norm" "$d/mtheirs.norm" > "$d/mmerged" 2>/dev/null \
    || return 1
  cp "$d/mmerged" "${root}/${p}" || return 1
  git add -- "$p" >/dev/null 2>&1 || return 1
  return 0
}

if git merge --no-edit "origin/${base}" >/dev/null 2>&1; then
  after=$(git rev-parse HEAD)
  if [ "$before" = "$after" ]; then
    printf '{"caught_up": true, "base": "%s", "branch_up_to_date": true, "resolved_append_only": [], "resolved_mechanical": []}\n' "$base"
  else
    printf '{"caught_up": true, "base": "%s", "branch_up_to_date": false, "resolved_append_only": [], "resolved_mechanical": []}\n' "$base"
  fi
else
  # Capture the unmerged paths BEFORE aborting the merge.
  conflicted=$(git diff --name-only --diff-filter=U)

  if [ -z "$conflicted" ]; then
    # The merge never started, so there is nothing to classify. Say that.
    git merge --abort >/dev/null 2>&1 || true
    printf '{"caught_up": false, "base": "%s", "conflict": false, "reason": "merge_failed"}\n' "$base"
    exit 0
  fi

  root=$(git rev-parse --show-toplevel)
  d=$(mktemp -d)
  trap 'rm -rf "$d"' EXIT

  : > "$d/all"
  : > "$d/resolved"
  : > "$d/remaining"
  printf '%s\n' "$conflicted" > "$d/all"

  # The loop runs in a subshell (pipe), so the two lists are accumulated in files.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if resolve_append_only "$f" "$d"; then
      printf '%s\n' "$f" >> "$d/resolved"
    else
      printf '%s\n' "$f" >> "$d/remaining"
    fi
  done < "$d/all"

  # THE MECHANICAL PASS, only under the flag. It runs AFTER the append-only pass and only over
  # what that pass left, so a repository whose caller does not opt in behaves byte-for-byte as
  # it always has -- and the append-only resolution is never reached through this path.
  : > "$d/mech"
  if [ "$resolve_mechanical" = true ] && [ -s "$d/remaining" ]; then
    mv "$d/remaining" "$d/remaining_in"
    : > "$d/remaining"
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      if resolve_mechanical_path "$f" "$d"; then
        printf '%s\n' "$f" >> "$d/mech"
      else
        printf '%s\n' "$f" >> "$d/remaining"
      fi
    done < "$d/remaining_in"
  fi

  if [ ! -s "$d/remaining" ] && git commit --no-edit >/dev/null 2>&1; then
    # Every conflict was resolvable without a judgement -- the catch-up completed.
    printf '{"caught_up": true, "base": "%s", "branch_up_to_date": false, "resolved_append_only": [%s], "resolved_mechanical": [%s]}\n' \
      "$base" "$(json_list "$d/resolved")" "$(json_list "$d/mech")"
    exit 0
  fi

  # Classify what this script could not resolve: mechanical iff every remaining path is
  # one of the version/lockstep manifests or lives under outputs/ (a strict allowlist —
  # anything else is content).
  # The index stages are still present here -- the merge is aborted below, not above -- so the
  # classifier is handed the same three blobs the reader's is, through the same predicate.
  class="mechanical"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if stage_files "$f" "$d"; then
      conflict_class_mechanical "$f" "$d/manc" "$d/mours" "$d/mtheirs" || class="content"
    else
      conflict_class_mechanical_path "$f" || class="content"
    fi
  done < "$d/remaining"

  files_json=$(json_list "$d/all")
  append_json=$(json_list "$d/resolved")

  # Aborting discards the append resolutions above; the agent redoing this merge
  # reproduces them deterministically, and `append_only_files` names which they are.
  git merge --abort >/dev/null 2>&1 || true

  printf '{"caught_up": false, "base": "%s", "conflict": true, "conflict_class": "%s", "conflicted_files": [%s], "append_only_files": [%s]}\n' \
    "$base" "$class" "$files_json" "$append_json"
fi
