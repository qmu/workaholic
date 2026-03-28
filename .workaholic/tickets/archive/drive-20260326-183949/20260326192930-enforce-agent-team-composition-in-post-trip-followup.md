---
created_at: 2026-03-26T19:29:30+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort: 0.5h
commit_hash: 2ca3c8a
category: Changed
---

# Enforce Agent Team Composition Discipline in Post-Trip Follow-Up

## Overview

After a trip session completes in a worktree (plan.md reaches `complete/done`), the user may send follow-up requests in the same Claude Code conversation. When this happens, Claude Code's leader (the main Claude instance) tends to spawn new, arbitrary Agent Teams agents rather than re-invoking the pre-designated planner/architect/constructor trio. This results in unnamed or generically-named agents that lack the trippin plugin's behavioral constraints, QA role boundaries, language policy, and trip-protocol awareness.

The root cause is that nothing in the trippin plugin constrains what happens after a trip session reaches `complete/done`. The trip command's Step 5 (Present Results) is the terminal step -- it summarizes results and suggests `/report` and `/ship`. There is no guidance for the leader about how to handle follow-up requests that arrive in the same conversation context. Without explicit instructions, Claude Code defaults to its general Agent Teams behavior: spawning new agents on-demand based on the task description, with no connection to the trippin plugin's agent definitions.

The fix has two dimensions: (1) instruct the team lead that follow-up requests after `complete/done` should be handled by the lead itself or by re-invoking the same three designated agents -- never by spawning arbitrary new agents; and (2) add a post-completion protocol to the trip-protocol skill that defines how the team lead should handle follow-up work within the worktree.

## Key Files

- `plugins/trippin/commands/trip.md` - Trip command; Step 4 Agent Teams instructions define the team lead's behavior but have no guidance for post-completion follow-ups. Step 5 is terminal with no continuation protocol. The team lead instruction block (lines 53-67) needs a post-completion section.
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill; defines step identifiers up to `complete/done` but has no post-completion workflow. The Phase Gate Policy (line 14) states "No sub-agent may autonomously advance" but does not address agent creation after completion. Needs a new section defining post-completion behavior.
- `plugins/trippin/agents/planner.md` - Planner agent definition; may be re-invoked for follow-up E2E testing or business validation tasks
- `plugins/trippin/agents/architect.md` - Architect agent definition; may be re-invoked for follow-up structural review tasks
- `plugins/trippin/agents/constructor.md` - Constructor agent definition; may be re-invoked for follow-up implementation tasks

## Related History

The trip protocol has evolved through progressive tightening of agent discipline: phase gate synchronization enforced sequential advancement, concurrent coding restructured agent parallelism, QA role differentiation established exclusive quality domains, and the phase gate policy prohibited autonomous agent advancement. Each iteration added behavioral constraints to the three designated agents. However, all constraints assume the trip is in-progress. The `complete/done` state is a terminal boundary beyond which no agent discipline exists. The language policy ticket (in todo) addresses language enforcement but not agent composition enforcement.

Past tickets that touched similar areas:

- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Established Phase Gate Policy preventing autonomous agent advancement (same principle of leader-controlled agent dispatch, now extended to post-completion)
- [20260312102503-differentiate-coding-phase-quality-responsibilities.md](.workaholic/tickets/archive/drive-20260312-102414/20260312102503-differentiate-coding-phase-quality-responsibilities.md) - Differentiated QA roles across the three agents (same agent discipline pattern; follow-up work should respect these same role boundaries)
- [20260311215034-concurrent-coding-phase-agents.md](.workaholic/tickets/archive/drive-20260311-125319/20260311215034-concurrent-coding-phase-agents.md) - Restructured concurrent agent dispatch with convergence gates (same leader-controlled dispatch model that should extend to follow-ups)
- [20260311183049-redefine-trippin-agent-personality-spectrum.md](.workaholic/tickets/archive/drive-20260311-125319/20260311183049-redefine-trippin-agent-personality-spectrum.md) - Defined the progressive/neutral/conservative agent spectrum (these personality definitions are lost when arbitrary agents are spawned instead)
- [20260326183945-enforce-written-language-policy-in-trippin.md](.workaholic/tickets/todo/20260326183945-enforce-written-language-policy-in-trippin.md) - Pending ticket to enforce language policy in trippin agents (same enforcement gap: arbitrary agents spawned post-trip would also lack language policy)

## Implementation Steps

1. **Add a Post-Completion Protocol section to `plugins/trippin/skills/trip-protocol/SKILL.md`** after the Coding Phase section and before the E2E Assurance section:
   - Define the `complete/followup` step identifier as the state for post-completion work
   - State the team composition rule: after `complete/done`, the team lead must NOT create new agent team members. Follow-up requests are handled either by the lead directly (for simple tasks like reading files, answering questions, or making small edits) or by re-invoking the existing three agents (planner, architect, constructor) for substantial work
   - Specify the decision criteria for the lead: handle directly when the task is a single-file edit, a question, or a quick fix; re-invoke designated agents when the task involves multi-file changes, requires QA validation, or touches the domain boundaries of specific agents
   - State that re-invoked agents retain their original role boundaries (Planner: E2E/business, Architect: structural/analytical, Constructor: implementation/internal testing)
   - Require `plan.md` frontmatter update to `complete/followup` when follow-up work begins, and back to `complete/done` when it finishes

2. **Add post-completion instructions to the team lead instruction block in `plugins/trippin/commands/trip.md`** (Step 4):
   - After the existing instructions about following trip-protocol and enforcing convergence cap, add a post-completion section
   - State: "After the trip reaches `complete/done`, if the user sends follow-up requests: handle simple tasks directly (reading, answering, small edits). For substantial work, re-invoke ONLY the three designated teammates (Planner, Architect, Constructor) -- never create new agent team members. The designated agents retain their original roles and constraints."
   - This instruction is critical because the team lead's instruction block is the primary context that persists through the conversation

3. **Add a follow-up rule to each agent definition** (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`):
   - Add a rule in each agent's Rules section: "When re-invoked for post-completion follow-up work, the same role boundaries, QA domain, and behavioral constraints apply as during the original trip session"
   - This ensures agents do not "reset" their behavioral constraints when re-invoked after completion

4. **Update Step 5 (Present Results) in `plugins/trippin/commands/trip.md`** to include continuation guidance:
   - After the existing transition guidance ("Use `/report` and `/ship` when ready to merge"), add: "For follow-up modifications in this worktree, the lead handles simple tasks directly or re-invokes the designated agents. No new agents are created."
   - This makes the post-completion policy visible to the user at the natural transition point

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -107,6 +107,22 @@
 Any agent may propose returning to Planning Phase. Requires 2/3 majority. Proposer writes `rollbacks/rollback-v<N>.md`; others vote in `rollbacks/reviews/rollback-v<N>-<agent>.md`. On approval, return to Planning with incremented artifact versions.

+## Post-Completion Protocol
+
+After the trip reaches `complete/done`, the team lead may receive follow-up requests from the user. The team composition rule applies strictly:
+
+**Never create new agent team members.** The only agents permitted in the worktree are the three designated teammates: Planner, Architect, and Constructor. This applies regardless of the nature of the follow-up request.
+
+**Lead handles directly** when the task is: answering a question, reading files, making a single-file edit, running a command, or any task that does not require the specialized perspective of a designated agent.
+
+**Lead re-invokes designated agents** when the task involves: multi-file changes, implementation work (Constructor), structural review (Architect), E2E validation (Planner), or any work that falls within a designated agent's domain. Re-invoked agents retain their original role boundaries, QA domains, and behavioral constraints from the trip session.
+
+Update `plan.md` frontmatter: set step to `complete/followup` when follow-up work begins, return to `complete/done` when it finishes. Log follow-up events to `event-log.md`.
+
+Step identifier: `complete/followup`
+
 ## E2E Assurance
```

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -66,6 +66,9 @@
 > All agents work inside `<worktree_path>`. Follow trip-protocol for the Planning Phase (concurrent artifacts, one-turn review, respond/escalate, moderate) and Coding Phase (concurrent launch, review & testing, iteration). Enforce convergence cap: max 3 review rounds before forced moderation. Use `trip-commit.sh` and `log-event.sh` for every step. Update `plan.md` at phase transitions. If resuming, skip completed steps.
+>
+> **Post-completion rule**: After the trip reaches `complete/done`, if the user sends follow-up requests: handle simple tasks directly (reading, answering, small edits). For substantial work, re-invoke ONLY the three designated teammates (Planner, Architect, Constructor) -- never create new agent team members. The designated agents retain their original roles and constraints.

 ## Step 5: Present Results

@@ -74,3 +77,4 @@
 3. Report implementation results
 4. Show the worktree branch name
 5. Transition guidance: "Use `/report` and `/ship` when ready to merge."
+6. Continuation guidance: "For follow-up modifications in this worktree, request changes directly -- the lead will handle simple tasks or re-invoke the designated agents (Planner, Architect, Constructor). No new agents are created."
```

### `plugins/trippin/agents/planner.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/planner.md
+++ b/plugins/trippin/agents/planner.md
@@ -30,3 +30,4 @@
 - Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
 - After completing any task, STOP and wait for the team lead's next instruction
 - Never modify another agent's artifact
+- When re-invoked for post-completion follow-up, the same role boundaries and QA domain (E2E/external testing) apply
```

### `plugins/trippin/agents/architect.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/architect.md
+++ b/plugins/trippin/agents/architect.md
@@ -30,3 +30,4 @@
 - Follow the preloaded **trip-protocol** skill for commit/log-event commands, artifact format, and all workflow procedures
 - After completing any task, STOP and wait for the team lead's next instruction
 - Never modify another agent's artifact
+- When re-invoked for post-completion follow-up, the same role boundaries and QA domain (analytical review only) apply
```

### `plugins/trippin/agents/constructor.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/agents/constructor.md
+++ b/plugins/trippin/agents/constructor.md
@@ -32,3 +32,4 @@
 - Run system-safety detection before any implementation that may touch system configuration
 - After completing any task, STOP and wait for the team lead's next instruction
 - Never modify another agent's artifact
+- When re-invoked for post-completion follow-up, the same role boundaries and QA domain (internal testing) apply
```

## Considerations

- This ticket addresses a limitation of Agent Teams where the leader has broad discretion to create new agents. The trippin plugin cannot technically prevent Claude Code from creating new agents -- it can only instruct the leader not to. The effectiveness depends on the team lead instruction being prominent enough in the leader's context to override its default behavior of spawning agents. Redundancy across trip.md (team lead instructions), trip-protocol (skill), and agent definitions (rules) increases the likelihood of compliance. (`plugins/trippin/commands/trip.md` lines 53-67)
- The `complete/followup` step identifier extends the existing step vocabulary without breaking the `read-plan.sh` script, which simply parses the `step` field from frontmatter as a string. No script changes are needed to support the new identifier. (`plugins/trippin/skills/trip-protocol/sh/read-plan.sh`)
- The trip command's resume logic (Step 1) routes `complete/done` to "inform user and suggest `/report`". If the user has already been informed and continues with follow-up requests, the resume logic is not re-triggered -- the team lead instruction block governs behavior for the remainder of the conversation. The post-completion rule in the team lead instruction is the operative constraint. (`plugins/trippin/commands/trip.md` line 30)
- The pending language policy ticket (20260326183945) addresses a complementary problem: arbitrary agents lack language enforcement. If that ticket is implemented first, the language rule in the trippin plugin's `rules/` directory would apply to designated agents but still not to arbitrary agents spawned outside the plugin's agent definitions. Both tickets together provide comprehensive agent discipline: this ticket prevents arbitrary agents from being created, and the language ticket ensures designated agents follow language rules. (`.workaholic/tickets/todo/20260326183945-enforce-written-language-policy-in-trippin.md`)
- The "lead handles directly" path is important for efficiency. Re-invoking a full Agent Teams trio for a one-line fix would be excessive. The decision criteria (single-file vs multi-file, question vs implementation) give the leader clear heuristics. However, there is an edge case where the leader might handle a task directly that would benefit from an agent's specialized perspective (e.g., a "small edit" that has structural implications the Architect would catch). The guideline prioritizes practical efficiency over exhaustive coverage. (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- This constraint applies to the worktree context. If the user starts a completely new `/trip` session in a different worktree, the normal trip workflow (with fresh agent creation) applies. The post-completion rule is scoped to follow-up interactions within the same worktree after the same trip session completes. (`plugins/trippin/commands/trip.md` Step 4)

## Final Report

Development completed as planned.
