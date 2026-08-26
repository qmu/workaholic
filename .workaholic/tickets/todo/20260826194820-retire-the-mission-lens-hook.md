---
created_at: 2026-08-26T19:48:20+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy: auto
verification_handoff:
claim: work-20260826-195732
---

# Retire the mission-lens hook

## Overview

Delete `plugins/workaholic/hooks/mission-lens.sh` — the always-on roadmap
re-anchor on UserPromptSubmit (model-visible) and Stop (user-visible) — together
with its hooks.json wiring, its tests, and every live-behavior document that
names it. Its two demonstrated jobs are carried elsewhere now: the
finished-mission discovery it performed by accident (eleven done-but-open
missions, feedback `20260822182237`) is owned by `/moderate`'s
`closable-missions` step, which since 2026-08-24 closes what it proves; and the
roadmap/claimable-work view lives on bare `/mission` and in `/drive`'s and
`/implement`'s own surveys, which never read the lens. What the lens still emits
in an attended session is a status line about queue work the loop itself will
drive — the shape this repository has retired repeatedly (the 🔧/📦 status
roots, the `[Workaholic]` routine) on the ground that a status line addressed to
nobody is noise whatever its dedup key.

The lens's own arguments are answered, not dismissed. Its three gates
(ownership/location/signal) and summarize-on-change compaction were real
noise-reduction work, but they tuned the volume of a surface whose remaining
information has no reader: the unattended path never read it, and the attended
reader (the operator) reports it as noise. It is also the only always-on hook
wired into a code path that writes — its readers reach `lib/resolve.sh`'s living
migration, which `git add`s; a stale install running that backwards on every
prompt caused the 2026-08-04 drive-loop outage (`dirty_workspace`,
`docs/drive-loop-runbook.md`).

**Costs, stated**: (1) after this the plugin registers no `Stop` hook at all and
no surface speaks unasked in an attended session — `/moderate`'s root is
repository-scoped, hourly, and lands in Slack; (2) the model-visible roadmap
orientation on every prompt disappears — a deliberate reduction of the
always-in-context surface `policy-as-plugin` builds, judged worth it because
the roadmap is one `/mission` away; (3) the in-session `[unclaimed — yours to
take]` offer survives only on-demand (bare `/mission`, `/drive`'s survey).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (all code work)
- `workaholic:implementation` / `policies/objective-documentation.md` — every doc naming the lens as live behavior must be corrected in the same commit; historical decision records are re-voiced as history, never erased
- `workaholic:development` / `policies/commit-change-history.md` — the retirement rationale rides the ticket/story/PR; `docs/loop-engineering-workflow.md`'s dated decision records stay intact
- `workaholic:development` / `policies/policy-as-plugin.md` — the change removes part of the always-in-context surface this policy builds; the cost is stated in Overview rather than absorbed

## Key Files

- `plugins/workaholic/hooks/mission-lens.sh` — delete (227 lines; sole writer of ephemeral `${TMPDIR:-/tmp}/workaholic-mission-lens/` cksum state — nothing in-repo to clean)
- `plugins/workaholic/hooks/hooks.json` — remove the UserPromptSubmit entry (leaving `policy-lens.sh` alone on that event) and delete the **entire `Stop` key** (mission-lens is its only registrant; a dead `"Stop": []` is the value-nothing-declares shape the `[Workaholic]` retirement refused). `hooks` stays the only top-level key
- `scripts/test-workflow-scripts.mjs` — delete `SCRIPTS.missionLens` (line ~33), the three lens test functions + their registry rows (`testMissionLensUnassigned`, `testMissionLensOnChange`, `testMissionLensWorktreeFocus`), and the lens pin embedded in `testMissionResolution` (~lines 1893-1899). Deleted, never skipped or excluded (the suite's own rule). The resolve.sh absolute-path-caller coverage that pin carried is re-pointed at a surviving absolute-path caller (`drive/scripts/plan-units.sh` or `mission/scripts/summary.sh`), not dropped. `testHooksExecutable` self-updates from hooks.json — no edit
- `CLAUDE.md` — delete the `mission-lens.sh` bullet from the Hooks list; re-voice the Mission-lifecycle paragraph's "found only because the mission lens printed all of them on every prompt" as past tense (keep the measurement); `mission-lens.sh` also appears in the `layout-doctor.sh` context — check the whole Hooks section
- `README.md` — "always-on policy and mission lenses" → singular
- `plugins/workaholic/skills/mission/SKILL.md` (~line 122), `reference/schema.md` (~lines 76, 80) — drop the lens from consumer enumerations
- `plugins/workaholic/skills/gather/SKILL.md` (~line 53) — drop the lens from the owners.sh consumer list
- `plugins/workaholic/hooks/validate-mission.sh` (comments, ~lines 10/30), `mission/scripts/summary.sh` (~7/39 — line 39's claim is already stale: the hook never called summary.sh; surviving consumers are `commands/mission.md` and `moderate/scripts/step-closable-missions.sh`), `mission/scripts/lib/resolve.sh` (~214), `mission/scripts/close.sh` (~63-64 — re-justify the worktree-per-slug rule without the lens), `mission/scripts/next-acceptance.sh` (~7 — name surviving callers), `drive/scripts/plan-units.sh` (~145), `moderate/scripts/step-closable-missions.sh` (~9) and `moderate/reference/workflow.md` (~353 — past-tense the historical citation, keep the fact)
- `docs/drive-loop-runbook.md` (~line 284) — the `dirty_workspace` row: re-anchor on the living migration in `lib/resolve.sh` (still reached by 15+ callers) and mark the lens path as applying to pre-retirement installs
- `docs/loop-engineering-workflow.md` (~line 256) — historical decision record: leave intact
- `.workaholic/terms/core-concepts.md` (~lines 66, 90-91) — deliberate authored edit of the `hook`/`lens` Term entries ("Two ship active" becomes one); nothing mechanical flags this (`area-freshness.sh`'s RETIRED list doesn't cover "mission lens"), so this step is the only catch
- `outputs/workflows/` — never hand-edit; the comment-bearing mission/drive scripts are copied into six bundles each, so run argument-less `node scripts/build-plugins/build.mjs` in the same change

## Related History

The lens shipped 2026-07-13 (a7166555) and was narrowed four times — worktree focus, the 0/0 signal gate, unassigned-mission surfacing, summarize-on-change — always tuning volume, never questioning the surface. The one complaint against the surface itself (ticket `20260718231848`) predates the loop's current push channels.

- [20260718231848-goal-stop-hook-context-injection-buries-message.md](.workaholic/tickets/archive/work-20260717-141501/20260718231848-goal-stop-hook-context-injection-buries-message.md) - per-turn injection buried the developer's message; its remedies did not include removal (the root this ticket answers outright)
- [20260715163311-mission-lens-says-less.md](.workaholic/tickets/archive/work-20260715-112717/20260715163311-mission-lens-says-less.md) - the signal gate; its Considerations first wrote down the per-prompt subshell cost
- [20260714014042-mission-lens-worktree-focus.md](.workaholic/tickets/archive/work-20260714-000543/20260714014042-mission-lens-worktree-focus.md) - gate 2 and the tests that pin it
- [20260715215008-summary-unassigned-missions.md](.workaholic/tickets/archive/work-20260715-213222/20260715215008-summary-unassigned-missions.md) - the `[unclaimed — yours to take]` offer; the on-demand half survives
- [20260721161212-developer-centric-bare-mission.md](.workaholic/tickets/archive/work-20260721-153431/20260721161212-developer-centric-bare-mission.md) - built the bare `/mission` roadmap this retirement defers to; its insight — grep for script consumers before removing a surface — is applied in Implementation Steps
- [20260717152506-mission-resolution-follows-the-ticket-not-cwd.md](.workaholic/tickets/archive/work-20260717-141501/20260717152506-mission-resolution-follows-the-ticket-not-cwd.md) - the embedded resolve.sh pin this ticket re-points
- [20260804041306-a-stale-installed-plugin-halts-the-drive-loop.md](.workaholic/tickets/archive/work-20260804-085951/20260804041306-a-stale-installed-plugin-halts-the-drive-loop.md) - the outage that makes the lens the only always-on hook reaching a writing code path

## Implementation Steps

1. Delete `plugins/workaholic/hooks/mission-lens.sh`.
2. Edit `plugins/workaholic/hooks/hooks.json`: remove the mission-lens
   UserPromptSubmit hook object; delete the whole `Stop` key. Verify with
   `node scripts/build-plugins/validate-metadata.mjs`.
3. Edit `scripts/test-workflow-scripts.mjs` per Key Files: delete the constant,
   the three functions, their three registry rows, and the embedded pin —
   re-pointing the resolve.sh absolute-path-caller assertion at a surviving
   caller before deleting the lens invocation.
4. Correct every live-behavior document and script comment listed in Key Files;
   leave `docs/loop-engineering-workflow.md`'s dated records intact; make the
   Term edit in `.workaholic/terms/core-concepts.md` deliberately.
5. Run `node scripts/build-plugins/build.mjs` (argument-less) to regenerate
   `outputs/` for the touched skill files and comments.
6. Run the full local verification sequence (Quality Gate).

## Quality Gate

Decided: verification is the repository's own five-command local sequence plus a live hook probe — no new tests are written for a deletion; the existing suite's absence-of-dangling-reference checks are the proof (developer may override at /drive).

**Acceptance criteria** — the checkable conditions that must hold:

- `plugins/workaholic/hooks/mission-lens.sh` does not exist; `grep -r "mission-lens" plugins/ scripts/ README.md CLAUDE.md` finds no live-behavior reference (historical records in `docs/loop-engineering-workflow.md`, `.workaholic/tickets/archive/`, `.workaholic/stories/`, `.workaholic/feedbacks/` are exempt; past-tense citations in `step-closable-missions.sh`/`moderate/reference/workflow.md` are allowed)
- `hooks/hooks.json` parses, carries `hooks` as its only top-level key, and has no `Stop` key
- A UserPromptSubmit/Stop event in a session running this checkout injects no mission line (probe: pipe `{"hook_event_name":"Stop"}` — the hook path no longer exists to invoke)
- The resolve.sh cwd-independence test still asserts an absolute-path caller

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs` then `git status --porcelain outputs/` is clean after commit (Outputs Freshness equivalent)
- `node scripts/build-plugins/verify.mjs`
- `node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs` is green (includes `testHooksExecutable`, which walks hooks.json and fails on a dangling entry)
- `bash plugins/workaholic/hooks/layout-doctor.sh .` conforming

**Gate** — what must pass before approval:

- All five commands green; the grep criterion holds; hooks.json criterion holds.

## Considerations

- The `Stop` event key is deleted outright, not emptied — after this the plugin ships no Stop hook, which is intended and stated in the story/PR (`plugins/workaholic/hooks/hooks.json`).
- Nothing is orphaned: `progress.sh`, `next-acceptance.sh`, `owners.sh`, `summary.sh` all keep multiple live callers (`plugins/workaholic/skills/mission/scripts/`, `drive/scripts/plan-units.sh`, `moderate/scripts/step-closable-missions.sh`); do not retire collateral readers.
- No renames.tsv row (a retirement is not a rename), no layout-allowlist change (no `.workaholic/` directory involved), no check-deps change (it tracks only the three guards), no migration script (the hook creates nothing in a consuming tree).
- `testMissionLensWorktreeFocus` is the only local user of `SCRIPTS.createMissionWorktree`/`cleanupMissionWorktree` in its block — confirm those keep coverage elsewhere before deleting the function (`scripts/test-workflow-scripts.mjs` lines ~2846-2938).
- The commit is deletion-dominated; if any new file is created (should not be needed), name it in `commit.sh`'s `files...` to avoid the half-a-rename refusal (`plugins/workaholic/skills/commit/SKILL.md`).
