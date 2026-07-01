---
created_at: 2026-07-01T22:18:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Night mode must attempt every authorized ticket — no pre-emptive skip

## Overview

Autonomous night runs are too protective. A 16-ticket `/drive night` banked only 3 tickets and declined 13 with the rationale *"large / all-or-nothing / human-in-loop tickets I deliberately did not force."* That defeats the whole point of an overnight run: the developer authorized the batch precisely so the AI would **do the work while they sleep**, then review in the morning. Declining to even attempt 13 of 16 is not safety — it is the runner second-guessing the authorization it was given.

The loophole is in the "safe-by-default failure policy." Drive Night Mode §3 skips when a ticket "cannot be implemented, or its checks/tests fail," and the Critical Rules list "out of scope, **too complex**, blocked, or **any other reason**" (`skills/drive/SKILL.md` line 197) as grounds to not proceed. Under an unattended run those subjective outs ("too complex", "any other reason") collapse into "skip anything that looks big." The trip-protocol has the sibling clause (Night Mode §4 park on "an irreducibly ambiguous requirement").

This ticket redefines the autonomous contract for **both** `/drive night` and `/trip night` to **attempt-first**: every authorized ticket (or trip phase) MUST be attempted; a skip/park is legitimate **only after a genuine attempt** whose type-check/tests fail or that hits a **named hard external blocker** (missing credential, unreachable external dependency). Size, complexity, "all-or-nothing", and "needs a human" are **explicitly not** skip reasons. The morning report is tightened to a closed set of outcomes so a future run cannot present a ticket as "deliberately did not force."

This changes the *entry condition* to skipping only. It does **not** relax the existing safety floor: the attempt-then-fail path still stashes partial work, never force-commits red checks, never auto-iceboxes, and never runs destructive git.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing, and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — the change edits authored plugin skill/command content under `plugins/` and must regenerate `outputs/` (source-vs-artifact rule); never hand-edit `.claude/` or `outputs/`.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all plugin-content work; keep the prose precise and unambiguous.
- `workaholic:implementation` / `policies/objective-documentation.md` — the night-mode contract and the morning report must be stated as **objective, verifiable outcomes** (implemented / failed / blocked), not subjective judgments ("too large", "did not force").
- `workaholic:implementation` / `policies/policy-conformance-audit.md` — the gate includes a re-read audit confirming size/complexity/"human-in-loop" are no longer stated as skip grounds anywhere in the two night-mode sections.
- `workaholic:operation` / `policies/ci-cd.md` — regenerating `outputs/` and keeping the `Outputs Freshness` CI green is part of delivery; the build must be run before the change is considered done.

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` - Night Mode §3 "Safe-by-default failure policy" (lines 178-182) and Critical Rules (lines 197-205); the "too complex / any other reason" skip loophole lives here. Also §5 report contract (lines 186-189) and Phase 4 (line 166).
- `plugins/workaholic/commands/drive.md` - line 20 one-line night-mode summary ("skip-and-record on failure") must reflect attempt-first.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - Night Mode §4 "Safe-by-default failure policy" (line 362) and the Team-lead night directive (line 368); "irreducibly ambiguous requirement" park reason.
- `outputs/workflows/` - generated artifacts; drive/report skills are rebuilt from source. Trip is Claude-only and excluded from the build, but rebuild anyway to catch any shared-closure drift.

## Related History

Night mode was built up incrementally (add mode → drop the per-ticket checkbox → add a night trip → flow trips through the design pause). Each step made the run *more* autonomous at the front end; none revisited the *failure/skip* entry condition at the back end, which is where the over-protective behavior leaks in.

Past tickets that touched this area:

- [20260617010324-add-night-drive-mode.md](.workaholic/tickets/archive/work-20260617-000311/20260617010324-add-night-drive-mode.md) - Introduced `/drive night` and the safe-by-default failure policy being tightened here (same section)
- [20260617213242-night-drive-no-per-ticket-checkbox.md](.workaholic/tickets/archive/work-20260617-210627/20260617213242-night-drive-no-per-ticket-checkbox.md) - Removed the per-ticket checkbox; established "the whole batch IS the night's work"
- [20260622220702-add-night-trip-autonomous-mode.md](.workaholic/tickets/archive/work-20260621-192132/20260622220702-add-night-trip-autonomous-mode.md) - Added `/trip night` and its sibling safe-park policy (also tightened here)
- [20260627213819-trip-flow-through-design-pause.md](.workaholic/tickets/archive/work-20260627-153246/20260627213819-trip-flow-through-design-pause.md) - Removed the design-pause green-light so trips flow autonomously (same "don't second-guess the authorization" spirit)
- [20260408113052-fix-abandon-stops-session.md](.workaholic/tickets/archive/work-20260408-001129/20260408113052-fix-abandon-stops-session.md) - Prior fix to an over-eager "stop/skip" behavior in drive

## Implementation Steps

1. **Drive Night Mode §3 → attempt-first (`skills/drive/SKILL.md` ~178-182).** Rename to make the entry condition explicit: a skip is permitted **only after a real attempt** that fails. Enumerate the *only* legitimate skip triggers: (a) the ticket was implemented but its type-check/tests are red, or (b) implementation is blocked by a **named hard external blocker** (missing credential, unreachable external service/dependency). State explicitly that **ticket size, complexity, "all-or-nothing" scope, and "this seems to need a human" are NOT skip reasons** — a large or all-or-nothing ticket must be attempted in full; if its final checks are red it becomes failed→skipped (stash + record), never pre-emptively declined. Keep the existing safety floor verbatim (stash partial work, never force-commit red checks, never auto-icebox, never destructive git).
2. **Drive Critical Rules (`skills/drive/SKILL.md` ~197).** Remove the subjective outs from the "cannot be implemented" list: strike "too complex" and "or any other reason". In night mode, the branch is: attempt every ticket; on a genuine attempted failure or named hard blocker, skip+record and continue (no icebox, no destructive git). "Too complex"/"large" must not appear as a not-proceed reason.
3. **Drive report contract (`skills/drive/SKILL.md` §5 ~186-189 and Phase 4 ~166).** Constrain the per-ticket outcome to a **closed set**: `implemented` (commit hash), `failed` (attempted → checks red; reason + stash location), or `blocked` (named hard external blocker; what unblocks it). Forbid any "declined / did not force / too large / human-in-loop" outcome category. Every authorized ticket must appear as one of the three, and totals must reconcile to the authorized batch size.
4. **Drive command one-liner (`commands/drive.md` line 20).** Update "skip-and-record on failure" to reflect attempt-first: "attempt every authorized ticket; skip-and-record only on a genuine attempted failure or a named hard external blocker."
5. **Trip Night Mode §4 (`skills/trip-protocol/SKILL.md` ~362) and Team-lead directive (~368).** Apply the same attempt-first tightening to the trip executor: a "Night Park" is legitimate only for a dev-env that is unfixable *after attempting the fix* or a blocking external dependency — **not** for perceived size/complexity. Keep the existing "ambiguous requirement → record reasonable assumptions and proceed" behavior (already correct); ensure "irreducibly ambiguous requirement" as a *park* reason is scoped to genuine contradiction, not "big/hard". Do not remove the safe-park floor (no destructive git, no new agents, park at furthest safe state).
6. **Regenerate and verify.** Run `node scripts/build-plugins/build.mjs` to refresh `outputs/` and the policy index, then `verify.mjs`, `validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs`. Confirm no `outputs/` drift is left uncommitted.

## Quality Gate

How the outcome's quality is assured. This is skill/command **prose** (no shell scripts change → posix-lint N/A), so the gate is builds-green plus a targeted re-read audit.

**Acceptance criteria** — the checkable conditions that must hold:

- In `skills/drive/SKILL.md` Night Mode and Critical Rules, the words "too complex" and "any other reason" no longer appear as grounds to not-proceed/skip, and the text explicitly states size / complexity / "all-or-nothing" / "needs a human" are **not** skip reasons.
- The night-mode contract states every authorized ticket **must be attempted**, and a skip is permitted **only** after an attempt fails (checks red) or a **named** hard external blocker is hit.
- The drive morning-report spec constrains per-ticket outcomes to exactly {implemented, failed, blocked} and explicitly forbids a "declined / did not force" category; totals reconcile to the authorized batch size.
- `commands/drive.md` line 20 reflects attempt-first.
- `skills/trip-protocol/SKILL.md` Night Mode §4 + Team-lead directive apply the same attempt-first rule; the safe-park floor (no destructive git, no new agents) is unchanged.
- The existing safety floor is preserved everywhere: attempted-then-failed still stashes partial work, never force-commits red checks, never auto-iceboxes, never runs destructive git.

**Verification method** — the commands/probes that prove them:

- `node scripts/build-plugins/build.mjs` regenerates `outputs/` + `hooks/policy-index.md`; `git status` shows any regeneration staged, not stray/uncommitted.
- `node scripts/build-plugins/verify.mjs` green (generated skills self-contained, policy index in sync).
- `node scripts/build-plugins/validate-metadata.mjs` green (Codex manifests well-formed / version-aligned).
- `node scripts/test-workflow-scripts.mjs` green (branching + drive script smoke tests unaffected).
- Prose audit: re-read the two night-mode sections and confirm each acceptance-criteria bullet above by inspection.

**Gate** — what must pass before approval:

- All four `node` commands above are green, `outputs/` has no leftover diff after the build, and the prose audit confirms every acceptance criterion. Approve at `/drive` against this checklist.

## Considerations

- **Do not weaken the safety floor.** The change targets the *entry condition to skipping* only. The stash-on-failure, no-force-commit, no-auto-icebox, and no-destructive-git rules (`skills/drive/SKILL.md` lines 180-182, 195-206) must remain byte-for-byte intact — an attempt-first policy that also dropped these would be strictly worse.
- **"Blocked" needs a name, or it becomes the new loophole.** Require the report's `blocked` outcome to name the *specific* external blocker and what unblocks it; a vague "blocked" would re-open the exact "any other reason" escape this ticket closes (`skills/drive/SKILL.md` §5).
- **Trip ambiguity handling already differs and is correct.** Trip night mode records reasonable assumptions and proceeds rather than asking (`skills/trip-protocol/SKILL.md` §3, line 360). Preserve that; only the *park-on-cannot-complete* clause (§4) needs the size/complexity carve-out, so the two skills read consistently without overwriting trip's superior ambiguity behavior.
- **Trip is excluded from the `outputs/` build** (Agent Teams, Claude-only), so editing `trip-protocol/SKILL.md` produces no `outputs/` diff — but still run `build.mjs` to catch shared-closure drift and keep `hooks/policy-index.md` fresh (affects `.github/workflows/outputs-freshness.yml`).
- **This is a behavior/policy change to an LLM-driven flow**, not deterministic code, so there is no unit test that asserts "the AI attempted ticket N." The gate is therefore prose-precision + builds-green; the real-world confirmation is the next night run's report showing all authorized tickets attempted.
