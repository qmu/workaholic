#!/bin/sh -eu
# The claim WRITER: take a PR-unit before driving it, by pushing the claim.
#
#   claim.sh mission <slug>            -- claim one approved mission (unit id = the slug)
#   claim.sh batch <ticket-file>...    -- claim one batch of backlog tickets
#                                         (unit id = batch-<YYYYMMDDHHMMSS>, minted here)
#
# One unit <-> one branch <-> one worktree <-> one PR. The sequence is fixed:
#   1. fetch origin (a claim that cannot be pushed is not a claim -- see below);
#   2. verify the unit is unclaimed THROUGH THE READER (lib/claims.sh, the same scan
#      list-claims.sh renders, so writer and reader can never disagree);
#   3. create the unit's worktree + branch via the sanctioned creator;
#   4. stamp `claim: <branch>` into the claimed artifacts IN THE WORKTREE CHECKOUT;
#   5. commit `Claim <unit-id>` and push -u immediately.
#
# Output: {"claimed": true, "unit": "...", "branch": "work-...", "worktree_path": "..."}
#     or: {"claimed": false, "reason": "...", ...} on stderr with a non-zero exit.
# Refusal reasons: already_claimed (names the holding branch and unit), no_origin,
# origin_unreachable, artifact_missing, no_frontmatter, push_failed.
#
# NEVER PROMPTS. It is the coordination step of an unattended runner.
#
# THE STAMP RIDES THE WORKTREE, NEVER THE MAIN TREE. The runner's main checkout must
# stay clean between ticks (the /propose batch commits on main and depends on that),
# and the claim is branch-only by design: main never shows a claim, so no merge ever
# has to un-stamp one.
#
# AN UNREACHABLE ORIGIN FAILS LOUDLY HERE. The reader degrades offline; the writer
# must not. A claim nobody else can see is not a claim, and proceeding to drive on
# one is exactly the double-pick the protocol exists to prevent.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/claims.sh"

fail() {
    printf '{"claimed": false, "reason": "%s"%s}\n' "$1" "${2:-}" >&2
    exit 1
}

kind="${1:-}"
case "$kind" in
    mission | batch) shift ;;
    *)
        echo 'Usage: claim.sh mission <slug> | claim.sh batch <ticket-file>...' >&2
        exit 1
        ;;
esac

if [ "$#" -eq 0 ]; then
    echo 'Usage: claim.sh mission <slug> | claim.sh batch <ticket-file>...' >&2
    exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"claimed": false, "reason": "not inside a git repository"}' >&2
    exit 1
fi
repo_root="$(git rev-parse --show-toplevel)"

# --- 1. Origin is mandatory for the writer ---------------------------------
git config --get remote.origin.url >/dev/null 2>&1 \
    || fail "no_origin" ', "detail": "a claim is a pushed branch; this repository has no origin remote"'
[ "$(claims_fetch)" = "true" ] \
    || fail "origin_unreachable" ', "detail": "refusing to claim a unit without a reachable origin -- an unpushed claim is not a claim"'

base=$(claims_base)

# --- 2. Resolve the unit and the artifacts it claims -----------------------
# `unit` is the id that rides the commit subject; `artifact_rels` are repo-relative
# paths (the shape the reader reports), resolved in the MAIN tree here and re-rooted
# into the worktree at stamp time.
artifact_rels=""
case "$kind" in
    mission)
        unit="$1"
        . "${SCRIPT_DIR}/../../mission/scripts/lib/resolve.sh"
        mission_file=$(mission_resolve "${repo_root}/.workaholic" "$unit")
        # A mission living in its own unmerged worktree has no mission.md in the main
        # tree; that is normal and not an error -- the artifact is resolved again
        # inside the worktree below, which is the checkout the stamp belongs to.
        case "$mission_file" in
            "${repo_root}/"*) artifact_rels="${mission_file#"${repo_root}/"}" ;;
        esac
        ;;
    batch)
        unit="batch-$(date +%Y%m%d%H%M%S)"
        for arg in "$@"; do
            [ -f "$arg" ] || fail "artifact_missing" ', "artifact": "'"${arg}"'"'
            abs=$(cd -- "$(dirname -- "$arg")" && pwd)/$(basename -- "$arg")
            case "$abs" in
                "${repo_root}/"*) : ;;
                *) fail "artifact_outside_repo" ', "artifact": "'"${arg}"'"' ;;
            esac
            artifact_rels="${artifact_rels}${abs#"${repo_root}/"}
"
        done
        ;;
esac
artifact_rels=$(printf '%s' "$artifact_rels" | grep -v '^$' || true)

# --- 3. Refuse a unit (or an artifact) already in flight -------------------
# Both checks matter: the unit id catches a second runner claiming the same mission,
# and the artifact overlap catches a batch that scoops up a ticket another branch
# already took under a different batch id.
rows=$(claims_scan "$base")
if [ -n "$rows" ]; then
    while IFS='	' read -r held_unit held_branch _held_at _held_stale held_arts; do
        [ -n "$held_unit" ] || continue
        if [ "$held_unit" = "$unit" ]; then
            fail "already_claimed" ', "unit": "'"${unit}"'", "holder_branch": "'"${held_branch}"'", "holder_unit": "'"${held_unit}"'"'
        fi
        for rel in $artifact_rels; do
            old_ifs="$IFS"
            IFS=','
            for held in $held_arts; do
                if [ "$held" = "$rel" ]; then
                    IFS="$old_ifs"
                    fail "already_claimed" ', "artifact": "'"${rel}"'", "holder_branch": "'"${held_branch}"'", "holder_unit": "'"${held_unit}"'"'
                fi
            done
            IFS="$old_ifs"
        done
    done <<EOF
$rows
EOF
fi

# --- 4. Create the unit's worktree + branch --------------------------------
# The sanctioned creator: it cuts from the FETCHED origin/main, mints the canonical
# work-* branch name, and reports the worktree's real HEAD. The worktree directory is
# the unit id, so `.worktrees/<unit>` stays keyed 1:1 to the unit for both a mission
# (dir = slug) and a batch (dir = batch id).
if create_out=$(sh "${SCRIPT_DIR}/../../branching/scripts/create-mission-worktree.sh" "$unit"); then
    :
else
    fail "worktree_creation_failed" ', "unit": "'"${unit}"'", "detail": "see the creator'"'"'s error above"'
fi
worktree_path=$(printf '%s' "$create_out" | sed -n 's/.*"worktree_path":[ ]*"\([^"]*\)".*/\1/p')
branch=$(printf '%s' "$create_out" | sed -n 's/.*"branch":[ ]*"\([^"]*\)".*/\1/p')
if [ -z "$worktree_path" ] || [ -z "$branch" ]; then
    fail "worktree_creation_failed" ', "detail": "could not read worktree_path/branch from the creator"'
fi

# Undo a partial claim: the worktree and its branch exist only to hold a claim that
# was never published, so removing them leaves no debris and no false "unclaimed".
abort_claim() {
    ( cd "$repo_root" && sh "${SCRIPT_DIR}/../../branching/scripts/cleanup-mission-worktree.sh" "$unit" ) >/dev/null 2>&1 || true
    fail "$1" "${2:-}"
}

# --- 5. Stamp the claim in the WORKTREE checkout ---------------------------
# For a mission, resolve again against the worktree's own .workaholic: that is where
# an unmerged mission.md actually lives, and the resolver takes an explicit root
# precisely so this is not a cwd guess.
if [ "$kind" = "mission" ]; then
    artifact_rels=""
    wt_mission=$(mission_resolve "${worktree_path}/.workaholic" "$unit")
    [ -f "$wt_mission" ] || abort_claim "artifact_missing" ', "artifact": "'"${wt_mission}"'"'
    artifact_rels="${wt_mission#"${worktree_path}/"}"
fi

stamp_claim() {
    _sc_file="$1"
    _sc_branch="$2"
    _sc_tmp="${_sc_file}.claim.$$"
    awk -v br="$_sc_branch" '
        NR == 1 && $0 == "---" { in_fm = 1; print; next }
        in_fm && /^---[ \t]*$/ { if (!done) { print "claim: " br; done = 1 } in_fm = 0; print; next }
        in_fm && /^claim:[ \t]*/ { print "claim: " br; done = 1; next }
        { print }
        END { exit(done ? 0 : 1) }
    ' "$_sc_file" > "$_sc_tmp" 2>/dev/null && mv "$_sc_tmp" "$_sc_file" && return 0
    rm -f "$_sc_tmp" 2>/dev/null || true
    return 1
}

for rel in $artifact_rels; do
    target="${worktree_path}/${rel}"
    [ -f "$target" ] || abort_claim "artifact_missing" ', "artifact": "'"${rel}"'", "detail": "not present in the claim worktree"'
    stamp_claim "$target" "$branch" \
        || abort_claim "no_frontmatter" ', "artifact": "'"${rel}"'", "detail": "a claimed artifact must carry YAML frontmatter to stamp"'
done

# --- 6. Commit and push -- immediately, in that order ----------------------
set -- "Claim ${unit}" \
    "The runner takes PR-unit ${unit} before driving it; the claim is published so every other runner's reader sees the unit in flight and never double-picks it" \
    "None -- coordination only; the stamp is branch-local and never reaches main" \
    "None" "None" \
    "list-claims.sh reports this unit as claimed on ${branch} from any clone"
for rel in $artifact_rels; do
    set -- "$@" "$rel"
done
( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../commit/scripts/commit.sh" "$@" ) >&2 \
    || abort_claim "commit_failed" ', "branch": "'"${branch}"'"'

if git -C "$worktree_path" push -u --quiet origin "$branch" >&2; then
    :
else
    # Classify the failure before reporting it. The branch name is minted from the
    # clock to the second (create-mission-worktree.sh), so two runners claiming
    # different units in the SAME second mint the SAME name -- and neither can see
    # the other's remote ref yet, so the collision surfaces only here, as a rejected
    # push. That rejection is the protocol working: without it, the loser's claim
    # commit would land on the winner's branch and one unit would silently vanish
    # from the reader (a branch reports only its newest `Claim` subject). Name it
    # `branch_collision` so a runner retries on the next tick instead of reading it
    # as a broken remote -- the very next second mints a different name.
    git fetch --quiet origin >/dev/null 2>&1 || true
    if git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
        abort_claim "branch_collision" ', "branch": "'"${branch}"'", "detail": "another runner minted this work-* branch name in the same second; nothing was claimed -- retry"'
    fi
    abort_claim "push_failed" ', "branch": "'"${branch}"'", "detail": "the claim was not published; nothing was claimed"'
fi

printf '{"claimed": true, "unit": "%s", "branch": "%s", "worktree_path": "%s", "artifacts": [' \
    "$unit" "$branch" "$worktree_path"
sep=""
for rel in $artifact_rels; do
    printf '%s"%s"' "$sep" "$rel"
    sep=", "
done
printf ']}\n'
