---
created_at: 2026-08-27T23:22:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-drill-the-blocked-retirement-with-no-network.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Write the blocked retirement into the documents

## Overview

This repository's own rule is that a change altering behaviour updates every
affected document **in the same commit**; outdated documentation is a defect. The
retirement's blocked path touches three documents that currently describe it as
working, and one of them is the claim protocol's proofs-and-judgements table, which
a hermetic test pins against its consumers.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — the documents move with the behaviour

## Key Files

- `CLAUDE.md` — the claim-protocol bullet describing `retire-claim.sh`'s three acts
  ("its only writes are one REST `PATCH` and one branch delete"), and `/moderate`'s
  step list, where `retire-claims` is described as asking nothing.
- `plugins/workaholic/skills/drive/reference/claims.md` — *Proofs and judgements*,
  the one home of the classification, whose consumers the suite pins.
- `plugins/workaholic/skills/moderate/SKILL.md` — the step's own contract.
- `plugins/workaholic/rules/shell.md` — only if ticket 3 admitted a second act.
- `docs/loop-drill-runbook.md` — the new drill rows' blame table.

## Implementation Steps

1. Update `CLAUDE.md`'s claim-protocol bullet: the three acts, the named word for a
   refused delete, what stands when one act is blocked, and that a blocked unit now
   reaches its holder once. State the measurement that drove it, as the surrounding
   entries do.
2. Update `/moderate`'s step list where it says `retire-claims` asks nothing and its
   `needs_agent` is empty — narrowed, not reversed, and say which half moved and why.
3. Update `claims.md`'s *Proofs and judgements* section if and only if the word set
   moved. `superseded` stays a **proof** and its classification does not change; the
   new reason word is the retirement's own vocabulary, not the oracle's — say so, so
   a later reader does not add it to the wrong table.
4. Update `shell.md` only if ticket 3 admitted a second act; if it recorded that no
   transport can delete a branch, record **that**, where a later session looking for
   a retry finds the answer instead of re-deriving it.
5. Record the drill's new rows in the runbook's failure-reason→file table.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every document naming the retirement describes what it now does, including the
  blocked path and who is asked.
- `superseded`'s classification as a proof is unchanged, and the new word is placed
  in the retirement's vocabulary rather than the oracle's.
- The suite's pin over the proofs-and-judgements table and its consumers passes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- All three pass, and `outputs/` is regenerated so the freshness workflow is clean.

## Considerations

- The behaviour and the documents land in the same commit by this repository's rule.
  This ticket is last in the order because it records what tickets 1–7 concluded,
  not because the documentation is deferred to a later change.
- Ticket 3's two possible outcomes produce different documentation. Write the one
  that happened; do not describe a retry that was never admitted.
