#!/bin/sh -eu
# Refuse a body bound for ANOTHER repository that still names THIS one.
#
# Usage: check-outbound-body.sh <body-file>
# Emits JSON: { ok: true } or { ok: false, error }.
#
# This is a MECHANICAL BACKSTOP, not assurance. It knows only this repository's own
# name, its `owner/name` remote form, every form of its clone URL, and its absolute
# path — the things that are always mechanically knowable. It cannot know a customer's
# vocabulary; that is what the developer's verbatim confirmation is for, and a pass
# here means nothing beyond "our own name is absent".
#
# IT MATCHES AN IDENTIFIER, NOT A SUBSTRING (2026-08-02). The bare-name test used to be
# a case-insensitive plain `grep -F`, which refuses any body where this repo's basename
# appears anywhere at all — including inside a directory name belonging to the TARGET
# repo. A repo whose basename is an ordinary English word therefore could not raise any
# ask that listed paths on either side (`docs/<name>-reports/x.md -> docs/site-<name>/x.md`),
# and since the path list WAS the ask there was nothing to remove: the refusal was
# unconditional and its instruction ("mask it") named an action that did not exist.
# Worse, it fired AFTER the developer had already confirmed destination and body
# verbatim — this backstop is the one place a legitimate ask can be refused past the
# human gate, so its false-positive rate is a usability property and not only a safety
# one.
#
# The narrowing is about ADJACENCY, never about dropping checks. The `owner/name` remote
# form and the clone URL are matched exactly; the absolute-path test is exact and carries
# the real weight. Every refusal names the matched text and its line, so the next false
# positive is diagnosable rather than mysterious.
#
# IT MATCHES A REFERENCE, NOT A WORD (2026-08-12). The 08-02 narrowing fixed adjacency to
# *identifier* characters; it did not address prose. For a repository whose basename is an
# ordinary English word, a standalone occurrence is usually not a reference to the
# repository — it is just the language. Measured 2026-08-12 (qmu/workaholic#384) on a body
# that was a generated publish plan of about seventy path pairs: it was refused on two
# lines naming no repository — the plan's own heading, and a line carrying a published
# article's title that has to be reproduced verbatim because it doubles as the
# destination's sidebar label. Masking that title would mean changing a published page's
# title to satisfy a lint, so once again "mask it" named an action that did not exist,
# after the human gate.
#
# So the bare name is refused only where it READS AS A REFERENCE: inside backticks (code
# formatting marks it as a token rather than prose), or directly beside a
# repository-indicating noun — `<name> repo|repository|checkout|worktree|project`, the
# possessive `<name>'s repo`, and the reversed `repository <name>` — in either order and
# case-insensitively.
#
# WHAT THIS GIVES UP, stated rather than glossed: an UNQUALIFIED bare mention in prose
# ("a ticket that still says <name> in the text") now passes. So does a qualifier outside
# the short literal noun list, including its plurals — the list is deliberately not grown
# speculatively, because a missed qualifier is the same trade this change already accepts.
# What still holds: every exact rule above is untouched and carries the real weight (each
# clone-URL form, the `owner/name` slug, the absolute path), and the developer's verbatim
# confirmation of destination and body remains the actual control — this was never
# assurance. There is deliberately NO skip flag: an escape hatch reachable by the agent the
# backstop exists to constrain turns a mechanical check into an optional one.

set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"
. "${SCRIPT_DIR}/lib/remote-url.sh"

emit_err() {
    printf '{"ok": false, "error": "%s"}\n' "$1"
    exit 0
}

body_file="${1:-}"
[ -n "$body_file" ] || emit_err "no body file given"
[ -f "$body_file" ] || emit_err "body file not found: ${body_file}"
[ -s "$body_file" ] || emit_err "body is empty — nothing to send"

SOURCE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source_name="$(basename -- "$SOURCE_ROOT")"

# The first `grep -n` hit for a pattern, or empty. `|| true` because grep exits 1 on no
# match and this script runs under `set -e`.
first_fixed() { grep -n -i -F -- "$1" "$2" 2>/dev/null | head -1 || true; }
first_ere()   { grep -n -i -E -- "$1" "$2" 2>/dev/null | head -1 || true; }

# "<line>: <text>" from a `grep -n` hit, trimmed so the message stays one line.
cite() { printf '%s' "$1" | cut -c1-160 | tr -d '"\\' ; }

# EVERY FORM OF THE URL IS CHECKED, NOT JUST ONE. git rewrites remote URLs through
# insteadOf rules, so `git remote get-url` and `git config --get remote.origin.url` can
# name the same repository differently (see lib/remote-url.sh). A developer pastes
# whichever form their tooling showed them — GitHub's UI gives the canonical one, their
# shell gives the rewritten one — so matching a single form is a backstop that silently
# stops firing under a rewrite.
#
# That was measured, not imagined. In the container the hourly runner uses, the injected
# `url.https://github.com/.insteadOf = git@github.com:` rule meant a body containing this
# repository's literal `git@github.com:owner/repo.git` clone URL did NOT match the
# clone-URL rule at all; it fell through to the unrelated `owner/name` rule, which refused
# it while naming the wrong thing to mask. Widening a backstop is the conservative
# direction: the cost of an extra form is one more grep, and the cost of a missing one is
# a check that reads as passing.
source_forms="$(remote_url_forms "$SOURCE_ROOT")"

# TWO PASSES, URLS BEFORE SLUGS, AND THE ORDER IS LOAD-BEARING. Every clone URL contains
# its own `owner/name`, so a single interleaved pass would let form A's slug rule fire on a
# body carrying form B's full URL — refusing correctly but naming the wrong thing to mask,
# which is the exact defect the widening exists to fix. The most specific rule must be
# exhausted across all forms before the more general one is tried.
#
# Both passes run in THIS shell, never behind a pipe: emit_err exits, and an exit inside a
# subshell would leave the script running past a refusal it had already printed. IFS is
# pinned to newline because `remote_url_forms` emits one URL per line.
old_ifs="$IFS"

IFS='
'
for form in $source_forms; do
    IFS="$old_ifs"
    [ -n "$form" ] || { IFS='
'; continue; }
    hit="$(first_fixed "$form" "$body_file")"
    [ -z "$hit" ] || emit_err "body still contains this repository's clone URL at line $(cite "$hit") — mask it and re-confirm"
    IFS='
'
done
IFS="$old_ifs"

# The `owner/name` each form implies. Distinct URL forms of one repository normally imply
# the SAME slug, so the repeated check is a no-op rather than a second rule.
IFS='
'
for form in $source_forms; do
    IFS="$old_ifs"
    slug="$(printf '%s' "$form" | sed -e 's#\.git$##' -e 's#^.*[:/]\([^/][^/]*\)/\([^/][^/]*\)$#\1/\2#')"
    case "$slug" in
        */*)
            hit="$(first_fixed "$slug" "$body_file")"
            [ -z "$hit" ] || emit_err "body still names this repository as '${slug}' at line $(cite "$hit") — mask it and re-confirm"
            ;;
    esac
    IFS='
'
done
IFS="$old_ifs"

hit="$(first_fixed "$SOURCE_ROOT" "$body_file")"
[ -z "$hit" ] || emit_err "body still contains this repository's path at line $(cite "$hit") — mask it and re-confirm"

# The bare name, where it reads as a REFERENCE. Two conditions have to hold together.
#
# Adjacency to identifier characters (unchanged, 2026-08-02): a neighbouring alphanumeric,
# `-`, `_` or `/` means the name is part of some OTHER identifier — `<name>-reports/`,
# `site-<name>/` — which is not a mention at all.
#
# Adjacency to a qualifier (2026-08-12): a backtick on either side, or one of the five
# repository-indicating nouns directly before or after it, with an optional possessive.
# Everything else is prose and passes. The noun list is short and literal on purpose.
name_re="$(printf '%s' "$source_name" | sed -e 's/[][\\.^$*+?(){}|/-]/\\&/g')"
bt='`'
lb='(^|[^A-Za-z0-9_/-])'
rb='([^A-Za-z0-9_/-]|$)'
noun='(repo|repository|checkout|worktree|project)'
poss="('s|’s)?"
ref_re="${bt}${name_re}${rb}"
ref_re="${ref_re}|${lb}${name_re}${bt}"
ref_re="${ref_re}|${lb}${name_re}${poss}[[:space:]]+${noun}${rb}"
ref_re="${ref_re}|${lb}${noun}[[:space:]]+${name_re}${rb}"
hit="$(first_ere "$ref_re" "$body_file")"
[ -z "$hit" ] || emit_err "body still names this repository ('${source_name}') at line $(cite "$hit") — mask it and re-confirm"

printf '{"ok": true}\n'
