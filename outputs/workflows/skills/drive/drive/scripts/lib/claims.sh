#!/bin/sh
# Shared claim-protocol reader -- the SINGLE implementation of "which PR-units are
# in flight", sourced by both consumers so the reader and the writer cannot drift.
#
#   list-claims.sh  renders this scan as JSON (the human/agent-facing reader).
#   claim.sh        verifies a unit is unclaimed through this SAME scan before it
#                   creates anything (a writer that carried its own scan would be
#                   free to disagree with the reader, which is exactly the state a
#                   coordination protocol must not have).
#
# THE MODEL (docs/loop-engineering-workflow.md G3): the repository is the
# coordination medium. A claim is a commit whose subject is `Claim <unit-id>` on a
# fresh work-* branch, stamping `claim: <branch>` into the claimed artifacts'
# frontmatter, pushed immediately. So the set of claims in flight is exactly the set
# of remote branches carrying commits not yet on the base -- no lock file, no server,
# nothing to leak when a runner dies. A merge empties a claim by definition; deleting
# the branch releases it explicitly.
#
# Usage (from a drive script, with SCRIPT_DIR its own scripts/ dir):
#   . "<scripts-dir>/lib/claims.sh"
#   claims_fetch            # echoes true/false -- NEVER fails (see the asymmetry below)
#   claims_base             # echoes the base ref the unmerged set is measured against
#   claims_scan "<base>"    # echoes one TSV row per claim
#
# `claims_scan` emits, tab-separated, one row per claim:
#   unit <TAB> branch <TAB> last_commit_at <TAB> stale <TAB> artifact,artifact,...
# where `branch` is the SHORT name (no `origin/` prefix -- the name the stamp carries),
# `stale` is true|false against WORKAHOLIC_CLAIM_STALE_HOURS (default 24), and the
# artifact list is comma-separated repo-relative paths (empty when a claim commit
# stamped nothing that survives at the tip).
#
# Paths are assumed free of tabs, commas, quotes and backslashes -- true of every
# .workaholic/ artifact by construction (the ticket/mission filename rules), and the
# same assumption posix-lint.sh and the worktree scripts already make. That is what
# lets both consumers use flat TSV and unescaped JSON.

# Fetch origin, tolerating an unreachable one. Echoes `true` when the fetch actually
# ran, `false` otherwise -- and NEVER returns non-zero.
#
# THE ASYMMETRY IS DELIBERATE. An unreachable origin only DEGRADES the reader (it
# reports `fetched: false` and answers from the last-known remote-tracking refs) but
# must FAIL the writer loudly (claim.sh), because a claim that was not pushed is not
# a claim. False "unclaimed" is the dangerous error: it double-picks work. A stale
# reader over-reports claims, which merely makes a runner wait.
claims_fetch() {
    if ! git config --get remote.origin.url >/dev/null 2>&1; then
        printf 'false'
        return 0
    fi
    if git fetch --prune --quiet origin >/dev/null 2>&1; then
        printf 'true'
    else
        printf 'false'
    fi
}

# The ref the "unmerged" set is measured against. origin/main is the truth; the
# remaining candidates keep the scan working in a fixture or a master-named repo.
# Echoes an empty string when nothing resolves (a repo with no base has no claims).
claims_base() {
    for _cb in origin/main origin/master main master; do
        if git rev-parse --verify --quiet "${_cb}^{commit}" >/dev/null 2>&1; then
            printf '%s' "$_cb"
            return 0
        fi
    done
    printf ''
}

# Read one frontmatter key out of a blob at <ref>:<path>. Same frontmatter shape as
# every other reader in the plugin (first match inside the leading --- block wins).
claims_blob_field() {
    git show "${1}:${2}" 2>/dev/null | awk -v key="$3" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        index($0, key ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
    ' 2>/dev/null || true
}

# Scan the remote branches for claims. $1 = base ref (from claims_base).
claims_scan() {
    _cs_base="${1:-}"
    [ -n "$_cs_base" ] || return 0

    _cs_hours="${WORKAHOLIC_CLAIM_STALE_HOURS:-24}"
    case "$_cs_hours" in
        '' | *[!0-9]*) _cs_hours=24 ;;
    esac
    _cs_now=$(date +%s)
    _cs_threshold=$((_cs_hours * 3600))

    for _cs_ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin 2>/dev/null | sort); do
        [ "$_cs_ref" = "origin/HEAD" ] && continue
        [ "$_cs_ref" = "$_cs_base" ] && continue

        # Unmerged? A branch whose commits all reached the base is released by
        # definition -- merging IS the release, so no separate signal is needed.
        _cs_ahead=$(git rev-list --count "${_cs_base}..${_cs_ref}" 2>/dev/null || echo 0)
        [ "$_cs_ahead" -gt 0 ] || continue

        # Fast filter: the newest `Claim <unit-id>` subject in the unmerged range.
        # A branch with unmerged commits but no claim commit is ordinary in-flight
        # work (someone's hand-made branch), not a claim, and is not reported.
        _cs_row=$(git log --format='%H%x09%s' "${_cs_base}..${_cs_ref}" 2>/dev/null \
            | awk -F'\t' '$2 ~ /^Claim [^ ]+$/ { print $1 "\t" substr($2, 7); exit }' || true)
        [ -n "$_cs_row" ] || continue
        _cs_sha=$(printf '%s' "$_cs_row" | cut -f1)
        _cs_unit=$(printf '%s' "$_cs_row" | cut -f2)
        [ -n "$_cs_unit" ] || continue

        _cs_branch="${_cs_ref#origin/}"

        # The claimed artifacts are the files the claim commit touched that STILL
        # carry `claim: <branch>` at the tip -- so a later commit that removes a
        # stamp drops that artifact from the claim without any bookkeeping.
        _cs_artifacts=""
        for _cs_file in $(git diff-tree --no-commit-id --name-only -r "$_cs_sha" 2>/dev/null || true); do
            [ "$(claims_blob_field "$_cs_ref" "$_cs_file" claim)" = "$_cs_branch" ] || continue
            if [ -z "$_cs_artifacts" ]; then
                _cs_artifacts="$_cs_file"
            else
                _cs_artifacts="${_cs_artifacts},${_cs_file}"
            fi
        done

        _cs_at=$(git log -1 --format='%cI' "$_cs_ref" 2>/dev/null || true)
        _cs_ct=$(git log -1 --format='%ct' "$_cs_ref" 2>/dev/null || echo "$_cs_now")

        # STALENESS IS REPORTED, NEVER AUTO-BROKEN. A tip older than the threshold
        # says "look at this", not "take it": a runner that reclaims on its own
        # verdict is a runner that can silently duplicate a colleague's in-flight
        # work over a long lunch. Reclaiming is a human/dispatcher decision.
        if [ $((_cs_now - _cs_ct)) -ge "$_cs_threshold" ]; then
            _cs_stale=true
        else
            _cs_stale=false
        fi

        printf '%s\t%s\t%s\t%s\t%s\n' \
            "$_cs_unit" "$_cs_branch" "$_cs_at" "$_cs_stale" "$_cs_artifacts"
    done
}
