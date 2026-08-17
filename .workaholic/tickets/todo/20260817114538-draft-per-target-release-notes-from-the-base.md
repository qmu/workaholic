---
created_at: 2026-08-17T11:45:38+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817114537-derive-the-deploy-target-environment-mapping.md
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Draft per-target release notes from the base

## Overview

Expected action 2: for each deployment target, precompute from the pull requests and
branches merged into the default branch what the release note would say if that component
were deployed now, and hold it as a draft.

This is the heart of the ask and the place where `workaholic:ship` §7's first refusal
either dissolves or does not. The refusal was against **refreshing a merged note on `main`**:
for a target with no `paths:`, the refresh's own commit increments the `unreleased_count`
it reports, so each refresh invalidates itself. The reporter's design changes two things
that bear on it — the note is *per target* and its primary home is *GitHub Releases* — and
whether that is enough is the Open Decision below.

## Policies

- `workaholic:operation` / `policies/delivery.md` — what is waiting to ship is derived from the base, never remembered
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — a note is a reading of history; it must be reproducible from it

## Key Files

- `plugins/workaholic/skills/ship/scripts/read-deploy-state.sh` — already computes, per
  target, what is merged on the base and not yet released (`unreleased_count`,
  `attribution`, `paths:`). The generator's input, not a thing to reimplement.
- `plugins/workaholic/skills/ship/scripts/draft-deploy-plan.sh` — the existing per-unit
  drafter, idempotent (`changed: false`) and deliberately clock-free. The closest prior art
  and the model for idempotency.
- `plugins/workaholic/skills/write-release-note/SKILL.md` — the note's content structure and
  guidelines; a pure-prose skill, intentionally exposed.
- `plugins/workaholic/skills/ship/scripts/read-release-notes.sh`,
  `commit-release-note.sh` — the existing readers and writer for `.workaholic/release-notes/`.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the merged-PR list. REST only;
  `gh pr …` is refused by the transport rule and by `test-workflow-scripts.mjs`.
- `.workaholic/release-notes/` — today keyed by **branch** (`work-*.md`), not by target. The
  keying change is part of this ticket.

## Implementation Steps

1. Take the mapping from the previous ticket and, per target, compute the unreleased set
   from `read-deploy-state.sh` — never a second traversal of git.
2. For each unreleased merge, gather what the note needs: the pull request title and body,
   the branch story where one exists, and the archived tickets it carries. Prefer the story:
   it is the written record of *why*, which a commit list cannot reconstruct.
3. Render the draft through `workaholic:write-release-note`'s structure so a generated note
   and a hand-written one read alike.
4. Make it **idempotent and clock-free**, exactly as `draft-deploy-plan.sh` is: the same base
   state renders byte-identical output and reports `changed: false`. A timestamp inside the
   note is what turns an idempotent drafter into a commit treadmill.
5. Key the draft by target. Decide the naming (`<target>.md`, or `<target>/<release>.md`)
   with the sync ticket, since the GitHub side has its own identity for the same object.
6. Emit the draft without committing it — the write seam belongs to the cadence and sync
   tickets, which is what keeps this generator testable and pure.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A draft is produced per target, from `read-deploy-state.sh`'s unreleased set only.
- Two runs against an unchanged base produce byte-identical output and `changed: false`.
- No timestamp, sha or run-varying value appears in the rendered note body.
- A target with nothing unreleased produces an explicit empty draft, not an error.
- Every GitHub read goes through `gh-rest.sh`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Two consecutive generator runs, diffed: empty.
- A run against a synthetic two-target fixture where one target declares `paths:` and the
  other does not.

**Gate** — what must pass before approval:

- The Open Decision resolved and recorded in the Final Report.

## Open Decisions

1. **How does a note avoid counting itself?** For a target declaring no `paths:` —
   `attribution: whole_range`, which this repository's `marketplace` target uses — every
   commit on the base is unreleased for that target, including the commit that writes the
   note. `workaholic:ship` §7 refused the hourly writer for exactly this. Candidate answers,
   none of which this session can recommend outright: (a) require `paths:` on every target
   before enabling generation, which makes the feature opt-in and pushes work onto the
   record's human author; (b) exclude `.workaholic/release-notes/**` from every target's
   attribution by rule, which is a silent global carve-out in a field whose whole purpose is
   to be explicit; (c) keep the draft **only** in GitHub Releases (outside git) and mirror
   into `.workaholic` at release time rather than at draft time — which conflicts with the
   ask's "always identical" requirement (the sync ticket's decision); (d) commit the note but
   compute `unreleased_count` from a base excluding note commits, which makes the number
   depend on a rule a reader cannot see in the diff. Measure each against the diagnosis
   ticket's numbers before choosing.

## Considerations

- The branch-keyed history in `.workaholic/release-notes/` stays as it is; this adds a
  target-keyed draft alongside it. Rewriting the existing notes is not in the ask and would
  destroy the branch↔note relation the stories depend on.
- "What the note would say if the component were deployed now" is a prospective document.
  Keep it visibly prospective — a reader who mistakes a draft for a record of a release that
  happened is the failure mode this whole area exists to prevent.
