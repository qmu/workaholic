---
created_at: 2026-08-17T11:45:38+00:00
status: done
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

## Final Report

Development completed as planned.

### The Open Decision, resolved: (c) — the draft lives only outside git

**How does a note avoid counting itself? By never being a commit.**

The diagnosis ticket measured the problem rather than restating it: `paths:` is declared
on **0 of 1** targets here, so `attribution: whole_range` is not an edge case but this
repository's only state; under it a note commit is **100 % self-counted**, and a daily
committing writer is **+365 commits/year** on `main`, each one incrementing the number the
next day's regeneration reports. Measured against that number, the four candidates:

- **(a) require `paths:` on every target before enabling generation** — pushes the work
  onto the record's human author and makes the feature silently unavailable in exactly the
  repositories that have not done it. It also does not actually close the hole: a target
  may legitimately declare `paths:` that covers `.workaholic/`.
- **(b) carve `.workaholic/release-notes/**` out of every target's attribution by rule** —
  a silent global exception inside the one field whose entire purpose is to be explicit. A
  reader of the record cannot see the rule that changed their number.
- **(d) compute `unreleased_count` from a base excluding note commits** — same defect, one
  level deeper: the number depends on a rule invisible in the diff.
- **(c) keep the draft outside git and write `.workaholic` at release time** — **chosen.**
  The refusal in `workaholic:ship` §7 was against *committing* a regenerated document. Take
  the commit away and the refusal has nothing left to bite: there is no note commit, so
  nothing self-counts, and the arithmetic above goes to zero rather than being compensated
  for. It is the only candidate that removes the problem instead of correcting for it.

**Its stated conflict with "always identical" is answered, not dismissed.** The ticket
flagged (c) as conflicting with the ask's dual-recording requirement. The answer is that
identity is guaranteed **by derivation rather than by copying**: one renderer, one input
(the base state), so wherever both copies exist they are byte-identical by construction,
and the sync reports any divergence per target and section instead of repairing it
blindly. That is ticket 5's ruling and this ticket defers to it rather than pre-empting it.

### What was built

`ship/scripts/draft-release-note.sh` — a pure renderer, `[--target <slug>] [--out <dir>]
[--enrich] [base]`:

- The unreleased set is **taken from `read-deploy-state.sh --rows`, never re-derived**. That
  reader owns the boundary and the attribution; this script asks git only for the *detail*
  inside the range it was handed (subjects, `Category:` trailers, merge subjects).
- The body follows `workaholic:write-release-note`'s structure, so a generated draft and a
  hand-written note read alike, and its first paragraph says it is a draft.
- **Idempotent and clock-free.** Verified: two consecutive stdout runs are byte-identical
  (`diff -q` empty), the same `body_sha` both times, and a second `--out` run reports
  `changed: false`.
- **A target with nothing unreleased renders an explicit empty draft**, not an error and
  not an absent file.
- **Writes nothing into the repository.** No `--out` ⇒ no file touched at all; `--out`
  materialises under a caller-chosen directory. `changed` is `null` without `--out`, because
  with nothing to compare against `false` would be a claim the script cannot make.

### On "no timestamp, sha or run-varying value in the body"

Held, with one thing named rather than glossed: the body contains no clock, no commit sha
and no boundary sha — the boundary is named in words (`latest_tag:v1.0.178`) precisely so
the body has no sha in it. It *does* contain merged **branch names** (`work-20260817-133501`),
whose form happens to embed a date. That is the identity of a merged branch and a stable
property of history, not a reading of the run's clock — which is why the byte-identity
check, not a regex, is the property that was verified.

### `--enrich` is off by default

Pull request bodies are fetched through `gather/scripts/gh-rest.sh` (REST only) and only
when asked for. Remote content can change under an unchanged base, so enriching by default
would make a daily generator produce a diff on a day nothing happened — it would trade the
idempotency the whole cadence rests on for detail already available locally in the merge
subject and the story.

### Verification

- Two consecutive runs diffed: empty. `changed: false` on the second `--out` run.
- **Synthetic two-target fixture**, as required: `api` declares `paths: [api/**]`, `web`
  declares none. After one commit under `api/` and one under `infra/`, `api` reports
  `unreleased_count: 1` with only its own commit rendered, `web` reports `2` with both —
  the per-target attribution splits the range correctly.
- The same fixture with the tag at `HEAD`: both targets render the explicit empty draft.
- `web` declares no `confirmation_method`: rendered as *"this target declares no
  confirmation method"* with the note that `/ship` halts on it, never as an unverified
  success.
- `node scripts/test-workflow-scripts.mjs`, `build.mjs`, `verify.mjs`.

### Discovered Insights

- **Insight**: A story in this repository carries neither a `title:` frontmatter field nor
  an H1 — checked across all 197 of them. Its title-equivalent is the first sentence under
  `## 1. Overview`, and both obvious extractors return empty.
  **Context**: Any generator summarising branch work must read the Overview paragraph, not
  a title field. The first version of this renderer silently emitted "no branch story
  joined" for every merge because both extractors failed quietly — a reminder that a
  missing-data path which prints a plausible sentence is harder to notice than one that
  errors.

- **Insight**: `verify.mjs` treats any `<skill>/scripts/<file>` string in a SKILL.md as a
  script reference that must resolve inside the generated bundle. `write-release-note` is
  deliberately prose-only and carries no script closure, so documenting a generator by its
  path breaks the bundle even though the prose is correct.
  **Context**: In a prose-only skill, name a script as ``workaholic:<skill>`'s `<file>` ``
  rather than by path. The constraint is a feature — it is what keeps the exposed
  cross-agent bundle self-contained.
