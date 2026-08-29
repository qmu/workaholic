---
name: propose
description: Use when a session runs `/propose` or the `[Propose]` routine's clock fires — read the running identity's own active strategies, plan the one mission whose evolutionary move would bring the nearest one closer to its aim, and open that plan as a GitHub issue the next `/specificate` tick will ingest. Defines the mission grain, the eligibility gates, the three moves, the refusal of housekeeping, and the scripts.
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:strategy
metadata:
  internal: true
---

# Propose

The third turning routine. `[Specificate]` (`:15`) turns an ask into a record and the work it
warrants; `[Implement]` (`:30`) drives that work to a pull request; **`[Propose]` (`:40`)
supplies the ask** — so the loop turns without a person having to write the next ticket, and
what a person supplies instead is the **direction**.

It reads the running identity's own `status: active` strategies, plans the single **mission**
whose **evolutionary move** would bring the nearest one closer to its aim before its date, and
opens that plan as a **GitHub issue assigned to that identity** — the one surface
`/specificate`'s unattended entrance actually reads. The unit is a mission, not a change
(*The unit is a mission, not a change*, below).

**It is a pure reader of this repository.** No file, no commit, no branch, no pull request, no
merge, no deployment, and no `AskUserQuestion` at any step. Its only writes are issues, and
every one lands on GitHub, not in the tree — the same contract `/standup` and
`/prepare-release` hold, and the reason it adds no unattended-`main`-writer class.

## The inbound sweep — the channel is read, not mentioned

**Before the strategy judgment, the run sweeps the repository's designated Slack channel for
asks nobody addressed to any bot** (2026-08-23, the developer's instruction). The loop's two
inbound surfaces are now **GitHub issues** — which `[Specificate]`'s hourly discovery already
reads — and **the channel**, which this sweep converges onto that same issue surface. The
Claude Tag route (an ask captured only when a person wrote `@Claude`) is retired as a
dependency: it cost a tagged session per ask and stopped capturing entirely at the usage
limit, so an ask's arrival depended on a budget. This sweep reads the channel **as the running
identity through the Slack connector** — no mention required, no tagged session spent — and
files the same `[FB]` issue the tag produced, so the deliverable is unchanged and everything
downstream (`[Specificate]`'s ingestion, the record, the proposal) is untouched.

**The channel** is `WORKAHOLIC_INBOUND_SLACK_CHANNEL`, defaulting to the repository's own
name, `<repo_name>` — the channel `workaholic:notify` already holds standing consent to read
(the `dev-` prefix convention was retired 2026-08-28; no prefix is expected or required).
**A repository whose channel is named otherwise sets the variable**, which is the escape
hatch that retirement documented; this one sets it to `dev-workaholic` in its own
`.claude/settings.json` `env` block, because no `#workaholic` exists in the workspace. The
default derivation does not move and no routine prompt gains a repository name (P7).
**The window** is `WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS` (default 26): wider than the hourly
tick by a day so a missed tick drops nothing, and the dedup below is what makes the overlap
free. **This read is a bounded channel-history read, and it is the one place that has
one**: `workaholic:notify`'s no-history-read bound governs thread *lookups*, where history is a
guessing surface — here the history *is* the inbox, the developer instructed it read, and the
bound that replaces the lookup rule is the window plus the one designated channel. `/moderate`'s
Slack half keeps its two-query search bound unchanged; and unlike that step's record-writing
sweep, this one files **only the issue** — the `/fb` shape, chosen for the same measured reason
(`/fb`, *One artifact, two addresses*): a record written before its issue exists can never name
it, and would be re-discovered forever.

**What is FB-worthy is the feedback skill's own bar** (`workaholic:feedback`, *Whether this
merits filing*): a genuine ask, instruction, concern or must-not-miss item written by a
person. Three exclusions, each by shape rather than judgment: **the loop's own posts** (the
routine roots, replies and finish lines this plugin's skills emit — a machine's post is never
an opinion to capture); **messages a filed issue already names**, matched by the
`slack-ref: <channel>:<ts>` marker `list-swept-slack-refs.sh` reads back out of the issue
ledger; and **answers to the tick's own questions**, which belong to `/moderate`'s
`record-answer.sh`, not to a new issue **opened here** — since 2026-08-28 that sentence names a
path that exists: `/moderate`'s `question-answers` step reads the question's own thread, records
the answer through that writer, and files the ones that ask for work through this same
`file-inbound-ask.sh`, stamping the answer message's own `slack-ref` so the ledger this sweep
reads already names it. When unsure whether a message is an ask, the standing
bar applies — this sweep captures, it does not originate, so *when unsure, skip and say what
made you unsure* costs one hour, not the ask.

**Each capture goes through one writer**: `file-inbound-ask.sh` stamps the three-axis header
(`source: slack` fixed; `subject` is the message author's — `person:<display name>`, never the
machine), the `slack-ref:` dedup marker and the message's permalink, then hands the body to
`feedback/scripts/open-issue.sh` — same title stamp, same `--assignee <running identity>`, same
REST transport as every other capture. The next `[Specificate]` tick ingests it like any
issue.

**And it carries the direction the ask answers** (2026-08-26). Until then the sweep — the loop's
own writer and its majority inbound path — filed an issue with no `feedback:` line at all, so
work born on the channel intersected every strategy's `feedback[]` at nothing. Measured on this
repository the same day: a message became issue #604, `/specificate` emitted a five-ticket
mission from it, and `attributed-work.sh` still reported that strategy's `waiting_count: 0` — the
in-flight brake stood open over a whole queued mission.

**The judgment, in order.** A message naming an explicit strategy **slug** is attributed to it —
explicit slug only, the same rule the lifecycle recognition already holds, never a title and
never a paraphrase. A message naming none is judged against the `active` set read through
`strategy/scripts/list.sh`, the same read the strategy half already makes. A message that answers
no live direction is **`unattributed`** — an ordinary answer, never forced, because nothing is
refused for naming no direction.

**What rides the issue is the strategy's own refs**, passed as `file-inbound-ask.sh --feedback`
and emitted through `feedback/scripts/ask-feedback-line.sh`, the one writer of that line — never
a strategy slug, never a new field, so the retired `strategy:` relation stays retired. With no
direction the flag is absent and the composed body is byte-identical to what it was before the
flag existed.

**It is reported, not enforced.** Every filed issue's line in the run report carries
`direction:<slug>` or `direction:unattributed` beside its existing outcome — the judgment can be
wrong, and the only new obligation is that the loop say which direction it decided or that it
decided none. An **unreadable strategy set is named** (`strategy_list_unreadable`) rather than
collapsed into `unattributed`: reading nothing and finding nothing are different facts, and
blurring them is the invisible loss this whole change exists to remove.

**And every capture is acknowledged where it was written** (2026-08-26, the developer's
instruction). Filing an issue and leaving no trace on the message makes a captured ask and an
ignored one **byte-identical from the channel** — the person who wrote it cannot tell which
happened without going to look on GitHub. Measured the same day: the developer's 18:56 and
19:20 JST messages became issues #620 and #621 within the hour, and, seeing nothing in the
thread, they asked why neither had been treated as feedback. The capture had worked; only its
receipt was missing.

After `file-inbound-ask.sh` returns `ok: true`, the run posts **one reply into that message's
own thread** — the `📥 受理` shape in `workaholic:notify`'s catalog, carrying the issue link and
the session URL. It needs **no lookup**: the `slack-ref` the wrapper just wrote *is*
`<channel>:<ts>`, so the thread coordinate is the sweep's own input and the model's
two-query bound is never touched (`workaholic:notify`, *The inbound sweep's receipt*). A
message with no thread gets one rooted on itself, which is where a person reading that message
looks.

**And a reaction on the message itself, beside the reply** (2026-08-26). The reply closed half
the gap and left the other half open: a reply lives *inside* a thread, so from a channel scroll
a captured ask and an ignored one still look identical — a person has to open the thread to find
out which happened. The reaction is the same receipt at a glance, in the place someone scrolling
the channel is already looking. The emoji is named **once**, in `workaholic:notify`'s catalog
(*The inbound sweep's receipt*), so the skill, the routine template and the drift pin read one
source; it is the emoji the reply already speaks with, because one event keeps one vocabulary.

It is added **after** `file-inbound-ask.sh` returns `ok: true`, on the `slack-ref` that wrapper
just wrote — so, like the reply, **no lookup, no search and no second query**. It is a **second
signal for a second audience**, never a substitute: a reaction carries no link and is invisible
to anyone reading the issue rather than the channel, while the reply carries the issue URL and
is invisible to anyone scrolling past.

**Only a message this run filed, and never load-bearing.** An **already-swept** message gets
nothing — **neither reply nor reaction**; its receipt is on the issue that already exists, and a
second one an hour later is the hourly restatement this repository retires posts for; an
exclusion, a degradation and the strategy half of the tick post nothing at all. The issue is
open before either is attempted, so a reply or a reaction that fails is reported per message as
`ack_failed: <reason>` — one outcome each, so a landed reaction and a failed one are two facts —
and changes nothing about the filing, the dedup marker or what `/specificate` ingests. A capture
that landed and a receipt that did not are two facts and the run report states both.

**Degradations are named, and the strategy flow never waits for them**: no Slack connector in
the session → `no_slack_transport`, sweep skipped and said; an unreadable channel →
`channel_unreadable` with the transport's own error; an unreadable issue ledger →
`sweep_dedup_unreadable`, and the sweep is **skipped** rather than run blind — filing against
an unreadable dedup is how the same ask arrives twice an hour. The run report names every
message filed (issue URL **and** whether its receipt landed), every one excluded (reason), and
every degradation. The sweep happening or not never changes what the strategy half proposes.

**`channel_unreadable` never claims the channel is absent, and it names the channel it resolved**
(2026-08-29, mission `point-the-inbound-readers-at-the-channel-that-exists`). Slack answers *not
found* for a channel the calling token cannot **see**, so absent and invisible are one response —
the distinction `check-slack-channel.sh` exists to preserve. It is also distinct from *the channel
was read and held nothing*, which is an ordinary quiet window and is reported as one. Naming the
resolved channel in the report is what makes a divergence between the channel the loop posts to
and the one it reads legible without anyone re-deriving the default; the person who must act on a
persistent one is reached by `/moderate`'s `inbound-channel-unreadable:<channel>` question, asked
once, never by an hourly line here.

**It is not the `/propose` this repository retired.** That name belonged to what is now
`/specificate` (renamed 2026-08-19), and `[Propose]` belonged to what is now `[Moderate]`.
Both were vacated in the same change and neither is claimed by any live template
(`reference/loop.md`, *Taking the name back*).

## The unit is a mission, not a change

**One proposal plans one mission** (2026-08-26, the operator's ask). The issue names a mission
**title**, the **experience** it demands once it lands, and its **ordered ticket set** — held to
the ruled scale, roughly **7–8 tickets**, with a follow-up repair mission of 3–4 available and a
second concurrent mission refused (`workaholic:specificate`, *A strategy is not a mission
factory*). `/specificate` emits that plan rather than re-deriving one.

**The move vocabulary and every refusal built on it are unchanged; only the scale of the unit
they are declared over moves.** A move is now what the *mission* does to the Aim, and
`## What this is chosen against` names the rival **mission**, not the rival edit. The
anti-housekeeping effect is expected to come from the scale as much as from the refusals: a
mission-sized proposal cannot be "add a test" without saying so out loud.

**The body floor gains two sections and one count** (`open-proposal.sh`): `## Experience` and
`## Tickets` join the three below, and a `## Tickets` section naming fewer than **two** tickets
is refused `under_planned` with the alternative named — the discipline
`mission/scripts/check-floor.sh` already applies at the publish seam, applied here at the
proposing seam, because a proposal naming one unit of work is a plain ticket's worth of
direction. The **ceiling stays a judgement**: a floor is checkable and "roughly seven" is not,
and this floor has never graded a proposal.

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
`open_proposal` · `attribution_unreadable`

**`describing_move` is reported beside them and is not one of them.** Those eight are computed by
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

#### Quiescent changes no gate — and the reason is recorded so it is not changed by reflex

`quiescent` **lifts and closes no gate.** An arrived direction stays **eligible**; `refusal`,
`pace`, `overdue`, `dormant`, the sort and `selected` are byte-identical, and `/propose` keeps
proposing against it. What changes is only that the run report **says** it is doing so:
a tick that proposes against a `quiescent: true` strategy names `arrived` beside that proposal,
as evidence, in the same voice `pace` uses (`reference/loop.md`, step 5).

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
the operator's act, not a reading's — and the whole point of the reading is to *reach* that
person, not to pre-empt them.

**The obvious next request will be to gate on `arrived`, and it should be refused
deliberately rather than by accident.** Silencing the one routine that originates work on a
machine's guess is exactly what `pace` already refuses: `arrived` is a **candidate, not a
verdict** (a strategy's "Reached when" is prose no script reads, so nothing here can know the
aim was met — only that everything attributed has landed and nothing is queued), and a wrong
guess would stop the direction producing work while the operator was never asked. The reading's
job is to raise the question with a name on it — `/moderate`'s `direction-arrived:<slug>` — and
nothing else.

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
#                  What this is chosen against / Experience / Tickets (two or more)

# The inbound sweep's dedup ledger: which channel messages are already an issue.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-swept-slack-refs.sh

# The inbound sweep's ONE writer: one FB-worthy message -> one [FB] issue.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/file-inbound-ask.sh \
  --slack-ref <channel>:<ts> --permalink <url> \
  --subject 'person:<name>' --assignee <login> <owner/name> "<title>" <body-file>
```

The run itself is five steps: [reference/loop.md](reference/loop.md) carries them, together
with the clock placement, the name reclamation, and the alternatives that were refused.

## The one thing it posts to Slack, and everything it still does not

**It posts exactly one shape — the sweep's `📥 受理` receipt, with its reaction — and nothing
else** (2026-08-26).
It read Slack and posted nothing at all from 2026-08-23 until then; what changed is narrow and
the reasons that kept it silent are unchanged for everything else, so they are restated rather
than dropped.

**The proposal is still announced by nobody.** The issue is assigned to exactly one person, who
is the running identity, and GitHub already delivers it to them. A Slack copy would be the same
noise twice — the argument that gives the retired `[Workaholic]` no connector — and a status
line addressed to nobody is the noise that retired `🔧 Needs a decision` and `📦 Release
Preparation`. The routine's result reaches its one reader as a **Claude notification**
(`notifications: push`) — since `[Workaholic]` retired on 2026-08-22 (issue #557), the only
template that declares the field. Nothing about the strategy half posts, and neither does a
refusal, a degradation or an idle tick.

**Why the receipt is not that same noise, stated rather than assumed.** It is **addressed to the
one person who wrote the message**, in the thread they wrote it in, **exactly once**, and only
when this run captured something — it is a reply to a human, not a status line. The three
properties every retired post lacked are each present, and the failure it fixes was measured:
without it, a captured ask and an ignored one look identical from the channel.

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
