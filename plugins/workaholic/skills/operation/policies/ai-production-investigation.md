---
title: AI-Assisted Production Investigation
slug: ai-production-investigation
category: operation
source: https://qmu.co.jp/operation/ai-production-investigation
---

# AI-Assisted Production Investigation

_When using an AI agent to investigate a production issue, constrain it to read-only access and record its actions; the speed advantage of AI-assisted diagnosis is real, but so is the risk of an agent taking an unintended action on live data._

AI agents are useful in production investigation: they can cross-reference logs, query metrics, correlate events, and draft hypotheses faster than a human reading the same data manually. The risk is that an agent operating against a production environment has both read access and, unless constrained, write access. An agent that queries a database to understand a data inconsistency is helpful. An agent that modifies data to "fix" what it diagnosed — without a human review step — is a production incident waiting to happen. The policy here is to capture the benefit while structuring the constraint: AI-assisted investigation operates in read-only mode, and any production change it proposes is reviewed and executed by a human.

## Goal (目標)

The situation this policy aims to achieve is one in which AI-assisted production investigation produces faster diagnosis without increasing the risk of unintended production mutations.

- The agent's access to production systems is read-only during investigation.
- Every action the agent takes during an investigation is logged, so the investigation can be replayed and audited.
- The agent's findings and proposed remediation steps are presented to a human for review before any production change is executed.

## Responsibility (責務)

The situation this policy aims to prevent is one in which an AI agent causes a production incident in the course of investigating one.

States we do not tolerate:

- An AI agent with write access to a production database during an investigation that was initiated to diagnose a data issue.
- Agentic execution of remediation steps — running DELETE, UPDATE, or INSERT against production — without a human review of those steps before execution.
- Investigations that leave no record of what the agent queried or what it found, so that the investigation cannot be verified or audited afterward.

## Practices (実践)

### Create a read-only investigation credential

For database access, create a read-only database user for AI-assisted investigations. The credential has SELECT and no other DML permissions. Do not use the application's read-write credential for AI-assisted queries. The read-only credential is managed in the same rotation schedule as other credentials — see the infrastructure-as-code policy on sensitive information management.

### Log the investigation session

Record the full session of an AI-assisted investigation: the queries issued, the logs and metrics accessed, the hypotheses generated, and the proposed remediation. The record is attached to the incident ticket or equivalent. This log is the audit trail that allows a later reviewer to verify what the agent found and what it proposed.

### Present proposed changes for human review before execution

An AI agent's proposed remediation — a data correction script, a configuration change, a restart procedure — is presented as a diff or a command for human review before it is executed. The human executes the change; the agent does not. This applies even in high-urgency incidents: the few seconds of review for a proposed DELETE or UPDATE are worth the protection against an erroneous agent action.

### Limit the investigation scope to the incident context

Configure the agent's context to include only the data relevant to the incident being investigated. An agent that has access to the entire production database during every investigation has a larger blast radius than an agent whose access is scoped to the relevant tables, time window, and tenant. Narrow the scope before starting the investigation.

### Related: Observability and Self-Healing, CI/CD Automation, Capacity and Recovery Planning

AI-assisted investigation supplements the observability posture — [Observability and Self-Healing](../../implementation/policies/observability.md) — and is activated when observability outputs point to an incident. The rollback automation in [CI/CD Automation](ci-cd.md) is the preferred first response for deploy-induced incidents; AI-assisted investigation handles cases where automated rollback did not resolve the issue. Recovery planning that accounts for AI-investigation procedures belongs in [Capacity and Recovery Planning](../../implementation/policies/operational-planning.md).
