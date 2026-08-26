---
name: propose
description: Use when a session runs `/propose` or the `[Propose]` routine's clock fires — read the running identity's own active strategies, judge the one evolutionary move that would bring the nearest one closer to its aim, and open that judgment as a GitHub issue the next `/specificate` tick will ingest. Defines the eligibility gates, the three moves, the refusal of housekeeping, and the scripts.
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

It reads the running identity's own `status: active` strategies, judges the single
**evolutionary move** that would bring the nearest one closer to its aim before its date, and
opens that judgment as a **GitHub issue assigned to that identity** — the one surface
`/specificate`'s unattended entrance actually reads.

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
`dev-<repo_name>` — the channel `workaholic:notify` already holds standing consent to read.
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
`record-answer.sh`, not to a new issue. When unsure whether a message is an ask, the standing
bar applies — this sweep captures, it does not originate, so *when unsure, skip and say what
made you unsure* costs one hour, not the ask.

**Each capture goes through one writer**: `file-inbound-ask.sh` stamps the three-axis header
(`source: slack` fixed; `subject` is the message author's — `person:<display name>`, never the
machine), the `slack-ref:` dedup marker and the message's permalink, then hands the body to
`feedback/scripts/open-issue.sh` — same title stamp, same `--assignee <running identity>`, same
REST transport as every other capture. The next `[Specificate]` tick ingests it like any
issue.

**Degradations are named, and the strategy flow never waits for them**: no Slack connector in
the session → `no_slack_transport`, sweep skipped and said; an unreadable channel →
`channel_unreadable` with the transport's own error; an unreadable issue ledger →
`sweep_dedup_unreadable`, and the sweep is **skipped** rather than run blind — filing against
an unreadable dedup is how the same ask arrives twice an hour. The run report names every
message filed (issue URL), every one excluded (reason), and every degradation. The sweep
happening or not never changes what the strategy half proposes.

**It is not the `/propose` this repository retired.** That name belonged to what is now
`/specificate` (renamed 2026-08-19), and `[Propose]` belonged to what is now `[Moderate]`.
Both were vacated in the same change and neither is claimed by any live template
(`reference/loop.md`, *Taking the name back*).

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
move would produce **documentation about that Aim**. The refusal is reported like every other
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
"rename for consistency" are `/moderate`'s job. What they have in common is that they are
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

Three of them carry the design:

- **`work_waiting` + `open_proposal` are one gate in two halves, and they hand off with no
  window** — from the issue opening until its `/specificate` pull request merges the issue is
  open; from that merge onward the tickets it produced are queued. So **one proposal per
  strategy is in flight at a time**, enforced continuously with no cursor and no stored state.
  A per-day bound was considered and refused: the ask is for three routines turning an
  **hourly** loop, and a daily cap on the only routine that originates work would cap the loop
  itself at one turn a day.
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

**A gate that cannot be read is not a gate**: if the open-proposal list cannot be fetched, the
whole tick refuses (`inbox_unreadable`) rather than proposing blind.

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

# The inbound sweep's dedup ledger: which channel messages are already an issue.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/list-swept-slack-refs.sh

# The inbound sweep's ONE writer: one FB-worthy message -> one [FB] issue.
bash ${CLAUDE_PLUGIN_ROOT}/skills/propose/scripts/file-inbound-ask.sh \
  --slack-ref <channel>:<ts> --permalink <url> \
  --subject 'person:<name>' --assignee <login> <owner/name> "<title>" <body-file>
```

The run itself is five steps: [reference/loop.md](reference/loop.md) carries them, together
with the clock placement, the name reclamation, and the alternatives that were refused.

## It posts nothing to Slack

**It reads Slack since 2026-08-23 — the inbound sweep above — and still posts nothing**: the
sweep consumes the channel and writes only issues. The distinction is load-bearing, because
the reasons below are all about *posting*.

The issue is assigned to exactly one person, who is the running identity, and GitHub already
delivers it to them. A Slack copy would be the same noise twice — the argument that gives
the retired `[Workaholic]` no connector — and a status line addressed to nobody is the noise that retired
`🔧 Needs a decision` and `📦 Release Preparation`. The routine's result reaches its one reader
as a **Claude notification** (`notifications: push`) — since `[Workaholic]` retired on 2026-08-22 (issue #557), the only template that declares the field.

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
