#!/bin/sh -eu
# Recognise and reconcile the ONE conflict shape the .workaholic/ tree produces by
# construction: both sides only INSERTED lines, neither modified or removed one.
# Sourced by ship/scripts/catchup-main.sh; not executable on its own.
#
# WHY THIS EXISTS. `.workaholic/` is full of append-structured artifacts that both
# branches routinely extend -- a mission's `## Changelog` (every ticket archived,
# story reported and run recorded appends a line), and the OKF `index.md` files.
# When two units land concurrently, both append to the same tail and git reports a
# conflict whose resolution is unambiguous: keep both sides. Classifying that as
# "needs human judgement" cost the merge -- `/drive` demoted an `auto` unit to the
# PR path -- on EVERY concurrent pair, because both sides always touch the mission
# changelog and the story index.
#
# THE SCOPE IS RULED BY PATH, THE RESOLUTION IS RULED BY SHAPE. The ticket offered
# either test alone; neither alone is right, so this uses both and the reason is
# recorded here rather than rediscovered:
#
#   - Path alone is too weak. It would auto-reconcile a mission.md whose conflict is
#     a ticked `## Acceptance` box (`tick-acceptance.sh` MODIFIES a line) or a
#     regenerated index that reordered its entries. Neither is an append, and
#     "keep both sides" silently duplicates or reorders content there.
#   - Shape alone is too broad. An insertion-only union merge is a plausible answer
#     for any file, but it is only the CORRECT answer where the file has a single
#     append-only writer. Applied to implementation code it would silently
#     concatenate two independently added functions -- a real merge a human should
#     see. Widening auto-resolution to every path is not a change this defect asks
#     for.
#
# So: the path set below bounds where we are willing to auto-reconcile at all, and
# the shape test decides whether this particular conflict is actually an append.
# Anything failing either test stays `content` and halts the ship exactly as before.

# --- Scope -------------------------------------------------------------------
# A POSIX `case` glob's `*` spans `/`, so `.workaholic/*/index.md` matches an index
# at ANY depth and `.workaholic/missions/*/mission.md` matches `active/<slug>/`,
# `archive/<slug>/` and the legacy flat `<slug>/` layout alike. That is deliberate:
# it covers areas added later without a code change, which is the one advantage the
# pure-shape test had.
append_only_candidate() {
    case "$1" in
        .workaholic/index.md|.workaholic/*/index.md|.workaholic/missions/*/mission.md) return 0 ;;
        *) return 1 ;;
    esac
}

# --- Shape -------------------------------------------------------------------
# Deletions of <base> against <other>. A pure insertion deletes nothing, so a zero
# here IS "no existing line was modified or removed" -- git counts a modified line
# as one addition plus one deletion, and a reorder as both. Empty output means the
# two files are identical (also insertion-only, vacuously); a binary file reports
# "-", which is not "0" and therefore refuses.
_append_only_deletions() {
    git diff --no-index --numstat -- "$1" "$2" 2>/dev/null | awk 'NR==1{print $2}'
}

# Order a mission's `## Changelog` list lines by their leading date, so a merged
# changelog reads chronologically instead of in merge order (ours-block then
# theirs-block, which is what a union merge produces).
#
# HONEST FALLBACK (the ticket's Considerations): this is only well-defined while
# every list line in the section starts with a date. If even one does not, the
# lines are left in merge order rather than sorted on a key that is not there.
# Insertion sort with a strict `>` comparison is stable, so same-date lines keep
# their merge order, and only the list lines move -- any prose interleaved in the
# section stays where it is.
_append_only_order_changelog() {
    awk '
        { L[NR] = $0 }
        END {
            n = NR
            s = 0
            for (i = 1; i <= n; i++) if (L[i] ~ /^##[ \t]+Changelog[ \t]*$/) { s = i; break }
            if (s == 0) { for (i = 1; i <= n; i++) print L[i]; exit }
            e = n
            for (i = s + 1; i <= n; i++) if (L[i] ~ /^## /) { e = i - 1; break }
            c = 0; dated = 1
            for (i = s + 1; i <= e; i++) {
                if (L[i] ~ /^- /) {
                    c++; idx[c] = i
                    if (L[i] !~ /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] /) dated = 0
                }
            }
            if (dated && c > 1) {
                for (k = 1; k <= c; k++) v[k] = L[idx[k]]
                for (k = 2; k <= c; k++) {
                    cur = v[k]; cd = substr(cur, 3, 10); j = k - 1
                    while (j >= 1 && substr(v[j], 3, 10) > cd) { v[j + 1] = v[j]; j-- }
                    v[j + 1] = cur
                }
                for (k = 1; k <= c; k++) L[idx[k]] = v[k]
            }
            for (i = 1; i <= n; i++) print L[i]
        }
    ' "$1"
}

# --- Resolution --------------------------------------------------------------
# Reconcile one conflicted path in the worktree and stage it. Returns 0 only when
# the conflict really was an append on both sides AND the merged file was written;
# every other outcome returns 1 and leaves the path unmerged for the caller to
# classify.
#
# A missing stage 1 (an add/add conflict: both sides created the file) returns 1.
# There is no common ancestor to prove the shape against, and concatenating two
# independently created files is a different reconciliation from extending a shared
# tail -- so it goes to a human like any other unproven conflict.
append_only_resolve() {
    _ao_path="$1"
    _ao_tmp=$(mktemp -d 2>/dev/null) || return 1
    _ao_ok=1

    git show ":1:${_ao_path}" > "${_ao_tmp}/base" 2>/dev/null || _ao_ok=0
    git show ":2:${_ao_path}" > "${_ao_tmp}/ours" 2>/dev/null || _ao_ok=0
    git show ":3:${_ao_path}" > "${_ao_tmp}/theirs" 2>/dev/null || _ao_ok=0

    if [ "$_ao_ok" -eq 1 ]; then
        _ao_del_ours=$(_append_only_deletions "${_ao_tmp}/base" "${_ao_tmp}/ours")
        _ao_del_theirs=$(_append_only_deletions "${_ao_tmp}/base" "${_ao_tmp}/theirs")
        [ -n "$_ao_del_ours" ] || _ao_del_ours=0
        [ -n "$_ao_del_theirs" ] || _ao_del_theirs=0
        if [ "$_ao_del_ours" != "0" ] || [ "$_ao_del_theirs" != "0" ]; then
            _ao_ok=0
        fi
    fi

    # --union resolves every conflicting region by keeping both sides' lines, which
    # is exactly "keep both" once the shape test has established both sides only
    # inserted. The marker sweep is belt-and-braces: a merged file that still holds
    # conflict markers is never written back.
    if [ "$_ao_ok" -eq 1 ]; then
        git merge-file -p --union \
            "${_ao_tmp}/ours" "${_ao_tmp}/base" "${_ao_tmp}/theirs" \
            > "${_ao_tmp}/merged" 2>/dev/null || _ao_ok=0
    fi
    # The open/close markers alone: a bare run of `=` is a setext heading underline in
    # ordinary markdown, so matching it would refuse legitimate prose. (Written as a
    # repetition rather than a literal run because the POSIX lint reads a literal
    # `<<<` as a here-string wherever it appears, quoted or not.)
    if [ "$_ao_ok" -eq 1 ]; then
        if grep -qE '^(<{7}|>{7})' "${_ao_tmp}/merged"; then
            _ao_ok=0
        fi
    fi

    if [ "$_ao_ok" -eq 1 ]; then
        case "$_ao_path" in
            */mission.md)
                if _append_only_order_changelog "${_ao_tmp}/merged" > "${_ao_tmp}/ordered" 2>/dev/null; then
                    mv "${_ao_tmp}/ordered" "${_ao_tmp}/merged"
                fi
                ;;
        esac
        cp "${_ao_tmp}/merged" "$_ao_path" 2>/dev/null || _ao_ok=0
    fi
    if [ "$_ao_ok" -eq 1 ]; then
        git add -- "$_ao_path" >/dev/null 2>&1 || _ao_ok=0
    fi

    rm -rf "$_ao_tmp"
    [ "$_ao_ok" -eq 1 ]
}
