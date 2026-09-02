#!/bin/sh -eu
# Make sure the log branch exists on origin, creating it as an EMPTY ORPHAN when it does not.
#
#   ensure-log-ref.sh [--root <repo-root>]
#
# Output (one JSON line):
#   {"ok", "ref", "state": "present|created|skipped|degraded", "reason", "sha"}
#
# WHY IT IS A SEPARATE SCRIPT. `open-publish-tree.sh` resolves `origin/<base>` and answers
# `base_unresolved` when the ref is absent -- correct for `main`, which always exists, and
# useless for a branch this plugin is introducing: every repository that takes this version has
# no log branch yet, and a first tick that reported `base_unresolved` forever would leave the
# log in the container exactly as before. So the absence is REPAIRED once, here, and the
# publish tree keeps its one behaviour.
#
# WHY AN ORPHAN, AND WHY EMPTY. Branching it off `main` would give the log branch `main`'s whole
# history, so every later `git log --all`, every clone and every `--merged` listing would carry
# the product's commits twice, and a stray `git merge workaholic-log` would be a fast-forward
# that silently reverted `main` to that point. An orphan shares no commit with `main`: it can
# only ever carry what this script and `persist-log.sh` put on it, and a merge into `main` has
# no common ancestor and refuses by default. The first commit is EMPTY (an empty tree) rather
# than carrying a README, because a file there would be an artifact nobody owns and the layout
# doctor would then have to have an opinion about it.
#
# IT IS BUILT AGAINST A SCRATCH INDEX, the same technique `heartbeat.sh` uses: no checkout is
# touched, no branch is created locally, nothing is staged in the caller's index, and the
# caller's working tree is byte-identical afterwards whether this creates the ref or finds it.
#
# IT CREATES, IT NEVER RESETS. A ref that exists is left exactly as it is (`present`) -- if the
# branch is there but broken, that is a fact for a person, not something an hourly tick may
# repair by force-pushing over somebody's history.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT='.'
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        *) printf '{"ok": false, "ref": "", "state": "degraded", "reason": "unknown_argument", "sha": ""}\n'; exit 1 ;;
    esac
done

REF=$(sh "${SCRIPT_DIR}/log-ref.sh")

emit() {
    printf '{"ok": %s, "ref": "%s", "state": "%s", "reason": "%s", "sha": "%s"}\n' \
        "$1" "$REF" "$2" "${3:-}" "${4:-}"
    exit 0
}

repo_root=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || printf '')
[ -n "$repo_root" ] || emit false skipped not_a_repo
git -C "$repo_root" config --get remote.origin.url >/dev/null 2>&1 || emit false skipped no_origin

# A REF THAT ALREADY EXISTS IS THE ORDINARY CASE, and it is answered with one network read
# rather than a fetch: `ls-remote` asks origin without writing a ref into this clone, so a
# caller that only wanted to know does not acquire a tracking branch as a side effect.
# AN UNREACHABLE ORIGIN AND AN ABSENT REF ARE DIFFERENT ANSWERS, and collapsing them would
# report a network outage as `push_failed` -- a degradation named after the wrong act, which
# sends whoever reads it to look at permissions instead of at the network. `ls-remote`'s exit
# status is the only thing that tells them apart: an empty listing is a ref that is not there.
if ! ls_out=$(git -C "$repo_root" ls-remote --heads origin "$REF" 2>/dev/null); then
    emit false degraded origin_unreachable
fi
existing=$(printf '%s' "$ls_out" | cut -f1)
[ -z "$existing" ] || emit true present '' "$existing"

# --- create it -----------------------------------------------------------------------------
# The empty tree is a constant in every git repository, so nothing has to be written to name it.
empty_tree=$(git -C "$repo_root" hash-object -t tree /dev/null 2>/dev/null || printf '')
[ -n "$empty_tree" ] || emit false degraded tree_failed

# No `-p`: this is a root commit, which is what makes it an orphan.
sha=$(printf '%s' "the tick log lives on this branch; see gather/scripts/log-ref.sh" \
    | git -C "$repo_root" commit-tree "$empty_tree" 2>/dev/null || printf '')
[ -n "$sha" ] || emit false degraded commit_failed

# `--force-with-lease` is NOT used and must not be: the lease we would name is "the ref does not
# exist", and a colleague's container creating it in the same second is a race this should LOSE
# quietly rather than win. A rejected push means somebody else created it; re-read and report it.
if git -C "$repo_root" push --quiet origin "${sha}:refs/heads/${REF}" >/dev/null 2>&1; then
    emit true created '' "$sha"
fi

raced=$(git -C "$repo_root" ls-remote --heads origin "$REF" 2>/dev/null | cut -f1 || printf '')
[ -z "$raced" ] || emit true present '' "$raced"
emit false degraded push_failed
