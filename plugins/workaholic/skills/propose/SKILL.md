---
name: propose
description: Use when a session runs `/propose` — by hand, or as the `propose` subagent of an `/infinite-development` tick — read the running identity's own active strategies, plan the one mission whose evolutionary move would bring the nearest one closer to its aim, and open that plan as a GitHub issue the next `/specificate` tick will ingest. Defines the mission grain, the eligibility gates, the three moves, the refusal of housekeeping, and the scripts.
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:strategy
metadata:
  internal: true
---

# Propose

The act that supplies the loop's own ask — so the loop turns without a person having to write
the next ticket, and what a person supplies instead is the **direction**. It runs as the
`propose` subagent of an `/infinite-development` tick, followed in the same subagent by
`/specificate`: the ask this command supplies is in the inbox that discovery reads seconds
later, and the `implement` subagent drives what it queued (`workaholic:loops`).

It reads the running identity's own `status: active` strategies, plans the bounded **ticket or
mission** whose **evolutionary move** would bring the nearest one closer to its aim before its date, and
opens that plan as a **GitHub issue assigned to that identity** — the one surface
`/specificate`'s unattended entrance actually reads. The unit follows the hypothesis's natural
scale (*The proposal is a bounded plan*, below).

**It is a pure reader of this repository.** No file, no commit, no branch, no pull request, no
merge, no deployment, and no `AskUserQuestion` at any step. Its only writes are issues, and
every one lands on GitHub, not in the tree — the same contract `/standup` and
`/prepare-release` hold, and the reason it adds no unattended-`main`-writer class.

## The channel is the tick's, not this command's

**The Slack turn and the inbound sweep moved out of `/propose` on 2026-09-03** (the developer's
instruction; `workaholic:loops`). The tick reads the channel, answers a question in its own
thread, files every ask as an `[FB]` issue and posts the receipt — all before this run starts,
so a person's redirection is captured in the same five minutes it was written rather than
waiting behind a strategy judgement.

**This command's scripts stayed here** — `list-swept-slack-refs.sh` (the dedup ledger) and
`file-inbound-ask.sh` (the one writer of a captured ask, stamping the three-axis header, the
`slack-ref:` marker and the permalink) — because moving them would be churn for nothing.
`commands/infinite-development.md` is the one place their use is specified.

**`/propose` posts nothing to Slack and reads nothing from it.** The proposal is announced by
nobody: the issue is assigned to exactly one person and GitHub already delivers it, and a
status line addressed to nobody is the noise that retired `🔧 Needs a decision` and
`📦 Release Preparation`.

## The channel reading is evidence, not a run-level brake

The tick still hands in whether a human spoke so the report can distinguish a quiet channel from
an unreadable one. That reading does not decide whether a strategy has another useful experiment:
the strategy, its declared stage, the evidence accumulated against its Aim, its open work and the
repository WIP limit decide continuation.

**The reading is handed in, not taken.** The tick already read the channel, so it passes its own
answer down: **`human_spoke`**, **`only_the_loop_spoke`** or **`unreadable:<reason>`**. The window
is the sweep's own — `WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS`, default 26 — so there is
no second query, no second window and no cursor, and a run given no reading at all treats it as
`unreadable`.

**`only_the_loop_spoke` is reported and gates nothing.** A quiet channel can coexist with a live,
human-authored strategy whose next hypothesis is supported by repository evidence. The 2026-09-02
run-level refusal is retired: it stopped every direction from one transport observation and made
silence stand in for an operator decision.

**`unreadable` remains distinct from silence.** A channel that could not be read is not quiet, and
a repository with no Slack transport reads `unreadable`, never `only_the_loop_spoke`. Report the
reason and continue; neither state changes the reactive path or the strategy survey.

**What may originate a mission at all is not this skill's rule.** It is stated once, at
`rules/workaholic.md`, *What May Originate a Mission*, and cited here rather than restated: a
human's ask or a human-authored strategy may; a record a routine wrote about the loop's own
apparatus (`self_authored`) and a proposal refining a prior self-proposal (`self_refining`) may not.

## The proposal is a bounded plan

**One proposal plans one bounded hypothesis.** The issue names the experience it demands and its
ordered ticket set. One ticket is valid when that is the whole hypothesis. Several tickets that
share a mid-term outcome may form a mission, sized by **what the container must be able to hold**
(`rules/workaholic.md`, *What a Mission Must Be Able to Hold*); independent hypotheses remain loose
tickets. `/specificate` emits the validated plan rather than re-deriving its scale.

**The move vocabulary and every refusal built on it apply at either scale.** The move is what the
ticket or mission does to the Aim, and `## What this is chosen against` names the rival hypothesis
or plan. A proposal cannot hide housekeeping behind either container.

**The body floor includes `## Experience` and `## Tickets`** (`open-proposal.sh`) beside the three
commitment sections below. One ticket is a valid bounded hypothesis; `/specificate` emits it as a
loose ticket. Two or more tickets may form a mission only when they share the mid-term outcome,
and `mission/scripts/check-floor.sh` retains that mission-publication floor. The ceiling stays a
judgement.

**`/propose` plans; `/specificate` writes.** The operator's ask is that this routine *take charge
of planning*, and planning is not writing: the publish-tree seam, the ticket floor, the carry
floor and the pull request all live on the `/specificate` side, and moving the write here would
duplicate every one of them and give the tree a second unattended writer. The granularity moved;
the architecture did not. `/propose` stays a **pure reader** whose only write is a GitHub issue.

## The one thing it is for: an evolutionary move, never housekeeping

Every proposal declares exactly one **move** against the strategy's Aim, and a run that cannot
name which one it is emits nothing:

| Move | What it does to the aim |
| ---- | ----------------------- |
| **`depth`** | Go further into what the aim already covers than the landed work has gone. |
| **`breadth`** | Go into a part of the aim nothing has touched yet. |
| **`contraction`** | Remove or unify something the landed work made inconsistent with the aim. |

**A move that DESCRIBES the aim instead of advancing it is refused by name** (2026-08-22).
A strategy whose Aim names something to be **built** may not be answered with a proposal whose
move would produce **documentation about that Aim**. At the mission grain the test is the same
one: a *mission* whose whole ticket set would produce documentation about a building Aim is
refused exactly as a single documenting change was. The refusal is reported like every other
gate (`describing_move`), and a tick refused for it opens nothing rather than reading as idle.

**A move that INVENTS a cross-cutting obligation is refused by name** (2026-09-02, issue #862).
A proposal whose deliverable is a new per-page verdict, stamp, score, gate, or frontmatter key
laid over every page of a repository — a "demonstrability" verdict on ~100 specification pages,
a build gate failing on its absence, a generator and a model module to carry it — is not an
evolutionary move; it is scope the operator never granted, whatever move word it claims.
Measured: roughly fifty self-approved propose→specificate→implement cycles built exactly that
apparatus, unattended, against a direction the operator had already judged arrived; the operator
called it incomprehensible AI slop and tore it out by hand, so the waste was paid twice. The
refusal is `invented_obligation`, and it is a judgement the run makes at composition — the test:
does this mission create an obligation that every existing page/artifact must newly satisfy,
where no strategy acceptance item, Schedule milestone, or human ask names that obligation? Such
work is proposable only when a human ask names it, in which case it arrives through the inbound
path and never through origination. **And a `depth` move has a floor**: it names the acceptance
item or Schedule milestone it advances, on the strategy it targets — a move that can justify
itself only by "the same reasoning has not yet been applied to X" is describing the move, not
the aim, and is refused with it.

**A move that DEEPENS THE LOOP'S OWN INVENTION is refused by name** (2026-09-02, mission
`refuse-an-ask-the-loop-wrote-to-itself`). **Measured**: a chain five links long in one day — a
verdict, then where its difference is seen, then what present practice it is measured from, then
recording that practice — each link a defensible `depth` move against the Aim, each proposed,
ticketed, implemented and merged by the next ticks, and the operator abandoned the direction
mid-drive and reported the whole day as waste with their own development stopped throughout.
`depth` on a documentation-shaped aim can always invent one more axis, and nothing at the bar
asked whether **the thing being deepened was itself the loop's own invention**.

The refusal is **`self_refining`**, and the test the run applies at composition is: *does the
thing this move deepens trace back to a human's ask or a human-authored strategy — or only to a
previous proposal this loop wrote?* A chain whose root is the loop's own output is refused, and
the tick reports the word rather than reading as idle.

**What it must not catch**, named here so the rule is bounded rather than chilling: a second
mission answering a **human's** ask on the same subject, and the follow-up repair mission the
strategy's own scale allows beside its first (`rules/workaholic.md`, *What a Mission Must Be Able
to Hold*). Depth is not banned; depth on the loop's own invention is.

**It is a judgement, not a gate, and it stays out of the mechanics.** It reaches no expression
in `survey-strategies.sh`, changes no `refusal`, no `pace`, no sort and no `selected`; a survey
run over the current strategies is byte-identical before and after. It is not folded into
`describing_move` either — one word answering two questions is how two questions drift, which
this repository has recorded twice.

*Why the housekeeping refusal below does not already catch it.* That one works because
housekeeping is chosen against **nothing** — nobody argues for the mess — so the body floor's
`## What this is chosen against` section catches it. A new page about the Aim passes that floor
honestly: it is chosen against something real (the Aim is undocumented here), it commits in the
imperative, and it is a textbook `depth` move — *go further into what the aim already covers than
the landed work has gone*, and a document about what the aim covers is further than no document.
Measured over weeks on a consuming repository whose strategy Aim was to build an application
platform: every mission attributed to it produced documentation, and the deployment worker's own
config still said it had no code of its own. The loop was obeyed, not broken.

*The test, and it is the exemption that makes it checkable rather than a matter of taste.* Read
the strategy's Aim. **A strategy whose Aim is itself documentation is unaffected** — there a page
*is* the advance, and refusing it would be refusing the direction. The refusal applies only where
the Aim names a thing to be built and the move would produce prose about it instead.

*Documentation is not banned.* A build strategy legitimately needs some, and a proposal may carry
it alongside what it builds. What is refused is documentation as **the move** — chosen instead of
the build, which is the shape that repeats forever. The judgement is the run's and is stated in
the proposal body, where a human can argue with it; do not try to detect "is this a document"
from a file extension, because the proposal declares what it will produce.

**Housekeeping is refused by name.** "Tidy this up", "the docs drifted", "add a test",
"rename for consistency" are `/moderate`'s job. A mission-shaped proposal makes this
easier to see rather than harder: a housekeeping direction decomposed into seven tickets is
seven pieces of housekeeping, and `## What this is chosen against` still has nothing to name. What they have in common is that they are
chosen against **nothing** — nobody would argue for the mess — which is why the body floor
requires a `## What this is chosen against` section: a proposal that cannot name the fork it
did not take is either uncontroversial or unformed, and both are the safe small change the ask
refuses. **The proposal commits**: it states the change in the imperative, and it carries no
"consider whether", no "we might", no menu of options.

## The bar this drops, and the brake that replaces it

This is the **first** unattended routine here to drop the standing conservative bar
(`workaholic:specificate`, *The judgment bar*: when unsure, record only, and say what made you
unsure). It drops it on purpose — a routine that proposed only what it was sure of would
propose housekeeping. What replaces the bar is not a softer judgment but a set of
**mechanical, derived gates** the running session cannot decide differently
(`survey-strategies.sh`; each refusal is reported by name):

`not_active` · `not_mine` · `past_target_date` · `no_feedback_refs` · `work_waiting` ·
`open_proposal` · `wip_limit` · `attribution_unreadable`


**Planning is one job across three skills, and it is named in one place**: `CLAUDE.md`, *The planning job* — which act lives where, what it may act on, and the four things it may not do, each with the rule that forbids it. The `wip_limit` rung is one of its five acts; the section is where a reader learns the other four and why the loop plans no further.

**`wip_limit` bounds the REPOSITORY, where the two halves above bound a strategy** (2026-09-01,
ticket `20260901123357-hold-new-divergence-above-a-work-in-progress-limit`). `work_waiting` and
`open_proposal` give *one mission per strategy in flight*, and nothing bounded the repository —
N directions each inside their own gate still put N missions in flight together. Measured
2026-09-01: **six missions running in parallel with no sequencing**, every merge to the base
re-conflicting five open pull requests on the loop's own generated index, reported hourly as an
external fact. Two in flight and four queued would have produced the same work with none of the
conflicts.

- **Absent means no limit, and that is the safety property.** The bound is declared as
  `WORKAHOLIC_WIP_LIMIT` in the repository's own `.claude/settings.json` `env` block — the same
  home, for the same reason, as `WORKAHOLIC_CADENCES`. A repository that declares nothing is
  **byte-identical** to one before this existed: the count is not even taken, the gate reports
  `not_declared`, and a tick behaves exactly as it did. Picking a number for every consuming
  repository is the tunable constant this layer refuses; the operator who measured
  six-in-parallel is the one who knows what their repository can carry.
- **It is placed LAST in the ladder**, so a direction refused by any earlier gate never reaches
  it and is not also reported as held by the repository's bound.
- **What is counted**: active missions that still have queued work — not open pull requests,
  which conflate the loop's own paperwork with the product's work, and not a sum over the
  per-row `waiting_missions`, which would count a mission serving two directions twice.
- **A gate that cannot be read is not a gate.** A non-numeric declaration (`bad_limit`) or a
  count that could not be taken (`wip_count_unreadable`) holds **nothing** and reports its
  reason, matching `attribution_unreadable` and `inbox_unreadable` — holding origination on a
  failed read would silently stop the loop, which is worse than one extra mission.
- **It holds origination only.** Inbound work is judged and emitted by `/specificate`
  regardless, exactly as the `観察中` stage gates origination and nothing else; a limit that
  swallowed the operator's own instructions on a busy day would be a defect, not a brake.
- **The gate reports itself whether or not it fired** — the survey carries
  `wip: {declared, limit, count, readable, reason}`, so a held tick says *why* rather than
  looking idle. Holding divergence makes the loop quieter, which looks like the loop stopping,
  and an unexplained silence is the outage this repository has already measured twice.

**`describing_move` is reported beside them and is not one of them.** Those nine are computed by
`survey-strategies.sh` and the running session cannot decide them differently; the describing
refusal is the run's own **judgement**, stated in words and arguable by a reader — which is why it
is named here rather than folded into the mechanical list. It is a refusal on the same standing as
housekeeping's, and like it, it is reported by name so a tick refused for it never reads as idle.

**`attribution_unreadable` now covers a walk that did not complete** (2026-08-29, mission
`keep-the-closing-link-readable-as-the-corpus-grows`). It used to mean only *the attribution reader
produced no output at all*. Since that reader learned to tell *found nothing* from *could not look*
(`workaholic:strategy`), a walk it could not complete reaches the same refusal — **the word this
condition already had, never a second one** — and every reading composed on the walk is emitted as
**unmade** rather than as false: `pace: unknown`, `dormant: false`, `quiescent: false`, and **null**
`count` / `active_count` / `waiting_*` instead of zeroes. `direction-state.sh` answers `unreadable`
for such a row through its existing precedence and carries the nulls rather than re-zeroing them.

**`work_waiting` cannot stand open on it**, which is the whole point: a degraded walk cannot prove
the brake is clear, and a gate that cannot be read is not a gate — the rule `no_feedback_refs` and
`inbox_unreadable` already hold themselves to. Measured against the pre-change survey: a corpus one
unreadable path wide put **both** directions in `eligible` with `dormant: true`, `waiting_count: 0`
and both `selected`, on a walk that had read nothing. **The date terms do not move** — `overdue`,
`expiring` and `days_to_target` come from the strategy's own `target_date`, never from the walk.
The cost is accepted for the reason `inbox_unreadable` already records: proposing against a reading
nobody can trust is worse than not proposing, and the degradation is now visible rather than silent.

Three of them carry the design:

- **`work_waiting` + `open_proposal` are one gate in two halves, and they hand off with no
  window** — from the issue opening until its `/specificate` pull request merges the issue is
  open; **that same merge puts the mission on `main`**, so `work_waiting` holds from the same
  instant. The handoff is window-free by construction rather than by timing. So **one mission
  per strategy is in flight at a time**, enforced continuously with no cursor and no stored
  state. A per-day bound was considered and refused: the ask is for three routines turning an
  **hourly** loop, and a daily cap on the only routine that originates work would cap the loop
  itself at one turn a day.

  **`work_waiting` reads the mission grain since 2026-08-26**, in two OR'd terms and neither is
  redundant. The **mission** term — an *active* attributed mission — is what holds the gate
  while a mission's last ticket sits at a pull request with its queue already drained; under the
  change-grain arithmetic that gap was the design (the next *change* could start) and at the
  mission grain it is exactly the window a second mission would slip through. The **ticket**
  term stays because a loose ticket emitted with no mission around it must still brake. Neither
  counts: `> 0` is the whole question, so a mission's seven queued tickets are one mission in
  flight and not seven units of waiting work. It releases when the mission **closes**, which
  since 2026-08-23 the archive gate does on its own arithmetic — so *re-proposed when that
  mission finishes* is mechanical, not a judgement. Both terms are derived from the readers that
  already exist: `attributed-work.sh` for attribution (still the **one** attribution reader) and
  each ticket's own `## Key Files` for its kind. No counter was added and no artifact gained a
  field.

  **The describing/advancing distinction survives at the new grain** (2026-08-23): a mission is
  classified by its own queued tickets, so a mission whose queue is entirely `describing` does
  not gate an advancing proposal against a building Aim. A mission with **no** queued tickets is
  `unknown`, and `unknown` counts toward advancing — the same rule a single unknown ticket
  follows, and for the same reason: mislabelling build work as descriptive is the failure the
  gate exists to prevent.

  **`open_proposal` needed no change to match.** `list-open-proposals.sh` reads the
  `strategy: <slug> / move: <move>` marker `open-proposal.sh` stamps, and a mission-shaped
  proposal carries that marker exactly as a change-shaped one did — so an open mission-shaped
  proposal gates its strategy without the remote half learning anything about the grain.
- **`over_cap` is retired** (2026-08-22, the developer's ruling: one proposal per tick is not
  enough — the tick should propose everything it can conclude at that moment). A tick now
  proposes against **every** eligible strategy, still ordered nearest `target_date` first so a
  tick that dies partway has advanced the most urgent direction. `WORKAHOLIC_PROPOSE_MAX`
  survives as an explicit opt-in bound and its **default is unbounded** — the default is the
  point, because a default of 1 is what produced the starvation below.

  **The old reasoning is answered, not dropped.** It was: a developer carrying eight directions
  must not wake to eight issues at `:40`. The volume bound was never this cap's to provide —
  `work_waiting` and `open_proposal` already give *one proposal per strategy in flight at a
  time*, so eight issues arrive only when all eight directions are idle, and then all eight
  genuinely need their next move.

  **And the cap ran backwards.** It reduced no total; it fixed an *order*, putting some
  directions permanently behind others — and a strategy is skipped while its *own* work is in
  flight, so the direction whose work takes **longer** was proposed against **less** often. The
  direction that most needs its next move was the one being starved. Measured on a consuming
  repository: two active strategies sharing a `target_date`, one building a platform whose build
  work sat queued for hours and one documentation direction that drained fast; the fast one won
  every tick for a day while the other never got a turn.
### Pace: the one reading that is not a brake

Every gate above **reduces** proposals. None of them asked whether the direction will
**arrive**, so a strategy could be perfectly gated — every brake correct, every tick silent for
a correct reason — and reach its date with nothing built. `target_date` was read only by
`past_target_date` (*it has passed*), never *will it be met*; `landed[]` only by
`no_citing_artifacts` and `work_waiting`. Both were already in the survey; nothing put them
together.

**Measured** on a consuming repository: a platform strategy seven days from its `target_date`
whose 19 attributed artifacts were all specification pages, with no `tsconfig` and a deployment
config still stating that the worker had no code of its own. Every gate was correct on every
tick.

`survey-strategies.sh` now emits **`pace`** on every surveyed row — eligible **and** refused,
because a direction that will not arrive *and* is gated produces no proposal, and that is the
case that starves.

| `pace` | Meaning |
| ------ | ------- |
| `late` | Nothing landed over a period **as long as the one that remains** — one window looked back over, nothing in it, and fewer days left than that window |
| `on_course` | Something landed in the window, or more runway remains than the window can see |
| `unknown` | The attribution read was degraded, or the strategy has no resolvable `target_date` |

**The derivation needs no threshold, which is what makes it defensible.** Both of its terms are
already justified here: the window is *the evidence the judgment is made against*, and the
remaining days are the strategy's own date. A ratio would imply an accuracy `landed[]` cannot
support — its own reader states attribution is transitive and **lossy**.

**It is evidence, never a verdict.** `unknown` is a real third answer and never collapses into
either other one: a degraded read cannot tell a stalled direction from a moving one, and an
undated strategy is malformed rather than late.

**It does not judge what landed.** Whether documentation advances a build aim is
`describing_move`'s question, answered there. This is rate and remaining time only.

**It changes order, never eligibility.** Eligible strategies sort **late first**, then nearest
`target_date`, so a tick that dies partway has advanced the direction least likely to arrive.
`unknown` orders exactly where it did before. A late direction that is `work_waiting` is still
`work_waiting` — the temptation to let lateness *lift* a gate is refused, because that produces
two proposals for one direction and the answer to "the work is in flight but not moving" is a
person, not another proposal.

**Who is told, and why not here.** `/propose` posts nothing and its run report is read by
whoever opens the session — on the day it matters, nobody. So the `late` reading is carried by
`/moderate`'s `strategy-pace` step, which calls this same script (a pure read, no stored state,
no second derivation) and asks the strategy's assignee once. The alternatives were weighed:
`/propose`'s own report is the invisibility this exists to end — measured with `over_cap`, which
named itself on every tick and still hid a day of starvation — and the proposal issue says
nothing precisely when the direction is gated.

### Overdue: has the date passed

`pace` answers *will this direction arrive*. It cannot answer *has its date already gone*, and
must not be asked to: `late` requires `(.landed | length) == 0`, so a direction that sailed past
its `target_date` **while producing work** reads `on_course`. It is then refused
`past_target_date` — a correct refusal — and produces no proposal and no question, forever.

`survey-strategies.sh` emits **`overdue`** as its own boolean on every surveyed row, eligible and
refused alike, `true` exactly when `days_to_target < 0`. The refused case is the whole point: a
reader that saw only `eligible` would never see a direction whose date has gone.

**It changes no gate.** `overdue` is computed *before* `refusal`, so `past_target_date` refuses
exactly the strategies it refused before, `pace` is byte-identical, the sort is untouched, and
`selected` does not move. Folding it into `pace` as a fourth value is refused: one field
answering two questions is how the two drift.

**Boundaries, stated rather than tuned.** A row with no resolvable `target_date` has a `null`
`days_to_target` and is never `overdue` — a malformed strategy is not a late one. `days_to_target`
is computed against a UTC `$today`, so a direction expiring **today** reads `0` and is not yet
overdue.

Who is told is `/moderate`'s business, not this routine's, for the reason `pace` records above.

### Expiring: the date is about to arrive

`pace`, `overdue` and `dormant` all answer **backwards**. None answers *this direction is about
to stop originating work*, so a live, in-date, `on_course` direction one day from its
`target_date` produced no reading and no question anywhere in the layer — and the day after,
`past_target_date` silenced origination with the only signal being `direction-overdue`, asked in
**arrears**. Measured on `an-autonomous-improvement-loop-run-by-the-routines` at the hour the ask
was written: `days_to_target: 2`, `pace: on_course`, `overdue: false`, `dormant: false` — every
reading healthy, two days from silence.

`survey-strategies.sh` emits **`expiring`** on every surveyed row, eligible and refused alike,
`true` exactly when `days_to_target != null` and `0 <= days_to_target <= $window_days`. The
refused case is the point rather than a courtesy: a direction with a date approaching normally
has work in flight, so it is refused `work_waiting` — the very shape the reading exists to catch.

**The threshold is not a threshold.** Both terms were already on the row and already justified
there: `$window_days` is the evidence window the judgment is made against, derived from the same
`$WINDOW` `pace` is derived from, and the remaining days are the date the strategy itself
declares. So the reading means *less runway remains than the window the judgment can see* — the
point at which `pace` stops being able to tell whether the direction will arrive. **A tunable
constant is refused by name**: a fresh number is one nobody can defend, and a narrower window
must narrow the reading with it.

**Folding it into `pace` as a fourth value is refused**, for the reason `overdue` records: one
field answering two questions is how the two drift.

**Boundaries, stated rather than tuned.** `days_to_target < 0` is the answer `overdue` gives and
never this one, so the two are exhaustive and disjoint with no gap and no overlap; a direction
whose date is **today** reads `0` and **is** expiring, not overdue; and a row with no resolvable
`target_date` is never expiring — malformed is not near, exactly as it is not late.

**It changes no gate.** `expiring` is computed *before* `refusal`, so every refusal, `pace`,
`overdue`, `dormant`, `quiescent`, the sort and `selected` are byte-identical across the
boundary. What changes is only that the run report **says** it: a tick proposing against an
`expiring: true` strategy names `expiring` beside that proposal as evidence, in the same voice
`pace` and `arrived` use. Proposing *more urgently* against an expiring direction, and *skipping*
one to leave the operator room to decide, are both refused deliberately — each makes the output
of the one routine that originates work a function of a clock, which is the coupling `pace` was
kept out of. **A machine re-dating or closing a direction on this reading is refused too**: the
artifact keeps its three writers, and a run never amends a direction on its own reading.

Who is told is `/moderate`'s business: `direction-expiring:<slug>`, addressed to the direction's
assignee, once, before the date.

### Dormant: a live direction nothing is answering

A direction can be perfectly legible, perfectly in date, perfectly eligible — and have nothing
happening against it. `/propose` reports `no_evolutionary_move`, which is the honest answer, into
a run report that on the day it matters is read by nobody; the direction stays eligible on every
tick and produces nothing. That state is byte-identical to a healthy idle hour, which is the
defect.

`survey-strategies.sh` emits **`dormant`** on every surveyed row. It is `true` only when *all* of
these hold, and every one is already computed here or by `attributed-work.sh` beneath it — no new
counter, no field on any artifact, no second derivation of `pace`:

| Term | Meaning |
| ---- | ------- |
| not `unreadable` | the attribution could be read at all — a degraded read is never dormant |
| `status == "active"`, `owns == "mine"` | a live direction of this identity's |
| `days_to_target >= 0` | not already `overdue`; that reading is its own |
| `feedback_refs` non-empty | something the reader *could* have seen, so silence means silence |
| `(.landed \| length) == 0` | nothing landed inside the window |
| `waiting_missions + waiting_count == 0` | nothing waiting at either grain |
| no open proposal | the last turn is not still sitting in the inbox |

**It is not `pace: late`**, which requires the date to be *near* (`days_to_target <=` the window):
a direction a year out with nothing happening is dormant and not late. **It is not
`no_citing_artifacts`** either — that reading is explicitly *not* a refusal here, and neither is
this: a dormant direction stays **eligible**, which is precisely what makes its silence a
*finding* rather than a gate. `refusal`, `pace`, the sort and `selected` are untouched.

**The two periods differ, and that is inherited rather than reconciled.** `landed` is bounded by
the survey's window while `waiting_*` is computed over the queue, so the reading means *nothing
landed in the window and nothing is waiting at all*.

**A direction filed an hour ago reads dormant immediately.** That is correct — it is exactly the
"nothing is answering this" state a person should be told about — but it is a description of the
direction, never an accusation, and the question's wording is held to that (`workaholic:moderate`).

#### An answer turns the reading back into work (2026-09-08)

Mission `turn-quiescent-blockers-into-mature-decisions-and-resume-work`. `no_evolutionary_move` is
the honest end of a tick and it is **an observation, never permission to end silently** — but the
moment somebody answers the question `/moderate` asked about that direction, the next tick was
still deriving the same silence from the same rows and reporting the same word. The answer stayed
in the tick log and reached no judgment.

**Before reporting `no_evolutionary_move` for a direction, read
`moderate/scripts/decision-maturity.sh --strategy <slug>` and name what it says about the
answer** — `answer_state`, and `resumable` when it is `true`. A
`resumable: true` reading means exactly two things at once: a person answered, and the direction
still reads blocked. Their words are **evidence for step 4's own judgment** — read the answer, and
ask again whether a `depth`, `breadth` or `contraction` move can now be named against the Aim.
**A `no_evolutionary_move` report that does not say whether an answer stands is non-conformant on
its face**, the enforcement this repository puts on every act whose absence no script can see.

**It is evidence, and it lifts no gate**, so every mechanical brake is untouched: `work_waiting`,
`open_proposal`, `arrived`, `no_feedback_refs`, `past_target_date`, `wip_limit` and the WIP bound
refuse exactly as before, and a direction the survey refused is not proposed against because
somebody answered a question about it. Both outcomes name the evidence — a move now named says
which answer let it be named, and a refusal that still stands says the answer did not change the
reading.

**There is no reopen flag, no cursor and no new field.** `resumable` is two existing readings
conjoined, derived at the moment it is read, so nothing has to be cleared and nothing can go
stale. A container that carries no tick log reads `answer_state: never_asked` — the honest
absence, not a claim that nobody answered.

**The cost is stated**: `decision-maturity.sh` composes `survey-strategies.sh`, so reading it
costs one more survey on a tick that was about to report `no_evolutionary_move`. That is the rare
path by construction, and paying for it there rather than on every tick is why the read sits at
the refusal rather than at step 1.

**The reader is NAMED here rather than invoked, and a later reader must not "fix" that.** It
lives in another skill, and writing the `${CLAUDE_PLUGIN_ROOT}` invocation form resolves it into
**this** skill's script closure — which copies `moderate`, `standup` and `workaholify` wholesale
into every cross-agent bundle that carries `/propose`, and surfaces `workaholify`'s own
`../bootstrap/` reference as unresolved. `workaholic:drive` records the same restraint for its
own cross-skill reader, and `verify.mjs` is what catches a regression: **measured** here, the
invocation form broke six bundles with thirty unresolved references. The run has already resolved
`src`, so the bare path is unambiguous.

- **`no_feedback_refs` is the answer to the lossy reader.** `attributed-work.sh` walks
  `strategy.feedback[] ∩ artifact.feedback[]` plus one hop through a mission and admits it
  cannot see everything. A strategy citing **no** record can never have anything attributed
  back to it, so the judgment would be made on a blind read and every proposal would land
  invisible. Such a strategy is refused with the repair named. **`no_citing_artifacts` is not
  a refusal** — that is a strategy nothing has answered *yet*, which is exactly when a
  proposal is most wanted. One means "no work yet"; the other means "no way to see work".

  **That sentence rests on a proof, not on prose** (2026-08-26, mission
  `prove-the-loop-s-closing-link`). It used to be ambiguous, and dangerously so: the reading
  also covered a direction whose answer *was* published with the carry-forward link dropped,
  and treating that as "not a refusal" made the loss self-perpetuating — the loop kept
  proposing against a direction it could no longer see its own work on. The hole is closed at
  the writing end (`workaholic:specificate`, *Carry the ask's own feedback refs forward*):
  the ask's line is read by a script, the carry is reported on both surfaces, and
  `check-carry-floor.sh` refuses a publish whose emitted artifact lost a **resolved** ref.
  The whole chain — ask → reader → scaffold → floor — is pinned by a hermetic test, so the
  guarantee is a fact that can be lost rather than a claim.

  **What it does not cover**, and must not be over-read: work a run never emitted, an ask
  that named no refs, a ref that did not resolve, and any artifact written by hand outside
  `/specificate`. Those are uncited for ordinary reasons, and the attribution stays
  transitive and lossy exactly as it was.

  **The bound widened on 2026-08-26 and its limits did not.** It now covers work emitted from
  an ask filed by `/propose`, by this routine's own **inbound sweep**, or by **`/fb`'s in-repo
  path** — the loop's three writers, each of which now stamps the `feedback:` line through one
  writer — and the chain test walks each header shape. Still outside it: work a run never
  emitted, an ask judged to answer no direction, a ref that did not resolve, an artifact
  written by hand, and a direction `/specificate` **judged** rather than read off a line,
  because the floor is keyed on the ask's own refs.

**A gate that cannot be read is not a gate**: if the open-proposal list cannot be fetched, the
whole tick refuses (`inbox_unreadable`) rather than proposing blind.

### Quiescent: a direction whose work is all in

`pace`, `overdue` and `dormant` all answer *is this direction in trouble*. None answers **has it
arrived**, so a direction that produced its work and has nothing left in flight is byte-identical
to one still running — and when its date passes, the loop reports that success as an hourly
`direction-overdue` question. Naming a success as a failure is the defect this reading removes.

`survey-strategies.sh` emits **`quiescent`** on every surveyed row, eligible and refused alike —
the refused case is the point, because a direction past its date is refused `past_target_date` and
would otherwise never show its arrival to anyone. It is `true` only when *all* of these hold, and
every one is already on the row — no new counter, no field on any artifact, no second derivation:

| Term | Meaning |
| ---- | ------- |
| not `unreadable` | the attribution could be read at all |
| `status == "active"`, `owns == "mine"` | a live direction of this identity's |
| `feedback_refs` non-empty | something the reader *could* have seen |
| `(.landed \| length) > 0` | **its answers are in** — the one term that separates it from `dormant` |
| `waiting_missions + waiting_count == 0` | nothing waiting at either grain |
| no open proposal | the last turn is not still sitting in the inbox |

**It is the complement of `dormant` on exactly one term** — `landed` empty versus non-empty — and
the two are mutually exclusive by construction. Nothing enforces that: deriving each from the row
independently is what keeps them from drifting.

**It carries no date term at all**, deliberately, unlike `dormant` (which is `false` once
`days_to_target < 0`). Arrival is independent of the date — a direction that finished late has
still finished — and that independence is why the projected lifecycle state ranks `arrived` above
`overdue` (`workaholic:strategy`). Folding a date term in here would make that projection
unreachable for the one case it exists to serve.

**And since 2026-08-28 one more term: the residue must have been *readable*.** `quiescent` is
`false` when the survey's `residue` read was degraded (mission
`say-what-the-direction-could-not-see-before-calling-it-arrived`). *Everything I could attribute
has landed* was true and partial, and nothing said which half — measured on this repository, a
strategy read `quiescent: true` with 125 landed items while **four active missions and ten queued
tickets** belonged to no direction at all. Claiming an arrival on a blind read sends the operator
to **close** a direction, while every other reading only asks them to **look**, so this is the one
reading refused when the tree could not be read (`workaholic:strategy`,
`strategy/scripts/unattributed-work.sh`). **A non-empty but successfully read residue leaves
`quiescent` exactly as it was** — an unattributed mission is not this direction's work, and
refusing on it would let any unrelated mission suppress every arrival forever. What a non-empty
residue earns is being **named**, in the question and in the run report.

#### Quiescent is evidence, never an origination gate

`quiescent` says attributed work landed and nothing attributable is waiting. It does not establish
that the strategy's Aim is achieved, so an active direction remains eligible when the actual gates
are clear. The run uses the evidence and declared stage to choose the next hypothesis: `観察中`
permits observation work and does not authorize the loop to rewrite the stage. `/moderate` still
asks the assignee whether an apparently arrived direction should close or change; that question is
the route to an operator decision, not a temporary machine stop.

The `arrived` refusal introduced on 2026-09-02 is retired. It prevented repeated low-value depth
missions, but it also turned an empty queue into a claim that an Aim was complete. Repetition is
now bounded by evidence, lineage, open-work and WIP checks instead of treating quiescence as a
verdict.

**And it names that strategy's residue beside it** (2026-08-28) — the unattributed mission slugs
and the counts, kept short. An `arrived` reading printed without its residue is the same partial
claim this mission removed from the question, so the evidence and its limit are read together. A
**degraded** residue read is reported as degraded and never as an empty one; a run that proposed
against no `quiescent` strategy reports no residue at all, because the residue is evidence beside
a reading and not a standing status line. Nothing is proposed, withheld, ordered or gated on it:
no gate expression, no sort, no `selected` and no token reads the residue, and `not_active`,
`not_mine`, `past_target_date`, `no_feedback_refs`, `work_waiting`, `open_proposal` and
`attribution_unreadable` are untouched.

**The gate that eventually holds is `not_active`, after a *person* closes the direction.** That is
the operator's act. `arrived` remains a candidate reading whose job is to raise the named
`/moderate` question and inform the next proposal.

### The run report names a degraded direction reading

(2026-08-29, mission `keep-the-closing-link-readable-as-the-corpus-grows`.) A tick that
surveyed a strategy whose attribution walk did not complete names that strategy and the
refusal the survey already emitted — **`attribution_unreadable`, never a second word** — in the
run report, in the same voice `pace` and `arrived` are named in (`reference/loop.md`, step 5).
Nothing else about the report moves: it never states a `pace`, a `dormant` or a `quiescent`
verdict for such a strategy, because the survey emits none, and no line may imply the tick
judged something it could not read.

**This ticket names; the survey brakes.** The actual gate is
`survey-strategies.sh`'s — a degraded row is refused and cannot be selected — and it is stated
where the refusal vocabulary lives, above. The report is read by nobody on the day it matters,
which is precisely why the brake is not here; and no question is added here either, because
reaching a person is `/moderate`'s job and belongs in its own ask if it is wanted.

### The declared stage rides on every row and gates nothing here

(2026-08-29, mission `make-a-direction-s-lifecycle-a-declared-stage`.) `survey-strategies.sh`
carries the direction's **declared** `stage` on every surveyed row, eligible and refused alike —
including rows refused by an independent ownership, date, lineage or work gate. It comes off
`list.sh`, which resolves the absent-means-進行中 default through `read.sh`, the one place that
default lives; a **degraded** row still carries it, because the degradation belongs to the
attribution walk and the stage is read off the artifact.

**Carrying it does not decide eligibility**: `refusal`, `pace`, `overdue`, `expiring`, `dormant`
and `quiescent` do not turn a declared stage into a stop. Stage guides the hypothesis: 観察中
permits observation work while leaving stage changes to the operator.

### 改良中 competes for attention — the stage joins the sort and nothing else

(2026-08-29, the same mission.) The ask's 改良中 carries one behaviour the other two do not:
its priority rises and falls **relative to the other active directions**, because the operator
runs several that reference each other and improve as a blend. The survey has exactly one seam
for that and no other — the **eligible order**, admitted on the ground that it is a proposal
about attention and never a gate, which is how `pace` was admitted — so the stage joins the
sort key and stops there.

**The whole ordering is stated in one place**, `survey-strategies.sh`'s own header, so no
consumer re-derives it: **改良中 first**, then **late first**, then **nearest date**. The
existing components keep their order beneath the new one.

**Why 改良中 rather than 進行中**, with the counter-argument recorded rather than dismissed:
work that cannot be cut over yet is the riskiest and might deserve attention first — it lost
because 改良中 is the stage the operator declared to mean *can absorb a proposal*, and a
blend's proposing energy belongs where it converts to shipped behaviour, while a direction
still building is advanced by the work already queued against it.

**It is a sort and not a gate**, which is what makes it cheap and reversible: `refused[]`, every
gate, the membership of `eligible[]` and `selected[]` and every reading are byte-identical, and
a repository whose directions all carry one stage — or none — produces the pre-change order
exactly. **No weight, no score, no tunable constant and no cross-direction arithmetic**: the key
is lexicographic over fields already on the row. Since `over_cap` was retired a tick proposes
against **every** eligible direction, so the order decides only which one a tick that dies
partway has advanced — which is precisely what bounds this change's blast radius. An explicit
operator-set numeric rank is refused: a rank is a second thing to keep current, and if it is
ever wanted it is a separate ask against a working ordering rather than a guess made now.

### 観察中 permits observation work

The `observing` refusal introduced with the declared stage on 2026-08-29 is retired. 観察中 says
which kind of learning the strategy needs; it does not say the strategy needs no further work.
When the remaining gates are clear, `/propose` may originate a bounded observation hypothesis and
must tie it to the Aim and existing evidence exactly as it would any other move.

The loop does not rewrite 観察中 to 進行中 or 改良中 on its own. A hypothesis that requires a
stage change identifies the operator decision instead of impersonating it, while reactive work
continues to reach the strategy unchanged.

### The run report names what is waiting on the operator

(2026-08-29, mission `follow-the-pull-requests-the-loop-opens-for-a-person`.) A tick names each
**un-acted operator-facing pull request** — the publications `publish-tree-pr.sh` refused to
auto-merge, where merging **is** the operator's ruling and closing **is** their refusal — with
its number, its age and the **refusal word** that made it the operator's (`ruling_touching` /
`strategy_touching`), read once through
`branching/scripts/list-operator-facing-pulls.sh` and `branching/scripts/publication-effect.sh`.
It is named in the same voice as `pace`, `overdue`, `expiring` and `arrived`: **evidence, never
a verdict**. A `merged` or `closed` reading is settled and is not named; an **`unreadable`** one
is named as unreadable by its reason, and never as *nothing waiting*.

**It gates nothing, and every gate is byte-identical across the change.** No `refusal`, no
`pace`, no `overdue`, no `dormant`, no `quiescent`, no sort and no `selected` reads it —
`survey-strategies.sh` is untouched — so `/propose` keeps proposing against a direction whose
ruling is unanswered, exactly as it did before this reading existed. It is a `/propose`-level
fact rather than a per-strategy one and rides no survey row. The person who must act is reached
by `/moderate`'s `operator-pull:<number>` question, for the reason the degraded-reading section
above records: this report is read by nobody on the day it matters, which is why nothing here is
ever a brake. Every value is a **judgement**
(`drive/reference/claims.md`, *Whether an operator-facing pull request was acted on*).

### The run report names how long a standing blocker has been standing

(2026-08-30, mission `say-how-long-the-loop-has-been-stuck`.) Every reading in this repository
was **instantaneous**: `late`, `overdue`, `dormant`, `arrived`, an un-acted ruling — each says
**what** is true and none said **how long**. A tick now names the age of the question about each
standing blocker it reports, read once through
`moderate/scripts/condition-age.sh --key <subject-key>`: `age.ticks` ticks since
`age.first_seen`, *at least* that when `age.first_seen_is_floor`.

It is named in the same voice as `pace`, `overdue`, `expiring` and `arrived`: **evidence, never
a verdict**. What it answers is the age of the **question**, which is a lower bound on the age
of the condition — a blocker that existed before anybody asked reads younger than it is — so the
report says *asked about since* and never asserts how long the subject itself has been stuck. A
subject nobody has been asked about yet reads `first_seen: null` and nothing is said about its
age: that is an ordinary absence, the first time anybody is being asked. A **`readable: false`**
reading is named **as unreadable, by its reason**, and never as *nothing standing*.

**It gates nothing, and every gate is byte-identical across the change.** No `refusal`, no
`pace`, no `overdue`, no `dormant`, no `quiescent`, no sort and no `selected` reads it —
`survey-strategies.sh` is untouched and never reaches the reader — so `/propose` proposes exactly
as it did before this reading existed. **It moves no token.** The tempting error is to brake on
an old blocker; the person who must act is reached by `/moderate`'s own questions
(`undrivable-unit`, `retire-blocked`, `undelivered-unit`, `stalled-unit`), for the reason the
degraded-reading section above records: this report is read by nobody on the day it matters,
which is why nothing here is ever a brake. Every value is a **judgement**
(`drive/reference/claims.md`, *How long a condition has been standing*).

## How the loop closes — and it closes with no new field

`open-proposal.sh` writes the issue's first three lines itself, and the third is the
load-bearing one:

```
kind: instruction / source: development / subject: observer_ai:[Propose] routine
strategy: <slug> / move: <depth|breadth|contraction>
feedback: <ref>, <ref>
```

Line 3 names the **strategy's own** `feedback:` refs, and `/specificate` carries them onto the
mission or ticket it emits, beside the record that run writes
(`workaholic:specificate`, *Carry the ask's own feedback refs forward*). Without it the emitted
work would cite only the new record, the intersection would be empty, and the loop would turn
leaving no trace on the direction that asked for it. It uses the existing **many-valued**
`feedback:` relation exactly as designed and **adds no field to any artifact**, which is what
keeps the retired `strategy:` mission relation and its ownership hop retired.

All three lines are **visible text, never an HTML comment**: a hidden marker would be a fact
the loop depends on that no human reading the issue can see.

## Scripts

```bash
# Which strategies may be proposed against this tick, and why each other one may not.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/survey-strategies.sh \
  [--open-proposals <file>] [window] [.workaholic-root]

# The open proposals already in flight, per strategy — the remote half of the brake.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-open-proposals.sh

# The ONE writer, and its only write is a GitHub issue.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/open-proposal.sh \
  --strategy <slug> --move depth|breadth|contraction --title "<title>" <body-file>
#   body sections: What to change / Why this commits to the strategy /
#                  What this is chosen against / Experience / Tickets (one or more)

# The inbound sweep's dedup ledger and its ONE writer. BOTH ARE CALLED BY THE TICK, not by
# this command (`commands/infinite-development.md`); they live here because moving them would
# be churn for nothing.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-swept-slack-refs.sh
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/file-inbound-ask.sh \
  --slack-ref <channel>:<ts> --permalink <url> \
  --subject 'person:<name>' --assignee <login> <owner/name> "<title>" <body-file>
```

The run itself is five steps: [reference/loop.md](reference/loop.md) carries them, together
with the alternatives that were refused.

## Describing work does not gate a building aim

`attributed-work.sh` attributes work through `strategy.feedback[] ∩ artifact.feedback[]`, and **a
page about the work cites the same ref the work would** — so the two are indistinguishable by
construction. `work_waiting` reading that undifferentiated count is what made the measured loop
self-sustaining: each documentation mission queued documentation tickets, which kept the gate
closed against the proposal that might have been the build; when they merged the gate lifted and
the next documenting move was named.

**The kind is derived from the ticket's own paths** (2026-08-23, the ticket's Open Decision, ruled
while driving it). `strategy/scripts/work-kind.sh` reads each queued ticket's `## Key Files`:
every path under a documentation area → `describing`; any path outside them → `advancing`; no
section, no path, or an unreadable file → `unknown`. `attributed-work.sh` reports
`waiting_kind` / `waiting_describing` / `waiting_advancing` beside `waiting_count`, and
**`unknown` counts toward advancing at the gate** — mislabelling build work as descriptive lets
parallel proposals accumulate, the failure the gate exists to prevent, while the opposite error
delays one proposal by a tick.

Two shapes were refused. Carrying the proposal's `move` onto what `/specificate` emits can only
label work **the loop itself produced** — work a person filed stays indistinguishable, and that
residue is what the mechanism had to be chosen against — and it puts a field on the mission that
the 2026-08-17 no-new-field ruling refused. Dropping `work_waiting` for a build-aim strategy
outright removes its in-flight brake entirely.

**The stated cost, and why it is covered**: a repository whose product *is* documentation inverts
the heuristic. That is the same inversion `describing_move` exempts **by Aim**, and the same
exemption covers it here, because the distinction is consulted only for a building aim.

**The Aim stays a judgment, in the one place that already makes it.** No script can read an Aim and
say whether it is to build or to document; this run already makes that call for `describing_move`,
so it passes the answer to the survey (`survey-strategies.sh --aim-kind building|documentation`).
Absent the flag the gate is byte-for-byte what it was — `work_waiting` off the undifferentiated
count — so nothing changes for a caller that does not judge.

`attributed-work.sh` remains the **one** reader of attribution: `work-kind.sh` asks what a ticket
*is*, never whose strategy it belongs to, and reads no relation at all. The retired `strategy:`
relation does not return.
