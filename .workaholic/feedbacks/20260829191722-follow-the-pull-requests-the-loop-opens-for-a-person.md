---
type: Feedback
title: Follow the pull requests the loop opens for a person
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-29T19:17:22+00:00
author: a@qmu.jp
supersedes: 
---

# Follow the pull requests the loop opens for a person

The [Propose] routine, judging the strategy `an-autonomous-improvement-loop-run-by-the-routines`, asks for a **contraction**: the loop opens pull requests **for a person** — the publications `publish-tree-pr.sh` itself refuses to auto-merge, reporting `merge_reason: ruling_touching` or `strategy_touching` — and then stops following them. Make it follow them.

Source: https://github.com/qmu/workaholic/issues/729

## What must become true

- **The loop reads back whether a pull request it opened for a person was acted on.** One reader, per pull request, in the shape the loop already uses for its own acts — `merged` / `closed` / `open:<age>` / `unreadable` — composed from the REST seam (`gather/scripts/gh-rest.sh`) that `list-open-proposals.sh` and `list-open-rulings.sh` already read. No field on any artifact, no store, no cursor, no second oracle. Every value is a **judgement**: a pull request can be merged or reopened between two reads, so nothing here may merge, close, gate, hold work or lift a gate.
- **Which open pull requests are the operator's is derived, never guessed** — from the publish seam's own refusal word, never from a title, a label or an `[Ruling]` prefix.
- **An un-acted operator-facing pull request reaches the person who must act.** One `/moderate` question per pull request, keyed so it is asked exactly once, addressed to the person the publication waits on, naming the pull request, its age and what merging it would unblock. It asks and nothing else.
- **The loop is never silent about a ruling and about what that ruling holds at the same time.** `ruling-suppression.sh` holds a subject's hourly question the moment a ruling names it — correct while the ruling is moving, wrong once the ruling itself has gone unanswered.
- **The reading is evidence and gates nothing.** `/implement`'s and `/propose`'s run reports name it in the voice `pace`, `overdue` and `expiring` already use.
- **It is classified once and pinned**, in the one home that already classifies whether an act the loop took had its effect, with the enumerated consumers named.
- **It is drilled offline** over a bare origin with the transport stubbed, registered so `Loop Drills` runs it on every push, with a breaker row written against the **behaviour**.

## What was measured (2026-08-29 18:41 UTC)

- **7 open pull requests**, the oldest last touched 2026-08-26.
- **#694 `[Ruling] Standing rulings for the operator`**, opened 00:59 UTC, **18 hours** unanswered. The *at most one open ruling at a time* brake means no further ruling can be drafted while it sits, and `ruling-suppression.sh` is holding the `undrivable-unit:` questions for the very addresses it names.
- **`plan-units.sh` offers nothing**: `backlog_all_excluded: true` over a backlog of 10, `missions: []`, `backlog: []` — **7** of those tickets excluded `owned_by_other` on `tamura.yoshiya@gmail.com`, the one address #694 would map.
- **#688 and #625** are `[Proposal]` publications whose missions have since landed on other branches; nothing reads those either.

Every claim-side verdict the loop has — `stalled`, `report_undelivered`, `awaiting_verification`, `content_conflict` — is bounded to a **claim**, and these publications carry none, which is why no existing step sees them. `stuck-prs` and `merge-conflicts` report into a root and ask nobody.

## Why it commits to the strategy

The Aim's second half is that *the developer's work moves up a layer*. After this direction's 259 landed items, what is left of the developer's work is almost entirely **ruling** — and the loop's one channel for delivering a ruling is a pull request only that person can merge, the single artifact in this machine that nothing reads back. Today the loop drafted its ruling, went quiet, held the questions the ruling was meant to answer, and drove nothing for hours while the direction layer read `quiescent: true`.

It is a **contraction**: today's own mission established that every reading answered *what did I find* and none answered *did what I did happen*, and repaired it for the two acts the loop takes on a proof. The act the loop takes **on the operator's behalf** was left out, so the same question is now answered in one place and unanswered in another.

## What it is chosen against

**Reading back whether the proposal itself turned** — folding `/propose`'s own issue into the same `taken` / `pending` / `refused` shape. **20 of the 20 closed proposals on this direction became missions**, so it answers a failure that has not once occurred, while the operator-facing pull request is failing at this moment with 10 queued units undrivable behind it.

Also chosen against **a single "what the loop is blocked on" report**, which this repository has already refused by name: a report addressed to nobody is what `🔧 Needs a decision` and `📦 Release Preparation` were retired for.

## The mission the ask names

**Experience** — the person who must rule is told, once, that a pull request is waiting on them, what it would unblock, and how long it has waited; and the loop can no longer be silent about a ruling and about the work that ruling holds at the same time. Nothing merges, closes or gates on the reading; a run that cannot read a pull request says so by name and asks nobody.

**Tickets**, in order:

1. Read back whether a pull request the loop opened for a person was acted on — one reader, `merged` / `closed` / `open:<age>` / `unreadable`, composed from the existing REST seam, `readable: false` carrying a named reason and null ages, always exit 0.
2. Derive which open pull requests are the operator's from the publish seam's own refusal word (`ruling_touching`, `strategy_touching`), never from a title or a label.
3. Ask the person who must act, once per pull request, from a `/moderate` step that asks and nothing else — the existing key, cap, quiet-hours and working-day holds unchanged.
4. Stop the ruling hold and the ruling's own silence from coexisting: a subject held by a stale ruling becomes reachable again, with one shared derivation behind both readings.
5. Report the reading in `/implement`'s and `/propose`'s run reports as evidence, moving no token and lifting no gate; pin that every refusal, sort and `selected` is byte-identical across the change.
6. Classify every value as a judgement in the one existing home, name its enumerated consumers, and fail the suite when a consumer and the table disagree.
7. Drill it offline over a bare origin with the transport stubbed, register it so `Loop Drills` runs it on every push, and carry a breaker row written against the behaviour.
