---
created_at: 2026-08-29T09:35:00+00:00
status: done
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

## Final Report

Development completed as planned, with step 1's measurement reached by a route the ticket did not
anticipate and the answer reversing one of the ticket's own premises.

**Step 1 — the shape, established as an absence.** The ticket asked for a write-and-read-back
through a `RemoteTrigger`-family tool. That transport is not exposed to this session class: a
`ToolSearch` for it returns the session-only `CronCreate`/`CronList`/`CronDelete` family and no
`RemoteTrigger*` at all, which is the same refusal `skills/workaholify/SKILL.md` records for the
routine-fired class. Rather than stop there, the question was put to the product's own
documentation, which answers it decisively and in the direction the ticket allowed for ("or record
the measured absence"):

- `code.claude.com/docs/en/routines`, *Select an environment* — the creation form sets up "the
  routine's prompt, repositories, environment, connectors, and triggers"; and *Environments and
  network access* — "Each routine uses a cloud environment that controls network access,
  environment variables, and setup scripts."
- `code.claude.com/docs/en/cloud-environments`, *Set environment variables* — `.env`-format
  `KEY=value` lines **on the environment**; "Each session copies the environment's values once, at
  startup".
- `code.claude.com/docs/en/claude-code-on-the-web` — the same environments serve "the web, the
  terminal, Claude Tag, routines, and the mobile and Desktop apps".

So **a routine stores no environment variables of its own**; it selects an environment and the
variables live on that record. There is no per-routine key to read back, which is why an absence
was the only thing a read-back could ever have established here.

**The ticket's premise about the sibling ticket is wrong, and that is the finding.** It states
that `20260821150359-state-the-environment-rule-and-its-named-refusal` "is a different question —
it is about `job_config.ccr.environment_id`, the runtime environment record, not about environment
variables". They are the **same** question: that pointer is precisely where the variables live,
one indirection away. Recorded here rather than silently, because the two tickets were scoped
apart on this belief.

**Steps 2-4.** The rule is stated in one place — `skills/workaholify/SKILL.md`, *Where a routine's
environment variables live* — with the evidence above and an explicit limit (this establishes the
documented model, not the wire shape of a live record; the standing "the API silently drops unknown
fields, so only a read-back establishes a field" rule is unchanged, and no template may declare one
until such a read-back exists). `render-routine.sh`'s header gained a one-line pointer, not a
restatement. `CLAUDE.md`'s claim that establishing the shape was "a separate queued ticket" is
reconciled to the established rule. P7 is intact and reinforced: the decisive argument for the
repository's own configuration is that an environment is **account-level** and shared by every
routine that selects it, so a per-repository value set there would be set for every repository at
once — no prompt needs a repository name, and no template gains a field.

### Discovered Insights

- **Insight**: The sanctioned home for a per-repository value — a committed `.claude/settings.json`
  `env` block — contaminates this repository's own hermetic test suite.
  **Context**: Every test in `scripts/test-workflow-scripts.mjs` spreads `process.env` into its
  throwaway repositories, so `WORKAHOLIC_INBOUND_SLACK_CHANNEL=dev-workaholic` overrode the very
  default four assertions in `step-unanswered-asks.sh` exist to pin — they read `dev-workaholic`
  where the fixture's own remote says `source-repo`. This was pre-existing (introduced with the
  sibling ticket that set the variable) and is not peculiar to this repository: it reaches any
  repository that uses the home this rule endorses. Fixed inside this ticket's scope because the
  Quality Gate's verification method is that suite passing: ambient `WORKAHOLIC_*` variables are
  stripped once at suite startup, so every test controls its own, which is what the override
  assertions beside the failures already did. 5024 passed / 4 failed → 5028 passed / 0 failed.

- **Insight**: "The transport is unreachable" and "the field does not exist" are different
  absences, and only the second answers this ticket.
  **Context**: Stopping at the first would have recorded a blocked ticket whose real answer was
  freely available; asserting the second *from* the first would have been the pre-declaration the
  ticket's own Considerations warned against. The documentation route establishes the second
  directly, which is why the rule could be stated without either error.
