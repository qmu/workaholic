---
created_at: 2026-07-16T16:30:07+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.5h
commit_hash:
category: Changed
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

## Final Report

Two of the four validations closed with recorded evidence in this session (2026-07-17, drive on `work-20260716-152211`); the other two name their venue. No fix rides in this commit — evidence only, per the Quality Gate.

- **(3) Codex runtime — VALIDATED.** `codex plugin marketplace upgrade workaholic` refreshed the snapshot (codex-cli 0.142.4); `codex plugin add workaholic@workaholic` installed `workaholic@1.0.95` into `~/.codex/plugins/cache/workaholic/workaholic/1.0.95/` cleanly; a live `codex exec --sandbox read-only` in this repo (session `019f6b86-0c91-7f23-a6c4-a1800282508b`) printed `hook: UserPromptSubmit` → `hook: UserPromptSubmit Completed` and exited normally — Codex **executes** the plugin's hooks after parsing, and workaholic's completed without error. Two environment-side observations, recorded here (not workaholic defects, no tickets minted): the developer's `~/.codex/config.toml` still enables the obsolete-named `standards@workaholic` plugin, and the unrelated `webwright` local marketplace is broken (missing manifest), which makes bare `codex plugin list` fail until removed.
- **(4) Living layout migration — VALIDATED,** in the consumer repos' own histories as the concern demanded: two consumer repositories' commits (`0fb13c9b` and `2ad863443`, in their respective repos) record the migration relocating flat `missions/<slug>/` dirs into `missions/active/<slug>/` via history-preserving renames (R100). Every consumer repo on this machine with missions (six were inspected read-only) is now on the nested layout; no flat-layout repo remains to migrate.
- **(1) Mission-authorized `/drive` — PENDING, venue named:** rides the developer's first real `/mission` replan session (this drive was per-ticket-approved, so it cannot stand in). The evidence lands as that session's story/report artifacts.
- **(2) End-to-end `/trip` — PENDING, venue named:** rides the next real `/trip` run; no trip was in flight this session.

### Discovered Insights

- **Insight**: Codex honors Claude Code's hook event names at runtime — a `codex exec` turn fired `UserPromptSubmit` and reported completion, so `hooks.json` is not merely parsed for compatibility; the hooks actually run under Codex.
  **Context**: Hook scripts must therefore stay POSIX-clean and side-effect-safe under BOTH agents — a Claude-only assumption inside a hook body would now break Codex sessions in consumer repos.
- **Insight**: A targeted `codex plugin marketplace upgrade <name>` succeeds even when another configured marketplace is broken, while the bare `list` commands fail on the first broken entry.
  **Context**: When a Codex plugin operation fails wholesale, check for an unrelated broken marketplace before suspecting this repo's manifests.
