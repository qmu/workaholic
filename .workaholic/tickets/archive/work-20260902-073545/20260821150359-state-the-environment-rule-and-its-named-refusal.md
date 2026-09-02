---
created_at: 2026-08-21T15:03:59+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-routine-create-body-documented-and-buildable
merge_policy:
verification_handoff: 
---

# State the environment rule and its named refusal

## Overview

PROPOSED. A create needs `job_config.ccr.environment_id`. §5 never says where one comes
from, and `render-routine.sh`'s header calls it "a question for the developer" — correct only
when the account has more than one, and nothing tells the session to enumerate first. The
account measured on 2026-08-20 had exactly one (`Default`), so the question had one answer and
was asked of nobody: the run simply stopped.

It stopped without vocabulary, too. `no_transport` is §5's only named refusal, and it is the
wrong one — the transport was present and was used. A session in that state either invents a
reason or falls back to the setup sheets, which is exactly the behaviour
§*`/workaholify` converges too* forbids.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — §5, which states the flow and its one refusal.
- `plugins/workaholic/commands/setup-dev-routines.md`, `setup-repo-routines.md`, `setup-user-routines.md`, `workaholify.md` — the four callers that report a refusal by name.
- `plugins/workaholic/skills/workaholify/reference/routines.md` — where the environment enumeration belongs beside the body record.


## Implementation Steps

1. Reproduce the stop against an account whose environment list is readable, and confirm which
   in-session surface enumerates environments with their ids before writing the rule around it.
   The ask names the harness's own `schedule` skill; treat that as a hypothesis to verify, not
   as the design.
2. State the environment rule in §5, in four branches: enumerate the account's environments;
   **exactly one** → use it without asking; **more than one** → ask (an interactive caller) or
   refuse by name (an unattended one); **none reachable** → refuse by name.
3. Add the second named refusal beside `no_transport` — `no_environment` unless the repository
   prefers another word — with the same standing: reported by name, and **never** a reason to
   render a setup sheet. A sheet stays the recovery path of `no_transport` alone.
4. Update all four command bodies to name the new refusal, since each states its own outcomes.
5. Pin the refusal's name in `test-workflow-scripts.mjs` the way `no_transport` is pinned.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- §5 states all four environment branches, and an unattended caller never picks between two.
- A second refusal is named beside `no_transport`, and it never renders a setup sheet.
- All four command bodies name the new refusal.

**Verification method** — the commands/tests/probes that prove them:

- Run `/workaholify` against an account with exactly one environment: it creates without asking.
- Simulate an unreadable environment list: the run reports the new refusal and renders no sheet.
- `node scripts/test-workflow-scripts.mjs` pins the refusal's name and passes.

**Gate** — what must pass before approval:

- The enumerating surface is verified in-session, not taken from the ask on trust.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` clean.


## Considerations

- "Ask when there is more than one" is only available to an interactive caller. `/workaholify`
  is interactive by construction (no routine prompt names it), but the rule must still say what
  an unattended caller does — refuse by name, never pick.
- Adding a refusal means four command bodies change. That is the cost of each command stating
  its own outcomes; the alternative (one list in the skill) is a larger change than this ticket.


## Final Report

Development completed as planned.

**Step 1 was performed and it refuted the ask's hypothesis.** The ask named the harness's own
`schedule` skill as the surface that enumerates environments; **no such skill is exposed to
this session class**, so it was not taken as the design. What is exposed — and what was read
live on 2026-09-02 from an unattended, routine-fired session — is
`mcp__Claude_Code_Remote__list_environments`, which returns each environment's
`environment_id`, `name`, `kind` and `state`. It answered with **exactly one**: `Default`,
`env_01XM4EPbtZEi2gDLYN69PvYZ`, selected by all eight live routines on the account. That
reproduces the 2026-08-20 reading independently and is the stop's own reproduction: the
question `render-routine.sh` called "a question for the developer" has one answer here, so it
was asked of nobody and the run simply stopped.

The rule is written in §5 as *Which environment a routine is created in*, in the four branches
the ticket specified, with the unattended caller never picking between two. `no_environment`
joins `no_transport` as the section's second named refusal, and the section heading and its one
cross-reference were rewritten so nothing still calls `no_transport` "its one refusal".

**The refusals do not share one standing, and that asymmetry is the point.** `no_transport`
falls back to a setup sheet because a sheet is exactly what a developer needs when the session
cannot reach the account at all. `no_environment` renders **nothing**: a session that *did*
reach the account is not helped by paste-by-hand instructions, and handing them over is the
renders-rather-than-converges behaviour the same section exists to forbid.

**Three command bodies, not four.** The ticket names four callers; `setup-user-routines.md` was
deleted with the `user` scope on 2026-08-22 (issue #557). The three that survive each state
their own outcomes and each now name the refusal.

The suite pins the refusal the way `no_transport` is pinned — the word in every command that
states its own outcomes, plus its no-sheet standing, plus the four branches living in the skill
so no command re-derives them.

**One accounting note, stated rather than glossed.** This ticket's edits were already in the
worktree when the previous ticket was archived, so they ride commit `5cf7273f` rather than this
ticket's own. The per-ticket record is the archived ticket and its Final Report; the commit
boundary is the part that is off by one, and the branch story and pull request carry both.

### Discovered Insights

- **Insight**: an account with one environment is the *hardest* case for a rule written as
  "ask the developer", not the easiest.
  **Context**: with two or more, the absence of a rule produces a visible question. With
  exactly one, it produces a silent stop — nothing to ask about, nothing to report, and the
  run ends looking like it had nothing to do. Every branch of the new rule is therefore
  written to produce *output*: the one-environment case names the environment it used, and
  each refusal names what was enumerated or why it could not be.
