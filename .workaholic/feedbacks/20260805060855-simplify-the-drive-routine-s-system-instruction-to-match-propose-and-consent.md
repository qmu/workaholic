---
type: Feedback
title: Simplify the [Drive] routine's system instruction to match [Propose] and [Consent]
kind: instruction
source: slack
created_at: 2026-08-05T06:08:55+00:00
author: a@qmu.jp
supersedes: 
---

# Simplify the [Drive] routine's system instruction to match [Propose] and [Consent]

The `[Drive]` routine template's system instruction is far longer than the other two routine templates', and it inlines procedural detail that belongs in the `drive` skill. Measured in this repository: `plugins/workaholic/skills/workaholify/routines/drive.md` is 141 lines against `fb.md` (`[Propose]`) at 60 and `merged-pr.md` (`[Consent]`) at 54. The other two keep their prompts thin by deferring to their skills for the actual procedure; `[Drive]`'s prompt restates it instead — preconditions, the failure-alert dedup rule, the claim-one-unit-at-a-time constraint with its justification, the handoff steps, and a closing hard-rules list that largely repeats CLAUDE.md and the always-loaded rules. The ask is to audit `[Drive]` against `[Propose]` and `[Consent]` and rewrite its system instruction to match their length and shape, moving whatever procedure it inlines into the `drive` skill so the routine instruction stays a thin pointer rather than a restatement of the skill's content.
