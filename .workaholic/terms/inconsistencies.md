---
type: Term
title: Inconsistencies
description: Terminology conflicts that are live today — two live meanings for one word
category: developer
last_updated: 2026-08-13
---

# Inconsistencies

Known terminology conflicts. A term entry like any other, with no special status.

**What belongs here**: a word this project uses today in two different live senses, where
a reader could pick the wrong one and be misled. **What does not**: a name the project
retired. A conflict between two names that no longer exist is resolved by history, not by
a ledger entry — those are recorded in [retired-terms.md](retired-terms.md) with their
dates and successors. Every entry this file carried before 2026-08-13 was of that second
kind and has moved there.

## "policy" has three live senses

### Issue

The word carries three unrelated meanings, and two of them appear in the same ticket.

### Current usage

- **An engineering policy** — one of the canonical articles distributed by the six pillar
  skills (planning, design, implementation, operation, safety, development). A ticket's
  mandatory policy section names the ones its work answers to, and the driver opens each
  before writing code.
- **`merge_policy`** — a two-valued field on a mission or ticket (`auto` / `review`)
  deciding whether the unit may merge without a human. Nothing to do with engineering
  policy.
- **The nesting policy** — the table of which component may invoke which, in `CLAUDE.md`.

### Resolution

Say which one. "Engineering policy" for the pillar articles, "merge policy" written out
for the field, "nesting rules" for the table. Never the bare plural for the pillar
articles: the same word named a `.workaholic/` area retired on 2026-08-13, and the
freshness seam reads it as that retired area.

## "report" is both a command and an output

### Issue

`/report` is the command that writes a story and opens a pull request. The **run report**
is what an unattended executor prints at the end of every run. Neither produces the
other.

### Current usage

- `/report` → a story file plus a pull request.
- The run report → per-unit outcomes, minted tickets, deferred decisions, the
  reconciliation line and the terminal token, printed to the session.

### Resolution

Write "the run report" whenever the executor's terminal output is meant, and `/report`
with the slash whenever the command is. Do not shorten either to "the report".

## "scan" now means the safety scan only

### Issue

`scan` names the deterministic branch-safety gate. It previously named a documentation
command that no longer exists, and older archived stories use it that way.

### Current usage

- Current: the branch-safety scan — `secret`, `size` and `leak` rules over the branch
  diff, warn tier at report time and block tier at ship time.
- Historical: a documentation-regeneration command, retired 2026-05.

### Resolution

Unqualified "scan" means the safety scan. A historical document keeps its own meaning and
is not edited.

## subject, source and author look alike

### Issue

A feedback record carries all three, and they answer different questions.

### Current usage

- **subject** — whose opinion the record carries (`person`, `meeting`, `observer_ai`,
  `customer`, `team`, `other`, plus a free-text identity).
- **source** — the channel it arrived through (meeting, slack, discussion, development).
- **author** — the git identity that ran the capture.

### Resolution

Name the axis explicitly in prose. The failure mode is real and was the reason `subject`
was added: without it, a record written by a routine reads as the machine's own opinion.

## "release" names four different things

### Issue

Four live artifacts and one branch pattern share the root word.

### Current usage

- **`release/*` branch** — the QA window cut from the base, where a batch's production
  evidence is proved.
- **release note** — one per shipped unit branch, in `.workaholic/release-notes/`.
- **release record** — one per production release, in `.workaholic/releases/`.
- **GitHub Release** — what continuous integration publishes after a version bump lands.

### Resolution

Never write bare "release" where two could be meant. The note is per unit, the record is
per release, and the branch is per batch.

## "archive" is both a verb and a place

### Issue

Standard English, and standard in this project's instructions: "archive the ticket" and
"check the archive".

### Current usage

- Verb: the seam that moves a completed ticket and commits it.
- Noun: `.workaholic/tickets/archive/<branch>/`.

### Resolution

Acceptable as-is. Where a sentence could be read either way, write "the archive
directory" for the noun.

## "feedback" is a record kind, not a review comment

### Issue

`/fb` registers an immutable record in the inbound stream. Claude Code separately ships a
built-in `/feedback` for reporting problems with the tool — which is why this project's
command is abbreviated.

### Current usage

- `/fb` → a record in `.workaholic/feedbacks/`, with a kind, a source and a subject.
- `/feedback` → the host agent's own built-in, unrelated to this repository.

### Resolution

Write `/fb` with the slash when the command is meant, and "feedback record" when the
artifact is. Do not write `/feedback` for this project's command.
