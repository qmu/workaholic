---
type: Engineering Policy
title: "Policy Conformance Auditing"
description: "Auditing the codebase against stated policies on a quarterly cadence to surface drift before it becomes structural, tracking non-conformances as debt, and updating policies that the audit reveals as unworkable."
resource: https://qmu.co.jp/implementation/policy-conformance-audit
tags:
  - implementation
  - policy-conformance-audit
---

# Policy Conformance Auditing

_Periodically audit the codebase against the project's stated policies, to keep the policies in contact with the code and to surface drift before it becomes structural._

Policies are commitments about how a codebase will be structured, secured, and operated. Without periodic review, the distance between policy and practice grows silently — not through malicious evasion, but through the normal accumulation of incremental decisions that each seemed acceptable in isolation. An audit makes that gap visible, converts findings into actionable items, and creates a feedback loop between the policies and the codebase. We treat the audit not as a compliance exercise but as a practice that keeps the policies honest and the code intentional.

## Goal (目標)

The situation this policy aims to achieve is one in which the codebase is kept in contact with the project's stated policies through periodic review, and where drift, when found, is tracked and resolved rather than allowed to accumulate.

- The audit covers each active policy and produces a finding (conforming, partially conforming, or not conforming) per policy per area of the codebase.
- Non-conformances are entered as tracked items and resolved within a defined window.
- Policies that the audit repeatedly finds impossible to conform to are updated, not ignored.

## Responsibility (責務)

The situation this policy aims to prevent is one in which policies become shelfware — written and forgotten, with no mechanism connecting them to actual code.

States we do not tolerate:

- Policies that have never been audited against the codebase. A policy that has never been verified is a statement of intent, not a description of practice.
- Non-conformances found in an audit that are not tracked. An untracked finding is an accepted deviation.
- An audit process that is too heavyweight to run — if the audit takes more effort than it returns, it will not happen.

## Practices (実践)

### Conduct an audit on a quarterly cadence

Run a policy conformance audit quarterly — or after a major architectural change, whichever is sooner. The audit scope covers: the implementation policies (domain layer separation, persistence, vendor neutrality, observability, infrastructure as code), the design policies (access control, data sovereignty, admin isolation), and the operation policies (CI/CD automation, no-customer-support-in-repo). The output is a brief report: per-policy conformance status, findings, and action items.

### Use automated checks as the first layer

Automate what can be automated: dependency vulnerability scans, secret scanning, lint rules, type coverage, accessibility audits (Axe), outdated dependency detection. Automated checks run in CI and feed into the quarterly report. Manual review covers what automation cannot: architectural conformance, access control design, documentation currency.

### Track non-conformances as debt

Non-conformances found in an audit are recorded as tracked items (GitHub issues, ADRs, or equivalent) with a target resolution window. The quarterly report includes the count of open non-conformances from previous audits. Items open for more than two audit cycles are escalated.

### Update policies when the audit reveals a mismatch

If a policy consistently fails its audit, that is evidence that either the policy is unrealistic given the codebase's actual constraints, or that the codebase needs to change. Resolve the mismatch in one direction: change the policy to reflect the actual intent, or change the code to meet the policy. Do not maintain a policy that is permanently violated.

### Related: All implementation, design, and operation policies

Policy conformance auditing is the feedback mechanism for all other policies. Cross-reference the implementation policies ([Domain Layer Separation](/implementation/domain-layer-separation.md), [Schema-First Database Design](/implementation/persistence.md), [Observability and Self-Healing](/implementation/observability.md)), design policies (accessible from Design SKILL.md), and operation policies ([CI/CD Automation](/operation/ci-cd.md)).
