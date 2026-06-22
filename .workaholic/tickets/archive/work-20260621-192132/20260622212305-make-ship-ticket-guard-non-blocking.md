---
created_at: 2026-06-22T21:23:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash: 49f96d1
category: Changed
depends_on:
---

# Make `/ship`'s ticket guard non-blocking: note queued todo tickets but never prompt or block the merge

## Overview

`/ship`'s **§4 Ticket Guard** currently **blocks** the ship whenever the current user's `todo/<user>/` queue is non-empty: `check-todo.sh` returns `clean:false`, and the skill issues an `AskUserQuestion` forcing "Move all to icebox" or "Stop". This is wrong, and annoying in practice: a branch's shippability has nothing to do with what is queued for *future* work. Shipping PR X gets blocked by unrelated tickets (e.g. 生保/損保 tickets queued for entirely different work), with the only offered escapes being to icebox future work or abort.

The legitimate "unfinished work" gate is the **§3 Workspace Guard** (uncommitted changes) and the deployment-confirmation gate — both untouched here. The todo queue is future/unstarted work; blocking a merge on it conflates "I have plans queued" with "this PR is not ready". A prior change already scoped this guard per-user (`todo/<user>/`) so teammates' tickets do not block; this ticket finishes the job by making it **non-blocking**.

**Decision (confirmed with the requester):** keep a one-line informational note but never prompt or block — `/ship` always proceeds past a non-empty queue. (Alternatives considered: full removal, or branch-scoping; the requester chose the non-blocking note, which preserves a harmless heads-up while removing the spurious gate.)

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` - PRIMARY. Rewrite **§4 Ticket Guard**: on `clean:false`, print a single non-blocking note (count, optionally filenames) and **proceed to the Ship Flow** — remove the `AskUserQuestion` and the Move-to-icebox/Stop options. Also fix the **§2-4** description line ("Used as a pre-merge guard to prevent shipping with unfinished work") to say it is now an informational, non-blocking pre-merge note.
- `plugins/workaholic/skills/ship/scripts/check-todo.sh` - Keep AS-IS. It still reports `{clean, count, tickets}` (now consumed only for the informational note) and keeps its per-user `todo/<user>/` scoping. No change expected; reference only.
- `plugins/workaholic/commands/ship.md` - Line ~21 ("Workspace Guard and Ticket Guard — follow `workaholic:ship` §3 and §4"). Update the wording so it does not imply the ticket guard blocks (e.g. "Workspace Guard (blocking) and Ticket Guard (informational, non-blocking)").
- `outputs/workflows/skills/ship/SKILL.md` - GENERATED. The ship skill is in the cross-agent build, so regenerate `outputs/` after editing the source and commit the result.
- `scripts/test-workflow-scripts.mjs` - `check-todo.sh` behavior is unchanged, so no test change is required; confirm the existing suite still passes. Reference only.

## Related History

- The per-user scoping of `check-todo.sh` (the "partition the todo queue per developer" work, story `work-20260528-122941`) made the guard check only `todo/<user>/`. It did not make it non-blocking — that residual blocking is exactly what this ticket removes. Confirm against the archived ticket for that branch if precise wording is needed.
- `.workaholic/tickets/archive/work-20260617-231848/` (ship reorder: deploy-confirm-before-merge) and `work-20260617-210627` (deployment-confirmation hard gate) established the *real* ship gates; this ticket must not touch those — only the todo guard becomes non-blocking.

## Implementation Steps

1. **Rewrite §4 Ticket Guard** in `ship/SKILL.md`:
   - Run `check-todo.sh` as today.
   - If `clean` is `true`: proceed silently to the Ship Flow (unchanged).
   - If `clean` is `false`: print ONE non-blocking line — e.g. "Note: N ticket(s) still queued in your `.workaholic/tickets/todo/<user>/` (not blocking this ship)." optionally listing filenames — then **proceed directly to the Ship Flow**. Remove the `AskUserQuestion`, the "Move all to icebox" option, and the "Stop" option entirely.
2. **Fix the §2-4 description** of `check-todo.sh` in `ship/SKILL.md`: change "Used as a pre-merge guard to prevent shipping with unfinished work" to describe it as an **informational, non-blocking** pre-merge note (the script still reports the count; the skill no longer blocks on it).
3. **Update `commands/ship.md`** line ~21 so "Ticket Guard" is labelled non-blocking/informational (Workspace Guard remains the blocking guard).
4. **Leave `check-todo.sh` unchanged** — it still returns `{clean, count, tickets}` scoped to `todo/<user>/`, now consumed only for the note. Do not remove the script.
5. **Regenerate and verify**: `node scripts/build-plugins/build.mjs` (ship skill is in the cross-agent build → `outputs/workflows/skills/ship/SKILL.md` regenerates; commit it), then `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs` (all green; check-todo behavior unchanged). Confirm `/ship`'s flow now proceeds past a non-empty queue with only the note.

## Considerations

- **Implementation + Operation are the binding lenses.** `workaholic:implementation` (Config/workflow prose + skill; directory-structure, no inline shell logic in markdown) and `workaholic:operation` (this touches the ship/release path — but it only *removes* a spurious blocker; the real gates, §3 Workspace Guard and the deployment-confirmation gate, stay intact and must not be weakened). `design`/`planning` do not bind.
- **Do NOT weaken the real gates.** Only the todo guard becomes non-blocking. The Workspace Guard (uncommitted changes) and the deployment-confirmation / merge-last gate remain blocking — they are what actually protect production.
- **Keep `check-todo.sh` and its per-user scoping.** The script is still the source of the count for the note; removing it would also break the informational line. The non-blocking behavior lives in the SKILL prose, not the script.
- **Shell Script Principle.** No inline conditionals/pipes added to the markdown; the skill just interprets `check-todo.sh`'s JSON and prints a note.
- **Regenerate `outputs/`.** The ship skill ships cross-agent, so `outputs/workflows/skills/ship/SKILL.md` must be rebuilt and committed or the Outputs Freshness CI fails.
- **No version bump implied** by the change itself; a patch bump happens at `/report`/release time as usual.

## Final Report

Development completed as planned. §4 became a non-blocking note; the §2-4 description and `commands/ship.md` guard labels were updated to match; `check-todo.sh` was left unchanged (still feeds the note, still per-user scoped). `outputs/workflows/skills/ship/SKILL.md` regenerated. The real gates (Workspace Guard, deploy-confirm-before-merge) were not touched.

### Discovered Insights

- **Insight**: The blocking behavior lived entirely in the SKILL.md prose, not in `check-todo.sh` — the script only ever reported `{clean, count, tickets}`. So making the guard non-blocking was a pure documentation/skill-prose change with zero script edit (and the existing smoke suite, which doesn't test check-todo, stayed green). The script's `clean:false` is now an informational signal, not a gate.
  **Context**: This cleanly separates fact-gathering (script) from policy (skill prose) — the same script could later drive either a note or a block by prose alone. Future "should X block ship?" decisions are skill-prose edits, not script changes.
- **Insight**: The two ship "guards" were always different in kind — §3 Workspace Guard protects against losing/shipping uncommitted work (real), while §4 Ticket Guard only ever reflected queue housekeeping (not branch state). Labeling them explicitly in `commands/ship.md` (blocking vs informational) removes the implication that they are peers.
  **Context**: A branch's shippability is its archived tickets + clean workspace + passing deployment confirmation. The todo queue is orthogonal future work; it never belonged in the ship gate.
