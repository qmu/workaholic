#!/bin/sh -eu
# THE ONE READER of a queued ticket's OPERATOR DEFERRAL declaration (2026-09-21, ticket
# `20260921180418-declare-an-operator-deferral-on-a-queued-ticket`).
#
# Usage: read-deferral.sh <ticket-path>
# Output: one JSON line, always, exit 0 in every case.
#   {"path": "<as given>", "deferred": true|false, "declared_reason": "<the operator's words>"}
#   {"path": "<as given>", "deferred": null, "declared_reason": "",
#    "readable": false, "reason": "<word>"}
#
# WHAT THE DECLARATION IS. An operator writes `deferred: <why>` into a QUEUED ticket's
# frontmatter. Presence alone is the hold; the value carries the reason, so the reason is
# visible where the hold is — the shape `verification_handoff:` already uses. **Absent means
# not deferred**, the `merge_policy` / `status:` convention this repository already holds, so
# every ticket written before this existed reads exactly as it did.
#
# WHY A NEW KEY RATHER THAN `status: icebox`, decided at the ticket and recorded here so a
# later reader does not "simplify" the two together. (1) In this repository's vocabulary
# `done`, `abandoned` and `icebox` all mean *archived with that outcome* — `list-todo.sh` drops
# all three from the queue walk — while a deferred ticket stays **queued** and is **named** as
# held; an invisible ticket is the defect, not the repair. (2) One field answering two
# questions is the shape this repository has twice recorded as how two readings drift. So
# `status: icebox`, `promote-icebox.sh` and `list-icebox.sh` are byte-identical and untouched.
#
# THE COST, STATED: two parking concepts now stand side by side. Reach for `icebox` to park a
# ticket OUT of the queue (archived, promotable, invisible to the survey); reach for `deferred:`
# to hold a ticket IN the queue, counted and named, until the operator removes the line.
#
# REMOVAL IS THE ONLY RE-OFFER PATH. There is no promotion script, no flag and no stored
# cursor: the next survey reads the frontmatter again. Nothing in the loop writes or clears
# this key — a run that could defer its own work would be excusing itself, exactly as it may
# not declare its own `verification_handoff:`.
#
# AN ABSENCE OF A READING IS NEVER `deferred: false`. A file that is not there, cannot be read,
# carries no frontmatter, or carries a malformed declaration answers `deferred: null` with
# `readable: false` and a named reason. `readable` is ABSENT on a completed read — the
# convention every degradation reading here holds — so a consumer tests `readable == false` and
# never `readable // true`, because `false` is a real answer for `deferred`.
#
# MALFORMED IS ITS OWN ANSWER, not a silent pass. A bare `deferred:` with no value is ambiguous
# between *not deferred* and *deferred, reason unwritten*, and that collapse is the whole point
# of the field; a value opening `[` or `{` is a collection where one reason belongs. Both are
# refused at write time by `hooks/validate-ticket.sh` and read here as `malformed_declaration`,
# because a hand-edited or legacy file can still carry one.
#
# NOTHING ELSE IN THE TREE PARSES THE KEY. Two parsers of one field is how two readings drift;
# `plan-units.sh` composes this reader and re-derives nothing.
#
# PURE READ. No file, no commit, no branch, no network.

set -eu

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

emit_unreadable() {
    printf '{"path": "%s", "deferred": null, "declared_reason": "", "readable": false, "reason": "%s"}\n' \
        "$(json_escape "${1:-}")" "$2"
    exit 0
}

[ $# -ge 1 ] && [ -n "${1:-}" ] || emit_unreadable "" no_ticket_path
TICKET="$1"

[ -f "$TICKET" ] || emit_unreadable "$TICKET" ticket_not_found
[ -r "$TICKET" ] || emit_unreadable "$TICKET" ticket_unreadable

FIRST=$(head -n 1 "$TICKET" 2>/dev/null) || emit_unreadable "$TICKET" ticket_unreadable
[ "$FIRST" = "---" ] || emit_unreadable "$TICKET" no_frontmatter

# `present<TAB>value`, so a key that is there with an empty value is distinguishable from one
# that is not there at all — which is exactly the distinction the floor rests on. First match
# inside the leading `---` block wins, like every other frontmatter reader in the plugin.
LINE=$(awk '
    NR == 1 { if ($0 != "---") exit; next }
    /^---[ \t]*$/ { exit }
    index($0, "deferred:") == 1 {
        sub(/^deferred:[ \t]*/, ""); sub(/[ \t]+$/, "");
        printf "present\t%s", $0; exit
    }
' "$TICKET" 2>/dev/null) || emit_unreadable "$TICKET" ticket_unreadable

case "$LINE" in
    '')
        printf '{"path": "%s", "deferred": false, "declared_reason": ""}\n' "$(json_escape "$TICKET")"
        exit 0
        ;;
esac

VALUE=${LINE#present	}
[ -n "$VALUE" ] || emit_unreadable "$TICKET" malformed_declaration
case "$VALUE" in
    '['*|'{'*) emit_unreadable "$TICKET" malformed_declaration ;;
esac

printf '{"path": "%s", "deferred": true, "declared_reason": "%s"}\n' \
    "$(json_escape "$TICKET")" "$(json_escape "$VALUE")"
