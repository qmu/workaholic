---
title: Capacity and Recovery Planning
slug: operational-planning
category: implementation
source: https://qmu.co.jp/implementation/operational-planning
---

# Capacity and Recovery Planning — Start from Simple Capacity, and Shape Recovery Procedures by Working Backward from Scenarios

Capacity planning and recovery planning are policies that secure operational continuity as a matter of planning done in advance. Rather than scrambling to think about "how much can we handle" and "how do we get back after a failure" only once operations have begun, we hold these in a simple form at the construction stage. We treat the two as a single subject because they are bound together by a common principle — rejecting excessive advance planning while working backward from scenarios.

## Goal (目標)

The situation this policy aims to achieve is one in which the preparation needed for operational continuity is in place, without introducing complexity through excessive advance headroom or elaborate calculation.

The contours of the goal are as follows:

- Room is left, in both infrastructure and process, to start from the minimum, observe actual demand, and expand accordingly.

- The recovery plan is worked backward from concrete failure scenarios (具体的な障害シナリオ), rather than from an abstract "99.9% availability."

- For each failure scenario, a recovery path, an allowable data-loss margin, and a restoration procedure are defined.

- The RTO (Recovery Time Objective / 復旧時間目標) and RPO (Recovery Point Objective / 復旧時点目標) are derived from the scenarios, and are not established in the reverse order.

- The recovery plan has been rehearsed, and has not been left to languish as a desk-bound document.

## Responsibility (責務)

The situation this policy aims to prevent is one in which continuity preparation is optimized only for "good days," and the "worst day" is not anticipated before it arrives.

States we do not tolerate:

- Introducing complexity through elaborate advance capacity planning. A state in which, while actual demand is still unknown, one invests in large-scale load testing, capacity models, and scaling design, and implementation falls behind as a result.

- Recovery design worked backward from abstract availability targets (99.9%, 99.99%). Numerical targets that are not tied to concrete scenarios cannot be translated into operational judgment.

- Recovery procedures that have not been rehearsed. A state in which "if a failure occurs, we restore using this procedure" is written down, but the procedure has never actually been carried out.

- No decided margin for allowable data loss. If you set "we will absolutely never lose data" as the goal, you cannot devise a response to unavoidable failures (a full-region outage, accidental deletion, corruption).

- Treating "recovery" as synonymous with "rollback." Data corruption, accidental deletion, and failures of dependencies are not undone by a rollback. The recovery path differs from scenario to scenario.

- Not considering a scenario "because it can't happen." If you assume that "a region failure won't occur" or that "the DB will never break," then when it does occur, the response becomes improvised.

## Practices (実践)

### Simple capacity planning (簡素な容量計画)

We keep infrastructure small and simple. If portability is secured, capacity can be re-measured and changed at any time, so excessive advance headroom and elaborate capacity planning introduce complexity of little commensurate value.

- Start from the minimum: the initial configuration is the smallest configuration that works for the smallest user count you anticipate.

- Observe actual demand: from metrics (observability and self-healing), continuously grasp the current load.

- Expand accordingly: once the limit comes into view, or signs that it is about to appear, increase capacity at that point.

Do not build out infrastructure in advance by calculating "the anticipated user count three years from now." Leaving yourself the freedom to rebuild the infrastructure three years from now is cheaper and more accurate.

### Scenario-based recovery planning (シナリオベースの復旧計画)

The recovery plan is built along concrete failure scenarios (具体的な障害シナリオ), not abstract availability targets. Each scenario prescribes its own recovery path, allowable data-loss margin, and restoration procedure.

Typical scenarios we anticipate:

- Data corruption: a failed DB schema change, erroneous data written by an application bug, and the like.

- Region failure: a full outage of a particular region of a cloud vendor.

- Accidental deletion: an operator, a script, or an automation mistakenly deletes a resource.

- Dependency failure: a SaaS outage, a prolonged downtime of an external API, a failure of the authentication provider.

- Security incident: data contamination or tampering due to unauthorized access (linked with safety).

The RTO and RPO are derived from these scenarios, and are not established in the reverse order. It is normal for the allowable RTO / RPO values to differ from scenario to scenario (accidental deletion within a few minutes, a region failure within a few hours, and so on).

### A recovery procedure is only completed once it has been rehearsed (復旧手順はリハーサルで初めて完成する)

A recovery procedure cannot be known to work until it has actually been carried out.

- On a monthly-to-quarterly cadence, conduct a recovery rehearsal for each scenario.

- Fix the problems found in the rehearsal (gaps in the procedure, insufficient permissions, tooling that is not in place).

- Keep a rehearsal record (date conducted, time required, findings).

If you feel that "there is no time to rehearse," that is a sign that either there are too many scenarios (they need to be narrowed down) or the recovery process itself is too complex (it needs to be simplified).

### Backups emphasize "restoration" over "acquisition" (バックアップは「取得」よりも「復元」を重視する)

The purpose of a backup is not that you are taking it, but that you can restore from it.

- Periodically perform a restoration from backup into a separate environment, and measure the restoration success rate.

- Verify the data integrity at restoration time (migration consistency, referential integrity, recency).

- Measure the time required until restoration completes, and confirm that it is reasonable in light of the RTO.

A backup that "is being taken but has never been restored from" is the same as not having one.

### Scaling is done "observation-driven" (スケーリングは「観測駆動」で行う)

The decision to increase capacity is made on the basis of metrics.

- CPU utilization exceeding a threshold: over 80% for 5 continuous minutes → automatic scale-out.

- Increase in queue depth: when processing cannot keep up, increase the number of workers.

- Degradation of latency p99: once it begins to exceed the SLO, isolate the cause (CPU, I/O, dependency) before responding.

Decide the thresholds in advance and build them into automatic responses (linked with the scale-out triggers of observability and self-healing).

### Reference the recovery manifest from docs/safety/incident-response.md (復旧マニフェストを docs/safety/incident-response.md から参照する)

The per-scenario recovery procedures are placed where they can be referenced from the incident-response procedures of the safety policy.

- For each scenario: scenario name, detection method, priority, RTO/RPO, recovery procedure (at the command level), and contacts.

- Write the procedure at a granularity that can be executed by copy-paste (not "restore the DB," but `wrangler d1 backup restore <id>`).

### Backup strategy (バックアップ戦略)

- Frequency: transaction logs (at 1-minute granularity if PITR is possible) + a daily full backup.

- Storage location: a physical boundary separate from production (a separate region, a separate vendor).

- Retention period: the most recent 30 days (high-frequency access) + 1 year (cold storage). Adjust according to business requirements.

- Access control: access to backups is managed under a permission boundary separate from write permissions to production (to cut off a cascade in the event of unauthorized access).

### Hold a capacity "reserve" (キャパシティの「予備」を持つ)

Within a range that does not contradict simple capacity planning, hold reserve capacity that can withstand short-lived surges (短時間の急増に耐える予備容量).

- Set 1.5 to 2 times the observed peak as the upper limit for autoscaling.

- Set an alert (observability and self-healing) for when the upper limit is reached.

### Related: CI/CD, Portability, Observability, Safety (関連: CI/CD・移植性・可観測性・安全性)

Rollback automation is directly connected to CI/CD automation. Reproducibility presupposes passive vendor dependence (消極的ベンダー依存) and infrastructure as code. Scaling decisions take the metrics of observability and self-healing as their input. Recovery in the event of a security incident references safety and incident response.
