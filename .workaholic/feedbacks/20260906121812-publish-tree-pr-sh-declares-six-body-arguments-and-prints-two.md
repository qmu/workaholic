---
type: Feedback
title: publish-tree-pr.sh declares six body arguments and prints two
kind: instruction
source: development
subject: observer_ai:a@qmu.jp
created_at: 2026-09-06T12:18:12+09:00
author: a@qmu.jp
supersedes: 
---

# publish-tree-pr.sh declares six body arguments and prints two

Source: https://github.com/qmu/workaholic/issues/1015

# `publish-tree-pr.sh` declares six body arguments and prints two; the other four are discarded in silence

The script's own usage line is:

    publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify> [files...]

Its argument handling assigns `TITLE="$1"` and `WHY="$2"` and nothing else. `$3` through `$6` — the
changes, concerns, insights and verify sections — are never bound to a variable and never appear in
the body it builds. The composed body is `## Overview` (from `<why>`), an `## Artifacts` block
derived from the diff, and a fixed `## Notes` paragraph. Every caller that passes the six arguments
the usage line asks for loses four of them, and nothing in the result says so: the envelope reports
`ok: true` with a `pr_url`, and the caller has no way to tell a complete publication from a
two-thirds-empty one.

Measured on a consuming project today, twice. A propose run published a mission proposal through
this script, read its own pull request back, found only the overview, and repaired the body by a
separate PATCH so its carry, direction, precedence and mint judgements were on the record at all.
Reading the script at the source confirms it is the argument handling rather than anything about
that run.

**This is not the `body_source: "fallback"` reading, and the two should not be conflated.** That
field describes the MERGE COMMIT body, and the script's own comment is right that `fallback` is the
ordinary answer there, because a publication has no branch story. The defect above is in the PULL
REQUEST body, on the create call, and it happens on the happy path with no degradation reported
anywhere.

What the loss costs is worth stating, because it is not cosmetic. A publication's pull request is
where the run's judgement is supposed to be legible to a person — what it decided, what it was
worried about, what it verified. Discarding those three leaves a record that says what was published
and never why it was judged that way, which is the thing a later reader most needs and the thing the
six-argument interface exists to carry.

Two ways to close it, and the reporter would take the first: print the four sections in the body the
way `<why>` is printed. If any of them was deliberately dropped for a publication — the way the merge
body's `fallback` was — then the usage line should stop asking for it, so a caller is not invited to
write something the script will not carry.

## Re-measured while registering this record, 2026-09-06

Confirmed at the source: `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` line 6 and
line 88 both declare the six-argument usage; lines 92-93 bind `TITLE="$1"` and `WHY="$2"` and no
other positional argument is ever bound. And confirmed by behaviour on this very run: the
record-only publication for issue #1014 (pull request #1016) passed all six and its created body
carried `## Overview`, `## Artifacts` and `## Notes` only — the precedence, the `self_authored`
judgement, the carried ref and the direction were all dropped, and were restored by a follow-up
PATCH. Three independent reproductions now, two of them on this repository.

## Why nothing was emitted for it

The ask is machine-originated (`subject: observer_ai:a@qmu.jp`, `ask-origin.sh` -> `machine`) and its
subject is the loop's own apparatus — the publish-tree seam. Under `rules/workaholic.md`, *What May
Originate a Mission*, such a record may not originate a mission, however well-evidenced the defect
is. It is registered as knowledge and stays open for a person to pick up.
