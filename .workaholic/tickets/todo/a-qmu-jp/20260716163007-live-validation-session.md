---
created_at: 2026-07-16T16:30:07+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Four flows are proven only hermetically: run and record the live validations

## Overview

Promoted from four triaged deferred concerns (2026-07-16 triage-to-zero). Each
records the same honest state: the hermetic suite pins the script seams, but the
flow itself has never been observed end to end, and only a live run can close
it. This ticket is the checklist for that session; its deliverable is
**recorded evidence**, not code.

1. **`the-approval-free-drive-is-unproven`** — no recorded live run of a
   mission-authorized `/drive`: a real `/mission` interrogation, then `/drive`
   draining its queue with **zero** Step 2.2 prompts, plus one mid-run
   out-of-scope problem minting a ticket instead of stopping.
2. **`trip-unification-is-unproven-by-a`** — no recorded end-to-end `/trip` in
   either mode (design-first: Decomposition gate emits well-formed tickets and
   the per-ticket loop archives each; queue-execute: routing skips design and
   drives a pre-populated queue).
3. **`codex-hook-runtime-behavior-remains-unproven`** — `hooks.json` carries
   Claude-only `${CLAUDE_PLUGIN_ROOT}` paths and event names; what Codex does
   after a successful parse is unverified. Refresh the Codex plugin cache and
   confirm workaholic loads cleanly.
4. **`hermetic-tests-prove-migration-not-local`** — the mission living-layout
   migration has run only against throwaway fixtures; it needs one real
   consumer repo on the flat layout.

## Key Files

- `plugins/workaholic/skills/mission/scripts/drive-authorized.sh`, `skills/drive/SKILL.md` — the flow under test in (1)
- `plugins/workaholic/skills/trip-protocol/SKILL.md`, `commands/trip.md` — (2)
- `plugins/workaholic/hooks/hooks.json`, `.agents/plugins/marketplace.json` — (3)
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` (`missions_migrate_layout`) — (4)

## Implementation Steps

1. Run each validation in its real environment (this repo for 1–2, a Codex install for 3, a flat-layout consumer repo for 4).
2. Record each outcome where the corresponding concern said the evidence belongs: the drive/trip runs as story/report artifacts of that session; the Codex check as a note in the ship verification; the migration as the consumer repo's own history.
3. Anything a validation breaks becomes its own ticket through the normal path — this ticket never absorbs fixes.

## Policies

- `workaholic:planning` / `policies/verify-before-building.md` — verify with the real thing: these four are precisely the checks a hermetic suite cannot stand in for.
- `workaholic:implementation` / `policies/observability.md` — an unrecorded validation is indistinguishable from an unrun one; the deliverable is the evidence trail.

## Quality Gate

- Each of the four validations has either recorded evidence (where, when, what was observed) or a minted defect ticket naming what failed.
- No fix is bundled into this ticket's commit — it archives with evidence links only.

## Considerations

- (1) may naturally combine with the first real `/mission` → replan use the developer already plans; the replan ticket's own deferred live check can ride the same session.
- (3) depends on a Codex environment being available; if none is, record `blocked` with that named blocker rather than skipping silently.
