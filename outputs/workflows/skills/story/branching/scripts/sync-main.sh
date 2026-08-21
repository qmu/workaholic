#!/bin/sh -eu
# Bring THIS checkout's base branch up to date with origin's, FAST-FORWARD ONLY.
#
#   sync-main.sh [base-branch]      # base defaults to the branch check.sh calls main
#
# Output (stdout, always exit 0 for a reported outcome):
#   {"ok": true,  "base": "origin/<base>", "sha": "<sha>", "advanced": true|false,
#                 ["realigned": true, "previous_sha": "<sha>", "backup_ref": "<ref>"]
#                 ["off_base": true, "branch": "<name>"]
#                 ["fast_forwarded": true, "previous_sha": "<sha>"]}
#   {"ok": false, "reason": "not_on_main"|"dirty_workspace"|"no_origin"
#                          |"origin_unreachable"|"diverged", ...}
#
# NEVER merges, rebases or stashes. A fast-forward is the only mutation it will
# perform on a base branch a developer has touched, and every state in which it
# cannot fast-forward is REPORTED rather than resolved: staleness is reported and
# never auto-broken, and a reset would discard a developer's local commits.
# The single exception is §5 below, which fires only where that rationale is
# provably absent -- a base branch with no local commits at all -- and preserves
# the discarded tip under refs/backup/ when it does.
#
# §1a is the OTHER narrow exception, and it mutates nothing at all: a checkout
# parked off the base branch entirely, but sitting on the base's exact tip with a
# clean tree, is reported `ok` with `off_base: true` instead of refused. See its
# own reasoning below. §1b is its sequel and the one place a parked checkout is
# MOVED: a DETACHED, clean HEAD that is a strict ancestor of the base tip is
# fast-forwarded onto it. See §1b's own reasoning for why that is not the licence
# the header withholds above.
#
# The reasons ride stdout with exit 0 on purpose. Every one of them is a
# legitimate state of a developer's checkout — on a branch, mid-edit — not a
# failure of this script, and the callers (`/specificate` step 1, `/drive`'s
# freshness step) are command markdown that cannot branch: they hand the JSON to
# an orchestrator that reads one uniform contract. A genuine misuse (not a git
# repository) still exits non-zero with an "error" key.
#
# Composed from the existing readers (check.sh, check-workspace.sh) rather than
# re-deriving "am I on main" and "is the tree clean" — those questions have one
# implementation each.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
requested_base="${1:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"error": "not inside a git repository"}' >&2
  exit 1
fi

# --- 1. On the base branch? -------------------------------------------------
# check.sh answers for main OR master, so a master-default repository works with
# no argument. An explicitly requested base must match exactly.
check_out=$(sh "${SCRIPT_DIR}/check.sh")
branch=$(printf '%s\n' "$check_out" | sed -n 's/.*"branch":[ ]*"\([^"]*\)".*/\1/p')
on_main=$(printf '%s\n' "$check_out" | sed -n 's/.*"on_main":[ ]*\([a-z]*\).*/\1/p')

off_base=false
if [ -n "$requested_base" ]; then
  base="$requested_base"
  [ "$branch" = "$base" ] || off_base=true
else
  if [ "$on_main" != "true" ]; then
    # No base branch is checked out, so there is no branch name to take the base
    # from. check.sh recognises `main` OR `master` by name but does not say which
    # this repository uses, so read it off the refs that exist rather than
    # defaulting to one: a local base branch first (the shape §5's baked-clone
    # case leaves behind), then origin's. Nothing resolvable means the off-base
    # proof below cannot be made, and it refuses `not_on_main` as before.
    base=""
    for candidate in main master; do
      if git rev-parse --verify --quiet "refs/heads/${candidate}" >/dev/null 2>&1 \
        || git rev-parse --verify --quiet "refs/remotes/origin/${candidate}" >/dev/null 2>&1; then
        base="$candidate"
        break
      fi
    done
    off_base=true
  else
    base="$branch"
  fi
fi

# --- 1a. Parked off the base, but standing on its exact tip --------------------
# THE REFUSAL BELOW IS RIGHT IN THE GENERAL CASE AND STAYS. A developer's feature
# branch carries different content, so surveying it reports a queue that does not
# exist -- which is the whole reason `/drive`'s freshen step runs before its
# survey. What this section adds is the one shape where that reasoning provably
# does not apply: the checkout is on some other branch, but HEAD is the base's
# exact tip and the tree is clean, so the working tree the caller is about to read
# is byte-identical to the one it would read standing on the base.
#
# Measured twice within one hour on 2026-08-12 -- 21:38Z (this ticket) and 22:24Z
# (the tick that minted `20260812223046-pin-the-plugin-source-across-the-freshen-step`)
# -- plus two merged pull requests from a `claude/*` branch (#394, #395). The cloud
# container hands the session a harness branch created from `origin/main` and checks
# THAT out, leaving the image's baked `main` behind; every such tick was
# contractually finished before it could survey, with work sitting in the queue.
# It is the same class as the superseded plugin binding and the baked base branch:
# a harness artifact wearing a developer's clothes, which the run should proceed
# past rather than stop on.
#
# THE EXCEPTION RESTS ON A PROOF, NEVER ON A BRANCH NAME. A `claude/*` allowlist
# would be a guess about a harness that is free to rename its branches tomorrow;
# "same commit as the base, nothing modified" is checkable here and now. Every way
# the proof can fail -- no origin, an unreachable one, a tip that does not match,
# a dirty tree -- refuses `not_on_main` exactly as before, so no off-base refusal
# changes its reason. And it MUTATES NOTHING: there is no branch to fast-forward
# (the caller is not on one) and moving the caller's checkout is not this script's
# licence to take. `off_base: true` rides the success so the caller reports the
# state rather than silently treating it as an ordinary sync.
if [ "$off_base" = true ]; then
  refuse_off_base() {
    if [ -n "$requested_base" ]; then
      printf '{"ok": false, "reason": "not_on_main", "branch": "%s", "base": "%s"}\n' "$branch" "$base"
    else
      printf '{"ok": false, "reason": "not_on_main", "branch": "%s"}\n' "$branch"
    fi
    exit 0
  }

  [ -n "$base" ] || refuse_off_base
  git config --get remote.origin.url >/dev/null 2>&1 || refuse_off_base
  git fetch --quiet origin "$base" >&2 || refuse_off_base

  off_remote_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/${base}^{commit}" || true)
  off_head_sha=$(git rev-parse --verify --quiet "HEAD^{commit}" || true)
  [ -n "$off_remote_sha" ] || refuse_off_base
  [ -n "$off_head_sha" ] || refuse_off_base

  off_ws=$(sh "${SCRIPT_DIR}/check-workspace.sh")
  off_clean=$(printf '%s\n' "$off_ws" | sed -n 's/.*"clean":[ ]*\([a-z]*\).*/\1/p')
  [ "$off_clean" = "true" ] || refuse_off_base

  if [ "$off_head_sha" = "$off_remote_sha" ]; then
    printf '{"ok": true, "base": "origin/%s", "sha": "%s", "advanced": false, "off_base": true, "branch": "%s"}\n' \
      "$base" "$off_remote_sha" "$branch"
    exit 0
  fi

  # --- 1b. Parked off the base, DETACHED, clean, and strictly behind it ----------
  # §1a admits the container's checkout only while it stands on the base's EXACT
  # tip -- which is true for a run's first freshen and false for every one after it
  # merges anything. Measured 2026-08-18 (tickets `20260818070000` and
  # `20260818075500`, the second minted by the run the first describes): a tick
  # surveyed two unrelated tickets, drove and merged the first (PR #492), and then
  # refused `not_on_main` at its next freshen -- the same checkout §1a had admitted
  # eighteen minutes earlier, with a claimable ticket queued and nothing wrong with
  # the tree. An `/implement` run in a detached container therefore drove AT MOST ONE
  # PR-unit per tick, and the obstacle was the run's own success: a tick that merges
  # nothing never hits this.
  #
  # THE ADMISSION IS THE HEADER'S RATIONALE APPLIED, NOT WIDENED. The refusals above
  # rest on one sentence: "a reset would discard a developer's local commits." A
  # DETACHED HEAD that is a strict ANCESTOR of the base tip, with a clean tree, holds
  # nothing to discard -- no branch points at it, no commit on it is absent from the
  # base, no edit is pending. Moving it is a fast-forward of the working tree, the
  # same operation §4 performs on a base branch, and NOT the `git reset --hard` §1
  # forbids: `git checkout --detach <base-tip>` refuses on its own if anything would
  # be overwritten. The header's "moving the caller's checkout is not this script's
  # licence to take" is answered rather than dropped -- it was written about §1a,
  # where HEAD already equalled the tip so moving it would have been pure risk for no
  # gain; here refusing to move it is what costs the run.
  #
  # DETACHED IS LOAD-BEARING, AND IT IS THE PROOF, NOT A HARNESS GUESS. A NAMED
  # off-base branch that is behind the base is a developer's branch -- moving it
  # would rewrite a ref a person created and would silently change which branch they
  # are on -- so it keeps refusing `not_on_main`, byte-unchanged, as do dirty, ahead
  # and genuinely diverged. `fast_forwarded: true` and `previous_sha` ride the
  # success beside `advanced: true` so the caller reports that the checkout MOVED
  # rather than implying it never needed to.
  if [ -z "$branch" ] && git merge-base --is-ancestor "$off_head_sha" "$off_remote_sha"; then
    git checkout --quiet --detach "$off_remote_sha" >&2 || refuse_off_base
    printf '{"ok": true, "base": "origin/%s", "sha": "%s", "advanced": true, "off_base": true, "branch": "", "fast_forwarded": true, "previous_sha": "%s"}\n' \
      "$base" "$off_remote_sha" "$off_head_sha"
    exit 0
  fi

  refuse_off_base
fi

# --- 2. Clean tree? ---------------------------------------------------------
# A fast-forward moves tracked files under the caller's feet; refuse rather than
# risk a conflicted checkout over uncommitted work.
ws_out=$(sh "${SCRIPT_DIR}/check-workspace.sh")
clean=$(printf '%s\n' "$ws_out" | sed -n 's/.*"clean":[ ]*\([a-z]*\).*/\1/p')
if [ "$clean" != "true" ]; then
  summary=$(printf '%s\n' "$ws_out" | sed -n 's/.*"summary":[ ]*"\([^"]*\)".*/\1/p')
  printf '{"ok": false, "reason": "dirty_workspace", "branch": "%s", "summary": "%s"}\n' "$branch" "$summary"
  exit 0
fi

# --- 3. Origin ---------------------------------------------------------------
if ! git config --get remote.origin.url >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "no_origin", "base": "%s"}\n' "$base"
  exit 0
fi

# An unreachable origin is its own reason. Reporting `ok: true` off a stale
# remote-tracking ref would be the silent yesterday's-queue survey this script
# exists to prevent.
if ! git fetch --quiet origin "$base" >&2; then
  printf '{"ok": false, "reason": "origin_unreachable", "base": "%s"}\n' "$base"
  exit 0
fi

local_sha=$(git rev-parse --verify --quiet "refs/heads/${base}^{commit}" || true)
remote_sha=$(git rev-parse --verify --quiet "refs/remotes/origin/${base}^{commit}" || true)

if [ -z "$remote_sha" ]; then
  printf '{"ok": false, "reason": "origin_unreachable", "base": "%s", "detail": "origin has no %s ref after a successful fetch"}\n' "$base" "$base"
  exit 0
fi

if [ "$local_sha" = "$remote_sha" ]; then
  printf '{"ok": true, "base": "origin/%s", "sha": "%s", "advanced": false}\n' "$base" "$remote_sha"
  exit 0
fi

# --- 4. Fast-forward, or report why not --------------------------------------
# Local strictly behind: fast-forward. Anything else — local ahead, or genuine
# divergence — is a human's decision, reported with a `detail` that says which.
if git merge-base --is-ancestor "$local_sha" "$remote_sha"; then
  git merge --ff-only --quiet "origin/${base}" >&2
  printf '{"ok": true, "base": "origin/%s", "sha": "%s", "advanced": true}\n' "$base" "$remote_sha"
  exit 0
fi

if git merge-base --is-ancestor "$remote_sha" "$local_sha"; then
  detail="local_ahead"
else
  detail="both_diverged"
fi

# --- 5. The one divergence that is not a developer's ---------------------------
# The refusal above rests on a stated rationale: "a reset would discard a
# developer's local commits on the base." When the base branch provably carries
# NO local commits, that rationale does not apply and the refusal costs a run for
# nothing. Measured 2026-08-12: a cloud container's baked clone had `main` at a
# commit 59 behind an upstream history that had since been rewritten, so the tip
# was on no remote branch at all and every tick reported `both_diverged` and
# terminated -- an image artifact wearing a developer's clothes, the same class of
# failure as the superseded plugin binding (`check-deps/scripts/plugin-src.sh`).
#
# The proof is the reflog, and it is deliberately narrow: exactly ONE entry, and
# that entry is the branch's creation -- `clone: from …` when git checked the
# branch out during a clone, `branch: Created from …` when the image built it from
# a remote-tracking ref (the shape the 2026-08-12 container actually had). A branch
# that was ever committed to, reset, amended, merged or rebased locally carries a
# second entry, so it keeps the refusal. An absent or disabled reflog proves
# nothing and also keeps it -- silence is not evidence. The old tip is preserved
# under refs/backup/ rather than dropped, so even a misjudged realignment is
# recoverable with a single `git reset --hard`.
if [ "$detail" = "both_diverged" ]; then
  reflog=$(git reflog show "$base" 2>/dev/null || printf '')
  entries=$(printf '%s\n' "$reflog" | grep -c . || true)
  case "$reflog" in
    *"clone: from "*|*"branch: Created from"*) created_only=true ;;
    *) created_only=false ;;
  esac
  if [ "$entries" = "1" ] && [ "$created_only" = true ]; then
    backup_ref="refs/backup/${base}-$(git rev-parse --short "$local_sha")"
    git update-ref "$backup_ref" "$local_sha"
    git reset --hard --quiet "origin/${base}" >&2
    printf '{"ok": true, "base": "origin/%s", "sha": "%s", "advanced": true, "realigned": true, "previous_sha": "%s", "backup_ref": "%s"}\n' \
      "$base" "$remote_sha" "$local_sha" "$backup_ref"
    exit 0
  fi
fi

printf '{"ok": false, "reason": "diverged", "base": "%s", "local_sha": "%s", "remote_sha": "%s", "detail": "%s"}\n' \
  "$base" "$local_sha" "$remote_sha" "$detail"
exit 0
