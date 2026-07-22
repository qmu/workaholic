---
created_at: 2026-07-22T12:26:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 2h
commit_hash:
category: Added
depends_on: 20260722122105-concern-promotion-floor.md
mission:
---

# Demotion pass: shrink an already-bloated concern corpus, developer-confirmed and reversible

## Overview

The promotion floor (`20260722122105`, shipped) stops the tracked concern corpus from *growing* — new `low` concerns stay in the story. But it does nothing for a corpus that is **already** bloated: an adopting repo sitting at ~100 active concerns (mostly `low`) keeps all 100 until something reduces them. This ticket is that companion lever: a **demotion pass** that re-shelves existing sub-floor active concerns out of the tracked set, moving the corpus from ~100 toward the intended curated ~20-30.

**Demotion is not resolution, and it is a developer decision — never an unattended side effect.** A demoted concern is not closed (`resolved`/`accepted`), not deleted, and not lost: it is moved to `.workaholic/concerns/archive/` with `status: demoted` (reversible, recorded, still in git history and still referenced by its branch's story). It simply leaves the *active triage set* — the same "keep everything, track only what clears the bar" split the promotion floor established, applied retroactively. This is why it is developer-confirmed (icebox-shaped), not something `/ship` or `/report` does silently.

## Policies

- `workaholic:development` / `qa-engineering` — demotion is judge-proposes / developer-decides; the pass proposes the set and the developer confirms before anything moves. No concern leaves the active set without an explicit go.
- `workaholic:implementation` / `objective-documentation` — every demotion records its rationale (below-floor severity, age) and is reversible; the archive entry carries `status: demoted` and a changelog line, never a silent delete.
- Backward compatibility — idempotent and best-effort, like `migrate-concern-identity.sh`; re-running demotes nothing new.

## Key Files

- `plugins/workaholic/skills/report/scripts/` — a new `propose-demotions.sh` (read-only: lists active concerns at or below the demotion floor, with age, as a proposal) and a `demote-concern.sh` mutator (moves an active concern to `archive/` as `status: demoted` with a recorded reason; the reversible analogue of `close-concern.sh`).
- `plugins/workaholic/skills/report/SKILL.md` (Phase 1b triage) — surface the demotion proposal in the triage step so the developer confirms the set (mirrors the A+B compound flow: judge/script proposes, developer decides, mutator applies).
- `plugins/workaholic/skills/report/scripts/list-active-deferred-concerns.sh` — a demoted concern (in `archive/`, `status: demoted`) is excluded from the active listing exactly like `resolved`/`superseded`.
- `CLAUDE.md` — note the `demoted` status alongside `resolved`/`superseded` in the concern lifecycle.

## Implementation Steps

1. `propose-demotions.sh` — read-only proposal: active concerns whose severity is at/below the demotion floor (a knob, default `low`), reported with `concern_id`, severity, and `last_seen` age. Never mutates.
2. `demote-concern.sh <concern-id> "<reason>"` — move the concern to `.workaholic/concerns/archive/` with `status: demoted`, append the reason, git-stage; the reversible, evidence-recording analogue of `close-concern.sh`. Idempotent (a re-demote is a no-op).
3. Wire the proposal into `/report`'s Phase 1b triage as a **developer-confirmed** bucket (like compound merges): the developer confirms which proposed concerns to demote; nothing moves without confirmation.
4. `list-active` and the identity migration treat `status: demoted` as archived (excluded, never resurrected by extraction).
5. Docs in lockstep; tests; rebuild; verify.

## Quality Gate

- **Acceptance**: on a synthetic corpus of mixed severities, `propose-demotions.sh` lists exactly the at/below-floor active concerns and mutates nothing; `demote-concern.sh` moves a named concern to `archive/` as `status: demoted` with its reason, and a demoted concern no longer appears in `list-active`; re-extraction never resurrects a demoted concern; the mutator is idempotent.
- **Verification**: `node scripts/test-workflow-scripts.mjs` green with the new fixtures; `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs` pass; `outputs/` rebuilt.
- **Gate**: no concern is demoted without developer confirmation in the triage flow; every demotion records a reversible, evidence-bearing trail (`status: demoted` + reason + changelog); the proposal script never mutates.

## Considerations

- **Reversibility is the safety property**: because a demoted concern is archived (not deleted) and reversible, an over-eager demotion is cheap to undo — unlike `resolved`/`accepted`, which assert something about the work. Keep the two dispositions distinct: demotion is "not worth *tracking*", resolution is "no longer *applies*".
- The demotion floor (default `low`) is a knob; a repo that wants a tighter active set can raise it, but demoting `moderate` should stay deliberate — that is real risk leaving the active view.
- This pass is a one-time-ish cleanup lever; steady state is held by the promotion floor. A repo that has always had the floor may never need to run it.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: Demotion is `close-concern.sh`'s shape but with a different meaning — reversible re-shelving, not resolution. Keeping `demoted` a distinct status (not folding into `accepted`) is what lets the archive stay honest: `accepted` asserts a won't-fix decision about the work, `demoted` asserts only "not worth tracking", and the two must not blur.
  **Context**: The reversibility is the safety property that makes a developer-confirmed demotion safe to offer where an auto-close would not be.
- **Insight**: No wiring was needed to exclude demoted concerns from extraction — `extract-deferred-concerns.sh` already builds `archived_ids` from everything under `concerns/archive/`, so a demoted file's id is skipped for free. Reusing the archive/ location instead of a new "demoted/" dir inherited that exclusion.
  **Context**: When adding a disposition, prefer the existing archive/ sink so the no-resurrection invariant holds without touching the extractor.
