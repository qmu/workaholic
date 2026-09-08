---
created_at: 2026-09-08T12:47:10+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: restore-the-mission-as-the-planning-merge-story-and-release-boundary
merge_policy:
verification_handoff: 
---

# Batch related asks into one standing mission plan

## Overview

Make mission formation a deliberate batching act: collect related small asks into one bounded hypothesis and append tickets while its experience can honestly hold them.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/` — mission formation, extend-before-mint, and batching window.
- `plugins/workaholic/skills/mission/` — bounded plan and ticket-set ownership.
- `plugins/workaholic/rules/workaholic.md` — canonical mission grain and release-boundary responsibility.

## Implementation Steps

1. Trace why one inbound issue currently publishes and triggers implementation immediately even when adjacent related asks are already visible.
2. Define when a batch opens, what relation admits another ask, and which observable condition closes formation without an arbitrary ticket count.
3. Keep each feedback reference while producing one ordered ticket set and one mission acceptance sketch.
4. Prove unrelated or urgent asks do not get trapped behind an incompatible mission.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Related small asks form or extend one real mission before implementation starts.
- The mission remains bounded by one experience and preserves every source reference.

**Verification method** — the commands/tests/probes that prove them:

- Test a related burst, an unrelated concurrent ask, a late compatible ask, and an incompatible extension.

**Gate** — what must pass before approval:

- No behavior depends on cautionary prose or a one-off issue exception.

## Considerations

The batching close condition must balance prompt work with enough observation to avoid per-message release churn.

## Final Report

The inbound issue page is now one mission-formation turn. While it contains an uncaptured or
recorded-but-unplanned ask, or an unmerged capture, `/infinite-development` allocates zero new
implement runners and processes the complete oldest-first page through `/specificate`. Compatible
asks extend the standing active mission; unrelated or urgent asks keep an independent unit. The
close condition is observable `formation_pending: false`, with no arbitrary delay or ticket cap.

### Discovered Insights

- Batching needs exclusion between intake and implementation, not a timer: the existing issue and
  branch facts say when formation has actually settled.

## Verify

Hermetic fixtures cover unplanned records, planned relations, proposal branches, empty pages and
numeric issue boundaries. The full workflow suite passed 6,830 tests.
