#!/bin/sh -eu
# Open the confirmed, masked, scanned body as a GitHub issue on ANOTHER repository.
#
# Usage: open-issue.sh <owner/name> <title> <body-file>
# Emits JSON: { ok, url, slug } or { ok: false, error }.
#
# THIS IS THE ONLY SANCTIONED CROSSING, and it writes into no checkout at all. The
# earlier route copied a ticket file into the target's working tree, which meant the
# boundary crossing arrived as a file appearing in somebody else's `git status` — an
# artifact its owners had no native way to see, triage, or decline. An issue is the
# form the target already reads: its own [Propose] routine ingests it like any other
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
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

wire_title="$(sh "${SCRIPT_DIR}/fb-title.sh" "$title" 2>/dev/null || true)"
[ -n "$wire_title" ] || emit_err "could not render the issue title for ${slug}: ${title}"

payload="$(jq -n --arg t "$wire_title" --rawfile body "$body_file" '{title: $t, body: $body}' 2>/dev/null || true)"
[ -n "$payload" ] || emit_err "could not build the issue payload for ${slug} (is jq present?)"

out="$(printf '%s' "$payload" \
    | sh "${GATHER_SCRIPTS}/gh-rest.sh" api "repos/${slug}/issues" --method POST --input - 2>&1)" \
    || emit_err "issue creation failed for ${slug}: ${out}"

url="$(printf '%s' "$out" | jq -r '.html_url // empty' 2>/dev/null || true)"
[ -n "$url" ] || emit_err "issue creation reported no issue URL for ${slug}: ${out}"

printf '{"ok": true, "url": "%s", "slug": "%s"}\n' "$url" "$slug"
