#!/bin/sh -eu
# Does a ticket DESCRIBE the work or ADVANCE it? Read from the ticket's own paths.
#
# WHY (2026-08-23). `attributed-work.sh` attributes work through
# `strategy.feedback[] ∩ artifact.feedback[]`, and **a page about the work cites the same ref
# the work would** — so the two are indistinguishable by construction. `survey-strategies.sh`
# then reads `waiting_count > 0` as `work_waiting` and proposes nothing further for that
# strategy until the queue drains. That is what made the measured loop self-sustaining: each
# documentation mission queued documentation tickets, which kept `work_waiting` true, which
# prevented any proposal that might have been the build; when they merged the gate lifted and
# the next documentation move was named.
#
# THE RULING (the ticket's Open Decision, ruled while driving it). Three shapes were offered:
#
#   (a) Carry the proposal's `move` onto what `/specificate` emits. **Refused**: it can only
#       label work the loop itself produced. Work a person filed carries no move and stays
#       indistinguishable — and that residue is precisely what the Considerations say to
#       design against. It also puts a field on the mission, which the 2026-08-17 no-new-field
#       ruling refused for attribution and which this does not need.
#   (b) Derive it from the ticket's own paths. **Chosen.** No field, no relation, no stored
#       state, and it covers a ticket however it entered the queue.
#   (c) Drop `work_waiting` for a build-aim strategy entirely. **Refused**: that strategy then
#       loses its in-flight brake and can accumulate parallel proposals, which is the failure
#       `work_waiting` was added to prevent.
#
# THE STATED COST OF (b), AND WHY IT IS COVERED. It is a heuristic, and a repository whose
# product *is* documentation inverts it — every ticket would read `describing` while being the
# real work. That is the same inversion the sibling ticket exempts **by Aim**, and the same
# exemption covers it here: this classification is consulted only for a strategy whose Aim is
# to build. Judging the Aim is not this script's job and is not mechanised anywhere — it is the
# judgment `/propose` already makes for `describing_move`, and it stays there
# (`survey-strategies.sh --aim-kind`).
#
# THIS IS NOT A SECOND ATTRIBUTION PATH. It answers "what kind of work is this ticket",
# never "whose strategy is it" — `attributed-work.sh` remains the one reader of attribution,
# and the retired `strategy:` relation does not return.
#
# THE CLASSIFICATION, and it is deliberately coarse:
#   describing  every path the ticket's `## Key Files` names lies under a documentation area
#   advancing   any named path lies outside them
#   unknown     no `## Key Files` section, no path in it, or the file cannot be read
#
# `unknown` COUNTS AS ADVANCING AT THE GATE, not here. This script reports three values; the
# consumer keeps the brake on for `unknown`, because mislabelling build work as descriptive
# lets parallel proposals accumulate — the failure the gate exists to prevent — while the
# opposite error only delays one proposal by a tick.
#
# Usage: work-kind.sh <ticket-path>...
# Output: one JSON line
#   {"kind": "describing|advancing|unknown", "counts": {...}, "tickets": [{path, kind, paths}]}
#   `kind` is the whole set's verdict: `advancing` if any ticket advances, `describing` if at
#   least one describes and none advances, else `unknown`.

set -eu

# A documentation area: the specification tree, the knowledge bundle, and a top-level markdown
# file. Anything else — source, configuration, workflows, scripts — is the product.
is_doc_path() {
    case "$1" in
        docs/*|doc/*|.workaholic/*|report/*) return 0 ;;
        */docs/*|*/doc/*)                    return 0 ;;
        *.md)
            # A markdown file inside a code tree is documentation of that code; one at the
            # root (README, CLAUDE.md) is documentation too. Both describe.
            return 0 ;;
    esac
    return 1
}

rows=''
sep=''
n_desc=0
n_adv=0
n_unk=0

for t in "$@"; do
    [ -n "$t" ] || continue
    if [ ! -f "$t" ]; then
        rows="${rows}${sep}$(printf '{"path": "%s", "kind": "unknown", "paths": 0}' "$t")"
        sep=', '; n_unk=$((n_unk + 1)); continue
    fi
    # Backticked paths inside `## Key Files`, up to the next heading. The section is a list a
    # human wrote, so the paths are extracted rather than parsed at a position.
    paths=$(awk '
        /^## Key Files/ { inside = 1; next }
        /^## / { inside = 0 }
        inside { print }
    ' "$t" 2>/dev/null | grep -o '`[^`]*`' | tr -d '`' \
        | grep -E '^[A-Za-z0-9._][A-Za-z0-9._/-]*\.[A-Za-z0-9]+$' | sort -u || true)
    count=$(printf '%s' "$paths" | grep -c '[^[:space:]]' || true)
    if [ "$count" -eq 0 ]; then
        rows="${rows}${sep}$(printf '{"path": "%s", "kind": "unknown", "paths": 0}' "$t")"
        sep=', '; n_unk=$((n_unk + 1)); continue
    fi
    kind=describing
    for p in $paths; do
        if ! is_doc_path "$p"; then kind=advancing; break; fi
    done
    rows="${rows}${sep}$(printf '{"path": "%s", "kind": "%s", "paths": %s}' "$t" "$kind" "$count")"
    sep=', '
    if [ "$kind" = advancing ]; then n_adv=$((n_adv + 1)); else n_desc=$((n_desc + 1)); fi
done

if [ "$n_adv" -gt 0 ]; then verdict=advancing
elif [ "$n_desc" -gt 0 ]; then verdict=describing
else verdict=unknown
fi

printf '{"kind": "%s", "counts": {"describing": %s, "advancing": %s, "unknown": %s}, "tickets": [%s]}\n' \
    "$verdict" "$n_desc" "$n_adv" "$n_unk" "$rows"
