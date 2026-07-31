---
created_at: 2026-08-01T09:00:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy: review
---

# The claims reader drops a claimed ticket whose archive falls below git's default rename threshold, so the survey re-offers work already in flight

## Overview

`lib/claims.sh` resolves each claimed artifact's current path with a
tree-to-tree rename diff:

```sh
_cs_renames=$(git diff --find-renames --name-status "$_cs_sha" "$_cs_ref" ...)
```

`--find-renames` with no argument uses git's **default 50% similarity
threshold**. `archive.sh` renames a driven ticket
(`todo/<user>/X.md` -> `archive/<branch>/X.md`) *and* the drive flow appends a
`## Final Report` to it in the same commit. When that report is long relative to
the ticket, similarity falls under 50%, git reports the change as `D` + `A`
instead of `R`, no rename row is produced, and `claims_current_path` answers
with the old path — which no longer exists at the tip. The artifact silently
leaves the claim's list.

The consequence is the exact double-pick the claim protocol exists to prevent:
`plan-units.sh` subtracts claimed artifacts through this same reader, so a
ticket that is claimed, implemented and committed on a claim branch is offered
again as unclaimed backlog. A second runner (or the next tick) will claim and
re-drive work that is already done.

This is adjacent to the 2026-07-30 fix that introduced the rename diff — that
fix made the reader follow renames at all; this one is that the following is
thresholded.

## Reproduction

Observed live on a real batch unit that claimed two tickets. After the first was
archived with a substantial Final Report, `list-claims.sh` reported **one**
artifact for a unit holding two, and the next survey re-offered the missing one.

Measured against the resulting commits:

```
$ git diff --find-renames --name-status <claim-base> <tip> -- .workaholic/tickets/
A       .workaholic/tickets/archive/<branch>/<ticket>.md
D       .workaholic/tickets/todo/<user>/<ticket>.md      # <- no R row

$ git diff --find-renames=20% --name-status <claim-base> <tip> -- .workaholic/tickets/
R039    .workaholic/tickets/todo/<user>/<ticket>.md  ->  .workaholic/tickets/archive/<branch>/<ticket>.md
```

39% similarity — detected at a 20% threshold, invisible at the default 50%. A
sibling ticket archived with a short report in the same unit scored `R100` and
tracked correctly, which is why the defect is intermittent and looks unrelated
to ticket size.

## Policies

- `workaholic:implementation` / `observability` — the reader fails silently. A
  dropped artifact is indistinguishable from an artifact that was never claimed,
  so the survey reports a confident, wrong answer.
- `workaholic:implementation` / `objective-documentation` — the claim's artifact
  list is the coordination record; it must reflect what is actually held.

## Key Files

- `skills/drive/scripts/lib/claims.sh` — the `--find-renames` call (~line 137)
  and `claims_current_path`.
- `skills/drive/scripts/list-claims.sh` — renders the reader's output.
- `skills/drive/scripts/plan-units.sh` — subtracts claimed artifacts through the
  same reader, so it inherits the drop.
- `skills/drive/scripts/archive.sh` — the renaming writer, and the reason the
  content changes in the same commit as the move.

## Implementation Steps

1. Decide the instrument. Two candidates, and the second is likely the better
   answer:
   - **Lower the threshold** — `--find-renames=01%` (plus `-C` / `--find-copies`
     if needed). Minimal, but still similarity-based: a ticket rewritten
     wholesale during driving would fail again, and the threshold is a guess.
   - **Stop relying on similarity.** The ticket's **basename is invariant**
     across the archive move (`archive.sh` moves the file, never renames it).
     Pairing a `D` and an `A` that share a basename is exact, needs no
     threshold, and cannot regress with content size.
2. Apply the fix in `claims.sh` so both `list-claims.sh` and `plan-units.sh`
   inherit it — do not fix it in one caller.
3. Add a regression test that archives a ticket **with a large body change** and
   asserts the artifact still resolves. Existing tests pin the rename case, but
   a 100%-similarity move is exactly the case that already passes; the test must
   construct a sub-threshold change or it will not fail on the current code.

## Quality Gate

- **Acceptance:** a unit claiming two tickets, where the first is archived with a
  body change large enough to score below 50% similarity, still reports **both**
  artifacts from `list-claims.sh`, and `plan-units.sh` does **not** re-offer the
  archived one as unclaimed backlog.
- A regression test covering the sub-threshold case fails on the current
  implementation and passes after the fix.
- No behaviour change for the already-working 100%-similarity move.

## Considerations

- The drop is **silent and durable**: nothing warns, and the survey looks
  healthy. On an unattended tick this reads as "there is work available", which
  is the worst shape for a coordination bug.
- Worth checking whether any other caller resolves claimed paths independently
  of `claims.sh`; the skill documents that the writer must not carry its own
  scan, and the same argument applies to path resolution.
- If the basename-pairing approach is taken, a genuine stamp *removal* and a
  *deleted* artifact must keep their current documented behaviour (both drop the
  artifact deliberately, and both are pinned by tests).
