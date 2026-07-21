---
paths:
  - '**/*'
---

# Interaction Rules

- **Ask only for genuine decisions; default to act-and-report.** Issue an `AskUserQuestion` (or any blocking prompt) only when **all three** hold: (1) a competent developer could genuinely go either way, (2) the answer materially changes the artifact, and (3) it is not already determined by safety, repo conventions, the stated goal, or an obvious sensible default. When any of those determine it, **decide, state the choice plainly, and let the developer correct it** — asking is the exception, not the default.
- **Do not under-ask either.** The test narrows *what* qualifies as a prompt; it does not remove the real forks. A genuine design decision, an irreversible or outward-facing action (deploy, send, publish, merge), or an unsignalled preference among genuinely diverging options still gets a prompt — and gets *pushed*, one decision at a time, not buried in a report you leave for later.
- **For naming and terminology**, prefer picking a strong default and offering the alternative over a blocking prompt; ask only when the options genuinely diverge and the developer has not signalled one.
- **Necessity is a judgement, not a check.** No hook can read whether a prompt was warranted — a `PreToolUse(AskUserQuestion)` hook sees only the prompt text, not whether a real decision existed. `hooks/guard-askuserquestion-label.sh` enforces prompt *structure* (the `[<project label>]` prefix); whether a prompt *should have fired* stays with this rule and your judgement, the same division of labour as the `/request` masking judgement (rules for syntax, judgement for meaning). Do not try to enforce this with a new hook.
