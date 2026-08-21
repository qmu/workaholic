---
created_at: 2026-08-21T15:07:10+09:00
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
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

