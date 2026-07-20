---
created_at: 2026-07-20T16:28:07+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
---

# Add an interaction-necessity rule (act-and-report by default)

## Overview

The agent asks the developer to decide things that do not need a human decision. The principle that should govern this is scattered and narrow today: `create-ticket` §4b says "ask decisions, derive the rest", each command carries its own "User interaction" prose, and `guard-askuserquestion-label.sh` enforces only the *structure* of a prompt (the `[label]` prefix), never whether the prompt was warranted. Capture the cross-cutting principle once, as an always-loaded rule.

The change is **policy-only — no new hook.** Whether a question is *necessary* is a judgement (a hook sees the prompt text, not whether a real decision existed), and adding hooks has real costs the developer flagged: latency on hot events, contradictory advice between non-blocking hooks, and the risk of starving another flow's sanctioned path. So the existing `guard-askuserquestion-label.sh` stays the sole `AskUserQuestion` gate; this ticket adds guidance, not machinery. It follows the plugin's own division of labour: **hooks for syntax, policy for judgement.**

**The necessity test** (the substance of the rule): issue an `AskUserQuestion` **only** when all three hold — (1) a competent expert could genuinely go either way, (2) the answer materially changes the artifact, and (3) it is not already determined by safety, repo conventions, the stated goal, or an obvious sensible default. Otherwise **decide, state the choice plainly, and invite the developer to correct it** — the default is act-and-report, and asking is the exception.

## Policies

- `workaholic:planning` / `ai-native-future` — the human-in-the-loop checkpoint is placed *deliberately*, not sprinkled through the run. The necessity test is exactly the criterion for when a checkpoint is warranted, so autonomy is the default and a prompt is a considered exception.
- `workaholic:development` / `overnight-ai` — judgement is pre-answered so the AI does not stop for things it can settle itself; a prompt is reserved for the calls a human genuinely must make.
- `workaholic:design` / `no-dark-patterns`, `self-explanatory-ui` — act-and-report must surface the decision and the chosen default plainly, with an easy path to override; "decide silently" is not the goal, "decide visibly and reversibly" is.
- `workaholic:implementation` / `objective-documentation` — the rule states an applicable, checkable test (the three conditions), not a vague "ask less".

## Implementation Steps

1. **Add `plugins/workaholic/rules/interaction.md`** (frontmatter `paths: ['**/*']`, like `general.md`, so it is always loaded). State the necessity test and the act-and-report default concisely: asking is the exception; when the answer is determined by safety, conventions, the goal, or an obvious default, decide and let the developer veto rather than prompt; for naming/terminology, prefer picking a strong default and offering the alternative over a blocking prompt, unless options genuinely diverge and the developer has not signalled one. Keep it short — a behavioural rule, not an essay.
2. **Reconcile the existing narrower guidance.** In `create-ticket/SKILL.md` §4b ("ask decisions, derive the rest") and the command `User interaction` prose that issue prompts (`ticket`, `request`, `drive`, `monitor`, `report`, `ship`, `mission`), add a one-line cross-reference to the new rule so the two never contradict — do **not** restate the test in each place.
3. **Do not add or change any hook.** `hooks/hooks.json` and `guard-askuserquestion-label.sh` are untouched; confirm no new hook is introduced. The `[label]` structural gate remains the only machine check on `AskUserQuestion`.
4. **Docs in the same change.** Add `rules/interaction.md` to the `rules/` inventory in `CLAUDE.md`'s Project Structure, and add a one-line pointer where interaction is discussed — a pointer, not the full rule (keep `CLAUDE.md` thin). Verify truthfulness at change time.

## Quality Gate

**Method:** prose/rule review against the stated test; a check that no hook was added. Approve only when all hold:

- `plugins/workaholic/rules/interaction.md` exists, is scoped `paths: ['**/*']`, and states the **three-part necessity test** plus the **act-and-report default** (asking is the exception; decide-and-let-veto when determined by safety/conventions/goal/default). It is concise, not bloated.
- `create-ticket` §4b and the prompt-issuing commands **cross-reference** the rule rather than restating it; nothing contradicts it (the narrower "ask decisions, derive the rest" reads as an instance of the general rule).
- **No new hook**: `git diff` shows `hooks/hooks.json` and `hooks/guard-askuserquestion-label.sh` unchanged, and no new file under `hooks/`.
- `CLAUDE.md` lists the new rule in the `rules/` inventory and carries at most a one-line pointer (the full rule is not duplicated into `CLAUDE.md`).
- Rules are Claude-only and not built into `outputs/`; `node scripts/test-workflow-scripts.mjs` still passes (nothing script-level changed).

## Considerations

- **This ticket is itself an instance of the rule.** It was written without a clarifying prompt because the placement (a `rules/` file), the policy-only scope, and the test's wording were all derivable — exactly the act-and-report default the rule prescribes.
- **Necessity is not machine-checkable**, so resist any later urge to "enforce" it with a hook that inspects prompt text; that would re-create the matcher-for-a-judgement mistake `/request`'s masking warns against. The control is the rule plus the model's judgement.
- **Do not over-correct into never asking.** The rule narrows *what* qualifies as a prompt; it does not remove the genuine forks (a real design decision, an irreversible action, an unsignalled preference among diverging options). Under-asking on those is as wrong as over-asking on the rest — pair this with the existing "push genuine decisions, don't stall" guidance.
