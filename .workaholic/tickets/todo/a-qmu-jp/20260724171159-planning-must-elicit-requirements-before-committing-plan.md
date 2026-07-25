---
created_at: 2026-07-24T17:11:59+09:00
author: a@qmu.jp
type: enhancement
layer: [Docs]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# Planning must elicit the developer's requirements before committing a plan — a plan built without the questions the developer invited cannot be rescued downstream

## Overview

A mission was planned and then executed autonomously over many hours, and the result was unusable — a user-facing feature that a person could not actually operate, and an automated output that was not presentable. When the developer saw the result, the diagnosis was blunt and correct: **the failure was not downstream (weak verification of the built thing); the failure was the plan itself.** Before any building, during planning, the developer had explicitly invited clarifying questions — asking, in effect, "is there anything else you need to ask so we can firm up the plan?" — and the planning step **did not ask them.** The plan was therefore committed on a shallow, wrong understanding of what the feature was even supposed to be, and autonomous execution then faithfully amplified that wrong plan into hours of garbage.

The key correction to earlier guidance: no amount of downstream verification (does the artifact exist, do tests pass, is the output present) can rescue a plan built without understanding the goal. **Plan quality gates everything.** A garbage plan produces garbage no matter how diligently it is executed and checked. So the leverage point is the planning phase, and specifically the elicitation of the developer's knowledge that the agent cannot derive on its own.

### The specific failure

At planning time the developer holds requirements the agent cannot infer from the code or the ticket title — what the feature must let a user actually do, what a good output looks like, what the real workflow is. The developer signalled they had this to give and invited the questions. The planner skipped them and wrote the plan anyway. That is the failure this ticket exists to prevent.

### The tension with the sibling guidance (must be reconciled)

A sibling change asked the agent to stop offloading **decidable execution choices** back to the developer during an unattended run (don't ask which fixable failure to retry, don't re-ask a decided question). That guidance is right for its scope — but it appears to have over-rotated into "don't ask," and contributed to skipping the **planning-time requirements questions**, which are a completely different thing. This ticket draws the line explicitly:

- **Execution-time decidable choices** — the agent decides and proceeds; do not offload. (sibling guidance)
- **Planning-time requirements elicitation** — the agent MUST ask; the developer holds knowledge the agent cannot derive, and skipping it poisons the whole run. Not asking is the failure — *especially* when the developer has invited the questions.

The two are not in conflict once separated: decide the *how*, but never assume the *what*.

## The rule the guidance must state

When creating a mission or an implementation ticket — before the plan is committed and before any autonomous build:

- **Actively interrogate the developer for requirements** the agent cannot derive: what a user must be able to do, what a correct/good output looks like (with an example), the real end-to-end workflow, and the acceptance in terms of that workflow. Ask concrete, specific questions — not "any feedback?" but the actual unknowns the plan depends on.
- **Treat any developer signal of "ask me what you need" as a hard gate.** If the developer has invited questions, failing to ask is a planning defect, not efficiency.
- **A user-facing feature may not be planned from a title.** The plan must encode what "usable" means for a real person, because the agent's own checks (artifact exists, tests pass) cannot see usability.
- **If the goal is not yet understood well enough to write verifiable, user-experience-level acceptance criteria, the plan is not ready** — keep eliciting, do not start building. Long autonomous execution on an un-elicited plan is the anti-pattern.

## Policies

The standard engineering policies — synced from the corporate site into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing and keep every change defensible against that policy's Goal, Responsibility, and Practices.

- `workaholic:planning` — planning exists precisely to establish real understanding of the goal before design and build; a plan committed without eliciting the developer's requirements is planning that skipped its own reason to exist
- `workaholic:development` / `policies/overnight-ai.md` — unattended autonomous execution multiplies whatever plan it is given; that makes the quality of the up-front plan, and the elicitation behind it, the highest-leverage control
- `workaholic:implementation` / `policies/objective-documentation.md` — acceptance criteria for user-facing work must be phrased at the level of real user experience, verifiably, so "usable" is a checkable target rather than an assumption

## Key Files

- `plugins/workaholic/skills/mission/SKILL.md` and `plugins/workaholic/skills/create-ticket/` — the planning entry points: require an explicit requirements-elicitation step with the developer before a plan/ticket is committed; for user-facing work, require an example of a good output and a walked end-to-end workflow, and forbid committing a plan whose acceptance cannot be phrased at the user-experience level.
- `plugins/workaholic/skills/monitor/SKILL.md` and `plugins/workaholic/commands/monitor.md` — the "front-load decisions / don't ask mid-run" language must explicitly carve out that planning-time requirements elicitation is mandatory and separate from execution-time decidable choices; an unattended run must not begin on a plan that was never elicited.
- The sibling guidance on not offloading decidable choices — cross-reference it so the distinction (decide the *how*, never assume the *what*) is stated in both places.

## Acceptance Criteria

- [ ] The planning guidance requires the agent to actively elicit the developer's requirements (what a user must do, an example of a good output, the real workflow) before a plan/ticket is committed — with concrete questions, not a generic "any feedback?".
- [ ] Guidance states plainly that a developer's invitation to ask questions is a hard gate: not asking is a planning defect.
- [ ] Guidance forbids committing a plan for a user-facing feature whose acceptance cannot be written at the user-experience level; if the goal is not understood well enough for that, elicitation continues and building does not start.
- [ ] The monitor/execution guidance carves out planning-time elicitation as mandatory and distinct from execution-time decidable choices, cross-referencing the sibling ticket so "don't ask" is not read to mean "don't elicit requirements."
- [ ] `commands/monitor.md` and `skills/monitor/SKILL.md` agree, and the mission/create-ticket skills agree with them.

## Considerations

- This narrows and corrects, it does not reverse, the sibling "don't offload decidable choices" change: decide the *how* autonomously, but never assume the *what* — elicit it.
- Keep the mandatory gates intact (the single verbatim confirmation before writing to another repo; authorization before irreversible outward actions).
- The concrete symptom that motivated this — hours of autonomous work producing an unusable user-facing result — is downstream of an un-elicited plan; the durable fix is at planning, not at post-hoc verification (though verifying real user-facing content, not artifact existence, remains its own necessary discipline).
