---
created_at: 2026-08-31T11:35:59+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# State the no-waiting rule where the shell rules live

## Overview

Three surfaces change here — how the tick reads its own files, when the log lands, and a
new step — and each has a documented home. This repository's own rule is that a behaviour
change updates every affected document in the same commit.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/shell.md` — the read rule.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step contracts and the
  finding classification table.
- `plugins/workaholic/skills/moderate/SKILL.md` — the tick's steps and its voice.
- `CLAUDE.md` — the `/moderate` row, its step count, and the `persist-log.sh` paragraph
  that says the persist runs twice.


## Implementation Steps

1. Correct the `persist-log.sh` account in place: it runs **three** times once the early
   persist lands (opening, closing, and again after the agent records what it filed), and
   the paragraph currently states two with its reasons. Say what the third one buys.
2. Document the new step, its key, whose question it is, and that it supplies an event
   only when it finds a stopped tick.
3. Classify the new step id in the finding table deliberately — an unclassified id reads
   `needs_ruling`, which is safe and is not the same as having decided.
4. Move the step count in the skill and `CLAUDE.md` together.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The persist paragraph states three persists with the reason for each.
- The new step is documented, classified, and counted consistently in the skill and
  `CLAUDE.md`.
- `rules/shell.md` carries the read rule.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `outputs/` regenerated in the same change; no document left asserting two persists.


## Considerations

- The step count appears in more than one sentence of the `/moderate` row; grep for the
  numeral rather than trusting one edit.


## Final Report

Development completed as planned. Four surfaces moved together in this change:

- **The persist account is corrected in place.** It runs **three** times, not two, and the reason
  for each is stated: the **opening** (immediately after `open-log`, so a tick that dies mid-run
  leaves its opening on the base — without it the record that would show a stop is the record the
  stop prevents), the **closing** (`run.sh`'s last act), and the **agent's** (the `<step>-filed`
  lines the closing act could not have carried). Corrected in `moderate/SKILL.md` and in
  `rules/workaholic.md`, which carried its own two-persist sentence; no document is left asserting
  two.
- **The new step is documented**: `reference/workflow.md` §31 (what it reads, what "closed" means
  and why it is not the persist, which tick and why not the previous one, its abort reasons, and
  that it supplies an event only when it finds a stopped tick), named in `moderate/SKILL.md`'s list
  of what the tick can ask about, and given a row plus a note in `CLAUDE.md`'s `/moderate` step
  table.
- **It is classified deliberately** as `needs_ruling` in the finding table: the reading says a tick
  stopped and cannot say why, so filing it as work would have the loop repairing a cause it never
  established — `cadence-lapse`'s row, for `cadence-lapse`'s reason.
- **The step count moved from thirty to thirty-one** in the skill (four sentences: the frontmatter
  description, the relocated-detail line, the run section and the ask enumeration) and in
  `CLAUDE.md`, in the same commit; `scripts/test-workflow-scripts.mjs`'s expected `STEPS` array is
  the mechanical partner that fails if they disagree.

`rules/shell.md` carries the read rule (its own ticket). `outputs/` is regenerated in the same
change.

### Discovered Insights

- **Insight**: the two-persist claim lived in **two** documents, and only one of them was named in
  this ticket's Key Files.
  **Context**: `rules/workaholic.md`'s `moderations/` paragraph carries its own full account of the
  persist seam, so a correction made only where the ticket pointed would have left the tree
  self-contradicting. Grepping for the claim ("runs twice") rather than the document is what found
  it — the same discipline the ticket recommends for the step count numeral.
