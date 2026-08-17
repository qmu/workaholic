---
created_at: 2026-08-17T11:45:39+00:00
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
