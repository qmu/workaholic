---
created_at: 2026-09-03T10:42:22+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# Compose the squash body at the agent-level merges

## Overview

Two merges are made by an agent rather than a script: the `review` route's REST merge, spelled in
`workaholic:drive`'s own text, and the `mcp__github__merge_pull_request` retry that follows a
`session_type_cannot_merge` refusal. Both land on the trunk and neither reads the composer, so a
fix confined to the scripts leaves the loop's most common merge path untouched.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — the `review` route, which spells the REST merge for
  the agent to compose.
- `plugins/workaholic/commands/implement.md` — the ceiling naming the connector retry.
- `plugins/workaholic/commands/specificate.md` — the same retry on the proposal path.
- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — the derivation both must
  read.


## Implementation Steps

1. Rewrite the `review` route's instruction so the agent reads `merge-commit-body.sh` and passes
   its `title` and `body` as `-f commit_title=` / `-f commit_message=` fields — named as fields to
   pass, with the values read and never spelled, exactly as `merge-method.sh` already is.
2. Do the same for the connector retry: `mcp__github__merge_pull_request` accepts a commit title
   and message, and the retry passes the composer's answer.
3. Carry the instruction into the two command ceilings byte-identical to its source, since a
   routine-fired run must read it to act.
4. Add a suite row asserting each of the two ceilings carries the instruction, in both directions
   — present where it belongs, absent where the search is not performed.
5. State in the run report which `source` the merge used, beside the existing merge outcome.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- The `review` route and the connector retry each pass a composed title and body.
- The two ceilings carry the instruction byte-identical to its source.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A `review` unit merged by an `/implement` run, read back with `git show --format=%B`.

**Gate** — what must pass before approval:

- Neither ceiling spells a body value; both name the reader.
- The suite pins the byte-identity of the carried text.


## Considerations

- This half is prose a session must follow, so nothing mechanical proves a run obeyed it. The
  suite can only prove the instruction is present, and the ticket says so rather than implying a
  stronger guarantee.

## Final Report

**Outcome**: implemented, with one step deliberately narrowed and the reason stated.

The `review` route in `plugins/workaholic/skills/drive/SKILL.md` now names the composer beside
`merge-method.sh`: the session runs `merge-commit-body.sh <n>` and passes its `title` and `body` as
`-f commit_title=` / `-f commit_message=`, with the values **read and never spelled** — the shape
`merge-method.sh` already established. The same instruction covers the connector retry, whose one
sanctioned attempt through `mcp__github__merge_pull_request` carries the composer's answer as its
commit title and message. §7's per-unit report line now names the `source` beside the merge outcome,
as evidence that moves no token.

**Step 3 reached one ceiling, not two, and this is a judgement rather than an oversight.**
`commands/implement.md` carries the instruction, because `/implement` is where both agent-level merges
happen. `commands/specificate.md` does **not**, because that command performs no merge at all: its
publication is merged by `publish-tree-pr.sh`, a script, which the sibling ticket already patched.
Inlining a merge instruction there would put a rule into a ceiling whose command never executes it —
the same shape the existing thread-lookup row forbids. Step 4's *absent where the search is not
performed* half is therefore asserted positively: the suite pins that `/implement` carries the composer
and that `/specificate` does not, so a later contributor adding one is making a visible decision.

**What nothing can check, named rather than implied**: an agent's merge call is composed at run time and
appears in no file, so the suite can only prove the instruction is present in the ceiling that will be
read. The assertion says so in its own comment; the ticket's Considerations predicted exactly this.

**Verified**: `node scripts/test-workflow-scripts.mjs`.
