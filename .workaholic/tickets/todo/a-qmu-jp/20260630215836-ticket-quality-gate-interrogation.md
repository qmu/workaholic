---
created_at: 2026-06-30T21:58:36+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Interrogate the developer for a quality gate at /ticket time and surface it at the /drive approval

## Overview

When a developer runs `/ticket`, Claude Code should **actively interrogate the developer about how the outcome's quality will be assured** — the verification method, the acceptance criteria, and the gate (what must pass before approval) — and record that as a structured, mandatory `## Quality Gate` section in the ticket. The payoff is downstream: today the `/drive` per-ticket approval prompt is built from the ticket's title + Overview only, so the developer approves against a vague description. With a recorded quality gate, the approval prompt can state the concrete acceptance criteria the implementation was supposed to meet, so the developer's approval is **concrete and trustworthy** — they can see the gate was thought through up front and confirm the work actually clears it.

This is net-new: the ticket template (Overview, Policies, Key Files, Related History, Implementation Steps, Patches, Considerations) has no acceptance-criteria / verification / definition-of-done section, and the `/ticket` workflow never asks about verification. Verification is captured today only *after* implementation, via the commit body's `Verify:` key (threaded through `drive/scripts/archive.sh` as the `<verify>` arg). This feature pushes that thinking **upstream**, into the ticket, where it can shape implementation and the approval gate.

The closest precedent — and the model to follow — is the mandatory `## Policies` section: a structured, recorded ticket section that `/drive` and `/trip` consume verbatim. `## Quality Gate` is its sibling.

**Interaction stance (explicit, per developer direction): grill the developer.** The QA elicitation is a deliberate, thorough interrogation — ask as many focused questions as it takes to pin down a *concrete, checkable* gate, and do not water it down. The `modeless-design` "don't over-interrogate / minimal-friction" concern **does not apply here and must not be used to soften this step** — for quality assurance, sufficient interrogation is the goal, not a cost. An implementer must not reintroduce a "skip if it seems obvious" escape hatch.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — changes stay within the existing `create-ticket`/`drive` skills; no new top-level area.
- `workaholic:implementation` / `policies/coding-standards.md` — this is prose/template work; where any shell/validator logic is touched, the repo's `rules/shell.md` (POSIX sh) is the operative concrete standard.
- `workaholic:implementation` / `policies/objective-documentation.md` — **load-bearing**: the recorded gate must be factual and verifiable ("returns 422 when the email field is missing"), never aspirational ("validates input") or evaluative. The interrogation must drive the developer toward checkable statements.
- `workaholic:implementation` / `policies/test.md` — "what must pass before approval" should lean on real unit tests / domain regression and boundary conditions, not green-count; the gate's substance is tests, not narrative.
- `workaholic:operation` / `policies/ci-cd.md` — where possible the gate maps to automated CI checks so the codebase answers for itself whether the work is acceptable, rather than a human-memory checklist.
- `workaholic:planning` / `policies/modeling-centric-design.md` — defining acceptance/success up front is requirements analysis: the gate is the success model placed as the foundation before implementation.

## Key Files

- `plugins/workaholic/skills/create-ticket/SKILL.md` — **primary edit site.** (a) Add a new mandatory **Quality Gate Interrogation** Workflow step (the *command* asks; the skill prose defines the questions and the "keep grilling until concrete" stop condition). (b) Add the `## Quality Gate` section to the **File Structure** template (between `## Implementation Steps` and `## Patches`), documented like the mandatory `## Policies` block (lines ~262–270). (c) Wire Step 5 "Write Ticket(s)" to populate it from the interrogation answers. (d) Extend the Output Contract so the eliciting questions ride the existing `needs_clarification` channel (the command relays them via `AskUserQuestion`).
- `plugins/workaholic/commands/ticket.md` — thin command; issues the new QA `AskUserQuestion`(s) at the main-agent level (skills/leaves cannot). The interrogation is a command-level interaction fed by leaf JSON, mirroring the moderation/ambiguity prompts.
- `plugins/workaholic/skills/drive/SKILL.md` — **consumer.** Workflow Step 1 reads the new `## Quality Gate`; Step 4 return JSON gains `quality_gate` / `acceptance_criteria`; the **Approval** section's question template (the literal `"<overview>\n\nApprove this implementation?"`) injects the acceptance criteria + "what must pass" so the approval is concrete; Step 2.3 maps the verified-against-gate result into the existing `<verify>` archive arg.
- `plugins/workaholic/skills/commit/SKILL.md` — the `Verify:` body key is the existing downstream sink; the pre-agreed gate becomes the post-implementation `Verify:` checklist (no new commit key required unless desired).
- `plugins/workaholic/hooks/validate-ticket.sh` — validates frontmatter + location only; it does **not** enforce body sections (even `## Policies` is prose-mandated). Hard-enforcing `## Quality Gate` would require adding a body-section grep here — a deliberate decision (see Considerations).
- `scripts/build-plugins/build.mjs`, `verify.mjs`, `validate-metadata.mjs` — `create-ticket` and `drive` ship in the generated `outputs/workflows` bundle, so editing their SKILL.md requires regenerating `outputs/` and the freshness gates.

## Related History

The mandatory-recorded-section pattern and the downstream approval/verify surfaces this feature threads through are all recent, established work.

- [20260623170417-ticket-policies-section.md](.workaholic/tickets/archive/work-20260621-192132/20260623170417-ticket-policies-section.md) - **The pattern to copy**: added the mandatory `## Policies` section that `/drive` and `/trip` consume verbatim. `## Quality Gate` is its sibling.
- [20260627210216-restructure-commit-body-for-report.md](.workaholic/tickets/archive/work-20260627-153246/20260627210216-restructure-commit-body-for-report.md) - Governs the commit body `Verify:` key (the `<verify>` arg), the existing place verification is recorded — but only after implementation.
- [20260617231848-ship-confirm-in-production-before-merge.md](.workaholic/tickets/archive/work-20260617-231848/20260617231848-ship-confirm-in-production-before-merge.md) - The project's canonical evidence-gated approval (merge gated last on executable confirmation); the same trust-through-verification principle, one stage earlier.
- [20260310234932-add-e2e-assurance-policy-to-planner.md](.workaholic/tickets/archive/drive-20260310-220224/20260310234932-add-e2e-assurance-policy-to-planner.md) - `/trip`'s E2E assurance gate (Constructor tests → Architect review → Planner E2E); a recorded quality gate would directly inform what these agents and the `/drive` approver verify.

## Implementation Steps

1. **Add the Quality Gate Interrogation step** to `create-ticket` SKILL.md, run by the `/ticket` command after discovery and before writing the ticket. The command asks the developer a focused, *thorough* set of questions (one or several `AskUserQuestion` rounds) covering: the verification method (which automated tests / type-check / CI checks / manual steps / production probe); the acceptance criteria as specific checkable conditions; the gate — exactly which checks/commands must be green before approval; the edge cases and failure modes to cover; and how Claude assures quality during implementation vs. how the developer confirms it at the approval gate. Keep grilling until the gate is concrete enough to drive the approval prompt — define that stop condition in prose. Seed proposals from discovery's existing signals (the source-mode `test_coverage`, present CI checks) so the questions are specific, but the developer's answers are authoritative.
2. **Add the `## Quality Gate` section** to the File Structure template (between `## Implementation Steps` and `## Patches`), documented as mandatory and never empty, mirroring the `## Policies` block. Structure it as: **Acceptance Criteria** (checkable bullets), **Verification Method** (the commands/tests/probes that prove them), and **Gate** (what must pass before approval). Require objective, verifiable wording per `objective-documentation`.
3. **Populate it in Step 5** from the interrogation answers, and thread the answers through the workflow (not the discovery JSONs — this section is developer-elicited, unlike every existing section). Surface the eliciting questions through the existing `needs_clarification` Output Contract channel so the command issues them.
4. **Make `/drive` consume the gate**: read `## Quality Gate` in Workflow Step 1; add `quality_gate`/`acceptance_criteria` to the Step 4 return JSON; inject the acceptance criteria + "what must pass" into the Approval question body so the developer approves against the pre-agreed gate; and map the verified-against-gate result into the existing `<verify>` archive arg → commit `Verify:` key. Keep night mode's auto-resolve behavior intact (it still skips the prompt, but the gate is now recorded).
5. **Keep architecture invariants**: all `AskUserQuestion` at the command/main-agent level (never in discovery leaves); one-level fan-out; thin command / comprehensive skill; `create-ticket` stays `metadata.internal: true`. Use one consistent term ("quality gate") across the template, SKILL prose, command, and `/drive` approval copy (`planning/terminology`).
6. **Decide enforcement** (see Considerations) — default to prose-mandated like `## Policies`; if hard enforcement is chosen, add a body-section grep to `validate-ticket.sh` plus a smoke test mirroring the existing validation tests.
7. **Regenerate + verify**: `node scripts/build-plugins/build.mjs`, then `verify.mjs`, `validate-metadata.mjs`, and `node scripts/test-workflow-scripts.mjs`. `create-ticket` and `drive` are bundled, so the `Outputs Freshness` CI fails on any uncommitted `outputs/` diff.

## Considerations

- **Do not soften the interrogation.** The developer explicitly wants to be grilled on QA; the `modeless-design` minimal-friction concern is deliberately overridden here and must not be cited to add a skip/“seems obvious” path. The gate is mandatory. (`plugins/workaholic/skills/create-ticket/SKILL.md`)
- The gate must be **objective and checkable**, not aspirational — the interrogation's job is to convert vague intent ("make it robust") into verifiable criteria ("`node scripts/test-workflow-scripts.mjs` green; returns 422 on missing email"). (`workaholic:implementation` / `objective-documentation`)
- This section is **developer-elicited**, unlike every existing section (which is discovery-fed); the new step must capture and thread the answer into the Step 5 write — it cannot be derived from discovery JSON. (`plugins/workaholic/skills/create-ticket/SKILL.md`)
- Enforcement choice: `validate-ticket.sh` checks frontmatter + location only, so even a "mandatory" section isn't hook-blocked today (`## Policies` is prose-mandated). Default to matching that precedent; only add a body-section grep if a missing gate should hard-fail the write. (`plugins/workaholic/hooks/validate-ticket.sh`)
- Cross-agent: `AskUserQuestion` is a Claude-Code enhancement; on other agents the same interrogation degrades to the native prompt / plain chat — the skill prose must not hard-depend on `AskUserQuestion`. (`plugins/workaholic/skills/create-ticket/SKILL.md`)
- Editing `create-ticket`/`drive` SKILL.md requires an `outputs/` rebuild; keep the source's `${CLAUDE_PLUGIN_ROOT}` / `metadata.internal` markers intact so the generated bundle stays self-contained. (`outputs/workflows/skills/`)
- `/trip`'s decomposition emits tickets too; the new mandatory section should be authored by the trip Constructor as well, so trip-emitted tickets also carry a quality gate. (`plugins/workaholic/skills/trip-protocol/SKILL.md`)
