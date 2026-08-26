---
created_at: 2026-08-26T02:18:25+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826021825-read-the-ask-s-feedback-line-through-one-script.md
mission: prove-the-loop-s-closing-link
merge_policy:
verification_handoff: 
---

# Report every carried and dropped feedback ref

## Overview

The carry-forward is the loop's fourth link and no surface names it. `/specificate`'s run
report ends with the form, the record filename, the PR URL and `notified`; the
pull-request body carries the record and the proposal. Neither says which refs rode onto
which artifact, so a turn that lost the link reports success on the turn that lost it —
and the loss then reads downstream as `no_citing_artifacts`, which is also what a direction
nobody has answered reads as.

`reference/workflow.md` step 3b already says a dropped ref "is dropped and named in step 10's
pull-request body". Nothing implements that half either. Make both surfaces name it, per
emitted artifact.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a dropped ref is named where it
  was dropped
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 3b (what it hands
  forward), step 10 (the PR body), step 13 (the run report line)
- `plugins/workaholic/skills/specificate/SKILL.md` — *Carry the ask's own feedback refs
  forward*; the Workflow summary's step 5 report contract
- `plugins/workaholic/commands/specificate.md` — the entry-point contract, if the report
  shape it names changes
- `CLAUDE.md` — the `/specificate` row states what the run reports

## Implementation Steps

1. Extend step 13's report contract: beside `precedence:<form>` / `unsure:<what>`, the line
   names **per emitted artifact** the refs carried and the refs dropped with their reason —
   using the previous ticket's script output as the source, never a re-read by eye.
2. Extend step 10: the pull-request body carries the same two sets. Keep it to what is true —
   a proposal that carried nothing because the ask named nothing says so in one clause, not
   as a warning.
3. State the record-only case explicitly: a record-only outcome emits no artifact, so it
   reports the refs it *would* have carried and that nothing was emitted — otherwise a
   dropped link and an unproposed ask look alike in the report too.
4. Update the SKILL's *Carry the ask's own feedback refs forward* section so the reporting
   obligation lives beside the carrying obligation, and refresh the `CLAUDE.md`
   `/specificate` row in the same change (this repository treats stale documentation as a
   defect).
5. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Step 13's report contract names carried and dropped refs per emitted artifact, with a
  reason per drop
- Step 10's pull-request body carries the same information
- The record-only case is stated: what would have been carried, and that nothing was emitted
- `CLAUDE.md`'s `/specificate` row and the SKILL agree with `reference/workflow.md`

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The three documents state one contract, and `outputs/` is regenerated in the same commit

## Considerations

- This is a **prose contract over a script's output**, not a new script: the mechanical part
  is the previous ticket's reader, and what remains is that the run must say what the reader
  returned. The floor that makes a silent loss impossible is the next ticket — reporting
  alone would still let a run report a drop and publish anyway.
- Keep the report line short. It is read in a routine's container log and in a finish post's
  neighbourhood; a per-artifact ref dump that nobody reads is the noise this repository has
  twice retired status roots for.
