---
created_at: 2026-08-17T11:37:53+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817113750-add-the-housekeep-command-and-skill.md
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff: 
---

# Implement the strategy proposal step

## Overview

Step 8 of the ask, and the one that reverses a standing decision rather than extending one:
auto-propose missions and tickets **for the strategy** — expansion directions and
cleanup/consolidation directions both, so the repository keeps an active metabolism without
losing consistency — creating the FB, mission, ticket, pull request and Slack thread, and
mentioning from Slack marked `:large_yellow_circle: Proposing` instead of
`:large_blue_circle: Proposed`. Not every tick does it; it waits up to about a week for
reactions to what it already proposed. Negative feedback is recorded as a decline in the
repository, including the process leading to it, and the pull request is closed as part of
the lifecycle.

Three things in that paragraph collide with live contracts. Each is called out below rather
than quietly resolved — the whole step is buildable, but not by a session inferring which
side of each collision the operator meant.

## Policies

- `workaholic:planning` / `policies/scoping.md` — what may originate a unit of work
- `workaholic:operation` / `policies/observability.md` — a proposal nobody asked for must be visibly attributable
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md`, *The judgment bar* — the contract this step
  reverses: "**Missions, the queue, and commits are constraints, never triggers**", and
  feedback is the only input that can originate a proposal.
- `plugins/workaholic/skills/propose/reference/workflow.md` — the run this step would either
  reuse or fork.
- `plugins/workaholic/skills/strategy/scripts/list.sh` / `create.sh` / `close.sh` — the
  strategy artifact and its **exactly two writers**. Nothing edits a live strategy.
- `plugins/workaholic/skills/notify/SKILL.md`, *The prompt is the ceiling* and the post-shape
  catalog — the 🟡 collision below.
- `plugins/workaholic/skills/feedback/scripts/create.sh` — the decline record's writer;
  resolution is a **new** record naming the old via `supersedes`, never an edit.

## Implementation Steps

1. Resolve the three Open Decisions. Nothing below is safe to build before they are ruled.
2. Implement the candidate generator: read the strategy set (`list.sh`), the repository
   state, and produce candidate directions in **both** flavours the ask names — expansion
   and cleanup/consolidation. Cap the number per tick.
3. Reuse `/propose`'s emission machinery (publish tree → record → scaffold → one pull
   request) rather than a second implementation of it; what differs is the *trigger*, and
   only the trigger.
4. Implement the cadence gate: at most one strategy-driven proposal in flight per strategy,
   and no new one while an earlier one is inside its reaction window (~1 week). The window
   is state; derive it from the open pull request's age, not from a stored cursor — the
   repository is the coordination medium.
5. Implement the decline lifecycle: on negative feedback, write a `kind: concern` or
   superseding record capturing the decision **and the reasoning that led to it**, then
   close the pull request. Recognising "negative feedback" from a Slack reaction or reply is
   itself a judgment; state its rule explicitly or require an explicit token.
6. Post the proposal's Slack message in the shape the ruling in Open Decision 2 settles.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No strategy-driven proposal is emitted while an earlier one for the same strategy is
  inside its reaction window.
- A declined proposal leaves a record naming the reason and a closed pull request — never a
  closed pull request alone.
- The Slack shape used is one the routine's own prompt names.
- The step is a clean no-op when the strategy set is empty.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A dry run against the current repository (zero strategies): the step reports
  `no_strategies` and writes nothing.
- Two consecutive ticks with one open proposal: the second emits nothing.

**Gate** — what must pass before approval:

- All three Open Decisions resolved and recorded in the Final Report.

## Open Decisions

1. **This reverses the propose bar; how far?** `workaholic:propose` states that the
   repository's own state can only *shrink or veto* a proposal, never originate one, and the
   retired `[Propose Batch]` routine was exactly the sweep this step reintroduces — its
   recorded failure mode was "a channel full of plausible noise". A strategy is arguably a
   better trigger than a backlog sweep: it is bounded, owned and dated, and it is the
   operator's own resolved direction. Decide (a) strategies become a second legitimate
   originator, stated in the propose skill so there is one bar and not two; (b) the step is
   built inside `/housekeep` with its own narrower bar; or (c) the step is dropped. Do not
   build it while the propose skill still says the opposite.
2. **`:large_yellow_circle: Proposing` collides twice.** 🟡 is the **handoff** finish line
   today, and the `📐 Proposing` *start* post was retired by the developer's order on
   2026-08-11 ("a routine posts its finish only"). The ask reintroduces a start-shaped post
   and gives it an emoji already in use. Decide the emoji and whether a start post returns —
   and note that *The prompt is the ceiling* means the shape must be named in the routine's
   own prompt before any session may emit it, no matter what this ticket documents.
3. **What counts as "negative feedback"?** The lifecycle hinges on it. A ❌ reaction, a
   reply containing a token, a closed pull request by a human, or a model's reading of a
   Slack thread are four very different triggers with four different false-positive rates.
   An auto-close driven by a misread reply destroys a proposal nobody rejected.

## Considerations

- **The repository currently holds zero strategies**, so this step is a no-op on day one.
  That is an argument for building it last, and an argument for making its empty-set
  behaviour explicit rather than incidental.
- "Wait up to about a week" is the only soft number in the ask. Make it a named constant in
  one place so the operator can change it without reading the implementation.
- A proposal nobody asked for is the highest-risk output in this mission: the loop's trust
  rests on `/propose`'s false-positive cost being near zero. Prefer emitting less.

## Final Report

**Step 8 is deliberately left unbuilt, and the step says so in every report.** That is not a
failure to implement it — it is the mission's own acceptance criterion carried out: *every step
reversing a standing decision is ruled on by the operator or left unbuilt, never inferred.* No
operator was present in this run, so the alternative the criterion names is the one taken. What
shipped is the gate: `step-strategy-proposals.sh` reads the strategy set, emits **nothing**, and
names the three outstanding rulings in its output — `no_strategies` today (the repository holds
zero), `blocked` / `awaiting_operator_ruling` the moment one exists.

The three Open Decisions, each recorded rather than resolved:

1. **How far does this reverse the propose bar?** Not resolved here. The argument in favour is
   real and is written down for the operator instead of acted on: `propose`'s bar exists because
   the *repository's own state* — missions, queue, commits — produces plausible noise when swept
   (the retired `[Propose Batch]`, and its recorded failure mode). A **strategy is not repository
   state**: it is the operator's own resolved, dated, owned direction, which sits far closer to
   feedback than to a backlog sweep. If the operator accepts it, option (a) is the coherent form —
   state it in `workaholic:propose` as a second originator so there is one bar and not two.
   Accepting it is their act, and the propose skill is left byte-identical; a test now asserts the
   bar's wording is unchanged, so a later session cannot slip the reversal in sideways.
2. **The Slack shape.** Not resolved here, and it could not take effect if it were:
   `workaholic:notify`'s *the prompt is the ceiling* means no session may emit a shape the
   routine's own prompt does not name, so a shape settled in this ticket alone would be inert.
   Recorded for the ruling: `🟡` is the handoff finish line today and the start post was retired
   on 2026-08-11 ("a routine posts its finish only"), so the ask's `🟡 Proposing` collides twice
   and needs two separate rulings — whether a start post returns, and which emoji.
3. **What counts as "negative feedback"?** Not resolved. Recorded with a recommendation: of the
   four candidate triggers (a reaction, a token in a reply, a human closing the pull request, a
   model's reading of a thread), an **explicit token** is the only one whose false-positive rate
   is a property of the *rule* rather than of the *reader* — and an auto-close on a misread reply
   destroys a proposal nobody rejected.

The quality gate's four acceptance criteria hold vacuously and by construction: the step emits no
proposal at all, so it cannot emit one inside a reaction window, cannot leave a closed pull
request without a record, and cannot post an unnamed Slack shape. The fourth — "a clean no-op when
the strategy set is empty" — is implemented and tested directly.

### Discovered Insights

- **Insight**: A step whose specification reverses a standing decision has a *buildable* form that
  is neither "build it" nor "do nothing": build the gate, emit nothing, and name the rulings in
  the machine-readable output so every tick's report carries them to whoever reads it.
  **Context**: The alternative failure modes are both bad — inferring the ruling puts an
  unauthorised reversal into an hourly unattended routine, and leaving the step absent loses the
  fact that a decision is pending. The gate makes "waiting on a human" a first-class, reported
  state, which is the same move `verification_handoff` makes for a unit.

- **Insight**: `workaholic:notify`'s *the prompt is the ceiling* makes some documentation
  decisions inert on their own — a post shape must be named in the **routine's own prompt** before
  any session may emit it.
  **Context**: This is why Open Decision 2 could not be usefully "resolved" in this ticket even in
  principle: the ruling has to land in the routine template's prompt, which is a different file
  and a different ticket, and a shape written only into a skill would never reach the wire.
