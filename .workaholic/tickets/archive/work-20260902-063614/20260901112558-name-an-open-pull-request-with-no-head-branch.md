---
created_at: 2026-09-01T11:25:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# Name an open pull request with no head branch

## Overview

PROPOSED. `#813`, `#799`, `#688`, `#635` and `#625` were open with **no branch on the remote**.
GitHub does not close a pull request when its head branch is deleted, and such a pull request can
never be merged by anyone. Their content was already on `main`, verified file by file, and a person
closed all five by hand on 2026-09-01. Nothing in the loop reads this state, so they sat in the open
set inflating every count that reads it — `total_open` in both publication readers, the operator's
own waiting list, and every `/implement` report line derived from them.

A pull request whose head branch is gone is **unmergeable by construction**: a fact about the
repository, not a judgement. The ask says it belongs beside `operator-pulls`, and it does — that is
the step that already follows pull requests waiting on a person.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a reading that could not be made is named

## Key Files

- `plugins/workaholic/skills/branching/scripts/list-operator-facing-pulls.sh` — the sibling reader;
  its header states that membership is derived from the seam's refusal word and never from a title.
  This is a **different question**, so it gets its own reader rather than a widened membership.
- `plugins/workaholic/skills/moderate/scripts/step-operator-pulls.sh` — the step this rides,
  including the addressee rule (the operator) and the `condition-age.sh` exemption stated there.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step spec and the question body
  contract (`workaholic:notify`: lead with what happened, identifier after it, one act asked).
- `plugins/workaholic/skills/branching/scripts/list-stranded-publications.sh` — the third reader of
  the open set; check whether a headless pull request currently reads as a candidate there.

## Implementation Steps

1. Add `branching/scripts/list-headless-pulls.sh`: the open pull requests whose `head.ref` names no
   ref on origin. One repository-scoped REST listing plus the ref set already available; pure read,
   `ok: false` with a reason and **no `pulls` key** on a degraded read, exit 0 always.
2. Read it in `step-operator-pulls.sh` beside the existing candidates, under its own question key
   `headless-pull:<number>`, addressed to the operator. Distinct key, because the act asked for is
   different: the existing question asks for a ruling on a diff, this asks for a close.
3. Write the question body to the contract — what happened first, identifier after: *this pull
   request's branch no longer exists, so it can never be merged; close it.* Never lead with the
   number and never emit a bare verdict word.
4. Confirm the reading does not double-report: a headless pull request must not also be offered as
   a stranded publication or a catch-up candidate, since both would ask for an act that cannot
   succeed. Filter it out by name in whichever reader currently admits it, and say so in that
   reader's header.
5. Record the step and its key in `moderate/reference/workflow.md` and in `CLAUDE.md`'s step table.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An open pull request whose head ref is absent from origin is named once, under
  `headless-pull:<number>`, addressed to the operator.
- The same pull request is offered as neither a stranded publication nor a catch-up candidate.
- A degraded read names its reason and never renders as *nothing headless*.
- The existing `operator-pull:<number>` candidates, key and addressee are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic rows for a headless pull request, a normal
  one, and an unreadable listing.
- Inspect the rendered question body against the `workaholic:notify` contract by eye; it is prose
  and nothing mechanical checks it.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

## Considerations

- The loop **asks** and does not close. Closing another person's pull request is not a bounded act
  the way a branch delete is, and five of these were closed by a person who first verified the
  content was on `main` file by file. The ask does not request an act, only a reading.
- Why not widen `list-operator-facing-pulls.sh`: that reader answers *which pull requests wait on
  the operator's ruling*, derived from the publish seam's refusal word. A headless pull request
  waits on nothing and has no refusal word. Two questions, one derivation each.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: A headless pull request was already reaching `list-stranded-publications.sh` as a
  candidate and coming back `mergeability: unanswerable` — reported, never acted on, and never
  asked about. The double-report was real but silent, because `unanswerable` is the class that
  reaches no act and no `/moderate` question.
  **Context**: The two acceptance terms ("named once" and "offered as neither a stranded
  publication nor a catch-up candidate") therefore needed a filter in the stranded reader rather
  than only a new reader; a catch-up candidate was already structurally impossible, since
  `list-catchable-claims.sh` needs a claim and a claim needs an unmerged remote branch.
- **Insight**: The ref set is read through one repository-scoped REST listing
  (`repos/{slug}/branches`) rather than through `refs/remotes/origin/*`, even though the claim
  scan has just fetched with `--prune`.
  **Context**: The two readings fail in opposite directions. A stale or never-fetched local ref
  renders a **live** pull request headless, and the act asked for is a close — so the reading that
  sends a person to close something must be the exact one. The local read is kept only inside
  `list-stranded-publications.sh`, where being wrong can merely drop a publication for one tick.
- **Insight**: `gh api` arguments are matched by position by every transport stub in the hermetic
  suite, so `--paginate` goes **after** the endpoint.
  **Context**: A flag in the first position after `api` silently stops matching `case "$2"` in the
  stubs and the row passes for the wrong reason.
