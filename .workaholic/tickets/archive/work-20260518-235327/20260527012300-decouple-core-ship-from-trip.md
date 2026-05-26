---
created_at: 2026-05-27T01:23:00+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: 143f112
category: Changed
depends_on:
---

# Decouple core:ship from trip (pure merge/deploy/verify)

## Overview

`/ship` is "context-aware" and currently entangles two unrelated concerns: (1) the **ship essence** — merge PR, deploy via `cloud.md`, verify — which is trip-independent, and (2) **trip lifecycle** — worktree gitignored-file sync, worktree cleanup, and "Drive or Trip?" context routing — which exists only because `/trip` runs in git worktrees. The ship command even preloads `core:trip-protocol`. This coupling blocks `core:ship` from joining the cross-agent-portable workflow set (ticket/drive/report/ship), because trip is a Claude-only Agent Teams feature that other agents cannot run.

This ticket separates the two: `core:ship` becomes a **trip-independent** skill (merge/deploy/verify only), and the worktree/trip-context handling moves to the trip side. This is the foundation that lets the later portability tickets treat `ship` like `drive`/`report`/`create-ticket`.

## Key Files

- `plugins/work/commands/ship.md` - Frontmatter preloads `core:trip-protocol`, `core:ship`, `core:branching` (line 5). Description says "with worktree cleanup for trips." Drop the `core:trip-protocol` preload here; keep `core:ship` + `core:branching`. The trip-context shipping path delegates to the trip side.
- `plugins/core/skills/ship/SKILL.md` - Core ship skill. The essence is at line ~12 ("Merge a pull request, deploy to production, and verify ... following `cloud.md`") — trip-independent. The trip coupling lives in: step 4 "Sync gitignored files (if worktree exists)" (line ~161), step 5 "Clean up worktree" (line ~162), the "Worktree Context" route (lines ~167-175), and the "Unknown Context" → "Drive or Trip?" branch (line ~180). Relocate/guard these so the core ship path has no trip/worktree assumptions.
- `plugins/core/skills/ship/scripts/find-gitignored-files.sh`, `sync-gitignored-files.sh` - Worktree-only helpers. These belong to the trip lifecycle, not ship essence. Move them to the trip side (or a clearly trip-scoped location) or keep them but invoke only from the trip-ship path.
- `plugins/core/skills/trip-protocol/SKILL.md` - Destination for the trip-ship lifecycle (worktree sync + cleanup) that ship sheds.
- `plugins/core/skills/branching/scripts/cleanup-worktree.sh`, `list-worktrees.sh` - Worktree mechanics used by the trip-context path.

## Related History

- [20260527000801-reorganize-skill-dependencies-for-self-containment.md](.workaholic/tickets/archive/work-20260518-235327/20260527000801-reorganize-skill-dependencies-for-self-containment.md) - Reorg design; the portability goal that motivates decoupling ship.
- [20260525205530-audit-claude-specific-refs-in-portable-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205530-audit-claude-specific-refs-in-portable-skills.md) - Established which skills are mechanism-bound vs portable.

## Implementation Steps

1. **Define the ship essence as trip-independent.** In `core:ship`, isolate the merge → deploy(`cloud.md`) → verify → carry-over-extract → summarize flow so it makes no reference to worktrees or trip. This becomes the path every agent can run.
2. **Move worktree sync + cleanup to the trip side.** Relocate the "Sync gitignored files" and "Clean up worktree" steps (and `find-gitignored-files.sh`/`sync-gitignored-files.sh`) into `core:trip-protocol` (or a trip-ship subsection). The drive-context ship path no longer mentions them.
3. **Relocate context routing.** The "Worktree Context" route and the "Drive or Trip?" disambiguation are trip-aware orchestration. Keep them in the Claude-only `/ship` command (or trip side), not in the portable ship essence. On non-trip/other agents, ship runs the essence directly against the current branch's PR.
4. **Drop `core:trip-protocol` from `/ship` frontmatter.** `/ship` preloads `core:ship` + `core:branching`; the trip-ship path (if invoked in Claude Code) pulls trip-protocol only when a worktree/trip context is detected.
5. **Verify the drive-context ship path** still merges/deploys/verifies correctly with no worktree present (the common case), and that the trip worktree-cleanup path still works when a worktree exists.

## Considerations

- **No behavior loss in Claude Code.** Trip shipping (worktree sync + cleanup) must still work end-to-end when invoked in Claude Code on a trip worktree — it just lives on the trip side now. This is a reorganization, not a feature removal.
- **Carry-over extraction stays in ship essence.** `extract-carryover.sh` (sections → `.workaholic/concerns/`) is part of the ship essence, not trip-specific; keep it on the portable path.
- **This unblocks ship's portability** but does not itself make ship portable — script self-containment (build step) and agent-neutral prose are later tickets. Scope here is purely the trip/ship separation.
- **`Config`-layer architecture change** governed by CLAUDE.md. No runtime change to what ship does; only which skill owns which step.

## Final Report

Development completed. `core:ship` is now the trip-independent essence (guards → pre-check → merge → extract-carryovers → deploy → verify → summarize, on the current branch), with §5 rewritten from the old context-routed "Route by Context" into a single linear Ship Flow. `find-gitignored-files.sh` and `sync-gitignored-files.sh` were `git mv`d to `trip-protocol/scripts/`. `core:trip-protocol` gained a **Trip Ship** section (worktree gitignored-sync + cleanup + worktree/unknown context routing) that wraps the `core:ship` Ship Flow, plus two rows in its Shell Scripts table. The `/ship` command now performs context detection and routes: `work` → `core:ship` Ship Flow; `worktree`/`unknown` → `core:trip-protocol` Trip Ship. Verified: no dangling references to the moved scripts under the old `ship/scripts/` path, and the only `worktree`/`trip` mentions left in `core:ship` are the intentional pointer sentences.

### Deviation from Implementation Step 4

The step said "drop `core:trip-protocol` from `/ship` frontmatter … pull it only when a worktree/trip context is detected." Kept the preload instead: Claude Code skills are preloaded via frontmatter and cannot be loaded conditionally mid-run, and the command's worktree route needs the Trip Ship section in context. This does not compromise the decoupling goal — `core:ship` itself has zero trip dependency (other agents invoke it directly), and `/ship` is the Claude-Code-only work-plugin command, so its trip-protocol preload is harmless. For the common work-context path, trip-protocol is simply unused.

### Discovered Insights

- **Insight**: ship's trip coupling was never Agent-Teams logic — it was purely **git-worktree lifecycle** (gitignored-file sync + worktree cleanup) plus drive/trip context routing. Trips run in worktrees, so ship had absorbed worktree teardown. The merge/deploy/verify essence (`core:ship` §1-2) referenced neither trip nor Agent Teams.
  **Context**: This is why ship can join the portable set after a shallow reorganization, whereas `trip` cannot — trip's dependency is the Agent Teams runtime, ship's was only worktrees (a separable concern now owned by `core:trip-protocol`).
