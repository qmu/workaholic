---
name: strategy
description: Use when a session needs to record, list, read, or close a strategy — the operator's outbound, resolved direction, bounded by a schedule and carried by a named assignee. Defines the artifact's model and owns its scripts.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Strategy

A **Strategy** is one piece of **outbound, resolved direction**: what the operator has committed
to pursue (**Aim**), by when (**Schedule**), and who carries it (**Assignee**). It lives flat at
`.workaholic/strategies/<slug>.md`, one file per strategy, and is **operator-authored** — no
command, hook, or routine puts one on `main` on its own.

**The one drafting exemption** (2026-08-14): `/specificate` may draft a strategy into its proposal
pull request, and **that pull request never auto-merges**, so the file still reaches `main` only
when a human merges it — the operator's merge is the authorship. Everything else holds unchanged:
`close.sh` is still the only writer of an end state, `/drive`
still never surveys a strategy, and the bar `/specificate` must clear is all three parts present in
the ask (a date, a named owner, an aim with no decomposable plan) or it emits nothing
(`workaholic:specificate`, *The strategy form, and the one rule it widens*). The same exemption
covers `close.sh` when an ask **announces** that a named strategy ended — matched by explicit
slug only, never by title similarity.

**There are three writers, and the third arrived on 2026-08-27** (mission
`let-the-operator-revise-a-live-direction-through-the-loop`): `create.sh` creates, **`amend.sh`
revises a live direction's `## Aim`, Schedule and Assignee**, `close.sh` ends. Nothing else writes
the file. Until then an announced *change* was captured as feedback and applied by the operator by
hand on `main` — the one act in this repository that required a person to edit the base directly.

**What did not move, and why the authorship premise survives.** The two-writer rule was written to
stop a machine **authoring** the operator's direction, and it holds: `amend.sh` carries a revision
the operator **announced by explicit slug** (`/specificate` step 9d), onto a pull request that
**never auto-merges** — and since the same change that is the publish seam's own refusal
(`publish-tree-pr.sh` → `merge_reason: strategy_touching`) rather than a caller's judgement, so
the operator's merge is still the authorship. No routine amends on its own reading of a direction:
`/moderate`'s `direction-health` step asks a person and writes nothing. `close.sh` is still the
only writer of an end state and re-opening is offered nowhere. `/drive` still never surveys a
strategy. Matching is still by explicit slug only. The citation still runs strategy → feedback one
way, and the retired `strategy:` relation stays retired.

**The third writer is bounded, and the bounds are the reason it is admissible.** Only the three
parts this model calls revisable are reachable from its interface; `slug`, `type`, `status`,
`created_at`, `author` and `feedback:` are asserted immutable over its own candidate before it
writes. A closed direction is refused `not_active`. Every floor breach is refused with **nothing
written** — no partial write, no staged half, no write-then-revert. And each revision appends one
dated line to `## Schedule` saying what moved, so the artifact carries its own history.

## The model

| Part | Where it lives | What it means |
| ---- | -------------- | ------------- |
| **Aim** | `## Aim` body section | The direction's substance, in the operator's words. What is being pursued and what "pursued" means here. |
| **Schedule** | `target_date:` frontmatter + `## Schedule` body section | The dated bound. `target_date` is a single `YYYY-MM-DD` — the date by which the aim is meant to hold. `## Schedule` carries the shape around it (a start, milestones, a cadence) in prose. |
| **Assignee** | `assignees:` frontmatter | Who carries it. Plural like every other artifact, resolved through the one ownership oracle (`gather/scripts/owners.sh`), but — unlike everywhere else — **it may not be empty**: an unowned direction is not a strategy. |

`status:` is a single axis, `active | achieved | abandoned`. `close.sh` is the only writer of an
end state; nothing else edits the field. There is no separate `archive/` area — a closed strategy
stays where it is and its `status` says what happened, because a strategy is small enough that its
whole history is the file.

## What a strategy is not

- **Not the feedback stream.** `feedbacks/` records what someone *said*: inbound, immutable,
  undated, unowned. A strategy records what the operator *decided*: outbound, revisable until
  closed, dated, owned. The link is **one-way** — a strategy may cite the records that formed it
  through the many-valued `feedback:` relation, and no feedback record ever points at a strategy.
  Two homes for direction only drift when both are inboxes; only one of these is.
- **Not a mission.** A strategy carries **no ticket plan and no acceptance list**. Planning
  executable work is a mission's job (`workaholic:mission`, and the two-or-more-tickets floor).
  A strategy that wants execution gets missions created under it by the operator; it never grows
  a queue of its own, and `/drive` never surveys it.
- **Not a status board.** Progress is not computed and not stored. The schedule is the only
  temporal claim a strategy makes.

## Its relation to missions

A strategy and a mission are **not linked in either direction**. The 2026-07-28 retirement removed
`strategy:` from the mission scaffold and folded strategy `assignees` down onto missions precisely
because the extra relation gave ownership a second resolution path (the "ownership hop"
`mission-owners.sh` used to make), and that hop is not being rebuilt. A mission's owner is on the
mission; a strategy's owner is on the strategy. An operator who wants to see them together reads
both.

## Which work belongs to a strategy — through the feedback stream, adding no field

A reader that needs "what moved on this strategy" — `/standup`'s per-strategy digest is the first —
asks **one script** and nothing else parses the question:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/attributed-work.sh <slug> [window] [.workaholic-root]
```

**The rule, written down before any summary is computed** (the Open Decision on ticket
`20260817115231-resolve-strategy-to-activity-attribution`, resolved 2026-08-17): attribution runs
along the citation that already exists, and **no new field is added anywhere**.

| Hop | Rule | `attribution` |
| --- | ---- | ------------- |
| 1 | The artifact's `feedback:` refs intersect the strategy's | `direct` |
| 2 | A **mission** attributed by hop 1 is named by the artifact's `mission:` relation | `via_mission:<slug>` |

Hop 2 is load-bearing, not a nicety: `/specificate` puts the `feedback:` refs on the **mission** and its
ticket set carries `mission:` instead, so a one-hop reader would see almost nothing. Both hops read
their relation through that relation's existing single reader
(`specificate/scripts/read-feedback-relation.sh`, `mission/scripts/read-relation.sh`), so this script
parses neither field itself.

**The direction is unchanged and stays one-way.** A strategy cites feedback; nothing cites a
strategy. That is what makes this option the one that answers the 2026-07-28 removal instead of
reopening it — it adds no relation, so it cannot rebuild the ownership hop, and it needs no write
floor, no hook and no migration. The three rejected alternatives and why are in the script's own
header, beside the rule they lost to.

**It is lossy, and it says so.** Work that answers a strategy without citing the same record is
invisible to hop 1 and hop 2 alike. Every artifact therefore carries the `attribution` that caught
it, and a consumer states what it could not attribute rather than implying the digest is exhaustive.
A quiet strategy is a real answer, not an error: `empty_reason` is `no_feedback_refs` (it cites
nothing), `no_citing_artifacts` (nothing cites it back) or `no_activity_in_window` (attributable work
exists, none of it moved) — never an empty result with no reason, and never a guess. All three name
why a **completed** walk found nothing; a walk that did not complete answers below instead, and is
never folded into this vocabulary.

**It reports the mission grain beside the ticket grain** (2026-08-26). `waiting_missions`,
`waiting_missions_advancing`, `waiting_missions_describing` and `waiting_mission_slugs` sit
beside `waiting_count` / `waiting_advancing` / `waiting_describing`: an *active* attributed
mission is one still in flight, whether or not any of its tickets are still queued. `/propose`'s
brake reads it, because a proposal is now a whole mission and a mission whose last ticket sits
at a pull request with the queue drained is not finished. A mission is classified by its own
queued tickets, and one with none is `unknown` — which counts toward advancing, the same rule an
unknown ticket follows. This adds no relation and no artifact field: the mission set is the
attributed artifacts already walked, filtered on the lifecycle field `close.sh` writes.

**And it says when it could not look at all** (2026-08-29, mission
`keep-the-closing-link-readable-as-the-corpus-grows`). Both hops prefilter the corpus with one
`grep` per `xargs` batch. A batch matching nothing is honest and leaves the walk complete; a batch
the reader **could not read** is a failure, and until now both vanished into one swallowed status —
so a corpus nobody could read was emitted as `no_citing_artifacts`, the reading that means the exact
opposite. A walk that did not complete now reports:

| Field | On a degraded walk |
| ----- | ------------------ |
| `readable` | `false` |
| `reason` | `patterns_unreadable` (the pattern set) or `corpus_unreadable` (one or more corpus entries) |
| `count`, `active_count`, every `waiting_*` | **`null`**, never `0` — `unattributed-work.sh`'s existing shape, because a zero on a read that failed is the whole defect |
| `artifacts` | `[]` — the batches that *did* read are kept inside the walk so it can finish, and are deliberately not emitted: a half list rendered as a list is the same collapse one step on |
| `empty`, `empty_reason` | **`null`** — a reading we did not make, never one of the three we did not reach |

**`readable` is absent on every completed walk, and that is the contract rather than an omission**:
*absent means the walk completed*, the convention `merge_policy` (absent means review) and a ticket's
`status:` (absent means queued) already use here. A completed reading is therefore byte-identical to
what it was before the field existed, and a consumer not yet taught the term behaves exactly as it
did. **Test it as `readable == false`**, never as `readable // true`: in jq `//` treats `false`
itself as empty, so `false // true` is `true` and that spelling reads every degraded walk as a
healthy one. It is derived in exactly one place inside the script, for both hops; the reader still
exits 0, degraded included.

**Two sibling terms sit beside each other and must not be folded together.** `quiescent` reads
`false` when the **residue** read was degraded (2026-08-28, `workaholic:propose`); a survey row is
refused `attribution_unreadable` when the **attribution** read was degraded (2026-08-29, the
paragraph above). Different reads, different consequences: the first withholds one reading, the
second refuses the whole row and every reading composed on it.

**And the residue refuses it too** (2026-08-29, the same mission). `mission-strategy.sh` names a
direction whose walk did not complete in `unreadable` rather than answering *no strategy* from a
blind read — `attributed: false` means *no strategy could be attributed*, and a walk nobody could
complete cannot say even that. `unattributed-work.sh` then reports `readable: false` with **null**
counts and names nothing, under **`strategy_unreadable`** when at least one active direction failed
and the pre-existing `all_strategies_unreadable` when every one did. The partial case is the point:
a mission attributed *only* to the direction that failed is named as residue in exactly the same
way, and which missions those are is precisely what the failed walk cannot say. `closing-residue.sh`
carries that block's reason to its own top-level `readable` through its existing contract, and both
consumers already behave — `quiescent` reads the residue's flag, so a degraded read yields no
`arrived` and therefore no `direction-arrived:<slug>` question, and the standing-rulings draft
reaches no writer with a candidate it could not attribute. **A non-degraded, non-empty residue is
untouched**: an unattributed mission is still an unattributed mission, and suppressing those would
be a different defect of the same shape.

**`no_citing_artifacts` is bounded, and the bound is stated rather than implied** (2026-08-26). After `/specificate`'s carry floor it means *nothing has answered this direction yet* — for work the loop emitted from an ask filed by `/propose`, by the inbound Slack sweep, or by `/fb`'s in-repo path, whose refs resolved. It says nothing about work a run never emitted, an ask judged to answer no direction, a ref that did not resolve, or an artifact written by hand outside `/specificate`. A hermetic test walks ask → reader → scaffold → floor for each writer's header shape and fails when the ref is dropped, so the reading is a fact a change can lose rather than a claim.

**And the inverse is readable, so the link is visible where missions are read** (2026-08-26).
`mission-strategy.sh` answers *which strategy does this mission belong to* by composing the same
walk — no second walker, no relation of its own, and no field on any artifact, which is what
keeps the `strategy:` relation retired for the third time. `/mission`'s bare roadmap names each
mission's strategy and renders an explicit **no strategy** where it could not attribute one: the
answer is as lossy as what it composes, `exhaustive` is `false` by construction, and a strategy
whose own read failed is named in `unreadable` rather than contributing silence. A mission may
belong to more than one strategy and is not de-duplicated across them — attribution is not a
partition.

**And what NO direction claims is readable too** (2026-08-28, mission
`say-what-the-direction-could-not-see-before-calling-it-arrived`).
`unattributed-work.sh` names the active missions and the queued tickets `mission-strategy.sh`
cannot attribute to any `active` strategy — composing that reader, adding no walker, no relation
and no field, one layer further up the same stack. A mission's queued tickets ride its row
(through `mission/scripts/read-relation.sh`, the relation's single reader) and a queued ticket
naming no active mission is its own entry.

It exists because `quiescent` renders as *this direction has arrived* — a reading that invites the
operator to **close** the direction — while being blind to everything the walk cannot see:
measured 2026-08-28, a strategy read `quiescent: true` with 125 landed items while four active
missions and ten queued tickets belonged to no direction at all. So a **degraded** residue read
makes `quiescent` false (`workaholic:propose`), and a **readable** but non-empty one is **named**
in `/moderate`'s `direction-arrived:<slug>` question and in `/propose`'s run report rather than
refusing anything. `readable: false` carries its own reason and **null** counts, never a zeroed
residue: an empty residue and a residue we could not read are the two states the whole reading
exists to keep apart. `exhaustive` is `false` by construction, and a loose queued ticket is
residue by construction too — this reader answers at the mission grain, so it over-reports rather
than under-reports and says so.

### What a direction leaves behind — the three readings, composed at the moment of the decision

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/closing-residue.sh [--state-row <file|->] <slug> [window] [workaholic-root]
```

Every reading above is bounded to `status: active`, so a direction stops being legible the instant
it is closed — and the operator was asked to close it with none of this in front of them. The
three facts a person needs are already in the tree and already readable; nothing composed them, so
nothing could **state them before the decision**. After the close it is a post-mortem; before it,
it is evidence.

| Block | Fact | Its own single reader |
| ----- | ---- | --------------------- |
| `waiting` | what it never reached | `attributed-work.sh`'s waiting grains |
| `residue` | what no direction claimed | `unattributed-work.sh` |
| `lifecycle` | its last lifecycle reading | `direction-state.sh` |

**It composes; it derives nothing.** No second walker, no relation of its own, no field on any
artifact — the only thing it owns is the **assembly**, and it owns that exactly once so no
consumer assembles it a second time and drifts. `--state-row` is how the assembly stays single
without recursing: `direction-state.sh` attaches this reading to its own rows by handing back the
row it already computed, so the lifecycle and the residue are **carried, never re-read**.

**A reading we could not make is never an empty one.** Each block carries its own `readable` and
its own reason, a degraded block reports **null** counts rather than zeroed ones, and a degraded
block makes the top-level `readable` false naming the source (`waiting_unreadable:<reason>`) —
this output is rendered beside a decision, and half of it rendered as silence is worse than none
of it. A non-degraded empty is **not** a degradation: `no_citing_artifacts`,
`no_activity_in_window` and an empty residue are real answers about a real tree and keep honest
zeros. A **closed** direction is readable too, reported `state: not_active` — the lifecycle reader
is bounded to the `active` set by design, and calling that a failure would leave the one caller
that reads this *after* a close unable to state anything at all.

`exhaustive` is `false`, always and by construction, inherited from all three: it says what is
visibly outstanding, never that nothing else is. It is **evidence for a decision, never an
assertion that closing is correct** — it closes nothing, proposes nothing, amends nothing and
lifts no gate, and the artifact keeps its three writers.

### Carrying an attribution the operator ruled

Some of that residue answers a direction and was published with the carry-forward link dropped.
`carry-attribution.sh <strategy> <mission>` appends the named `active` strategy's **own existing**
`feedback:` refs to the named active mission — the refs the walk above already reads — so the
repair reaches a pull request instead of a hand edit of `main`, which is exactly what `amend.sh`
was admitted to remove for the strategy artifact.

It copies `amend.sh`'s premise literally and that premise is its whole justification: a machine
only ever **carries** a ruling the operator **announced**, by explicit slug, onto a pull request
only they can merge. `/specificate`'s announcement route (step 9e) is the one caller; a run never
reaches it on its own reading that a mission looks like it belongs somewhere — that reading is
`unattributed-work.sh`, which decides nothing.

The bound is the safety property: it appends refs that already exist, authors none, removes none,
touches the `feedback:` line and nothing else (asserted over the candidate before writing), and
**never touches a strategy file** — that artifact keeps its three writers and this is none of
them. It refuses `strategy_not_found`, `mission_not_found`, `not_active` (a closed direction
acquires no new work), `no_revision` and `immutable_field`, and **writes nothing on any refusal**;
a re-run leaves the mission byte-identical and reports `already`.

**Its pull request does not auto-merge, and that is the caller's rule rather than the seam's.**
`publish-tree-pr.sh` derives `strategy_touching` from a path under `.workaholic/strategies/` and
this route writes `.workaholic/missions/`, so the seam cannot see it. `/specificate` leaves
`WORKAHOLIC_AUTO_MERGE` unset at step 9e and a hermetic test pins that step's text — a weaker
guarantee than the strategy exemption's, recorded as such rather than implied to be the same.

## Scripts

```bash
# Create — the writer that mints one. Body (the ## Aim prose) arrives on stdin.
printf '%s\n' "<aim prose>" | bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/create.sh \
  "<title>" <target-date YYYY-MM-DD> "<assignee-email>[,<assignee-email>...]" "<schedule prose>" ["<feedback-ref>,..."]

# Amend — the ONLY writer of a LIVE direction's three revisable parts. Aim prose on
# stdin with `--aim -`. At least one revision, or it refuses `no_revision`.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/amend.sh <slug> \
  [--target-date <YYYY-MM-DD>] [--schedule "<prose>"] [--assignees "<a>[,<b>...]"] [--aim -]

# Which strategy a mission belongs to — the inverse of the attribution walk. Pure read.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/mission-strategy.sh [--root <dir>] [<mission-slug>...]

# List — every strategy with its status, target date and assignees, as JSON.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/list.sh [--status active|achieved|abandoned]

# Read — one strategy's fields and body, as JSON.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/read.sh <slug>

# Close — the ONLY writer of an end state.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/close.sh <slug> achieved|abandoned

# Attributed work — the ONE reader of "which work belongs to strategy X in window W".
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/attributed-work.sh <slug> [window] [workaholic-root]

# Direction state — the ONE reader of "what is the lifecycle state of this direction".
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/direction-state.sh [--open-proposals <file>] [window] [workaholic-root]

# Unattributed work — the ONE reader of "what does no direction claim". Pure read.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/unattributed-work.sh [--root <dir>]

# Carry attribution — appends a named strategy's OWN refs to a named mission. Writes
# one frontmatter line on one mission and nothing else; never touches a strategy.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/carry-attribution.sh <strategy-slug> <mission-slug> [workaholic-root]

# Closing residue — WHAT A DIRECTION LEAVES BEHIND, composed from the three readers above.
# Pure read; `--state-row` carries a direction-state row already in hand instead of re-reading.
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/closing-residue.sh [--state-row <file|->] <slug> [window] [workaholic-root]
```

Every script is POSIX `#!/bin/sh -eu`, takes an optional trailing `.workaholic` root so it can be
pointed at another tree, and emits one JSON object. `create.sh` refuses an empty aim, an empty
assignee list, a non-`YYYY-MM-DD` target date, and an existing slug — the same presence floor
`validate-strategy.sh` enforces at the write seam, so a refusal is never a surprise later.

## The lifecycle state of a direction — one reader, composed, never re-derived

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/strategy/scripts/direction-state.sh [--open-proposals <file>] [window] [workaholic-root]
```

`propose/scripts/survey-strategies.sh` emits four readings — `overdue`, `expiring`, `dormant`
and `quiescent` — beside
`pace` and the refusal list. A consumer assembling a lifecycle answer out of them would be a
**second derivation** of a state this repository insists has one reader, exactly as
`attributed-work.sh` is the only walker of the attribution. So `direction-state.sh` **composes**
that survey and re-derives nothing: no date arithmetic, no attribution walk, every state a
projection of a field the survey emitted.

| Answer | Meaning |
| ------ | ------- |
| `live` | active, in date, and something is happening against it |
| `arrived` | live, legible — and **its work has landed** with nothing waiting (`survey-strategies.sh`'s `quiescent`) |
| `overdue` | the `target_date` has passed (`survey-strategies.sh`'s `overdue`) |
| `expiring` | the `target_date` is **approaching** — inside the survey's own window (`survey-strategies.sh`'s `expiring`) |
| `dormant` | live, in date, legible — and nothing landed, nothing waiting, no proposal open |
| `unreadable` | the attribution could not be read; **never** folded into any other answer |
| `none` | **repository-level**: no `status: active` strategy exists at all |

**The precedence is the only thing this script owns**, and it is fixed: `unreadable` > `arrived` >
`overdue` > `expiring` >
`dormant` > `live`. `unreadable` first because a reading we could not make must never be dressed
as one we did; `overdue` before `dormant` because a direction past its date is the operator's to
re-date or close whatever else is true of it, and one direction reported twice under two names
would double the question a consumer asks about it.

**`arrived` outranks `overdue`, and a later reader must not quietly reorder them.** `quiescent`
carries no date term, so a direction that finished late is both `quiescent` and `overdue` and the
precedence has to choose. The two states ask a person for **different acts**: `overdue` says
*re-date this or close it*, `arrived` says *your work is in — is this done?*. A direction whose
work is all in is the operator's to **close** whatever its date says, and reporting that success
as lateness is naming a success as a failure — the defect the reading was added to remove.
Ranking `overdue` first would make `arrived` unreachable for the one case it exists to serve,
since a finished direction is very often a late one.

**`expiring` sits between `overdue` and `dormant`, and both neighbours are argued** (2026-08-29,
mission `warn-a-direction-before-its-date-silences-the-loop`). Against `overdue`, below it: a
date that has **gone** is a stronger fact than one approaching, and the two ask for the *same*
act with different urgency, so where one word must be chosen the fact that has already happened
wins. Against `dormant`, above it: a direction near its date and silent is about to be silenced
**by the date** first, and the date is the fact with a deadline on it — `dormant` stays true
tomorrow, while `expiring` stops being actionable the moment the date passes, at which point the
reading becomes `overdue` and the warning was never given. (`arrived` outranks both for the
reason above: it asks for a *different* act, which is why a rung is not a severity ordering.)
The leaving rides an `expiring` row exactly as it rides `arrived` and `overdue`, at no extra
read — a person asked to re-date a direction **before** its date needs the same evidence as one
asked to close it after.

**`arrived` is a candidate, never a verdict.** A strategy's "Reached when" is prose no script
reads, so nothing can know the aim was met — only that everything attributed to the direction has
landed and nothing is queued. The reading says *this looks finished*; the operator's answer
decides. **No reading closes a direction**, and that is pinned mechanically rather than by this
sentence (below).

**`none` rides the same output as the per-strategy list** on purpose: a caller asking *what is
the direction layer doing* must not have to call twice to learn that it is empty.

**What it does not answer.** It never closes, never proposes, never **amends**, never lifts a gate
and writes nothing — reading a direction's state and writing one are different acts, and
`amend.sh` is reached only from `/specificate`'s announcement route. It is not a second `pace`: `pace` answers
*will this arrive*, `overdue` answers *has the date passed*, `dormant` answers *is anything
answering this at all*, `expiring` answers *is the date about to arrive*, and `arrived` answers
*has its work all come in*. It inherits the survey's
lossiness and reports it: `dormant` **and `quiescent`** require
`owns == "mine"` upstream, so **another identity's direction can only ever read `live`,
`overdue` or `expiring` here** — that limit is stated in the script's header rather than left to be discovered.

**It makes no second network call.** The survey's one call is the open-proposal gate; a caller
already holding that read passes `--open-proposals` through. A survey that refuses yields
`readable: false`, `repository: "unreadable"`, the survey's own reason carried through, and
**exit 0** — a reader that could not read is reported, never rendered as quiet.

**The refusals are pinned mechanically, not by this prose** (2026-08-26, count moved 2026-08-27).
The writer rule on this artifact has been re-decided three times, so
`scripts/test-workflow-scripts.mjs` fails if `/moderate`'s `direction-health` step writes anywhere
under `.workaholic/strategies/`, if its closure reaches `close.sh`, `amend.sh` or
`open-proposal.sh`, if the set of writers under `strategy/scripts/` is anything other than
`amend.sh`, `close.sh`, `create.sh`, or if running the step changes any `/propose` gate outcome.
**The count moved from two to three deliberately and the move is recorded at the assertion
itself** — the pin exists so a re-decision cannot happen silently, and moving it silently is
exactly what it was written to catch, so a **fourth** writer still fails it. The writer count is a
grep and its bound is stated in the test: a writer reached *indirectly* would pass it, so it
catches the failure that has actually happened rather than every possible one.

## The write-time floor

`hooks/validate-strategy.sh` (PostToolUse `Write|Edit`) holds any file under
`.workaholic/strategies/` to: non-empty `type: Strategy`, a `status` in the closed set, a
`YYYY-MM-DD` `target_date`, non-empty `assignees`, and non-empty `## Aim` and `## Schedule`
sections. Like its siblings it checks **presence, never quality**, and **git-tracked files are
grandfathered** — history is never retro-blocked.

**The hook does not cover an amendment, and `amend.sh` carries the floor instead** (2026-08-27).
Every strategy an amendment touches is by definition already git-tracked, so the grandfathering
makes the hook silent on exactly that class of write — the one class where the file was not
freshly authored by a human looking at it. `amend.sh` therefore evaluates the three properties
over its **post-revision candidate** before touching the artifact, refusing under `create.sh`'s
own names (`bad_target_date` / `no_assignees` / `empty_schedule` / `empty_aim`) with **nothing
written**. Write-then-revert is refused as a design: a revert is a second write, and what this
artifact needs is that a refusal never wrote.
