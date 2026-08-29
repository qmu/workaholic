---
created_at: 2026-08-29T14:00:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff: 
feedback: 20260829121658-run-the-loop-s-own-proofs-on-every-turn.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
---

# Make the archive gate's mission close actually fire

## Overview

**Minted mid-run on 2026-08-29** while driving `run-the-loop-s-own-proofs-on-every-turn`,
whose own eight tickets archived with every acceptance item ticked and the queue drained —
and which the archive gate then left `active`.

`drive/scripts/archive.sh` closes a mission it can prove finished by reading
`mission/scripts/progress.sh` and `mission/scripts/queue-size.sh` and calling
`close.sh <slug> achieved`. It passes **`$MISSION_FILE`** — a path — to `progress.sh`, and
that reader answers:

```
{"error": "not_found", "path": ".../missions/active/.workaholic/missions/active/<slug>/mission.md/mission.md"}
```

on exit 1, because `missions_root_for_arg` + `mission_resolve` treat the argument as a
**slug** and concatenate it under the missions root. `progress.sh`'s own usage line says it
takes "a path to a mission.md, or a bare slug"; the path half does not work.

The consequence is that the gate's `M_CHECKED` is empty on every archive, the
"an unreadable reader is NOT a proof" branch fires, and **the archive-gate close has never
once fired** — which is why `/moderate`'s `closable-missions` step keeps finding
finished-and-open missions (eleven of them accumulated by 2026-08-24, found only because a
since-retired hook printed them on every prompt).

Reproduced on 2026-08-29 against this repository:

```
$ sh mission/scripts/progress.sh .workaholic/missions/active/<slug>/mission.md
{"error": "not_found", ...}                       # exit 1
$ sh mission/scripts/progress.sh <slug>
{"checked": 3, "total": 3, "unlinked": 0}         # exit 0
```

**Which side to fix is the decision this ticket carries**, and both sides are real: either
`progress.sh` honours the path form its own usage line promises (one reader gains a shape
it already documents, and every caller keeps working), or `archive.sh` passes the slug it
already holds in `$MISSION_SLUG` (one line, no reader changes). Prefer fixing the
**reader**, because its documented contract is the thing that is false, and a caller
reading the docs would make the same mistake again.

## Policies

- `workaholic:implementation` / `policies/error-handling.md` — a reader whose documented shape refuses is worse than one that never claimed it
- `workaholic:implementation` / `policies/testing.md` — the guarantee is a fact a change can lose, not a claim in prose

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` — the close gate; passes
  `$MISSION_FILE` to `progress.sh` and `$MISSION_SLUG` to `queue-size.sh`
- `plugins/workaholic/skills/mission/scripts/progress.sh` — the reader; its usage line
  promises the path form
- `plugins/workaholic/skills/mission/scripts/lib/resolve.sh` — `missions_root_for_arg` and
  `mission_resolve`, where the path form is lost
- `scripts/test-workflow-scripts.mjs` — where the fix is pinned: an archive that leaves a
  mission provably finished must close it

## Implementation Steps

1. Reproduce both invocations above, and confirm from `lib/resolve.sh` which of the two
   helpers drops the path form.
2. Fix the chosen side. If the reader: make `missions_root_for_arg`/`mission_resolve`
   accept an existing path to a `mission.md` and return it unchanged, leaving the slug form
   byte-identical. If the caller: pass `$MISSION_SLUG`, and say in the commit why the
   reader was left alone.
3. Check every other caller of `progress.sh` for the same confusion — a second caller
   passing a path is the same defect wearing a different name.
4. Pin it: a hermetic test archiving the last ticket of a fixture mission whose acceptance
   is complete must leave that mission **closed**, and one whose acceptance is not complete
   must leave it untouched. The pin has to assert the CLOSE, not the reader's return shape,
   or the same defect can come back through a refactor that keeps the shape.
5. Leave the "unreadable reader is not a proof" branch exactly as it is — it is correct and
   is what turned this defect into silence rather than a wrong close.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Archiving the last ticket of a mission whose acceptance is fully checked, with an empty
  queue, closes that mission `achieved` through `close.sh`.
- A mission that does not satisfy the arithmetic is left untouched, and an unreadable
  reader still leaves it untouched.
- `close.sh` remains the only writer of an end state, and only `achieved` is ever passed.
- Every existing caller of `progress.sh` is unchanged in behaviour.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic fixture archive over a complete mission and over an incomplete one.
- `node scripts/test-workflow-scripts.mjs` green.

**Gate** — what must pass before approval:

- Both fixture archives behaved as stated, and the suite is green.

## Considerations

- The tempting quick fix is the caller's one-line change. It works, and it leaves a reader
  whose usage line is false — which is what produced this defect in the first place.
- This changes when an unattended run closes a mission, across every consuming repository.
  That is the intended behaviour and has been since 2026-08-23; what changes is that it
  starts happening. `/moderate`'s `closable-missions` step is the backstop and stays.
