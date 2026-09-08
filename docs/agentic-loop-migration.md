# Agentic loop v1 migration

Version 1.0.334 moves the loop to typed snapshots, durable effect records, capability based adapters, and resumable publication and delivery transactions. Legacy command names and result projections remain available while new code writes runtime state below the repository's absolute Git common directory at `workaholic/runtime/v1/`.

## Ownership map

| Decision | Single owner |
| --- | --- |
| What is due and whether an agent is needed | `runtime/scripts/plan-poll.sh` and `plan-turn.sh` |
| Snapshot evidence and invalidation | `gather/scripts/read-snapshot.sh` |
| Local state transitions and revisions | `runtime/scripts/state.sh` |
| Transport selection and effect confirmation | `transport/scripts/perform.sh` |
| Claim exclusion and recovery verdicts | `drive/scripts/lib/claims.sh` |
| Delivery checks and expected head | `drive/scripts/branch-checks.sh` and `gather/scripts/merge-pull.sh` |
| Publication transaction recovery | `branching/scripts/publication.sh` |
| Markdown section replacement | `story/scripts/replace-section.sh` |
| Maintenance order and triggers | `moderate/scripts/steps.json` |

Shell code owns finite state changes, atomic writes, bounded retries, and evidence matching. The agent owns decomposition, conflict meaning, hypothesis choice, prose, and whether a discovered change is valuable. This boundary keeps recovery deterministic without encoding product judgement as shell branches.

## State conversion and rollback

- The old `.codex-loop/` status and worker files remain readable through the legacy launcher and status projection. They are imported only after ownership is established; old flock files and new leases never act as simultaneous authorities.
- Binding inbox and outbox records are stored separately. A cursor advances after every message is captured. Unknown sends and incomplete inbox, delivery, claim, or publication records are not removed by TTL compaction.
- Publication retries reuse their transaction ID, worktree, branch, and committed SHA. A failed PR lookup is `unknown`; it does not license a second PR.
- Delivery retries reuse the existing branch and PR. Checks, release scan, local worktree, and merge request refer to one head SHA. An uncertain merge response is reconciled from the PR before cleanup.
- Rolling back the executable keeps the v1 directory inert. The legacy readers can continue from `.codex-loop/`; unfinished v1 records remain available for a later upgrade. Before a downgrade, reconcile any `sending`, `unknown`, `waiting_checks`, `merging`, or `pr_unknown` record because the legacy executor cannot prove those effects.

## Context and cost evidence

The current `/work` selected path is the short work skill and tick command plus the pure turn and polling planners. Historical rationale stays outside the path. Test-only capability, context-packet, dispatch, adapter, metrics, and compaction shells were removed after the live supervisor audit showed that no production path called them.

Hermetic P5 fixtures advance 100 unchanged poll boundaries with zero observations and zero worker launches. Request metrics store wall time, reader/API/worker counts, bytes, and provider usage only when returned; unknown token usage remains `null`.

The dedicated agentic-loop suite covers portable packaging, legacy projections, snapshots and atomic state, transport reconciliation, production delta capture, publication and claim recovery, adaptive polling, input normalization, delivery resume, and section-preserving reports.

## Live verification still required

Hermetic fixtures do not establish a real QFS workspace and sender, provider side incremental pushdown, Slack delivery and readback, native UI interruption, two automatic foreground reports, or downgrade recovery from a deliberately interrupted external effect. Those paths keep named `needs_parent`, `deferred`, or `unknown` outcomes. They must be measured with authorized real services; fake transports and historic PRs are not delivery evidence.
