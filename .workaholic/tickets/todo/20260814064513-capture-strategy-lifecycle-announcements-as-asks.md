---
created_at: 2026-08-14T06:45:13+00:00
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
