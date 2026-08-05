---
created_at: 2026-08-05T05:37:16+00:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
depends_on:
feedback: [20260805053636-list-proposed-refs-sh-dedup-misses-feedback-refs-on-unmerged-pull-requests.md]
merge_policy:
---

# Cover unmerged pull requests in the propose dedup set

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`list-proposed-refs.sh` walks the working tree's `.workaholic/` — the missions in both
areas and the tickets in `todo/` and `archive/` — and unions their `feedback:` refs. At
the propose seam that working tree is the publish tree, a checkout of `origin/main`, so
the set contains merged artifacts only. A proposal sitting in an open pull request has
its refs on a branch nobody reads, and the seam concludes the ask has never been
answered.

This is not a theoretical window. On 2026-08-05 issue #242 restated the ask already
proposed ten minutes earlier in open pull request #241, and the scripted dedup did not
catch it; the duplicate was caught only because the reviewing session listed open pull
requests by hand, which is not part of the dedup path. The same run that recorded this
gap reproduced it — the record behind PR #241 is absent from the set this ticket's own
proposal read.

The fix is to widen the set to cover the `feedback:` refs carried by open pull requests,
so the dedup answers "has this ask been proposed", not merely "has a proposal for it
merged".

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/failure-design.md` — the reader must degrade loudly, never silently under-read

## Key Files

- `plugins/workaholic/skills/propose/scripts/list-proposed-refs.sh` — the dedup set; the
  only file that decides what counts as "already proposed".
- `plugins/workaholic/skills/propose/scripts/read-feedback-relation.sh` — the single
  `feedback:` parser. Whatever path is added must read through it; a second parser would
  eventually disagree, and the side that under-reads re-proposes answered feedback.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — the existing precedent for
  reading unmerged remote branches, including the shallow-clone handling to mirror.
- `plugins/workaholic/skills/propose/SKILL.md` — the *list-proposed-refs.sh — the dedup
  set* section states the set is "artifacts on `main`"; it must say what the set now covers.
- `CLAUDE.md` — the `/propose` row describes the dedup set in the same terms.

## Implementation Steps

1. Extend `list-proposed-refs.sh` to add, to the refs it already collects from the working
   tree, the `feedback:` refs carried by artifacts on **open pull request branches**.
   Prefer the git-native route the claim protocol already uses — enumerate unmerged
   remote branches and read each artifact blob out of the ref — over `gh pr list`: it
   needs no auth, no API budget, and no network beyond the fetch the seam already does.
2. Feed every blob through `read-feedback-relation.sh`. Keep it to one invocation over
   many inputs; this runs inside a capture session a reporter is waiting on.
3. Mirror `claims.sh`'s shallow-clone handling. `git rev-list --count <base>..<ref>` cannot
   be reduced across a shallow graft, so a shallow clone counts merged branches as ahead
   and would pull refs from long-merged branches into the set. Over-reading here is the
   safe direction — it suppresses a proposal rather than duplicating one — but it must be
   deliberate, not accidental.
4. Decide and record what happens when the branch scan cannot run (no origin, unreachable
   remote). Failing open means duplicates; the conservative reading is to report the
   degradation rather than to silently return the narrower set.
5. Update `skills/propose/SKILL.md` and the `/propose` row in `CLAUDE.md` so both describe
   the widened set.
6. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`) — the propose skill ships
   in the generated bundle, and `Outputs Freshness` CI fails on any diff.

## Quality Gate

<!-- Provisional; sharpened when this proposal is reviewed. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Given an open pull request whose branch carries an artifact with `feedback: [X]`, and no
  merged artifact referencing `X`, `list-proposed-refs.sh` includes `X`.
- The merged-artifact refs the script reports today are all still reported.
- The `feedback:` field is parsed only by `read-feedback-relation.sh`.
- A shallow clone does not cause merged branches to be read as open pull requests.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic case in `node scripts/test-workflow-scripts.mjs` building a throwaway repo
  with one merged and one unmerged artifact, asserting both refs appear. The suite must
  stay network-free and must not call `gh`.
- A shallow-clone case asserting merged branches do not leak into the set.
- `node scripts/build-plugins/verify.mjs` for bundle self-containment.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs` leaves `outputs/` clean.
- `node scripts/test-workflow-scripts.mjs` passes, new cases included.
- `node scripts/build-plugins/verify.mjs` and `validate-metadata.mjs` pass.

## Considerations

- **Which direction to err.** A dedup set that over-reads suppresses a real proposal; one
  that under-reads publishes a duplicate. The duplicate is the louder failure and the one
  measured here, so over-reading is the safer default — but a suppressed proposal is
  silence to the reporter, so the choice belongs in the script's header, not in a commit
  message.
- **Closing a pull request without merging** leaves its branch unmerged, so its refs stay
  in the set and the ask it answered can never be re-proposed. Whether a rejected proposal
  should free its feedback again is a real design question this ticket should answer
  explicitly rather than inherit.
- **Cost at the seam.** This runs while a reporter waits. Reading blobs from every unmerged
  branch is more work than one `.workaholic/` walk; keep it to a single parser pass and
  measure before adding a second.
- **The gap is self-demonstrating.** The proposal that queued this ticket read a dedup set
  that did not contain PR #241's record — useful as a regression fixture.
