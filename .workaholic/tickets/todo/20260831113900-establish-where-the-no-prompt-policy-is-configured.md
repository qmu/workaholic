---
created_at: 2026-08-31T11:39:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# Establish where the no-prompt policy is configured

## Overview

The ask names the routine's own configuration as the natural home and says it has no
field for it today. **Establish that rather than assume it**, on the precedent this
repository already set for the environment-variable question: measure what the routine
record actually carries, state the answer with its evidence and its limit, and if the
field does not exist, name the reachable alternative instead of leaving a gap.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — *Where a routine's environment
  variables live*, the precedent for establishing an **absence** from the product's own
  documentation rather than from a write-and-read-back.
- `plugins/workaholic/skills/workaholify/routines/*.md` — the templates and every field
  they declare (`allowed_tools`, `cron_expression`, `autofix_on_pr_create`, `mcp`,
  `notifications`, the environment pointer).
- `plugins/workaholic/skills/workaholify/scripts/` — the convergence flow, which is what
  would carry a new field if one exists.
- `.claude/settings.json` — the repository-scoped alternative, and the home the
  2026-08-29 ruling chose for a per-repository value.


## Implementation Steps

1. Enumerate what a routine record can actually declare, from the product's own
   documentation and from the fields convergence already reads. Do **not** infer a field
   from a name.
2. Answer the question in one place: is there a routine-side field that decides how a
   run answers a prompt? If yes, name it and wire it through convergence. If no, say so
   with the evidence, exactly as the environment-variable absence is stated.
3. When the answer is no, name the reachable alternatives and choose one with its
   reasoning — the cloud **environment** record (account-level, shared by every session
   and routine that selects it: wrong for a per-repository value, and that is precisely
   the argument already recorded), the repository's own `.claude/settings.json`
   permissions, or the routine's `allowed_tools` ceiling.
4. State the limit of whatever is chosen: which prompts it can prevent and which it
   cannot, so a later reader does not over-read it as total coverage.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The answer is stated once, with the evidence it rests on and the limit of what it
  covers.
- If a routine-side field exists it is read by convergence; if none exists, the absence
  is stated in the same voice the environment-variable absence is.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- No field is claimed to exist without evidence; an absence is named as an absence.


## Considerations

- The transport that would let this session write a routine record is not exposed to a
  clock-fired container, which is why the precedent established its answer from
  documentation rather than a write-and-read-back. Expect the same constraint here and
  say so rather than reporting the check as unperformed.
- An environment is account-level, so a value set there is set for every repository that
  account has — the recorded reason the per-repository home is the repository's own
  configuration. If the chosen home is the environment, that cost must be stated.

