---
created_at: 2026-08-05T13:04:57+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: drive-on-a-merged-proposal-and-report-it-in-that-proposal-s-thread
merge_policy:
---

# Report drive start and finish in the item's thread

## Overview

PROPOSED. The threading policy already covers this case in principle — *One thread per
feedback item* names "any `/drive` outcome for work that traces back to it" as an
in-thread reply, and `[Drive]`'s §5 defers its post routing to it. What is missing is
the granularity and the wiring. The postable set is per-**run**: "a run started" names
no single item, so there is no thread it could land in. And a drive session has no path
from the unit it is driving, through that artifact's `feedback:` refs, to the
`fb:<stem>` key that identifies the thread.

This ticket makes the start and finish posts per-**unit** and keyed to the item, which
is what the reporter asked for. The resolution path already half exists — an artifact's
`feedback:` list is read by `propose/scripts/read-feedback-relation.sh`, which takes a
mission or a ticket — so this is mostly connecting readers that exist, plus deciding
what a unit carrying several feedback refs, or none, posts.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — *One thread per feedback item* and
  the bright line listing the postable events; where per-unit start and finish are stated
- `plugins/workaholic/skills/workaholify/routines/drive.md` — §5's list of the five
  postable events, which is per-run today
- `plugins/workaholic/skills/propose/scripts/read-feedback-relation.sh` — the existing
  single reader of an artifact's `feedback:` list, for a mission or a ticket
- `plugins/workaholic/skills/drive/SKILL.md` — where a unit's posts are described
- `plugins/workaholic/skills/drive/scripts/claim.sh` — already posts one line when a
  claim lands; the natural seam for "implementation started"

## Implementation Steps

1. Resolve a PR-unit to its feedback stems through the existing reader — a mission unit
   via the mission's `feedback:`, a batch via its tickets' — and decide what a unit with
   several stems posts, and what one with none does.
2. Make the start post per-unit rather than per-run, landing in the resolved item's
   thread, and add the finishing post on the unit's terminal outcome.
3. Keep the three-case thread routing and its not-found fallback exactly as they are: a
   miss founds a keyed root, never a keyless line.
4. State the change once in the `workaholify` SKILL and let the template keep deferring
   to it — do not restate the rules in `drive.md`.
5. Update `CLAUDE.md` and `docs/drive-loop-runbook.md` in the same commit, and rebuild
   `outputs/` if a built skill changed.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- A unit whose artifact carries a `feedback:` ref posts its start and its finish into
  that item's thread, and both name the unit's pull request.
- A unit with no resolvable feedback ref still reports, by the existing fallback, and
  never posts a keyless top-level line.
- The postable-event list says per-unit where it now says per-run, in one place.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` for whatever resolution script this adds
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs`
- Read back a real thread after a drive run: root, start, finish, all under one key

**Gate** — what must pass before approval:

- Slack stays non-load-bearing: a failed or unreachable post never fails a run, blocks
  a claim, or delays a merge.
- No change to what `/drive` surveys, claims or implements — this is posts only.

## Considerations

- A unit's start is knowable at claim time and its finish at the route step, but a
  `handoff` is neither cleanly — deciding whether a handoff posts as a finish, or as its
  own line, is part of the work.
- A batch unit can carry tickets tracing to different feedback items, so "the item's
  thread" is not always singular; posting to each is the obvious reading but multiplies
  posts, and the bright line is deliberately conservative about volume.
- Under the `[Consent]` routine the merge is already announced in the same thread, so
  the finish post must not simply restate it.
