---
type: Feedback
title: Command rename shipped without a version bump, so every routine resolves the stale plugin cache
kind: concern
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-19T11:55:51+00:00
author: a@qmu.jp
supersedes: 
---

# Command rename shipped without a version bump, so every routine resolves the stale plugin cache

The 2026-08-19 rename commit c821520 ("Rename commands to match their routine names", #535) renamed /propose -> /specificate and /housekeep -> /propose across commands/ and skills/, but touched no version file. The plugin version stayed at 1.0.190, which was already published and cached.

Measured this tick from a routine-fired [Propose] container:

- check-deps/scripts/plugin-src.sh returned src=/root/.claude/plugins/cache/workaholic/workaholic/1.0.190 (source: registry, src_immutable: true, degraded: true).
- That cache ships skills/housekeep + the OLD commands/propose.md ("Judge the ask in hand...").
- The checkout at the SAME version 1.0.190 ships skills/propose (the maintenance tick), skills/specificate, and the NEW commands/propose.md.
- plugin-src.sh resolves on two axes -- newest version wins, an equal version goes to the immutable candidate -- so at equal versions it deterministically prefers the STALE cache.

Consequence: the harness preloaded the pre-rename workaholic:propose skill, and the routine prompt's own documented fallback (run plugin-src.sh, take its src, read <src>/commands/propose.md) leads to the same stale copy. A [Propose] tick that followed either path would silently run the judge-the-ask workflow under the /propose name and never run the nine-step maintenance tick -- no log, no stuck-PR reminder, no check-in. [Specificate] is worse off still: the cache carries no commands/specificate.md at all.

This tick only reached the right workflow because the mismatch between the preloaded skill and the routine prompt's notification format (the stuck:<digest> post) was noticed and the checkout was read directly.

The immediate fix is the manual version bump CLAUDE.md already specifies (marketplace.json root + both plugins[].version, plugins/workaholic/.claude-plugin/plugin.json, .codex-plugin/plugin.json, then regenerate outputs/). The durable question is whether a behaviour-changing plugin edit should be allowed to land without one -- the equal-version tiebreak is correct in isolation, and it is exactly what turns a forgotten bump into stale code served to the whole routine fleet.
