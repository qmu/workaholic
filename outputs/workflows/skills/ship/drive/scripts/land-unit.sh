#!/bin/sh -eu
# Land a CLAIMED PR-unit on the base right now, on a present developer's instruction.
#
#   land-unit.sh <unit-id> --developer-present [--override-scan] [base-branch]
#
# THE THIRD ROUTE. /drive's Unified Run §6 routes a unit two ways: `auto` ships through
# the evidence-gated ship doctrine, `review` (and absence) stops at a PR and waits for a
# human to merge it out of band. Neither serves the case where the developer is standing
# in the session saying "wrap this up so a fresh session can resume immediately":
#
#   * `auto` does not apply -- the unit's recorded policy is `review`, and a script must
#     never grant itself the policy it was denied.
#   * `review` publishes the work but does not make it CLAIMABLE. Tickets minted mid-run
#     live on the claim branch, and until that branch reaches the base no other session
#     can see them (decision J1). "Published" and "queued" are different states.
#
# What was actually done instead, twice, was a hand-rolled sequence: local `git merge`,
# a manual recovery when origin/main had moved under it, a manual worktree cleanup and a
# manual remote-branch delete. Every one of those steps already had a sanctioned script;
# nothing composed them, so the composition was improvised under time pressure. This is
# that composition.
#
# THE REVIEW IS THE DEVELOPER, WHICH IS WHY IT REFUSES HEADLESS. `review` means "a human
# must look", and here one is looking -- in person, in the session. That reading holds
# only while a human is genuinely present, so this script refuses two ways:
#
#   1. `--developer-present` must be passed explicitly. It is the instruction, not a
#      proof: no script an agent runs can demonstrate that a human was
#      in the room, and it is not sold as doing so. What it does is make the claim
#      EXPLICIT, so an unattended caller has to state a falsehood rather than fall into
#      the route by omission -- and /drive's own prompt forbids stating it.
#   2. A recognised headless marker refuses outright, ahead of the flag, and cannot be
#      overridden: CLAUDE_CODE_REMOTE=true (the Claude-Code-on-the-web container every
#      routine tick runs in -- the same signal workaholify's session-start hook keys on),
#      a non-empty CI, or WORKAHOLIC_HEADLESS=1 for anything else that knows it is
#      unattended. The env check is the backstop the flag cannot be: it fires whether or
#      not the caller thought about it.
#
# GATES APPLY UNCHANGED. The branch-safety scan runs before anything lands. A `secret`
# finding is a hard refusal with no override -- exactly as in /ship, and for the same
# reason. `size`/`leak` findings are the tier a developer may override interactively, so
# they refuse unless `--override-scan` is passed; that flag is the developer's ruling and
# is reported in the output so the override is never silent.
#
# HOW IT LANDS, and why not `git merge` on the local base. The branch is caught up with
# origin/<base> IN ITS OWN WORKTREE (ship's catchup-main.sh, so the append-only
# .workaholic/ resolution and the mechanical/content classification are inherited), and
# then the branch tip is pushed straight onto the base ref:
#
#     git push origin <branch>:<base>
#
# which is a fast-forward by construction -- the same idiom publish-tree-commit.sh uses.
# Merging into a local `main` instead would mutate the caller's checkout before the push
# and leave it ahead of origin whenever the push were rejected, and the only cheap repair
# for that is `git reset --hard`, which the safety floor forbids outright. Pushing the
# ref means a rejection changes nothing anywhere: re-fetch, re-catch-up, retry ONCE.
# The retry is bounded for the same reason publish-tree-commit.sh bounds its own --
# an unbounded loop hides sustained divergence a human should see.
#
# ORDER IS THE DESIGN, and it is the inverse of release-claim.sh's. There the worktree is
# torn down BEFORE the claim is dropped, so a refused teardown never publishes "this unit
# is free" over unpushed work. Here the work is LANDED FIRST and the teardown follows: a
# failed teardown after a successful land loses nothing (the commits are on the base), and
# tearing down first would destroy the branch this script still has to push.
#
# Output (stdout, exit 0 for a reported outcome):
#   {"landed": true, "unit": "...", "branch": "...", "base": "main", "sha": "...",
#    "retried": true|false, "scan_verdict": "pass"|"overridden", "scan_findings": N,
#    "worktree_removed": bool, "remote_branch_deleted": bool, "base_synced": bool}
#   {"landed": false, "reason": "...", ...} for every refusal:
#     headless_context, no_developer_instruction, not_claimed, worktree_missing,
#     dirty_worktree, no_origin, origin_unreachable, catchup_conflict, secret_finding,
#     scan_block, diverged
#
# Run it from the MAIN checkout: the teardown cannot remove the worktree you stand in.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/claims.sh"

unit=""
base=""
developer_present=false
override_scan=false

for arg in "$@"; do
    case "$arg" in
        --developer-present) developer_present=true ;;
        --override-scan) override_scan=true ;;
        --*) echo "land-unit.sh: unknown option $arg" >&2; exit 1 ;;
        *)
            if [ -z "$unit" ]; then unit="$arg"; else base="$arg"; fi
            ;;
    esac
done

if [ -z "$unit" ]; then
    echo 'Usage: land-unit.sh <unit-id> --developer-present [--override-scan] [base-branch]' >&2
    exit 1
fi
[ -n "$base" ] || base="main"

refuse() {
    printf '{"landed": false, "unit": "%s", "reason": "%s", "detail": "%s"}\n' "$unit" "$1" "$2"
    exit 0
}

# --- 1. The human gate, before anything is read or fetched -------------------------
# The env backstop runs FIRST and has no override: a caller that is provably unattended
# must not be able to talk its way past it with a flag.
headless=""
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
    headless="CLAUDE_CODE_REMOTE=true"
elif [ -n "${CI:-}" ]; then
    headless="CI=${CI}"
elif [ "${WORKAHOLIC_HEADLESS:-}" = "1" ]; then
    headless="WORKAHOLIC_HEADLESS=1"
fi
if [ -n "$headless" ]; then
    refuse "headless_context" \
        "${headless}; landing is a present developer's ruling. Route the unit to its PR and let a human merge it."
fi

if [ "$developer_present" != true ]; then
    refuse "no_developer_instruction" \
        "pass --developer-present. This route treats an explicit instruction as the review, so it is never taken by omission."
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"landed": false, "error": "not inside a git repository"}' >&2
    exit 1
fi
repo_root="$(git rev-parse --show-toplevel)"

# --- 2. Resolve the claim through the reader's own scan ----------------------------
# The reader is the authority on what is claimed (drive/SKILL.md, Claims): a writer
# carrying its own scan would be free to disagree with every other runner.
if ! git config --get remote.origin.url >/dev/null 2>&1; then
    refuse "no_origin" "nothing can be landed without a remote to land it on"
fi
if [ "$(claims_fetch)" != "true" ]; then
    refuse "origin_unreachable" "the base could not be fetched; nothing was changed"
fi

branch=""
rows=$(claims_scan "$(claims_base)")
if [ -n "$rows" ]; then
    while IFS='	' read -r held_unit held_branch _at _stale _arts; do
        if [ "$held_unit" = "$unit" ]; then
            branch="$held_branch"
            break
        fi
    done <<EOF
$rows
EOF
fi
if [ -z "$branch" ]; then
    refuse "not_claimed" "no unmerged claim branch carries this unit; it is already landed, released, or never claimed"
fi

worktree_path="${repo_root}/.worktrees/${unit}"
if [ ! -d "$worktree_path" ]; then
    refuse "worktree_missing" "expected ${worktree_path}; land runs the catch-up in the unit's own worktree"
fi

# Uncommitted work would be left behind by the land and then destroyed by the teardown.
if [ -n "$(git -C "$worktree_path" status --porcelain)" ]; then
    refuse "dirty_worktree" "commit or stash the work in ${worktree_path} first; nothing was landed"
fi

# --- 3. Catch up with the base, in the worktree -----------------------------------
# Composed, never re-derived: catchup-main.sh owns the append-only .workaholic/
# resolution and the mechanical/content conflict classification.
catchup_out=$( ( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../ship/scripts//catchup-main.sh" "$base" ) )
case "$catchup_out" in
    *'"caught_up": true'*) ;;
    *)
        class="unknown"
        case "$catchup_out" in
            *'"conflict_class": "content"'*) class="content" ;;
            *'"conflict_class": "mechanical"'*) class="mechanical" ;;
            *'"reason": "merge_failed"'*) class="merge_failed" ;;
        esac
        refuse "catchup_conflict" \
            "the branch could not absorb origin/${base} (${class}); reconcile it in the worktree and run land again"
        ;;
esac

# --- 4. The safety gates, unchanged -----------------------------------------------
scan_out=$( ( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../release-scan/scripts//scan-branch-safety.sh" "origin/${base}" ) )
scan_verdict="pass"
scan_findings=0
case "$scan_out" in
    *'"verdict": "block"'*)
        # The scan's finding objects are emitted without spaces after the colons
        # (`"severity":"hard"`), unlike its top-level verdict. Match what it emits.
        scan_findings=$(printf '%s' "$scan_out" | grep -o '"category":' | wc -l | tr -d ' ')
        case "$scan_out" in
            *'"severity":"hard"'*)
                refuse "secret_finding" \
                    "the branch-safety scan found a credential shape; this gate is not overridable. Nothing was landed."
                ;;
        esac
        if [ "$override_scan" != true ]; then
            refuse "scan_block" \
                "the branch-safety scan blocked (${scan_findings} finding(s)); re-run with --override-scan to rule past it, or fix the branch"
        fi
        scan_verdict="overridden"
        ;;
esac

# --- 5. Land it ---------------------------------------------------------------------
# The branch tip already contains origin/<base>, so this is a fast-forward. A rejection
# means the base moved between the catch-up and now: re-catch-up and retry once.
retried=false
push_land() { git -C "$worktree_path" push --quiet origin "HEAD:refs/heads/${base}" >/dev/null 2>&1; }

if ! push_land; then
    retried=true
    git fetch --quiet origin "$base" >/dev/null 2>&1 || true
    catchup_out=$( ( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../ship/scripts//catchup-main.sh" "$base" ) )
    case "$catchup_out" in
        *'"caught_up": true'*) ;;
        *) refuse "catchup_conflict" "the base moved and the retry could not absorb it; nothing was landed" ;;
    esac
    if ! push_land; then
        refuse "diverged" "the base moved again during the retry; nothing was landed and the branch is intact"
    fi
fi
sha="$(git -C "$worktree_path" rev-parse --short HEAD)"

# Keep the claim branch's own remote ref consistent with what landed, so a reader that
# sees it before the delete below reports a MERGED claim rather than a divergent one.
git -C "$worktree_path" push --quiet origin HEAD >/dev/null 2>&1 || true

# --- 6. The land released the claim; now tear the claim's housing down --------------
# Everything below is bookkeeping AFTER an irreversible success. None of it may turn a
# landed unit into a reported failure (merge-pr.sh learned this the expensive way).
worktree_removed=false
cleanup_out=$( ( cd "$repo_root" && sh "${SCRIPT_DIR}/../../branching/scripts//cleanup-mission-worktree.sh" "$unit" ) 2>/dev/null ) || cleanup_out=""
case "$cleanup_out" in
    *'"worktree_removed": true'*) worktree_removed=true ;;
esac

remote_deleted=false
if git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
    if git push --quiet origin --delete "$branch" >/dev/null 2>&1; then
        remote_deleted=true
    fi
fi

# --- 7. Make the landed artifacts visible to THIS checkout's next survey ------------
# Without this the unit's leftover tickets are on the base but not in the working tree
# plan-units.sh reads, so the run that just landed them would still not offer them.
base_synced=false
sync_out=$( ( cd "$repo_root" && sh "${SCRIPT_DIR}/../../branching/scripts//sync-main.sh" "$base" ) 2>/dev/null ) || sync_out=""
case "$sync_out" in
    *'"ok": true'*) base_synced=true ;;
esac

printf '{"landed": true, "unit": "%s", "branch": "%s", "base": "%s", "sha": "%s", "retried": %s, "scan_verdict": "%s", "scan_findings": %s, "worktree_removed": %s, "remote_branch_deleted": %s, "base_synced": %s}\n' \
    "$unit" "$branch" "$base" "$sha" "$retried" "$scan_verdict" "$scan_findings" \
    "$worktree_removed" "$remote_deleted" "$base_synced"
