---
type: Feedback
title: Attribute an inbound ask to the direction it answers
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-26T04:16:50+00:00
author: a@qmu.jp
supersedes: 
---

# Attribute an inbound ask to the direction it answers

Source: https://github.com/qmu/workaholic/issues/609

Opened by the `[Propose]` routine against the strategy
`an-autonomous-improvement-loop-run-by-the-routines` (move: `contraction`), carrying
`feedback: 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md`.

## What the ask says

Make an ask that arrives on the loop's **other** inbound surface carry the direction it
answers, so the work it produces is visible on that direction instead of reading as work
nobody did.

The loop now has two inbound surfaces and only one of them is attributable. `/propose`
writes a `feedback:` header line naming the strategy's own refs, `/specificate` carries it
onto what it emits, and `check-carry-floor.sh` refuses a publish that drops a resolved ref.
The **inbound Slack sweep** — run by that same routine since 2026-08-23 — and `/fb`'s
in-repo path write no such line at all, so a person's ask about a live direction produces
work that intersects that direction's `feedback[]` at nothing.

Measured on the tick that filed this: the developer's 11:08 JST message in
`#dev-workaholic` asked that missions hang off strategies and that `/propose` plan whole
missions — an ask about this strategy's own aim, in this strategy's own words. The sweep
filed it (issue #604), `/specificate` emitted
`.workaholic/missions/active/turn-the-loop-at-mission-granularity/` with five tickets, and
`attributed-work.sh` reports this strategy's `waiting_count: 0`. Five tickets about the
direction, none of them attributable to it — and because `waiting_count` is what
`work_waiting` reads, the in-flight brake stood open while a whole mission for the
direction sat queued. The tick's own moderation post says the same from the other side:
*13 tickets queued now ... are attributable to no strategy.*

## What must become true

- The **sweep's writer** (`propose/scripts/file-inbound-ask.sh`) and **`/fb`'s** issue path
  (`feedback/scripts/open-issue.sh`) can emit the same visible `feedback:` header line
  `open-proposal.sh` already writes, so an inbound ask reaches `/specificate` carrying the
  direction it answers.
- **Which direction is a derivation, then a judgment, and never a guess.** An ask naming a
  strategy **slug** is attributed to it — explicit slug only, the rule `/specificate`'s
  lifecycle recognition already holds, never a title or a paraphrase. An ask naming none is
  judged by `/specificate` against the `active` strategies it **already reads** for the
  operator-record check: those Aims are already binding on that run, so asking it which Aim
  an ask falls under adds no reader, no relation and no field to any artifact. The retired
  `strategy:` relation stays retired.
- **Unattributed stays a real answer, and a visible one.** An ask that answers no live
  direction is attributed to none — that is ordinary and must not be forced. What changes is
  that it is **reported by name** on both surfaces the carry already reports on: the sweep's
  run report per filed issue, and `/specificate`'s run report and pull-request body per
  emitted artifact, beside the carried/dropped counts they now render.
- **The guarantee the last mission bought is extended to cover the loop's own second mouth.**
  `no_citing_artifacts` was just made to mean *nothing has answered this direction yet* —
  bounded to work the loop emitted from an ask whose refs resolved. The sweep is the loop's
  own writer, so an ask it filed belongs inside that bound; today it sits outside it and
  reproduces exactly the reading the mission was built to eliminate. Extend the hermetic test
  that pins ask → reader → scaffold → floor so it walks the sweep's ask too, and state the
  remaining limits rather than widening the claim: a ref that does not resolve, and an
  artifact written by hand outside `/specificate`, stay uncited for ordinary reasons.

## Why it commits to the strategy

The Aim's reached condition is that a turn of the loop is *"visible back on the strategy it
came from through the attribution reader that already exists — with no field added to any
artifact and no second inbox created."* The last mission proved that for the turn
`/propose` originates. This is the same sentence applied to the turn a **person**
originates, which the Aim never exempted and which is now the majority path: the sweep
exists precisely so an ask arrives without anybody tagging a bot.

It also repairs a brake the Aim calls load-bearing. The Aim says the brake is *"mechanical
and derived, never a judgment the run can talk itself past"* and that a strategy is proposed
against only while *"carrying no work already waiting."* Measured above, `work_waiting` read
open with five tickets waiting — not because a run talked past it, but because the count it
reads cannot see work born on the channel.

And it is bounded by the Aim's own constraint: **no field is added to any artifact and no
second inbox is created.** The relation used is the many-valued `feedback:` one.

## What it is chosen against

- **`depth` into the carry-forward proof itself** — extending the floor, tightening the
  reporting, drilling the round trip. Rejected: the floor landed the same day and holds for
  the path it covers; going deeper hardens a provable path while the adjacent one stays
  invisible.
- **The mission-grain work already queued.** `turn-the-loop-at-mission-granularity`
  re-expresses the brake at mission grain and makes a mission's strategy visible where
  missions are read — and both of its tickets assume the refs *arrive*. This is the
  assumption underneath them; without it a mission-grain brake counts the same zero more
  carefully.
- **Leaving it alone as correct lossiness.** `attributed-work.sh` declares itself transitive
  and lossy, a person's free-text ask may genuinely belong to no direction, and making
  someone name a slug in Slack pushes human-shaped work back into the loop. That argument is
  why the change is *judge, then report*, never *require*: nothing is refused for naming no
  direction, and the only new obligation is that the loop say out loud which direction it
  decided an ask answered, or that it decided none.
