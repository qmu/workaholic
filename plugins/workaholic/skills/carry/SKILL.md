---
name: carry
description: Hand off in-progress work to a fresh Claude Code session by writing durable resume state (a resumption ticket, and/or a trip checkpoint) that a later /drive continues, instead of relying on in-session compaction.
allowed-tools: Bash, Read, Write, Glob, Grep
user-invocable: false
skills:
  - workaholic:gather
  - workaholic:planning
  - workaholic:design
  - workaholic:implementation
  - workaholic:operation
metadata:
  internal: true
---

# Carry

Checkpoint the current session's in-progress work to durable disk state so a **fresh** Claude Code session can continue it via `/drive`, instead of letting the context window fill and compaction degrade fidelity. `/carry` writes where the executors already look: a **resumption ticket** under `.workaholic/tickets/todo/<user>/`, and — when a trip is in progress — a **checkpoint** in the trip's `plan.md` / `event-log.md`. It is **capture-only**: it never implements, commits, or archives.

## 1. Agent Compatibility

`/carry` is user-invoked by design. Discovery confirmed there is **no** hook, setting, statusline, or API by which a command can read the remaining token/context budget (a `PreCompact` hook is a plain shell script with no model access, so it cannot summarize the conversation), so `/carry` cannot auto-fire on window exhaustion — the developer runs it when they notice the window is short. There is **no `AskUserQuestion`** in this workflow; it runs to completion and reports what it wrote. The mechanics are portable, but the feature targets Claude Code sessions specifically, so like `/trip` it stays Claude-only (the script-bearing skill carries `metadata.internal: true` and is not part of the cross-agent build).

## 2. Run Workflow

The `/carry` command (main agent) runs this workflow directly. It reads the live session state, runs the bundled script, and writes the handoff files itself — no subagents, no prompts.

### 2-1. Policy Lens (read first)

The carried state is **documentation for a future agent**, so hold it to `workaholic:implementation` / `objective-documentation`: concrete and verifiable (exact ticket path, the specific next step, files touched, the current position), never aspirational prose. Shape it as a recovery checkpoint worked backward from the context-exhaustion scenario (`workaholic:implementation` / `operational-planning`) — keep it simple: write the remaining state, and make it resumable. The resume path must need no manual (`workaholic:design` / `self-explanatory-ui`): the resumption ticket must, on its own, tell a fresh `/drive` what the priority is, where work stopped, and the findings and decisions it should not rediscover.

### 2-2. Phase 0: Identify the In-Progress Work

From the live conversation, determine what is in flight:

- **Which ticket** (if any) is being driven right now — its path under `.workaholic/tickets/todo/<user>/`, and which of its `## Implementation Steps` are already done vs. remaining.
- **Whether a trip is in progress** — the script reports this; a trip also has a `plan.md` position (phase/step) and remaining decomposed tickets.
- **Any uncommitted working-tree changes** and what they represent (run `git status --porcelain` through your normal reading; do not discard anything).

Pick a short kebab-case `<slug>` for the resumption ticket filename (e.g. `resume-explain-pdf-export`).

### 2-3. Phase 1: Summarize Remaining Work + Position

Distil, factually (catch-style — name files, paths, step numbers, commit hashes):

- **What is already done** — the completed steps / landed commits, as *context* (this becomes Overview background, NOT steps to re-run).
- **What remains** — the concrete outstanding actions, in order. These become the resumption ticket's `## Implementation Steps`. **Only remaining work** goes here: `/drive` implements every listed step with no notion of "already done", so any completed step left in the list is re-run.
- **Where we are** — the exact current position (mid-step N of ticket X; trip at `coding/iteration-2`; etc.).
- **What was learned** — the insights and dead-ends the session surfaced: what was ruled out and why, what behaved unexpectedly. These become `## Findings` — the reasoning a fresh `/drive` would otherwise have to rediscover, so it does not re-explore a path this session already closed.
- **What was decided** — the choices made this session and their rationale (approach A over B, and the constraint that drove it). These become `## Decisions`, so the resuming agent does not relitigate a settled choice.

### 2-4. Phase 2: Write the Handoff

Run the checkpoint script to get the resumption-ticket path, dynamic frontmatter metadata, and trip presence:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/carry/scripts/carry-checkpoint.sh "<slug>"
```

It returns `{ created_at, author, filename_timestamp, user_slug, slug, ticket_path, trips_present, trips }`.

**Drive / general case — write the resumption ticket** at the returned `ticket_path` using the **Resumption Ticket Template** (section 3). It must satisfy `validate-ticket.sh` (correct `todo/<user>/` location, `YYYYMMDDHHmmss-*.md` filename, full frontmatter). Carry forward the interrupted ticket's `## Policies` and `## Quality Gate` (or derive them from the `layer` if none), list **only remaining** steps, and add a `**Carry Origin:**` line under `## Overview`. If the remaining work belongs to an existing todo ticket that is still queued, say so in the Carry Origin line and note that this resumption ticket **supersedes** that ticket's remaining work — then tell the developer (Phase 3) so they can drop the superseded original (`/carry` never moves it — that is a developer decision). Set `depends_on` only when another queued ticket must genuinely land first.

**Trip case (`trips_present: true`)** — also checkpoint the trip so a resumed trip/`/drive` knows the position:

1. Append a Plan Amendment to `.workaholic/trips/<name>/plan.md` recording the remaining work and current position (mirroring a "Night Park" amendment), and update the frontmatter `step` if it moved.
2. Log the checkpoint event:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/trip-protocol/scripts/log-event.sh "<trip-path>" carry carry-checkpoint plan.md "<one-line remaining-work summary>"
   ```

Coding-phase remainders already live as tickets under `todo/<user>/`, so mid-implementation trip carry converges on the same resumption-ticket channel as a drive carry.

### 2-5. Phase 3: Report

Print what was written — the resumption ticket path (and the trip checkpoint, if any) — and the one instruction the developer needs: **start a fresh Claude Code session and run `/drive`**; it will find the resumption ticket, order it, and continue the remaining work. If the resumption ticket supersedes a still-queued original, name that original so the developer can remove it.

## 3. Resumption Ticket Template

```markdown
---
created_at: <created_at from carry-checkpoint.sh>
author: <author from carry-checkpoint.sh>
type: <carried from the origin ticket, or inferred>
layer: [<carried from the origin ticket, or inferred>]
effort:
commit_hash:
category:
depends_on:
---

# Resume: <what remains, in a few words>

## Overview

**Carry Origin:** <origin ticket path or "session handoff on <branch>"> — carried on <date> because the token window was filling; continue in a fresh session.

<What is already done, as context — the completed steps / landed commits, so the
resuming agent does not redo them. Then one line on where work stopped.>

## Policies

<Carried verbatim from the origin ticket's ## Policies, or derived from the layer
per the create-ticket Policy Lens. Mandatory and never empty for code work.>

## Implementation Steps

1. <first REMAINING action>
2. <next REMAINING action>
   ... (only remaining work — never re-list completed steps)

## Quality Gate

<Carried forward from the origin ticket's ## Quality Gate so the fresh /drive
approval stays gated on the same objective criteria.>

## Findings

<Optional — omit this heading entirely when the session surfaced nothing worth
recording. What the session learned, as verifiable claims, so the resuming agent
does not re-explore a path already closed:
"Ruled out <X> because <Y> (verified by <Z>)." /
"Discovered <A> behaves as <B>, contrary to <assumption>."
Context for the remaining steps — never itself an Implementation Step.>

## Decisions

<Optional — omit this heading entirely when nothing of note was decided. The
choices made this session and their rationale, so the resuming agent does not
relitigate them:
"Chose <A> over <B> because <constraint C>."
State the reason, not the deliberation. Context — never an Implementation Step.>

## Considerations

- <Any in-flight caveat the resuming agent must know (uncommitted changes, a
  half-applied edit, an environment assumption).>
```

## 4. Writing Guidelines

- **Remaining-only steps.** The single correctness rule: completed work is Overview context, never an Implementation Step. `/drive` re-runs any step it sees.
- **Objective and traceable.** Name the exact files, paths, step numbers, and commit hashes; a resuming agent must be able to verify the state, not guess it (`workaholic:implementation` / `objective-documentation`).
- **Preserve the reasoning, objectively.** `## Findings` and `## Decisions` carry what the session learned and decided so a fresh `/drive` neither re-explores a ruled-out path nor relitigates a settled choice — the one thing a remaining-only ticket would otherwise drop. Hold them to the same bar: each is a verifiable claim — the dead-end and *why* it was ruled out, the decision and *its* rationale — never aspirational prose or a transcript of deliberation (`workaholic:implementation` / `objective-documentation`, "document decisions, not implementations"). They are context, not Implementation Steps; omit either heading when the session produced none.
- **Carry the gate.** Preserve the origin's `## Quality Gate` so the resumed approval is concrete, not a fresh vague summary.
- **Capture only.** Never implement, edit toward the task, commit, or archive; never discard uncommitted changes. `/carry` writes resume state and stops.
