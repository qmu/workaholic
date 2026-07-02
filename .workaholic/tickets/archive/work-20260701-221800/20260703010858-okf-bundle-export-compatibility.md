---
created_at: 2026-07-03T01:08:58+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort: 2h
commit_hash: 8e8e690
category: Added
depends_on:
---

# Support the Open Knowledge Format (OKF) as a generated export target

## Overview

Google announced the Open Knowledge Format (OKF, v0.1) as an industry standard for vendor-neutral knowledge interchange: plain markdown files with YAML frontmatter organized as directory bundles, with optional `index.md` files for progressive disclosure and standard markdown links expressing concept relationships (spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf — `okf/SPEC.md`).

Workaholic's knowledge already lives on exactly this substrate (markdown + frontmatter skills and policy hard copies, generated self-contained bundles, a generated policy index, CI freshness guarding), so compatibility is a convention-and-metadata alignment job, not a rewrite. This ticket adds OKF as **one more generated export target** of the existing cross-agent distribution pipeline: `scripts/build-plugins/build.mjs` emits a committed, CI-guarded, OKF-conformant bundle under `outputs/okf/` derived from the policy hard copies (and the exposed pure-prose skills), behind a thin translation boundary — source conventions in `plugins/` stay untouched.

Key OKF v0.1 spec facts the emitter must honor:

- Every non-reserved `.md` file must carry parseable YAML frontmatter with a non-empty `type` field (the only required key; values are producer-defined, not centrally registered).
- Recommended keys: `title`, `description`, `resource` (canonical URI), `tags` (string list), `timestamp` (ISO 8601 of last meaningful modification). Extra keys are permitted; consumers must preserve unknown fields.
- `index.md` and `log.md` are reserved filenames — never concept documents. `index.md` is optional at any level; the bundle-root `index.md` is the one place a bundle may declare its target `okf_version` (`<major>.<minor>`).
- Links may be bundle-absolute (leading `/`, resolved from bundle root — recommended for refactoring stability) or relative; broken links are tolerated but ours should resolve.
- Concept IDs are the file path minus `.md`.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work); governs where the new `outputs/okf/` bundle lands relative to `outputs/workflows/`
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions for the new build code in `scripts/build-plugins/*.mjs` (declarative style, validation at unknown boundaries when parsing/emitting frontmatter)
- `workaholic:implementation` / `policies/vendor-neutrality.md` — adopting OKF is a new external-standard dependency: requires a dependency-decision log (Reason/Assessment/Monitoring/Exit strategy) and an anti-corruption/translation boundary so Google's format never drives workaholic's internal knowledge model
- `workaholic:design` / `policies/vendor-neutrality.md` — endorses exporting to open standards (data portability is the exit path) while demanding the integration boundary stay thin: OKF support is a translation layer at the edge of the build pipeline
- `workaholic:planning` / `policies/ai-native-future.md` — "do not commit to uncertain formats": OKF is v0.1 and just announced; support must stay rebuildable and never become workaholic's only knowledge representation (deleting the emitter is the exit)
- `workaholic:planning` / `policies/accessibility-first.md` — emitting OKF bundles is a concrete instance of "AI as information consumer": knowledge published in the same structured, machine-readable form humans read
- `workaholic:planning` / `policies/terminology.md` — reconcile OKF vocabulary (bundle, concept, `type`, `resource`, `timestamp`) with workaholic's established terms (skill, policy, `title`/`slug`/`category`/`source`) as an explicit mapping at the boundary, not accumulated synonyms
- `workaholic:implementation` / `policies/command-scripts.md` — OKF emission must be encapsulated in the repo's runnable build scripts so CI invokes the same command a developer does; no generation logic living only in CI YAML
- `workaholic:operation` / `policies/ci-cd.md` — the generated `outputs/okf/` bundle inherits the Outputs Freshness discipline: rebuild-and-diff in CI keeps artifact and source in lockstep
- `workaholic:implementation` / `policies/objective-documentation.md` — the adoption decision and the emitter's actual conformance guarantees are documented in verifiable language, reviewed in the same PR as the code

## Key Files

- `scripts/build-plugins/build.mjs` - the build orchestrator; its `publicizeSkillMd()` already strips/rewrites frontmatter and `${CLAUDE_PLUGIN_ROOT}` refs at publish time — the natural seam for the OKF emitter and frontmatter mapping
- `scripts/build-plugins/policy-index.mjs` - the repo's only existing auto-generated index generator (`generatePolicyIndex`); the direct template for the OKF bundle-root `index.md` emitter
- `scripts/build-plugins/verify.mjs` - asserts generated skills are self-contained and the policy index is fresh; gains the OKF conformance assertions (frontmatter parses, `type` non-empty, links resolve, reserved filenames respected)
- `scripts/build-plugins/validate-metadata.mjs` - manifest well-formedness/version alignment; extend only if the OKF bundle grows manifest-level metadata
- `plugins/workaholic/skills/{planning,design,implementation,operation}/policies/*.md` - the ~60 policy hard copies (frontmatter: `title`/`slug`/`category`/`source`) that become OKF concept documents via the frontmatter mapping (read-only inputs — not modified)
- `plugins/workaholic/skills/{planning,design,implementation,operation}/SKILL.md` - the four pillar indexes whose `## Policies` TOC sections group the concepts for the generated `index.md`
- `outputs/` - the committed generated-artifact tree; `outputs/okf/` is the new sibling of `outputs/workflows/`
- `.github/workflows/outputs-freshness.yml` - CI backstop; its existing `outputs/` diff automatically covers `outputs/okf/` (confirm — no explicit path addition should be needed)
- `CLAUDE.md` - the Project Structure and Local Verification sections describe `outputs/`; document the new target

## Related History

The May–June 2026 cross-agent distribution work built every mechanism OKF compatibility needs: a build step generating self-contained public bundles from DRY source, per-target manifests over one neutral generated dir, a generated index with progressive-disclosure discipline, and a CI freshness guard. OKF slots in as another consumer of that pipeline, not a greenfield effort.

Past tickets that touched similar areas:

- [20260527012301-build-step-for-self-contained-portable-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260527012301-build-step-for-self-contained-portable-skills.md) - Introduced the build pipeline generating self-contained skill folders (same generation machinery an OKF target hooks into)
- [20260525205529-package-core-standards-cross-agent-skills.md](.workaholic/tickets/archive/work-20260518-235327/20260525205529-package-core-standards-cross-agent-skills.md) - Made skills installable by non-Claude agents per the Agent Skills standard (same vendor-neutral distribution goal)
- [20260619011557-always-loaded-policy-index-injection.md](.workaholic/tickets/archive/work-20260618-182253/20260619011557-always-loaded-policy-index-injection.md) - Generated the policy-index digest from the pillar `## Policies` sections (direct analogue of OKF's generated `index.md`)
- [20260527012303-codex-plugin-manifests-and-exposure.md](.workaholic/tickets/archive/work-20260518-235327/20260527012303-codex-plugin-manifests-and-exposure.md) - Precedent for adding a new distribution target alongside existing ones without disturbing them
- [20260527142132-add-dist-freshness-ci-check.md](.workaholic/tickets/archive/work-20260518-235327/20260527142132-add-dist-freshness-ci-check.md) - Added the rebuild-and-diff CI guard the new generated bundle extends
- [20260527012302-agent-neutral-workflow-skill-prose.md](.workaholic/tickets/archive/work-20260518-235327/20260527012302-agent-neutral-workflow-skill-prose.md) - Precedent for vendor-neutral knowledge content, which OKF-consumable output requires

## Implementation Steps

1. **Read the authoritative spec first**: fetch and read `okf/SPEC.md` from the knowledge-catalog repo in full; pin the target `okf_version` (0.1) and note any detail this ticket's summary got wrong (in particular the exact rules for bundle-root `index.md` structure and where `okf_version` is declared — the spec elsewhere says `index.md` carries no frontmatter, so resolve that contradiction against the real spec text).
2. **Record the dependency-decision log** per `implementation/vendor-neutrality`: Reason (industry-standard interchange for the policy/skill knowledge base), Assessment (v0.1 maturity, Google governance, permissive consumption model), Monitoring (watch spec releases; revisit at the policy-conformance audit), Exit strategy (delete the emitter — no source coupling). Commit it with the PR in verifiable language (`implementation/objective-documentation`).
3. **Add the OKF emitter to `build.mjs`** (new module `scripts/build-plugins/okf.mjs` following the `policy-index.mjs` pattern; wire into the argument-less full build only, like the policy index):
   - Inputs: the four pillars' `policies/*.md` hard copies (and the intentionally exposed pure-prose skills — `write-release-note`, `review-sections` — if they map cleanly as concepts; skip `metadata.internal` skills entirely).
   - Frontmatter mapping (the terminology boundary, one place only): `type` ← a producer-defined descriptor such as `Engineering Policy`; `title` ← `title`; `description` ← first-sentence summary (from the pillar TOC line); `resource` ← the `source:` qmu.co.jp URL; `tags` ← `[<pillar>, <slug>]`; `timestamp` ← last-meaningful-modification derived deterministically from git (`git log -1 --format=%cI -- <file>`), never wall-clock time.
   - Preserve original body prose verbatim; rewrite intra-bundle links to bundle-absolute (leading-`/`) form; never emit `${CLAUDE_PLUGIN_ROOT}`.
4. **Generate the bundle-root `index.md`** declaring the target `okf_version` (per whatever the real SPEC.md mandates for its structure) and listing concepts grouped by pillar with relative links and one-line descriptions — reuse the grouping already maintained in the pillar `## Policies` sections.
5. **Extend `verify.mjs`** with OKF conformance assertions over `outputs/okf/`: every non-reserved `.md` parses as YAML frontmatter + body; `type` is non-empty everywhere; `index.md`/`log.md` never appear as concept documents; all intra-bundle links resolve to files inside the bundle.
6. **Confirm CI coverage**: the Outputs Freshness workflow's existing `outputs/` diff covers `outputs/okf/`; run the full local verification suite.
7. **Document**: update `CLAUDE.md`'s Project Structure (`outputs/okf/`) and Local Verification sections; note the OKF target is opt-in knowledge interchange, consumed by any OKF reader via the git repo (the spec's recommended distribution), with no marketplace manifest required.
8. **Make the runtime-generated `.workaholic/` markdown OKF-conformant** (Revision 1 — the developer's primary intent): every markdown file the workflow skills write into a project's `.workaholic/` tree must satisfy OKF's conformance floor — a parseable YAML frontmatter block whose `type` is non-empty. Tickets already conform (`type: enhancement|bugfix|refactoring|housekeeping` — producer-defined values are explicitly allowed). Update the file-writing templates in the skills whose artifacts lack frontmatter, adding a minimal OKF-conformant block (`type` + existing metadata conventions like `created_at`/`author` as extra keys, which OKF consumers must preserve):
   - `report` / `review-sections` — the branch story file (`.workaholic/stories/<branch>.md`): `type: Story`.
   - `write-release-note` — the release note file (`.workaholic/release-notes/`): `type: Release Note`.
   - `ship` — deferred concern/idea files (`.workaholic/concerns/`): `type: Concern`.
   - `carry` / `trip-protocol` — trip checkpoints and design documents (`.workaholic/trips/`): `type: Design` / `type: Checkpoint` (resumption tickets already use the ticket format).
9. **Keep source conventions primary**: OKF conformance is additive — do not rename existing keys (`created_at` stays `created_at`; OKF tolerates unknown keys), do not break `validate-ticket.sh`, `collect`-side parsers, or the report workflow's story readers.
10. **Regenerate `outputs/workflows`** (the changed skills ship in the portable bundle) and re-run the full verification suite.
11. **Switch the workflow-maintained directory index to OKF's reserved `index.md`** (Revision 2): the story index the report workflow maintains moves from `.workaholic/stories/README.md` to `.workaholic/stories/index.md` in OKF index form (no frontmatter; `* [title](file.md) - description` entries) so OKF readers recognize it as the navigation index; update `catch`'s `scan-window.sh` to exclude `index.md` alongside `README.md` when scanning stories; migrate this repo's existing `stories/README.md` to the new form.
12. **Make `.workaholic/` itself an OKF bundle hierarchy that the workflows keep organized** (Revision 3 — the developer's core requirement): add a bundled index-refresh script (new internal `okf` skill) that deterministically regenerates the bundle entry point `.workaholic/index.md` (frontmatter `okf_version: "0.1"` — the bundle root is the one `index.md` allowed frontmatter) listing each present knowledge area, plus per-directory `index.md` files for the flat knowledge dirs (`release-notes`, `concerns`, `deployments`, `guides`, `specs`, `policies`, `terms`) and `trips/` (one entry per trip linking its `plan.md`). Entry titles/descriptions derive from each file's frontmatter (falling back to the H1), so the hierarchy reorganizes itself from what exists. `stories/index.md` stays report-maintained (richer hand-written descriptions) and is linked, not regenerated; `tickets/` internals are never touched (its queue scripts and structure guards own that tree — the root index links the directory without generating indexes inside it).
13. **Wire the refresh into the writing flows**: `drive`'s `archive.sh` runs the refresh before its commit so every archived ticket ships with a fresh hierarchy; the `report` and `ship` flows run it after writing stories/release-notes/concerns and stage the refreshed indexes with their existing commits.

## Quality Gate

How the outcome's quality is assured. **Note:** the developer was away at ticket time, so these criteria are the interrogation's recommended defaults (export-target scope; all four acceptance criteria; full-suite gate) adopted autonomously — the `/drive` approval prompt is where the developer confirms or adjusts them before implementation is accepted.

**Acceptance criteria** — the checkable conditions that must hold:

- Every non-reserved `.md` emitted under `outputs/okf/` parses as YAML frontmatter + markdown body and carries a non-empty `type` field (OKF v0.1 conformance rule).
- `index.md` and `log.md` never appear as concept documents; a generated bundle-root `index.md` declares the target `okf_version` and lists all emitted concepts grouped by pillar.
- All intra-bundle links in emitted documents resolve to files inside `outputs/okf/` (no `${CLAUDE_PLUGIN_ROOT}`, no repo-external relative paths).
- A dependency-decision log for adopting OKF v0.1 (Reason/Assessment/Monitoring/Exit strategy) is committed in the same PR.
- Source files under `plugins/` are byte-identical before and after the change except for build-script edits — the translation happens entirely at publish time.
- Running `node scripts/build-plugins/build.mjs` twice in a row produces zero diff (deterministic output; no wall-clock timestamps).
- (Revision 1) Every markdown artifact template the workflow skills write into `.workaholic/` produces a file with a parseable YAML frontmatter block and a non-empty `type` — the OKF conformance floor — without renaming any existing metadata key.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs` regenerates `outputs/` cleanly, then `git status --porcelain outputs/` after a second run shows no diff (determinism probe).
- `node scripts/build-plugins/verify.mjs` is green, including the new OKF conformance assertions (frontmatter parse, non-empty `type`, reserved filenames, link resolution).
- `node scripts/build-plugins/validate-metadata.mjs` and `node scripts/test-workflow-scripts.mjs` remain green (no regression to existing targets).

**Gate** — what must pass before approval:

- The full local verification suite (build, verify with OKF assertions, validate-metadata, test-workflow-scripts) is green in-session, the determinism probe shows an empty diff, and the Outputs Freshness CI workflow passes on the PR covering the new `outputs/okf/` tree.

## Considerations

- OKF is v0.1 and freshly announced — keep the blast radius one deletable emitter module plus verify assertions; no OKF vocabulary may leak into source frontmatter conventions or the standards-sync controller's expectations (`scripts/build-plugins/build.mjs`, `plugins/workaholic/skills/*/policies/*.md`)
- The fetched spec summary contradicts itself on whether bundle-root `index.md` carries frontmatter (`okf_version` declaration vs "no frontmatter block") — Implementation Step 1 must resolve this against the real `SPEC.md` before emitting, per the verify-specs-before-proposing discipline
- `timestamp` must be deterministic or the Outputs Freshness CI (rebuild-and-diff) will fail on every run — derive from git commit dates, never `new Date()` (`.github/workflows/outputs-freshness.yml`)
- The policy hard copies are periodically overwritten by the `workaholic-standards-sync` controller; the emitter must tolerate policy files appearing/disappearing without hand-maintained lists (`plugins/workaholic/skills/*/policies/`)
- `outputs/okf/` is generated and committed — never hand-edited; the existing `outputs/` diff in CI should cover it with no workflow edit, but confirm rather than assume (`.github/workflows/outputs-freshness.yml`)
- The `workflows` marketplace entry pattern does not apply: OKF consumers read the bundle directly from the repo path, so no `.claude-plugin`/`.codex-plugin` manifest is added unless the spec requires one (`.claude-plugin/marketplace.json`)
- New build code is Node `.mjs` under the TypeScript-family coding standards; any helper shell must be POSIX `#!/bin/sh -eu`, never bash (`plugins/workaholic/rules/shell.md`)

## Discussion

### Revision 1 - 2026-07-03T03:12:52+09:00

**User feedback**: "I don't think you get my point correctly, because what I was expecting is that the Markdown files generated by Wakahoric should be compatible with the OKF format."

**Ticket updates**: Added Implementation Steps 8–10 (make the runtime-generated `.workaholic/` markdown OKF-conformant by updating the file-writing templates in `report`/`review-sections`, `write-release-note`, `ship`, and `carry`/`trip-protocol`; keep existing key conventions; regenerate `outputs/workflows`). Added a Revision 1 acceptance criterion to the Quality Gate.

**Direction change**: The primary deliverable is native OKF compatibility of the markdown files workaholic *generates at runtime* (tickets, stories, release notes, concerns, trip artifacts) — not only an exported bundle. The `outputs/okf/` policy bundle built in the first pass is kept (it is a valid OKF surface and independently useful), but the templates the workflow skills use to write `.workaholic/` files are the point: each generated file must itself satisfy OKF's conformance floor (parseable YAML frontmatter, non-empty `type`). Tickets already conform; the other artifact families gain a minimal frontmatter block.

### Revision 2 - 2026-07-03T03:12:52+09:00

**User feedback**: "how about index.md ?"

**Ticket updates**: Added Implementation Step 11 — the workflow-maintained story index moves from `README.md` to OKF's reserved `index.md` (no frontmatter, link-list entries), `scan-window.sh` excludes `index.md` when scanning stories, and the repo's existing `stories/README.md` is migrated.

**Direction change**: Directory navigation should use OKF's reserved `index.md` filename so OKF readers recognize the index as an index (progressive disclosure), accepting the loss of GitHub's automatic README rendering on that directory page.

### Revision 3 - 2026-07-03T03:12:52+09:00

**User feedback**: "if the user is using this plugin ... to generate Markdown file documents under the .workaholic directory, we will have the OKF format compatibility document hierarchy. I am not talking about currently existing Markdown files right now. However, once the next version release ... has been cut over, the developer will use this. Under the .workaholic directory, I want to have the OKF-compatible organized documents generated and reorganized."

**Ticket updates**: Added Implementation Steps 12–13 — a deterministic index-refresh script (internal `okf` skill) that generates and maintains the `.workaholic/` bundle hierarchy (root `index.md` with `okf_version` + per-area indexes), wired into the drive/report/ship writing flows.

**Direction change**: The unit of OKF compatibility is the whole `.workaholic/` tree in a *consumer project*, kept organized automatically as workflows generate documents — per-file frontmatter (Revision 1) and reserved index names (Revision 2) are necessary but not sufficient; the bundle needs a self-maintaining entry-point hierarchy.

## Final Report

Development completed as planned, across three developer-driven revisions: the OKF policy bundle (`outputs/okf/`, 50 concepts + root `index.md`), OKF-conformant frontmatter on every workflow-generated artifact family, reserved-name `index.md` navigation, and the self-maintaining `.workaholic/` bundle hierarchy (new internal `okf` skill; `refresh-index.sh` called by drive/ship/report before their commits). Documentation (root README, `.workaholic/README.md`, CLAUDE.md, rules) updated in the same change, with a new CLAUDE.md rule making same-commit doc updates mandatory.

### Discovered Insights

- **Insight**: Commit-date-derived `timestamp` values in committed generated artifacts are structurally incompatible with a rebuild-and-diff freshness CI — the artifact's inputs change at the very commit that ships it, so the tree is permanently one commit stale.
  **Context**: Any future generated artifact under `outputs/` must be a pure function of the working tree (no git-state, no wall clock). The OKF bundle omits `timestamp` for exactly this reason.
- **Insight**: `publish-release.sh` posted the release-note file verbatim to GitHub Releases, so adding frontmatter to committed notes required a strip step at the publish boundary — any future frontmatter addition to a file that is republished elsewhere needs the same audit of its consumers.
  **Context**: The consumer list of an artifact family (PR body via `create-or-update.sh`, GitHub Release via `publish-release.sh`, scanners like `scan-window.sh`) is the real blast radius of a format change, not the writer.
- **Insight**: Scripts that scan `.workaholic` directories by glob (`scan-window.sh`, `list-todo.sh`, concern scripts) each carry their own reserved-filename exclusions; introducing a new reserved name (`index.md`) means auditing every scanner, and the tickets/ tree was deliberately left index-free because its scanners and structure guards would fight generated files.
  **Context**: Explains why `refresh-index.sh` covers the flat knowledge areas but never writes inside `tickets/`, and why `stories/index.md` is report-maintained rather than regenerated.
