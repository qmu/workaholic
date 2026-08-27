---
created_at: 2026-08-27T01:20:36+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: close-the-units-the-loop-already-finished
merge_policy:
verification_handoff: 
---

# Split the exclusion that hides the difference

## Overview

`claimed_reported` covers two states a reader cannot tell apart: a unit **legitimately waiting on
a person** (a scan finding holds its pull request open) and the loop's **own undelivered work** (a
transport refusal stopped the merge and nobody was told). Both read `queue_drained` in
`lib/claims.sh`, both are excluded `claimed_reported` by `plan-units.sh`, and no later survey
offers either again — so the second is reachable by nothing.

This is precisely the shape the 2026-08-19 `report_incomplete` split fixed one layer up, and its
own header says why: a reason must imply its own next action, and folding two next actions into
one word is what makes the invisible half invisible. Give the undelivered state its own reason.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — one reason, one next action

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the shared derivation that produces
  `queue_drained` / `report_incomplete` / `superseded`. **Read its header whole** before adding a
  verdict: the ordering of the verdicts (`claim_active` first, then `superseded`, then the drained
  fork) is load-bearing and each position is justified there.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — lines ~60–140 and ~270: the exclusion
  vocabulary and its mapping from claim reason to exclusion reason, plus the header paragraphs
  recording why each reason exists separately.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the per-claim row the survey reads.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — its refusal loop reads the same derivation,
  so the offer and the refusal cannot disagree (the 2026-08-27 `superseded` fix).
- `plugins/workaholic/skills/drive/reference/claims.md` — the protocol's full statement.

## Implementation Steps

1. Read `lib/claims.sh`'s header and `plan-units.sh`'s reason paragraphs, and write down where the
   new verdict sits in the existing order and why — the position is part of the change.
2. Derive the split from the reading the first ticket added (pull request open, and the run's own
   recorded merge outcome), never from a second lookup.
3. Emit the new reason from `lib/claims.sh`, surface it in `list-claims.sh`'s row and map it to its
   own exclusion reason in `plan-units.sh`. `claimed_reported` keeps meaning **waiting on a
   person** and nothing else.
4. Decide and state whether the new state is resumable, in the header, with the reason — the
   2026-08-19 split's `resumable: true` and 2026-08-26's `resumable: false` are both precedents and
   they went opposite ways for stated reasons.
5. Make `claim.sh`'s refusal loop read the same derivation, so a unit the survey offers is not
   refused by the claim (the failure the 2026-08-27 `superseded` fix records).
6. Update `drive/reference/claims.md`, `drive/SKILL.md` and `CLAUDE.md`'s claim-protocol section in
   the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A drained, reported claim whose merge was refused by the transport reads the new reason; one
  held by a scan finding still reads `claimed_reported`.
- `list-claims.sh` and `plan-units.sh` agree, both reading `lib/claims.sh`.
- `claim.sh` does not refuse a unit the survey offers.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Walk both claim shapes over a fixture and compare the row, the exclusion and `claim.sh`'s answer.

**Gate** — what must pass before approval:

- Every existing verdict is byte-identical over the existing fixtures; only the new one appears.

## Considerations

- Adding a verdict to `lib/claims.sh` changes what every consumer sees. The regression bar is that
  each existing verdict is unchanged over the existing fixtures — assert it rather than assume it.
- Resist deriving the split from a fresh network read per claim. `claim-merged.sh`'s three-valued
  `unanswerable` contract exists because a wrong verdict here releases work still in flight; an
  answer the run already recorded is stronger evidence than one re-fetched later.

## Final Report

Development completed as planned, with one design decision the ticket left open and one defect
found while testing.

**The position, written down first** (step 1): the new verdict sits **inside** the drained fork's
`reported == true` branch, so every gate ahead of it is untouched — `identity_unresolved`,
`foreign_identity`, `shallow_history`, `claim_active` and `superseded` all still win first, in
that order, each for the reason `lib/claims.sh`'s header records. Nothing before the fork moved.

**Where the reading comes from, and the decision the ticket left open.** Step 2 says derive it
from "the run's own recorded merge outcome" — which did not exist durably: the sibling ticket put
that outcome in the run report, and a run report dies with its container. Two alternatives were
rejected before the third was taken:

- **Re-run the scan** to ask whether a `hard`/`confirm` finding would have held the pull request.
  Impossible here: `scan-branch-safety.sh` diffs `<base>..HEAD` of the *current* checkout, and
  the oracle stands in the main tree, so answering for another branch means checking it out
  inside what is contractually a pure read.
- **A fresh lookup per claim.** Weaker evidence than the run's own answer, and the ticket's own
  Considerations say so: a wrong verdict here releases work still in flight.

So the run that attempted the merge **records the outcome into the branch story it already
committed** (`story/scripts/record-merge-outcome.sh`), and `claims_merge_outcome` reads that one
line out of a blob the oracle already fetches — no network call, no second derivation, and it
cannot disagree with the run that made the attempt. No new artifact type: the story is the
branch's own record and is already what `claims_has_story` reads.

**Resumability, decided and stated** (step 4): `resumable: false`, and for a *different* reason
than `queue_drained`'s. The next action is a **merge retry**, which is not a takeover — resuming
would push an empty `Resume` commit onto a branch whose pull request is open, the 2026-08-01 gate
exactly. The 2026-08-19 split went `resumable: true` because its unit had never reported and the
takeover had real work to do; this one has already written its story and opened its pull request.
`claim.sh resume` refuses it under its own name rather than `queue_drained`'s wording, which
would send the reader to wait for a human who is not coming.

**An absent section keeps `queue_drained`.** Every story written before this section, and every
run that died before recording, answers empty — so the new reason is claimed only on positive
evidence, and the regression bar the Considerations set (every existing verdict byte-identical
over the existing fixtures) is met by construction and asserted directly.

### Discovered Insights

- **Insight**: The refusal for a malformed outcome was itself malformed.
  **Context**: `record-merge-outcome.sh` interpolated the outcome raw into its JSON, so the one
  input it refuses for containing a newline produced a refusal that was not parseable JSON — a
  caller got a syntax error instead of `outcome_not_one_line`. Caught only because the test
  parsed the refusal rather than grepping it. The emitter now escapes quotes and backslashes and
  collapses control characters, so every emission is parseable whatever was passed in.

- **Insight**: A shell-level newline cannot be passed through `JSON.stringify` in these tests.
  **Context**: `JSON.stringify("a\nb")` yields `"a\nb"` with a literal backslash-n, and `sh`
  inside double quotes does not interpret it — so the argument is one line and the script was
  right to accept it. The first version of this test asserted a refusal that should never have
  happened. Any test of a multi-line argument has to build it in the shell (`"$(printf 'a\nb')"`),
  which is worth knowing before the next one reads as a script defect.
