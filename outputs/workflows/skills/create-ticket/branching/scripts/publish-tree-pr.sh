#!/bin/sh -eu
# Commit what the caller wrote into the publish tree and LAND IT ON A work-*
# BRANCH BEHIND A PULL REQUEST — the standard path for every workaholic artifact
# (feedback, mission, ticket).
#
#   publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]
#
# The positional arguments are commit.sh's, forwarded verbatim: this script owns
# the branch, the push, and the pull request, not the message. The base branch is
# `main` unless WORKAHOLIC_PUBLISH_BASE names another.
#
# THE PULL REQUEST'S TITLE IS NOT THE COMMIT SUBJECT (P4, 2026-08-06). Set
# WORKAHOLIC_PR_TITLE to give the pull request a title of its own; unset, it is
# the commit subject, which is the long-standing behaviour and stays the default.
#
# They are different surfaces with different contracts, and conflating them was a
# live defect. The commit subject is gated by `commit/scripts/check-subject.sh`:
# present tense, <= 50 characters, and NO `[bracket]` prefix. The pull request
# title is gated by nothing and is what `/specificate` must prefix with `[Proposal]`
# — the string the `[Implement]` routine's GitHub trigger filters on. Passing one
# string to both made those two rules contradict each other: `/specificate` could
# satisfy its own documented prefix only by writing a commit subject the gate
# refuses, so the publish failed at `commit_failed` before the pull request
# existed. Splitting them lets each surface keep its own rule.
#
# THE BODY CARRIES NO NOTIFICATION TARGET (Q1, 2026-08-07). P4 briefly added a
# second env var that wrote a machine-readable thread-URL line into the body for
# the next routine to read back; that propagation is retired — the reply thread
# is found statelessly by the consumer (workaholic:workaholify, *One thread per
# feedback item*), and a carried target must not be reintroduced here.
#
# WORKAHOLIC_CLOSES_ISSUE threads a GitHub issue number into the body as a
# native closing keyword (`Closes #<N>`), so merging this pull request
# auto-closes the "[FB] ***" issue the ask came from. Same reasoning as
# WORKAHOLIC_PR_TITLE for being an env var: the positionals are commit.sh's
# and end in an open-ended [files...], so a new required positional cannot be
# told from a filename. Unset or non-numeric — the common case, since most
# asks never had a GitHub issue at all — emits no line, unchanged from before
# this existed.
#
# WORKAHOLIC_PR_TITLE is an ENV VAR rather than a positional because the
# positionals belong to commit.sh and end in an open-ended `[files...]`, so an
# extra one could not be told from a filename.
#
# Output (stdout, exit 0 for a reported outcome):
#   {"ok": true,  "sha": "<sha>", "branch": "work-…", "pr_url": "<url>", "base": "<base>"}
#   {"ok": false, "reason": "no_publish_tree"|"nothing_to_commit"|"commit_failed"
#                          |"branch_collision"|"push_failed"|"no_gh"|"pr_failed", ...}
#
# WHY THIS EXISTS ALONGSIDE publish-tree-commit.sh. Both write through the same
# isolated `.publish/` checkout, so the caller's branch, staged set, untracked
# set, and file contents are left byte-identical either way — that property is
# the whole reason the publish tree exists and it is unchanged here. What differs
# is the destination: `publish-tree-commit.sh` lands the commit directly on the
# base, this one lands it on a branch and opens a PR. The project standard is
# that every artifact reaches the base through a MERGED pull request, because the
# merge is the event that can be announced; a commit pushed straight to the base
# produces no such event. Direct-to-base publication remains available for the
# seams that are already downstream of a merge (concern extraction at ship time),
# where a second PR would be circular.
#
# THE REMOTE BRANCH IS work-*, THE LOCAL BRANCH IS STILL publish-main.
# `git push origin publish-main:work-YYYYMMDD-HHMMSS` creates the remote branch
# under the claim vocabulary's name while the local publish branch never leaves
# the machine. That is safe for the claim protocol precisely because the claim
# scan does not key on the NAME: it reads a `Claim <unit-id>` commit subject in
# the branch's unmerged range, and a publication branch carries none, so the scan
# skips it. A publication branch is therefore invisible as a claim while being an
# ordinary reviewable branch to everything else.
#
# A COLLISION IS REPORTED, NEVER RESOLVED BY OVERWRITING. Two publications in the
# same second would otherwise force-share a branch and one would silently lose
# its commit. The commit stays intact in the publish tree, and the next call —
# one second later — succeeds.
#
# A FAILED PULL REQUEST IS NOT A FAILED PUBLICATION, AND IS NOT REPORTED AS A
# SUCCESS EITHER. If the push landed but `gh` could not open the PR, the artifact
# IS on the remote branch and is recoverable; `ok` is false with `reason:
# "pr_failed"`, and both `branch` and `sha` are reported so the caller can open
# the PR by hand rather than re-publishing and duplicating the artifact.

set -eu

base="${WORKAHOLIC_PUBLISH_BASE:-main}"
PUBLISH_BRANCH="publish-main"

if [ "$#" -lt 6 ]; then
  echo 'Usage: publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]' >&2
  exit 1
fi

TITLE="$1"
WHY="$2"

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
publish_path="${repo_root}/.publish"

if ! git worktree list --porcelain | grep -q "^worktree ${publish_path}$"; then
  printf '{"ok": false, "reason": "no_publish_tree", "path": "%s", "detail": "run open-publish-tree.sh first"}\n' "$publish_path"
  exit 0
fi

before_sha="$(git -C "$publish_path" rev-parse HEAD)"

# --- 1. Commit through the shared wrapper ------------------------------------
if ( cd "$publish_path" && sh "${SCRIPT_DIR}/../../commit/scripts//commit.sh" "$@" ) >&2; then
  :
else
  printf '{"ok": false, "reason": "commit_failed", "path": "%s"}\n' "$publish_path"
  exit 0
fi

after_sha="$(git -C "$publish_path" rev-parse HEAD)"
if [ "$before_sha" = "$after_sha" ]; then
  # commit.sh exits 0 on "nothing staged". Reporting ok:true here would hand back
  # a sha that predates the caller's write — a publication that never happened,
  # reported as one that did.
  printf '{"ok": false, "reason": "nothing_to_commit", "path": "%s", "detail": "commit.sh staged nothing; nothing was published"}\n' "$publish_path"
  exit 0
fi

# --- 2. Mint the publication branch ------------------------------------------
work_branch="work-$(date +%Y%m%d-%H%M%S)"

if git -C "$publish_path" ls-remote --exit-code --heads origin "$work_branch" >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "branch_collision", "branch": "%s", "sha": "%s", "path": "%s", "detail": "a remote branch of that name already exists; the commit is intact in the publish tree and the next call succeeds"}\n' \
    "$work_branch" "$after_sha" "$publish_path"
  exit 0
fi

# --- 3. Push the commit onto the publication branch --------------------------
# No rebase-and-retry here, and none is needed: the destination is a BRAND NEW
# branch, so there is nothing to be non-fast-forward against. (publish-tree-commit.sh
# needs the retry because it pushes onto a shared base another runner may have
# advanced.) Reconciling with the base is the pull request's job.
if git -C "$publish_path" push --quiet origin "${PUBLISH_BRANCH}:refs/heads/${work_branch}" >&2; then
  :
else
  printf '{"ok": false, "reason": "push_failed", "branch": "%s", "sha": "%s", "path": "%s", "detail": "the commit is intact in the publish tree"}\n' \
    "$work_branch" "$after_sha" "$publish_path"
  exit 0
fi

# --- 4. Open the pull request ------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "no_gh", "branch": "%s", "sha": "%s", "base": "%s", "detail": "the artifact IS pushed to the branch; open the pull request by hand"}\n' \
    "$work_branch" "$after_sha" "$base"
  exit 0
fi

# A closing keyword is validated here, not trusted from the caller: a
# non-numeric value would land verbatim in a public PR body as inert text
# that merely looks like it closes something.
closes_issue="${WORKAHOLIC_CLOSES_ISSUE:-}"
case "$closes_issue" in
  ''|*[!0-9]*) closes_issue="" ;;
esac

body_file=$(mktemp "${TMPDIR:-/tmp}/workaholic-publish-pr.XXXXXX")
trap 'rm -f "$body_file"' EXIT
{
  printf '## Overview\n\n%s\n\n' "$WHY"
  if [ -n "$closes_issue" ]; then
    printf 'Closes #%s\n\n' "$closes_issue"
  fi
  printf '## Artifacts\n\n'
  # Counts per (.workaholic/ area, status), not an enumerated file-path list (a
  # reviewer wants roughly what shape the change is, not each literal path). A path
  # outside .workaholic/, or directly under it with no subdirectory, folds into one
  # generic "files changed" line rather than being dropped. Renames (R###) and copies
  # (C###) carry two paths; the destination (last field) is what matters, and a
  # rename reads as "modified" — the artifact did not newly appear.
  git -C "$publish_path" show --stat --oneline --name-status --format='' HEAD | awk '
    NF == 0 { next }
    {
      status = substr($1, 1, 1)
      path = $NF
      area = ""
      if (index(path, ".workaholic/") == 1) {
        rest = substr(path, length(".workaholic/") + 1)
        slash = index(rest, "/")
        if (slash > 0) area = substr(rest, 1, slash - 1)
      }
      if (area == "") { other++; next }
      word = "modified"
      if (status == "A") word = "added"
      else if (status == "D") word = "deleted"
      else if (status == "C") word = "added"
      key = area SUBSEP word
      if (!(key in count)) order[++n] = key
      count[key]++
    }
    END {
      for (i = 1; i <= n; i++) {
        split(order[i], parts, SUBSEP)
        area = parts[1]; word = parts[2]
        printf("- %d %s %s\n", count[order[i]], label(area, count[order[i]]), word)
      }
      if (other > 0) printf("- %d files changed\n", other)
      if (n == 0 && other == 0) print "- no artifact changes"
    }
    function label(area, n,    s) {
      if (n == 1) {
        if (area == "feedbacks") return "feedback"
        if (area == "missions") return "mission"
        if (area == "tickets") return "ticket"
        if (area == "stories") return "story"
        if (area == "releases") return "release"
        if (area == "release-notes") return "release note"
        if (area == "trips") return "trip"
        s = area
        if (substr(s, length(s), 1) == "s") return substr(s, 1, length(s) - 1)
        return s
      }
      if (area == "release-notes") return "release notes"
      gsub(/-/, " ", area)
      return area
    }
  '
  printf '\n## Notes\n\nPublished from the publish tree, so the caller'"'"'s checkout was never touched. Merging this pull request is what lands the artifact on `%s`.\n' "$base"
} > "$body_file"

PR_TITLE="${WORKAHOLIC_PR_TITLE:-$TITLE}"

# REST, NOT `gh pr create` (2026-08-12, FB 20260812172522). The subcommand is
# GraphQL-backed and a Claude Code Web session may serve only "the pinned set of
# PR-review operations" — measured HTTP 403 in this repository's own tick. This is the
# worse half of that failure: the artifact is already committed and PUSHED by the time
# the PR is opened, so a stop here leaves work pushed-but-unpublished for a human to
# finish by hand, every tick, in a session nobody is reading.
#
# THE STDERR IS CAPTURED, AND THAT IS HALF THE FIX. This call used to end in
# `2>/dev/null`, so the 403 never reached the operator and `pr_failed` was
# indistinguishable from a network blip, an expired token, or a policy denial. The
# underlying message now rides the `detail`, which alone would have made the measured
# incident self-describing.
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"
pr_url=""
pr_number=""
pr_err=""
if slug=$( cd "$publish_path" && sh "${GATHER_SCRIPTS}/gh-rest.sh" slug 2>&1 ); then
  # The payload goes in on stdin rather than through argv: a PR body is unbounded (it
  # carries the whole story), and a single argv entry is capped at 128 KiB on Linux.
  pr_payload=$(jq -n --arg t "$PR_TITLE" --arg h "$work_branch" --arg b "$base" \
    --rawfile body "$body_file" '{title: $t, head: $h, base: $b, body: $body}' 2>/dev/null || true)
  if [ -n "$pr_payload" ]; then
    if pr_resp=$( cd "$publish_path" && printf '%s' "$pr_payload" \
        | sh "${GATHER_SCRIPTS}/gh-rest.sh" api "repos/${slug}/pulls" --method POST --input - 2>&1 ); then
      pr_url=$(printf '%s' "$pr_resp" | jq -r '.html_url // empty' 2>/dev/null || true)
      pr_number=$(printf '%s' "$pr_resp" | jq -r '.number // empty' 2>/dev/null || true)
      [ -n "$pr_url" ] || pr_err="$pr_resp"
    else
      pr_err="$pr_resp"
    fi
  else
    pr_err="could not build the pull-request payload (is jq present?)"
  fi
else
  pr_err="$slug"
fi

if [ -z "$pr_url" ]; then
  detail=$(printf '%s' "$pr_err" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)
  printf '{"ok": false, "reason": "pr_failed", "branch": "%s", "sha": "%s", "base": "%s", "detail": "the artifact IS pushed to the branch; open the pull request by hand rather than re-publishing. Underlying error: %s"}\n' \
    "$work_branch" "$after_sha" "$base" "$detail"
  exit 0
fi

# --- 5. Optional immediate merge (WORKAHOLIC_AUTO_MERGE=1) --------------------
# Opt-in for /specificate and /implement only (mission
# auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split,
# 2026-08-11): their pull requests merge immediately after opening, with the
# release scan as the sole mechanical gate — ANY finding (secret hard, size/leak
# confirm) leaves the PR open instead, because there is no human here to
# override, exactly the /implement demotion doctrine. Default off, so /ticket,
# /mission, and every other publish-tree caller keep their human-merged PR.
#
# A STRATEGY-TOUCHING PUBLICATION NEVER MERGES, AND THAT IS THE SEAM'S RULE RATHER
# THAN THE CALLER'S (2026-08-27, mission
# `let-the-operator-revise-a-live-direction-through-the-loop`). The exemption has
# stood since 2026-08-14 — the operator's merge is what AUTHORS that artifact — and
# it was PROSE ONLY: `/specificate`'s step 10 said "leave WORKAHOLIC_AUTO_MERGE
# unset", and nothing stopped a run from setting it. That was tolerable while the
# only strategy writes were a create and a close, both rare. `amend.sh` made the
# exemption load-bearing — it is the entire premise on which a THIRD writer of a
# live direction is admissible — so it moved into the seam.
#
# It is derived from the TREE BEING PUBLISHED, never from a caller-supplied flag: a
# flag is the same prose one layer down. `merged: false` with
# `merge_reason: strategy_touching` is NOT A FAILURE and must not read as one — it
# is the exemption, and the pull request is left open for the operator exactly as it
# was before. A create (step 9b), a close (step 9c) and an amendment (step 9d) are
# all covered by the one refusal, which strengthens an existing rule rather than
# introducing a new behaviour for any of them. Every other path is byte-identical:
# a publication touching no strategy still merges under WORKAHOLIC_AUTO_MERGE=1, and
# a scan finding still holds a pull request open under its own reason.
merged=false
merge_reason="not_requested"
if [ "${WORKAHOLIC_AUTO_MERGE:-}" = "1" ]; then
  touches_strategy=$( cd "$publish_path" && \
    { git diff --name-only "origin/${base}" HEAD 2>/dev/null \
      || git show --name-only --format='' HEAD 2>/dev/null; } \
    | grep -c '^\.workaholic/strategies/' 2>/dev/null || true )
  case "${touches_strategy:-0}" in
    ''|0) : ;;
    *)
      printf '{"ok": true, "sha": "%s", "branch": "%s", "pr_url": "%s", "base": "%s", "merged": false, "merge_reason": "strategy_touching"}\n' \
        "$after_sha" "$work_branch" "$pr_url" "$base"
      exit 0
      ;;
  esac
  scan_json=$( cd "$publish_path" && sh "${SCRIPT_DIR}/../../release-scan/scripts//scan-branch-safety.sh" "origin/${base}" 2>/dev/null || true )
  case "$scan_json" in
    *'"verdict": "pass"'*)
      # `PUT .../merge` with merge_method "merge" — the REST equivalent of the
      # `gh pr merge --merge` this replaces, for the same GraphQL reason as the create
      # above. merge_reason stays HONEST rather than collapsing every non-200 into
      # merge_failed: 405 is GitHub refusing the merge itself (conflict, or a required
      # check not satisfied), 409 is the head moving under us, and those are different
      # next actions for whoever reads the line.
      if merge_resp=$( cd "$publish_path" && sh "${GATHER_SCRIPTS}/gh-rest.sh" api \
          "repos/${slug}/pulls/${pr_number}/merge" --method PUT -f merge_method=merge 2>&1 ); then
        merged=true
        merge_reason="merged"
      else
        # THE LADDER LIVES IN ITS OWN SCRIPT (2026-08-23) so every rung is testable
        # without making a real merge fail: `merge-reason.sh` is a pure function over the
        # response text, and its header states what each reason means and what a reader
        # should do about it. `session_type_cannot_merge` is the rung added that day — the
        # execution class saying no, which `rules/shell.md` allows the CALLER to retry
        # through a connector; this script never does, and reports it instead.
        merge_reason=$(sh "${SCRIPT_DIR}/merge-reason.sh" "$merge_resp")
      fi
      ;;
    *'"verdict": "block"'*) merge_reason="scan_finding" ;;
    *) merge_reason="scan_unreadable" ;;
  esac
fi

printf '{"ok": true, "sha": "%s", "branch": "%s", "pr_url": "%s", "base": "%s", "merged": %s, "merge_reason": "%s"}\n' \
  "$after_sha" "$work_branch" "$pr_url" "$base" "$merged" "$merge_reason"
