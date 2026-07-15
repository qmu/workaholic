---
created_at: 2026-07-15T16:33:11+09:00
author: a@qmu.jp
type: bugfix
layer: [UX, Config]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Mission Lens Stops Reporting What It Has Nothing to Say About

## Overview

The mission lens prints a line per active mission on every `Stop`, directly above Claude Code's own answer, and a developer reported it as noise they read past to get to the agent's message. Measured in `/home/ec2-user/projects/research` (this repo has no `.workaholic/missions/`, so the lens is a silent no-op here — the report originates there and the fix lands here): the lens emits **7 lines, of which 1 carries information**.

Two independent causes, both fixed in `hooks/mission-lens.sh`:

1. **No signal threshold.** Six of the seven missions have an empty `## Acceptance` section, so `progress.sh` returns `total=0` and `next-acceptance.sh` returns nothing. Each renders as a bare title plus `0/0 acceptance criteria met` — a technical condition (the section was never filled in) reported with no next step and nothing to act on. `total` is already parsed at line 72 and then ignored at line 76.
2. **A non-mission worktree gets the main tree's list.** The worktree-focus rule keys `.worktrees/<slug>` to a mission slug — which is correct by design, since `slug.sh` is the single source deriving both the mission directory name and the worktree directory name. But when `ROOT` is a worktree whose basename matches no mission (a `/drive` worktree, e.g. `.worktrees/work-20260714-005155`), `CURRENT_MISSION` stays empty and control falls through to the **main-tree** branch, which lists every mission that owns no worktree. A session focused on one ticket in its own worktree is shown the whole roadmap. That fall-through is the "unrelated to what this session is doing" complaint.

Deliberately **out of scope**: shortening or throttling the `Stop` message itself. Removing the `0/0` lines takes the reported case from 7 lines to 1, and the volume question should be judged after that, not before. Also out of scope: back-filling worktrees for the seven missions in `research/`, which is data in another repository, not code here.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — the change stays inside `hooks/mission-lens.sh`; `hooks/` is not built, so no `outputs/` footprint and no new script.
- `workaholic:implementation` / `policies/coding-standards.md` — realized here by `rules/shell.md`: POSIX sh, `#!/bin/sh -eu`, no bashisms; machine-checked by `hooks/posix-lint.sh` and re-asserted under `dash`.
- `workaholic:design` / `policies/modeless-design.md` — the lens is an orientation aid, not a nag. Both events must stay non-forcing: `Stop` keeps emitting only `systemMessage` (never `decision: block`), `UserPromptSubmit` keeps emitting `additionalContext`. Suppressing noise is in-policy; escalating to force attention is not.
- `workaholic:design` / `policies/self-explanatory-ui.md` — the Stop nudge *is* the UI, and every line must earn its place. `0/0 acceptance criteria met` reports a technical condition rather than telling the developer what they can do next; the remedy is to say nothing, not to say more.
- `workaholic:design` / `policies/interaction-design-standard.md` — the degenerate state must be decided deliberately, not fall out of the loop. `total == 0` and "worktree that owns no mission" are both currently undecided states that default to the noisy branch.
- `workaholic:implementation` / `policies/domain-layer-separation.md` — the hook is a thin entry point. Gate on the `total` that `progress.sh` already returns; do not re-parse `## Acceptance` in the hook.
- `workaholic:implementation` / `policies/test.md` — the lens's scoping is under hermetic test; new rules extend that suite rather than being verified by eye.
- `workaholic:implementation` / `policies/objective-documentation.md` — CLAUDE.md and `mission/SKILL.md` state the current gating rules as fact and go false with this change; update them in the same commit.

## Key Files

- `plugins/workaholic/hooks/mission-lens.sh` - The whole change. Line 72-73 parses `total` and line 76 ignores it; lines 41-47 compute `CURRENT_MISSION` and silently fall through to the main-tree branch when a worktree owns no mission. Its header comment (lines 3-16) is a behavioral spec and goes stale too.
- `plugins/workaholic/skills/mission/scripts/progress.sh` - Defines the `0/0` case: `printf "%d %d", checked + 0, total + 0` returns `0 0` for an empty `## Acceptance` section. This is a legitimate result, not an error — the caller must decide what it means. **Do not modify** (it is built into `outputs/workflows`; changing it forces a rebuild this ticket does not need).
- `plugins/workaholic/skills/mission/scripts/next-acceptance.sh` - Prints nothing when the section is empty, which is why a `0/0` line has no `; next:` suffix and therefore no actionable content. Corroborates `total == 0` as a sound proxy for "this line says nothing". **Do not modify.**
- `plugins/workaholic/skills/mission/scripts/slug.sh` - The single source of the slug rule, deriving both the mission directory name and the `.worktrees/<slug>` name. This is *why* basename-matching is the right mechanism and must not be replaced by a frontmatter field.
- `plugins/workaholic/skills/mission/scripts/create.sh` - Context, not a change: line 46 self-assigns to the creator and lines 76-81 scaffold `## Acceptance` as a comment with zero items, so every mission is born matching the lens's gate while carrying no signal. See Considerations.
- `plugins/workaholic/hooks/hooks.json` - No change needed; the events stay as registered (`UserPromptSubmit` line ~72, `Stop` line ~83).
- `scripts/test-workflow-scripts.mjs` - `testMissionLensWorktreeFocus` (line 656, registered line 3554) is the lens's only coverage, and its fixture excludes both bugs by construction. Extend it.
- `CLAUDE.md` - The "Always-on mission lens" section documents the gate and the worktree rule as fact.
- `plugins/workaholic/skills/mission/SKILL.md` - Line 68 (`assignee` "is the key the mission lens gates on"), line 145 (`summary.sh` uses "the same gate the mission lens uses" — that claim changes), line 188 (the lens's full behavioral description).

## Related History

The lens's noise has been addressed once before, from the same motivation, and that work shipped — this ticket is the next layer, not a re-do. The worktree-focus rule below is **already implemented and tested**; do not re-implement it.

Past tickets that touched similar areas:

- [20260714014042-mission-lens-worktree-focus.md](.workaholic/tickets/archive/work-20260714-000543/20260714014042-mission-lens-worktree-focus.md) - Shipped the worktree-focus rule for this exact file, citing `design/modeless-design` ("the lens is an orientation aid, not a nag"). It hides missions that *own* a worktree; it never decided what a worktree that owns *no* mission should do. That undecided case is bug 2 here.
- [20260714000528-command-summary-mode.md](.workaholic/tickets/archive/work-20260714-000543/20260714000528-command-summary-mode.md) - Established the `assignee` == `git config user.email` gate the lens reuses. The gate is working correctly and must stay; new scoping is additional to it, never a replacement.
- [20260706203046-mission-progress-and-changelog-automation.md](.workaholic/tickets/archive/work-20260713-144839/20260706203046-mission-progress-and-changelog-automation.md) - Source of the computed `checked/total` model. Progress is derived, never stored, so `0/0` means "no criteria written", not "no progress made".
- [20260713103820-mission-active-archive-split-and-close.md](.workaholic/tickets/archive/work-20260713-144839/20260713103820-mission-active-archive-split-and-close.md) - Defines `missions/active/` as the lens's scan root; only `close.sh` moves a mission out of it.

## Implementation Steps

1. Read the four `design` and `implementation` policy hard copies listed under `## Policies`, plus the shipped predecessor ticket, so the worktree rule is understood as intentional before touching it.
2. In `hooks/mission-lens.sh`, add the **non-mission-worktree** exit. Record whether `ROOT` is under `.worktrees/` at all, separately from whether that worktree names an active mission, and exit 0 when it is a worktree but names no mission. After this, the `else` branch of the per-mission loop is reachable only from the main tree — tighten its comment to say so.
3. In the same file, add the **signal threshold**: `continue` when `total` is 0, placed after `total` is defaulted and *before* the `next-acceptance.sh` call, so a skipped mission costs one subshell instead of two.
4. Update the hook's header comment (lines 3-16) to state both rules — it is the file's spec.
5. Extend `testMissionLensWorktreeFocus` in `scripts/test-workflow-scripts.mjs` with the two cases its current fixture cannot reach: a mission whose `## Acceptance` section is empty (assert no line for it, while a sibling with criteria still appears), and a branch-named `.worktrees/work-20260714-005155` worktree (assert the hook emits nothing at all). Keep the three existing assertions green.
6. Update `CLAUDE.md`'s "Always-on mission lens" section and `mission/SKILL.md` (lines 68, 145, 188) so they describe the shipped behavior. Line 145's claim that `summary.sh` uses "the same gate the mission lens uses" becomes false — the lens now gates on assignee **and** signal **and** location, while `summary.sh` gates on assignee alone. State the difference rather than deleting the cross-reference; `/mission summary` is deliberately the on-demand view that still shows a `0/0` mission.
7. Run the verification commands in `## Quality Gate` and confirm `build.mjs` produces no `outputs/` diff (this change is confined to `hooks/`, which is not built).

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission with an empty `## Acceptance` section (`total == 0`) produces **no line**; a sibling mission with at least one criterion still produces its line unchanged.
- Inside a worktree whose basename matches no active mission slug (e.g. `.worktrees/work-20260714-005155`), the hook emits **nothing** — exit 0, empty stdout — on both `Stop` and `UserPromptSubmit`.
- Inside a mission's own `.worktrees/<slug>` worktree, only that mission surfaces (existing behavior, unbroken).
- In the main tree, missions owning a worktree stay hidden and worktree-less missions with criteria still surface (existing behavior, unbroken).
- Another user's mission never surfaces (existing `assignee` gate, unbroken).
- `Stop` still emits only `systemMessage` and `UserPromptSubmit` only `additionalContext` — neither event blocks or forces a turn.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, including the two new cases in `testMissionLensWorktreeFocus`: one seeded with an empty `## Acceptance` section, one seeded with a branch-named `work-*` worktree. Both conditions are absent from the current fixture by construction, so the tests must fail against the unfixed hook — confirm that before fixing.
- `sh plugins/workaholic/hooks/posix-lint.sh` reports zero findings.
- `node scripts/build-plugins/build.mjs` leaves `outputs/` with no diff.

**Gate** — what must pass before approval:

- The full suite and posix-lint are green, `outputs/` is clean, and the two new tests are demonstrated to fail on the pre-fix hook (so they test the fix, not the fixture).
- `CLAUDE.md` and `mission/SKILL.md` describe the shipped behavior — specifically, `SKILL.md` line 145 no longer claims the lens and `summary.sh` share one gate.

## Patches

> **Note**: These patches are speculative — verify line numbers and context before applying.

### `plugins/workaholic/hooks/mission-lens.sh`

```diff
@@ -38,13 +38,20 @@ ME=$(git config user.email 2>/dev/null || true)
 # Worktree focus: a mission runs in its own worktree (.worktrees/<slug>). Inside
 # a mission worktree, surface ONLY that mission — you are already focused on it,
 # so other worktrees' missions are noise. In the main tree (or a non-mission
 # worktree), surface only missions that do NOT own a dedicated worktree (a
 # worktree-owned mission stays silent everywhere but its own worktree).
 CURRENT_MISSION=""
+IN_WORKTREE=""
 case "$ROOT" in
     */.worktrees/*)
+        IN_WORKTREE=yes
         cand="${ROOT##*/}"
         [ -f "${ACTIVE_DIR}/${cand}/mission.md" ] && CURRENT_MISSION="$cand"
         ;;
 esac
+# A worktree that names no mission is a /drive worktree (.worktrees/work-*): it is
+# focused on one ticket, and the roadmap is not its business. Stay silent rather
+# than falling through to the main tree's list.
+[ -z "$IN_WORKTREE" ] || [ -n "$CURRENT_MISSION" ] || exit 0
+
 # Slugs that own a registered .worktrees/<slug> worktree (one per line).
 WT_SLUGS=$(git worktree list --porcelain 2>/dev/null | sed -n 's|^worktree .*/\.worktrees/\(.*\)$|\1|p' || true)
@@ -57,7 +64,7 @@ for f in "$ACTIVE_DIR"/*/mission.md; do
     if [ -n "$CURRENT_MISSION" ]; then
         # Inside a mission worktree: only that worktree's mission.
         [ "$slug" = "$CURRENT_MISSION" ] || continue
     else
-        # Main tree / non-mission worktree: skip missions owned by a worktree.
+        # Main tree (a non-mission worktree exited above): skip worktree-owned missions.
         if printf '%s\n' "$WT_SLUGS" | grep -Fqx "$slug"; then
             continue
         fi
@@ -69,10 +76,14 @@ for f in "$ACTIVE_DIR"/*/mission.md; do
     checked=$(printf '%s' "$prog" | sed -n 's/.*"checked":[ ]*\([0-9][0-9]*\).*/\1/p')
     total=$(printf '%s' "$prog" | sed -n 's/.*"total":[ ]*\([0-9][0-9]*\).*/\1/p')
     [ -n "$checked" ] || checked=0
     [ -n "$total" ] || total=0
+
+    # No acceptance criteria written yet: progress says 0/0 and next-acceptance.sh
+    # has nothing to offer, so the line would carry no information. Stay silent;
+    # `/mission summary` is where an unfilled mission is still visible on demand.
+    [ "$total" -gt 0 ] || continue
+
     next=$(sh "${PLUGIN_ROOT}/skills/mission/scripts/next-acceptance.sh" "$f" 2>/dev/null || true)
```

## Considerations

- **The `0/0` filter treats a symptom whose cause is upstream** (`plugins/workaholic/skills/mission/scripts/create.sh` lines 46, 76-81). Every mission is born self-assigned *and* with an empty `## Acceptance` section — i.e. born matching the lens's gate while carrying no signal. This ticket deliberately silences them rather than preventing them, because requiring a criterion at creation time changes a built script (forcing an `outputs/` rebuild) and a UX decision about mission creation that has not been made. Consequence to accept knowingly: a mission whose criteria are never written becomes invisible to the lens and may stay unfilled indefinitely. `/mission summary` and `/catch` still show it. If unfilled missions accumulate, the follow-up is in `create.sh`, not the hook.
- **`SKILL.md` line 145's "the same gate the mission lens uses" becomes untrue** (`plugins/workaholic/skills/mission/SKILL.md`). The divergence is intentional — an always-on nudge and an on-demand list should not have the same threshold — but it must be written down, or the next reader will treat it as drift and "fix" it back.
- **The two paths diverge in what they suppress** (`plugins/workaholic/hooks/mission-lens.sh` lines 95-105). Both rules here apply to `Stop` and `UserPromptSubmit` alike, so the model and the developer keep seeing the same set — which `workaholic:planning` / `ai-native-future` asks for ("AI paths and human paths aligned on top of the same function"). Any future Stop-only throttle breaks that symmetry deliberately and should say so.
- **`layer: [UX, Config]` departs from the precedent** (`.workaholic/tickets/archive/work-20260714-000543/20260714014042-mission-lens-worktree-focus.md`, which used `[Infrastructure]`). `UX` selects `workaholic:design`, where the policies that actually govern this change live; `Config` covers the hook as tooling. `Infrastructure` would additionally pull in `workaholic:operation`, none of whose three policies apply here. Noted so the layer difference reads as a choice, not an inconsistency.
- **A skipped mission still costs a `progress.sh` subshell**, which sources `lib/resolve.sh` and runs `missions_migrate_layout()` (`plugins/workaholic/skills/mission/scripts/lib/resolve.sh`). Placing the `total` check before `next-acceptance.sh` halves the cost per silenced mission but does not eliminate it. CLAUDE.md's claim that the lens "costs only a few greps" is optimistic at seven missions; if this becomes a real cost, the fix is a batch reader in `skills/mission/scripts/`, not inlined parsing in the hook.
- **One queued ticket touches the same file** (`.workaholic/tickets/todo/a-qmu-jp/20260715143954-mission-relation-many-valued.md` line 112). Its concern is relation cardinality, not lens selection, and it lists `hooks/mission-lens.sh` under "Confirmed NOT affected — do not touch". Overlap is low, but if both are driven in one branch, apply this one's hook edits first.
