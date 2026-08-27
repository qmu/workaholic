---
created_at: 2026-08-27T23:22:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-give-a-refused-delete-its-own-reported-word.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Retry a refused delete or record no transport

## Overview

Where a second transport can take the one act the first refused, retry it there —
bounded exactly as `rules/shell.md`'s one qualification bounds the merge retry: one
named precondition, one act, one attempt, the outcome reported either way. **If no
connector surface can delete a branch, that is this ticket's finding**, recorded
rather than worked around, and the mission lands on the reporting half alone. Both
outcomes complete this ticket; neither is a failure.

The candidate surfaces are the REST endpoint through `gh-rest.sh`
(`DELETE /repos/{owner}/{repo}/git/refs/heads/{branch}`) and the GitHub connector.
Ticket 1's measurement says whether either is answerable at all — a session-type
refusal that covers every surface makes this a recording ticket by construction.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a refusal names itself

## Key Files

- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — Act 2; a second REST
  attempt lives here, a connector attempt does not (a script may not call an MCP tool).
- `plugins/workaholic/rules/shell.md` — the qualification whose bounds this reuses
  verbatim; extend it only if a second act is genuinely admitted.
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — where a
  connector retry, if one exists, would be a numbered step with its own reported outcome.

## Implementation Steps

1. Read ticket 1's measurement. If the refusal is a **protection rule** or a
   **missing scope**, no second transport helps: record that finding, close the
   retry half here, and stop at step 5.
2. If a second **REST** attempt is admissible, make it inside `retire-claim.sh`:
   precondition is the exact reason word ticket 2 introduced and no other, one
   attempt, and both outcomes reported by name.
3. If only the **connector** can delete a branch, the attempt cannot live in a
   script. Enumerate the connector's branch-delete surface; if none exists, that is
   the finding. If one exists, it becomes a numbered step of the caller with its own
   reported outcome, on `rules/shell.md`'s bounds and its enforcement — a run naming
   the precondition and reporting no retry outcome is non-conformant on its face.
4. Never widen the precondition. No other reason word, no other verdict, and never
   a retry on a claim that is not `superseded` — the proof gate is untouched.
5. Record the outcome in `rules/shell.md` and the claim protocol reference: either
   the second act and its bounds, or the finding that no surface can take it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Either one bounded retry exists with both outcomes reported by name, or the
  absence of any capable surface is recorded as the finding — and the branch taken
  is stated with its evidence.
- The precondition is one reason word; no other verdict or word reaches the retry.
- Nothing merges, reverts or releases a claim, and the `superseded` proof gate is unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-retire`

**Gate** — what must pass before approval:

- The finding (or the retry's bounds) is written where a later reader finds it, not
  only in the pull-request body.

## Considerations

- Recording "no transport can do this" is a **complete** outcome, not a half-done
  ticket. The mission's value then rests on tickets 4–6, which is why they are
  independent of this one.
- A script shelling out to an MCP tool would be the same gap with more moving parts.
  If the connector is the only surface, the step belongs to the caller.
- The 2026-08-05 comment predicted this refusal and called it "not fatal". It is
  fatal to the mechanism's purpose — unmerged remote branches are the only claim
  oracle — and that is the reasoning this mission acts on, not the comment.
