---
created_at: 2026-07-24T09:12:52+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
---

# Stop offloading decidable choices to the developer — exercise judgment; reserve prompts for genuine developer-only rulings

## Overview

During an unattended overnight parallel mission run (the `monitor` command fanning out one `drive` leaf per mission), the orchestrator repeatedly interrupted the operator with multiple-choice prompts asking which obvious next action to take — for example "retry this fixable failure, or finalize, or do the other item first" — when the operator had already stated the intent ("do it now") and the evidence made the next step unambiguous. The operator's rebuke: *why are you even asking me.* The prompts were pointless because the agent had everything it needed to decide.

This directly violates the run's own doctrine. `monitor` already says: front-load every foreseeable decision into a single pre-flight batch, and **after dispatch the run is unattended — nothing is asked**; and "blockers become decisions — never report why and stop," meaning the agent proceeds on its own judgment rather than kicking the choice back. The orchestrator ignored that and turned ordinary judgment calls into interactive prompts, one after another.

The distinction the guidance must make crisp:

- **A prompt is for a genuine developer-only ruling** — something the agent must not decide for the developer: authorization to do irreversible outward actions, security-boundary values (who is allowed access, which recipients), secrets/credentials the agent cannot and should not fabricate, or a true strategic fork with no evidence-based default. These are gathered **once, up front**, in the single pre-flight batch.
- **Everything else is the agent's to decide.** Which fixable failure to retry, whether to finalize now vs. push one more step, ordering of independent work, how to recover a stale environment — these follow from the evidence and the operator's stated intent. The agent makes the call, states what it decided and why in one line, and proceeds. Re-asking a question already answered by intent, or asking mid-run at all, is the failure mode.

A useful litmus test to include: *before* emitting a prompt, the agent must be able to say what genuinely-developer-only input it is missing that it cannot obtain or decide itself. If it cannot name that input, it must not prompt — it must decide and act.

This completes a trio with the two sibling issues already raised: leaves that give up too early (attempt-before-defer), a dispatcher that waits forever on silence (watchdog), and — here — a dispatcher that will not decide and offloads the call to the human. All three are the same root: the run failing to exercise the autonomous judgment it is designed for.

## Policies

The standard engineering policies — synced from the corporate site into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing and keep every change defensible against that policy's Goal, Responsibility, and Practices.

- `workaholic:development` / `policies/overnight-ai.md` — the run is meant to execute autonomously after front-loading; peppering the operator with decidable choices defeats the entire point of an unattended run
- `workaholic:implementation` / `policies/objective-documentation.md` — phrase the prompt-vs-decide boundary and the litmus test verifiably in the sections the dispatcher follows

## Key Files

- `plugins/workaholic/skills/monitor/SKILL.md` — §1 pre-flight / §3 loop: sharpen that developer prompts are **only** for genuine developer-only rulings gathered once up front; the agent must decide every evidence-resolvable choice itself, state the decision in one line, and proceed; add the litmus test (name the missing developer-only input, or do not prompt); reaffirm "after dispatch, nothing is asked."
- `plugins/workaholic/commands/monitor.md` — mirror the wording so the command's own interaction rules match the skill.
- `plugins/workaholic/skills/drive/SKILL.md` — reaffirm that a leaf never prompts and the main agent does not stand in for the leaf by prompting on decidable choices.

## Quality Gate

This ticket predates the mandatory `## Quality Gate` section; its original `## Acceptance Criteria` list is preserved verbatim below as the acceptance criteria, with the verification method and gate recorded at drive time (2026-07-24).

Decided: documentation-only verification — no runtime behaviour is mandated beyond how the agent chooses to prompt, so the hermetic suite plus the build/verify/metadata trio is the whole provable surface (developer may override at /drive).
Decided: the four developer-only kinds are written as an **exhaustive** list rather than examples — an open-ended list is what let "ordinary judgment call" drift into "prompt-worthy" in the first place, and `rules/interaction.md` already supplies the general test this specializes (developer may override at /drive).
Decided: not enforced by a hook — `rules/interaction.md` records that necessity is a judgement a `PreToolUse(AskUserQuestion)` hook cannot read (it sees only prompt text), so this stays prose by the same reasoning that keeps the Recommended-label test unhooked (developer may override at /drive).

**Acceptance criteria** — the checkable conditions that must hold:

- [x] The `monitor` guidance states that developer prompts are reserved for genuine developer-only rulings (authorization for irreversible outward actions, security-boundary values, unfabricatable secrets, true evidence-free forks), gathered once in the pre-flight batch.
- [x] The guidance requires the agent to **decide** every choice resolvable from evidence + stated intent, record the decision in one line, and proceed — never offloading it as a prompt.
- [x] A litmus test is included: if the agent cannot name the specific developer-only input it lacks, it must not prompt.
- [x] The guidance explicitly forbids re-asking a question already answered by the operator's stated intent, and forbids mid-run prompts outside the pre-flight batch.
- [x] `commands/monitor.md` and `skills/monitor/SKILL.md` agree on the reworded interaction rules.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the hermetic suite, including the existing monitor front-loading and interaction assertions that read these sections.
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` — `drive` is a built skill and must regenerate self-contained (`monitor` is Claude-only, not built).
- `node scripts/build-plugins/validate-metadata.mjs` and `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- Suite green, outputs/ rebuilt and fresh, metadata valid, layout conforming, and the genuinely-required gates left exactly as strict (the `/request` verbatim confirmation and irreversible-action authorization are untouched).

**Result (2026-07-24):** all five criteria met — see the run output recorded in the Final Report below.

## Considerations

- Guidance/documentation change only — no runtime behaviour is mandated beyond how the agent chooses to prompt.
- This narrows *when* to prompt; it must not weaken the genuinely-required gates (e.g. the single verbatim confirmation before writing into another repository, or authorization before an irreversible outward action) — those stay exactly as strict.
- Complements the attempt-before-defer and watchdog tickets; the three together define the autonomy contract for an overnight run.

## Final Report

Development completed as planned. The prompt-vs-decide boundary landed as a named block in `monitor/SKILL.md` §1 (the exhaustive four developer-only kinds, the "name the missing input" litmus test, the never-re-ask-intent and nothing-after-dispatch rules), a leaf-caller counterpart in `drive/SKILL.md`'s "when the gate is skipped" section, and a mirrored block in `commands/monitor.md`. Verified with `node scripts/test-workflow-scripts.mjs` (1301 passed / 0 failed), a clean `build.mjs` + `verify.mjs`, valid `validate-metadata.mjs`, and a conforming `layout-doctor.sh`.

### Discovered Insights

- **Insight**: This ticket specializes `rules/interaction.md` rather than restating it — the four developer-only kinds are the concrete enumeration of that rule's abstract "a true fork where the developer holds information you cannot derive", scoped to an overnight run.
  **Context**: Writing it as a specialization (with an explicit pointer back to the Recommended-label test) keeps a single source of truth for the interaction doctrine. The overnight case needed the concrete list because "genuine decision" was too abstract to stop the drift in practice — the run kept classifying ordinary judgment calls as genuine.
- **Insight**: The drive-side fix targets the *caller relaying upward*, which is a distinct hole from the leaf prompting.
  **Context**: The one-level-fan-out rule already forbids a leaf from calling AskUserQuestion, so a naive reading is "the boundary is covered." But it is satisfiable by the leaf deciding *or* by the dispatcher relaying the leaf's choice to the developer — and the second is exactly the observed failure. The rule had to name relaying-upward as offloading, not just repeat that leaves don't prompt.
- **Insight**: All three sibling tickets (attempt-before-defer, watchdog, decide-don't-ask) share one root and now cross-reference each other by section number.
  **Context**: They are three faces of "the run fails to exercise the autonomous judgment it is designed for" — giving up too early, waiting forever, and refusing to decide. Anchoring them to stable section labels (drive §3a/§3b/§3c, monitor §1/§2/§3) lets each cite the others without duplicating the rule, so the autonomy contract reads as one coherent thing.
