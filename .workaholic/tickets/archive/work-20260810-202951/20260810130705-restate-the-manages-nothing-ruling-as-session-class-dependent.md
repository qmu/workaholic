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

## Final Report

Development completed as planned. Grepped the repository for "manages nothing" and its paraphrases and restated each surviving instance as session-class-dependent rather than unconditional: `CLAUDE.md`'s `/setup-routines` row now leads with the two-branch behavior (interactive session with `RemoteTrigger` → direct-apply; routine-fired session without it → unchanged sheet-only fallback) before restating the original 2026-08-06/2026-08-10 findings as the reason the *fallback* class still manages nothing; `reference/routines.md`'s *The schedule field* section now states that the interactive-session case it had left as an open question was subsequently checked and found true. `SKILL.md` §5 already carried the qualified statement from the sibling direct-apply ticket in this mission, so it needed no further change beyond what that ticket already made. The prior ruling's evidence (the 2026-08-06 digest-gate measured costs, the GitHub-trigger API-blindness finding) is preserved verbatim everywhere it was already recorded — only the scope of the conclusion changed, never the reasoning behind it.

### Discovered Insights

- **Insight**: "Manages nothing" was stated in this repository's docs as a property of the `/setup-routines` *command*, when it was actually a property of the *session class* every check to date happened to run in (the unattended, routine-fired class) — a distinction the docs only made explicit once a differently-classed session actually falsified the unconditional reading.
  **Context**: A finding measured from inside one session class does not automatically generalize to another; restating it as scoped from the start (rather than unconditional) would have made this ticket unnecessary.
