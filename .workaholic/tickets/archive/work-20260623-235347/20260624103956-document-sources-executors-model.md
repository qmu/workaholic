---
created_at: 2026-06-24T10:39:56+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.5h
commit_hash: 183ac87
category: Changed
depends_on: [20260624103955-trip-context-aware-queue-execute-mode.md]
---

# Document the unified "sources × executors" model in CLAUDE.md and README

## Overview

With `/trip` now context-aware (prerequisite ticket), the drive/trip relationship has a clean single framing worth documenting so users and future agents reason about it correctly: **the ticket is the spine; sources fill the queue, executors drain it.**

- **Sources** (write to `tickets/todo/`): `/ticket` (human-directed, with discovery) and a trip's **Decomposition** gate (design → tickets).
- **Executors** (drain `todo/ → archive/`): the **drive executor** (solo main-agent + developer approval) and the **trip executor** (three-agent team + three-perspective QA).
- **Entry is context-aware**: `/drive` always drives; `/trip <instruction>` designs then drives; `/trip` over a populated queue trip-drives it. Switching executors mid-queue works because both read the same `todo/`.

Document this in `CLAUDE.md` and `README.md`.

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each before writing.

- `workaholic:implementation` / `policies/objective-documentation.md` — `CLAUDE.md`/`README` must describe the actual behavior shipped by the prerequisite ticket, not aspirational intent.
- `workaholic:implementation` / `policies/directory-structure.md` — keep the `trips/` (rationale) vs `tickets/` (contract) split accurate in the documented architecture.

## Key Files

- `CLAUDE.md` - Extend the existing `/trip` ↔ `/drive` convergence note with the sources × executors framing and the context-aware `/trip` entry table.
- `README.md` - Add the sources × executors model to the `/trip` / development-workflow section so the two commands read as one system.

## Related History

Documents the model completed by the prerequisite `20260624103955-trip-context-aware-queue-execute-mode.md` and the earlier trip-integration series.

## Implementation Steps

1. In `CLAUDE.md`, expand the `/trip`↔`/drive` convergence paragraph (added by the Decomposition series) with the sources × executors framing and a short context-aware `/trip` entry table (instruction→design-first; populated queue→trip-drive; empty→nothing to do).
2. In `README.md`, add the sources × executors model near the `/trip` explanation so `/ticket`, `/drive`, and `/trip` read as one ticket-centric system.

## Considerations

- Documentation only; depends on the prerequisite ticket so the prose describes real behavior (`workaholic:implementation` / objective-documentation).
- Do not duplicate the full protocol into the docs — summarize and point at `trip-protocol`.
