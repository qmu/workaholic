---
created_at: 2026-09-08T12:41:52+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-incremental-across-messages-threads-and-mentions
merge_policy:
verification_handoff: 
claim: work-20260910-125058
---

# Declare and audit a repository-local Slack transport binding

## Overview

Define one repository-local transport declaration that Codex and Claude instruction surfaces can both carry, and make `/workaholify` scaffold and audit it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/` — scaffold and audit the declaration.
- `plugins/workaholic/skills/work/` — read applicable root and nested instructions before transport selection.
- `plugins/workaholic/skills/transport/` — parse the binding without assuming one instruction filename.

## Implementation Steps

1. Discover current instruction-file and Slack destination conventions across Codex and Claude hosts.
2. Define a copyable schema for workspace/team, channel name and ID, preferred QFS mount/account, expected sender, operations, and fallback order.
3. Make `/workaholify` create or audit an AGENTS.md-compatible declaration while preserving existing instructions.
4. Test root/nested precedence, missing declarations, and conflicting declarations.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Both `AGENTS.md` and supported `CLAUDE.md` instructions can declare the same binding.
- `/workaholify` reports missing or ambiguous fields without inventing identities.

**Verification method** — the commands/tests/probes that prove them:

- Run workaholify and transport parser fixtures for each instruction surface and precedence case.

**Gate** — what must pass before approval:

- A repository receives one judgeable binding schema, not host-specific parallel contracts.

## Considerations

Nested instruction precedence must follow the host's applicability rules without silently merging incompatible destinations.

## Final Report

Development completed as planned — **and the implementation was already on the base when this
ticket was driven**, so the work of this drive was to verify each acceptance criterion against
the tree rather than to write the mechanism a second time.

The declaration, its one reader, its precedence and the `/workaholify` scaffold and audit landed
2026-09-08 under mission `make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage`
— a differently-named mission answering the same ask as this ticket's own (now closed)
`make-slack-intake-incremental-across-messages-threads-and-mentions`. Every acceptance criterion
was re-proved here by fixture rather than accepted on the strength of that record.

**Criterion 1 — both `AGENTS.md` and supported `CLAUDE.md` can declare the same binding.** Proved
against throwaway roots through `transport/scripts/read-declared-binding.sh`: an `AGENTS.md`-only
root and a `CLAUDE.md`-only root each resolve the same schema to the same `binding` object, and
`apply-slack-binding.sh --file CLAUDE.md` writes a declaration the same reader resolves. Two
sources at one depth that disagree settle **no value at all** — `reason:
contradictory_declaration`, `binding: {}`, both `conflicts[]` named with their sources — rather
than guessing which instruction file the operator meant. An undeclared root answers
`declared: false, reason: no_declaration`, the ordinary answer, not an error.

**Criterion 2 — `/workaholify` reports missing or ambiguous fields without inventing identities.**
`workaholify/scripts/check-slack-binding.sh` was exercised over five fixtures and named each
finding by its own word: `not_declared`, `incomplete_declaration` (with `missing: ["workspace"]`),
`contradictory_declaration`, `invalid_declaration` (with the offending `operations` value),
`unknown_key:bogus_key` — a typo being silent otherwise — and `unverifiable_sender`. Nothing is
invented: `unverifiable_sender` fires precisely where no `sender_id` was declared, and the audit
reports the absence instead of filling one in. The scaffold half was proved too:
`apply-slack-binding.sh` appends one fenced block to an existing `AGENTS.md` leaving the
operator's own lines byte-identical above it, and a second run refuses `already_declared` with
nothing written.

**Steps 1-4** are therefore all discharged: the schema is
`transport/scripts/schemas/binding.schema.json`; `/workaholify` both creates and audits an
`AGENTS.md`-compatible declaration while preserving existing instructions; and root, nested,
missing and conflicting cases are each covered — by the fixtures run here and by the ten rows of
`scripts/tests/agentic-loop/slack-binding.test.mjs`, which pass.

No gap was found and no line of the mechanism was changed. This drive's only repository change
outside the archive is one minted ticket (below).

### Discovered Insights

- **Insight**: `check-slack-binding.sh` takes its repository root **positionally**
  (`check-slack-binding.sh [repo-root] [--scope RELDIR]...`) while its sibling
  `apply-slack-binding.sh` takes it as `--root REPO`. Passing `--root` to the first is not an
  error — its `case "$ROOT" in --*) ROOT=. ;;` guard silently defaults the root to `.` and the
  flag is then consumed by the option loop.
  **Context**: the audit then answers about **the current repository** rather than the one the
  caller named, which reads as a plausible result and is a different question. Two sibling
  scripts in one skill with two root conventions is a trap for any caller that scripts both;
  worth knowing before writing a third. The guard itself is deliberate — a leading flag must not
  be mistaken for a path — so the cost is the inconsistency, not the defaulting.

- **Insight**: this ticket and its sibling were queued against a mission that was **closed** under
  a different slug while both remained in `todo/`, so the survey offered them as loose backlog
  long after their substance had merged.
  **Context**: `mission_closed` on the survey row is the signal, and it is the shape to expect
  whenever an ask is re-specificated under a second title — the earlier record's tickets outlive
  the mission they named. The repository already refuses to retire a ticket it judges mooted (a
  reading about behaviour, not a file test), so verifying and archiving, as done here, is the
  sanctioned way such a ticket leaves the queue.
