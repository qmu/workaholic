---
created_at: 2026-08-29T07:20:44+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: keep-the-closing-link-readable-as-the-corpus-grows
merge_policy:
verification_handoff: 
---

# Pin the batching failure before repairing it

## Overview

PROPOSED. The failure this mission repairs is a **size** property, so it is invisible to
every fixture this suite already builds. Before anything is changed, add a hermetic test
that reproduces it: a throwaway `.workaholic/` corpus large enough that `xargs` splits it
into more than one batch, with the citing artifacts in an early batch and non-matching
filler in the last. Write the test **first** and record that it fails against today's
script — a repair whose test never failed proves nothing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-gaps.md` — the property is pinned mechanically, not asserted in prose

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the new case lands here, beside
  the existing `attributed-work.sh` cases.
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the subject; **read only**
  in this ticket.

## Implementation Steps

1. **Reproduce it by hand first, outside the suite**, and record the numbers in the ticket's
   own commit message: build a corpus, run the prefilter with and without the `||` branch,
   and confirm the candidate count differs. Measured on this checkout 2026-08-29 06:41 UTC:
   1402 files / 131508 bytes against a 131072-byte command buffer, split 1396 + 6, 25 real
   citations discarded, `empty_reason: no_citing_artifacts` for a direction with 2 active and
   23 archived citing missions.
2. **Localize it to the two call sites**: hop 1's `cand1` and hop 2's `cand2`, both of the
   shape `xargs grep -lFf … || : > …`. Confirm the mechanism rather than assuming it — a
   batch that matches nothing makes `grep` exit 1, `xargs` exits 123, and the `||` branch
   truncates the file the earlier batches already wrote.
3. **Write the hermetic case**: a throwaway repository whose `.workaholic/` holds a strategy,
   its feedback record, at least one citing mission, and enough non-citing filler artifacts
   that the corpus path list exceeds one `xargs` batch. Size the filler from the boundary
   rather than a magic number, and state in a comment why a dozen-file fixture proves nothing.
4. **Assert the citation is reported** — `count`/`artifacts` name the citing mission — and
   assert the hop-2 `via_mission:` attribution comes back for a ticket carrying that mission.
5. **Record the failure**: run the case against the unrepaired script and keep the observed
   output in the commit message, so the next reader can see the test had teeth.
6. Leave `attributed-work.sh` **unchanged** in this ticket. The repair is the next one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A new case in `scripts/test-workflow-scripts.mjs` builds a corpus past the `xargs` batching
  boundary and asserts every citing artifact is attributed, at both hops.
- The case **fails** against `attributed-work.sh` as it stands today, and the observed failure
  is recorded in the commit message.
- The fixture is hermetic: a throwaway directory under the OS temp dir, no network, no `gh`,
  the working tree untouched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new case fails, naming the missing citation.
- `git status --porcelain` after the run is empty.

**Gate** — what must pass before approval:

- The rest of the suite still passes; only the new case fails, and it fails for the stated
  reason rather than a fixture error.

## Considerations

- The batch size is a property of the running system (`xargs` default max-chars, ~128 KiB),
  not of this repository, so the fixture must derive its filler count from that boundary
  rather than hard-coding 1400 files — a machine with a different limit must still exercise
  the split.
- Keep the fixture's file bodies small; what has to be large is the **path list**, which is
  what `xargs` measures.

## Final Report

Development completed as planned.

Reproduced by hand first, on this checkout at 2026-08-29 07:41 UTC: the corpus is
1411 paths / 132292 bytes against a 131072-byte `xargs` command buffer, so it splits
into two batches. The prefilter as it stands returned **0** candidates; the same walk
appending across batches returned **26**. `attributed-work.sh
an-autonomous-improvement-loop-run-by-the-routines "30 days ago"` answered
`empty_reason: no_citing_artifacts`, `count: 0`, for a direction with 26 citing
artifacts.

Localized to the two call sites and the mechanism confirmed rather than assumed: a
batch that matches nothing makes `grep -l` exit 1, `xargs` exit 123, and the
`|| : > "${TMP}/cand1"` branch then truncates the file the earlier batches wrote.

The new hermetic case fails against the unrepaired script exactly there:

```
# strategy/attributed-work.sh past the xargs batching boundary
  ok    the fixture's corpus really does span more than one xargs batch
  FAIL  a citation in an early batch survives a later batch that matches nothing
         expected [".workaholic/missions/active/m-one/mission.md",
                   ".workaholic/tickets/todo/20260810000001-queued.md"], got []
  FAIL  hop 2's via_mission attribution crosses the boundary with it
         expected ["direct","via_mission:m-one"], got []
  FAIL  a direction with citing work is never reported as uncited past the boundary
         expected [false,"no_activity_in_window",2], got [true,"no_citing_artifacts",0]
  ok    no filler artifact is attributed — the prefilter still only decides worth reading
  ok    the reader leaves the tree clean
```

Whole suite: 4865 passed, 3 failed — only the new case, and for the stated reason.
`attributed-work.sh` is left unchanged; the repair is the next ticket.

### Discovered Insights

- **Insight**: the batching boundary is `xargs`'s own command buffer (131072 bytes on
  GNU) and not `ARG_MAX` (2097152 here), so a fixture sized against `getconf ARG_MAX`
  would never split.
  **Context**: any later test of a corpus-scale property must derive the boundary by
  probing `xargs` itself — the fixture counts how many times `xargs` invokes its
  command — rather than reading a system constant or hard-coding a file count.
- **Insight**: what `xargs` measures is the **path list**, never the file contents.
  **Context**: a fixture past the boundary costs ~600 files with 180-character names
  and three-line bodies, not 1400 realistic artifacts — cheap enough to run in the
  hermetic suite on every commit.
