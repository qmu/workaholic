---
created_at: 2026-08-29T09:35:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: point-the-inbound-readers-at-the-channel-that-exists
merge_policy:
verification_handoff: 
---

# Say where a routine's environment lives

## Overview

MINTED mid-run by `/implement` while driving
`20260829062827-name-the-channel-the-routines-actually-post-to`. That ticket asked for
`WORKAHOLIC_INBOUND_SLACK_CHANNEL` to be set "in the two routine templates, in whatever form
the template's environment block takes". **Neither template has one, and this repository has
no rule saying where one would go** — so the run set the variable in the repository's own
`.claude/settings.json` `env` block instead, which reaches every session in this checkout
including a routine-fired one, and recorded the deviation.

The gap is worth its own ticket because two invariants collide and nothing states the
resolution:

- **P7** (`workaholic:workaholify`): routine prompts are byte-identical across
  repositories — no substitution, no repository name — so a channel name may not go in a
  prompt.
- **The frontmatter route is unverifiable from a routine container**: the routines API
  *silently drops unknown fields*, so only a write-and-read-back proves an environment shape
  took, and no `RemoteTrigger`-family tool is exposed to a clock-fired container. A template
  that reads as configured over a routine that is not is, in this repository's own words,
  the most expensive kind of broken.

`20260821150359-state-the-environment-rule-and-its-named-refusal` is a different question —
it is about `job_config.ccr.environment_id`, the runtime environment record, not about
environment variables — so this is not a duplicate of it.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — §5's convergence field list and P7.
- `plugins/workaholic/skills/workaholify/routines/*.md` — the templates.
- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh` — its header already says
  the caller builds the API body and this script deliberately emits no `job_config`.
- `.claude/settings.json` — where this repository's setting lives today.

## Implementation Steps

1. Establish, by writing and reading back through a `RemoteTrigger`-family tool in an
   interactive session, whether the routines API stores per-routine environment variables and
   under which key. Record the measured shape, or record the measured absence.
2. State the rule either way: if the API stores them, say how a template declares one and how
   convergence diffs it; if it does not, state that a repository's own configuration is the
   only home and say so where a reader would look for it.
3. Keep P7 intact in both branches — a repository name never reaches a prompt.
4. Reconcile the places that state the channel default with whichever rule is established.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The rule is stated in one place, with the measurement that established it.
- A repository whose channel differs from its own name has one documented way to say so.
- No routine prompt carries a repository name.

**Verification method** — the commands/tests/probes that prove them:

- The write-and-read-back itself, quoted.
- `node scripts/test-workflow-scripts.mjs` — the template drift pins still pass.

**Gate** — what must pass before approval:

- No speculative field is added to a template on an unverified shape.

## Considerations

The measurement in step 1 needs an interactive session holding a `RemoteTrigger`-family tool,
which no clock-fired container has. This ticket deliberately does **not** declare
`verification_handoff:` for it: that field has two writers, `/ticket` and `/specificate`, and a
driving run may never declare it for its own unit — that is what keeps `handoff` from becoming
a soft landing. Whoever picks this up and finds the measurement unreachable should say so and
re-scope, rather than the run that minted it pre-declaring the answer.
