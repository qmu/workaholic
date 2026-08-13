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
