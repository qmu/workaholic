---
created_at: 2026-05-27T01:23:00+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
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
