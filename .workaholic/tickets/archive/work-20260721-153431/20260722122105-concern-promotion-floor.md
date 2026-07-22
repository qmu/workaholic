---
created_at: 2026-07-22T12:21:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 2h
commit_hash:
category: Added
depends_on:
mission:
---

# Concern promotion floor: the story keeps everything, the corpus promotes only what clears the bar

## Overview

The deferred-concern corpus grows append-only because there is **no bar on what becomes a durable concern** — `/report`'s section 6 invites "risks, trade-offs, limitations, and forward-looking suggestions", and `/ship` promotes every one of them into the tracked `.workaholic/concerns/` corpus. So a branch that notes five nice-to-haves adds five durable concerns, and the pile climbs to 100 while only ~30 are real risks. The fix is prevention, not disposal: rebalance by raising the bar at the moment a concern is *promoted*, not by building machinery to auto-close a pile after the fact.

This is a **dial, not a switch** — concerns are wanted, just not this many. The design separates two layers:

- **The story records every concern** (section 6 is unchanged — the branch's immutable record; nothing is lost).
- **The corpus promotes only what clears a floor** — the set that accumulates across branches and drives triage stays a curated ~20-30.

The floor is severity: `moderate`/`urgent` (a real risk you hit or clearly foresee will bite) are promoted; `low` (a nice-to-have, a speculative "we might also want", a thing noticed but not run into) stays in the story only. A genuinely-must-track low can opt in with `- **Keep:** true`. The floor is a knob (`CONCERN_PROMOTE_MIN`, default `moderate`).

**Demotion of already-tracked concerns is deliberately out of scope** — re-shelving an existing pile is a developer decision (like moving a ticket to icebox), never an unattended extraction side effect. This ticket stops the pile *growing*; shrinking an already-bloated corpus is a separate, developer-confirmed step.

## Policies

- `workaholic:development` / `qa-engineering` — the developer's looking-through is preserved: every concern is still recorded in the story and visible on the PR; only the durable-tracking bar changed.
- `workaholic:implementation` / `objective-documentation` — the gate leaves an auditable count (`story_only`) of what was left in the story rather than promoted.
- Backward compatibility — an already-tracked concern still updates in place regardless of severity; no existing concern is demoted or lost.

## Key Files

- `plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh` — the promotion gate (new concern below floor and not `Keep: true` → story-only, not written); `CONCERN_PROMOTE_MIN` knob; `story_only` count in the JSON.
- `plugins/workaholic/skills/report/SKILL.md` (§6 guidelines) — severity is the balance dial; set it honestly (the ticket-minting bar applied to concerns).
- `plugins/workaholic/skills/ship/SKILL.md` (§2-5) — document the floor and `story_only`.
- `CLAUDE.md` — the `.workaholic/` concern lifecycle note.

## Implementation Steps

1. Gate creation in `extract-deferred-concerns.sh` on `severity >= CONCERN_PROMOTE_MIN` (default `moderate`) OR `Keep: true`; leave sub-floor concerns in the story, count them as `story_only`.
2. Reframe §6 severity guidance so `low` = story-only, `moderate`+ = tracked, with the honesty caveat (don't inflate to force-track, don't drop to hide).
3. Document in ship SKILL and CLAUDE.md.
4. Tests + rebuild + verify.

## Quality Gate

- **Acceptance**: on a story with urgent/moderate/low/kept-low concerns, only the urgent, moderate, and kept-low are written to the corpus; the plain low is left story-only and counted; `CONCERN_PROMOTE_MIN=low` promotes all; an already-tracked concern still updates in place at any severity.
- **Verification**: `node scripts/test-workflow-scripts.mjs` green with the new promotion-floor fixtures (and the existing extraction/update/escalation tests still pass); `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs` pass; `outputs/` rebuilt.
- **Gate**: no existing concern is demoted or lost by this change (updates and the story record are untouched); docs in lockstep.

## Considerations

- To shrink an **already-bloated** corpus (an adopting repo at 100), a separate developer-confirmed demotion pass — low active concerns → archived-as-demoted, reversible and recorded — is the companion lever; it is intentionally not built here because auto-demotion crosses the developer-decision line.
- `Keep: true` is the escape hatch so the floor never silently drops a low concern that genuinely matters.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The corpus grew append-only because promotion (story section 6 → tracked corpus) had no bar at all — the same shape as ticket-minting before its "an observation is not an obligation" doctrine. Reusing that doctrine on the concern side (severity honesty + a promotion floor) is the prevention fix; the disposal machinery (corpus-wide judge, verify-command, staleness) was treating the symptom.
  **Context**: When a pile grows without bound, look for the missing gate at the *creation/promotion* seam before building disposal — the cheaper fix is upstream.
- **Insight**: Separating "recorded in the immutable story" from "promoted to the tracked corpus" lets the balance move without losing anything — low concerns stay in the branch's story forever, just out of the cross-branch triage set. Demotion of existing concerns stays a developer decision (icebox-shaped), so the gate only stops growth, never silently reshuffles history.
  **Context**: The story/corpus split is the general pattern for "keep everything, track only what clears a bar".
