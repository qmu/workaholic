---
created_at: 2026-08-13T11:26:16+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260813112616-record-the-subject-that-formed-each-feedback.md
mission: revive-strategy-and-reshape-the-workaholic-artifact-set
merge_policy:
---

# Retire the policies guides and specs areas

## Overview

PROPOSED. Issue #436 asks to erase `.workaholic/policies`, `guides` and `specs`, "after the plugin update, erase immediately". These three are the closed layout's conventional, model-written documentation areas: `policies/` (7 files) and `guides/` (3) are described in `plugins/workaholic/rules/workaholic.md` as project-local documentation a consuming repo *may* keep, and `specs/` (10 files) is the "current state reference documentation" area that `rules/workaholic.md` also names as the destination for a "docs" request. All three are registered in the two lockstep sources, so removing them is a layout amendment — the allowlist is permissive, and a directory that leaves it must leave the rules table in the same commit, or the next write into it is hard-blocked with a stale reason.

The area removal is mechanical; what needs deciding is what happens to the content, because the repository's own precedent for retiring an artifact layer is explicit that **nothing is deleted from knowledge, only from structure** (`20260728183203-retire-strategy-layer.md`).

## Policies

- `workaholic:design` / `policies/history-structures.md` — a retirement is a recorded transition; decide deliberately what survives and where
- `workaholic:planning` / `policies/terminology.md` — once the areas are gone, no rule may still map a request onto them
- `workaholic:implementation` / `policies/directory-structure.md` — the closed layout's two sources move in lockstep, in one commit
- `workaholic:implementation` / `policies/objective-documentation.md` — every document naming the three areas is updated in the same change

## Key Files

- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` — drop `policies`, `guides`, `specs`; its header comment explicitly describes `guides/` and `policies/` as the conventional exceptions and must be rewritten with them.
- `plugins/workaholic/rules/workaholic.md` — drop the three table rows, the "conventional project-local documentation areas" sentence, and the `"docs" → specs/` mapping in the Guidelines list; name the replacement destination.
- `plugins/workaholic/hooks/layout-doctor.sh` — audits against the allowlist, so it reports the surviving directories as undesignated the moment the allowlist changes; the in-repo removal and the allowlist edit must land together.
- `.workaholic/policies/`, `.workaholic/guides/`, `.workaholic/specs/` — 20 files in this repository, plus their `README.md`/`index.md`.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — drop any of the three from the indexed areas; regenerate `.workaholic/index.md`.
- `plugins/workaholic/skills/workaholify/` — the audit that tells a consuming repo what shape to be.
- `README.md`, `.workaholic/README.md`, `CLAUDE.md` — the docs sweep.

## Implementation Steps

1. Grep the whole tree for the three area paths and list every reference (rules, hooks, skills, docs, generated `outputs/`); the list is the work.
2. Resolve the Open Decision below on the existing content, then act on it — move or delete — in its own commit, so the transition is readable in history either way.
3. Remove the three entries from the allowlist and the rules table in one commit with the in-repo removal, including the header comment and the `"docs" → specs/` mapping.
4. Drop the areas from `refresh-index.sh` and regenerate the OKF indexes.
5. Update `/workaholify`'s audit so a consuming repo that still has the areas is told what to do with them, not silently failed.
6. Sweep the docs; argument-less `node scripts/build-plugins/build.mjs`; commit regenerated `outputs/`.

## Open Decisions

Resolve explicitly while driving and record the resolution in the Final Report.

- **Is the content deleted, or relocated?** The ask says "erase immediately". The repository's own retirement precedent says knowledge survives structure (each retired strategy's prose became a feedback record). The 20 files include current reference material (`specs/`), user documentation (`guides/`) and project-local policy (`policies/`) — some of which `docs/` or the plugin's own policy skills may already cover, and some of which exists nowhere else. Delete outright, move to `docs/`, or fold into the plugin's policy skills: the ask does not say, and the driving session must not choose silently.
- **What replaces the `"docs" → specs/` mapping** for a user who asks where reference documentation goes?

## Quality Gate

Provisional — sharpened by the interrogation that replans this mission to drive-ready.

**Acceptance criteria** — the checkable conditions that must hold:

- `.workaholic/policies/`, `guides/` and `specs/` are absent from this repository, from the allowlist, and from the rules table — all in the same commit.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- `grep -r` over `plugins/`, `README.md`, `CLAUDE.md` and `docs/` returns no sentence claiming the three areas exist.
- The resolution of the content decision is recorded, and nothing it promised to keep is lost.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming.
- `node scripts/test-workflow-scripts.mjs` green; `node scripts/build-plugins/build.mjs` then `verify.mjs` and `validate-metadata.mjs` green with `outputs/` committed.
- `git log --follow` on a representative relocated file, if the decision was to relocate.

**Gate** — what must pass before approval:

- Suite, build/verify and layout-doctor green, and an explicit statement in the Final Report of what happened to each of the 20 files.

## Considerations

- Order matters against the rest of this mission: the ask says "after the plugin update", so this lands after the artifact-side changes, not before them.
- A consuming repository will still have the three areas after its plugin updates. Removing them from the allowlist makes every later write into them a hard block — that is why the `/workaholify` step of this mission exists, and why this ticket must tell it what to do.

## Final Report

Development completed as planned. The three areas are gone from the repository, the allowlist, the rules table and the OKF index set, in one commit, and a consuming repository that still holds them is told so by name.

### Open Decisions — resolved

- **Deleted, or relocated? → Deleted, and the reasoning is a measurement rather than a preference.** The repository's retirement precedent is that *knowledge* survives structure — and the test of that precedent is whether the content is knowledge. It is not. **17 of the 20 files describe the retired three-plugin architecture** (`core` / `standards` / `work`, `drivin`, `trippin`, the `/trip` command, per-workflow agent files): `specs/component.md` carries 45 such references, `specs/infrastructure.md` 41, `specs/feature.md` 40, `policies/delivery.md` 38, `specs/ux.md` 38. Not one has been touched since 2026-05-14 and most not since 2026-03-10; every one still stamps `commit_hash: f76bde2`. Relocating them into `docs/` would move stale text describing a system that no longer exists next to the maintained documents that contradict it — which is worse than deletion, because a reader would find it and believe it. The precedent is honoured where it applies: git history holds every byte and `git log --follow` recovers any of them. The three `README.md`/`index.md` files went with their areas.
- **What replaces the `"docs" → specs/` mapping? → The repository's own `docs/` tree, outside `.workaholic/`.** The mapping is now written that way in the rules Guidelines list. The reason is the same one that retired the area: `.workaholic/` holds **what the loop writes and reads**, and documentation has no writer in the loop — which is exactly how these three went stale. `docs/` has a human maintainer who reads it, and this repository's own `docs/` (the loop-engineering workflow, the runbooks, the dependency logs) is the demonstration that the arrangement works.

### What happened to each of the 20 files

All deleted in the archive commit; each recoverable at `git log --follow -- <path>`. None relocated, because none was still true.

- `policies/` (8): `README.md`, `accessibility.md`, `delivery.md`, `observability.md`, `quality.md`, `recovery.md`, `security.md`, `test.md` — the seven substantive files carry 13–38 retired-architecture references each. The live equivalents are the plugin's own pillar policy skills (`workaholic:design` / `implementation` / `operation` / `planning` / `safety` / `development`), whose `policies/` directories are hard copies synced from qmu.co.jp and are **not** affected by this change.
- `guides/` (4): `README.md`, `commands.md`, `getting-started.md`, `workflow.md` — the live equivalent is `README.md`'s commands table and `CLAUDE.md`.
- `specs/` (11): `README.md`, `index.md`, `application.md`, `component.md`, `data.md`, `feature.md`, `infrastructure.md`, `model.md`, `stakeholder.md`, `usecase.md`, `ux.md` — the live equivalent is `CLAUDE.md` plus `docs/`.

### Discovered Insights

- **Insight**: The three retired areas were exactly the three the allowlist's own header called exceptions — "conventional, model-written areas" with no writer in the loop — and that exemption is what let them rot.
  **Context**: Every other allowlist entry is created or read by a live script, so a change to the system changes the artifact. These three had no such coupling, so the system changed around them for five months in silence. The header now states the admission rule positively — *every entry is plugin-generated or plugin-read* — so the next candidate exception has to argue against a rule instead of joining a list of exceptions.
- **Insight**: De-listing needs the same lockstep as listing, and it is the more dangerous direction.
  **Context**: Adding a directory to the rules table without the allowlist blocks a legitimate write. **Removing** one from the allowlist blocks every *future* write into a directory a consuming repo already has, with a reason describing a shape it has never had. That is why `layout-doctor.sh` gained a `retired-area` classification that names the retirement and its date rather than reporting "not in the canonical allowlist", and why it emits a remediation but never applies it — the content decision belongs to whoever wrote the content.
- **Insight**: A test fixture can quietly encode a policy. Two suites used `.workaholic/specs/` as their stand-in for "a flat indexed area" and `guides/`+`policies/` as their stand-in for "a clean tree".
  **Context**: Both were green for the wrong reason after the retirement — one because `specs/` was no longer indexed, one because the clean tree was no longer clean. They now use `terms/` and `strategies/`, with a comment saying why the substitution happened, so a future reader does not restore the retired area to make a test pass.
