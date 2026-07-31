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
#   unit <TAB> branch <TAB> last_commit_at <TAB> stale <TAB> author <TAB>
#   resumable <TAB> resume_reason <TAB> artifact,artifact,...
# where `branch` is the SHORT name (no `origin/` prefix -- the name the stamp carries),
# `stale` is true|false against WORKAHOLIC_CLAIM_STALE_HOURS (default 24), and the
# artifact list is comma-separated repo-relative paths (empty when a claim commit
# stamped nothing that survives at the tip). The artifact list stays LAST because it
# is the only variable-length field; every consumer reads it as the tail.
#
# RESUMABILITY: A CLAIM NOBODY FINISHES USED TO BE UNREACHABLE FOREVER.
# The design record says in-flight state lives on the claim branch and "the next tick
# re-claims and resumes from what is pushed" (docs/loop-engineering-workflow.md I5).
# The implementation did the opposite, measured 2026-08-01: plan-units.sh dropped every
# claimed unit as `claimed`, and claim.sh refused the same unit as `already_claimed`, so
# NO survey ever offered it again -- not the same runner's next tick, not another runner,
# not a developer typing /drive. That is survivable for a local runner whose worktree is
# still on disk, and fatal for a cloud runner whose worktree dies with its sandbox: the
# pushed branch is the sole surviving copy and nothing routed anyone to it.
#
# The verdict is computed HERE, in the one scan all three consumers read, for the same
# reason the claim check is: a surveyor and a writer that each decided resumability for
# themselves would be free to disagree, and this protocol's one intolerable state is the
# reader and the writer disagreeing about what is in flight.
#
# Two conditions, and the ORDER matters -- identity is checked first because a foreign
# claim is never resumable at ANY age:
#
#   1. SAME IDENTITY. The claim commit's author email must equal this runner's
#      `git config user.email`. The governing principle (developer, 2026-08-01) is that
#      a *pushed claim is the loop's work* -- merging to main means the runner
#      implemented it, and work you mean to keep in your own hands should never have
#      been pushed as a claim. That is what makes same-identity resumption safe rather
#      than reckless: it never licenses taking over a colleague's claim. An unresolvable
#      identity resumes nothing, the same conservative reading plan-units.sh applies to
#      mission ownership.
#   2. NOT ACTIVE. The branch tip must be older than
#      WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES (default 30). THE BRANCH TIP *IS* THE
#      HEARTBEAT: heartbeat.sh refreshes it with an empty commit at a bounded interval,
#      and any ordinary work commit refreshes it too -- which is correct, since a run
#      that is committing is a run that is alive. Deciding liveness this way needs no
#      lock file and no server (the protocol forbids both), pollutes no PR diff (an
#      empty commit changes no file), and leaks nothing when a runner dies: the signal
#      lives on the very branch that a merge or a release already cleans up.
#
# The 24-hour `stale` flag keeps its separate meaning -- REPORTED, never acted on. It is
# not the resumption trigger: an hourly routine that recovers its own dropped unit only
# after a day is not a recovery path, which is why the heartbeat threshold is in minutes.
#
# `resume_reason` always answers "why is it in this state", and is NEVER empty (see the
# no-empty-field rule below): `heartbeat_lapsed` when resumable, else `claim_active`,
# `foreign_identity`, or `identity_unresolved`. It is reported rather than merely implied
# so an operator can read WHY a unit is untouchable straight out of list-claims.sh.
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

# Map a path the claim commit touched to where that file lives NOW at the branch tip.
# $1 = the newline/tab rename map (old<TAB>new rows), $2 = the original path.
# Echoes $2 unchanged when it was never renamed (including when it was deleted --
# `git show <ref>:<gone>` then fails and the caller drops the artifact, which is the
# intended reading: a deleted artifact is not claimed).
claims_current_path() {
    printf '%s\n' "$1" | awk -F'\t' -v p="$2" '
        $1 == p { print $2; found = 1; exit }
        END { if (!found) print p }
    '
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

    # The liveness window, in MINUTES and deliberately short (see the header). A
    # malformed value falls back to the default rather than failing the scan: the
    # reader must keep answering, and a bad env var is not a reason to report no
    # claims at all.
    _cs_hb="${WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES:-30}"
    case "$_cs_hb" in
        '' | *[!0-9]*) _cs_hb=30 ;;
    esac
    _cs_hb_threshold=$((_cs_hb * 60))

    # Resolved once: whose runner this is. Empty means unresolvable, and every claim
    # is then somebody else's.
    _cs_me=$(git config user.email 2>/dev/null || true)

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
        #
        # THE STAMP IS READ AT THE FILE'S CURRENT PATH, NOT THE CLAIMED ONE. `archive.sh`
        # RENAMES a driven ticket (todo/<user>/X.md -> archive/<branch>/X.md) carrying its
        # stamp along, and looking the old path up at the tip finds nothing -- so every
        # batch unit silently lost its whole artifact list the moment its first ticket was
        # archived, and the survey then offered tickets that were already in flight. That
        # is the double-pick the protocol exists to prevent; it was observed live on
        # 2026-07-30. One tree-to-tree diff per claim gives the net old->new mapping
        # (chained renames collapse to a single row, so no walk is needed).
        _cs_renames=$(git diff --find-renames --name-status "$_cs_sha" "$_cs_ref" 2>/dev/null \
            | awk -F'\t' '$1 ~ /^R/ { print $2 "\t" $3 }' || true)

        # WHAT IS REPORTED IS THE BASE-SIDE PATH -- the one the claim commit stamped, which
        # is where the artifact still sits on the base. That is the coordinate space both
        # consumers work in: plan-units.sh compares against list-todo.sh's view of the
        # working tree, and claim.sh against paths it resolved in the main tree. Reporting
        # the archived path instead would be the useless half of the pair.
        _cs_artifacts=""
        for _cs_file in $(git diff-tree --no-commit-id --name-only -r "$_cs_sha" 2>/dev/null || true); do
            _cs_at_tip=$(claims_current_path "$_cs_renames" "$_cs_file")
            [ "$(claims_blob_field "$_cs_ref" "$_cs_at_tip" claim)" = "$_cs_branch" ] || continue
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

        # WHO holds this claim: the author of the claim commit itself, not of the tip.
        # A resumed unit gains a `Resume` commit by whoever took it over, but takeover
        # is same-identity by construction, so the claim commit stays the honest answer
        # to "whose loop is this" even after several hand-offs.
        #
        # NO FIELD OF THIS ROW MAY BE EMPTY EXCEPT THE LAST. A tab is an IFS *whitespace*
        # character, so `read` with IFS=<tab> collapses a run of tabs into one delimiter
        # -- an empty middle field silently vanishes and every field after it shifts left.
        # That is not theoretical: it is what an empty `resume_reason` did on first
        # implementation, handing plan-units.sh the artifact list in the reason slot and
        # an empty artifact list, which would have let the survey offer a ticket a claim
        # already held. The artifact list is last precisely because a trailing empty field
        # is the one case `read` handles correctly.
        _cs_author=$(git log -1 --format='%ae' "$_cs_sha" 2>/dev/null || true)
        [ -n "$_cs_author" ] || _cs_author="unknown"
        [ -n "$_cs_at" ] || _cs_at="unknown"

        # The resumability verdict (see the header). Identity first: a foreign claim is
        # untouchable at any age, so its liveness never even needs measuring.
        if [ -z "$_cs_me" ]; then
            _cs_resumable=false
            _cs_reason=identity_unresolved
        elif [ "$_cs_author" != "$_cs_me" ]; then
            _cs_resumable=false
            _cs_reason=foreign_identity
        elif [ $((_cs_now - _cs_ct)) -lt "$_cs_hb_threshold" ]; then
            _cs_resumable=false
            _cs_reason=claim_active
        else
            _cs_resumable=true
            _cs_reason=heartbeat_lapsed
        fi

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$_cs_unit" "$_cs_branch" "$_cs_at" "$_cs_stale" \
            "$_cs_author" "$_cs_resumable" "$_cs_reason" "$_cs_artifacts"
    done
}
