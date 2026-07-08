---
created_at: 2026-07-09T02:32:56+09:00
author: a@qmu.jp
type: enhancement
layer: [UX]
effort: 0.5h
commit_hash: 705f7a8
category: Changed
depends_on: [20260709023255-catch-scan-mission-join.md]
mission:
---

# Render missions in the /catch report (top-level + per-developer)

## Overview

Consume the `missions[]` data contract from `20260709023255-catch-scan-mission-join.md` and
render the mission axis in the `/catch` report. Per the developer's design choices, missions
appear in **both** places:

1. **A top-level `## Missions` section** (right after `## Overall Direction`): every active
   mission with its **merged progress** (`checked/total`), its **unmerged / in-flight** work,
   and the **activity under it this window** (typed dated changelog events + who did it).
2. **Per-developer**: each developer's section gains a line attributing the missions they
   advanced this window — merged (their commits whose archived ticket carries the mission
   slug) and unmerged (their `mission:`-tagged `todo` tickets).

This closes the developer's requirement in full: when you run `/catch` you see (1) the active
missions, (2) how far each has come — **and** how far the not-yet-merged work has carried it —
and (3) what happened under each mission this window, both merged and in flight, and *how* it
is being progressed.

`/catch` stays strictly read-only: this ticket only formats data the scanner already gathered.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code.

- `workaholic:implementation` / `policies/directory-structure.md` — the change is confined to the catch skill prose + the `outputs/` regeneration; no new files or layout changes.
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions for any collector-output/JSON contract edits.
- `workaholic:implementation` / `policies/objective-documentation.md` — the report **describes** activity, it does not grade it: render merged progress (`checked/total`) as the derived number, mark in-flight work distinctly (never fold it into progress), and keep every mission characterization traceable to a changelog line, ticket, or commit hash. Any unmerged commit→mission link is labeled an inference.
- `workaholic:design` / `policies/history-structures.md` — the window activity is the append-only changelog read date-filtered; present it as history, do not restate it as current mutable state.
- `workaholic:planning` / `policies/terminology.md` — it is a **Missions** view; never conflate mission / trip / epic; reference missions by slug/title.
- `workaholic:implementation` / `policies/test.md` — the rendering is proven by a live `/catch` run showing the section (the automated contract is guarded by the dependency ticket's smoke test).

## Key Files

- `plugins/workaholic/skills/catch/SKILL.md` — the report definition. Add the top-level `## Missions` section to **Report Structure** (lines 141–188) and **Phase 2** (lines 73–80); add a mission-attribution line to the per-developer template and to **Collector Output** (lines 108–139) + **Collect Developer** (lines 86–106) so each collector returns the missions its developer advanced; document `missions[]` consumption in **Phase 0** (already contract-documented by the dependency ticket).
- `plugins/workaholic/commands/catch.md` — the thin command's one-line description of what `/catch` surfaces should mention missions.
- `plugins/workaholic/skills/mission/SKILL.md` — cross-reference `/catch` as the read-only surface where a mission's merged + in-flight progress is viewed (the create/list `/mission` command remains the writer; only its list/progress *view* is mirrored into `/catch`, never mission creation).
- `README.md`, `.workaholic/README.md`, `CLAUDE.md` — the command table / feature prose describing `/catch` must mention the missions view (same-change docs rule).
- `scripts/build-plugins/build.mjs` — rebuild `outputs/workflows/skills/{catch,mission}/` after the SKILL.md edits.

## Related History

The per-developer enrichment and deployments-per-developer tickets established the exact
collector-output + report-template extension this mirrors.

Past tickets that touched similar areas:

- [20260630215229-catch-per-developer-focus-branches-style.md](.workaholic/tickets/archive/work-20260630-050446/20260630215229-catch-per-developer-focus-branches-style.md) - Added per-developer report fields (focus windows, branches, generation style) — the template this extends with a mission line.
- [20260630215230-catch-this-week-deployments-releases.md](.workaholic/tickets/archive/work-20260630-050446/20260630215230-catch-this-week-deployments-releases.md) - Added a windowed, attributed subsection to each developer — same rendering shape as the per-developer mission line.
- [20260630011811-add-catch-command.md](.workaholic/tickets/archive/work-20260630-011820/20260630011811-add-catch-command.md) - The `/catch` foundation (Overall Direction + By Developer) this adds a third axis to.

## Implementation Steps

1. **Top-level `## Missions` section** in Report Structure. For each active mission from
   `missions[]`, render: `<title>` — `<checked>/<total>` merged (as a plain derived count,
   optionally a simple bar), `status`, then two sub-parts:
   - **Progress this window (merged)**: the `window_events` as dated typed lines, each linking
     the artifact and (where the scanner joined a `commit_hash`) the author + commit link.
   - **In flight (unmerged)**: the `in_flight[]` tickets — title, who's on it, branch, latest
     commit subject where available — framed explicitly as *not yet counted in `checked/total`*.
   Render achieved/abandoned missions compactly (or omit abandoned); do not pad empty missions.
2. **Phase 2 synthesis**: fold a one-line mission read into **Overall Direction** where a
   mission dominates the window's effort (the cross-cutting synthesis), then print the
   `## Missions` section before **By Developer**.
3. **Per-developer mission line**: extend **Collect Developer** so each collector returns a
   `missions` field — the missions this developer advanced this window, split into merged
   (commits whose ticket `commit_hash`+`mission` match) and in-flight (their `mission:`-tagged
   `todo` tickets). Add it to **Collector Output (JSON)** and render a `**Missions:**` bullet
   in the per-developer template (`—` when none).
4. **Honest rendering rules** (add to Report/ Writing Guidelines): merged progress is the only
   number; in-flight is a distinct list, never summed into progress; any commit-level mission
   attribution for unmerged work is phrased as an inference; a mission with no window activity
   still shows its standing progress rather than being dropped silently.
5. **Docs**: update `commands/catch.md`, `skills/mission/SKILL.md` cross-reference, and
   `README.md` / `.workaholic/README.md` / `CLAUDE.md` command descriptions in the same change.
6. **Regenerate outputs**: `node scripts/build-plugins/build.mjs`, then `verify.mjs` and
   `validate-metadata.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Running `/catch` in this repo prints a `## Missions` section after `## Overall Direction`, listing each active mission with its derived `checked/total` and, when present, its this-window `window_events` and `in_flight[]` work.
- Merged progress and in-flight work are rendered **distinctly** — an unmerged in-flight ticket is never added into the `checked/total` count.
- Each per-developer section shows a `**Missions:**` line (or `—`) attributing that developer's merged and unmerged mission work for the window.
- With no missions present, `/catch` renders exactly as before (no empty Missions section, no regression to Overall Direction / By Developer).
- `commands/catch.md`, `skills/mission/SKILL.md`, `README.md`, `.workaholic/README.md`, and `CLAUDE.md` all describe the missions-in-catch view truthfully.
- `outputs/workflows/skills/{catch,mission}/` regenerated & byte-identical to a fresh build.

**Verification method** — the commands/tests/probes that prove them:

- **Live `/catch` run** (the developer-confirmed gate): create a mission with an acceptance checklist, archive one `mission:`-tagged ticket and leave one in `todo`, run `/catch`, and read the printed report — confirm the Missions section shows the mission with merged progress, the archived event under it, the todo ticket as in-flight, and the per-developer mission line; and that a no-mission `/catch` is unchanged.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` succeed with no `outputs/` diff.
- `node scripts/test-workflow-scripts.mjs` remains green (the scanner-contract assertions from the dependency ticket still hold).

**Gate** — what must pass before approval:

- A live `/catch` run demonstrably shows the top-level Missions section **and** the per-developer mission line with merged vs. in-flight rendered distinctly; the no-mission case is unchanged; docs are truthful; and `outputs/` is regenerated & verified clean.

## Considerations

- **Read-only.** This ticket formats scanner data only — it must not call any mission mutator; a `/catch` run adds no changelog line and ticks no acceptance box. (`plugins/workaholic/skills/catch/SKILL.md`)
- **Do not over-claim unmerged work.** In-flight commit→mission links are inferences; keep the "looks like / in flight, not yet counted" framing rather than asserting merged-style facts (`workaholic:implementation` / `objective-documentation`). (`plugins/workaholic/skills/catch/SKILL.md`)
- **One-level fan-out.** The cross-developer Missions synthesis belongs in the main-agent Phase 2, not inside a collector leaf; collectors only return their own developer's `missions` field. (`plugins/workaholic/skills/catch/SKILL.md` Phase 1/2)
- **Only the view combines, not creation.** `/mission` still creates missions (a write); `/catch` mirrors only the list/progress *view*. Do not imply `/catch` can create or mutate a mission. (`plugins/workaholic/commands/mission.md`)
- Depends on `20260709023255-catch-scan-mission-join.md` — the `missions[]` contract and enriched `tickets[]` must exist first.

## Final Report

Development completed as planned. The catch skill now renders a top-level `## Missions` section (main-agent synthesis from the scanner's `missions[]`) and a per-developer `**Missions:**` line (from a new collector `missions` field), with rules that keep derived `checked/total` progress strictly separate from unmerged in-flight work. Docs updated across `commands/catch.md`, `README`/`.workaholic/README`, and `CLAUDE.md`; the mission-side `/catch` read-only-consumer cross-reference already landed with the dependency ticket.

Verified by a live end-to-end run: a realistic throwaway repo (a mission, one missioned ticket archived via `archive.sh`, two in-flight `todo` tickets) fed the real `scan-window.sh`, and the rendered report showed the mission at 1/3 merged, the `ticket archived` event with an author + commit link, both in-flight todos marked "not yet counted", and a matching per-developer Missions line. No-mission repos omit the section (smoke-test asserted). `build.mjs`/`verify.mjs`/`validate-metadata.mjs` green; full suite 374 passed / 0 failed.

### Discovered Insights

- **Insight**: The two cross-developer syntheses in the report — `## Overall Direction` and the new `## Missions` — both live in the main agent, never in a collector; a collector only returns its own developer's `missions` slice.
  **Context**: The one-level-fan-out rule means a `general-purpose` collector leaf sees only one developer's inputs, so any "across all missions/developers" view must be assembled by the command/main agent after the collectors return. Putting the top-level Missions synthesis in a collector would have given each leaf a partial, per-developer picture.
