---
created_at: 2026-08-17T11:45:39+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817114538-draft-per-target-release-notes-from-the-base.md
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Structure the note as the release record

## Overview

Expected action 3: the note states what confirmation steps and release procedure are needed
after release, and it records that the AI completed the confirmation — so the note serves
as the *record of the release*, not only its announcement.

Both halves already exist in pieces and are currently split across two documents: `/ship`
§5-D records a deployment attempt (`pass`/`fail`/`not_run`/`bypassed`) into the story **and**
into the note's append-only `## Deployment Verification`, and the procedure and its
executable confirmation live in the target's `deployments/` record. This ticket makes the
note the place where a reader finds all of it, without making the note a second source of
truth for the procedure.

## Policies

- `workaholic:operation` / `policies/delivery.md` — the confirmation is the release's evidence
- `workaholic:safety` / `policies/incident-response.md` — a failed confirmation must be legible after the fact
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` §5 and §5-D — the drafting phase and the
  deployment attempt's recording, including the four outcome values.
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh`,
  `confirm-release.sh`, `record-release-cut.sh` — the existing writers of confirmation
  evidence; extend, never duplicate.
- `plugins/workaholic/skills/ship/scripts/check-confirmation-capability.sh` — the gate that
  halts when a target declares no confirmation method. The note must show that state rather
  than hide it.
- `.workaholic/deployments/marketplace.md` — `## Procedure` and `## Confirmation`: the
  authored source the note quotes.
- `plugins/workaholic/skills/write-release-note/SKILL.md` — the structure this ticket
  extends.

## Implementation Steps

1. Define the note's sections for this purpose: the prospective `## Deployment Plan` (what
   is waiting, the procedure, the verification required) and the append-only
   `## Deployment Verification` (each attempt, its outcome, when, by whom/what).
2. **Quote the procedure, cite the source, never fork it.** The `deployments/` record is
   authored by a human and is the gate's evidence; a note that carries an editable copy will
   drift from it and the next ship will gate on the wrong text.
3. Record the AI's confirmation completion as an attempt row with its outcome — including
   `not_run` and `bypassed`, which are the two a summary is most tempted to omit and the two
   an auditor most needs.
4. Show a target with **no** confirmation method as exactly that. `/ship` already halts on
   it; the note must not render that as an unverified success.
5. Keep the verification section append-only: a re-attempt adds a row, never rewrites one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A note shows the procedure and required verification quoted from the target's record, with
  the source cited.
- Every attempt appears as its own row with one of the four outcomes; no row is ever
  rewritten.
- A target lacking a confirmation method renders as lacking one.
- The `deployments/` record is never written by this path.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A simulated `pass`, then a `fail`, then a `not_run` against one target: three rows, in
  order, none rewritten.
- `bash plugins/workaholic/skills/ship/scripts/check-confirmation-capability.sh`

**Gate** — what must pass before approval:

- The append-only property is demonstrated, not asserted.

## Considerations

- "The AI completed the confirmation" is a claim with weight. It should record *what
  command ran and what it returned*, not a sentence saying it was done — the difference
  between evidence and an assertion is the whole point of the `## Confirmation` gate.
- The story already carries the same attempt record. Two homes are acceptable here because
  they answer different questions (the story is the branch's history, the note is the
  target's), but they must be written by one writer so they cannot disagree.

## Final Report

Development completed as planned. One real defect was found while demonstrating the
append-only property, and fixing it is the substance of this ticket.

### The note's two sections, defined

- **`## Deployment Plan`** — prospective, regenerated. Beyond the per-target facts it
  already carried, it now holds two quoted sub-sections: `### Procedure` and
  `### Verification required after release`.
- **`## Deployment Verification`** — append-only, one `### Attempt` block per attempt,
  written by `record-evidence.sh`.

### Quoted, cited, and still not forked

The ticket asked for the procedure to be **quoted**; `workaholic:write-release-note`
already said the plan should carry **references** rather than copies, because a copy
drifts from the text `/ship` gates on. Both hold, and the reconciliation is that the
quote is **regenerated on every render**:

- The quote lives inside a section that is rewritten from the record each time, so it
  cannot drift — a fork requires an editable copy, and there is none.
- The citation names the authored source and says which document to edit ("Edit that
  record — never this note: … anything typed here is lost").
- `read-deployments.sh` gained a `--section <slug> <Procedure|Confirmation>` mode so the
  quote comes from the **single parser** of that frontmatter. A second reader would have
  been exactly the fork the area's rule forbids.

A record declaring no `## Procedure` or no `## Confirmation` renders as *"the record
declares no …"*, and a target with no `confirmation_method` renders as **none declared**
with the note that `/ship` halts on it — never as an unverified success.

### The defect: the attempt was appended to the file, not to the section

`record-evidence.sh` appended each block at **EOF**. That was correct only while
`## Deployment Verification` happened to be the last heading in every note. A generated
per-target draft ends with `## Links`, so the first recorded attempt landed *below* it
while the Verification section above still read "no attempt has been recorded against
this draft" — **the document contradicting itself about whether the release was ever
verified**, which is precisely the confusion the section exists to prevent.

Fixed: the block is now inserted at the **end of the `## Deployment Verification`
section** (before the next `## ` heading), falling back to EOF-plus-heading when the
section is absent. Append-only is unchanged — the insert point is the end of the
section, so no earlier attempt is rewritten or reordered.

### The append-only property, demonstrated

Three attempts against one target on a generated draft, in order:

| # | Status | Observed |
| - | ------ | -------- |
| 1 | `pass` | release v1 present |
| 2 | `fail` | release missing |
| 3 | `not_run` | no gh in container |

Result: three `### Attempt` blocks at lines 122 / 133 / 144, statuses in that order, all
under the single `## Deployment Verification` heading at line 110 and all above
`## Links` at line 154. No block was rewritten and none reordered. The pre-existing
EOF-style note kept working (4 blocks after a 4th call), so the fix is not a regression
for notes that have no section after Verification.

`not_run` and `bypassed` are the two a summary is most tempted to omit; both are carried
through unchanged as first-class statuses, and `not_run` stays deliberately distinct from
`fail` — "we could not check" and "we checked and it was wrong" call for different acts.

### The `deployments/` record is never written by this path

Verified two ways: `git status --porcelain .workaholic/deployments/` is empty after the
whole exercise, and a grep for any redirect/copy/move targeting that directory across the
ship skill's scripts finds no writer. `check-confirmation-capability.sh` still refuses a
target with no declared method (`{"error": "confirmation method is required"}`).

### Discovered Insights

- **Insight**: An "append to the end of the file" writer and an "append-only section" are
  the same thing only until some document grows a heading after that section. The bug was
  latent for the whole life of `record-evidence.sh` and became visible the moment a
  generated note put `## Links` last.
  **Context**: Any future append-only section in this repository should be written as
  *insert before the next sibling heading*, not as `>>`. The failure mode is not a lost
  write — it is a document whose two halves disagree, which is worse than a missing one
  because it reads as authoritative.

- **Insight**: "Quote it" and "reference it, never copy it" are not in conflict when the
  quoting surface is regenerated. What the no-copy rule actually forbids is a *second
  editable home* for a human's contract; a derived quote has no independent existence to
  drift with.
  **Context**: Worth reusing wherever this repository debates duplication — the question
  to ask is "can the copy be edited independently?", not "does the text appear twice?".
