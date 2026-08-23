---
created_at: 2026-08-21T15:07:10+09:00
status: done
author: a@qmu.jp
assignees: [tamura.yoshiya@gmail.com]
depends_on:
mission: name-the-session-type-that-cannot-merge
merge_policy:
verification_handoff: 
---

# Rule on the connector as a merge transport

## Overview

PROPOSED. The GitHub MCP `merge_pull_request` tool merged, with 200, the pull request REST
had just refused with 403. So the capability exists in the session; what does not exist is a
rule about using it. `rules/shell.md` says every workflow script reaches GitHub through
`gh-rest.sh` — written for the mirror case, `gh issue|pr|repo` being GraphQL-backed and 403-ing
in web sessions — and a **script cannot call an MCP tool at all**; only an agent can. So this
is not a code change hiding behind a decision: adopting the connector would move the merge out
of the script and into the calling agent, which is a different shape of seam.

This ticket produces the ruling and, if it is yes, the seam. Its outcome is a written decision
either way — including "no", with the reasoning recorded, which is a complete result.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/shell.md` — the "GitHub over REST only" rule this would qualify.
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` — the merge step, today entirely inside the script.
- `plugins/workaholic/skills/specificate/reference/workflow.md` step 10 — the caller that would carry an agent-level merge if one is adopted.
- `plugins/workaholic/skills/workaholify/routines/specificate.md` — a routine's `mcp` list decides whether the connector is even present.


## Implementation Steps

1. Establish what is actually true before designing: confirm from a routine-fired container
   (not an interactive one) whether a GitHub connector is present at all, and whether it merges
   there. The reporter measured an interactive web session; the class that matters for
   auto-merge is the tick.
2. Resolve Open Decision 1 and write the ruling into `rules/shell.md` as a qualification of the
   REST rule — naming what may use a connector, for what, and what stays REST-only.
3. If the ruling is yes: move the merge to the calling agent for that execution class only,
   leaving the script's REST path as the default, and make the script report that it declined
   to merge rather than that it failed.
4. If the ruling is no: record why, and let the previous ticket's named reason stand as the
   whole answer. Note it in the routine templates so the standing behaviour is not re-litigated.
5. Either way, state the outcome in the mission's changelog so the next reader finds the
   decision rather than the debate.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A written ruling exists on whether a connector may merge, with its reasoning.
- `rules/shell.md` reflects the ruling rather than being silently contradicted.
- If yes, the connector path is a second attempt behind REST and never a replacement.

**Verification method** — the commands/tests/probes that prove them:

- Probe a routine-fired container for the connector and record what was found.
- `node scripts/test-workflow-scripts.mjs` passes, including the REST-only tripwire.

**Gate** — what must pass before approval:

- Open Decision 1 is resolved explicitly in the driving session's Final Report.
- The measurement comes from the tick's execution class, not an interactive session.


## Considerations

- A connector is not guaranteed present in any given session, so a connector path can only ever
  be a second attempt behind REST, never a replacement.
- Moving a step out of a script and into an agent's prose is exactly what this repository's
  "no complex inline shell in command markdown" principle pushes against. That tension is the
  substance of the decision, not an objection to be argued away.

## Open Decisions

1. **May an agent-level connector become a sanctioned GitHub transport, and if so for what?**
   The reporter names this as the design question and does not answer it. `rules/shell.md`'s
   REST-only rule exists because a session's GraphQL surface is unreliable; this is the mirror
   case, a REST endpoint the same session refuses. Narrowing the rule to "REST for reads and
   writes a script performs; a connector for the one act a script cannot perform at all" is one
   answer; keeping the rule absolute and accepting that web-session proposals stay open is
   another, and it is not obviously worse — an open pull request with an honest reason is a
   recoverable state. Resolve it in the Final Report; do not adopt the connector merely because
   it worked once.


## Final Report

**Done. Open Decision 1 is resolved: yes, narrowly.**

### The ruling

A REST merge refused with `session_type_cannot_merge` — and **only** that refusal — may be
retried once through `mcp__github__merge_pull_request`. A second attempt behind REST, never a
replacement. Reads, writes and pull-request creation stay REST-only; `gh issue|pr|repo` stays
banned and the suite's tripwire is untouched. Written into `rules/shell.md` as a qualification
of the REST rule, into `specificate/reference/workflow.md` step 10 as the seam, and into
`CLAUDE.md`.

The rejected side is recorded rather than dismissed, because it was not obviously worse: keep
the rule absolute and let a web-session proposal stay open with an honest reason. What lost it
is that **the honest reason had nobody to reach.** A finished, green unit sat at an open pull
request and the only party who could act was a human who was never told. "Recoverable" describes
a state a person is looking at; nothing was looking at this one.

The cost is stated rather than absorbed: a script cannot call an MCP tool, so this moves one
step into the calling agent, against this repository's own no-inline-shell grain. It is bought
narrowly — one tool, one named precondition, one act — and the script reports the refusal rather
than pretending it merged. That tension was the substance of the decision, exactly as the
Considerations said, and it is answered by making the exception too small to grow.

### The measurement, and where it stops

Step 1's precondition was that the evidence come from **the tick's execution class**, not an
interactive one. It does, partly, and the gap is reported rather than papered over:

- **Routine-fired container, connector present and working — measured.** The `[Implement]` tick
  of 2026-08-23 07:33 UTC (`cse_01MTFyJuBmo1GpmnJozsYHZi`) successfully called
  `mcp__github__list_pull_requests` and `mcp__github__pull_request_read`. The connector is not a
  fiction in a tick.
- **A merge through it is measured only in an interactive session** — the reporter's own
  observation, 200 on the pull request REST had just refused. No tick has been observed merging.
- **And a connector is not universal**: this driving session had **no GitHub connector exposed
  at all**. That is not a footnote — it is the reason the shape had to be *retry behind REST*
  and not *use the connector*, and it is why the design reports **both** outcomes by name
  instead of assuming the second attempt is available.

So the seam is written to be correct when the tool is absent, present-and-refusing, and
present-and-merging, and the run says which happened. Adopting it because it worked once is
what the Open Decision warned against; what is adopted is a fallback that names its own
absence.

### Verification

`node scripts/test-workflow-scripts.mjs` — **3426 passed, 0 failed** (read from the log tally,
not the exit code), including the REST-only tripwire, which the ruling does not weaken: the
qualification is agent-level and no script gained a non-REST call. `build.mjs` + `verify.mjs`
clean.

### Not done, and why

Step 4's clause ("if the ruling is no, note it in the routine templates") does not apply. The
templates' `mcp` lists are untouched: `[Specificate]` and `[Implement]` already carry the
connector, and adding it to `[Propose]` — which writes nothing and merges nothing — would widen
a surface for no act.
