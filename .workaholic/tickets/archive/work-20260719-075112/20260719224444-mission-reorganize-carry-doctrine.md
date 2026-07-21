---
created_at: 2026-07-19T22:44:44+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission:
---

# Make reorganize-and-carry the encouraged end for a mission whose direction changed

## Overview

A mission is currently **sticky to finish honorably**: the two clean endings are `achieved` (every `## Acceptance` item checked) or `carried` (done-as-framed, remainder to a successor), and the doctrine frames `carried` as an exception rather than the normal answer. In practice a mission's direction changes mid-flight — a **different class of issue** surfaces, the original criteria become **contradictory or moot**, or the remainder really **belongs to another active mission**. Grinding to check every original criterion (or to fill in every quality gate) against a plan that no longer reflects reality is wasted effort; forcing `achieved` fabricates completion the computed-progress model is built to prevent; `abandoned` discards real progress.

The mechanisms already exist — `carried` (incl. merge via `--successor <slug>`), the `/mission` **replan** flow, and replan's `acceptance dropped` changelog line for a now-moot unchecked item. What is missing is the **doctrine that makes reorganize-and-carry the positively-encouraged response to a changed direction**, and the **surfacing** of that recommendation where a session meets a stuck mission: `/monitor`'s morning report and `/carry`'s handoff.

This is a **doctrine + surfacing** change only. No new close outcome, no new script, no change to `close.sh` / `validate-mission.sh` / `drive-authorized.sh`. The write-time floor stays: an authorized mission still needs a non-empty `## Acceptance` and `## Experience` (validated by `hooks/validate-mission.sh`). "Skip filling quality gates" means **stop grinding to CHECK moot criteria** — drop them in the reorganizing replan — not relax that floor.

**Scope decisions (developer, at ticket time):**
- Reach = doctrine (mission/close) **plus** surfacing the reorganize recommendation in `/monitor`'s final report and `/carry`'s mission-monitor case. No new mechanism.
- The "mergeable" case = the existing `carried --successor <existing-slug>` (carry the unchecked criteria into an existing active mission); documented, not re-built.
- "Skip quality gates" = drop now-moot unchecked criteria via replan (`acceptance dropped`); the `validate-mission` floor is untouched.

## Policies

- `workaholic:implementation` / `objective-documentation` — the doctrine and the surfaced recommendation must be **observable and actionable**, not aspirational: name the concrete triggers (new issue class / contradiction / mergeable-into-another-mission) and the concrete next action (`/mission <replan instruction>`, or `carried --successor <slug>`), never "consider reorganizing".
- `workaholic:design` / `history-structures` — reorganization stays **recorded, append-only**: dropping a moot criterion is an `acceptance dropped — <artifact>` changelog line and a carry is `mission carried into <successor>`, exactly as the replan/close scripts already emit. The doctrine must route through those, never hand-editing.
- `workaholic:development` / `overnight-ai` — `/monitor` runs unattended after dispatch: it **recommends** reorganize-and-carry in the morning report and **never** closes or replans a mission itself (a leaf cannot ask; the main agent does not auto-decide direction). The honest terminal token is unchanged — a reorganizable-but-unreorganized mission is still `pending`, not `ok`.
- `workaholic:implementation` / `observability` — the recommendation lands in the deliverable a human reads (the `/monitor` report, the `/carry` resumption ticket), so a stuck mission's next move is graspable without reconstructing the run.

## Implementation Steps

1. **`skills/mission/SKILL.md` — the reorganize-and-carry doctrine.** Extend the `carried` outcome guidance (in the `close.sh` **Outcomes** area and/or a short subsection near it) to make reorganize-and-carry the **encouraged, positive** answer for a mission whose direction changed. State the three triggers explicitly: a **different class of issue** surfaced, the original criteria are **contradictory or moot**, or the remainder **belongs to another active mission**. Frame the choice positively: `carried` (mint a successor, or **merge via `--successor <slug>`**) is the *honest normal* verdict for a changed-direction mission; `achieved` would fabricate completion; `abandoned` would discard progress. Say plainly: **do not grind to check every original acceptance criterion** — drop the now-moot unchecked ones during the reorganizing **replan** (recorded as `acceptance dropped` changelog lines), and carry the still-valid remainder forward. Cross-link the **Replan** section as the reorganization mechanism, and note the write-time `validate-mission` floor is unchanged.
2. **`skills/monitor/SKILL.md` — §5 final report surfaces the recommendation.** When a driven mission is incomplete/escalation-blocked because its direction changed (a leaf's `deferred`/`blocked` naming a new issue class or contradiction, or §4 interference showing the remainder overlaps another mission), the morning report **recommends reorganize-and-carry** for that mission — naming the merge/successor target when interference identified one — instead of presenting it as a plain `pending` to grind later. Keep the run **unattended and non-acting**: `/monitor` recommends, never closes or replans a mission itself, and the terminal token stays honestly derived from `status.sh` (§3 unchanged).
3. **`skills/carry/SKILL.md` — mission-monitor case records the recommendation.** In the mission-monitor case (just added), when the carried state reflects a direction change (deferred escalations that are a new issue class/contradiction, or a mission whose remainder merges elsewhere), the per-mission resumption ticket's `## Decisions` / `## Findings` records the **reorganize recommendation** — that the fresh session should weigh `/mission` replan or `carried --successor <slug>` over driving the stale queue as-is. Stays **capture-only**: `/carry` never closes or replans.
4. **Docs in the same change.** Update `CLAUDE.md`'s `/mission`, `/monitor`, and `/carry` rows (and `README.md`'s `/mission` / `/monitor` rows if their wording implies achieving every criterion is the only honorable end) to reflect the positively-framed reorganize-carry doctrine. Verify doc truthfulness before requesting approval (the `/report` doc-drift backstop is not the place to fix it).
5. **Rebuild generated artifacts and verify.** `skills/mission/SKILL.md` is built into `outputs/workflows` — run `node scripts/build-plugins/build.mjs`, then `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs`. `monitor` and `carry` are Claude-only (not built), so only `mission` should move `outputs/`; confirm the Outputs-Freshness diff is exactly the mission doctrine and nothing else.

## Quality Gate

**Method:** prose/doctrine review against the source it describes, plus the full script/verify suite; no behavioral code changes, so no new script tests. Approve only when every item below holds:

- `skills/mission/SKILL.md` states reorganize-and-carry is the **encouraged** response to a changed-direction mission, names the three triggers (new issue class / contradiction / mergeable-into-another-mission), and explicitly says **not** to grind moot criteria — drop them via replan (`acceptance dropped`) — while stating the `validate-mission` floor (non-empty `## Acceptance` + `## Experience` once authorized) is untouched.
- The "mergeable" path is documented as the existing `carried --successor <existing-slug>` — **no new close outcome or script**; `close.sh`, `validate-mission.sh`, and `drive-authorized.sh` are unchanged (`git diff` shows no edits to those files).
- `skills/monitor/SKILL.md` §5 recommends reorganize-and-carry for a direction-changed incomplete mission and names the merge/successor target when §4 found one; the run stays unattended and never auto-closes/replans; the terminal token remains honestly derived (`ok` only on genuine completion, else `pending`).
- `skills/carry/SKILL.md` mission-monitor case records the reorganize recommendation in the resumption ticket's `## Decisions`/`## Findings` and stays capture-only.
- `CLAUDE.md` (and `README.md` where applicable) reflect the doctrine; no doc describes achieving every criterion as the sole honorable ending. Doc-truthfulness checked at change time.
- `node scripts/build-plugins/build.mjs` run; `verify.mjs`, `validate-metadata.mjs`, and `test-workflow-scripts.mjs` all pass; the `outputs/` diff is confined to the `mission` skill (monitor/carry are not built).

## Considerations

- **Recommend, never auto-reorganize.** Direction is a human judgment; `/monitor` (unattended) and `/carry` (capture-only) must only *surface* the reorganize recommendation. Neither closes, replans, or drops a criterion on its own — the operator runs `/mission` replan or `carried --successor`.
- **Honest terminal is preserved.** A mission that *should* be reorganized but has not been is still incomplete: `/monitor` keeps emitting `pending`, not `ok`. This doctrine changes what the report *recommends*, not what the token *asserts* — do not soften §3.
- **No relaxation of the write-time floor.** Tempting to read "skip filling quality gates" as loosening `validate-mission`; it is not. An authorized mission still needs a non-empty `## Acceptance` and `## Experience`. The loosening is only about not force-checking obsolete criteria.
- **Reuse the existing history seams.** Dropping a moot criterion and carrying the remainder already have idempotent, append-only changelog writers (`append-changelog.sh` `acceptance dropped`, `close.sh` `mission carried into <successor>`). The doctrine points at them; it must not invent a parallel record.
