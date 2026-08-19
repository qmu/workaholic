#!/bin/sh -eu
# Open a composed, scanned body as a GitHub issue — on another repository (the crossing)
# or on this one (the in-repo `/fb` path).
#
# Usage: open-issue.sh [--assignee <login>] <owner/name> <title> <body-file>
# Emits JSON: { ok, url, slug, requested_assignee, assignees, assigned }
#         or: { ok: false, error }.
#
# THE TARGET MAY BE THIS REPOSITORY, and saying so is the point of this sentence: the
# script was written for one destination — somebody else's tracker — and since the `/fb`
# unification (mission `register-every-fb-as-an-issue`) a destination-less `/fb` files an
# `[FB] ` issue HERE through this same writer. Only the shape check survives: the slug
# must be `owner/name`, and this repository's own slug is an accepted value rather than an
# oversight. There is deliberately no "is this us" branch — THE CALLER DECIDES THE
# DESTINATION, and a script that re-derived it would be a second, silent router.
#
# WIDENING THE DESTINATION DOES NOT WIDEN THE GATES, and this header is the only place
# that says so. When the target is another repository, composition in the target's
# vocabulary, the masking judgement, the developer's verbatim confirmation and
# `check-outbound-body.sh` all still run BEFORE this script is invoked; the in-repo path
# keeps the `secret` scan and drops the crossing-specific three, because nothing leaves
# the project (`reference/crossing.md`, *The in-repo path*). Either way the judgement is
# the caller's and none of it happens here.
#
# THE ASSIGNEE IS LOAD-BEARING, NOT COSMETIC. `[Specificate]`'s discovery
# (`propose/scripts/list-inbound-issues.sh`) lists only issues assigned to the running
# identity and deliberately never unassigned ones, so an unassigned in-repo `[FB]` issue
# would be ingested by nobody. THE LOGIN COMES FROM THE CALLER — `gh api user` is the
# caller's source, never this script's — so this script keeps having no identity opinion,
# exactly as it has no destination opinion. Absent flag → the payload carries no
# `assignees` key at all, byte-identical to what the crossing has always sent.
#
# AN ASSIGNMENT GITHUB SILENTLY DROPS IS REPORTED, NEVER ASSUMED: the API drops a login
# without access rather than refusing the request, so `assignees` echoes back what the
# response actually carries and `assigned` says whether the requested login is among them.
# A dropped assignment does NOT fail issue creation — a filed ask with no assignee is
# recoverable by hand, a lost ask is not.
#
# THIS IS THE ONLY SANCTIONED CROSSING, and it writes into no checkout at all. The
# earlier route copied a ticket file into the target's working tree, which meant the
# boundary crossing arrived as a file appearing in somebody else's `git status` — an
# artifact its owners had no native way to see, triage, or decline. An issue is the
# form the target already reads: its own [Specificate] routine ingests it like any other
# inbound report, and the recording and the proposal judgment happen inside the
# target's loop rather than ours.
#
# NOTHING HERE MASKS OR JUDGES. By the time this runs the body has been composed in the
# target's vocabulary, masked, shown to the developer verbatim and confirmed, and put
# through `scan-outbound-body.sh`. This script refuses only the mechanical mistakes and
# reports what `gh` said.
#
# A REFUSAL FROM `gh` IS REPORTED VERBATIM, NEVER WORKED AROUND. A target that has
# issues disabled, or that this identity cannot reach, is a fact about the boundary —
# retrying it another way would be routing around the target's own decision.
#
# REST, NOT `gh issue create` (2026-08-12, FB 20260812172522): the subcommand is
# GraphQL-backed and a Claude Code Web session may serve only "the pinned set of
# PR-review operations". THE CROSSING'S CONTRACT IS UNCHANGED, and that is the point of
# this conversion being the most conservative of the set: composition in the target's
# vocabulary, the masking judgment, the developer's verbatim confirmation of destination
# and body, `scan-outbound-body.sh` and `check-outbound-body.sh` all happen BEFORE this
# script is invoked and none of them move. What changes is only the wire call — the same
# request, the same target, the same body file, reported the same way.

set -eu

emit_err() {
    printf '{"ok": false, "error": "%s"}\n' "$(printf '%s' "$1" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
    exit 0
}

# `--assignee` is an OPTION, so the three positionals do not move and every existing
# caller's command line still means what it meant (the shape `create.sh` used when it
# took `--subject`).
assignee=""
saw_assignee=""
while [ $# -gt 0 ]; do
    case "$1" in
        --assignee)
            [ $# -ge 2 ] || emit_err "no login given for --assignee"
            assignee="$2"; saw_assignee=1
            shift 2
            ;;
        --assignee=*)
            assignee="${1#--assignee=}"; saw_assignee=1
            shift
            ;;
        --) shift; break ;;
        *) break ;;
    esac
done

# An EMPTY login is a refusal, not a silent fall-back to unassigned: a caller that meant
# to pass one and resolved nothing must hear about it rather than file an issue no
# discovery will ever list.
if [ -n "$saw_assignee" ]; then
    [ -n "$assignee" ] || emit_err "no login given for --assignee"
    printf '%s' "$assignee" | grep -qE '^[A-Za-z0-9][A-Za-z0-9-]*$' \
        || emit_err "assignee must be a GitHub login, got: ${assignee}"
fi

slug="${1:-}"
title="${2:-}"
body_file="${3:-}"

[ -n "$slug" ]  || emit_err "no target repository given"
[ -n "$title" ] || emit_err "no title given"
[ -n "$body_file" ] || emit_err "no body file given"
[ -f "$body_file" ] || emit_err "body file not found: ${body_file}"
[ -s "$body_file" ] || emit_err "body is empty — nothing to send"

printf '%s' "$slug" | grep -qE '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$' \
    || emit_err "target must be owner/name, got: ${slug}"

command -v gh >/dev/null 2>&1 || emit_err "gh is not available — cannot open an issue on ${slug}"

# THE TITLE CARRIES AN `[FB] ` MARKER, AND THIS IS WHERE IT IS STAMPED — reversing, on
# the developer's instruction (issue #411, 2026-08-12), the rule that stood here for the
# life of the crossing. The old rule read: "The title is the target's, not ours: no
# `[Proposal]`/`[Request]` prefix of ours is added here or anywhere upstream... a prefix
# that means something in our vocabulary reads as noise — or worse, as a category — in
# theirs." That reasoning was never wrong about vocabulary; it was wrong about what was
# actually happening. Measured before the reversal: 17 of the 17 issues this repository
# received through the crossing already carried `[FB]`, against 1 of 9 filed directly by
# a human — every composing agent had been stamping it by hand anyway, so the written
# rule and the shipped behavior had disagreed 100% of the time. The reporter's
# "doesn't always" is therefore about the absence of a *guarantee*, not about observed
# misses, and mechanizing the marker changes no observable output: it only makes the
# convention true by construction. `[FB]` also earns its keep in the target's own terms
# — a target running this same loop ingests it, and for one that does not it reads as
# the provenance tag it is.
#
# The shape itself lives in `fb-title.sh`, not here, because the crossing's confirmation
# step must show the developer the *stamped* string: a title confirmed verbatim and then
# rewritten on the way out is not a title anyone confirmed.
#
# The body goes in on STDIN, never through argv — it is unbounded prose and a single argv
# entry is capped at 128 KiB on Linux. `--body-file` had that covered; a naive `-f
# body=@...` would not.
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"

wire_title="$(sh "${SCRIPT_DIR}/fb-title.sh" "$title" 2>/dev/null || true)"
[ -n "$wire_title" ] || emit_err "could not render the issue title for ${slug}: ${title}"

# NO ASSIGNEE REQUESTED -> NO `assignees` KEY. The crossing's request body stays exactly
# what it has always been; the widening is additive on the wire, not just in the docs.
payload="$(jq -n --arg t "$wire_title" --arg a "$assignee" --rawfile body "$body_file" \
    '{title: $t, body: $body} + (if $a == "" then {} else {assignees: [$a]} end)' 2>/dev/null || true)"
[ -n "$payload" ] || emit_err "could not build the issue payload for ${slug} (is jq present?)"

out="$(printf '%s' "$payload" \
    | sh "${GATHER_SCRIPTS}/gh-rest.sh" api "repos/${slug}/issues" --method POST --input - 2>&1)" \
    || emit_err "issue creation failed for ${slug}: ${out}"

url="$(printf '%s' "$out" | jq -r '.html_url // empty' 2>/dev/null || true)"
[ -n "$url" ] || emit_err "issue creation reported no issue URL for ${slug}: ${out}"

# What the API ACTUALLY assigned, not what we asked for. A login without access to the
# target is dropped by GitHub rather than refused, so a caller that read its own request
# back would report an assignment that never happened.
assignees="$(printf '%s' "$out" | jq -c '[(.assignees // [])[] | .login]' 2>/dev/null || true)"
[ -n "$assignees" ] || assignees='[]'
assigned=false
if [ -n "$assignee" ] && printf '%s' "$assignees" | jq -e --arg a "$assignee" 'index($a) != null' >/dev/null 2>&1; then
    assigned=true
fi

printf '{"ok": true, "url": "%s", "slug": "%s", "requested_assignee": "%s", "assignees": %s, "assigned": %s}\n' \
    "$url" "$slug" "$assignee" "$assignees" "$assigned"
