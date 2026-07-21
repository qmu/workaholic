---
created_at: 2026-07-21T02:57:22+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission: reorganize-missions-under-strategies
---

# Raise the ask bar to decide-and-record

## Overview

Developer ruling (2026-07-21, during this mission's creation — after answering four interrogation questions whose first options all carried "(Recommended)" labels, choosing all four recommendations): **a question you could answer with a recommended option must not be asked.** If any option can honestly carry the "(Recommended)" label, that *is* the answer — decide it, record the decision and its reason in the artifact being produced, and let the developer veto later. Ask **only** when no option can honestly be recommended: a true fork where the developer holds information or preference the agent cannot derive. The economics behind it are part of the doctrine and belong in the rule's "why": a coding agent's mistake is cheaply amendable by a later agent — code is getting cheaper — while every question spends the scarce resource, developer attention; fewer questions and confirmations are the key to orchestration efficiency.

This raises the existing interaction-necessity bar (ask only genuine decisions → *a decision with a recommendable default is not genuine*) across the plugin's interrogation surfaces: `/ticket`'s Quality-Gate interrogation, `/mission`'s Creation Interrogation and replan, `/monitor`'s pre-flight batch, and the always-loaded interaction rule.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conformance (applies to all code work)
- `workaholic:development` / `policies/overnight-ai.md` — pre-answering judgment calls is the whole overnight model; a recommendable question is a judgment call the agent already answered and asked anyway
- `workaholic:implementation` / `policies/objective-documentation.md` — decisions taken under this rule are *recorded* (what was decided, why, where the veto lands), so the saved question never becomes a silent assumption
- `workaholic:planning` / `policies/modeling-centric-design.md` — the ask/decide split is stated as a testable rule (the Recommended-label test), not a mood

## Key Files

- `plugins/workaholic/rules/interaction.md` — the always-loaded rule (note: added on `work-20260719-075112`, not yet on this checkout's base — if absent at drive time, reconcile with/await that branch's merge per the mission Scope note, then amend it; do not create a divergent copy). Add the **Recommended-label test**: before any `AskUserQuestion`, if you would mark an option "(Recommended)", do not ask — decide, record, invite veto. Include the recovery rationale (mistakes are cheaply amendable; questions are the expensive thing).
- `plugins/workaholic/skills/create-ticket/SKILL.md` — §4b Quality Gate Interrogation: the "developer-owned decisions" category is narrowed by the test — a verification-depth/scope/risk question with an honestly recommendable answer is decided and written into the ticket's `## Quality Gate` with a one-line `Decided:` record; only unrecommendable forks are asked. The "do not soften" warning stays — the bar on *derivable* thoroughness is untouched; what changes is that *recommendable* ⊂ derivable.
- `plugins/workaholic/skills/mission/SKILL.md` — Creation Interrogation ("Grill; do not tick a box") and Replan: same test; "as many rounds as it takes" now means as many *unrecommendable* rounds as it takes; recorded decisions land in the mission changelog or the tickets' gates.
- `plugins/workaholic/skills/monitor/SKILL.md` + `commands/monitor.md` — §1 front-loaded batch: each foreseeable escalation passes the test first; recommendable ones are auto-resolved and listed in the pre-flight summary as decisions taken, only unrecommendable ones become the blocking batch.
- `plugins/workaholic/commands/ticket.md`, `commands/mission.md` — the interrogation step wording aligned (thin echoes; knowledge stays in the skills).
- `outputs/workflows` — create-ticket and mission are built targets: run the argument-less build.
- `CLAUDE.md` (AskUserQuestion enforcement section: note the necessity rule's sharpened form stays judgment-not-hook), `README.md` if it describes the interrogations.

## Implementation Steps

1. Amend `rules/interaction.md` with the Recommended-label test and the recovery rationale (reconciling with the `work-20260719-075112` version of the file).
2. Rework create-ticket §4b: the test applied to the decision category, the `Decided:` record format in `## Quality Gate`, an example of a converted question.
3. Rework the mission Creation Interrogation/Replan wording identically; name the record seams (changelog line / ticket gate).
4. Rework monitor §1: auto-resolved-and-listed vs asked; the pre-flight summary shape gains a "decisions taken" list.
5. Align the two command files' echoes; full build; docs.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo. This ticket is prose/doctrine — its gate is consistency, not new scripts.

**Acceptance criteria**

- The Recommended-label test appears once in full (`rules/interaction.md`) and is referenced — not restated — by create-ticket §4b, mission Creation Interrogation/Replan, and monitor §1.
- Every surface that drops a question gains a named **record seam** (where the taken decision is written) — no decide-without-record path exists.
- The "do not soften the interrogation" guarantees remain: derivable-criteria thoroughness and the mandatory-run status of §4b/Creation Interrogation are unchanged.
- Built outputs regenerated; no contradiction left between the four surfaces' wording.

**Verification method**

- `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green; `node scripts/test-workflow-scripts.mjs` still green.
- A cross-reading pass over the four surfaces captured in the drive log (each reference resolves, no duplicated rule text).

**Gate**

- Build/verify/suite green and the cross-reading evidence recorded; wording approved against this ticket's Overview as the canonical statement.

## Considerations

- This remains judgment, not a hook — a `PreToolUse(AskUserQuestion)` matcher cannot read whether an option was recommendable, the same reason the necessity rule was never hooked (`CLAUDE.md` AskUserQuestion section).
- The genuinely unrecommendable question is still pushed promptly and one-at-a-time — this ticket lowers question *count*, never decision *latency* (`rules/interaction.md`).
- Guard the failure mode where "decide-and-record" erodes into silent assumptions: the record seam is mandatory, and a veto that arrives later is cheap by the same economics that justify deciding (`## Quality Gate` `Decided:` lines).
- This session itself is the first live application: four asked questions would have been zero under the test; the mission changelog records the rulings they produced.

## Final Report

Development completed as planned. The Recommended-label test now lives once in full in `plugins/workaholic/rules/interaction.md` (two new bullets: the test itself plus its economics/record rationale, and a clause in the "necessity is a judgement" bullet noting recommendability is likewise unhookable). Every other surface references it by name (`rules/interaction.md`) and applies it without restating the canonical statement, each naming a concrete record seam:

- **create-ticket §4b** — the developer-owned-decision category is narrowed by the test; a recommendable verification-depth/scope/risk answer is decided and written into `## Quality Gate` as a `Decided: <choice> — <why> (developer may override at /drive).` line, with a worked example. The "do not soften" warning was strengthened to say the test narrows prompt *count*, never the gate's thoroughness.
- **mission Creation Interrogation ("Grill; do not tick a box") and Replan** — same test; "as many rounds as it takes" now means as many *unrecommendable* rounds; recorded decisions land in the mission `## Changelog` or the ticket's `## Quality Gate`.
- **monitor §1** — each foreseeable escalation (and each design ruling) passes the test first; recommendable ones are decided-and-recorded in a new pre-flight-summary **"decisions taken"** block (item 5), only unrecommendable forks become the blocking batch.
- **commands/ticket.md, commands/mission.md** — thin echoes aligned; the record format/example stays in the skill.
- **CLAUDE.md** — the AskUserQuestion enforcement section notes the sharpened form stays judgment-not-hook.

Built targets (create-ticket, mission) regenerated via the argument-less build; `outputs/workflows` and the OKF bundle are in sync (idempotent rebuild produces no further diff).

### Discovered Insights

- **Insight**: `scripts/test-workflow-scripts.mjs:7131` pins the literal doctrine string `Only a genuine **design ruling**` in monitor's reevaluate paragraph. Refining that paragraph for the Recommended-label test must **preserve that exact phrase** (an unrecommendable design ruling still "is collected into the up-front batch"), not paraphrase it away.
  **Context**: The monitor skill has a dense band of string-pinned assertions (tests 7128–7143) that treat specific sentences as the contract; edits there should be checked against those regexes, and monitor is *not* a built target, so its edits need no `outputs/` rebuild while create-ticket/mission do.
