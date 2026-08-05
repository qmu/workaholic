---
created_at: 2026-08-05T06:09:05+00:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
feedback: [20260805060855-simplify-the-drive-routine-s-system-instruction-to-match-propose-and-consent.md]
merge_policy:
claim: work-20260805-180653
---

# Slim the [Drive] routine template to a thin pointer

## Overview

PROPOSED. `plugins/workaholic/skills/workaholify/routines/drive.md` is 141 lines against `fb.md` (`[Propose]`) at 60 and `merged-pr.md` (`[Consent]`) at 54. The gap is not incidental: the two short templates state a policy point and then defer — `[Consent]` says the threading model "is stated once in the `workaholify` SKILL, *One thread per feedback item*; this template implements it and does not restate it" — while `[Drive]` carries nine numbered procedural sections that restate what `/drive` and the `drive` skill already own.

Restating a procedure in a routine prompt costs more than length. It creates a second source of truth that drifts, and the drift is already measurable: §1 tells the runner to read mission frontmatter itself because "the survey does NOT enforce this -- `plan-units.sh` offers EVERY approved mission regardless of owner." That is false — `plan-units.sh:301` resolves owners through `mission-owners.sh` and drops a colleague's mission as `owned_by_other` — and the same sentence still says "approved", a status word retired on 2026-07-31. A runner following the template does work the survey already did, against a rule the template describes wrongly.

Bring `[Drive]` to the shape of the other two: a short rationale, then a prompt that names the policy points and defers the procedure to the skill that owns it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/change-history.md` — the docs that describe a changed area are updated in the same commit

## Key Files

- `plugins/workaholic/skills/workaholify/routines/drive.md` — the template to slim; the whole subject of the ticket
- `plugins/workaholic/skills/workaholify/routines/fb.md` / `merged-pr.md` — the target shape, and the source of the "stated once in the SKILL … does not restate it" deferral phrasing
- `plugins/workaholic/skills/drive/SKILL.md` — receives the run-procedure detail that is genuinely `/drive`'s (§1 claim-one-at-a-time and its justification, §3 failure contract, §5 handoff, §6 terminal token)
- `plugins/workaholic/skills/workaholify/SKILL.md` — receives the Slack-notification policy (§0a alert dedup, and the post formats in §2/§4/§5); it already owns *Slack is the only surface* and *One thread per feedback item*
- `CLAUDE.md` — the `/workaholify` and `/drive` rows describe the routine set and must stay true

## Implementation Steps

1. Audit `drive.md` section by section and classify each block as **already owned elsewhere** (delete and defer), **routine-specific policy** (keep, compressed), or **procedure to relocate**. The expected classification, to be confirmed rather than assumed:
   - §0 preconditions — largely already `/drive`'s own §1 (`sync-main.sh` handles `not_on_main`/`dirty_workspace`; `check-deps` handles the plugin binding, and `/drive` already terminates `pending` on a superseded binding). Keep only the git-identity requirement, which is genuinely the routine's environment.
   - §0a failure-alert dedup — routine-specific Slack policy, not drive procedure. Relocate to the `workaholify` SKILL beside *Slack is the only surface*, and leave a one-line pointer.
   - §1 constraints — delete the ownership paragraph outright: it is stale and duplicates `plan-units.sh`. Relocate the claim-one-unit-at-a-time rule and its cost justification into the `drive` SKILL.
   - §2/§4/§5 Slack post formats — relocate the format blocks to the `workaholify` SKILL; the template keeps which events are postable, not how each line is shaped.
   - §3/§6 — already the `drive` skill's failure contract and terminal-token contract. Delete and defer.
   - Hard rules — already in `CLAUDE.md` and the always-loaded `rules/general.md`. Delete and defer.
2. Relocate each block marked *relocate* into its owning SKILL, preserving the reasoning verbatim where it records a measurement (the §0a two-day repeat-alert measurement and the §1 heartbeat-cost justification are decision records, not prose to compress away).
3. Rewrite `drive.md` in the shape of `fb.md`/`merged-pr.md`: frontmatter unchanged, a short rationale, then a `## Prompt` that states the policy points and defers.
4. Update `CLAUDE.md` where it describes the routine templates, in the same commit.
5. Refresh the live `[Drive]` routine through `/setup-routines`' verbatim-confirmed refresh — the template change does not reach the running routine on its own. This step is a human act and is out of scope for the drive that implements the ticket; name it in the PR body instead.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `drive.md` is comparable in length and shape to `fb.md` and `merged-pr.md` (target: within roughly their 54-60 line range, and no numbered multi-section procedure).
- No statement in `drive.md` contradicts the scripts: the stale ownership paragraph is gone, and no retired status word (`approved`, `draft`) remains.
- Every relocated block is present in its new home — nothing is deleted without a destination, and the two measurement records survive verbatim.
- The behaviour the routine produces is unchanged: the same five postable events, the same alert-dedup rule, the same handoff obligation, the same terminal token.

**Verification method** — the commands/tests/probes that prove them:

- `wc -l plugins/workaholic/skills/workaholify/routines/*.md` for the length comparison.
- `grep -n 'approved\|draft\|does NOT enforce' plugins/workaholic/skills/workaholify/routines/drive.md` returns nothing.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the `drive` SKILL is built into `outputs/workflows`, so relocating text into it requires a rebuild.
- `node scripts/test-workflow-scripts.mjs` — no script behaviour should change; this pins that.

**Gate** — what must pass before approval:

- `Outputs Freshness` CI is green (the `drive` SKILL edit must be rebuilt into `outputs/`).
- A reader can still answer, from the slimmed template plus the SKILLs it points at, every question the old template answered.

## Considerations

- **The ask says "move procedure into the `drive` skill", and taken literally that is wrong for part of it.** The alert-dedup rule and the Slack post formats are notification policy, and `/drive` invoked by a developer posts to Slack at no point — pushing them into the `drive` skill would put routine concerns in a skill that must not own them. The `workaholify` SKILL already owns the Slack surface rules, so it is the right destination. This is the one place the implementation should depart from the ask's literal wording, and the PR should say so.
- **Deletion and relocation must not be confused.** Several sections are safe to delete because `/drive` genuinely enforces them; several look redundant but carry measurements that exist nowhere else. Step 2 exists to keep the second group.
- **The template is not the running routine.** Editing `drive.md` changes what a future `/setup-routines` would create or diff against; the live routine keeps its current prompt until someone refreshes it. Any claim that this ticket "fixed the routine" is false until that refresh happens.
- **Length is a symptom, not the criterion.** A slimmed template that drops a rule the runner needs is a worse outcome than a long one. The acceptance criteria are written around behaviour preservation for that reason.
