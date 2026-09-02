---
created_at: 2026-08-21T15:07:10+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: name-the-session-type-that-cannot-merge
merge_policy:
verification_handoff: 
---

# Name the session-type merge refusal

## Overview

PROPOSED. `publish-tree-pr.sh` keeps its merge reason honest for two known refusals — 405 is
GitHub refusing the merge itself, 409 is the head moving under us — and collapses everything
else into `merge_failed`. A third refusal now exists and is neither: a web session gets **403
"Merging pull requests is not permitted for this session type"**. It is not a fault in the
change, not a conflict, and not a race; it is the execution class saying no. Reported as
`merge_failed`, it sends the reader to look for a defect that is not there.

This ticket adds the third rung. It changes no transport.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the `405`/`409`/`*` ladder at the merge step, and the emitted `merge_reason`.
- `plugins/workaholic/skills/specificate/SKILL.md` and `reference/workflow.md` step 10 — they name what the report says about `merged`/`merge_reason`.
- `scripts/test-workflow-scripts.mjs` — pins the existing reasons; the new one belongs beside them.


## Implementation Steps

1. Reproduce first: capture the exact 403 body from a web session rather than trusting the
   quoted string. The reporter gives both the status and the message, and the ladder must key
   on whichever of the two is actually stable — a message string can be reworded upstream.
2. Add the rung to the ladder in `publish-tree-pr.sh`, beside `405` and `409`, with a comment
   saying what it means as the neighbours do.
3. Name it for what it is — the session type cannot merge — not for the transport, since the
   pull request is fine and a different caller could merge it.
4. Carry the reason into what `/specificate` reports, so an unmerged proposal from a tick reads
   as an environment refusal rather than an unexplained failure.
5. Pin it in `test-workflow-scripts.mjs` alongside the reasons already covered.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A 403 session-type refusal emits its own `merge_reason`, never `merge_failed`.
- The reason is documented where the other two are, with what it means.
- `/specificate`'s report distinguishes it from an unexplained merge failure.

**Verification method** — the commands/tests/probes that prove them:

- Stub the merge call to return the captured 403 body and assert the emitted reason.
- `node scripts/test-workflow-scripts.mjs` covers the new rung and passes.

**Gate** — what must pass before approval:

- The 403 body is captured from a real web session, not copied from the report.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` clean.


## Considerations

- Keying on the message string alone is brittle; keying on 403 alone may be too broad if the
  same status covers other refusals. The reproduction in step 1 is what settles it.
- This ticket deliberately leaves the pull request open. Making it merge is the other ticket's
  question, and shipping the honest reason is worth doing whichever way that one lands.


## Final Report

**Done.** The ladder is a third rung, and it moved out of `publish-tree-pr.sh` into its own
script to get there.

**The 403 was captured, not copied** (step 1's precondition). The `[Implement]` tick of
2026-08-23 07:33 UTC (session `cse_01MTFyJuBmo1GpmnJozsYHZi`) hit it on a real unit: a
`merge_policy: review` pull request — the route whose contract is *merge immediately* —
finished, green, and left open because the container's `PUT .../pulls/N/merge` was answered
`403 {"message":"Merging pull requests is not permitted for this session type"}`. Both halves
of the reporter's quote held.

**Which half the rung keys on, and why it is not a coin toss.** The message, with the status
behind it. 403 alone is *also* what a missing permission and a protected branch return, so the
status cannot carry this meaning by itself — a rung keyed on 403 would swallow two different
next actions into one word. The sentence can carry it. The brittleness the Considerations
worried about is real and is answered by **ordering**: the generic `merge_forbidden` rung sits
directly behind, so an upstream rewording degrades to *"a 403, still not a fault in the
change"* rather than to `merge_failed`. The class is never mistaken for a defect either way.

**It became `branching/scripts/merge-reason.sh`** — a pure function over the response text, no
network, no git, no state. Not tidiness: the ladder was inline, so the only way to exercise a
rung was to make a real merge fail against a real remote, which the hermetic suite may not do.
Pinning it would have meant a regex over the source — the prose-pinning this repository refuses.
Pulled out, all five rungs run for real in the suite. `publish-tree-pr.sh` keeps no second copy,
and the one source assertion left is that the call exists, because what that protects is a call
and not a wording.

The five reasons are five different next actions, which is the whole argument against one
`merge_failed`: `merge_not_allowed` (405 — look at the pull request), `head_moved` (409 —
re-read and retry), `session_type_cannot_merge` (the execution class; the pull request is fine
and another caller can merge it unchanged), `merge_forbidden` (any other 403 — a person must
change something outside the pull request), `merge_failed` (unclassified, and honest about it).

**Verification.** `node scripts/test-workflow-scripts.mjs` — **3426 passed, 0 failed**, read
from the log's own tally rather than the exit code. `build.mjs` and `verify.mjs` clean; the
generated bundle carries `merge-reason.sh` into all six skill closures that ship
`publish-tree-pr.sh`.

**What this ticket deliberately did not do**, exactly as its Overview said: it changes no
transport and leaves the pull request open. Making it merge was the sibling ticket's question,
and shipping the honest reason was worth doing whichever way that one landed. It landed yes,
narrowly — but this rung is what that answer is keyed on, so the order was load-bearing rather
than incidental.
