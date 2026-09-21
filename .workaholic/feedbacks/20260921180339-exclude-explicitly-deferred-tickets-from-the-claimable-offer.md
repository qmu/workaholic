---
type: Feedback
title: Exclude explicitly deferred tickets from the claimable offer
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-21T18:03:39+09:00
author: a@qmu.jp
supersedes: 
review_surface: 
---

# Exclude explicitly deferred tickets from the claimable offer

kind: instruction / source: development / subject: person:tamurayoshiya

Source: https://github.com/qmu/workaholic/issues/1261

# Exclude explicitly deferred tickets from the claimable offer

An operator can explicitly defer a queued ticket until they revisit it, but there is no
machine-readable deferral state the claimable offer honours. The ticket stays in `backlog[]`,
so each implementation tick can claim it again only to rediscover the same instruction in
prose. The ask names four things to become true: a validated ticket-frontmatter declaration
for operator deferral; declared tickets returned in `excluded[]` with a specific reason;
removal of that declaration as the only way automation can offer the ticket again; and a queue
holding only operator-deferred work read as neither an implementation failure nor a reason to
consume an implementation runner.

## What this run measured, against the constraint the ask states

The premise *`plan-units.sh` has no machine-readable deferral state* is partly false and the
part that is false matters. `status: icebox` already exists, `validate-ticket.sh` already names
it, and `drive/scripts/promote-icebox.sh` already clears it — so a declaration and a
declaration-removal path both exist today.

What does not exist is visibility, and it is missing one layer below the survey.
`drive/scripts/list-todo.sh` filters `done | abandoned | icebox` out of the queue walk itself,
so such a ticket never reaches `plan-units.sh` at all: it is never counted in `backlog_size`,
never appears in `excluded[]`, and `backlog_all_excluded` reads `excluded: false` because
nothing was excluded. A queue emptied by deferral is therefore byte-identical to an empty
queue — the exact collapse `backlog_all_excluded` and `placeholder_identity` were each built
to end.

`icebox` is also, in this repository`s own vocabulary, an **archive** state: `done`,
`abandoned` and `icebox` mean *archived with that outcome*. The ask asks for a ticket that
stays **queued** and is **named** as held. Overloading one field to answer both questions is
the shape this repository has twice recorded as how two readings drift (`overdue` beside
`pace`, `self_refining` beside `describing_move`), so the declaration the ask asks for is
emitted as its own field and `icebox` is left untouched.
