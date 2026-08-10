---
created_at: 2026-08-10T13:07:05+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: configure-routines-automatically-via-remotetrigger
merge_policy:
---

# Restate the manages-nothing ruling as session-class-dependent

## Overview

Once the sibling ticket lands the direct-apply path, every doc still stating "`/setup-routines` manages nothing" unconditionally is wrong for the session class that now applies wiring directly. Restate the ruling everywhere it appears as session-class-dependent (interactive session with `RemoteTrigger`: applies directly; routine-fired session without it: sheet-only fallback), without weakening the parts of the ruling that still hold for the routine-fired class.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `CLAUDE.md` — `/setup-routines` row states the ruling and its two re-verifications (2026-08-06, 2026-08-10)
- `plugins/workaholic/skills/workaholify/SKILL.md` — §5 *Scheduled routines*
- `plugins/workaholic/skills/workaholify/reference/routines.md` — the account-management-surface retirement history
- `plugins/workaholic/commands/setup-routines.md` — the command's own one-line description of the ruling

## Implementation Steps

1. Grep the repo for "manages nothing" and every paraphrase of the unconditional claim.
2. Rewrite each to state the session-class split explicitly, citing this mission's ticket that implements the direct-apply path.
3. Keep the *reasoning* that motivated the original ruling (the account-management surface's measured cost, digest-gate retirement) intact — only the scope of the conclusion changes, not the evidence behind it.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- No doc claims `/setup-routines` "manages nothing" without the session-class qualifier.
- The prior ruling's evidence (measured costs of the retired account-management surface) is preserved, not deleted.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "manages nothing" plugins/ CLAUDE.md` shows only qualified statements.
- Manual read-through of the touched files.

**Gate** — what must pass before approval:

- Runs after (or in the same PR as) the sibling direct-apply ticket, so the doc change describes shipped behavior, not a promise.

## Considerations

This ticket is pure documentation and should be small; if the direct-apply ticket's scope shifts during review, keep this one in lockstep rather than letting the docs drift ahead of the code — the exact failure mode `CLAUDE.md`'s own "Update the docs in the same change" rule exists to prevent.
