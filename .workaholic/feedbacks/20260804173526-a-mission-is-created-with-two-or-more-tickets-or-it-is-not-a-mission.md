---
type: Feedback
title: A mission is created with two or more tickets, or it is not a mission
kind: insight
source: discussion
created_at: 2026-08-04T17:35:26+09:00
author: a@qmu.jp
supersedes: 
---

# A mission is created with two or more tickets, or it is not a mission

A mission is created **with two or more tickets, or it is not a mission**. This is the
rule that keeps three artifact kinds distinguishable from one another.

## Why the floor exists

Without it, "mission" has no lower boundary, and two other artifacts lose their identity
to it:

- **A mission with no tickets is a feedback record.** It states a direction and nothing
  is queued against it. That is exactly what the feedback stream is for — long-lived
  direction accretes there (decision B3, 2026-07-28). Writing it as a mission instead
  puts an undrivable object on the roadmap, where it is reported as pending work
  forever.
- **A mission with one ticket is a ticket.** A mission is an *epic-equivalent grouping*
  — its whole value is that a set of tickets was designed together and shares an
  acceptance bar. One ticket has nothing to group, so the mission wrapper adds a board,
  a progress fraction, and a close decision to a unit that already had all the tracking
  it needed.

So the floor is not a quality bar on missions; it is the boundary that makes
"feedback / ticket / mission" a partition instead of three overlapping names for the
same thing.

## What the repository already shows

Measured on `main` at d4a31c16, across all 11 missions ever created:

| tickets | missions |
| ------- | -------- |
| 0       | 1 (`make-the-branch-story-measurably-shorter`) |
| 1       | 1 (`drop-the-draft-gate-and-make-drive-own-its-worktree-from-refreshed-main`) |
| 3-11    | 9 |

Nine of eleven already comply. The rule is not a new demand on how missions are
written — it names the shape they already have, and refuses the two degenerate cases.
Both exceptions were produced by seams that mint a mission without emitting its ticket
set, not by anyone deciding a one-ticket mission was a good idea.

## Where it has to hold

Every seam that brings a mission into existence, not just the interactive one:

- `/mission` Creation Interrogation
- `/propose`s proposal batch (`scaffold-draft.sh`)
- `close.sh --successor-title` on a **carried** close — this is how the live 0-ticket
  mission was created on 2026-08-04, minutes before this record. A carry mints a
  successor from the unmet acceptance items and emits no tickets at all, so it
  produces the exact artifact the rule forbids, by construction and every time.

## The consequence to accept

A carry can no longer mint a bare successor. Either the close emits the successor's
ticket set in the same pass, or `--successor-title` is refused and the remainder must
be carried into an existing mission (`--successor <slug>`) or replanned into one.
That is a real cost at the close seam, and it is the price of the boundary: a
successor with no tickets is a feedback record wearing a mission's frontmatter,
which is the thing this rule exists to prevent.
