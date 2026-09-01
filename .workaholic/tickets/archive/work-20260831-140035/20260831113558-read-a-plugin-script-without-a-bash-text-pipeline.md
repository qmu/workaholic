---
created_at: 2026-08-31T11:35:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# Read a plugin script without a Bash text pipeline

## Overview

The measured prompt was raised on `sed -n '/^# Usage/,/^$/p' … | head -30` and
`grep -n … ask-question.sh` — two reads, classified as an edit of a sensitive file. The
classification is the harness's and this repository does not own it; what it **does** own
is whether the tick reaches for that shape at all. A read tool over the same file raises
no such prompt, so the repair here is to stop using a Bash text pipeline to read a plugin
script — in the rules, and in every documented example that models the habit.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/shell.md` — where the shell rules live, and the home for
  this one beside the REST-only transport rule.
- `plugins/workaholic/skills/moderate/SKILL.md` and its `reference/workflow.md` — the
  tick's own instructions, read by the agent that raised the prompt.
- `plugins/workaholic/skills/workaholify/routines/*.md` — the routine prompts, which are
  the ceiling on what a routine-fired session does.
- `scripts/test-workflow-scripts.mjs` — where a mechanical row would go.


## Implementation Steps

1. State the rule once in `rules/shell.md`: an unattended run reads a plugin script with
   a **read tool**, never through a Bash `sed`/`grep`/`head`/`cat`/`awk` pipeline. Give
   the measured reason — those pipelines can be classified as an edit of a sensitive
   file, and a routine has nobody to answer the resulting prompt.
2. Scope it honestly: this is about **reading a file to find something out**. A script
   that legitimately processes text inside a workflow script is untouched; the rule is
   about the agent's own inspection reads.
3. Sweep the documented examples that model the habit — a prompt or reference that shows
   `grep -n … $SRC/skills/...` teaches exactly the shape that hung the tick.
4. Consider a mechanical row in `scripts/test-workflow-scripts.mjs` failing on such an
   example inside command, routine and skill markdown, on the precedent of the row that
   fails on `gh issue|pr|repo`. Prose alone is what this repository already calls a rule
   whose enforcement is a human reading it.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `rules/shell.md` states the rule, its measured reason and its scope.
- No command, routine or skill markdown models an inspection read of a plugin script
  through a Bash text pipeline.
- If a mechanical row is added, it fails on such an example and passes on the tree.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- The rule does not forbid text processing inside workflow scripts, only the agent's own
  inspection reads; the distinction is written down.


## Considerations

- This does not fix the underlying classification, which is the harness's. It removes
  the repository's own exposure to it, which is the half this repository can hold. The
  broader policy — that an unattended run must never block on **any** prompt — is the
  operator's follow-up ask and belongs beside this, not inside it.
- A rule with no mechanical row is one a future prompt can quietly reintroduce; the row
  is proposed rather than assumed because its false-positive surface (documentation that
  legitimately quotes a pipeline) needs looking at first.


## Final Report

Development completed as planned, with one step deliberately not taken and its reasoning
recorded. `rules/shell.md` gains *Reading a plugin script: a read tool, never a Bash text
pipeline*, stating the rule, the measured reason (two reads classified as an edit of a sensitive
file, three ticks at `requires_action`, a routine with nobody to answer), and its scope: the
**agent's own inspection reads** only, with text processing inside a workflow script explicitly
untouched. The distinction is written as *why the text is being read*, and it is unambiguous
because a script cannot call a read tool at all.

**The sweep found nothing to change, which is reported rather than papered over.** Every
`sed -n` / `grep -n` / `| head -` / `cat …` occurrence under `plugins/workaholic/**/*.md` is either
this rule's own prose quoting the shape as its subject, or `story/reference/orchestration.md`'s
`cat "$RUN_DIR/…json" | bash …apply-deferred-concern-verdicts.sh`, which pipes a run-directory
payload **into** a script rather than inspecting a plugin script. No command, routine or skill
markdown models the habit.

**The mechanical row is refused, with its reason in the rule itself.** The `gh issue|pr|repo`
precedent keys on a command whose every use is wrong; `grep`, `sed` and `head` are correct in most
of their uses here and are quoted throughout the prose, so a row keyed on the command fires on
`posix-lint.sh`'s own description, and one keyed on "a pipeline targeting `plugins/`" cannot
separate an inspection read from a script's own processing without knowing why the text is being
read — the judgement the rule is made of. The ticket asked for the false-positive surface to be
looked at first; it was, and it decides against the row.

### Discovered Insights

- **Insight**: the underlying classification is the harness's and this change does not touch it —
  what it removes is the repository's own exposure.
  **Context**: a later reader finding a prompt still raised on some other read should not treat
  this rule as broken. The rule's claim is bounded to the shape the loop reaches for, and the
  wider policy lives in `rules/interaction.md`.
