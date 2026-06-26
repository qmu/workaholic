---
created_at: 2026-06-27T01:51:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Add an explicit, recorded "merge without production confirmation" override to the /ship gate

## Overview

`/ship` deploys and confirms in production **before** merging, and the merge is gated on a
passing confirmation. When **no confirmation method exists** (no `.workaholic/deployments/`
entry and no `CLAUDE.md` `## Verify` section), the Ship Flow applies the **§1-4 hard gate**:
it **HALTS pre-merge** and offers only *provide a verification path / inspect production /
author a deployments entry / abort*. In a repo or context where none of those is practical,
there is **no forward exit** — the developer cannot land their work through `/ship` at all.

This adds a fifth, deliberately-chosen option to that gate: **"Merge without production
confirmation (accepted-risk bypass)."** It is never the default and never automatic — the
developer must explicitly select it — and choosing it **records the bypass** into the branch
story / PR evidence (an accepted-risk, production-unverified note) before proceeding to the
merge. The gate stays the default safe behavior; the override is the audited escape hatch.

This keeps the design intent intact — *merge is evidence-gated, and a bypass is a visible,
recorded decision, not a silent skip* — while removing the dead-end. It mirrors the prior
relaxation of the over-aggressive ticket guard (made non-blocking in `76b49fb`).

**Scope guard:** the override covers only the **cannot-confirm** cases — (a) no confirmation
method exists, and (b) a method exists but cannot execute in this ship environment (e.g. a
`browser` confirmation in headless/CI, per the capability check). A confirmation that actually
**ran and FAILED stays a failed ship** (unmergeable via this override) — that is the exact
state the gate exists to protect against, and bypassing a *known-bad* deploy is out of scope.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code and keep every change defensible against
that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:operation` / `policies/observability.md` — **the central policy here.** The bypass must be *explainable from the outside*: recorded into the story/PR as an accepted-risk, production-unverified merge, and surfaced distinctly in the §5 step-9 summary. No silent merge-without-confirmation.
- `workaholic:operation` / `policies/ci-cd.md` — the gate and its override are part of the deploy→merge delivery path; keep the behavior reproducible and the merge step (`merge-pr.sh`) unchanged, with the override expressed as workflow logic, not a new bespoke merge path.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to the `record-evidence.sh` change (fail-fast, POSIX-clean, no silent fall-through).
- `workaholic:implementation` / `policies/directory-structure.md` — applies to all code work; the override logic stays inside the existing `ship` skill/scripts, no new top-level surface.

Repo-own rules (CLAUDE.md): **thin commands, comprehensive skills** — the AskUserQuestion that
presents the override is issued at the **command/main-agent level** (`commands/ship.md`), the
knowledge/flow lives in the skill; **Shell Script Principle** + **Skill Script Path Rule** for
any script edit; and **Outputs Freshness** — `ship` is a build target, so regenerate `outputs/`.

## Key Files

- `plugins/workaholic/skills/ship/SKILL.md` — the contract to amend in three places: the **Core design** paragraph (line ~14, document the recorded-bypass exception), the **§1-4 hard gate** option list (lines ~78-86, add the override option + its cannot-confirm-only scope), the **§5 Ship Flow** step 3 (line ~221, define the bypass branch: record evidence → proceed to merge) and step 9 Summarize (line ~238, surface the unconfirmed/bypassed merge distinctly).
- `plugins/workaholic/commands/ship.md` — line ~27 enumerates the §1-4 options presented via AskUserQuestion at the command level; add the override option here too (this is where the user actually picks it).
- `plugins/workaholic/skills/ship/scripts/record-evidence.sh` — the audit-trail mechanism. Currently documents `<status> = pass | fail` (line 9) and writes a `## Deployment Evidence` block verbatim. Extend the documented status set to include `bypassed` (the status string is already written as free text — minimal change), and confirm the block reads clearly for a bypass. Keep the secret-scan and the `no_story` guard.
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh` — unchanged; the override reaches the same `gh pr merge` path after recording the bypass.
- `scripts/test-workflow-scripts.mjs` — add a smoke case: `record-evidence.sh` with `status=bypassed` records the bypass block (and still refuses on a secret-shaped result).

## Related History

The `/ship` confirmation gate was built up deliberately, and an over-aggressive guard in the
same skill was previously given a relief valve — direct precedent for this escape hatch.

Past tickets that touched similar areas:

- [20260404014405-block-ship-when-todo-tickets-remain.md](.workaholic/tickets/archive/drive-20260403-230430/20260404014405-block-ship-when-todo-tickets-remain.md) — Added a blocking ship guard that was later judged too aggressive and **made non-blocking** (`76b49fb`); the same "deliberate relief for an over-strict gate" pattern this ticket applies.
- [20260311121500-add-deployment-confirmation-to-ship-commands.md](.workaholic/tickets/archive/drive-20260310-220224/20260311121500-add-deployment-confirmation-to-ship-commands.md) — Introduced the deployment-confirmation concept the gate enforces.

Relevant gate-building commits (not tickets): `80e721c` (require a verified confirmation method), `066714b` (reorder so deploy+confirm precede merge), `a23d69c` (pre-deploy capability check for headless contexts — the case where a declared method *can't run*, which the override (b) covers).

## Implementation Steps

1. **Add the override to the §1-4 gate option list** in `ship/SKILL.md` (lines ~78-86): a new bullet **"Merge without production confirmation (accepted-risk bypass)"** — proceed to merge despite no confirmable production proof. State inline that it is offered **only** for the cannot-confirm cases (no method, or a declared method that cannot execute in this environment), and **never** for a confirmation that ran and failed.
2. **Mirror the option in the command** (`commands/ship.md` line ~27), since the §1-4 AskUserQuestion is issued at the command/main-agent level. Keep wording identical to the skill.
3. **Define the bypass branch in Ship Flow §5 step 3** (`ship/SKILL.md` line ~221): when the developer selects the override, call `record-evidence.sh "<branch>" "<target-or-none>" "none (bypass)" "<short accepted-risk note: production state unverified, bypass accepted by developer>" "bypassed"` first, then continue to step 6 (Merge). The evidence write is **mandatory and precedes the merge** — if it cannot be written, see Considerations (do not lose the audit trail).
4. **Extend `record-evidence.sh`**: update the line-9 `<status>` doc to `pass | fail | bypassed`; verify the `## Deployment Evidence` block renders sensibly with `Status: bypassed` (optionally add a one-line "Confirmation: skipped — accepted-risk bypass" for readability). No change to the secret-scan or `no_story` behavior.
5. **Surface the bypass in the summary** (§5 step 9, line ~238) and the **Core design** paragraph (line ~14): a bypassed ship must be reported **distinctly** from a confirmed one — "merged WITHOUT production confirmation (accepted-risk bypass); evidence recorded" — so the audit signal is not flattened into a normal success.
6. **Keep the gate the default**: the override is an *added* AskUserQuestion option the user must deliberately pick; never pre-selected, never auto-taken on a halt. A confirmation that executed and **failed** remains a failed ship (unchanged).
7. **Regenerate + verify**: `node scripts/build-plugins/build.mjs` (ship is a DEFAULT_TARGET → propagates into `outputs/workflows/skills/ship/`), then `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs` (with the new `record-evidence.sh` bypass case) — all green before done.

## Considerations

- **The bypass must never be silent** — recording it is the whole point of honoring the evidence-gated-merge rule. If `record-evidence.sh` returns `recorded:false` because no story file exists yet (`no_story`, line 46-49), the bypass acknowledgment must still be captured somewhere durable — fold it into the PR body / step-9 summary so the accepted-risk decision is auditable even when the story is absent. (`plugins/workaholic/skills/ship/scripts/record-evidence.sh` lines 44-49)
- **Scope discipline**: a confirmation that ran and FAILED stays a hard stop. The override is for *inability to confirm*, not for *overriding a negative result* — conflating them would gut the gate. Make the option text and the §1-4 placement reflect that. (`plugins/workaholic/skills/ship/SKILL.md` line 14, lines 71-86)
- **Headless/CI relevance**: the capability check (`check-confirmation-capability.sh`, §2-3c) already detects a declared method that cannot run here (e.g. `browser` in headless). That path currently forces the post-deploy halt; it is the natural second trigger for the override (case (b)). Ensure step 3's wiring offers the override there too, not only on the no-method path. (`ship/SKILL.md` line 221)
- **Honors prior feedback**: the gate stays the default and the merge stays evidence-aware; this only adds a deliberate, recorded exit. Do not weaken the gate into a warning, and do not auto-bypass — that would contradict the reason the gate was introduced (`80e721c`/`066714b`).
- **Cross-agent / outputs**: `ship` ships into the committed `outputs/workflows/` bundle, so the SKILL.md and `record-evidence.sh` edits require a `build.mjs` regen committed in lockstep or the Outputs Freshness CI fails.
- Keep the override description **project-agnostic** — it is a general escape hatch, not tied to any particular consumer repo's deploy setup.
