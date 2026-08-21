---
created_at: 2026-08-20T18:28:02+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260820182800-add-the-rename-registry-and-its-convergence-seam.md
mission: make-a-rename-a-registry-entry-not-a-sweep
merge_policy: auto
---

# Rename report to story and deprecate report

## Overview

PROPOSED. `/report` writes a **branch story**. The artifact is a Story, it lands in
`.workaholic/stories/`, its floor is `validate-story.sh`, the skill's own reference
file is `story-structure.md`, the mission seam calls it `story reported`, and
`review-sections` exists to generate "the branch story's review content". One thing
is called report: the command, and the skill behind it. `report` is also the wrong
word for what the command *is* — `/catch`, `/standup` and `/prepare-release` are all
reports and none of them writes an artifact.

The developer's ruling: `/story`, renamed **concept-deep** — `skills/report/` →
`skills/story/`, `workaholic:report` → `workaholic:story`, and every live reference
swept — with `/report` kept as a **deprecated alias that still works**. Deprecation is
not removal: routine prompts, docs and muscle memory keep working, and the alias says
so once per run.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/report.md` — the thin command (7 substantive lines);
  becomes `story.md`, and `report.md` becomes the deprecated alias.
- `plugins/workaholic/skills/report/` — `SKILL.md`, 5 `reference/` files
  (`create-pr.md`, `judge-deferred-concerns.md`, `orchestration.md`,
  `release-readiness.md`, `story-structure.md`) and 9 `scripts/`
  (`apply-deferred-concern-verdicts.sh`, `area-freshness.sh`, `collect-commits.sh`,
  `create-or-update.sh`, `doc-drift.sh`, `filter-low-concerns.sh`, `shrink-pr-body.sh`,
  `strip-frontmatter.sh`, `ticket-commits.sh`).
- **The callers** — `commands/{drive,implement,commit}.md`, `skills/drive/SKILL.md`
  and `reference/{routing,ticket-workflow}.md`, `skills/ship/SKILL.md` and
  `reference/{flow,scripts}.md`, `skills/mission/SKILL.md` +
  `reference/schema.md` (the *Automatic updates* table's two `report` rows),
  `skills/moderate/scripts/step-doc-drift.sh`, `skills/feedback/SKILL.md`,
  `skills/release-scan/SKILL.md`, `skills/review-sections/SKILL.md`,
  `skills/okf/SKILL.md`, `rules/{general,workaholic}.md`, `hooks/policy-lens.sh`.
- `scripts/build-plugins/build.mjs` — the closure scan keys on
  `${SCRIPT_DIR}/../../<skill>/scripts/`; `outputs/workflows/report/` becomes
  `outputs/workflows/story/` and five bundles' closures move with it.
- `scripts/test-workflow-scripts.mjs`, `scripts/e2e/loop-drill.sh`,
  `docs/{drive-loop-runbook,loop-drill-runbook}.md`, `README.md`,
  `plugins/workaholic/README.md`, `CLAUDE.md` (the `/report` row, the Development
  Workflow list, the release-scan section, the *Important* section's `doc-drift.sh`
  sentence), `CHANGELOG.md` (history — do not rewrite).

## Implementation Steps

1. **Add the registry rows first** — `name` rows for `workaholic:report` → `workaholic:story`
   and `/report` → `/story`, with the deprecation stated in the `why` clause so a
   consuming repository is told the alias still works rather than that its docs are
   broken. Run `rename-conversions.sh` and use its output as this ticket's own worklist.
2. **Move the skill**: `git mv plugins/workaholic/skills/report plugins/workaholic/skills/story`,
   then `name:` and the `description` in `SKILL.md`. Keep the 9 script filenames
   unchanged — they are named for what they do (`collect-commits.sh`,
   `doc-drift.sh`), not for the skill, and moving them would churn every
   `${CLAUDE_PLUGIN_ROOT}/skills/…/scripts/` reference for no gain. Record that
   decision in the commit body.
3. **Sweep the `workaholic:report` namespace and the `skills/report/scripts/` paths**
   across every caller in Key Files. `hooks/policy-lens.sh` and `rules/*.md` are part
   of the sweep, not afterthoughts.
4. **Write `commands/story.md`** as the thin command — identical body to today's
   `report.md`, naming `workaholic:story` and keeping the `workaholic:policy-lens`
   sentinel comment (`policy-lens.sh` matches that marker literally; losing it
   silently drops the policy injection).
5. **Rewrite `commands/report.md` as the deprecated alias.** It must run the identical
   workflow — a stub that refuses would break `[Implement]`'s routing and every
   document that names `/report`. Add one line to its `description` and one line the
   run emits: deprecated, use `/story`, same behaviour. **One behaviour per command**
   still holds: the alias has exactly one behaviour and it is `/story`'s.
6. **Do not rename the `## Changelog` event string** `story reported`, the story
   frontmatter, `validate-story.sh`, or `.workaholic/stories/` — they are already
   correct and are what this rename is converging *toward*. Check
   `mission/reference/schema.md`'s table: its `report` cells name the **seam**, so they
   become `story`, while the event string in the adjacent column does not move.
7. **Rebuild the bundle.** `outputs/workflows/report/` disappears and
   `outputs/workflows/story/` appears; five target bundles carry the renamed closure
   (`create-ticket`, `drive`, `report`→`story`, `ship`, `catch`, `mission` all pull
   `okf`, and several pull this skill). Confirm `verify.mjs` still finds every
   reference self-contained.
8. **Update the documentation in the same change**: `CLAUDE.md`'s command table row
   (retitled `/story`, with the alias stated), its Development Workflow step 3, its
   *Important* and release-scan sentences that name `/report`, `README.md`,
   `plugins/workaholic/README.md`, and both runbooks. `CHANGELOG.md` is history and is
   not rewritten.
9. **Verify**: `node scripts/build-plugins/build.mjs`, `verify.mjs`,
   `validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs`,
   `bash plugins/workaholic/hooks/layout-doctor.sh .`, and a real `/story` run on a
   throwaway branch that opens a PR and writes a story.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `/story` runs the branch-story + PR workflow through `workaholic:story`, and
  `plugins/workaholic/skills/story/` is the only home of that skill.
- `/report` runs the identical workflow and states once that it is deprecated in
  favour of `/story`; nothing that names `/report` today stops working.
- No live reference to `workaholic:report` or `skills/report/` survives outside
  `commands/report.md`, `CHANGELOG.md` and `.workaholic/` history.
- `outputs/workflows/` carries `story/` and no `report/`, and the build is clean.
- The registry carries both rows, so a consuming repository is told what the name
  became and offered the conversion.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "workaholic:report\|skills/report/" plugins/ scripts/ docs/ README.md CLAUDE.md`
  — only the alias command and history
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`
- `ls outputs/workflows/story && ! ls outputs/workflows/report`
- `node scripts/test-workflow-scripts.mjs`
- a `/story` run on a throwaway branch: a story file is written, the PR opens, the
  mission seam appends `story reported`
- the same run invoked as `/report`: identical result plus the deprecation line

## Considerations

- **Open Decision (the developer's, not this run's):** how long the `/report` alias
  lives. Deprecated-forever and deleted-at-the-next-major are both defensible; this
  ticket ships the alias with no expiry and records the question rather than inventing
  a date. The registry row is what makes the eventual deletion cheap.
- **Deprecation must not become a second behaviour.** The alias runs `/story`'s
  workflow verbatim — it is one command with one behaviour, which is what keeps it
  clear of the *one behaviour per command* rule. A `/report` that behaved differently,
  or refused, would break `[Implement]`'s routing and every document naming it.
- **This is the largest sweep of the three and the one most likely to break the
  bundle.** `build.mjs`'s closure scan keys on the literal
  `${SCRIPT_DIR}/../../<skill>/scripts/` form; a reference rewritten to
  `${CLAUDE_PLUGIN_ROOT}` during the sweep becomes invisible to it and the built
  bundle ships a skill missing its dependency. `verify.mjs` catches it — run it.
- **The script filenames deliberately do not move.** `doc-drift.sh` and
  `area-freshness.sh` are named for their jobs and are called by `/moderate` too;
  renaming them would widen this ticket into a second sweep with no reader benefit.
- **Do not sweep `.workaholic/` history or `CHANGELOG.md`.** Every story and archived
  ticket that says "report" described what was true when written.
- **`report` is also an ordinary English word** in these files (`/catch` reports,
  `run.sh` "reports" per step). The sweep is for the **namespace and the path**, not
  the word; a blind `sed` here is the failure mode, which is exactly why the registry
  proposes conversions rather than applying them.

## Final Report

Development completed as planned. The rename needed **five** registry rows rather
than the two the ticket anticipated — `workaholic:report`, `skills/report/`,
`report/scripts/`, `report/reference/` and `/report` — because the skill is
referenced in four distinct written forms and only the namespaced one was obvious
from the ticket. Adding a row and re-reading the conversions was how each of the
other three was found; that is the registry earning its keep on its first real
use, and it is worth stating that no single row would have been enough.

**The Open Decision is left open, deliberately.** How long the `/report` alias
lives is the developer's; the alias ships with no expiry and the question is
recorded here rather than answered by a date this run invented. The registry row is
what makes the eventual deletion cheap.

**Two judgment calls, both recorded rather than guessed:**

- **What the sweep must not touch.** `commands/report.md` (it is the alias and must
  say `/report`), `CHANGELOG.md` and `docs/loop-engineering-workflow.md` — the
  latter two are history, and `CLAUDE.md` names the second as a home of decision
  history by that exact path.
- **Script filenames did not move.** `doc-drift.sh`, `area-freshness.sh` and the
  other seven are named for their jobs, are called by `/moderate` as well, and
  moving them would widen this into a second sweep with no reader benefit.

**What was renamed *toward*, not away from.** `type: Story`, `.workaholic/stories/`,
`validate-story.sh`, `story-structure.md`, `story-sections.sh` and the
`story reported` changelog event were already correct and did not move; the
mission seam table's `report` **cells** did, because they name the seam.

### Discovered Insights

- **Insight**: the bulk conversion for `/report` corrupted two live strings the
  same way and neither was visible as a broken word — `ship/scripts/report-deploy-status.sh`
  became `story-deploy-status.sh` (the token matched `scripts/report-…`), and the JS
  regex `/reported verbatim…/` became `/storyed verbatim…/`. **Context**: the first
  was caught only by `verify.mjs`'s unresolved-reference check and the second only
  by reading the diff; a `/story[a-z]` scan missed the first because the next
  character was a hyphen. A token beginning with `/` is not a word boundary in any
  useful sense, and any future `name` conversion should be followed by
  `verify.mjs` plus a diff read rather than trusted.

- **Insight**: `scripts/build-plugins/build.mjs` carries `DEFAULT_TARGETS`, a
  hard-coded list of skill names, and it is the one place a skill rename fails
  *loudly* — the build threw `No SKILL.md for target 'report'`. **Context**: it is
  also the only such list; everything else resolved through path references the
  sweep had already fixed. A skill rename is therefore a three-part change — the
  directory, the references, and that array — and the build tells you about the
  third immediately, which is worth knowing before someone adds a second list.

- **Insight**: the registry's own documentation was itself swept twice — once in
  ticket 2 and again here — because it used **live tokens as examples**
  (`housekeep`, `workaholic:report`, `/report`). **Context**: a file explaining a
  rename mechanism is inside the blast radius of every rename it explains. The rule
  now written into `renames.tsv`'s header, `rename-conversions.sh`'s header and the
  workaholify skill is that the registry never illustrates itself with a token that
  exists; it describes the shape instead.
