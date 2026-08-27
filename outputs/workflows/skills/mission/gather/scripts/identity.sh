#!/bin/sh -eu
# Resolve WHO A PERSON IS — the one reader of the `.claude/git-identities` mapping.
#
# The mapping is a committed, repo-root file, one line per person:
#
#   <github-login>=<canonical-address>[,<alias>...]
#
# The FIRST field after `=` is canonical; every field after it is another address
# of the same person. A line with no comma is exactly what the format was before
# 2026-08-26, so every file already committed stays valid and the bootstrap hook's
# own parse keeps working — which is what made this change safe to land before any
# of its consumers.
#
# WHY THIS FILE EXISTS (2026-08-26). A person's addresses were nameable only one at
# a time, so a developer with a second address had no way to say the two are one
# person. Every consumer that compares addresses therefore answered `other`:
# measured on this repository, `tamurayoshiya=a@qmu.jp` was committed while two
# active missions and five queued tickets carried `tamura.yoshiya@gmail.com`, and
# `plan-units.sh` excluded all seven as `owned_by_other` for five days while every
# hourly tick reported a clean, empty survey.
#
# IT NEVER GUESSES. An absent file, an absent entry and an unparseable line each
# answer `resolved: false` and echo the input straight back as `canonical` — the
# identity function, so a caller that resolves unconditionally behaves EXACTLY as
# the tree behaved before this script existed. A caller that must act on the
# difference (write a `--assignee`, ask a person about an address nobody maps)
# reads `resolved` and the named `reason`. Guessing an address is the one failure
# mode this whole change exists to remove: a wrong address is silently
# unrecoverable, while an unresolved one is a state every consumer already handles.
#
# THE MAPPING IS A CLAIM, AND ANYONE WHO CAN COMMIT CAN MAKE IT. Saying that two
# addresses are one person is the same trust boundary the file already carried for
# `<login>=<email>`, so the second field adds no new authority — it widens what one
# entry can say, not who may say it. The emails are public in git history already,
# which is why the file is committed at all.
#
# THE ONE OTHER PARSER IS DELIBERATE. `workaholify/bootstrap/session-start.sh`
# step 0b reads the same file and cannot call this script: it is copied to
# `.claude/hooks/` and runs at SessionStart, BEFORE the plugin is installed, so
# there is nothing to call. It takes the canonical field with a `cut -d, -f1` on
# the value it already extracted — the identity function on a line with no comma.
# That exception is stated in both headers so a later reader finding the second
# parse knows it is a decision rather than a bug.
#
# Usage: identity.sh <login-or-address> [mapping-file]
#   mapping-file defaults to `<repo root>/.claude/git-identities`, resolved through
#   git; `WORKAHOLIC_IDENTITY_MAP` overrides it (a data source, never a gate).
#
# Output: one JSON object on stdout. Always exit 0 — an unresolvable input is an
# answer, not an error.
#
#   {"resolved": true|false,
#    "input": "<what was asked>",
#    "kind": "login"|"address"|"unknown",
#    "login": "<the mapped login, or empty>",
#    "canonical": "<the canonical address, or the input echoed back>",
#    "addresses": ["<canonical>", "<alias>", ...],
#    "reason": ""|"no_input"|"no_mapping_file"|"no_entry",
#    "unparseable_lines": <count>}
#
# Matching: a LOGIN matches exactly (a login is a token, and the bootstrap's own
# lookup is exact). An ADDRESS matches by SLUG (gather/scripts/user-slug.sh), the
# same comparison `owns.sh` has always used, so `A@Qmu.jp` and `a@qmu.jp` are one
# address here for the same reason they are one owner there. A login is tried
# first: the two shapes do not overlap in practice, and the caller that asks with
# a login (an issue's assignee) is asking about a login.

set -eu

INPUT="${1:-}"
MAP="${2:-}"

SCRIPT_DIR=$(dirname "$0")

emit() {
    # $1 resolved, $2 kind, $3 login, $4 canonical, $5 reason, $6 addresses (newline-sep)
    _addrs=""
    for _a in $6; do
        if [ -z "$_addrs" ]; then _addrs="\"$_a\""; else _addrs="${_addrs}, \"$_a\""; fi
    done
    printf '{"resolved": %s, "input": "%s", "kind": "%s", "login": "%s", "canonical": "%s", "addresses": [%s], "reason": "%s", "unparseable_lines": %s}\n' \
        "$1" "$INPUT" "$2" "$3" "$4" "$_addrs" "$5" "${UNPARSEABLE:-0}"
}

UNPARSEABLE=0

if [ -z "$INPUT" ]; then
    emit false unknown "" "" no_input ""
    exit 0
fi

if [ -z "$MAP" ]; then
    MAP="${WORKAHOLIC_IDENTITY_MAP:-}"
fi
if [ -z "$MAP" ]; then
    root=$(git rev-parse --show-toplevel 2>/dev/null || true)
    [ -n "$root" ] || root="."
    MAP="${root}/.claude/git-identities"
fi

if [ ! -f "$MAP" ]; then
    emit false unknown "" "$INPUT" no_mapping_file "$INPUT"
    exit 0
fi

# Normalize the file to `login<TAB>value` rows, dropping comments, blanks and any
# line that is not `<login>=<value>` with both halves non-empty. A malformed line
# is COUNTED rather than fatal: one bad row must not make the whole mapping
# unreadable, and a silent skip would hide the very thing an operator has to fix.
rows=$(awk -F= '
/^[[:space:]]*#/ { next }
/^[[:space:]]*$/ { next }
{
    login = $1
    sub(/^[[:space:]]+/, "", login); sub(/[[:space:]]+$/, "", login)
    if (NF < 2 || login == "") { bad++; next }
    value = $0
    sub(/^[^=]*=/, "", value)
    sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value)
    if (value == "") { bad++; next }
    printf "%s\t%s\n", login, value
}
END { printf "#bad\t%d\n", bad + 0 }
' "$MAP" 2>/dev/null || true)

UNPARSEABLE=$(printf '%s\n' "$rows" | sed -n 's/^#bad\t//p' | head -n 1)
[ -n "$UNPARSEABLE" ] || UNPARSEABLE=0
rows=$(printf '%s\n' "$rows" | grep -v '^#bad	' || true)

input_slug=$(sh "${SCRIPT_DIR}/user-slug.sh" "$INPUT" 2>/dev/null || true)

# Pass 1: the input as a LOGIN, matched exactly.
#
# Rows are read through a here-document rather than a pipe: a pipe would run the
# loop in a subshell and the match could not be carried back out — the same reason
# owns.sh spells its own comparison loop out longhand.
match_login=""
match_value=""
kind=""
while IFS= read -r row; do
    [ -n "$row" ] || continue
    login=${row%%	*}
    value=${row#*	}
    if [ "$login" = "$INPUT" ]; then
        match_login=$login
        match_value=$value
        kind=login
        break
    fi
done <<ROWS
$rows
ROWS

# Pass 2: the input as an ADDRESS, matched by slug against every field of a row.
if [ -z "$match_login" ] && [ -n "$input_slug" ]; then
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        login=${row%%	*}
        value=${row#*	}
        hit=0
        for addr in $(printf '%s' "$value" | tr ',' ' '); do
            addr_slug=$(sh "${SCRIPT_DIR}/user-slug.sh" "$addr" 2>/dev/null || true)
            if [ -n "$addr_slug" ] && [ "$addr_slug" = "$input_slug" ]; then
                hit=1
                break
            fi
        done
        if [ "$hit" -eq 1 ]; then
            match_login=$login
            match_value=$value
            kind=address
            break
        fi
    done <<ROWS
$rows
ROWS
fi

if [ -z "$match_login" ]; then
    emit false unknown "" "$INPUT" no_entry "$INPUT"
    exit 0
fi

addresses=$(printf '%s' "$match_value" | tr ',' ' ')
canonical=""
for addr in $addresses; do
    canonical=$addr
    break
done

emit true "$kind" "$match_login" "$canonical" "" "$addresses"
