---
created_at: 2026-09-02T04:26:30+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: resolve-a-conflicted-pull-request-in-the-tick-not-report-it
merge_policy:
verification_handoff: 
---

# Localize which step posted each of the three corrected lines

## Overview

PROPOSED. The operator corrected three behaviours by quoting what the channel said, not by
naming a step. One of the three — "the stuck-prs step" — is a name no step in
`workaholic:moderate` carries; the candidates are `catchup-blocked`,
`stranded-publications` and `stalled-units`, and which of them produced each line decides
what the rest of this mission edits.

This is the mission's diagnosis step and it changes no behaviour. Guessing here means the
next four tickets edit the wrong step and the operator sees the same posts again.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/reference/workflow.md` — the per-step specs; each
  step's question and event wording is composed here.
- `plugins/workaholic/skills/moderate/scripts/step-catchup-blocked.sh`,
  `step-stranded-publications.sh`, `step-stalled-units.sh` — the three candidates.
- `plugins/workaholic/skills/drive/scripts/claim-mergeability.sh` — the source of the
  `unanswerable` class the "GitHub has not computed mergeability" line reports.
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — carries the
  same class onto a publication row.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shapes the lines were
  emitted in; which shape carried each line narrows the step.

## Implementation Steps

1. Take the three quoted behaviours one at a time: (a) *some pull requests could not be
   merged because GitHub had not yet computed mergeability*; (b) *we do not rebase here;
   generated-index conflicts are catch-up's to resolve and content conflicts belong to the
   claim holder*; (c) *the stuck-prs step*.
2. For each, find the composing surface in the tree — the step script, its spec in
   `moderate/reference/workflow.md`, and the shape it rendered into. Search the wording,
   not the step name; the operator quoted output.
3. Record the mapping in the ticket's own findings and in the mission's `## Changelog`:
   quoted line → step id → file and section. Where a line was composed by the agent from a
   step's spec rather than by a script, say so — the repair is then the spec.
4. Where a quoted line maps to no step, say that too, and name the nearest candidates with
   the evidence for each. An honest *not found* is the outcome; inventing a step id is not.
5. Name, for each mapped step, whether it currently acts or only reports — that is the fact
   the four following tickets are written against.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each of the three quoted behaviours has a named composing surface, or an explicit
  *not found* with the candidates and their evidence.
- The mapping is recorded where the following tickets can read it.

**Verification method** — the commands/tests/probes that prove them:

- The recorded mapping cites file and section for each line; a reader can open each one.

**Gate** — what must pass before approval:

- No behaviour change: the diff touches findings and the mission changelog only.

## Considerations

- "stuck-prs" may be the operator's name for a behaviour rather than a step id. Treat the
  quoted behaviour as authoritative and the name as a description.

## Findings — the mapping

Each quoted behaviour resolved to a composing surface in the tree. **All three land on two
steps, `stuck-prs` (step 6) and `merge-conflicts` (step 4)**, both registered in `run.sh`'s
`STEPS` list. Neither acts: `merge-conflicts` returns `"needs_agent": []` and posts nothing,
and `stuck-prs` asks — it emits `action: "ask"` rows under one `ask_key` — so **no step in
this mission's subject area repairs anything today.** That is the fact the four following
tickets are written against.

### (c) *"the stuck-prs step"* — FOUND, and the ticket's premise was wrong

The Overview states this is "a name no step in `workaholic:moderate` carries". It is a step
id, exactly as quoted: `plugins/workaholic/skills/moderate/scripts/step-stuck-prs.sh`, which
prints `"step": "stuck-prs"` on every one of its four exit paths. It is registered in
`run.sh:81` (`STEPS`) and specified at `moderate/reference/workflow.md:267`, *## 6.
`stuck-prs` — what failed to auto-merge, and what it needs*. The operator was naming a step,
not describing a behaviour, and the Considerations' hedge is not needed.

The three candidates the Overview offered are not where these lines come from:
`step-catchup-blocked.sh` and `step-stranded-publications.sh` compose neither quoted line,
and `step-stalled-units.sh` is about claim staleness. They stay untouched by this mission
unless a later ticket has its own reason.

### (b) *"we do not rebase here; generated-index conflicts are catch-up's to resolve and content conflicts belong to the claim holder"* — two surfaces, one of them the channel's

- `step-stuck-prs.sh:168` — the `blocked_by == "conflict"` arm of the `needs` awk program:
  *"a generated-index conflict is cleared by the catch-up on the next [Implement] tick; a
  real content collision belongs to the claim holder, and nobody else may push to that
  branch"*. This is the one that **reaches a person**: it rides `needs_agent`, which
  `human-checkin` renders into the `🙋` question shape.
- `step-merge-conflicts.sh:142` — the step's own `summary`: *"never rebased here: the
  catch-up clears what a generator settles, a content collision belongs to the claim
  holder"*. This is the closer verbatim match to the operator's words, but it is a
  **log-facing summary and an `event`**, not a question — step 4's `needs_agent` is empty
  by construction, and its own header says conflicts ride step 6's reminder so that one
  pull request never earns two Slack lines in one tick.

So the operator read step 6's question and step 4's root line as one sentence. **Both must
be corrected**; correcting only the one that posts would leave the false sentence in the log
and the root, which is where a later session reads its licence.

The same claim is restated as prose in five further places, each of which a later session
will obey if it survives: `moderate/SKILL.md:223` (*"This tick reports conflict state; it
does not rebase somebody else's unit"*), `moderate/reference/workflow.md:241` (*"It does not
rebase"*, recorded as a resolved Open Decision from 2026-08-17), `drive/SKILL.md:120`,
`drive/reference/routing.md:176`, `drive/reference/claims.md:1187`, and the header comments
of `catch-up-claim.sh:16` and `claim-mergeability.sh:16`.

### (a) *"some pull requests could not be merged because GitHub had not yet computed mergeability"* — and the class is NOT the one the sibling ticket names

Three surfaces:

- `step-stuck-prs.sh:127` — the headline arm: `what='with mergeability not yet computed'`,
  which renders as the first line of the reminder (`<N> pull requests with mergeability not
  yet computed`).
- `step-stuck-prs.sh:173` — the matching decision text: *"GitHub has not computed
  mergeability yet — re-read before acting"*.
- `step-merge-conflicts.sh:142` — carries an `uncomputed` count in its summary and event.

**The correction this mission needs**: the sibling ticket
`20260902042630-drop-the-notification-for-an-uncomputed-mergeable-state.md` names
`drive/scripts/claim-mergeability.sh` as the source, *"the one derivation of `clean |
mechanical | content | unanswerable`"*. It is not the source of this line. These two steps
read GitHub over REST through `moderate/scripts/pulls-state.sh`, whose vocabulary is a
different one — `blocked_by` ∈ `conflict | review | checks | draft | behind | unknown`, with
`unknown` defined at `pulls-state.sh:69` as `mergeable == null`. `claim-mergeability.sh`'s
`unanswerable` is a *local* `git merge-tree` reading and never reaches either step;
`step-stuck-prs.sh:49-56` says so in its own header, and explains why (the class needs a
branch ref, and a network read inside these steps was refused on a measurement).

**So the filter that ticket asks for is on `blocked_by == "unknown"`, not on
`unanswerable`.** Applying it to the word the ticket names would filter nothing, and the
operator would see the same post again — which is the exact failure this diagnosis ticket
exists to prevent.

### Where the mapping is recorded

The Final Report is the durable home: the archive commit is its permanent home and it lands
under `.workaholic/tickets/archive/<branch>/`, where the four following tickets read it. The
mission's `## Changelog` receives its dated line from `archive.sh` through
`append-changelog.sh` — that mutator's contract is one dated line per `(event, artifact)`
pair, so the mapping itself belongs here rather than there, and copying it into the
changelog would break the append-only one-line-per-event format the mission skill owns.

## Final Report

Development completed as planned. Diagnosis only — no behaviour changed. The diff touches
this ticket's findings and, through the archive seam, the mission changelog.

### Discovered Insights

- **Insight**: Two independent mergeability vocabularies exist in this tree and are easy to
  confuse by name. `pulls-state.sh` classifies GitHub's own `mergeable` field
  (`conflict | review | checks | draft | behind | unknown`) over REST; `claim-mergeability.sh`
  classifies a local `git merge-tree` result (`clean | mechanical | content | unanswerable`).
  Both have an absence-of-a-reading word, `unknown` and `unanswerable`, and they are not the
  same word.
  **Context**: A ticket, a spec or a filter written against the wrong one is a silent no-op —
  it compiles, it runs, it filters nothing. Any change to what the tick says about
  mergeability must first name which reader produced the string.

- **Insight**: `merge-conflicts` (step 4) deliberately posts nothing and lets `stuck-prs`
  (step 6) carry conflicts into the channel, so one pull request never earns two Slack lines
  in one tick. Its own text still reaches a reader through the log and the root `event`.
  **Context**: Correcting only the posting step leaves the retired claim alive in the log and
  the root line, which is where a later session reads its licence to defer. Both halves have
  to move together.

- **Insight**: The claim that the tick "does not rebase" is not localized to the step that
  says it — it is restated as prose in seven further places across `moderate/` and `drive/`,
  including one recorded as a settled Open Decision (`workflow.md:241`, 2026-08-17).
  **Context**: This mission's retirement ticket has to sweep all of them; a surviving
  sentence is what a later session will obey, and one of them presents itself as a decision
  already made.
