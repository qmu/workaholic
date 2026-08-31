---
created_at: 2026-08-31T20:09:59+09:00
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-questions-readable-and-close-them-in-the-thread
merge_policy:
verification_handoff: 
---

# Rewrite each step's question to that contract

## Overview

Apply the contract to every question the tick actually asks. Today each step's section in
`moderate/reference/workflow.md` specifies its own heading and body, and most lead with
the subject's identifier because that is what the step holds: `undrivable-unit:<path>`,
`stalled-unit:<unit>`, `retire-blocked:<unit>:<word>`, `base-red:<commit>`,
`direction-*:<slug>`, `operator-pull:<number>`, `catchup-blocked:<unit>`,
`raced-unit:<unit>`, `handoff-unit:<unit>`, `undelivered-unit:<unit>`,
`unanswered-ask:<channel>:<ts>`, `drill-failing:<drill>`, `strategy-pace:<slug>`.

Wording only, across every step, in one change — so the operator meets one voice rather
than thirteen.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/reference/workflow.md` — every step section that
  specifies a question's heading and body.
- `plugins/workaholic/skills/moderate/SKILL.md` — where it summarises what a step asks.
- `CLAUDE.md` — the `/moderate` step table's notes, updated in the same change.

## Implementation Steps

1. For each question-asking step, rewrite the specified heading so it opens with the plain
   fact — what happened to what — and carries the identifier after it. The named details
   that already ride the heading (a direction's stage, its residue, its leaving, the days
   left, the branch a retirement could not delete) stay in the heading.
2. Rewrite each body to name the single act asked of the addressee, inside the existing
   bound. Where the question genuinely has two options, keep both — that clause of the
   shape is unchanged.
3. Leave every key expression, cap, hold, addressee derivation and age reading
   byte-identical. Touch no script.
4. Re-read the result as the addressee: each question must stand alone without the tick
   log, the run report or the repository open.
5. Update `CLAUDE.md` and `workaholic:moderate` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every question-asking step's spec leads with the plain fact and names its act.
- No key, cap, hold, addressee or gate expression changed anywhere.
- The named details that rode the heading still ride the heading; no body grew past the
  bound.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`.
- `git diff --stat` shows only `reference/workflow.md`, `SKILL.md` and `CLAUDE.md`.

**Gate** — what must pass before approval:

- Each rewritten question is checked against the contract clause by clause, and the ones
  that could not be made self-contained inside the bound are named rather than stretched.

## Considerations

- Changing a body cannot re-ask a question: `already_asked` keys on the step id derived
  from the key by `lib/question-id.sh`, never on the text. That is what makes a sweep of
  every question's wording safe to do in one change.
- A question whose subject genuinely cannot be explained in one sentence is a signal about
  that step's finding, not about the bound; name it here rather than lengthening the post.
