---
created_at: 2026-08-28T06:23:08+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: reconcile-a-stale-thread-with-the-unit-s-real-state
merge_policy:
verification_handoff: 
---

# Read which announced items may still be called in flight

## Overview

An operator hand-finished several handed-off units in a terminal on 2026-08-28 — merged the
pull requests, executed the delegated decisions — and every affected feedback thread kept
`🟡 Handoff` as its last word. The finish line is posted only by the run that finishes the
unit (`workaholic:notify`, *Which thread an `/implement` unit's posts land in*), so a manual
takeover bypasses the seam entirely.

No existing step can see it: `stuck-prs` and `merge-conflicts` read **open** pull requests and
find nothing wrong with one that already merged; `handoff-units` reads a claim that is still
standing; `stalled-units` reads a stale tip. This ticket builds the reader that names the
candidates — and it derives them from the **repository**, not from a channel scan, because
`workaholic:notify` bounds every lookup at two exact-string searches with **no full-channel
read at any point**.

Reproduce and localize first: before wiring anything, list the units whose pull request merged
or closed in the last N days and whose threads the loop never posted a finish into on this
repository. That measured set is what the reader must reproduce, and it is the evidence the
later tickets are checked against.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a degraded read is named, never rendered as an empty one

## Key Files

- `plugins/workaholic/skills/moderate/scripts/` — where the new reader lands, beside `pulls-state.sh`
- `plugins/workaholic/skills/moderate/scripts/pulls-state.sh` — the precedent: one bounded REST read, the cap reported
- `plugins/workaholic/skills/drive/scripts/unit-feedback-stems.sh` — the one translation from a unit's artifacts to its thread key
- `plugins/workaholic/skills/specificate/scripts/read-feedback-relation.sh` — the one reader of the `feedback:` relation; never re-parse it
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport (`rules/shell.md`)
- `plugins/workaholic/skills/moderate/reference/workflow.md` — where the reader's contract is recorded

## Implementation Steps

1. **Measure the real set first.** On this repository, list pull requests merged or closed in
   the last few days whose head was a `work-*` branch, resolve each to its feedback stems, and
   record which of those threads carry no finish line. Write the measured count into the
   ticket's story; it is the localization the later tickets are judged against.
2. Write the reader — one script, a **pure read**: recently merged or closed pull requests the
   loop itself opened, each resolved to its unit's artifacts and then to its feedback stems
   through `unit-feedback-stems.sh`. Reads GitHub only through `gh-rest.sh`.
3. **Bound it and report the bound.** A window (days) and a candidate cap, both env-configurable
   with defaults, and the number beyond the cap reported rather than dropped — `pulls-state.sh`'s
   own rule, for its own reason.
4. Emit per candidate what the thread lookup and the reply will need: the stems, the pull
   request number, title and URL, whether it **merged** or **closed unmerged**, the merge
   commit's author and timestamp. A candidate whose stems resolve to nothing is reported by
   name and never keyed on `unit:<id>` here — this reader answers *which item*, and an item
   with no feedback record has no thread to reconcile.
5. Name every degradation: `gh_unavailable`, `list_failed`, `stems_unresolvable`. An unreadable
   read is `ok: false` with its reason and **exit 0**, never an empty candidate list.
6. Record the reader's contract in `moderate/reference/workflow.md` and update `CLAUDE.md` in the
   same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reader emits one row per candidate carrying stems, pull request coordinates, merged-or-closed, and the merging author and time
- It writes nothing: no file, no commit, no branch, no comment, no merge
- It reaches GitHub only through `gh-rest.sh`, and the window and cap are both bounded and reported
- An unreadable read reports its reason with exit 0 and an absent candidate list, never an empty one

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic coverage of the reader over a fixture, including the degraded read
- A run against this repository reproducing the set measured in step 1

**Gate** — what must pass before approval:

- The measured stale set from step 1 is recorded, and the reader reproduces it
- `node scripts/test-workflow-scripts.mjs` passes; no `gh issue|pr|repo <verb>` is introduced

## Considerations

- **The candidate set must be repository-derived.** A channel scan would break `workaholic:notify`'s
  written bound (*no full-channel read at any point*) and would make the reader's cost grow with
  the channel rather than with the work.
- The reader deliberately does **not** decide whether a thread is stale — that needs the thread,
  which only the agent half can read. It answers *which items to look at*, and nothing more.
- A `review` unit's thread ending at `🟢 Implemented` after a later human merge is **correct and
  out of scope** (`notify/reference/notifications.md`): only `🔵 Proposed` and `🟡 Handoff` are stale-able.
