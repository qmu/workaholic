---
created_at: 2026-07-09T02:32:55+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure, Domain]
effort: 1h
commit_hash: 3cb23a4
category: Changed
depends_on:
mission:
---

# Teach the /catch scanner to join missions (merged + unmerged)

## Overview

Extend `/catch`'s single scanner, `skills/catch/scripts/scan-window.sh`, so it surfaces the
mission axis the report needs. Today the scanner emits `{window, fetch_ok, buckets,
developers[], tickets[], stories[], deployments[]}` and never reads `.workaholic/missions/`
or a ticket's `mission:` relation. This ticket adds a `missions[]` block and enriches
`tickets[]`, all **read-only** — no mission mutation, preserving `/catch`'s write-nothing
contract (the only write stays the best-effort startup `git fetch`).

The design decision that drives this ticket: mission progress and the mission `## Changelog`
only advance at **merge/archive time** (the drive/report/ship seams). So the changelog alone
shows only *merged* work. The developer wants `/catch` to also show **unmerged, in-flight**
progress toward a mission — `mission:`-tagged tickets still sitting in `todo` and the commits
on their (possibly unmerged / remote-only) branches. The scanner already walks
`--branches --remotes` and the live `todo`/`icebox` queues, so it is the correct place to
compute both dimensions. **No new mission-side storage is added** — the `mission:` relation
on tickets and the derived `checked/total` already carry everything; this ticket only teaches
the scanner to *read* them.

This is the data-contract foundation; the report rendering (top-level Missions section +
per-developer weaving) is the dependent ticket `20260709023256-catch-report-missions-section.md`.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code and keep every change defensible against
its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout; the join reads `.workaholic/missions/<slug>/mission.md` and `.workaholic/tickets/` only, adds no ad-hoc file.
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions for the scanner edits.
- `workaholic:implementation` / `policies/command-scripts.md` — all join/window logic stays inside bundled `#!/bin/sh -eu` POSIX scripts (no bash, no inline conditionals/pipes/loops in markdown); reach mission scripts via `${SCRIPT_DIR}/../../mission/scripts/` exactly as `drive/scripts/archive.sh` does.
- `workaholic:implementation` / `policies/domain-layer-separation.md` — reuse mission's own readers (`list.sh` for `{slug,title,status,checked,total}`, `progress.sh` for `{checked,total}`) as the domain interface; do **not** re-parse `mission.md` acceptance or recompute progress inside the catch scanner. The mission schema stays owned by the mission skill.
- `workaholic:implementation` / `policies/objective-documentation.md` — progress stays **derived, never stored** (`checked ÷ total`); emit merged vs. in-flight as distinct, verifiable facts; never present an unmerged inference as a recorded fact.
- `workaholic:design` / `policies/history-structures.md` — the mission `## Changelog` is append-only; the scanner **reads** it (date-filtered to the window) and must never rewrite or reorder a line.
- `workaholic:planning` / `policies/terminology.md` — join strictly through the documented `mission: <slug>` relation (slug is the stable key); keep mission / trip / epic distinct.
- `workaholic:implementation` / `policies/test.md` — the new scanner behavior is covered by a hermetic smoke test in `scripts/test-workflow-scripts.mjs`.

## Key Files

- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — the scanner. `emit_tickets()` (lines 116–139) parses only author/title/scope; add `mission` and `commit_hash`. Add a new `missions[]` emitter that calls the mission readers and computes merged + in-flight per mission.
- `plugins/workaholic/skills/mission/scripts/list.sh` — reuse as-is: `{slug,title,status,checked,total}` per mission (active-missions + progress axes, free).
- `plugins/workaholic/skills/mission/scripts/progress.sh` — reuse as-is (already called by `list.sh`); progress stays derived.
- `plugins/workaholic/skills/mission/SKILL.md` — the schema the scanner reads: `mission:<slug>` relation, changelog line format (`- <YYYY-MM-DD> — <event> — <artifact>`, lines 74–88), Progress Rule (lines 90–92). Add a note that `/catch` is a **read-only mission consumer** (it does not appear in the Automatic-Updates seam table because it mutates nothing).
- `plugins/workaholic/skills/drive/scripts/archive.sh` — the producer the join mirrors: reads a ticket's `mission:` (lines 63–72) and stamps `commit_hash` (lines 90–95). No change; reference for the `mission:`-reading awk and the `../../mission/scripts` relative path.
- `plugins/workaholic/skills/create-ticket/SKILL.md` — confirms `mission:` and `commit_hash` are optional/empty until set; the scanner must treat an empty/absent `mission:` as "unmissioned" and never require it.
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests; `SCRIPTS.scanWindow` (line 49) and the mission block (lines 448–521) already exist. Add the mission-join case here.
- `scripts/build-plugins/build.mjs` — `catch` and `mission` are `DEFAULT_TARGETS` (line 50); any source edit mandates a rebuild of `outputs/workflows/` or Outputs Freshness CI fails.

## Related History

The `/catch` scanner has twice been extended by the same pattern (add scanner data → collector contract → report), and the mission artifact cluster established the `mission:` relation and derived progress this ticket consumes.

Past tickets that touched similar areas:

- [20260630215230-catch-this-week-deployments-releases.md](.workaholic/tickets/archive/work-20260630-050446/20260630215230-catch-this-week-deployments-releases.md) - Closest precedent: taught `/catch` to read an out-of-band artifact (stories/release-notes) and attribute it by author, window-filtered (same shape as the missions join).
- [20260630215229-catch-per-developer-focus-branches-style.md](.workaholic/tickets/archive/work-20260630-050446/20260630215229-catch-per-developer-focus-branches-style.md) - Established the scanner-data → collector-JSON → report extension pattern this follows.
- [20260706203045-mission-frontmatter-linkage.md](.workaholic/tickets/archive/work-20260706-182705/20260706203045-mission-frontmatter-linkage.md) - Stamped the machine-readable `mission:<slug>` relation onto tickets — the exact join key.
- [20260706203046-mission-progress-and-changelog-automation.md](.workaholic/tickets/archive/work-20260706-182705/20260706203046-mission-progress-and-changelog-automation.md) - Populates the `## Changelog` and acceptance state from the merge-time seams — the data this scanner surfaces, and the reason unmerged work is currently invisible.

## Implementation Steps

1. **Enrich `emit_tickets()`** in `scan-window.sh` to also read `mission:` and `commit_hash` from each ticket's frontmatter (mirror the `mission:`-reading approach in `archive.sh` lines 63–72; use the same `sed`/`awk` style already in `emit_tickets`). Add two fields to the emitted record and to the `jq` object: `{path, author, title, scope, mission, commit_hash}`. An absent field emits `""` — never fail on unmissioned tickets.
2. **Add a `missions[]` emitter.** Call `${SCRIPT_DIR}/../../mission/scripts/list.sh` for the `{slug,title,status,checked,total}` base (active-missions + merged progress). For each mission, compute:
   - `window_events` — lines from that mission's `## Changelog` whose leading `<YYYY-MM-DD>` date falls within the window. Reuse the `buckets`/`WINDOW` boundaries already computed at the top of the scanner; do the date compare in POSIX `awk`/arithmetic (no `date -d`). Each event: `{date, event, artifact}`.
   - `in_flight` — the **unmerged** dimension: `todo`/`icebox` tickets carrying `mission:<slug>` that are **not** archived (no `commit_hash` yet), each `{path, title, author, scope, branch?}`. This is the progress-toward-the-mission-from-unmerged-work the developer asked for.
3. **Emit `missions[]`** in the final JSON object alongside `developers`/`tickets`/`stories`/`deployments`. Emit `[]` when `.workaholic/missions/` is absent or empty (mirror `list.sh`).
4. **Keep it read-only.** The scanner calls only mission *readers* (`list.sh`/`progress.sh`) and reads changelog/ticket files — it never calls `append-changelog.sh` or `tick-acceptance.sh`.
5. **Document the schema** in `skills/catch/SKILL.md` Phase 0 (the `missions[]` field and the two new ticket fields) — full report rendering is the dependent ticket, but the scan-output contract is documented here where it is produced. Add the read-only-consumer note to `skills/mission/SKILL.md`.
6. **Add the smoke test** (see Quality Gate) to `scripts/test-workflow-scripts.mjs`.
7. **Regenerate outputs**: `node scripts/build-plugins/build.mjs`, then `verify.mjs` and `validate-metadata.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `scan-window.sh` output JSON gains a top-level `missions[]` array; each element has `{slug, title, status, checked, total, window_events[], in_flight[]}`.
- Each `tickets[]` element gains `mission` and `commit_hash` fields (empty string when absent); unmissioned/legacy tickets still scan without error.
- For a mission with an archived (merged) `mission:`-tagged ticket dated in the window, that mission appears with the correct derived `checked/total` and a matching `window_events` entry (`event: "ticket archived"`).
- For a mission with a `mission:`-tagged ticket still in `todo` (unmerged, no `commit_hash`), that ticket appears in the mission's `in_flight[]` and is **not** counted in `checked` — proving merged vs. in-flight are distinct.
- `missions[]` is `[]` when no missions exist; the scanner never mutates any `mission.md` (no changelog line, no acceptance tick added by a `/catch` scan).
- `outputs/workflows/skills/{catch,mission}/` is regenerated and byte-identical to a fresh `build.mjs` (Outputs Freshness clean).

**Verification method** — the commands/tests/probes that prove them:

- A new case in `scripts/test-workflow-scripts.mjs`: in a throwaway repo, create a mission with a 2-item acceptance checklist, create + archive one `mission:`-tagged ticket in-window (via the drive archive script) and leave one `mission:`-tagged ticket in `todo`, run `scan-window.sh`, and assert (a) the mission surfaces with `checked/total` reflecting only the archived item, (b) a matching `window_events` entry exists, (c) the todo ticket is in `in_flight[]`, (d) `tickets[]` carries `mission`/`commit_hash`, and (e) the mission file is unchanged after the scan.
- `node scripts/test-workflow-scripts.mjs` is green (existing scanWindow + mission assertions still pass).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` all succeed with no `outputs/` diff.

**Gate** — what must pass before approval:

- The smoke suite is green including the new join assertions, `outputs/` is regenerated & verified clean, and the scanner is confirmed to make no mission mutation.

## Considerations

- **Unmerged commit→mission attribution is inference, not fact.** A `todo` ticket has no `commit_hash` yet, so an individual in-window commit cannot be *machine-linked* to a mission pre-merge. Attribute the unmerged dimension at **ticket** (and, where useful, branch) granularity — the `in_flight[]` tickets and their branch — rather than asserting a specific commit belongs to a mission. Any commit-level association the report later draws must be labeled an inference (`workaholic:implementation` / `objective-documentation`), like the existing generation-style guess. (`plugins/workaholic/skills/catch/scripts/scan-window.sh`)
- **Do not double-count.** Merged progress comes only from the derived `checked/total`; `in_flight[]` is a separate, uncounted list. Keep them strictly disjoint so a ticket is never both counted and shown as in-flight — heed the existing progress double-count concern in the mission cluster. (`plugins/workaholic/skills/mission/scripts/progress.sh`)
- **POSIX-only date math.** Window-filter the changelog with the epoch boundaries already computed in the scanner and `awk` string/number compares — no `date -d` (Alpine). (`plugins/workaholic/skills/catch/scripts/scan-window.sh` lines 40–45)
- **Reuse, don't reimplement.** Call `list.sh`/`progress.sh` for slug/title/status/progress; do not re-derive acceptance counts in the catch scanner (`workaholic:implementation` / `domain-layer-separation`).
- Both `catch` and `mission` are `DEFAULT_TARGETS`; forgetting the rebuild fails CI. (`scripts/build-plugins/build.mjs` line 50)

## Final Report

Development completed as planned. The scanner now emits `missions[]` (active list + derived `checked/total` + window-filtered `window_events` + unmerged `in_flight`) and carries `mission`/`commit_hash` on every `tickets[]` entry, all read-only. Verified by the new `catch/scan-window.sh mission join` smoke test (13 assertions), the full suite (374 passed / 0 failed), and a clean `build.mjs`/`verify.mjs`/`validate-metadata.mjs`.

### Discovered Insights

- **Insight**: "This window" for the changelog filter is resolved by asking git for the oldest in-window commit's date via `git log --since="$WINDOW" --format=%cd --date=format:'%Y-%m-%d' --reverse | head -1`, then comparing changelog `YYYY-MM-DD` strings lexicographically — no `date -d`.
  **Context**: `scan-window.sh` deliberately avoids the non-POSIX `date -d` (Alpine/busybox). Using git's own date engine defines the mission window identically to the commit window the rest of the scan uses, so the two never disagree, and ISO-date string comparison is a correct substitute for epoch math.
- **Insight**: Because `scan-window.sh` now references `${SCRIPT_DIR}/../../mission/scripts/list.sh`, the argument-less `build.mjs` auto-vendors the `mission` (and its transitive `okf`) closure *inside* catch's self-contained bundle — the new untracked `outputs/workflows/skills/catch/{mission,okf}/` dirs are expected generated output, not stray files.
  **Context**: The generated `outputs/workflows` skills must be self-contained with relative script paths; a new cross-skill `../../<skill>/scripts/` reference silently expands the closure, so any such reference must be followed by a rebuild + `git add` of the newly vendored dirs or Outputs Freshness CI fails.
