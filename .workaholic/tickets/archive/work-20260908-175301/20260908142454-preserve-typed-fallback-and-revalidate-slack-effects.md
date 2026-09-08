---
created_at: 2026-09-08T14:24:54+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-slack-intake-honor-its-declared-binding-and-complete-thread-coverage
merge_policy:
verification_handoff: 
---

# Preserve typed fallback and revalidate Slack effects

## Overview

Permit connector fallback only after a typed QFS capability, authorization, availability, or
reachability failure, preserving the declared destination and thread while naming the degraded route and sender evidence.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/transport/scripts/perform.sh` — enforce operation-specific route eligibility and revalidation.
- `plugins/workaholic/skills/transport/scripts/adapters/` — normalize QFS and connector failures without destination drift.
- `plugins/workaholic/skills/work/` — report startup and effect-time degradation in the originating loop.

## Implementation Steps

1. Enumerate the typed failures that may move an operation from QFS to a connector and refuse every untyped switch.
2. Carry workspace, channel ID, thread timestamp, and expected sender through fallback resolution and delivery evidence.
3. Revalidate when the binding changes or QFS fails before an effect, without treating connector success as proof of preferred-route configuration.
4. Test successful QFS effects, each permitted fallback class, preserved thread delivery, unknown sender identity, and retry reconciliation.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every fallback names the exact QFS failure and never changes the bound channel or thread silently.

**Verification method** — the commands/tests/probes that prove them:

- Run transport protocol fixtures across QFS success, unavailable capability, authorization failure, channel reachability failure, and connector fallback.

**Gate** — what must pass before approval:

- A successful connector effect remains explicitly degraded and cannot certify the preferred QFS sender.

## Considerations

Effect retries must keep the stable request ID and reconcile unknown delivery before any resend.

## Final Report

Development completed as planned.

`perform.sh` now leaves the preferred route only on one of four named failures — availability,
capability, authorization, reachability — and keeps the operation where it was declared on every
other. A read may also leave on a reachability failure; a write may not, because every write
class fails before `--commit` while `qfs_connector_failure` and `accepted_send_timeout` happen
after it and are reconciled rather than resent. The declared `fallback` order governs, an empty
one forbids every fallback, and workspace, channel ID, thread timestamp and expected sender ride
the handoff verbatim. Every result carries `route`, `degraded`, `degraded_from`,
`degradation_reason` and `preferred_route_verified`. `expected_declared_digest` refuses
`binding_stale` before any effect.

### Discovered Insights

- **Insight**: The untyped switch was not a missing feature, it was the default: `choose_route`
  fell to the connector whenever the QFS map was undescribed, so a repository whose preferred
  route was misconfigured ran on the fallback indefinitely with every report reading like a
  clean success.
  **Context**: The repair is mostly *reporting* — the same route is still chosen — which is why
  `preferred_route_verified` had to be a field rather than an inference from `status: ok`.
- **Insight**: The safe fallback boundary is `--commit`, not the transport. Classifying by
  failure *kind* alone would have let a post-commit timeout be resent over the token route,
  which is the double-post the outbox exists to prevent; the four permitted classes are exactly
  those the QFS adapter can only emit before the commit.
  **Context**: `qfs_connector_failure` looks like the most fallback-worthy word in the
  vocabulary and is the one word a write may never fall back on.
- **Insight**: `(.ok // true) != false` never fires for `{"ok": false}` — jq's `//` treats
  `false` as empty, so the adapter's `qfs_preview_refused` guard read a refusal as an
  acceptance and went on to commit. It is the authorization rung of this ticket's own class
  table, so it was fixed here (`.ok != false`, the same tolerance for an absent field and an
  actual test of a present one) with a row proving the commit is never reached.
  **Context**: The same `// default` idiom guards boolean fields elsewhere in these scripts and
  is wrong wherever the meaningful value is `false`.
