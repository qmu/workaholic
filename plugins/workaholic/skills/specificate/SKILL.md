---
name: specificate
description: Use when a session has an ask in hand — the [Specificate] routine's clock tick that discovers one (the open GitHub issues assigned to this identity), or /specificate by hand — to judge it against the conservative bar and emit, in one publish-tree pull request, the feedback record together with whatever the judgment warrants. Defines the clock-fired discovery, the judgment bar, the four forms a proposal takes, the proposal schema, and the scripts.
allowed-tools: Bash
user-invocable: false
skills:
  - workaholic:notify
  - workaholic:strategy
metadata:
  internal: true
---

# Specificate

The AI half of "humans supply feedback, the AI proposes missions" (`docs/loop-engineering-workflow.md` §6.3): a session with an ask in hand judges it and emits, in **one** pull request, the feedback record together with whatever the judgment warrants — a mission with its ticket set, one loose ticket, one strategy, or the record alone. Everything it proposes is `feedback:`-linked with `merge_policy` empty (reads as `review`), on a `work-*` branch whose pull request **merges immediately after it opens** (`WORKAHOLIC_AUTO_MERGE=1`; mission `auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split`, 2026-08-11, superseding K1's approval-by-merge for this flow): `main` is the continuously auto-merged development branch, and quality is gated downstream — the `release/*` QA window and the scoped QA/release-planning/post-release loops — not at merge time. **Two** things leave the PR open for a human: a release-scan finding, and a proposal carrying a **strategy** (*The strategy form*, below — the operator's merge is what authors that artifact, so it is never machine-merged).

## Propose at the capture seam

The judgment happens in the session that receives the ask (developer's ruling, 2026-08-04, superseding a batch sweep over merged `main` — that proposer could not see the record its own capture session had just written, so a second seat, a cron cadence and a shared cursor existed only to compensate; `docs/proposal-loop-runbook.md`). The capture session holds what no later reader can recover: the reporter's words, the thread they arrived in, and the record it just wrote. The inputs keep their asymmetry: the **ask in hand** originates a proposal, while the repository's own state — what is planned, queued, and recently built, read from the base (`survey-state.sh`, `list-proposed-refs.sh`), never from the caller's imagination — can only shrink one or veto it. The relation direction is **artifact → feedback**: a proposal records its source records in its own `feedback:` frontmatter list; nothing is ever stored on the feedback side, so the stream stays immutable and dedup reads the artifacts.

## Clock-fired discovery

Since `[Specificate]` fires on an hourly schedule rather than a GitHub issue trigger (FB
`20260810085032`), no event hands the session an issue — so a run that starts with
nothing in hand **discovers its own asks** before conceding `nothing_in_hand`
(developer's instruction, 2026-08-12, closing the gap the schedule migration left
open): `list-inbound-issues.sh` lists the open GitHub issues on this repository
**assigned to the session's own identity**, excludes any a feedback record already
names (`already_captured` — reported, never silently dropped), and hands back the rest
oldest-first. Each returned issue is an ask in hand exactly as if the retired trigger
had delivered it: run the full workflow per issue — its own record, its own judgment,
its own pull request with `Closes #<N>` — one at a time.

The inbox is read through **REST** (`gather/scripts/gh-rest.sh` → `gh api
repos/{owner}/{repo}/issues`), never through `gh issue list` (2026-08-12, FB
`20260812172522`). That subcommand is GraphQL-backed, and a Claude Code Web session is
not guaranteed to serve that surface: measured HTTP 403 "only the pinned set of
PR-review operations is served" in this repository's own tick, 80 minutes after the same
path had worked — the capability is a property of the **session**, so a run must degrade
rather than stop. Two consequences of the REST endpoint are handled deliberately and
must not be undone: it returns pull requests alongside issues (rows carrying
`.pull_request` are dropped, or a routine would propose against its own PRs), and it
paginates where `--limit` truncated (`per_page` carries the cap, so a single page
reproduces the old ceiling).

Three boundaries keep this from becoming the retired `[Propose Batch]` sweep:

- **It reads the inbound ask channel, never the repository's own state.** Issues are
  what people (and `/fb`'s cross-repository mode) open *at* this repository — the same
  input the retired event trigger delivered one at a time. Missions, the queue, and
  commits stay constraints (*The judgment bar*); nothing here reads them for something
  to propose.
- **Assigned to me only, never unassigned** — every developer's copy fires hourly, so
  an unassigned issue offered to every copy would have N runners race for it (the
  measured failure P8 records). An unassigned issue still reaches `/specificate` by hand
  (`/specificate #<N>`), where a human chose the one session that acts. The server-side
  filter also makes `not_mine` impossible on this path by construction.
- **No title filter**, and the reason is the *inbound* mix, not our own outbound shape.
  Issues arrive here from humans typing into the GitHub UI and from other tools, neither
  of which will ever carry an `[FB]`-style prefix — measured 2026-08-12, only 1 of the 9
  issues filed directly by a human carried one — so filtering on the title would drop
  exactly the asks this loop exists to ingest. (This boundary once rested on `/fb`'s
  crossing adding no prefix of its own; since issue #411 it stamps `[FB] `
  — `feedback/scripts/fb-title.sh` — which changes nothing here, because the crossing
  was never the only sender.) Assignment is the routing signal; the title is prose.

An unreadable inbox is reported, never rendered as an empty one: `ok: false` carries
its reason (`gh_unavailable` / `identity_unresolved` / `list_failed`) into the run's
report beside `nothing_in_hand`. For the exclusion to hold, the record each run writes
**must carry the issue's URL** (its `/issues/<N>` form) — the capture step's contract.

## Workflow

The run, in order — the step-by-step contract, with every script invocation, env-var
envelope, and abort reason, is [`reference/workflow.md`](reference/workflow.md):

1. **Take the ask in hand** — the command's argument, the record this session just
   wrote, or a record the caller named. **With none of those** — the clock-fired
   `[Specificate]` tick — **discover the inbound issues** (`list-inbound-issues.sh`; below,
   *Clock-fired discovery*): each open GitHub issue assigned to this session's own
   identity is an ask in hand, taken oldest-first, each through the full run. Still
   none → `nothing_in_hand`; an ask assigned to someone else → `not_mine` (*Act only
   on an ask that is yours*, below).
2. **Open the publish tree** and **register the record** inside it — written whatever
   the judgment concludes.
3. **Read the constraints** (`survey-state.sh`), **discover** the mechanism the ask
   names or reports a failure of (below, *Discovery before scaffolding*), and **dedup**
   (`list-proposed-refs.sh`) — all before scaffolding anything.
4. **Judge and decide the form** (below); scaffold the mission and/or tickets, stamp the
   acceptance links, and check the ticket floor.
5. **Publish everything as one pull request** (`publish-tree-pr.sh` under
   `WORKAHOLIC_PR_TITLE`, and `WORKAHOLIC_CLOSES_ISSUE` when step 1 captured a
   triggering issue number — its merge then auto-closes that issue), close the
   publish tree,
   **notify**, and **report** one line: the form chosen with its reason, the record's
   filename, **the carry** (what each emitted artifact carried, and every dropped ref with
   its reason), the PR URL, and the `notified` flag.

## Discovery before scaffolding

`/ticket` runs history/source/policy discovery before it writes anything (`workaholic:create-ticket`
§2); `/specificate` had none, which let a store-location fork `/ticket`'s §4b would have
interrogated a human on get silently inherited from a reporter's framing instead of
inspected (qmu/workaholic#374). Step 3 of `reference/workflow.md` closes that gap: for an
ask that names an existing mechanism or reports a failure of one, run at least a
history-mode pass (`workaholic:discover`'s Discover History) before judging the form —
**inline, in this session**: unlike `/ticket`'s three parallel discovery modes, which
fan out to `general-purpose` subagents because they run concurrently, a single
history-mode pass has nothing to fan out to, so it runs directly in the command's own
context (Architecture Policy already permits this — no subagent, no open question).
Carry the resulting `diagnosis_first` verdict into the emitted ticket's
Implementation Steps (`workaholic:discover`, *Diagnosis-First Rule*). Scoped to the ask in
hand — this is not a second sweep of the backlog (the retired `[Propose Batch]` design).

### Open decisions

`/ticket` resolves a genuinely unrecommendable fork by asking the developer directly
(§4b); `/specificate` cannot ask anyone. When discovery surfaces that kind of fork, record it
verbatim as an item in the emitted ticket's `## Open Decisions` section
(`create-ticket/reference/ticket-format.md`) instead of choosing for the reporter. Most
proposals carry none; write the section only when a fork this session cannot recommend one
side of actually surfaced — and only after the two rules below, both written on a measured
deadlock (2026-08-23, issue #83).

**The premise that the driving session resolves it was false, and it is retired.** This
section used to end *the driving session resolves it explicitly and records the resolution in
its Final Report*. The driving session is `/implement`, and `workaholic:drive` forbids both
moves it would need: **no `AskUserQuestion` anywhere, at any step**, and **the run never
overrides a gate**. So a fork written as a gate item is handed to a driver structurally
incapable of clearing it, and the only reachable outcomes are `blocked` and `handoff`, every
tick, forever. Each skill was internally consistent; the deadlock lived in the seam. Measured:
one unit resumed **nine consecutive times** over nine hours — nine claims, nine resume commits,
1.6 recorded agent-hours, zero lines of implementation, 0/3 acceptance.

**1. Check whether the operator already ruled, before declaring a fork operator-only.**
Step 5b already reads the strategy set before the judgment; read the operator's own records in
the same breath — an `status: active` strategy's Aim, and the `subject: person:` records it
cites (`feedback/scripts/list.sh`). **An operator direction found there is binding: cite it and
proceed.** A strategy is *the operator's outbound, resolved direction* by `workaholic:strategy`'s
own definition, and a proposal has no standing to reopen one. Measured: a run declared "may this
repository host implementation code" an operator-only fork on 2026-08-22 while the operator's
own words — `subject: person:`, `source: slack`, 2026-08-21 — said a merge to this repository's
`main` deploys the Worker, which *is* the answer; every later run copied the framing forward, so
one run's caution became a permanent stall. Note what that framing produced: the ticket
discounted the request contradicting it because *the ask came from `[Propose]`, not the
operator* — correct about `[Propose]`, and the operator's actual instruction was sitting unread
in the same feedback stream.

**1b. An item that survives must not certify itself.** Three required parts
(`create-ticket/reference/ticket-format.md`): **the question**, **the sources consulted and what
they said**, and **the fork's sides**. It may name whose ruling would settle it; it may **not**
state that the question is unanswerable, and it may **not** instruct a later session not to
decide. The history-mode discovery pass must have covered the item's own subject before the item
is written, and **the whole of any page the item cites must have been read** — the measured
failure was a partial read of one table, with the answer fifty lines further down the same page.
Carry what the pass found into the item: that is the "sources consulted" part, and it is what
turns the item from a ruling back into a question. The escape hatch is intact — a genuinely
unrecommendable fork is still recordable, with its sources named.

**2. An unresolved fork never enters `## Quality Gate`.** It is recorded in `## Open Decisions`,
where a human reads it, and the ticket declares **`verification_handoff: <the decision needed>`**
— the field that already routes the unit to the `handoff` route: the pull request opens and
stays open, the non-droppable `## Handoff` quotes the reason, the claim stays standing, and a
standing claim is not re-surveyed, so **the unit costs nothing per tick** instead of being
re-claimed hourly. A gate item, by contrast, is re-claimed and re-failed forever.

This does not soften `verification_handoff`'s standing rule that *a run never declares it for
its own unit*. The rule exists so a driver cannot excuse its own work; here the declarer is
`/specificate`, the **writer**, ruling at creation about a unit it will not drive — which is
exactly the case the field was written for, one axis over from a credential. The bar is
unchanged and it is high: the fork must have survived rule 1.

## The form follows the work's shape

The judgment decides cardinality before anything else, and there are exactly four answers:

| The direction | What the pull request carries |
| ------------- | ---------------------------- |
| Decomposes into **two or more** units of work | The record **plus a mission with its whole ordered ticket set** |
| Is **atomic** — one clearly actionable thing | The record **plus one loose backlog ticket**, no mission wrapper |
| Carries **a date and a named owner but no decomposable plan** — direction, not work | The record **plus one strategy** (`.workaholic/strategies/<slug>.md`), on a pull request that **does not auto-merge** |
| Is neither decomposable nor clearly actionable (vague, a wish, a direction nobody can start) | **The record alone**, with the reason it warranted no work reported |

- **The precedence is consulted first; the record-only default applies only to what it did not resolve** (2026-08-22). The four rows above are an **ordered** rule, and the judgment bar's *when unsure, record-only* sits **after** them, never over them. Uncertainty about **how** to decompose is not uncertainty about **whether** it decomposes: an ask naming two or more separately buildable things has already been answered by row 1, whatever the run still does not know about the order or the boundaries. Measured 2026-08-22: an ask naming a runtime, a database, an object store, an access layer, a language, build and test tooling, a framework, authentication and a protocol server — and asking, in so many words, that a strategy stop producing documents and start driving implementation — was judged record-only. Nine named components is decomposable by any reading; the default was reached before the rule that had already decided. **Report which rule decided**, every time: `precedence:<form>` when a row answered, `unsure:<what>` when the default did. A record-only outcome a reader cannot argue with is the failure this repository's *say which it is, every time* already forbids.
- **An ask that already names a mission is emitted as that mission** (2026-08-26). Since `/propose` proposes at the mission grain, its issue carries a mission **title**, the **experience** it demands and an **ordered ticket set**. Row 1 is already the answer; what this adds is that the run **does not re-decompose it** — it emits that plan, in that order, with the strategy's carried refs on it. Two sessions deciding the same decomposition is how the ask's plan and the emitted mission drift apart, and the operator would then be reading a roadmap that does not match the proposal they approved. The run keeps its judgment and gives up only the re-planning: it still judges the ask against the bar, and an ask it judges unbuildable is still record-only with its reason.
- **Every gate stays over the top of the named plan**, and none of them is waived by the ask having named it: the two-ticket floor still runs at the publish seam, the mission ceiling still bounds it (`## Acceptance` ≤3 items, ~60 lines / 2 KB), the carry floor still refuses a lost ref, and the `verification_handoff` and `## Open Decisions` rules are untouched. **A named plan that breaches a floor is reported by name and demoted** — to a loose ticket or record-only, exactly as an unnamed one would be — never silently trimmed to fit. `precedence:<form>` already requires the run to say which rule decided; a demotion says which floor refused.
- **Where the named plan meets *A strategy is not a mission factory*.** A mission-shaped ask against a strategy whose **active mission** still exists lands as **tickets into that mission**, not as a new mission beside it — the extend-before-mint rule below, unchanged. A new mission is minted only when the existing one is closed, or when its `## Experience` cannot honestly cover the work, and the run **reports which of the two it judged**. This is the seam where the coarser proposal and the anti-proliferation rule meet, so it is stated rather than left to be inferred: the ask names a mission, and the rule decides whether that plan becomes one.
- **Record-only is an outcome of the judgment, never of the mechanics**: the session can always see the record it wrote, so "no proposal" means "this ask warrants none" — a statement a reader can disagree with. Say which it is, every time.
- **A mission is never one ticket** — the ticket floor, checked at the publish seam (`mission/scripts/check-floor.sh <slug>`; non-zero exit means this candidate is not published as a mission — fall back to a loose ticket or record-only and report the script's `alternative`), not in `scaffold-draft.sh`, which runs before any ticket exists.
- A **loose ticket** lands in the flat `todo/` behind the same pull request, carries no `mission:` key — so `plan-units.sh` offers it as ordinary backlog, while a mission's tickets are excluded from the loose offer as `mission_member` and driven only in their mission's unit — and its `feedback:` refs are mandatory (`no_feedback`): with no mission to hold the relation they are the only record of what it answers, and without them a re-asked direction has nothing to collide with.
- Do not dress a decomposable direction as one loose ticket, or an atomic one as a mission, to get something published: both trade the artifact's honesty for a publication. Nothing here is claimable before the pull request merges, and everything is after.
- **A strategy is not a mission factory** (2026-08-24, the developer's ruling, measured on a
  consuming repository where one strategy had accumulated missions faster than anyone could
  read them). The intended scale of a strategy's plan is **one mission of roughly 7–8 tickets,
  extended by at most one follow-up mission of 3–4 repair tickets** — and the way row 1 honours
  that is by **extending before minting**: when the ask advances a strategy that already has an
  **active mission** attributed to it (`strategy/scripts/attributed-work.sh`, the one reader),
  the decomposition lands as **tickets into that mission** (each carrying the `mission:`
  relation, appended to its plan) rather than as a new mission beside it. A new mission is
  minted only when the existing one is closed, or when the ask opens work the existing
  mission's `## Experience` cannot honestly cover — and the run reports which of the two it
  judged, so the choice can be argued with. The numbers are a target, not a gate: nothing
  refuses a ninth ticket, but a second *concurrent* mission under one strategy is the smell
  this rule exists to stop.

### The strategy form, and the one rule it widens

A **strategy** (`workaholic:strategy`) is the operator's outbound, resolved direction: an **Aim**, a **Schedule** (`target_date`), an **Assignee** (non-empty `assignees`). Until 2026-08-14 it was flatly operator-authored — "no command, hook, or routine creates one on its own" (2026-08-13, issue #436). That rule is **widened by exactly one clause, and the clause carries its own price**: `/specificate` may **draft** a strategy into a proposal pull request, and **a proposal carrying a strategy never auto-merges**. The strategy file therefore still reaches `main` only when a human merges it — the operator's merge *is* the authorship, which is what "operator-authored" was protecting. `create.sh` remains the only writer of the file; nothing else about the artifact moves (`/drive` still never surveys it, the citation link still runs strategy → feedback only, and `close.sh` is still the only writer of an end state).

**Why the exemption is not optional.** The reading that `/specificate` could simply write a strategy like anything else rests on "the proposal only reaches `main` when the operator merges the PR, the same approval a mission gets" — and that premise stopped being true on 2026-08-11, when propose pull requests began auto-merging on open (`WORKAHOLIC_AUTO_MERGE=1`). Without the exemption, a machine's reading of an inbound ask would land on `main` as the operator's resolved decision with nobody having decided it, and `strategies/` would become a second inbound stream — the exact drift the artifact's definition exists to prevent ("two homes for direction only drift when both are inboxes; only one of these is"). With it, the strategy form is the one place a `/specificate` run deliberately declines to auto-merge, and it reports that as the form's own outcome, not as a failure.

**What selects it**, and the precedence against the other three — checked in this order, so a vague direction can never slide into a strategy:

1. **Decomposable into two or more units → mission.** A direction that *can* be planned is planned; a strategy carries no ticket plan and is never a way to avoid decomposing one.
2. **Atomic and clearly actionable → loose ticket.** One thing to do is work, not direction.
3. **A strategy needs an owner and an aim present in the ask, and a date it either states or takes from the default** — an **owner** (below) and an **aim with no decomposable plan**, both from the ask itself and **never** inferred; plus a **date**, which is the ask's own when it states one resolvable to a single `YYYY-MM-DD` and otherwise the **one-week default** (below). A missing owner or a missing aim → record-only, naming which part was missing.
4. **Otherwise → record-only.** Vagueness is still record-only, and stating "no owner" is a better report than a strategy nobody committed to.

**The owner question the artifact forces.** `create.sh` refuses empty `assignees` — the one artifact where empty is a refusal rather than team-owned — and `/specificate` may never substitute the running identity (*Act only on an ask that is yours*). The two rules meet exactly at an **unassigned issue**: it cannot produce a strategy. The outcome there is **record-only with `no_assignee` reported as the reason**, never a strategy owned by whichever container executed the tick.

**The date question, and the operator's ruling on it** (2026-08-30, mission `draft-a-dateless-direction-with-the-operator-s-one-week-default`). The `target_date` was read exactly as the owner is — a date the ask states, never one this session picks — so an ask with a direction and an owner but no date was `no_target_date`, record-only. **Measured 2026-08-30: three announced directions all died there**, their refusal traced only by a parenthetical addressed to nobody, while the loop kept planning from the directions that already existed. **The operator ruled the default: one week from the ask.** So an ask with an aim and an owner and **no date at all** now drafts the strategy on that default, derived in one place by `strategy/scripts/default-target-date.sh` and counted from the **triggering issue's own date** rather than from this tick's clock.

Taking a default here is admissible for one reason and it is the exemption's own: **the operator's merge is the authorship**, and the drafted strategy sits at a pull request that never auto-merges. Editing the date before merging is how they set their own, and closing it is the refusal — so the default is a proposal a person answers, never a decision a machine made. That is also why every surface carrying it **says on its face that the date is the default** (below): a merge is only an authorship if the person merging can see what they are being asked to author.

**`no_target_date` is narrowed, not deleted.** It now answers exactly one case: **the ask stated a date this run could not resolve to a single `YYYY-MM-DD`**. Defaulting over the operator's own words is the failure this must not introduce while removing the other one, so an unparseable stated date stays record-only naming that reason. An ask stating no date at all no longer reaches it.

**There is no floor and no ceiling on strategies**, unlike a mission's two-ticket floor, so the bar above is the only brake on a run emitting them indefinitely. Hold it literally — and note that the **owner** requirement is what still holds it now that the date does not: an unassigned or unmapped issue is record-only exactly as before, so a stray ask cannot mint a direction.

### Strategy lifecycle announcements

A second class of strategy-shaped ask does not propose a *new* direction: it **announces something about one that already exists** — that it was created, changed, or ended. These reach this repository the same way every other ask does (a Slack message becomes an `[FB] ` issue through `/fb`'s crossing, `list-inbound-issues.sh` discovers it, step 1 takes it in hand); what is added here is only the **recognition**, so an announcement lands on the strategy it names instead of reading as a request for new work. The Slack half of the chain lives outside this repository — what is in scope here is everything from the issue inward.

**An announcement is identified by an explicit slug, and by nothing else.** The ask must name the strategy's slug; a title, a paraphrase, or a "the deployment one" is **not** a match. This is the same refusal `workaholic:notify` makes for reply threads and for the same reason: a similarity match that is wrong is silent, and it would attach a lifecycle event to a direction nobody meant. Read the actual set before judging — `strategy/scripts/list.sh` (step 5b), never a remembered one — and when the named slug is absent from it, the outcome is **record-only with `strategy_not_found` and the slug reported**, never a guessed match and never a newly created strategy standing in for the missing one. An ask that names no slug at all is not an announcement; judge it as an ordinary ask through the four forms above.

| The announcement | What the run does |
| ---------------- | ----------------- |
| **ended** (achieved or abandoned, and the ask says which) | `strategy/scripts/close.sh <slug> achieved\|abandoned` inside the publish tree — the only sanctioned writer of an end state, and the **only** thing this run writes. No mission, no ticket, no second artifact. Then `strategy/scripts/closing-residue.sh <slug>` is read and **what the direction is leaving is named in the pull-request body and the run report** (2026-08-28): what it never reached, what no direction claimed, and its last lifecycle reading. That reading writes nothing, and a degraded one is named as degraded by its own reason rather than rendered as an empty leaving — it is evidence for the operator, never an assertion that closing was correct. |
| **ended**, but the ask does not say achieved or abandoned | Record-only, `no_end_state`. The two are not interchangeable and this session may not pick between them. |
| **created** — announcing a direction not in the set | The strategy form above, on its own three-part bar. An announcement is not an exemption from it. |
| **created as the successor of a named predecessor** — the ask names an explicit predecessor slug | The strategy form, unchanged in every part, **plus the predecessor's own `feedback:` refs carried onto the successor** (2026-08-28). Record-only under `strategy_not_found` (the named predecessor is in no set), `predecessor_active` (a live direction is not a predecessor) and `no_predecessor` (nothing explicit is named). |
**A 観察中 direction still receives inbound work** (2026-08-29, mission
`make-a-direction-s-lifecycle-a-declared-stage`). The declared stage gates **origination
only**: `/propose` is refused `observing` and opens no issue of its own for such a direction,
while an ask that arrives from outside — a swept channel message, an issue somebody filed, an
error reported — is judged, attributed and emitted here exactly as before. Nothing about this
route narrows for a settled direction, and that asymmetry is what the stage means.

| **changed** — the named slug is already in the set | `strategy/scripts/amend.sh <slug>` inside the publish tree, carrying exactly the revision the ask states (2026-08-27) — the **only** thing this run writes for it. Since 2026-08-29 a revision may name the declared **stage** (`--stage`, from the closed set), carried verbatim and judged by nobody here; a bad value is record-only `bad_stage`. Record-only under two reasons of its own: `not_active` when the named direction is closed, and `no_revision` when the ask names the slug but nothing revisable. |
| **answers** — the ask names a strategy slug **and** a mission slug, ruling that the mission answers that direction | `strategy/scripts/carry-attribution.sh <strategy> <mission>` inside the publish tree (2026-08-28) — appends that strategy's **own existing** `feedback:` refs to that mission and writes nothing else. Record-only under `strategy_not_found`, `mission_not_found`, `not_active` (a closed direction acquires no new work) and `no_revision` (the strategy cites nothing to carry); a re-run leaves the mission byte-identical and reports `already`. |

**`strategy_exists_no_update_writer` is retired, and the two-writer rule's premise survives it** (2026-08-27, mission `let-the-operator-revise-a-live-direction-through-the-loop`). That reason named an **absence** — there was no writer of a live direction — so an announced change was captured in the record and the operator applied it by hand on `main`, the one act in this repository that required a person to edit the base directly. `amend.sh` is the third writer and it is bounded to the three parts the model calls revisable; what it does **not** change is the reason the rule existed. The rule was written to stop a machine **authoring** the operator's direction, and it still does: a machine only ever **carries** a revision the operator announced by explicit slug, onto a pull request that never auto-merges. Matching is still by slug only; a run still never amends on its own reading of a direction; `close.sh` is still the only writer of an end state and `/drive` still never surveys a strategy.

**A direction may name its predecessor, and the carry is a citation rather than a relation** (2026-08-28, mission `make-a-direction-s-end-a-turn-of-the-loop-not-its-stop`). Closing the last live direction leaves the loop originating nothing — `/propose` refuses `not_active`, the inbox empties, and the only signal is `direction-none`, addressed to nobody — so a successor announced by the operator inherits the predecessor's **visibility** through the relation that already exists: the successor's `feedback:` refs include the predecessor's own, so `attributed-work.sh` reads the predecessor's landed work and its residue as the successor's from its first hour and `/propose` resumes on the next tick.

**It adds no field, no relation and no writer.** The refs are read through `strategy/scripts/read.sh` (the reader that already reads them), composed through `feedback/scripts/ask-feedback-line.sh` (still the one writer of a `feedback:` ref set), and handed to `create.sh` as the argument it has always taken — **`create.sh` is byte-identical and learns nothing about succession**, which is what the suite pins. The strategy artifact still has exactly three writers, the retired `strategy:` relation stays retired, and the successor's Aim, Schedule and Assignee stay the operator's own words: **only the citation is carried.** Matching is by **explicit predecessor slug only**, on the same grounds every other announcement uses, and the publish still does not auto-merge.

**The attribution carry is the same premise one artifact over** (2026-08-28, mission `say-what-the-direction-could-not-see-before-calling-it-arrived`). `unattributed-work.sh` names the active missions no direction claims; some of them answer a direction and were published with the carry-forward link dropped, and until this route the repair was a **hand edit of `main`** — the same act `amend.sh` was admitted to remove. A machine still only ever **carries** a ruling the operator announced by explicit slug: it never decides that a mission looks like it belongs somewhere, it appends refs that already exist on the named strategy, it removes none, it never touches the strategy file, and it adds **no field** and revives **no** `strategy:` relation.

**And its pull request does not auto-merge either — the seam's rule since 2026-08-28** (mission `put-the-loop-s-standing-rulings-on-one-pull-request`). This paragraph read *that is the caller's rule, not the seam's* on the ground that an attribution carry is byte-indistinguishable from any other mission write, and it turned out **not to be indistinguishable**: an ordinary proposal *adds* a mission, while a carry *modifies* one that already exists on the base and moves its `feedback:` line, which is exactly and only what `carry-attribution.sh` writes. `publish-tree-pr.sh` derives **`ruling_touching`** from that shape — and from any touch of `.claude/git-identities` — and reports `merged: false`, `merge_reason: ruling_touching` with the pull request left open, whatever `WORKAHOLIC_AUTO_MERGE` says. It is its **own** word rather than a widened `strategy_touching`: the two name different trees and ask the operator for different acts (authoring a direction versus ruling on an attribution), and one word answering two questions is how the two drift. Step 9e still leaves `WORKAHOLIC_AUTO_MERGE` unset and that assertion still stands, now as a second guard rather than the only one.

**A strategy-touching proposal never auto-merges** — revising one or closing one is the same act as drafting one, a machine moving the operator's own direction, so the exemption covers **any** proposal that writes under `.workaholic/strategies/`. **It is the seam's rule rather than the caller's since 2026-08-27**: `publish-tree-pr.sh` derives from the tree it is publishing whether any such path is touched and reports `merged: false`, `merge_reason: strategy_touching` with the pull request left open, whatever `WORKAHOLIC_AUTO_MERGE` says. Report it as the form's outcome, never as a merge failure. **And the citation stays one-way**: the record may be cited *by* a strategy through `create.sh`'s `feedback:` argument, and **no feedback record ever gains a pointer to a strategy** — not for an announcement, not for a close. What connects a close to its ask is the pull request that carries both.

**Record and proposal arrive as one pull request.** Everything is written into the publish tree (`.publish/` is an independent checkout, so an interactive caller's branch and uncommitted work are untouched) and landed with a single `branching/scripts/publish-tree-pr.sh` call — never straight to the base and never as two pull requests: the record and the work it warrants are one decision, and splitting them would let a reviewer accept half of it. The pull request's **title carries the `[Proposal]` prefix** (`[提案]` when Japanese) — load-bearing, not cosmetic: the `[Implement]` routine's GitHub trigger filters merged pull requests by `title contains [Proposal]`, so a dropped prefix opens a pull request whose merge starts nothing. Set it through `WORKAHOLIC_PR_TITLE`, never the commit subject — the two are different surfaces with different rules (`check-subject.sh` forbids a `[bracket]` prefix on a subject; conflating them made every publish die at `commit_failed`, P4). The body carries **no notification target** (Q1, 2026-08-07 — P4's carried-target propagation is retired and its P9 disclosure withdrawn with it): `/implement`, started by the pull request's merge, finds the item's thread itself through the stateless exact-token lookup in `workaholic:notify` (*One thread per feedback item*), and this session's own finish post finds it the same way — the key is the record's `fb:<stem>`, in hand on both sides. Never thread by similarity or recency; a lookup that matches nothing posts a new keyed root.

## Act only on an ask that is yours

When the ask arrives from a GitHub issue carrying an assignee, compare it against the session's own GitHub identity (`gh api user` — the credential the session already holds, never an env var); when they differ, report `{"proposed": 0, "reason": "not_mine"}` and stop (P8). An unassigned issue is anyone's, exactly as an unowned artifact is. The check lives in the command, never in the routine prompt: the routines UI offers no assignee filter, so every developer's `[Specificate]` fires on every assigned issue, and the dedup only sees proposals that already reached a branch. (`/implement` filters at its *survey* because its artifacts already carry `assignees`; `/specificate` filters at its *input* because it creates them — one rule, asked at the only place each command can ask it.)

"Who" enters once, at the trigger, and rides the artifacts from there (P6):

```bash
scaffold-draft.sh "<title>" --assignee <email> <feedback-record>...
scaffold-proposed-ticket.sh "<title>" <mission-slug> --assignee <email>
```

Both write `assignees: [<email>]`; both write an empty field when no assignee is given — team-owned, claimable by anyone, a real state that stays available. Do not fall back to the running identity: that stamps whichever container executed the batch and silently assigns work to a runner rather than a person (measured: every unowned proposal had every developer's runner racing for it, whose push landed first deciding whose job it was).

**Stamp only an address the loop can resolve** (2026-08-26). The issue carries a GitHub **login**; the artifact needs a git **address**; and until this rule nothing in the run converted one to the other, so the running session resolved it by *judgement*. Measured on this repository: the judgement produced a person's second address for the login `tamurayoshiya`, whose committed mapping names their first — and an artifact stamped that way is excluded from every survey, permanently, because `owns.sh` answers `other` for an address no entry names. The mission that would have repaired the other half of the defect was itself one of the seven stranded units.

So the assignee is resolved through **`gather/scripts/identity.sh`**, the mapping's one reader, before either scaffold is called:

| The issue's assignee | What the run stamps | What it reports |
| -------------------- | ------------------- | --------------- |
| a login the mapping names (by its canonical address **or** an alias) | `--assignee <the canonical address>` | nothing extra |
| a login **no entry names** | **no `--assignee` at all** — the artifact is team-owned | `assignee_unmapped: <the login>`, in the run report and the pull-request body |
| no assignee at all | no `--assignee` — team-owned | the existing unassigned wording |

**An unassigned issue and an unmapped assignee both produce team-owned work, and they are different facts.** The first is nobody's; the second is somebody's, unresolvably — and only the second is repaired by adding a line to `.claude/git-identities`, which is why they are reported under different names rather than folded into one. The refusal to substitute the running identity is untouched and applies here with the same force: a **wrong** address is silently unrecoverable, while `assignees: []` is a documented, claimable state any run can pick up.

The **strategy form** is the one place this does not produce team-owned work: `create.sh` refuses an empty assignee list — the one artifact where empty is a refusal rather than team-owned — so an unmapped assignee makes a strategy **record-only**, reported `assignee_unmapped`, exactly as an unassigned issue makes it record-only reported `no_assignee`.

## Carry the ask's own feedback refs forward

An ask whose body carries a `feedback: <ref>, <ref>` line names records that already exist in this repository's stream, and those refs ride the emitted artifacts **alongside** the record this run writes — step 3b of [reference/workflow.md](reference/workflow.md). Both scaffolds already take a variadic ref list, so this adds no flag, no field and no migration.

**The line is read by a script, not by eye** — `read-ask-feedback-refs.sh`, the single reader of the ask's own line, mirroring `read-feedback-relation.sh` on the artifact side. One relation, two surfaces, one reader each: the rule that reader's own header states is that two parsers of one field eventually disagree, and this line had no parser at all until then.

**It is what closes the improvement loop.** A `[Propose]` proposal (`workaholic:propose`) names the **strategy's** own refs on that line, because `attributed-work.sh` attributes work to a strategy through `strategy.feedback[] ∩ artifact.feedback[]`. Without the carry-forward, a mission proposed for a strategy would cite only the new record, the intersection would be empty, and the loop would turn leaving no trace on the direction that asked for it.

**And the carry is floored, not merely instructed.** Reading the line and reporting it still leaves the failure reachable — a run that reads the refs and forgets to pass them to a scaffold publishes a mission missing them, and the loss reaches `main`. `check-carry-floor.sh` is read at the publish seam beside the two-ticket floor: when the ask carried refs that **resolved** and the run emitted a mission or a loose ticket, those refs must be on what it emitted, or the seam refuses with the repair named. The floor is on the **emitted artifact** — the mission when there is one, the loose ticket when there is not; a mission's tickets need not repeat its refs, since `attributed-work.sh` reaches them through `via_mission:<slug>`. It checks a string in a file and never whether the work advances the direction, which stays a judgment.

**And the carry is reported, on both surfaces.** The obligation lives beside the carrying obligation because a turn that lost the link would otherwise report success on the turn that lost it: the **run report** names, per emitted artifact, what it carried (a count) and every ref it dropped (by name, with its reason), and the **pull-request body** carries the same two sets. A **record-only** outcome emits no artifact, so it reports the refs it *would* have carried and that nothing was emitted — without that clause a dropped link and an unproposed ask read alike in the report too. Both surfaces read `read-ask-feedback-refs.sh`'s output, never a re-read by eye. Keep it short: a per-artifact ref dump nobody reads is the noise this repository has twice retired status roots for.

**An ask that names no direction gets one judged, and the judgment is reported rather than floored** (2026-08-26). An ask can arrive with no `feedback:` line at all — a human typing into the GitHub UI, another tool, an older issue — and until then the run carried nothing and reported `carried:none`: honest about the *line* and silent about the *direction*. Step 5b already reads the `active` strategies and the records they cite, so deciding which Aim an ask falls under adds **no reader, no relation and no field**: an explicit slug wins outright, else the judgment against those Aims, else `unattributed`. A decided direction's own refs ride the emitted artifact through the same variadic scaffold arguments.

**A line beats a judgment**, so `/propose`'s path is byte-identical; a judged direction is weaker evidence and is reported with **how** it was decided (`line` / `slug` / `aim`), which is what lets a later reader tell a stamped attribution from an inferred one with no new field. **The carry floor is untouched and still keyed on the ask's own resolved refs** — flooring an inference would turn a reported reading into a publish refusal — and an unreadable strategy set stays named at step 5b rather than collapsing into `unattributed`.

**What the three together buy is a reading downstream.** After the floor, a proposal that emitted work from an ask whose refs resolved cannot have lost them — so `attributed-work.sh`'s `no_citing_artifacts` means *nothing has answered this direction yet*, and nothing else. That is why `workaholic:propose` may go on treating it as explicitly not a refusal. The chain — ask → reader → scaffold → floor — is pinned by a hermetic test in `scripts/test-workflow-scripts.mjs`, so the guarantee is a fact a change can lose rather than a claim in prose. **Its limits are part of it**: it says nothing about work a run never emitted, an ask that named no refs, a ref that did not resolve, or an artifact written by hand outside `/specificate`. Those stay uncited for ordinary reasons, and the attribution stays transitive and lossy. **The bound now covers all three of the loop's writers** (2026-08-26): work emitted from an ask filed by `/propose`, by the **inbound Slack sweep**, or by **`/fb`'s in-repo path**, whose refs resolved. It still does **not** cover work a run never emitted, an ask judged to answer **no** direction, a ref that did not resolve, or an artifact written by hand outside `/specificate` — and a **judged** direction is outside it too, because the floor is keyed on the ask's own refs. The chain test walks each writer's header shape rather than being copied per writer.

**The direction stays one-way**: this puts a *feedback* ref on a *mission*, the relation both artifacts already have. Nothing gains a pointer to a strategy, so the `strategy:` relation retired on 2026-07-28 and its ownership hop stay retired. A ref that does not resolve under `.workaholic/feedbacks/` is dropped and named in the pull-request body — never invented, and never a reason to refuse the proposal.

## Unattended — the defining constraint

- **No `AskUserQuestion`, ever.** A situation that would need a human is an abort with a machine-readable reason; an ask too vague to judge is record-only, its ambiguity reported in the pull request.
- **The record is written whatever the judgment concludes** — capture is not conditional on proposing.
- **A failed publish loses nothing**: the publish tree is disposable and the ask stays in its thread. The exception is `pr_failed` — the artifact **is** pushed, so open the pull request by hand; never re-publish, which duplicates it.

## The judgment bar

A model judgment with a conservative, written bar, stated per input:

- **Feedback is the only input that can *originate* a proposal** — typically `kind: instruction`, or a substantial `insight` naming concrete work; one mission may draw on several records. A lone `concern`, a `material`/`answer` record, or a purely informational note is never a trigger — concerns feed replans and planning sessions. The `kind` is decided at capture (`workaholic:feedback`, *Choosing the kind*), and at this seam the same session decides both, so a misclassified ask is a self-inflicted record-only; the correction is a superseding record, never a bar loose enough to read concerns.
- **Missions, the queue, and commits are constraints, never triggers** — they can only shrink or veto: a direction restating an existing mission's scope is record-only (a direction that *sharpens* one belongs in a replan, a human act); work already specified as a todo ticket is not proposed again; commits say what is done, never what should come next — "this area changed a lot" is exactly the pattern that fills a channel with plausible noise.
- **Discovery is a fourth input, and it can only inform or veto, never originate** (*Discovery before scaffolding*, above): a history-mode pass over a named mechanism can turn an apparently-atomic ask into a mission (the mechanism is more entangled than the ask implies), surface a duplicate that makes the ask record-only, or leave the judgment unchanged — it never manufactures a proposal feedback did not originate.
- **When unsure, record-only — and only after the precedence rule has failed to answer** (2026-08-22). Say what made you unsure. A false negative costs one reading (a human can run `/mission` from the merged record); a false positive publishes work nobody asked for and erodes trust in the loop. What this bar must never do is **overrule** *The form follows the work's shape*: it is the last resort for an ask the four rows did not resolve, not a veto over one they did. The two-ticket floor (`check-floor.sh`) is what makes leaning toward a plan safe — an under-supported mission is demoted mechanically at the publish seam, so the cost of trying is bounded and the cost of not trying is a loop that records asks instead of planning them.

## Draft missions

Scaffolded by `scaffold-draft.sh`, NOT `mission/scripts/create.sh` — that scaffold seeds the creator as owner, and an unattended proposer has no business owning what it proposes:

```yaml
type: Mission
status: active           # the one in-flight state — in flight, not history
merge_policy:            # empty — the approval records it, never this session
assignees: []            # unowned — claimable by anyone once merged
assignee:
feedback: [<record filenames>]   # the mission→feedback relation
```

What keeps the proposal out of an executor's reach is not a status word but the **pull request**: it is not on `main`, so no survey can see it. Fill `## Goal`/`## Experience` and a clearly provisional `## Acceptance` sketch in the same write (`hooks/validate-mission.sh` fires on any active mission). Approval is the merge of the one pull request carrying record and proposal; a thin sketch is interrogated to drive-ready by its reviewer via `/mission <instruction>`.

## Scripts

Full invocations with `${CLAUDE_PLUGIN_ROOT}` paths are in [`reference/workflow.md`](reference/workflow.md).

- **`survey-state.sh [since-commit] [base]`** — the constraints: `{missions, queue, commits, since, since_reason}`. Pure read; composes `mission/scripts/list.sh` and `drive/scripts/list-todo.sh` rather than parsing frontmatter itself. `since_reason` names how the commit window was chosen (`given` / `recent`, the last `WORKAHOLIC_PROPOSE_COMMIT_WINDOW` commits, default 20 / `unresolvable` / `none`) — a constraint that quietly became empty must not read like one that found nothing. Run it against the base (the publish tree, or a synced `main`).
- **`read-feedback-relation.sh <artifact-file>...`** — the single reader of `feedback:` lists (mirror of `mission/scripts/read-relation.sh`); takes missions or tickets, many at once. Every consumer goes through it — two parsers of one field eventually disagree, and the side that under-reads re-proposes answered feedback.
- **`read-ask-feedback-refs.sh [feedbacks-dir]`** (the ask's body on stdin) — the single reader of the **ask's own** `feedback:` line, the mirror of `read-feedback-relation.sh` on the artifact side. Emits `{line_found, carried, dropped: [{ref, reason}]}` and exits 0 in every case, including no line at all — the ordinary case for an ask a human typed, so it must not read as a failure. Only the first line-initial `feedback:` is read (an ask is prose, and the word recurs); the inline-list and bare-scalar forms normalise exactly as the artifact reader normalises them; a repeated ref is carried once. A ref that does not resolve is dropped with its reason (`not_found` / `unreadable` / `dir_missing` / `not_a_filename`), never invented and never rewritten. Pure read.
- **`list-proposed-refs.sh`** — the dedup set: the union of `feedback:` refs across every mission (active + archive) and every ticket (todo + archive) — the archive counts, since a driven ticket is the strongest evidence its feedback was acted on — **plus the same artifacts on unmerged remote branches**, via the claim protocol's own oracle, so an open proposal pull request counts as proposed (added 2026-08-05, after an ask proposed ten minutes earlier was proposed again). Deleting the branch is what frees the feedback again, and ambiguity resolves toward *including* a ref — a shallow clone over-reads and says so on stderr, because a duplicate proposal is loud and a suppressed one is quiet. At this seam the veto keys on the records the ask *restates* (the new record has no refs pointing at it yet); read the set before scaffolding, since what this session writes joins it immediately.
- **`scaffold-draft.sh "<title>" [--assignee <email>] <feedback-filename>...`** — writes the proposed `mission.md` (schema above; slug via `mission/scripts/slug.sh`), refreshes the OKF indexes, git-stages; refuses an existing slug. Emits `{created, slug, path}`.
- **`scaffold-proposed-ticket.sh "<title>" <mission-slug> | --loose --feedback <record>... [--assignee <email>] [--verification-handoff "<what cannot run here>"]`** — one ticket into the flat `todo/`; the mission form carries `mission: <slug>`, the loose form carries `feedback:` instead (refused `no_feedback` without refs); `merge_policy` left empty; **`--verification-handoff` passed only when the ask itself says the real-world verification cannot run where an unattended run executes** (a missing credential, device or third-party account) — the proposer may write this and not `merge_policy` because it records a fact the ask stated rather than granting a permission, and `/drive` then hands that unit to a person instead of merging it (`workaholic:drive` §6). Never inferred from a Quality Gate this batch wrote itself. the mandatory `## Policies`/`## Quality Gate` sections scaffolded so the artifact is valid at write. Emits `{created, path, slug, mission, feedback, loose}` or a `reason` (`no_title`/`no_mission`/`mission_missing`/`no_feedback`/`exists`). **Stamp the acceptance links after the set is written** — `mission/scripts/link-acceptance.sh <slug> <item-selector> <ticket-filename>` once per satisfied item, naming the pairing decided at decomposition, never inferring; an unsatisfied item stays unlinked and is named in the PR body (37 unlinked items across six proposed missions is the measured cost of skipping this).
- **`check-carry-floor.sh [--refs "<ref>,<ref>"] <artifact-path>...`** — the carry floor's verdict, read at step 9 beside `mission/scripts/check-floor.sh`: `{ok, checked, missing: [{artifact, ref}], reason, repair}`, exit 1 on a violation with the refusal on stderr, so a seam that ignores the JSON still fails. `checked` counts the (artifact, ref) pairs proved. Composes `read-feedback-relation.sh` rather than parsing frontmatter again — a second parser of one relation is exactly what that reader's header forbids. Nothing to check (`no_refs_carried` / `record_only`) is a real `ok: true`, not a degradation; a named artifact it cannot read is `artifact_unreadable`, never a silent pass. A refusal is a **run failure to report**, never a demotion to record-only.
- **`strategy/scripts/list.sh [--status <s>]`** — the strategy set, read at step 5b before any judgment that names a slug. Pure read, and it degrades to an empty list in a tree with no `strategies/` area; an empty set simply means every announcement is `strategy_not_found`.
- **`strategy/scripts/close.sh <slug> achieved|abandoned`** — the only writer of an end state, run **inside the publish tree** for an *ended* announcement. Refuses `no_slug` / `bad_status` / `not_found` / `already_ended`, and `reason: already` on a no-op re-close; each refusal falls back to record-only naming it. Re-opening is not offered by the script and is not worked around here — a direction being pursued again is a new strategy.
- **`strategy/scripts/create.sh "<title>" <YYYY-MM-DD> "<assignees>" "<schedule>" ["<feedback-refs>"]`** (Aim prose on stdin) — the strategy form's only writer, run **inside the publish tree**; never Write/Edit the file directly. Refuses `no_title` / `bad_target_date` / `no_assignees` / `empty_schedule` / `empty_aim` / `exists`, and every one of those refusals is a **fall back to record-only naming the refusal**, never a retry with an invented value. Its own floor is the same one `hooks/validate-strategy.sh` enforces at the write seam, so a strategy that `create.sh` wrote is valid by construction.
- **`branching/scripts/publish-tree-pr.sh <title> <why> <changes> <concerns> <insights> <verify>`** — one call, everything written; emits `{ok, sha, branch, pr_url, base}`; `pr_failed` still reports `branch` and `sha`. `WORKAHOLIC_CLOSES_ISSUE=<N>` threads a native `Closes #<N>` line into the body, so merging the pull request auto-closes the "[FB] ***" issue the ask came from — empty (the common case) emits no line. **`WORKAHOLIC_AUTO_MERGE` is left unset for the strategy form** — that is the whole mechanism of the exemption, not a separate flag.
- **`extract-issue-number.sh ["<argument>"]`** — the source for that env var: `CCR_TRIGGER_ISSUE_NUMBER` under a routine, else a `#<N>`/issue URL in the argument; emits `{"issue_number": "<N>"}` or `""`. Run at step 1, kept in hand through to step 10.
- **`list-inbound-issues.sh [feedbacks-dir]`** — the clock-fired discovery (*Clock-fired discovery*, above): the open GitHub issues assigned to the session's own identity, oldest-first, minus those a feedback record already names (each exclusion reported as `already_captured`); `WORKAHOLIC_PROPOSE_ISSUE_LIMIT` caps the page (default 20). Pure read, never load-bearing: a missing `gh` or a failed lookup is `{ok: false, reason, detail}` with exit 0 — an unreadable inbox is reported, never rendered as an empty one.

## Notifier contract

After a successful push the proposal message goes out on the transport `workaholic:notify` selects (*The transport*): the account's Slack connector where the session has one, and `notify-slack.sh "<text>"` as the machine fallback for a caller with no connector, which posts as the bot (`SLACK_BOT_TOKEN` + `WORKAHOLIC_SLACK_CHANNEL`; `WORKAHOLIC_SLACK_API_URL` overrides the endpoint for tests; the token is read at call time and never persisted or echoed) and here posts a **keyed root only** — it **cannot search**, so on this path, where the connector that runs the lookup is exactly what is absent, it has no thread coordinate to reply into. (Since 2026-08-31 it *can* reply into a thread somebody else resolved, via `--thread-ts`; that capability has no caller here, because a caller with no connector has no lookup — `workaholic:notify`, *The transport*.)

**How many messages go out is the lookup's answer, not the run's choice** (`workaholic:notify`, *One thread per feedback item*): a found thread takes **one** message, the `🔵 Proposed` finish line as a reply; case 4 — no thread found — takes **two** on the connector, the description root first and the finish line as a reply into it. The fallback posts one either way, because it cannot search — with no connector the lookup never ran, so no thread was ever resolved for it to reply into. **Never load-bearing**: a missing token/channel or an API failure is `{"notified": false, "reason": ...}` with exit 0 — a proposal that pushed is a success whether or not anyone was told; the report records `notified` per message rather than retrying, and an unposted message is reported as unposted, never as sent. Provisioning and failure modes are `docs/proposal-loop-runbook.md`.

## Agent Compatibility

This skill works on any Agent-Skills-compatible agent; all logic lives in the bundled POSIX scripts. The judgment bar is prose the running model applies — on any agent, attended or not, the no-prompt rule holds.
