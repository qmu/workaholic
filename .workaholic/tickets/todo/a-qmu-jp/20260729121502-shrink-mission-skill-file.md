---
created_at: 2026-07-29T21:15:02+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy: review
claim: work-20260730-180928
---

# Shrink the Mission Skill File

## Overview

Requested via GitHub issue [#101](https://github.com/qmu/workaholic/issues/101) (itself relaying a Slack request): `plugins/workaholic/skills/mission/SKILL.md` is 562 lines / 78 KB — the third-longest of the 28 skills and the densest per line (131 lines over 200 characters), well past `CLAUDE.md`'s own design principle that a skill runs roughly 50-150 lines. The bulk sits in `## Scripts` (~140 lines, a quarter of the file) and the six `## Schema` subsections (~122 lines).

Make the file smaller **without losing knowledge** — nothing described in it today may be deleted outright, only relocated (to a companion reference file the skill links to) or tightened in place (denser wording that keeps every fact). Exactly what survives where is the implementer's call.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — any relocated content must land in a conventional location (e.g. a `skills/mission/reference/` subdirectory the skill links to), not scattered ad hoc
- `workaholic:implementation` / `policies/coding-standards.md` — applies to any bundled script this touches incidentally (none are expected to change behavior, only their doc references)
- `workaholic:implementation` / `policies/objective-documentation.md` — "tightened" must not mean "vaguer": every currently-stated fact (script contracts, schema fields, lifecycle rules) must remain checkable after the rewrite, whether it stays in `SKILL.md` or moves to a linked file

## Key Files

- `plugins/workaholic/skills/mission/SKILL.md` - the file to shrink
- `plugins/workaholic/rules/workaholic.md` - references the mission skill's layout/schema; check for cross-references that assume specific `SKILL.md` section locations
- `plugins/workaholic/hooks/validate-mission.sh`, `plugins/workaholic/hooks/mission-lens.sh` - consumers whose comments cite `mission/SKILL.md` sections by name; verify none point at a section that moves without updating the pointer
- `scripts/build-plugins/build.mjs` - builds this skill (with `${CLAUDE_PLUGIN_ROOT}` rewritten to relative paths) into `outputs/workflows/`; any new companion file under `skills/mission/` must be included in that self-contained bundle
- `CLAUDE.md` - states the ~50-150 line skill guideline this ticket is answering; no change expected, cited for context only

## Related History

No prior ticket in `.workaholic/tickets/archive/` specifically shrank a skill file; this is a new maintenance category. The mission skill itself has been amended incrementally many times (ownership moves, lifecycle redefinitions, claim protocol) which is presumably why it accreted to its current size — each amendment added content but none consolidated.

## Implementation Steps

1. Re-read `plugins/workaholic/skills/mission/SKILL.md` in full and classify each section by how load-bearing it is at *skill-load time* (every agent reading `/mission` pays for the whole file) versus *reference-only* (needed only when actually running a specific script or reading a specific schema field).
2. Relocate the `## Scripts` section's per-script prose (currently ~140 lines) into a companion reference file (e.g. `plugins/workaholic/skills/mission/reference/scripts.md`), leaving a short table or list in `SKILL.md` naming each script, its one-line purpose, and a link to the reference file for the full contract.
3. Do the same for the six `## Schema` subsections (~122 lines) — fold the frontmatter field table and its prose into a companion reference file, keeping only the schema block itself (or an even shorter summary) inline in `SKILL.md`.
4. Tighten dense prose elsewhere in the file (the Granularity, Lifecycle, Replan, and Close sections carry redefinition records and design-rationale asides that could compress without losing the decision itself — keep the *what was decided and why*, trim the *how many alternatives were narrated*).
5. Update every in-repo reference that assumes a section lives at a specific location in `SKILL.md` (grep the plugin and `docs/` for `mission/SKILL.md` mentions).
6. Regenerate `outputs/workflows/` (`node scripts/build-plugins/build.mjs`) so the generated, self-contained bundle picks up the new file(s) — confirm the build step correctly inlines or copies any new companion file under `skills/mission/`.
7. Run the verification commands in `## Quality Gate` below.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- [ ] `plugins/workaholic/skills/mission/SKILL.md`'s line count drops substantially from 562 — directionally toward the repo's own 50-150 line guideline, though a file this information-dense may reasonably land above that band once reference material is properly split out. Decided: no single hard target line count is set here, since the right number depends on how much genuinely belongs inline vs. in a reference file — the implementer judges this against the guideline, not against an arbitrary cutoff (developer may override at `/drive`).
- [ ] Every fact present in the original file (script contracts/argument shapes/emitted JSON keys, schema fields and their meaning, lifecycle/ownership/merge-policy rules, the redefinition records) is still findable somewhere in the skill's own directory after the change — either inline or in a linked companion file — none simply deleted.
- [ ] `SKILL.md` links to any companion file it relocated content into, so a reader following the skill is never left without the pointer.
- [ ] No other file in the repo references a `mission/SKILL.md` section by an assumption that breaks (e.g. a comment citing "`workaholic:mission`'s *Ownership* section" must still resolve to real content, wherever it now lives).

**Verification method** — the commands/tests/probes that prove them:

- `wc -l plugins/workaholic/skills/mission/SKILL.md` before/after, reported in the Final Report.
- `node scripts/build-plugins/build.mjs` followed by `node scripts/build-plugins/verify.mjs` — both must succeed, confirming the generated `outputs/workflows` bundle for the mission skill stays self-contained.
- `node scripts/test-workflow-scripts.mjs` — the hermetic smoke tests exercising mission scripts must stay green (this ticket is not expected to change script behavior, only documentation, but the suite is the regression backstop).
- `grep -rn "mission/SKILL.md" plugins/ docs/ --include=*.md --include=*.sh` (and equivalent for prose references like "workaholic:mission's *Ownership* section") to confirm every citation still resolves after the reorganization.

**Gate** — what must pass before approval:

- All four verification commands above succeed, and a reviewer diffs the relocated/tightened sections against the original file to confirm no fact was silently dropped (the one thing a line-count number and a passing test suite cannot themselves prove).

## Considerations

- This is a **documentation/structure-only** change; no script behavior, schema shape, or workflow logic should change as a side effect. If the review turns up a genuine inconsistency in the current file while shrinking it, record it as a `kind: concern` feedback record rather than silently "fixing" scope beyond the shrink (`workaholic:feedback`).
- `outputs/workflows/` is generated and CI-guarded (`Outputs Freshness`) — any restructuring of `plugins/workaholic/skills/mission/` must be followed by a rebuild in the same change, or CI will fail the diff.
- The six-pillar/28-skill count and the "third-longest" framing in the originating issue were measured 2026-07-29; if this ticket is picked up much later, re-measure rather than trusting the stale figures.
