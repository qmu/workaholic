---
created_at: 2026-08-29T10:25:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
claim: work-20260829-102134
---

# Resolve a unit's stems through an archived mission

## Overview

MINTED mid-run by `/implement` at §3 of unit `batch-20260829093639`.
`drive/scripts/unit-feedback-stems.sh` answered `{"count": 0, "stems": []}` for a batch whose
two tickets both carried `mission: land-the-loop-s-own-work-when-the-base-moves-under-it`, and
whose mission carries two `feedback:` refs. The mission had been **archived** minutes earlier
by the archive gate, and the resolver did not follow the hop into `missions/archive/`.

The consequence is a notification defect, not a driving one: with no stem, `workaholic:notify`'s
lookup has nothing to search in case 2 and the run falls to case 4 — a new description root —
for a unit whose thread already existed and was two replies deep. So a follow-up unit's finish
line lands in a fresh thread rather than in the item's own, which is exactly what *one thread
per feedback item, carrying its whole life* exists to prevent.

**It bites precisely when it is most likely to matter.** The archive gate closes a mission the
moment its last ticket is archived, so any follow-up ticket driven after that — a ticket minted
mid-run, a repair queued against work that just landed — resolves through an archived mission
by construction. The run that found this drove exactly that shape.

This is a **reader** change and nothing else: no artifact gains a field, no relation is added,
and the `mission:` relation keeps its one parser.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — the resolver; read its
  header before changing where it looks.
- `plugins/workaholic/skills/mission/scripts/read-relation.sh` — the one parser of the
  many-valued `mission:` relation; this must go through it rather than beside it.
- `plugins/workaholic/skills/drive/SKILL.md` §3 — where the resolver is called.
- `plugins/workaholic/skills/notify/SKILL.md` — *One thread per feedback item*, case 2, which
  is what an empty stem set silently skips.

## Implementation Steps

1. **Reproduce.** A hermetic case: two tickets naming one mission, the mission moved to
   `missions/archive/<slug>/`, and the resolver asked for their stems. Assert today's
   `count: 0` before changing anything.
2. **Localize.** Establish whether the resolver looks only under `missions/active/` or whether
   the miss is upstream in the reader it composes — the fix belongs wherever the search is
   bounded, and nowhere else.
3. Resolve a mission slug through **`active/` then `archive/`**, the same precedence
   `mission/scripts/close.sh`'s callers already use, so a slug that moved mid-run keeps
   answering. Never a second walker of the relation.
4. Report an unresolvable slug by name rather than as an empty set — *found nothing* and
   *could not look* are different answers, and this repository repairs that collapse by name.
5. Check the other readers of that relation for the same bound before closing: a fix in one
   caller while a sibling keeps the narrow search is how the two drift.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose tickets name an **archived** mission resolves that mission's `feedback:` refs.
- A unit naming an active mission resolves byte-identically to today.
- A slug that resolves to no mission at all is named, not folded into an empty stem set.
- No artifact gains a field, and the `mission:` relation still has exactly one parser.

**Verification method** — the commands/tests/probes that prove them:

- The hermetic case from step 1, which must fail against today's tree.
- `node scripts/test-workflow-scripts.mjs`.

**Gate** — what must pass before approval:

- The reproduction fails before the change and passes after, and the active-mission path is
  asserted byte-identical rather than merely re-run.

## Considerations

- **The notification is never load-bearing**, so this is a correctness-of-reporting fix rather
  than a delivery one: the unit that provoked it merged and was announced. What was lost is the
  thread's continuity, which is the whole point of the model.
- The run that found this posted the finish line into the correct thread by resolving the stem
  **from the artifacts by hand** — the tickets' `mission:` and that mission's `feedback:` — which
  is a case-2 lookup with the hop made by a person rather than by the script. That is evidence
  the relation was resolvable, not a licence to leave the script unable to make it.
