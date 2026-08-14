---
created_at: 2026-08-14T06:45:13+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: give-propose-a-strategy-artifact-form
merge_policy:
---

# Capture strategy lifecycle announcements as asks

## Overview

PROPOSED. The second half of the ask: once Strategy is a first-class `/propose`
artifact, a Slack message announcing that a strategy has been **created, changed or
ended** should be usable as the trigger and the content of an FB issue, the same way
Feedback/Mission/Ticket asks are today. The inbound path already exists end to end —
`/fb`'s crossing opens an `[FB] ` issue, `list-inbound-issues.sh` discovers it, and
`/propose` captures it — so what is missing is the *recognition*: an announcement
about an existing strategy must land on that strategy rather than read as a request
for new work.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` + `reference/workflow.md` — steps 5–7 (discovery, dedup, judgment) are where an announcement is recognised as being *about* an existing strategy.
- `plugins/workaholic/skills/strategy/scripts/list.sh` / `read.sh` / `close.sh` — the read side of the match and the only writer of an end state.
- `plugins/workaholic/skills/feedback/SKILL.md` — *Choosing the kind* decides whether an announcement is an `instruction` or an `insight`; a misfiled kind silences its own proposal.
- `plugins/workaholic/skills/feedback/reference/crossing.md` — the Slack-side ask reaches this repo as an issue through this path; check whether anything there needs to carry the strategy slug.
- `CLAUDE.md` (`/propose`, `/fb` rows) — the behaviour statement.

## Implementation Steps

1. Define what an announcement looks like as an ask: which of created / changed / ended it is, and the strategy it names. Decide how the strategy is identified (slug, title, or neither) and what happens when the named strategy does not exist — the honest outcome there is record-only with the reason, never a guessed match.
2. Add the read step: `strategy/scripts/list.sh` before the judgment, so an announcement can be matched against the actual set instead of a remembered one.
3. Route each of the three announcement kinds to its outcome — *ended* reaches `close.sh` (the only sanctioned writer of an end state), *changed* and *created* reach the form chosen in the first ticket. Every write still lands inside the publish tree and behind the one proposal PR.
4. Keep the one-way citation link intact: a strategy may cite the feedback records that formed it; no feedback record ever points at a strategy.
5. Update `CLAUDE.md` and the runbook in the same commit; regenerate `outputs/` and run the local verification set.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- An ask announcing a strategy ended lands on that strategy's `status` through `close.sh`, and on nothing else.
- An announcement naming a strategy that does not exist produces record-only with the reason named, never a guessed match.
- No feedback record gains a pointer to a strategy; the citation stays strategy → feedback.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && git diff --exit-code outputs/`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The three commands above pass, and the first ticket in this mission has landed (this one depends on the form it defines).

## Considerations

- Depends on the first ticket: without the strategy form there is nothing for a *created* or *changed* announcement to produce. Drive them in order.
- The Slack half of the ask lives outside this repository — Claude Tag decides what it files as an FB issue. What is in scope here is everything from the issue inward; say so rather than implying the whole chain is delivered.
- Matching an announcement to a strategy by title is a similarity match, and the notify skill already refuses similarity matching for threads for the same reason. Prefer an explicit slug and treat its absence as unmatched.

## Final Report

Development completed as planned.

### What the recognition rule ended up being

An announcement is identified by an **explicit slug and nothing else** — the same
refusal `workaholic:notify` makes for reply threads, for the same reason: a similarity
match that is wrong is silent, and it would attach a lifecycle event to a direction
nobody meant. The set is read through `strategy/scripts/list.sh` at a new step 5b, so
the match runs against the actual set rather than a remembered one; an absent slug is
record-only with `strategy_not_found` and the slug reported.

The three kinds route to three different outcomes, and one of them is deliberately a
non-write:

- **ended** → `close.sh <slug> achieved|abandoned`, the only sanctioned writer of an end
  state, and the only thing the run writes. An *ended* ask that does not say which end
  state is `no_end_state`, record-only — the two are not interchangeable and this
  session may not pick between them.
- **created** → the strategy form from the first ticket, on its own unchanged three-part
  bar. An announcement is not an exemption from it.
- **changed** → record-only, `strategy_exists_no_update_writer`. This is the decision
  worth naming: the ticket's step 3 says *changed* "reaches the form chosen in the first
  ticket", but `create.sh` refuses `exists`, and the artifact has exactly **two** writers
  by design (`create.sh` creates, `close.sh` ends). Adding a third that edits a live
  strategy's Aim, Schedule or Assignee would give the loop the power to rewrite the
  operator's standing decision — strictly worse than drafting a new one, which at least
  waits for a merge. The change is captured in the record and applied by the operator.

The auto-merge exemption from the first ticket was **generalised from "the strategy form"
to "any proposal that wrote under `.workaholic/strategies/`"**, so a close is held for the
operator's merge exactly as a create is. Ending a direction is as much the operator's act
as starting one.

### Scope stated rather than implied

The Slack half of the chain is outside this repository — Claude Tag decides what it files
as an FB issue. What landed here is everything from the issue inward, plus one addition on
the outbound side: `feedback/reference/crossing.md` now requires an announcement composed
for another repository to carry that strategy's slug verbatim, since the receiving
`/propose` cannot match anything else.

### Discovered Insights

- **Insight**: `close.sh` writes the strategy file **and** the OKF indexes
  (`okf/scripts/refresh-index.sh`, best-effort, same as `create.sh`). "Lands on that
  strategy's status and on nothing else" is true of the artifact set, not of the file
  set — a test asserting a single-file diff would fail on the index refresh.
  **Context**: every knowledge writer in this repo has that same tail, so the same
  caveat applies to any similar assertion elsewhere.
- **Insight**: adding `workaholic:strategy` to `propose/SKILL.md`'s `skills:` list pulled
  `strategy/scripts/*` into every generated bundle that transitively carries propose
  (`outputs/workflows/skills/drive/strategy/`, `.../create-ticket/strategy/`) — eight new
  files from one frontmatter line. **Context**: `build.mjs` resolves the script closure
  transitively, so a skill reference is a bundle-size decision as well as a preload one;
  the new files are untracked until committed and therefore invisible to
  `git diff --stat`, which is what makes the `Outputs Freshness` CI the real check.
