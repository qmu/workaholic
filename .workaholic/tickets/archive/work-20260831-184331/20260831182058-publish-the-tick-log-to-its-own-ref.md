---
created_at: 2026-08-31T18:20:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Publish the tick log to its own ref

## Overview

PROPOSED. `persist-log.sh` is the tick log's one publisher. Today it opens the
publish tree at `origin/main`, merges the day file line-wise, commits and pushes
to the base. This ticket repoints that target at the ref ticket 1 ruled, keeping
every property the current implementation gets from the publish tree — and the
union is the property that matters, because it is what lets two containers tick
in the same minute without erasing each other.

The union is **by `(tick, step)`, line-wise inside a shared section**, and the
script's own header records why by section was wrong: a `<step>-filed` line
appended after the persist had already landed could never reach the base. That
behaviour is not being redesigned here; it is being carried onto a different
target. Preserve equally: the bounded retry (`--attempts`, default 3) that
re-opens against a freshly fetched base rather than retrying the same patch, the
carry of **every missing section** rather than only this tick's, and the closed
`status`/`reason` vocabulary a caller reads.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — a degradation is named, never silent
- `workaholic:operation` / `policies/observability.md` — an operational log is read, not reviewed

## Key Files

- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the one writer to
  the remote; the target and the merge live here.
- `plugins/workaholic/skills/branching/scripts/open-publish-tree.sh`,
  `close-publish-tree.sh`, `publish-tree-commit.sh` — what the current
  implementation composes; whether the ref path still uses them is this ticket's
  decision, and either way the caller's checkout stays byte-identical.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the three call sites
  (`persist-log-opening`, the closing act, the agent's persist).
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — must not read the
  new ref as a claim.
- `plugins/workaholic/hooks/guard-git-branch.sh` — must permit whatever creation
  path ticket 1 ruled.

## Implementation Steps

1. Read ticket 1's ruling and implement exactly it. A disagreement is resolved by
   amending the ruling in the same change, never by diverging silently.
2. Repoint `persist-log.sh` at the ref: the day file is read from the checkout as
   it is now, and merged into the ref's copy.
3. Carry the union unchanged. For a section the ref already has, ask per **step**
   whether the ref's copy carries a line for it, and append only what it lacks,
   in this checkout's order, at the end of that section. A `(tick, step)` the ref
   already has still wins over a differing local copy.
4. Carry the retry unchanged: a rejected push re-reads the ref and re-unions
   rather than retrying the same patch; attempts stay bounded and a sustained
   divergence is reported `degraded`, not hidden.
5. Keep the closed vocabulary. `no_origin` stays `skipped` (nothing went wrong in
   a local-only checkout); every other failure stays `degraded`. Add a reason for
   a ref that could not be reached — do not fold it into an existing word.
6. Keep the two refusals that stop this script publishing into the wrong tree:
   a `--root` outside a git work tree, and a `--root` that is not the repository
   root.
7. Apply the two ref-reader rules ticket 1 named: exclude the log ref from
   `list-claims.sh`, and permit its creation path in `guard-git-branch.sh`.
8. Update `workaholic:moderate`, `rules/workaholic.md` and `CLAUDE.md` in the same
   change, and regenerate `outputs/` with `node scripts/build-plugins/build.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick's log reaches the ref and **no commit reaches `main`** from this script.
- Two persists of overlapping sections union by `(tick, step)`: neither loses a
  line, nothing is rewritten, reordered or removed.
- A late `<step>-filed` line appended after the first persist still reaches the
  ref on the second persist.
- The caller's checkout is byte-identical after a persist, and no `work-*` branch,
  claim, worktree or pull request is created.
- `list-claims.sh` does not report the log ref as a claim.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic fixture in `scripts/test-workflow-scripts.mjs`: two checkouts, two
  overlapping sections, persist both, assert the union.
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `git log --oneline origin/main -- .workaholic/moderations/` shows no new commit
  after a tick.

**Gate** — what must pass before approval:

- The union test fails against a deliberately by-section merge. A test that
  passes both ways proves nothing.

## Considerations

- The feedback records `--record` carries are a **different payload** with a
  different destination and are ticket 3's. Do not move them onto the ref by
  accident while repointing the target.
- The publish tree's value here was the fresh base and the byte-identical
  checkout, not the pull request. If the ref path keeps using it, say why; if it
  does not, say what replaces both properties.

## Final Report

Development completed as planned. `persist-log.sh` now publishes the day files to
`refs/heads/workaholic/moderation-log` and makes **no commit to the base** for the log.

- **The union is carried unchanged** and is the property that mattered: sections the ref
  lacks are appended whole, and a section it already has is merged **line-wise by step**,
  so a `(tick, step)` the ref carries wins over a differing local copy. Verified across
  two containers: neither lost a line, and a late `<step>-filed` line appended after the
  first persist reached a section that had already landed.
- **The retry is unchanged in force**: a rejected push re-fetches the ref and re-unions
  rather than replaying the patch; attempts stay bounded by `--attempts`.
- **The closed vocabulary is kept**, with `log_ref_unreachable` added rather than folded
  into an existing word — a ref that cannot be fetched and a ref that does not exist yet
  are different facts, and only the first is a degradation. `no_origin` stays `skipped`.
- **Both `--root` refusals are kept** (outside a work tree, and not the repository root).
- `list-claims.sh` excludes the ref by name; `guard-git-branch.sh` is deliberately
  untouched, and the suite pins that the publisher reaches for no local-branch form.

### Discovered Insights

- **Insight**: dropping the publish tree from the log half made the caller's byte-identical
  checkout a **structural** property rather than a maintained one. The commit is built with
  `GIT_INDEX_FILE` plumbing, so no working tree, HEAD or index is touched at any point, and
  there is no `.publish/` checkout that an interrupted run can leave dirty.
  **Context**: the publish tree was chosen in 2026-08-17 for a fresh base and an untouched
  checkout. The ref path gets the first from `git fetch` and the second for free, so the
  seam did not need replacing with an equivalent — it needed removing.

- **Insight**: the publish tree was also materializing the whole base into `.publish/`
  before it could append one line. Measured after the change: ~120 ms per carrying persist
  and ~62 ms for a no-op, two remote round-trips each.
  **Context**: the move was argued as a cost to `main`'s history. It is also cheaper.

- **Insight**: carrying **every** day file rather than only the tick's own closes a
  day-boundary hole that was in the old behaviour. A tick whose persist failed at 23:50 left
  its section behind, and the next tick's file is a different day, so nothing carried it up.
  **Context**: the header's "carries every missing section" claim was true within a day and
  silently false across one. Iterating the directory made both cases one code path.
