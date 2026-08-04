---
created_at: 2026-08-04T20:55:00+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-212445
---

# Truth up the root README's mission lifecycle, which still documents the retired draft gate

## Overview

`README.md` is the repository's front door and the one document a person reads before installing anything. It still describes a mission lifecycle that was retired weeks ago, in at least five places, so a new reader is taught the wrong model and an agent reading it is taught a workflow that no longer exists.

Found while stating the ticket floor in the five documents ticket `20260804173626` named. `README.md` was not one of them, and its floor sentences were corrected in that change; **this ticket is the rest** — the lifecycle drift, which belongs to earlier merged decisions (K1/K2/J4) rather than to the floor, and is too large to ride along in a doc-alignment commit.

## What is stale

| Line | Says | Actually |
| ---- | ---- | -------- |
| 7 | the developer "approves" a mission as a day-planning step | Approval is merging the mission's pull request (K1). There is no approve step |
| 57 | `/drive` surveys "approved missions" | It surveys missions in the active area; `status: approved` was retired |
| 59 | `/propose` registers "**draft** missions ... pushed to main" | It proposes a mission *with its ticket set*, unowned, onto a `work-*` branch behind a pull request (J4) |
| 63 | `/mission` "spins up a dedicated `.worktrees/<slug>/` worktree" at creation, and `/mission approve <slug>` is a subcommand | Creation makes no worktree (claim-born, I6/J1) and `approve` is gone (K1) |
| 92 | the example block runs `/mission approve <slug>` | The command does not exist |
| 120-121 | sources "publish straight to `main`"; approval given "at a mission's approval" | Every artifact reaches `main` through a merged pull request (J4); approval is that merge |

## Policies

- `workaholic:implementation` / `policies/objective-documentation.md` — outdated documentation is a defect, and the front door is where it costs most
- `workaholic:design` / `policies/history-structures.md` — the retired spellings are history worth recording as *retired*, not silently deleted

## Key Files

- `README.md` — the drifted document
- `CLAUDE.md` — the corresponding rows, already current; use them as the source of truth rather than re-deriving
- `.workaholic/README.md` — its missions entry was corrected on 2026-08-04 and is a worked example of the same repair

## Related History

The three decisions the README predates are recorded in `docs/loop-engineering-workflow.md`: K1 (draft/approved retired into `active`; merging the PR is the approval), K2 (`approve.sh` and `/mission approve` deleted, `merge_policy` moved to creation), and J4 (artifacts publish onto a `work-*` branch behind a pull request rather than straight to `main`).

## Implementation Steps

1. Rewrite the six spots above against `CLAUDE.md`'s current rows — the repair is transcription, not re-derivation.
2. Remove `/mission approve <slug>` from the example block, and replace it with what a developer actually does now: merge the mission's pull request.
3. Re-read the whole file for the same class of drift rather than only the listed lines; the list is what one pass found, not a survey.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `README.md` contains no occurrence of `draft` or `approve` as a mission lifecycle term, and none of `/mission approve`.
- Every mission/propose/drive sentence in `README.md` agrees with the corresponding `CLAUDE.md` row.
- No behavior changes — this is a documentation-only change.

**Verification method** — the commands/tests/probes that prove them:

- `grep -n "approve\|draft" README.md` returns nothing about missions.
- `node scripts/test-workflow-scripts.mjs` green (several tests assert on document content).

**Gate** — what must pass before approval:

- The grep is clean, the suite is green, and a reader can follow the README's mission example end to end without hitting a command that does not exist.

## Considerations

- **Do not re-derive the model from the code.** `CLAUDE.md` is current and was updated with each decision; transcribing from it is both faster and less likely to invent a fifth description of the same thing.
- The stale text is worth *retiring* rather than deleting where it explains a decision, but the README is a front door and not a history file — the history already lives in `docs/loop-engineering-workflow.md`.

## Final Report

Development completed as planned. The ticket's table named six spots; re-reading the whole file
per step 3 found roughly twice that, and two of them were diagrams rather than prose.

### Discovered Insights

- **Insight**: The deepest drift was in the two Mermaid diagrams, not the prose. Use case 2 drew
  `draft ==>|/mission approve| approved` as an explicit state machine, and use case 3 had a
  `/mission approve` command node with `status: draft` / `status: approved` artifact nodes — the
  retired gate encoded as topology, in the form a reader absorbs fastest.
  **Context**: A prose sentence can be corrected word by word, but a diagram encoding a retired
  model has to be re-drawn, so it silently outlives the prose fix. When a lifecycle changes, grep
  the ```mermaid fences for the old state names as a distinct pass — the ticket's own acceptance
  grep (`approve|draft`) would have caught these only because the node *labels* happened to spell
  them out.
- **Insight**: `.workaholic/README.md` line 27 is the current, correct statement of the mission
  lifecycle and was the transcription source alongside `CLAUDE.md`, exactly as the ticket's
  Considerations directed.
  **Context**: Three documents describe this model; two were already repaired. Deriving a fourth
  description from the code would have been slower and would have risked inventing a variant.
