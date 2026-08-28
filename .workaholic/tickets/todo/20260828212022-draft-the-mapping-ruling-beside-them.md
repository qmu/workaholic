---
created_at: 2026-08-28T21:20:22+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: put-the-loop-s-standing-rulings-on-one-pull-request
merge_policy:
verification_handoff: 
---

# Draft the mapping ruling beside them

## Overview

PROPOSED. Five tickets stamped an unmapped address have been undrivable by every runner
since 2026-08-21, and the repair is one line a person must uncomment by hand on `main`.
Put that line, completed, into the same ruling pull request with the git history that
supports it — so the operator rules by merging rather than by editing the base.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `.claude/git-identities` — the mapping; the line is appended **live**, not as a comment
- `plugins/workaholic/skills/gather/scripts/identity.sh` — the mapping's **one reader**;
  its position and the file's `<login>=<canonical>[,<alias>...]` format do not move
- `plugins/workaholic/skills/workaholify/scripts/apply-bootstrap.sh` — writes the proposed
  line as a **comment** today; unchanged, and still the path for an unjudged address
- `plugins/workaholic/skills/moderate/scripts/` — the drafting caller from the previous
  ticket, extended to this second kind

## Implementation Steps

1. For an address **this run judged**, append the completed `<login>=<address>` line to
   `.claude/git-identities` inside the same publish tree, as a **live line** rather than
   the comment `apply-bootstrap.sh` writes.
2. State the **git history that supports the judgement** in the pull-request body — which
   commits carry that address and under which login — so the operator is ruling on evidence
   rather than on the machine's assertion.
3. An **unjudged** address keeps its comment and its `undrivable-unit` question. Nothing
   about `apply-bootstrap.sh` or `audit-identity-coverage.sh` moves.
4. The file's format does not move, and `identity.sh` stays its one reader — the appended
   line is exactly the shape the audit already proposes, with the login filled in.
5. Appending an address the mapping already names live is a **no-op**, reported as such;
   never a duplicate line and never a rewrite of an existing entry.
6. Cover in the suite: a judged address lands one live line; a re-run is byte-identical; an
   unjudged address leaves the file untouched.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A judged address appends exactly one live line; a re-run appends none.
- An unjudged address leaves `.claude/git-identities` byte-identical.
- No existing entry is rewritten or removed.
- `identity.sh` remains the only reader; no second parser is added.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `identity.sh` resolving the drafted address before and after, over a fixture.

**Gate** — what must pass before approval:

- The single-reader pin over `.claude/git-identities` still passes.

## Considerations

- Writing a live line rather than a comment is the whole point and also the risk: a wrong
  line makes work drivable by the wrong person. It is bounded by the fact that only the
  operator's **merge** lands it, which the next ticket makes the seam's rule.
