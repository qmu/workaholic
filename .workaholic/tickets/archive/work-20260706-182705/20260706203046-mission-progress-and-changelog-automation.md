---
created_at: 2026-07-06T20:30:46+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort: 2h
commit_hash: b7a11ad
category: Changed
depends_on: [20260706203044-mission-artifact-type-and-command.md, 20260706203045-mission-frontmatter-linkage.md]
---

# Roll mission progress and append the historical changelog from the workflows

## Overview

With the mission artifact (ticket 1) and the machine-readable relations on every artifact
(ticket 2) in place, close the loop: as work moves through the workflow, **update the related
mission** — append human-readable changelog lines and recompute progress toward achievement.

Two things happen automatically whenever a missioned artifact reaches a milestone:

1. **Changelog line appended** to `missions/<slug>/mission.md` `## Changelog` — a dated,
   human-readable line relating the ticket/report/concern to the mission (this is the
   developer's "historical stuck changelog": ticket archived, story shipped, concern deferred
   ("stuck"), concern resolved ("unstuck")).
2. **Acceptance checklist updated** — the item whose ticket/story just completed flips to
   `[x]`, and progress (`checked ÷ total`, from ticket 1's `progress.sh`) reflects how far the
   mission has come.

Trigger points, reusing the existing OKF-refresh seams (`okf` skill "When It Runs"):

- **`/drive`** — `archive.sh`: when an archived ticket has `mission:`, append a
  "ticket archived" changelog line and tick the matching acceptance item.
- **`/report`** — the story flow: when a story has `mission:`, append a "story shipped /
  reported" line and reconcile acceptance items for its `tickets:`. Judged carry-over verdicts
  append "concern resolved (unstuck)" lines.
- **`/ship`** — `extract-carryover.sh`: when a concern has `mission:`, append a "concern
  deferred (stuck)" line to the mission changelog.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code and keep every change defensible against
its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — new logic lives in the
  owning skills' `scripts/`; no new top-level surfaces.
- `workaholic:implementation` / `policies/coding-standards.md` — script edits follow house style.
- `workaholic:implementation` / `policies/command-scripts.md` — the append/tick/recompute logic
  is bundled POSIX scripts called from `archive.sh` / report / `extract-carryover.sh`, never
  inline conditional shell in markdown (`rules/shell.md`).
- `workaholic:implementation` / `policies/objective-documentation.md` — progress is **computed**
  from the checklist state, never asserted; changelog lines state verifiable events.
- `workaholic:implementation` / `policies/observability.md` — mission progress and the changelog
  are the observable signal of "how far to achievement"; make them queryable via `/mission`.
- `workaholic:design` / `policies/history-structures.md` — the changelog is append-only and
  ordered; never rewrite past lines.
- `workaholic:operation` / `policies/ci-cd.md` — the appends must keep `refresh-index.sh`
  idempotent and the `outputs/` tree fresh.

## Key Files

- `plugins/workaholic/skills/drive/scripts/archive.sh` - the archive seam; append a mission
  changelog line + tick acceptance when an archived ticket carries `mission:` (already calls
  `okf/refresh-index.sh`).
- `plugins/workaholic/skills/report/` (+ `review-sections`) - the story flow; append on story
  ship and reconcile acceptance for the story's `tickets:`; append "unstuck" on resolved
  carry-overs.
- `plugins/workaholic/skills/ship/scripts/extract-carryover.sh` - append a "stuck" changelog
  line when a missioned concern is extracted.
- `plugins/workaholic/skills/mission/scripts/` - a shared `append-changelog.sh` and
  `tick-acceptance.sh` (or extend `progress.sh`) that all three seams call, so the append/tick
  logic lives in one place (the mission skill), not duplicated per workflow.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` - ensure appended mission changes
  keep the index deterministic/idempotent.
- `CLAUDE.md`, `.workaholic/README.md` - document the automatic mission updates in the OKF
  "When It Runs" flow.

## Related History

`archive.sh`, `commit-release-note.sh`/`extract-carryover.sh`, and the report story flow already
call `okf/refresh-index.sh` just before committing knowledge — the same seams that keep the OKF
hierarchy fresh are where the mission update hooks in, so no new orchestration seam is introduced.

## Implementation Steps

1. **Centralize the mutation in the mission skill.** Add `skills/mission/scripts/append-changelog.sh`
   (append a dated line under `## Changelog` for a given mission slug + event) and
   `tick-acceptance.sh` (flip the acceptance item matching a ticket/story to `[x]`). Keep them
   append-only and idempotent (re-running for the same event must not duplicate a line).
2. **Drive seam**: in `drive/scripts/archive.sh`, when the ticket frontmatter has `mission:`,
   call `append-changelog.sh` ("ticket archived") and `tick-acceptance.sh` before the existing
   `refresh-index.sh` + stage.
3. **Report seam**: on story generation with `mission:`, append "story reported/shipped" and
   reconcile acceptance for the story's `tickets:`; on a carry-over judged resolved, append
   "concern resolved (unstuck)".
4. **Ship seam**: in `extract-carryover.sh`, when the concern has `mission:`, append
   "concern deferred (stuck)".
5. **Surface**: ensure `/mission` (ticket 1) now shows real progress and the accumulated
   changelog.
6. **Regenerate + version**: `node scripts/build-plugins/build.mjs` (drive, report, ship, mission
   are shipped skills) and bump the version.

## Quality Gate

Full automated gate (Workflow Step 4b).

**Acceptance criteria** — the checkable conditions that must hold:

- Archiving a missioned ticket appends exactly one `## Changelog` line to its mission and flips
  the matching acceptance item to `[x]`; `progress.sh` then reports the higher `checked/total`.
- Re-running the archive/append for the same event does **not** add a duplicate line
  (idempotent append).
- A missioned concern extracted at ship time appends a "stuck" line; a resolved carry-over at
  report time appends an "unstuck" line.
- After any append, `okf/refresh-index.sh` run twice yields no diff on the second run.
- An un-missioned ticket/story/concern leaves all missions untouched.

**Verification method** — the commands/tests/probes that prove them:

- New hermetic assertions in `node scripts/test-workflow-scripts.mjs`: build a fixture repo with
  a mission + a missioned ticket; run `archive.sh`; assert one changelog line, the acceptance tick,
  and the new `progress.sh` count; run again and assert no duplicate; run with an un-missioned
  ticket and assert the mission is unchanged.
- `node scripts/build-plugins/verify.mjs` + `validate-metadata.mjs` green.
- `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/ hooks/policy-index.md` empty.
- `posix-lint` clean on edited/added scripts.

**Gate** — what must pass before approval:

- The new idempotency + rollup smoke tests green, verify/validate green, outputs/ + policy-index.md
  clean after rebuild, `refresh-index.sh` idempotent, posix-lint clean, and the OKF "When It Runs"
  docs updated in the same commit.

## Considerations

- **Idempotency is the sharp edge** — the drive/report/ship seams can re-run (retries, re-reports);
  the append/tick scripts must key on a stable event id (ticket filename + event) so a mission's
  changelog never double-counts (`skills/mission/scripts/append-changelog.sh`).
- **Single writer for mission mutation** — all three workflows must go through the mission skill's
  scripts, not hand-edit `mission.md`, so the format and idempotency rule live in one place.
- **Progress is derived, never stored as a number** — keep `checked/total` computed from the
  checklist (`progress.sh`); do not persist a `progress:` percentage that can drift from reality
  (`workaholic:implementation` / `policies/objective-documentation.md`).
- **Acceptance-item matching** — flipping the right item needs a stable link from acceptance line
  to ticket/story (e.g. the `(#filename)` reference in the checklist); define that convention in
  ticket 1's schema and rely on it here.
- **Depends on tickets 1 and 2** — needs the mission skill/scripts and the `mission:`/`tickets:`
  relations already emitted on artifacts.

## Final Report

Development completed as planned. All mission mutation is centralized in two shared, idempotent scripts in the mission skill; the drive/ship/report seams read each artifact's `mission:` relation and call them. Version bumped to 1.0.83.

### Discovered Insights

- **Insight**: Idempotency is keyed on `(event, artifact)` with the date deliberately excluded from the key. `append-changelog.sh` greps for the `"<event> — <artifact>"` substring before appending, so a re-run on a different day still no-ops. This is what makes the drive/report/ship seams safe to re-run (retries, re-reports) without double-counting a mission's history.
- **Insight**: The mutators git-stage the mission file themselves (`git add "$FILE" || true`), so no seam needs to change its staging logic — drive's `git add -A` and the report/ship commits pick the mission change up automatically. This mirrors the ticket-1 lesson about unstaged deletions: the writer stages its own output.
- **Insight**: Wiring the seams expanded the build closures — `drive`, `report`, and `ship` now bundle the `mission` skill (via `archive.sh`, `apply-deferred-concern-verdicts.sh`, `extract-deferred-concerns.sh` referencing `${SCRIPT_DIR}/../../../../workaholic/skills/mission/scripts/`). The build-detectable `${SCRIPT_DIR}` reference form is mandatory here; a computed path (e.g. `$(cd ...)/../...`) would pass the shell but be invisible to `build.mjs`, shipping a broken closure to Codex. `verify.mjs` confirms self-containment.
- **Insight**: The tick regex uses alternation-free `\[ \]` (unchecked box) and matches the artifact via `index($0, "(#" artifact ")")` rather than a regex, so filenames with regex-special characters (dots) match literally and the source never contains a `[[` the POSIX lint would flag.
