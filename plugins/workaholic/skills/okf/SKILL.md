---
name: okf
description: Keep the project's .workaholic/ tree organized as an Open Knowledge Format (OKF) bundle - regenerate the bundle-root index.md and per-area indexes whenever a workflow writes knowledge documents.
user-invocable: false
metadata:
  internal: true
---

# OKF Bundle Maintenance

The `.workaholic/` tree of a project using workaholic is an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) (OKF v0.1) bundle: every generated knowledge document carries YAML frontmatter with a non-empty `type` (the OKF conformance floor), and navigation uses OKF's reserved `index.md` filename so any OKF reader can enter at `.workaholic/index.md` and walk the hierarchy. **Tickets are the exception** — the queue is a work surface, not a knowledge area: a ticket carries no `type` and `tickets/` internals are never index-managed.

Two layers keep that true:

- **Per-file conformance** is owned by the writing workflows: stories (`type: Story`), missions (`type: Mission`), feedbacks (`type: Feedback`), release notes (`type: Release Note`), releases (`type: Release`), and legacy trip artifacts (`type: Direction|Model|Design|Review|Rollback|Trip Plan|Event Log`). Tickets are not on this list and must not be added to it: the `type`/`layer` fields left the ticket schema on 2026-08-07, no shipped ticket carries one, and `hooks/validate-ticket.sh` neither requires nor validates the field.
- **Hierarchy organization** is owned by this skill's refresh script, which deterministically regenerates the indexes from whatever exists on disk — documents added, renamed, or removed by any workflow are reflected on the next refresh, with no hand-maintained lists.

## Refresh Script

```bash
sh ${CLAUDE_PLUGIN_ROOT}/skills/okf/scripts/refresh-index.sh
```

Regenerates and git-stages:

- `.workaholic/index.md` — the bundle root. Carries the one frontmatter block an OKF `index.md` may have (`okf_version: "0.1"`) and lists each knowledge area present.
- `<area>/index.md` for the flat knowledge areas (`deployments`, `feedbacks`, `release-notes`, `releases`, `stories`, `strategies`, `terms`) — one `* [title](file.md) - description` entry per document, title/description read from the file's frontmatter (H1 and filename as fallbacks), plus links to subdirectories. The entry list lives inside a **marked generated region** (see below); prose outside it is preserved.
- `trips/index.md` — one entry per trip, linking its `plan.md`.
- `missions/index.md` — one `## active` / `## archive` section per non-empty area, one entry per mission linking its `mission.md` (`<area>/<slug>/mission.md`), described by the mission's frontmatter `title`. Legacy flat mission dirs (a pre-migration tree) are listed at the top level until the mission scripts' living migration relocates them.

It deliberately does **not** touch:

- anything inside `tickets/` — the queue scripts and structure guards own that tree; the root index links the directory itself.

**`stories/index.md` left this list on 2026-08-19.** It was excluded because a story's description existed nowhere but the index itself, so `/report` wrote the bullet by hand — which left the one ledger index with **no generator**: nothing repaired it after a merge disturbed it, nothing noticed a run that wrote its story and never added the bullet (22 stories were missing from this repository's own index when the area was first generated), and ordering degraded monotonically because every run inserted at the top. The exclusion's premise is what moved: the description now lives in the story's own `description:` frontmatter, so the generic derivation has something to read and the richness argument no longer distinguishes stories from any other area. Two narrow per-area knobs carry the rest (`build_region`'s `order` and `skip`): entries are ordered **newest-first**, and `stories/README.md` is not an entry — a skip that is per-area precisely because `deployments/`, `release-notes/` and `terms/` each index their own `README.md` as a real entry.

### Ownership model (flat areas)

An index is a **defined mix**, not fully generated: the entry list is regenerated between the markers `<!-- okf:generated:begin -->` / `<!-- okf:generated:end -->`, and everything outside them is hand-written content the script owns nothing of. This is the fix for the defect where a full regenerate silently deleted a hand-written `/ship` rule and section from `deployments/index.md`.

- **Marked index** → the region is regenerated in place; prose before, between sections of, and after the markers survives verbatim.
- **Legacy index with no markers, body purely the old generated shape** (only the `# <area>` H1 and `* [...]` bullets) → migrated once into the marked form. Lossless — the old body held only the entries the region reproduces — and it keeps updating thereafter.
- **Legacy index with no markers that carries hand-authored prose** → preserved verbatim, untouched. A human opts its list back into generation by adding the markers.

Within the region, an entry's description comes from the entry file's `description:` frontmatter, falling back to the description the prior region already held for that link — so a hand-written description survives a regenerate instead of degrading to a bare link.

A directory is listed only when git will carry it (at least one tracked file under it, by `git ls-files`). An empty, untracked, or ignored-only directory is not knowledge and a fresh clone would 404 on the link, so it is not indexed.

Idempotent and deterministic: same tree in, same bytes out (`LC_ALL=C` ordering, no timestamps), so repeated runs never dirty a clean working tree. Determinism is not the same property as safety: the script is safe because it preserves what it does not own. Safe to run anywhere — exits quietly when there is no `.workaholic/` directory.

## When It Runs

The writing flows call it just before they commit, so every knowledge commit ships with a fresh hierarchy:

- `drive` — `archive.sh` refreshes before staging the archive commit.
- `ship` — `commit-release-note.sh` and `extract-deferred-concerns.sh` refresh before their commits.
- `report` — the story flow runs it before staging the story and any superseding concern records.

**Mission roll (same seams).** These same commit seams also update every **mission** the touched artifact advances (`workaholic:mission`): when an archived ticket, shipped story, or extracted/resolved concern carries a `mission:` relation — many-valued, read through the mission skill's `read-relation.sh` — the seam appends a changelog line and reconciles the acceptance checklist **for each named mission** via the mission skill's shared, idempotent mutators (`append-changelog.sh` / `tick-acceptance.sh`) before the refresh + commit. The appends are keyed on a stable event id, so they never duplicate on a re-run, and `refresh-index.sh` stays deterministic over the updated `mission.md`.
