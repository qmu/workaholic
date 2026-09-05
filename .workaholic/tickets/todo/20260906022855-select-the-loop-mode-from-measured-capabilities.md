---
created_at: 2026-09-06T02:28:55+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-each-tick-in-the-originating-codex-chat
merge_policy:
verification_handoff: 
---

# Select the loop mode from measured capabilities

## Overview

The loop picks how it runs from the **agent's name and surface**, not from what the running
session can do. `work/SKILL.md`'s clock table has three rows — Claude Code, the ChatGPT
desktop app, and "any agent with no Scheduled management surface" — and
`reference/other-agents.md` states as a measured fact that Codex has no
parent-ends-children-continue lifetime, so a **detached process** is the substitution. Both
readings were taken against `codex-cli 0.149.1` in September 2026 and were correct about that
surface; neither is a statement about a live session's own tool set.

Measured (issue #989): a session whose harness exposed an interruptible wait
(`clock.sleep`, which returns early on user input), `collaboration.spawn_agent` with
`list_agents`/`send_message`/`followup_task`/`interrupt_agent`, four concurrent slots, and the
ability to emit commentary without ending its turn, still read the table, selected
`scripts/codex-loop.sh`, and ended its turn. The reporting assistant then told the operator
that this chat would receive nothing.

This ticket is the diagnosis and the selection rule. It does not implement the coordinator —
that is the ticket after it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — how a running loop is kept serving and how it reports its own state

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — the clock table and the substitution table; the
  two surfaces that decide the mode today.
- `plugins/workaholic/skills/work/reference/other-agents.md` — *The four mechanisms, and what
  Codex has*, which carries the assumption to be removed, and *Running it from Codex CLI or the
  IDE*, which stays as one mode among several.
- `plugins/workaholic/commands/infinite-development.md` — the tick body every agent executes;
  it must be reachable from whichever mode is selected.

## Implementation Steps

1. **Reproduce and localize before changing anything.** Name, by file and line, every place the
   mode is decided today, and quote what each says. The report must distinguish (a) a row keyed
   on the **agent's identity** from (b) a row keyed on a **capability**, and state which of the
   two the CLI-supervisor fallback is reached by. Do not proceed on the assumption that
   `other-agents.md`'s table is the only decider until the walk says so.
2. Name the **capability questions** the selection needs answered, and no others: can this
   session wait and be woken early; can it emit intermediate output without ending its turn;
   can it start child agents it does not have to collect before returning; is a same-chat
   scheduler callable. Each question is about a tool this session holds, never about a product
   name or a version string.
3. Write the selection rule as an **ordered table over those answers**, with the interactive
   native-parent branch first when its terms hold, an available same-chat scheduler as its own
   capability-dependent branch, and the external CLI supervisor last. Record for each branch
   what it does **not** promise — the supervisor's row states plainly that its output is not
   claimed to reach the invoking conversation.
4. **Remove the assumption**, not the measurement: `other-agents.md` keeps its `codex-cli
   0.149.1` finding, dated and scoped to that surface, and loses every sentence that
   generalises it to *every non-Claude agent*.
5. Make the resolved mode **reported at startup** — which branch, and the capability answers it
   was chosen on — so a wrong selection is visible in the transcript rather than inferred from
   behaviour hours later.
6. When no branch's terms hold, **name the specific missing mechanism at startup and stop**:
   the requirement is reported unresolved rather than silently answered by a mode that delivers
   somewhere else. A capability that could not be read is named as unread and never as absent.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every place the mode is decided is named in the ticket's own diagnosis, with what it said.
- The selection rule is an ordered table over capability answers; no branch is selected by an
  agent name or a version string.
- No document in the tree states or implies that a non-Claude agent lacks native background
  agents; the `codex-cli 0.149.1` measurement survives with its date and its scope.
- A session with none of the required mechanisms reports the missing one by name at startup and
  selects no substitute.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A read of the three Key Files showing the selection rule and no surviving generalisation.

**Gate** — what must pass before approval:

- The diagnosis in step 1 is recorded before any edit to the selection rule, and the mode table
  answers to it.

## Considerations

- The capability answers are a property of the **session**, so the rule must be re-evaluated at
  each startup rather than cached anywhere.
- The reporting session's tool list (`clock.sleep`, `collaboration.*`, `clock.curr_time`) is an
  **implementation lead** and evidence that the branch is reachable — never a claim that every
  Codex installation exposes it, and never a substitute for the end-to-end run.
