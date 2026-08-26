---
created_at: 2026-08-26T02:18:25+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826021825-read-the-ask-s-feedback-line-through-one-script.md
mission: prove-the-loop-s-closing-link
merge_policy:
verification_handoff: 
---

# Floor the carry at the publish seam

## Overview

Reading the ask's refs and reporting them still leaves the failure reachable: a run that
reads them and forgets to pass them to `scaffold-draft.sh` / `scaffold-proposed-ticket.sh`
publishes a mission whose `feedback:` list is missing the strategy's refs, and the loss
reaches `main`. The repository already has the shape of the answer — the two-ticket floor
is checked at the publish seam by `mission/scripts/check-floor.sh`, whose header states the
principle: the count is judged in one place so four inline checks cannot drift, and the
refusal names the alternative.

Add the carry floor beside it: when the ask carried refs that resolved and the run emitted a
mission or a ticket, those refs must be on what it emitted.

## Policies

- `workaholic:implementation` / `policies/fail-fast.md` — the seam refuses rather than
  publishing a violation
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/scripts/check-carry-floor.sh` — new; the verdict
- `plugins/workaholic/skills/mission/scripts/check-floor.sh` — the shape to mirror: JSON
  verdict, non-zero exit so a seam that ignores the JSON still fails, refusal names the repair
- `plugins/workaholic/skills/specificate/scripts/read-feedback-relation.sh` — the one reader
  of an artifact's `feedback:` list; this composes it rather than parsing frontmatter again
- `plugins/workaholic/skills/specificate/reference/workflow.md` — step 9 (beside the ticket
  floor) and step 10
- `scripts/test-workflow-scripts.mjs` — hermetic coverage

## Implementation Steps

1. Write `check-carry-floor.sh`, taking the resolved carried refs and the emitted artifact
   paths. Read each artifact's relation through `read-feedback-relation.sh` — never a second
   frontmatter parser, which is the rule that script's own header states.
2. Emit `{"ok", "missing": [{"artifact", "ref"}], "checked", "reason", "repair"}` and exit
   non-zero when any resolved ref is absent from an emitted artifact, mirroring
   `check-floor.sh`'s exit discipline.
3. The refusal names the repair concretely — which scaffold call to re-run with which refs —
   because a refusal stating only the rule leaves the caller retrying the same thing.
4. Invoke it in `reference/workflow.md` step 9, immediately beside `check-floor.sh`, so both
   floors are read at the same seam. A refusal here is a **run failure to report**, not a
   demotion to record-only: the record was already written and the artifacts are already
   scaffolded, so the correct action is to fix the refs and re-check before step 10 publishes.
5. Scope it exactly: no refs on the ask, or a record-only outcome, means nothing to check —
   `ok: true`, `checked: 0`. A ref that did **not** resolve was already dropped by the reader
   and is never required here.
6. Add hermetic cases: a mission missing one carried ref; a mission and its tickets carrying
   all of them; an ask with no refs. No `gh`, no network.
7. Regenerate `outputs/` and verify.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `check-carry-floor.sh` exits non-zero and names each `{artifact, ref}` when a resolved
  carried ref is missing from an emitted artifact
- An ask with no refs, and a record-only outcome, both return `ok: true` with `checked: 0`
- `reference/workflow.md` step 9 invokes it beside `check-floor.sh`
- The artifact's relation is read only through `read-feedback-relation.sh`

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The floor refuses the missing-ref case in a hermetic test, and `outputs/` is regenerated in
  the same commit

## Considerations

- **The floor is on the emitted artifacts, not on the strategy.** It checks a string in a
  file; it never asks whether the work advances the direction, which stays a judgment.
- A mission's tickets need not each repeat the mission's refs — `attributed-work.sh` reaches a
  ticket through `via_mission:<slug>`. Decide and state which artifacts the floor requires the
  refs on (the mission when there is one; the loose ticket when there is not), rather than
  demanding them everywhere and forcing noise into every ticket's frontmatter.
- Nothing here adds a field to any artifact and the retired `strategy:` relation stays retired.
