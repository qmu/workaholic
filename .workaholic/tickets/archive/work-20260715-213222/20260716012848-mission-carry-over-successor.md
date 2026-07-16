---
created_at: 2026-07-16T01:28:48+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 2h
commit_hash:
category: Changed
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

## Final Report

Development completed. Every gate row holds, but **two of this ticket's own premises were false** and were corrected rather than followed.

**Premise 1 — "close.sh today tears the mission's worktree down via `cleanup-mission-worktree.sh`" (step 4).** It does not. `close.sh` never mentioned a worktree at all; `commands/mission.md` orchestrates the teardown *after* `close.sh` succeeds. So the "sharpest design call here" was never a `close.sh` call — it is a command-layer one, which made it considerably less sharp than the ticket feared.

**Premise 2 — that keeping the worktree only risked "breaking the 1:1 naming".** The real consequence is worse and was measured, not argued: a successor living in the predecessor's `.worktrees/<old-slug>` **silences the mission lens inside that very worktree**. The lens reads a worktree whose basename names no active mission as a `/drive` worktree and exits saying nothing — so the mission you are working on becomes the one mission you cannot see. Verified with a known-positive control (the correctly-named worktree prints the line). The 1:1 slug↔worktree naming is load-bearing, not cosmetic.

**The developer's two decisions:**

- **Carry without the worktree.** The ticket's own fallback, and the measurement above is why. A rename (`git worktree move`) was costed as the alternative and is genuinely clean — the port lives in `.worktrees/<slug>/.env` and allocation scans live worktrees rather than a slug-keyed registry, so a rename would carry it automatically — but it needs a new primitive (none exists; `git worktree move` is unused repo-wide) and widens a ticket that is otherwise independent. In-flight state and the port do not carry; the command says so rather than letting the developer assume otherwise.
- **Goal/Scope carried verbatim.** A carry-over *is* a continuation: done as framed, remainder pursuing the same outcome. A genuine re-framing is a new mission, not a carry. This also kept the ticket independent of the interrogation flow (`20260716012845`), exactly as its Considerations claimed.

**Mid-run direction from the developer, folded in.** The `/mission close` branch must now **state where the mission stands before asking anything** — progress, unmet criteria, and on a carry exactly what moves to the successor and how far a fresh session could take it. This came from the developer mid-drive ("always mention where we are at in the mission and what to carry; in another session, how much can we proceed") and is the mission-centralized behavior the model is for. It is command-layer prose, not script logic, because it is a reporting obligation rather than a mutation.

### Discovered Insights

- **Insight**: A ticket that names its own escape hatch is worth more than one that is merely correct. Both design forks here — the worktree and Goal/Scope — were resolved by the Considerations' instruction to *record the finding and propose the association as its own decision rather than invent a fragile one*. The same clause resolved `20260715213322` earlier in this drive.
  **Context**: The pattern generalizes: the valuable part of a ticket is not its proposed solution but its statement of what to do when the proposal turns out wrong. Two of this batch's tickets were mis-premised about the code they described, and both were still drivable because they said so in advance.

- **Insight**: The order of operations in `close.sh` is load-bearing and non-obvious: the successor is built **before** the predecessor is archived. The predecessor's Acceptance list is then read from a stable `active/` path, and a failure to build the successor exits without having half-closed anything.
  **Context**: The mirror of this is the idempotence path — a re-run finds the predecessor already archived and returns `already_closed` *before* reaching the successor logic, which is exactly why an existing successor is never rebuilt (rebuilding would re-inherit items the developer may have since ticked). It also bit the test: an assertion about a nonexistent successor had to run while the predecessor was still active, or it short-circuited on `already_closed` and measured nothing.

- **Insight**: `carried` is the outcome that lets the progress model stay honest. The model's whole claim is that progress is computed from unchecked items and never hand-set — but with only `achieved`/`abandoned`, the common verdict "most of this landed, the rest is worth doing" had to be forced into a status that contradicted the computation.
  **Context**: A closed status set is a schema, and a schema that cannot express a routine real outcome does not prevent that outcome — it pushes people into recording a false one. The guard against `carried` becoming a soft `abandoned` is not a check but a surface: `/mission summary` and the lens now show an unclaimed successor, so a carry nobody drives is visible rather than quietly filed away.
