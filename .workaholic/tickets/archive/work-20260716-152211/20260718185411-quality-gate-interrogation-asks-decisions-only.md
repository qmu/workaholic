---
created_at: 2026-07-18T18:54:11+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
---

# Quality Gate interrogation asks decisions, not derivable checklists

## Overview

Developer feedback (2026-07-18, during a `/ticket` run): the Step 4b Quality Gate interrogation presented a **multi-select menu of acceptance criteria the agent had itself derived** from discovery, asking the developer to pick which ones to check. The developer's response: "この受け入れ基準は複数選択で本当に確認させる必要がありますか？ こういった質問をさせるworkaholicの仕様を見直してください." — every offered item was derivable and belonged in the ticket without a vote.

Revise the `create-ticket` Step 4b spec (and the `/ticket` command's echo of it) so the interrogation distinguishes two kinds of content:

- **Developer-owned decisions** — verification depth/method (e.g. smoke-only vs live E2E), scope calls, risk tradeoffs, anything with a real cost/benefit choice or information only the developer has. These are still asked, still thoroughly — "grill, don't tick a box" stands.
- **Agent-derivable criteria** — acceptance items that follow from discovery, repo conventions, and standing rules (docs-updated-with-change, posix-lint, closed report sets, isolation properties). These are **drafted by the agent, written into the ticket's `## Quality Gate`, and shown for review as part of the ticket** — never posed as a select-which-apply question. If the developer wants to trim them, they say so at the ticket presentation or the `/drive` approval gate.

This narrows *what qualifies as a question*; it does not soften the gate. The interrogation remains mandatory and the `## Quality Gate` section remains machine-checked and never empty.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions (applies to all code work)
- `workaholic:development` / `policies/qa-engineering.md` — the developer owns QA: the interrogation exists to capture their judgment, which is precisely why it must ask judgment, not clerical confirmation
- `workaholic:design` / `policies/modeless-design.md` — remove ceremony that is not a real decision; keep the one confirmation that is
- `workaholic:implementation` / `policies/objective-documentation.md` — derived acceptance criteria stay objective and verifiable in the ticket regardless of who authored them

## Key Files

- `plugins/workaholic/skills/create-ticket/SKILL.md` — Step 4b ("Quality Gate Interrogation") is the spec to revise: keep "grill, don't tick a box" for decisions, add the decision-vs-derivable distinction and the "draft derivables into the ticket, don't poll them" rule
- `plugins/workaholic/commands/ticket.md` — Step 1 item 4 echoes the interrogation wording; update consistently
- `scripts/build-plugins/build.mjs` — `create-ticket` is a `DEFAULT_TARGETS` build target: regenerate `outputs/workflows/` after the SKILL.md change
- `outputs/workflows/skills/ticket/` — generated artifact that must be rebuilt, never hand-edited

## Related History

The interrogation step was added deliberately as a hard, non-skippable gate (with an explicit "do not soften" note born of earlier feedback that quality questions were being skipped under a minimal-friction reading). This ticket refines its *shape* — thorough on judgment, silent on clerical derivables — without reopening that decision.

## Implementation Steps

1. Rewrite `create-ticket` SKILL.md Step 4b: define the two content kinds; instruct the agent to (a) derive and draft all derivable acceptance criteria directly into `## Quality Gate`, (b) ask the developer only genuine decisions (verification method/depth, scope, tradeoffs, unknowns), (c) present the drafted criteria as part of the written ticket for review — with an explicit anti-pattern note showing the multi-select-of-derived-criteria shape as what NOT to do.
2. Keep (verbatim or strengthened) the existing "do not soften / minimal-friction escape hatch not wanted" paragraph, scoped to the decision questions, so this change cannot be read as permission to stop asking.
3. Update `commands/ticket.md` Step 1 item 4 to match the revised contract.
4. Rebuild `outputs/` with argument-less `node scripts/build-plugins/build.mjs`; run `verify.mjs`.
5. Docs check: confirm `CLAUDE.md` / `README.md` prose describing the interrogation (if any) still tells the truth.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `create-ticket` SKILL.md Step 4b contains the decision-vs-derivable distinction, the "draft derivables into the ticket, never poll them" rule, and the anti-pattern example; the "do not soften" clause remains.
- `commands/ticket.md` wording is consistent with the revised Step 4b.
- `outputs/workflows/` is regenerated and in lockstep (no freshness diff).
- A dry `/ticket` run on a sample request asks only decision questions (e.g. verification depth) and produces a ticket whose `## Quality Gate` already carries the derived criteria.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` green; `git diff outputs/` empty after the committed rebuild (Outputs Freshness CI equivalent).
- Manual read of the revised Step 4b + `ticket.md` against the acceptance wording; one sample `/ticket` dry run observed.

**Gate** — what must pass before approval:

- Build/verify green with `outputs/` in lockstep, and the developer confirms the revised interrogation wording captures the feedback (asks decisions only) at the `/drive` approval prompt.

## Considerations

- Do not weaken the machine-checks: `hooks/validate-ticket.sh` presence-check of `## Quality Gate` is untouched (`plugins/workaholic/hooks/validate-ticket.sh`)
- The revision must not be interpretable as "skip asking when obvious" — that escape hatch was explicitly rejected before; the change only reclassifies derivable checklist items out of question-space (`plugins/workaholic/skills/create-ticket/SKILL.md` Step 4b)
- `create-ticket` ships in the generated `outputs/workflows` bundle; forgetting the rebuild fails the Outputs Freshness CI (`scripts/build-plugins/build.mjs`)

## Final Report

Development completed as planned. The dry-run acceptance item was satisfied by construction rather than a separate workflow launch: the very interrogation that provoked this ticket was re-run in-session under the corrected contract (the verification-depth choice was asked as a decision; the four derivable criteria were written straight into the /monitor ticket's `## Quality Gate`), and the built `outputs/workflows/skills/create-ticket/SKILL.md` carries the revised wording.

### Discovered Insights

- **Insight**: The "do not soften" clause and the decision/derivable split are not in tension — the first governs whether to ask, the second what qualifies as a question. Keeping both in the same paragraph prevents the split from being read as the escape hatch the clause forbids.
  **Context**: Two prior feedback rounds pulled in opposite directions (ask more / ask less); the resolution is a type distinction, not a dial.
