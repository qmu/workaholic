---
name: okf
description: Keep the project's .workaholic/ tree organized as an Open Knowledge Format (OKF) bundle - regenerate the bundle-root index.md and per-area indexes whenever a workflow writes knowledge documents.
user-invocable: false
metadata:
  internal: true
---

# OKF Bundle Maintenance

The `.workaholic/` tree of a project using workaholic is an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) (OKF v0.1) bundle: every generated markdown document carries YAML frontmatter with a non-empty `type` (the OKF conformance floor), and navigation uses OKF's reserved `index.md` filename so any OKF reader can enter at `.workaholic/index.md` and walk the hierarchy.

Two layers keep that true:

- **Per-file conformance** is owned by the writing workflows: tickets (`type: enhancement|bugfix|refactoring|housekeeping`), stories (`type: Story`), missions (`type: Mission`), release notes (`type: Release Note`), deferred concerns (`type: Concern`), and trip artifacts (`type: Direction|Model|Design|Review|Rollback|Trip Plan|Event Log`).
- **Hierarchy organization** is owned by this skill's refresh script, which deterministically regenerates the indexes from whatever exists on disk — documents added, renamed, or removed by any workflow are reflected on the next refresh, with no hand-maintained lists.

## Refresh Script

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/okf/scripts/refresh-index.sh
```

Regenerates and git-stages:

- `.workaholic/index.md` — the bundle root. Carries the one frontmatter block an OKF `index.md` may have (`okf_version: "0.1"`) and lists each knowledge area present.
- `<area>/index.md` for the flat knowledge areas (`concerns`, `deployments`, `release-notes`, `specs`, `terms`) — one `* [title](file.md) - description` entry per document, title/description read from the file's frontmatter (H1 and filename as fallbacks), plus links to subdirectories.
- `trips/index.md` — one entry per trip, linking its `plan.md`.
- `missions/index.md` — one entry per mission, linking its `mission.md`, described by the mission's frontmatter `title`.

It deliberately does **not** touch:

- `stories/index.md` — maintained by the report workflow, whose hand-written per-story descriptions are richer than any frontmatter derivation (the root index links to it).
- anything inside `tickets/` — the queue scripts and structure guards own that tree; the root index links the directory itself.

Idempotent and deterministic: same tree in, same bytes out (`LC_ALL=C` ordering, no timestamps), so repeated runs never dirty a clean working tree. Safe to run anywhere — exits quietly when there is no `.workaholic/` directory.

## When It Runs

The writing flows call it just before they commit, so every knowledge commit ships with a fresh hierarchy:

- `drive` — `archive.sh` refreshes before staging the archive commit.
- `ship` — `commit-release-note.sh` and `extract-deferred-concerns.sh` refresh before their commits.
- `report` — the story flow runs it before staging the story and concern verdicts.
