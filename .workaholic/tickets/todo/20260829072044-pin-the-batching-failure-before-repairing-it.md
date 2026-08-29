---
created_at: 2026-08-29T07:20:44+00:00
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
