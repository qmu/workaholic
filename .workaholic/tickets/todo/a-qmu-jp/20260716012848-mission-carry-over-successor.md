---
created_at: 2026-07-16T01:28:48+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Close a mission by carrying its remainder into a successor mission

## Motivation

A mission ends in one of two ways today, and the developer named a third that does not exist.

`close.sh` hard-validates its status argument and rejects anything outside `achieved|abandoned` with `invalid_status`; `mission/SKILL.md` documents it as *"the only sanctioned way to end a mission"*. So when a mission's tickets are driven and the honest verdict is *"most of this landed, the rest is still worth doing"*, there is nowhere to put it. The options are to mark it `achieved` while unchecked acceptance items remain — which quietly lies to a progress model whose whole claim is that progress is **computed, never a hand-set number** — or `abandoned`, which is worse and also false.

The developer's framing: *"by the end of the mission ticket lifecycle, we can judge whether we can close the mission or if we will carry it over by converting it into another mission."*

The judgement point is real and already exists in practice — it is the moment the queue empties. What is missing is the outcome that says: this mission is done **as framed**, and the remainder is a new mission that inherits what was not finished. Hand-rolling that today means creating a fresh mission and manually retyping the unmet criteria, which loses the lineage: the successor has no link back, and the predecessor's changelog does not record where its remainder went.

There is **no prior art anywhere in the corpus** — every "carry-over" hit refers to deferred concerns, an unrelated concept.

## Policies

- `design/history-structures` — the lineage is the point: a successor with no link to its predecessor loses the "who changed what, when" chain the mission model exists to keep. The predecessor's changelog must record where its remainder went.
- `implementation/objective-documentation` — the inherited acceptance items are carried as the verifiable statements they already are, not re-summarised into new prose that drifts from what was actually unmet.
- `implementation/coding-standards` — `close.sh` keeps its contract; the status set stays closed and validated, just larger by one.
- `implementation/directory-structure` — the successor lands in `missions/active/<slug>/` and the predecessor in `missions/archive/<slug>/`, per the existing split.
- `implementation/test` — the mutators are idempotent and hermetically tested; a carry-over is a state transition with an assertable before/after.

## Implementation Steps

1. **Add a third outcome to `close.sh`.** Keep the closed, validated set — it becomes `achieved | abandoned | carried`. `carried` requires a successor: either a title (mint the successor) or an existing slug (carry into it). Anything else still exits `invalid_status`.
2. **Decide what the successor inherits, and record the reasoning:**
   - **Unmet `## Acceptance` items** — the unchecked ones, verbatim, with their `(#<filename>)` ticket markers intact. Checked items stay with the predecessor: they were achieved *there*, and re-listing them would make the successor's computed progress claim work it did not do.
   - **`## Goal` / `## Scope`** — carried or re-interrogated? A carried-over mission that is a genuine continuation shares the goal; one that is a re-framing does not. Decide deliberately; if the successor should be interrogated, this ticket depends on the interrogation flow rather than duplicating it.
   - `gate_*` — the mission gate almost certainly carries, since the outcome being pursued is the same.
3. **Record the lineage in both directions.** The predecessor's `## Changelog` gets a line naming the successor (via `append-changelog.sh` — never hand-edit); the successor records what it came from. `design/history-structures` is the reason this is not optional: without it, the archive shows a mission that stopped and a mission that started, with nothing joining them.
4. **Decide the worktree question — the sharpest design call here.** `close.sh` today tears the mission's worktree down via `cleanup-mission-worktree.sh`. A successor pursuing the same outcome probably wants that worktree **kept** (it holds in-flight state and a port allocation) rather than destroyed and recreated under a new slug. But `.worktrees/<slug>` is keyed 1:1 to a mission by `slug.sh`, so keeping it means either the successor adopts the directory under the old slug (breaking the 1:1 naming the whole model relies on) or the worktree is renamed/recreated. **Neither is obviously right.** Investigate `adopt-worktree.sh` and `reset-mission-worktree.sh` — the primitives may already exist — and if no clean answer emerges, say so and carry over *without* the worktree rather than inventing a fragile aliasing scheme.
5. **Docs in the same change**: `mission/SKILL.md` (the outcome set and the lifecycle), `commands/mission.md`'s `close` branch (which today offers a two-way `AskUserQuestion` — it becomes three-way), CLAUDE.md's `/mission` row (*"close one (achieved/abandoned)"* becomes false), `README.md`, `.workaholic/README.md`.
6. `node scripts/build-plugins/build.mjs` — `close.sh` and `mission/SKILL.md` are bundled (scripts **six times**). Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria** (hermetic assertions in `scripts/test-workflow-scripts.mjs`, extending the existing `close.sh` coverage around the living-migration/close section):

| case | must hold |
| --- | --- |
| `close.sh <slug> carried --successor-title "<t>"` | predecessor moves to `missions/archive/<slug>/` with `status: carried`; a successor exists under `missions/active/<new-slug>/` |
| Successor's `## Acceptance` | contains exactly the predecessor's **unchecked** items, markers intact — and **none** of the checked ones |
| Predecessor's `## Changelog` | carries a line naming the successor (written via `append-changelog.sh`, not by hand) |
| Successor's provenance | records the predecessor's slug, so the lineage is traversable in both directions |
| Computed progress | the successor's `progress.sh` reports `0/<n unmet>` — **not** inheriting the predecessor's checked count |
| `carried` with no successor | rejected, like any other invalid input |
| `achieved` / `abandoned` | unchanged — no regression in the existing two outcomes |
| Idempotence | re-running the same carry is a no-op, matching every other mission mutator |
| Worktree | behaves as step 4 decided, and the decision is stated in the Final Report either way |

**Verification method:** hermetic temp repos with fabricated missions (partially-checked Acceptance), driving the real `close.sh` — the shape the existing mission tests already use. No network.

**The gate:** every row above; the worktree decision recorded; full suite green; `posix-lint` conforming; `verify.mjs`, `validate-metadata.mjs` pass; `git status --porcelain outputs/` empty after a rebuild.

**Watch it fail first:** revert `close.sh` alone via `git checkout HEAD -- <path>` (never `git stash`, which takes the tests away with the fix and passes vacuously), confirm the new cases go red, restore.

## Considerations

- **Do not let `carried` become a way to avoid `abandoned`.** If a mission's remainder is not actually worth doing, the honest outcome is `abandoned` — a successor that no one drives is just an abandoned mission with a longer name. The `/mission summary` and lens surfaces make an unclaimed successor visible; that is a feature.
- **`progress.sh` computes, never stores.** The successor's progress must fall out of its own Acceptance list. Do not carry a number across.
- The `## Acceptance` items name tickets by `(#<filename>)`. An unmet item may point at a ticket that was never written, or one that was archived without satisfying it — carry the marker as-is rather than trying to repair it; the successor's own interrogation is where that gets resolved.
- Independent of the other three tickets in this batch (they touch `/mission` create and `/drive`; this touches `close`). It can ship in any order.
