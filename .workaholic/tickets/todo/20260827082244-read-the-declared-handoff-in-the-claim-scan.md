---
created_at: 2026-08-27T08:22:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-re-resuming-a-declared-handoff-unit
merge_policy:
verification_handoff: 
---

# Read the declared handoff in the claim scan

## Overview

Give `claims_scan` the input it lacks: whether the work still queued behind this claim was
declared undrivable here. `verification-handoff.sh` already answers that question from the
artifact, so nothing new is derived — the reading is simply carried to the one place that
never consulted it. This ticket adds the reading and the row field; the verdict that uses
it is the next ticket.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_has_work` already walks
  the branch tip for the unit's remaining tickets at both grains; the same walk answers this.
- `plugins/workaholic/skills/drive/scripts/verification-handoff.sh` — the one reader of the
  field; it takes ticket files or a mission and is a pure read.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the row's consumer and the
  reporting surface.

## Implementation Steps

1. Re-run the previous ticket's fixture and confirm it still reproduces before touching
   anything.
2. Add `claims_declared_handoff`, deriving from the branch tip — never the working tree —
   whether any ticket still queued for this unit declares a non-empty
   `verification_handoff:`. Read it through `verification-handoff.sh`, never by parsing
   frontmatter again: a second parser of one field is what this repository forbids by name.
3. Answer at **both grains**, as `claims_has_work` already does: a batch claims its ticket
   files; a mission claims only `mission.md`, so the remaining work is the tickets at the tip
   that name the mission. A mission's own `verification_handoff:` counts, since any member
   declaring it carries the whole unit.
4. Keep it **offline**: a `git ls-tree`/`git show` against the fetched ref, no network call,
   so every existing verdict stays byte-identical on a run with no origin.
5. Report it on the row and in `list-claims.sh`'s JSON. Respect the row's no-empty-middle-field
   rule — the artifact list stays last.
6. A read that cannot be made answers `false` and is reported, never guessed: an unreadable
   declaration must not invent a handoff any more than it invents its absence.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `claims_declared_handoff` answers `true` for the fixture's declared unit and `false` for
  an otherwise identical unit with the field empty, at both the batch and the mission grain.
- No verdict changes in this ticket: every existing row reads exactly as it did.
- No network call is added; an offline run answers identically.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the previous ticket's fixture plus a case per
  grain and a case for the empty field.
- A run with the remote unreachable produces byte-identical verdicts to one before this
  change.

**Gate** — what must pass before approval:

- The suite passes and the diff adds no second parser of `verification_handoff:`.

## Considerations

- The declaration is read from the **remaining queued** work, not from the archived work,
  which is what makes the reading self-releasing: once the declared ticket is driven, the
  same reader answers `false` with nothing stored anywhere.
- `claims_has_work` is the model to follow for the grain split; deriving the ticket set a
  second way would give the protocol two answers to one question.
