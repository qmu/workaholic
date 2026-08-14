---
type: Term
title: Workflow Terms
description: The verbs — survey, claim, drive, archive, report, ship, propose
category: developer
last_updated: 2026-08-13
---

# Workflow Terms

The verbs. Each names a step some command actually performs today; the order they appear
in is roughly the order a unit of work meets them.

## propose

Propose is the operation that judges an **ask in hand** — an argument, a record just
written, or, on a clock-fired tick with nothing handed in, the open issues assigned to
the running identity — and emits, in one pull request, a feedback record plus whatever
the work's shape selects: a mission with its ticket set, one loose ticket, or the record
alone. It never prompts, and its pull request auto-merges on opening unless the scan
finds something. It is the loop's inbound half; `/implement` is the outbound half.
Related terms: feedback record, mission, ticket, publish tree.

## survey

The survey is the executor's read of what is claimable: unclaimed active missions and
queued tickets this runner owns or that are unowned, minus everything a claim already
holds. It **states its freshness and does not repair it** — an unreadable queue never
renders as an empty one, and four conditions (not current, shallow history, a backlog
error, unresolved ownership) forbid the run from ending `ok`. Every drop is named with
its reason; nothing leaves the offer silently. Related terms: claim, unit, freshen.

## freshen

Freshening is bringing the checkout level with its base **before reading it** — the step
that stops a run from surveying a stale queue. It is the caller's job, never the
survey's. A checkout parked on its own branch at the base's exact tip with a clean tree
is not stale, and the run says so and continues. Related terms: survey, catch up.

## partition

Partitioning turns the survey's offer into **PR-units** — what deserves one merge. Each
claimable mission is exactly one unit; related backlog tickets group only on a reason
statable in one sentence. The composition is derived and reported, never asked; only the
choice *among* units is ever put to a present operator. Related terms: unit, claim,
merge policy.

## claim

To claim is to take a unit **visibly**: push a `Claim <unit-id>` commit on a `work-*`
branch, creating the branch, the worktree and the right to drive. Claim one unit at a
time — claim, drive, report, route, then survey again — because an untaken claim is
invisible to every other runner until its heartbeat lapses. Related terms: resume,
release a claim, heartbeat, worktree.

## resume

To resume is to **take over an existing claim**, never to make a fresh one: it continues
from the pushed branch tip, adopting this machine's worktree when there is one and
otherwise creating one at the tip so archived tickets are not re-driven. Two tiers are
resumable — a run whose heartbeat lapsed (take it over before claiming fresh) and a unit
parked at its pull request (reportable, not mandatory). **Your own claim only**: a
colleague's is untouchable at any age. Related terms: claim, heartbeat, handoff.

## release a claim

To release a claim is to **deliberately discard an unfinished unit** — it is not a
recovery path and not how a finished unit ends. A merge releases a claim by definition;
this is for the case where the work is being abandoned on purpose. Related terms: claim,
worktree.

## drive

To drive is to implement a claimed unit inside its worktree: order the queue (dependency
sort, then context grouping — reported, never asked), then take each ticket through read
→ implement against the policy lens → run its `## Quality Gate` verification → append
the Final Report → archive. Reached through `/drive` (attended) or `/implement`
(unattended); the two share every step below the one selection question. Related terms:
claim, archive, executor, quality gate.

## archive

To archive is to move a completed ticket from `todo/` into
`tickets/archive/<branch>/` and commit it — **one script owns this seam**, never a manual
`mv` plus `git add`. The commit subject is validated before the ticket moves, so a
refused subject leaves the tree byte-identical rather than half-archived, and the archive
commit pushes its branch immediately because progress must always reach the remote.
Related terms: ticket, final report, commit, claim.

## commit

To commit is to write a structured message and record the change: a subject that is
present-tense, 50 characters or fewer, with no `feat:`-style prefix and no leading
`[bracket]` tag, followed by the sections that give downstream readers context. One
validator enforces the subject and every layer calls it — the commit script, the archive
seam, the tool-level guard, and the opt-in git hook — so the layers cannot drift.
Related terms: archive, subject, gate.

## report

Report is the operation that writes the branch **story** and opens or updates the unit's
pull request, right-sized to the branch: two or fewer archived tickets get one combined
worker and no Journey, more get a three-worker fan-out, and both produce the same result
record. It runs the branch-safety scan at warn tier — findings fold into the pull request
body rather than stopping anything. Note the collision: this is `/report` the command,
distinct from the **run report** an unattended executor prints at the end of its run.
Related terms: story, scan, pull request, run report.

## run report

The run report is what `/implement` prints when it finishes — per unit: members, policy,
route, ticket outcomes reconciling to its queue, commits, pull request URL, and whether
the finish notification actually landed; then minted tickets, deferred decisions and
exclusions; then the reconciliation line and the terminal token. It is **the
deliverable**, emitted whether the run succeeded or not, because it is where the
developer's looking-through relocated to. Related terms: report, terminal token,
reconciliation.

## route

To route is to send a finished unit down the path its **effective merge policy** selects
— derived by a script, never by prose, because the answer decides whether machinery
merges to the base. `auto` goes through the ship flow; `review` merges its pull request
as soon as the report opens it and the scan passes. Related terms: merge policy, ship,
gate.

## ship

Ship is the operation that **drafts the deployment plan and merges** — since 2026-08-13
it deploys nothing. It refreshes the release note's `## Deployment Plan` from the
deployment records, blocks pre-merge on the scan, halts when a target declares no
confirmation method, merges, and tears the claim's worktree down. Deploying is a separate
step taken **only on the developer's instruction**: it runs the procedure, confirms, and
records the attempt. "Shipped" therefore means merged with a current plan drafted, never
deployed. Related terms: route, deployment record, release note, confirm.

## catch up

To catch up is to merge the base branch into a work branch so what gets proved equals
what will land. Conflicts are classified rather than guessed at: an append-only conflict
in the knowledge tree is resolved by keeping both sides, a version or generated-output
conflict is mechanical and reconciled in place, and anything else is a content conflict a
human must judge. Related terms: freshen, ship, merge conflict.

## scan

**The branch-safety scan** — a deterministic, script-only gate over the branch diff, run
at warn tier by `/report` and at block tier by `/ship`. Three rule families: `secret`
(hard, never overridable), `size` (overridable by a human), and `leak` (re-introduction
of denylisted terms). Read its scope literally: a `pass` means these rules found nothing,
not that the branch is safe in some broader sense. The word once named a documentation
command; that meaning is retired. Related terms: gate, ship, report.

## cut a release branch

To cut a release branch is to create `release/YYYYMMDD-HHMMSS` from the base — batch
level, explicitly invoked, never a step of a per-unit ship. It carries no commits of its
own and is invisible to the claim protocol. Since 2026-08-13 **the confirmation at this
window is the production evidence**, not a second one, because the per-unit ship no
longer deploys. A failed confirmation deletes nothing; the next attempt cuts a fresh
branch. Related terms: release record, ship, confirm.

## confirm

To confirm is to run a deployment target's `## Confirmation` — the exact executable proof
that a change reached production — and record the attempt as `pass`, `fail`, `not_run` or
`bypassed`. A target with no confirmation method is a halt, not a warning: a plan whose
verification reads "none declared" is the aspirational plan the gate exists to prevent.
Related terms: deployment record, ship, cut a release branch.

## reconciliation

The reconciliation is the second-to-last line of an unattended run — `N units: X shipped,
Y PR'd, Z blocked` — so the outcome is graspable from outside without reading the report.
Ticket outcomes reconcile to the queue the unit was handed: a closed set of four
(implemented, failed, blocked, deferred). Related terms: run report, terminal token.

## terminal token

The terminal token is the last line of an unattended run — `ok` or `pending` — and it is
**derived, never self-asserted**. `ok` requires that every claimed unit reached its routed
end *and* a fresh survey offers nothing claimable over a readable, current queue.
"I stopped" is not "it's done": a blocked or handed-off unit is `pending`. It is the
contract a caller-side loop waits on. Related terms: reconciliation, run report, handoff.

## Retired verbs

`trip`, `scan` (the documentation command), `sync`, `abandon` (as a drive-time approval
option), `approval` and `prioritization` are recorded with their dates and successors in
[retired-terms.md](retired-terms.md).
