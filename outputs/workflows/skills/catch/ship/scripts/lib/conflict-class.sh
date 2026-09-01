#!/bin/sh
# THE ONE CLASSIFICATION RULE FOR A MERGE CONFLICT ON THIS TREE (2026-08-29, mission
# `land-the-loop-s-own-work-when-the-base-moves-under-it`).
#
# Two scripts ask the same question about one conflict and must never answer it differently:
#
#   ship/scripts/catchup-main.sh          the WRITER. It performs the merge, resolves what it
#                                         can prove is a pure append, and classifies the rest.
#   drive/scripts/claim-mergeability.sh   the READER. It predicts the same outcome from
#                                         `git merge-tree`, which touches no worktree.
#
# The reader exists so a claim branch can be told apart from a claim branch a person must look
# at BEFORE anything is checked out. A second copy of the rule would let the two disagree, and
# the dangerous direction is specific: the writer RESOLVES an append-only `.workaholic/`
# conflict, so a reader that classified those as `content` would report *a human must decide*
# for exactly the concurrent pairs the resolution was written for — every pair of units that
# each appended a `## Changelog` line. That is the whole mission turning into a no-op.
#
# WHAT LIVES HERE IS THE TEST, NOT THE RESOLUTION. Building the kept-both tail (dedup, the
# date-led sort, the merge-order fallback) is the writer's alone: only the writer needs a
# merged file, and moving it here would give the reader a code path it must never run. The
# reasoning behind each rule stays in `catchup-main.sh`'s header, which is where a reader of
# either script is sent.
#
# Sourced, never executed. Every function is a predicate: 0 means yes.

# Is the append-only shape test even allowed to look at this path? Bounded to `.workaholic/`
# deliberately — appending is only EVIDENCE OF INDEPENDENCE in a log. Two branches each
# appending a function to the end of a source file have the same shape and a genuine content
# decision behind it (`catchup-main.sh`, *THE SCOPE RULE IS SHAPE, BOUNDED BY PATH*).
conflict_class_append_scope() {
    case "$1" in
        .workaholic/*) return 0 ;;
        *) return 1 ;;
    esac
}

# Does this conflict's SHAPE prove both sides only appended?
#   $1 = path, $2 = merge-base file, $3 = ours file, $4 = theirs file.
#
# The proof is that the merge base is an exact LINE-PREFIX of both sides: nothing existing was
# modified or removed. It is self-verifying, so it covers files added to the tree later and can
# never be wrong about a file it accepts, where a hand-maintained path list drifts. Every
# failure mode is conservative by construction — a missing stage (an add/add or a
# delete/modify), an empty merge base (which would make every line an "append" and concatenate
# two independently written files), or an unreadable side all answer NO.
conflict_class_append_only() {
    conflict_class_append_scope "$1" || return 1
    _ccl_anc="$2"
    _ccl_ours="$3"
    _ccl_theirs="$4"
    [ -f "$_ccl_anc" ] && [ -f "$_ccl_ours" ] && [ -f "$_ccl_theirs" ] || return 1

    _ccl_n=$(wc -l < "$_ccl_anc" | tr -d ' ')
    case "$_ccl_n" in '' | *[!0-9]*) return 1 ;; esac
    [ "$_ccl_n" -gt 0 ] || return 1

    head -n "$_ccl_n" "$_ccl_ours"   | cmp -s - "$_ccl_anc" || return 1
    head -n "$_ccl_n" "$_ccl_theirs" | cmp -s - "$_ccl_anc" || return 1
    return 0
}

# Is this path routine reconciliation rather than a judgement? A STRICT allowlist — the
# version/lockstep manifests and generated output — because anything else is content by
# definition, and a permissive rule here is a machine resolving a decision a person owns.
conflict_class_mechanical_path() {
    conflict_class_generated_path "$1" && return 0
    conflict_class_version_manifest "$1" && return 0
    return 1
}

# The whole mechanical test: the path allowlist, or a flat area's index whose difference the
# proof below shows is purely generated. Both the writer and the reader call THIS, with the
# same three blobs, so neither can classify a conflict the other would not.
#   $1 = path, $2 = merge-base file, $3 = ours file, $4 = theirs file.
conflict_class_mechanical() {
    conflict_class_mechanical_path "$1" && return 0
    conflict_class_generated_region "$1" "$2" "$3" "$4" && return 0
    return 1
}

# Generated output: its correct content is DERIVED from the merged source, so the resolution
# is "take either side and regenerate" and cannot lose information. Which side is taken is
# immaterial by construction, which is exactly why this is separable from the manifests.
#
# `.workaholic/index.md`, `missions/index.md` and `trips/index.md` are here because
# `okf/scripts/refresh-index.sh` writes each of them WHOLESALE, deterministically, from what is
# on disk. The list is a copy of that script's own unconditional `write_index` calls and is
# coupled to them: adding a fourth there means adding it here, and the reverse.
conflict_class_generated_path() {
    case "$1" in
        outputs/*) return 0 ;;
        .workaholic/index.md) return 0 ;;
        .workaholic/missions/index.md) return 0 ;;
        .workaholic/trips/index.md) return 0 ;;
        *) return 1 ;;
    esac
}

# THE OKF INDEXES ARE GENERATED, NOT APPENDED — the finding that decided this rule
# (2026-08-29). The append-only shape proof refuses them correctly and for the right reason:
# `refresh-index.sh` emits a SORTED list derived from the tree, so archiving a mission MOVES a
# line from `## active` to `## archive` and inserts it in sorted position. Nothing about that is
# an append. Measured on this repository the same day: every one of the seven live claim
# branches read `content`, and on the four that were otherwise mechanical the ONLY content
# paths were `.workaholic/missions/index.md` and `.workaholic/stories/index.md` — so a rule
# that stopped at the append-only test would have left the mission a no-op on exactly the
# concurrent pairs it exists for.
#
# A FLAT AREA'S INDEX IS HALF GENERATED, so it gets a proof rather than a path match.
# `refresh-index.sh` owns only the bytes between `<!-- okf:generated:begin -->` and
# `<!-- okf:generated:end -->` and preserves a human's prose outside them verbatim. So this
# answers yes only when NEITHER side changed anything outside the region: then re-deriving the
# region is a complete resolution and nothing a person wrote can be lost. A hand-authored
# index with no markers — which `refresh-index.sh` never writes — falls through to `content`,
# which is the correct answer for a file no regeneration would repair.
#   $1 = path, $2 = merge-base file, $3 = ours file, $4 = theirs file.
conflict_class_generated_region() {
    case "$1" in
        .workaholic/*/index.md) ;;
        *) return 1 ;;
    esac
    _ccr_anc="$2"
    _ccr_ours="$3"
    _ccr_theirs="$4"
    [ -f "$_ccr_anc" ] && [ -f "$_ccr_ours" ] && [ -f "$_ccr_theirs" ] || return 1

    for _ccr_f in "$_ccr_anc" "$_ccr_ours" "$_ccr_theirs"; do
        grep -qF '<!-- okf:generated:begin -->' "$_ccr_f" || return 1
        grep -qF '<!-- okf:generated:end -->' "$_ccr_f" || return 1
    done

    _ccr_a=$(conflict_class_outside_region "$_ccr_anc")
    [ "$(conflict_class_outside_region "$_ccr_ours")" = "$_ccr_a" ] || return 1
    [ "$(conflict_class_outside_region "$_ccr_theirs")" = "$_ccr_a" ] || return 1
    return 0
}

# Everything a file holds OUTSIDE its generated region, markers kept so their position counts
# as prose too. Used only by the proof above.
conflict_class_outside_region() {
    awk '
        /<!-- okf:generated:begin -->/ { inside = 1; print; next }
        /<!-- okf:generated:end -->/   { inside = 0; print; next }
        !inside { print }
    ' "$1" 2>/dev/null || true
}

# A version/lockstep manifest: every `"version"` in these files carries the SAME semver by the
# repository's own rule (`CLAUDE.md`, *Version Management*), so two branches that each bumped
# collide on the version and on nothing else. That makes the collision resolvable without a
# judgement — take the higher version — while the rest of the file merges normally.
conflict_class_version_manifest() {
    case "$1" in
        .claude-plugin/marketplace.json) return 0 ;;
        plugins/workaholic/.claude-plugin/plugin.json) return 0 ;;
        plugins/workaholic/.codex-plugin/plugin.json) return 0 ;;
        *) return 1 ;;
    esac
}
