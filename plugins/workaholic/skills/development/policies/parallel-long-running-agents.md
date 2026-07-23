---
title: Parallel and Long-Running Coding Agent Operation
slug: parallel-long-running-agents
category: development
source: https://qmu.co.jp/development/parallel-long-running-agents
---

# Parallel and Long-Running Coding Agent Operation

_A policy for moving judgment before execution and using independent units of work with verifiable completion conditions to sustain parallel, long-running coding-agent operation._

We make the purpose, boundaries, completion conditions, and human judgment points of work explicit before execution, then advance independent units of work concurrently. The aim is not to maximize concurrency or elapsed time by itself, but to increase useful work that can proceed without waiting for a human response and whose completion can be verified from evidence.

## Goal (目標)

We aim for a state in which a short, abstract request becomes a work plan with a clear purpose, scope, order, and completion conditions through conversation before execution, then proceeds in units that do not interfere with one another. Each execution remains bounded and reviewable, and its result informs the next execution. This sustains hours of work, overnight runs, and, in current operating examples, runs lasting 48 hours or more without losing control of the process.

## Responsibility (責務)

Our responsibility is to prevent a state in which many agents run before judgments have been made concrete, mix one another's changes, and treat elapsed time or the number of passing checks as the result. Autonomous execution does not remove human responsibility for stating purpose and boundaries, judging interference between units of work, and reviewing the resulting work and verification evidence.

## Practices (実践)

### Move judgment before execution

Before a long-running execution begins, we identify where human judgment is likely to be needed and answer questions about purpose, priority, acceptable boundaries, and completion conditions. We retain those answers in the work plan rather than asking an agent to infer them during execution. If a new judgment is still required, the work remains bounded and returns the question in a form a human can review.

### Preserve the independence of each unit of work

Each concurrent unit has an independent change boundary, execution environment, and history. The intermediate state of one unit does not enter another, and its outcome and verification remain traceable on their own. When units affect shared files or environments, a human decides their order before they run concurrently.

### Connect short executions through evaluation

Each autonomous execution has a bound and records completed work, failed verification, and questions that require human judgment. Another execution starts only when completion conditions remain unmet, rather than repeating the same failure merely to extend elapsed time. Long-running operation is therefore a sequence of short, reviewable executions, not one unbounded process.

### Prepare the next work while execution continues

While agents execute prepared work, humans clarify the purpose and judgment points of the next unit. Alternating execution with judgment preparation removes human waiting points from the active path. After completion, a human reviews not only the artifacts but also what was verified and whether that evidence supports the completion conditions.

### Realization with the Workaholic Plugin

We realize this policy with Workaholic, a plugin that embeds our AI-assisted development workflow in the repository. The plugin records a long-lived work plan and its completion conditions as a "mission," then decomposes it into tickets small enough to implement. Because Workaholic asks the necessary human questions while the mission is prepared, executing agents can work from recorded judgments and verification conditions.

Each mission receives a dedicated Git worktree that separates its changes, development server, verification, and commits from other missions. Workaholic's monitor workflow selects prepared missions and assigns an executing agent to each worktree. It bounds each run, then returns ticket outcomes, unresolved judgments, and verification evidence together.

If one monitor run does not satisfy the completion conditions, a goal controller outside Workaholic invokes the same workflow again until it reports completion. Workaholic owns planning, isolation, bounded execution, and the result record; the outer controller connects those executions over a longer period. This separation keeps the plugin implementation distinct from the policy and preserves the principles that another implementation would also need to satisfy.

### Related: Preparing for After-Hours AI Work, Implementers Own Quality Assurance

See [Preparing for After-Hours AI Work](overnight-ai.md) for preparation specific to nighttime operation and [Implementers Own Quality Assurance](qa-engineering.md) for responsibility for reviewing quality after execution.
