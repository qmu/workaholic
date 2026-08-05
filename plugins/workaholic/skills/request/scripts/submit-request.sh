#!/bin/sh -eu
# Submit a confirmed, masked request as a ticket to ANOTHER repository.
#
# Usage: submit-request.sh <target-repo-root> <ticket-filename> <body-file>
#
# This is the ONLY sanctioned writer of a cross-repository artifact. Everything else is
# refused by hooks/guard-repo-confinement.sh. That guard watches the Write/Edit tools and
# does not see a script like this one — which is the point: the casual path is closed and
# the deliberate path runs here, where the caller has already shown the developer exactly
# what will be submitted and had them confirm it.
#
# This script does NOT mask and does NOT judge. By the time it runs, the body is already
# masked and confirmed. It refuses only the mechanical mistakes: a target that is not a
# repo, a body that is empty, a filename that is not ticket-shaped, and — as a last
# backstop, not a substitute for the confirmation — a body still carrying this repo's own
# name or path.
#
# Emits JSON: { ok, path } or { ok: false, error }.

set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"
. "${SCRIPT_DIR}/lib/remote-url.sh"

emit_err() {
    printf '{"ok": false, "error": "%s"}\n' "$1"
    exit 0
}

target="${1:-}"
filename="${2:-}"
body_file="${3:-}"

[ -n "$target" ]    || emit_err "no target repo given"
[ -n "$filename" ]  || emit_err "no filename given"
[ -n "$body_file" ] || emit_err "no body file given"
[ -f "$body_file" ] || emit_err "body file not found: ${body_file}"
[ -s "$body_file" ] || emit_err "body is empty — nothing to submit"

printf '%s' "$filename" | grep -qE '^[0-9]{14}-[a-z0-9-]+\.md$' \
    || emit_err "filename must be YYYYMMDDHHmmss-kebab-slug.md, got: ${filename}"

git -C "$target" rev-parse --show-toplevel >/dev/null 2>&1 || emit_err "not a git repository: ${target}"
target_root="$(git -C "$target" rev-parse --show-toplevel)"

SOURCE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ "$target_root" != "$SOURCE_ROOT" ] || emit_err "target is this repository — use /ticket, not /request"

# Last backstop. Deterministic, and deliberately narrow: it knows only this repo's own
# name, remote and path, which are the things always mechanically knowable. It cannot know
# a customer's vocabulary — that is what the confirmation is for, and a pass here means
# nothing beyond "our own name is absent".
#
# IT MATCHES AN IDENTIFIER, NOT A SUBSTRING (2026-08-02). The bare-name test used to be a
# case-insensitive plain `grep -F`, which refuses any body where this repo's basename
# appears anywhere at all — including inside a directory name belonging to the TARGET repo.
# A repo whose basename is an ordinary English word therefore could not submit a request
# that listed paths on either side (`docs/<name>-reports/x.md -> docs/site-<name>/x.md`),
# and since the path list WAS the ticket there was nothing to remove: the refusal was
# unconditional and its instruction ("mask it") could not be followed. Worse, it fired
# AFTER the developer had already confirmed destination and body verbatim — this backstop
# is the one place a legitimate request can be refused past the human gate, so its
# false-positive rate is a usability property and not only a safety one.
#
# The narrowing is about ADJACENCY, never about dropping checks. The two forms an actual
# reference takes — the `owner/name` remote form and the clone URL — are matched exactly
# and are new; the absolute-path test is untouched (an exact match with no false-positive
# mode, and the check that carries the real weight); and the bare name still refuses a
# standalone mention, declining only when it is glued to a neighbouring identifier
# character. Every refusal now names the matched text and its line, so the next false
# positive is diagnosable rather than mysterious.
source_name="$(basename -- "$SOURCE_ROOT")"

# The first `grep -n` hit for a pattern, or empty. `|| true` because grep exits 1 on no
# match and this script runs under `set -e`.
first_fixed() { grep -n -i -F -- "$1" "$2" 2>/dev/null | head -1 || true; }
first_ere()   { grep -n -i -E -- "$1" "$2" 2>/dev/null | head -1 || true; }

# "<line>: <text>" from a `grep -n` hit, trimmed so the message stays one line.
cite() { printf '%s' "$1" | cut -c1-160 | tr -d '"\\' ; }

# The clone URL and the `owner/name` it implies. Both absent outside a repo with an
# origin, in which case those two checks simply do not apply.
#
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
source_slug=""
source_forms="$(remote_url_forms "$SOURCE_ROOT")"

# TWO PASSES, URLS BEFORE SLUGS, AND THE ORDER IS LOAD-BEARING. Every clone URL contains
# its own `owner/name`, so a single interleaved pass would let form A's slug rule fire on a
# body carrying form B's full URL — refusing correctly but naming the wrong thing to mask,
# which is the exact defect this change exists to fix. The most specific rule must be
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
            [ -n "$source_slug" ] || source_slug="$slug"
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

# The bare name, as a standalone identifier. A neighbouring alphanumeric, `-`, `_` or `/`
# means it is part of some OTHER identifier — `<name>-reports/`, `site-<name>/` — which is
# exactly the false positive this rule exists to stop refusing.
name_re="$(printf '%s' "$source_name" | sed -e 's/[][\\.^$*+?(){}|/-]/\\&/g')"
hit="$(first_ere "(^|[^A-Za-z0-9_/-])${name_re}([^A-Za-z0-9_/-]|\$)" "$body_file")"
[ -z "$hit" ] || emit_err "body still names this repository ('${source_name}') at line $(cite "$hit") — mask it and re-confirm"

user_slug="$(git -C "$target_root" config user.email 2>/dev/null | tr '@.' '--' || echo "")"
[ -n "$user_slug" ] || user_slug="$(git config user.email 2>/dev/null | tr '@.' '--' || echo unknown)"

dest_dir="${target_root}/.workaholic/tickets/todo/${user_slug}"
dest="${dest_dir}/${filename}"
[ -e "$dest" ] && emit_err "already exists: ${dest}"

mkdir -p "$dest_dir"
cp -- "$body_file" "$dest"

printf '{"ok": true, "path": "%s"}\n' "$dest"
