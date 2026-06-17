---
created_at: 2026-06-18T00:31:20+09:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Fix the carry-over pipeline: accept `{"verdicts":…}` and dedup re-emitted concerns

## Overview

Two long-standing bugs make the carry-over corpus bloat and silently lose
resolutions (tracked as concerns #44 and #43-pipeline). Both have been worked
around by hand for several ships; this fixes the root causes.

**Bug 1 — `apply-carryover-verdicts.sh` silently skips `{"verdicts": […]}`.**
The script's python `parse()` does `json.loads(input)` then `for item in data`.
The report skill's documented Phase 1 schema and the carry-over judge produce
`{"verdicts": [...]}` (an object), so `data` is a dict, the loop iterates its
keys (strings), `item.get(...)` raises, and `2>/dev/null` swallows it — every
verdict is silently skipped, so **resolved concerns are never archived**. It
only works today because the orchestrator hand-writes a bare array to dodge it.

**Bug 2 — `extract-carryover.sh` re-emits the same concern under each PR
prefix.** Slugs are written as `<pr_number>-<slug>.md`, and the only dedup is
`os.path.exists(path)` for that exact prefixed name. So a concern carried from
PR #41 into #42/#43/#44 lands as `42-…`, `43-…`, `44-…` — distinct files for
one logical concern. The corpus has ballooned to ~18 active from ~6 unique.

## Key Files

- `plugins/workaholic/skills/report/scripts/apply-carryover-verdicts.sh` - PRIMARY (Bug 1). The python `parse()` (lines ~24-36) must accept BOTH `{"verdicts": [...]}` and a bare `[...]`.
- `plugins/workaholic/skills/ship/scripts/extract-carryover.sh` - PRIMARY (Bug 2). The slug/exists check (python, lines ~85-89) must dedup by canonical concern identity across PR prefixes, not just the exact `<pr>-<slug>` filename.
- `plugins/workaholic/skills/report/SKILL.md` - Phase 1 documents writing the verdicts to `/tmp/carryover-verdicts.json` and piping to the apply script; once Bug 1 is fixed, the orchestrator may pass the full `{"verdicts":…}` object directly — update the prose so the workaround is no longer required.
- `scripts/test-workflow-scripts.mjs` - Add hermetic cases for both fixes.
- `outputs/workflows/skills/ship/ship/scripts/extract-carryover.sh` + the bundled report scripts under `outputs/workflows/skills/ship/report/scripts/` - GENERATED; regenerate `outputs/`.

## Related History

These bugs were diagnosed and carried across PRs #43 and #44 and re-confirmed active on the two most recent ships; they are the root causes behind the manual bare-array workaround used during `/report`.

Past tickets that touched similar areas:

- [20260617231848-ship-confirm-in-production-before-merge.md](.workaholic/tickets/archive/work-20260617-231848/20260617231848-ship-confirm-in-production-before-merge.md) - Most recent ship-pipeline change; its report run again hand-wrote a bare verdicts array to dodge Bug 1, and its story documents the corpus bloat from Bug 2.

## Implementation Steps

1. **Bug 1 — accept both shapes** in `apply-carryover-verdicts.sh`: after `json.loads`, if the parsed value is a dict, use `data.get("verdicts", [])`; if it is a list, use it directly; otherwise treat as empty. Keep the tab-delimited output contract unchanged. Remove the silent failure path where possible (let a genuinely malformed input surface, rather than `2>/dev/null` hiding everything).
2. **Update `report/SKILL.md` Phase 1** to write and pipe the full `{"verdicts": [...]}` object (the natural judge output), now that the script accepts it — retiring the bare-array workaround. Optionally keep accepting a bare array for back-compat.
3. **Bug 2 — canonical dedup** in `extract-carryover.sh`: derive a stable identity from the concern (the bare slug without the PR prefix, or a content hash of title+normalized description). Before writing, scan existing `.workaholic/concerns/*.md` (and optionally `archive/`) for a concern with the same identity; if one exists and is still active, **skip** (or update its carry chain) instead of writing a new `<pr>-<slug>.md`. Preserve the `<pr>-<slug>` naming for genuinely new concerns.
4. **Decide archive handling** — a concern already resolved+archived under an old PR prefix should not be re-created from a new story; treat an archived match as "already handled" and skip.
5. **Add smoke tests**: (a) `apply-carryover-verdicts.sh` given `{"verdicts":[{resolved}]}` archives the resolved file and reports `resolved:1`; given a bare array still works. (b) `extract-carryover.sh` run twice with the same concern under different PR numbers produces ONE concern file, not two.
6. **Regenerate `outputs/`** and run `node scripts/build-plugins/{build,verify,validate-metadata}.mjs` and `node scripts/test-workflow-scripts.mjs`.

## Considerations

- **operation:CI/CD policy** — the carry-over pipeline is part of the repo's report/ship automation; a step that silently swallows input (Bug 1) is exactly the "looks green but did nothing" failure the policy warns against. Surface failures instead of hiding them (`plugins/workaholic/skills/operation/policies/ci-cd.md`).
- **implementation:declarative/type thinking** — Bug 1 is an unmodeled input-shape assumption (array vs object). Normalize the shape once at the boundary so the rest of the script has a single, known representation (`plugins/workaholic/skills/implementation/policies/functional-programming.md`).
- **Idempotency** — after Bug 2's fix, re-running `extract-carryover.sh` for the same story/concern must be a no-op; assert this in tests.
- **One-time cleanup (separate)** — the existing ~18 active concerns already contain chained duplicates (`41-…`, `42-carried-from-41-…`, …). This ticket stops *new* duplication; collapsing the *existing* duplicates is a follow-up housekeeping pass, not in scope here.
- **Shell rule / portability** — keep logic in the bundled scripts; both ship cross-agent via `outputs/`, so regenerate and keep them self-contained (`verify.mjs`).
