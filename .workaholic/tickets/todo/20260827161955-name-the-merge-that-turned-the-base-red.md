---
created_at: 2026-08-27T16:19:55+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827161954-write-read-base-checks-sh-the-one-checks-reader.md
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Name the merge that turned the base red

## Overview

<!-- PROPOSED. -->

A red tip says the base is broken; it does not say **what broke it**, and the tip
is very often not the culprit. This ticket adds the attribution walk: from the
base tip, back over commits the step-1 reader can answer for, to the last commit
it calls `green`; the **first red commit after that green one** is the attributed
merge, together with the pull request that landed it and that pull request's author.

The answer is bounded and honest. A walk that reaches neither a green commit nor
its own bound answers **`unattributable`** — a reading, not a blame. Blaming the
tip because the walk ran out of room is the failure this outcome exists to prevent.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — degrade by name, never silently

## Key Files

- `plugins/workaholic/skills/drive/scripts/attribute-base-red.sh` — **new**, the walk.
  Composes the step-1 reader; derives no check state of its own.
- `plugins/workaholic/skills/drive/scripts/read-base-checks.sh` — from ticket 1, the
  **only** source of a commit's check state. A second derivation is what this must not add.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the transport for the
  pull-request lookup that names the merge and its author.
- `plugins/workaholic/skills/drive/scripts/claim-merged.sh` — read how it resolves a
  branch to a merged pull request over REST; the same endpoint shape answers "which
  pull request landed this commit".
- `scripts/test-workflow-scripts.mjs` — hermetic coverage.

## Implementation Steps

1. Read ticket 1's shipped reader and reuse it verbatim. This script asks *which
   commit*, never *what state* — one derivation of check state, in one place.
2. Walk `git log` backwards from the base tip, calling the reader per commit, and
   stop at the first commit it calls `green`. The attributed commit is the oldest
   commit **after** that green one that the reader calls `red`.
3. Bound the walk explicitly (a commit count and/or a time window, env-overridable)
   and **report the bound in the output**. An unbounded walk over a busy base is a
   network call per commit with no ceiling.
4. Answer `unattributable` — with its reason — when the walk hits its bound, when it
   reaches the start of history, or when the commits between are `unanswerable`. It
   is a first-class outcome and never the tip by default.
5. Resolve the attributed commit's pull request and author over REST through
   `gh-rest.sh` (`repos/{owner}/{repo}/commits/{sha}/pulls`). A lookup that fails
   leaves the coordinates **unstated** rather than dropping the finding — the
   attribution is still real without a URL, exactly as `step-undelivered-units.sh`
   handles an `unanswerable` pull-request lookup.
6. Emit `{"ok", "state", "attributed": {"commit", "pull_request", "author"}, "last_green",
   "walked", "bound", "reason"}` and exit 0 in every case.
7. Add hermetic coverage with the transport stubbed: a red tip attributed to a mid-walk
   merge, a red tip whose walk exhausts its bound (`unattributable`), a green tip
   (nothing to attribute), and a pull-request lookup that fails but keeps the finding.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- a red base names the first red commit after the last green one, its pull request and its author
- a walk that reaches neither a green commit nor its bound answers `unattributable`, never the tip
- the walk's bound is explicit and reported
- a failed pull-request lookup leaves the coordinates unstated and keeps the finding
- check state comes only from ticket 1's reader — no second derivation

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the four cases above, transport stubbed, no network
- `grep` proves no check-state parsing outside `read-base-checks.sh`

**Gate** — what must pass before approval:

- the hermetic suite passes with no network call
- `unattributable` is reachable in the suite and is not a synonym for the tip

## Considerations

- **Cost.** The walk is one network read per commit inspected. The bound is what keeps
  a red base from costing an unbounded sweep every time something asks. Keep the
  default small; the interesting culprit is almost always recent.
- A **squash-merged** base means one commit per pull request, which is what makes this
  walk tractable here. Do not assume it holds for a repository that merges differently —
  say so in the header rather than encoding the assumption silently.
- Attribution is a **judgement about a judgement**: the underlying red can be falsified
  by a re-run, so nothing downstream may act on this. Ticket 6 pins that.
