---
created_at: 2026-06-30T21:52:30+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on: [20260630215229-catch-per-developer-focus-branches-style.md]
---

# Surface this-week deployments and releases per developer in /catch

## Overview

Add a seventh per-developer section to the `/catch` report: the **deployments / releases the developer made this week**, each rendered with a **timestamp**, a **release title**, and a **confirmation comment**. When no confirmation can be referenced for a developer's shipped work, the report instead emits guidance that workaholic can make this possible going forward via the `/ship` command.

This data already exists in the repo, produced out-of-band by the `/ship` flow — `/catch` currently reads none of it:

- **Confirmation comment + timestamp** live in each branch story's `## Deployment Evidence` block (`.workaholic/stories/<branch>.md`), written by `ship/scripts/record-evidence.sh`: `When` → timestamp, `Observed` → the confirmation comment, `Status` → `pass | fail | bypassed`.
- **Release title** lives in `.workaholic/release-notes/<branch>.md` (the H1 / Summary), written by the `write-release-note` skill; optionally cross-checked against `gh release list`.

The catch-specific challenge is **attribution**: stories and release-notes carry **no author**, so a developer is attributed to a deployment/release by the **git author of the commit that added the release-note / evidence block**, joined on **branch name**. Filter to the current week.

This ticket **depends on** the activity-dimensions ticket because both add keys to the same Collector Output JSON schema and bullets to the same Report Structure in `catch/SKILL.md`; landing the scaffolding first avoids a schema/template conflict.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — any new scan logic stays under `skills/catch/scripts/`; no new top-level area.
- `workaholic:implementation` / `policies/coding-standards.md` — the operative concrete standard for this shell-only change is `rules/shell.md` (POSIX sh `#!/bin/sh -eu`, machine-checked).
- `workaholic:implementation` / `policies/command-scripts.md` — the deployment/release scan (read evidence blocks + release notes, join author-by-branch, filter to this week) belongs in a bundled script, not inline markdown shell.
- `workaholic:implementation` / `policies/objective-documentation.md` — surface real, checkable deployment evidence; render `pass`/`fail`/`bypassed` distinctly and never imply a confirmation that does not exist.
- `workaholic:implementation` / `policies/observability.md` — the deployments section is an observability surface (the delivered state made explainable from outside); the `/ship` fallback is the graceful-degradation path when the confirmation signal is absent.
- `workaholic:operation` / `policies/ci-cd.md` — confirmation evidence originates from the sanctioned commit-to-deploy path; when it is missing, point the developer to `/ship` rather than fabricating a deployment record.
- `workaholic:implementation` / `policies/test.md` — cover the new author-by-branch join and this-week filtering in `test-workflow-scripts.mjs`.

## Key Files

- `plugins/workaholic/skills/catch/SKILL.md` — add a `deployments[]` key (`{timestamp, release_title, confirmation, status, branch}`) to the Collector Output JSON and a rendered "Deployments / Releases this week" subsection (plus the `/ship` fallback prose) to the Report Structure.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — extend (preserving the `0x1f`/`0x1e` + `jq` pattern) to emit a `deployments[]` axis keyed by author + branch + timestamp, so the collector receives it like `tickets[]` and the one-level fan-out stays intact.
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` — source of truth for the confirmation comment: the `## Deployment Evidence` block (`When`/`Target`/`Method`/`Status`/`Observed`). Read its shape; do not modify it.
- `plugins/workaholic/skills/ship/scripts/read-deployments.sh` — returns `has_confirmation`; use it to decide whether to print the `/ship` fallback (no confirmation capability ⇒ fallback is the correct output).
- `plugins/workaholic/skills/write-release-note/SKILL.md` — defines `release-notes/<branch>.md` (H1/Summary = release title; `-2`/`-3` suffixes for repeat ships on one branch, so a developer may list several this week).
- `plugins/workaholic/skills/ship/scripts/publish-release.sh` — defines a "release" as a GitHub Release tag tied to the merge commit; the offline/portable source is the release-note file, optionally cross-checked with `gh release list`.

## Related History

The deployment-evidence and release-note machinery this section reads was built out in the ship workflow; `/catch` is the first reader of it.

- [20260630011811-add-catch-command.md](.workaholic/tickets/archive/work-20260630-011820/20260630011811-add-catch-command.md) - Parent: the Collector Output + Report Structure this section extends.
- [20260617231848-ship-confirm-in-production-before-merge.md](.workaholic/tickets/archive/work-20260617-231848/20260617231848-ship-confirm-in-production-before-merge.md) - Establishes confirm-before-merge and the `## Deployment Evidence` story block (timestamp + result) this section reads back.
- [20260618003119-record-evidence-secret-scrub.md](.workaholic/tickets/archive/work-20260618-003119/20260618003119-record-evidence-secret-scrub.md) - Hardens `record-evidence.sh`, which writes the confirmation block; confirms its `When`/`Observed`/`Status` shape.
- [20260617210614-establish-deployments-directory-convention.md](.workaholic/tickets/archive/work-20260617-210627/20260617210614-establish-deployments-directory-convention.md) - Defines `.workaholic/deployments/` + `read-deployments.sh` (`has_confirmation`), the signal that gates the `/ship` fallback wording.
- [20260617001706-move-release-note-generation-to-ship.md](.workaholic/tickets/archive/work-20260617-000311/20260617001706-move-release-note-generation-to-ship.md) - Establishes ship-time release notes + GitHub Releases (title + timestamp), the release identity this section surfaces.

## Implementation Steps

1. **Collect the deployment/release axis.** Extend `scan-window.sh` to emit a `deployments[]` list within the window: for each `.workaholic/stories/<branch>.md` with a `## Deployment Evidence` block, capture `When` (timestamp), `Observed` (confirmation comment), and `Status`; join the matching `.workaholic/release-notes/<branch>.md` H1/Summary as `release_title`. Attribute each to a developer by the **git author of the commit that added the evidence/release-note block** (stories/notes carry no author), keyed by branch. Filter to the current week.
2. **Schema + render.** Add `deployments[]{timestamp, release_title, confirmation, status, branch}` to the Collector Output JSON and render a "Deployments / Releases this week" subsection per developer in the Report Structure, showing timestamp · title · confirmation, with `bypassed`/`fail` marked distinctly from `pass`. Reuse `repo_url` (gather) for clickable links.
3. **Fallback wording.** When a developer shipped branches this week but no `## Deployment Evidence` block exists for them, OR `read-deployments.sh` reports `has_confirmation: false`, emit the guidance: confirmation data is not available, and `/ship` can capture it going forward (deploy + confirm before merge). Keep this factual — do not imply a confirmation occurred.
4. **Keep read-only + one-level fan-out.** All deployment data is gathered by the scanner and handed to the collector; the collector reads and returns JSON only (no `AskUserQuestion`, no nested Task). `/catch` writes nothing.
5. **Tests + checks.** Add hermetic coverage in `test-workflow-scripts.mjs` for the author-by-branch attribution and this-week filtering (temp repo with a story `## Deployment Evidence` block + a release-note, added by a known author on a `work-*` branch). Run `node scripts/test-workflow-scripts.mjs` and `posix-lint`. No `outputs/` rebuild — `catch` is Claude-only.

## Considerations

- Attribution is the crux: stories and release-notes carry **no author**, so the only reliable developer signal is the git author of the add-commit for the evidence/release-note, joined on branch. A branch authored by one developer but shipped by another will attribute to the shipper — note this assumption in the report if it matters. (`plugins/workaholic/skills/catch/scripts/scan-window.sh`)
- `Status: bypassed` means an accepted-risk merge with production state unverified — render it distinctly from a real `pass`, and never collapse it into "confirmed" (`workaholic:implementation` / `objective-documentation`). (`plugins/workaholic/skills/ship/scripts/record-evidence.sh`)
- One branch can produce multiple release records (`-2`/`-3` notes for repeat ships); a developer's "this week" list may legitimately contain several. (`plugins/workaholic/skills/write-release-note/SKILL.md`)
- Prefer the offline/portable sources (story evidence + release-note files) over `gh release list` so `/catch` works without network/GitHub; treat `gh` as an optional cross-check, not a dependency. (`plugins/workaholic/skills/catch/scripts/scan-window.sh`)
- Depends on the activity-dimensions ticket: both edit the Collector Output schema and Report Structure in `catch/SKILL.md`; implement that first to avoid a conflicting schema. (`.workaholic/tickets/todo/a-qmu-jp/20260630215229-catch-per-developer-focus-branches-style.md`)
- Stay POSIX `#!/bin/sh -eu` — no bashisms (`rules/shell.md`).
