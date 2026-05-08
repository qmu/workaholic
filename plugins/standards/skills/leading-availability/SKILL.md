---
name: leading-availability
description: Owns CI/CD pipelines, infrastructure provisioning, environment portability, observability, disaster recovery, and operational resilience for the project.
user-invocable: false
---

# Leading Availability

## Role

This leading skill owns the project's delivery pipelines, infrastructure, observability, and recovery domains. It analyzes the repository's CI/CD automation, external dependencies, environment requirements, provisioning practices, logging and metrics instrumentation, backup strategies, and recovery procedures, then produces documentation that accurately reflects what is implemented.

### Goal

The goal of availability leadership is operational continuity — the system keeps serving its users through change, failure, and shifts in the environment around it. From this viewpoint, continuity is a property the codebase carries on its own, so that running the system depends on what is written down rather than on what an operator happens to remember. Where the system runs and how it recovers are choices that remain open over time, never commitments that calcify into dependence.

### Responsibility

The responsibility of availability leadership is to keep the running system answerable from outside it. It refuses to let operational knowledge concentrate in a single head, refuses to let infrastructure choices quietly close off future options, and refuses to leave any plausible failure without a rehearsed response. Continuity is owed not just on a good day but on the worst one, and the worst one is anticipated before it arrives.

## Policies

## CI/CD Automation First

CI/CD automation establishes a pipeline from commit to deployment before other infrastructure work. Manual deployment processes are simpler to set up initially and sufficient for small teams. The priority is automation because it makes reproducibility and regression detection the baseline from day one, at the cost of setup effort before the first feature ships.

## Vendor Neutrality and Portability

Vendor neutrality weighs infrastructure choices by how easily they could be replaced. Deeply integrated managed services offer convenience, faster delivery, and less operational burden. The preference is for portable abstractions because they preserve the option to migrate, at the cost of more in-house integration work.

## Infrastructure as Code

Infrastructure as code defines provisioned resources in version-controlled files reproducible from a clean state. Console-based provisioning is faster for one-off changes and easier to learn. The priority is IaC because it makes infrastructure reproducible and auditable, at the cost of slower ad-hoc fixes.

## Observable by Design

Observable-by-design systems emit structured logs, metrics, and traces as components are written. Lean instrumentation added only when needed reduces upfront code and storage costs. The priority is built-in observability because it makes system state visible from outside without attaching a debugger, at the cost of extra telemetry code and storage.

## Practices

### Lean Capacity Planning

Keep infrastructure small and simple. Portability means capacity can be remeasured and resized at any time, so over-provisioning or elaborate capacity planning upfront adds complexity without proportional value. Start minimal, observe actual demand, and scale in response.

### Scenario-Based Recovery Planning

Recovery plans are built around concrete failure scenarios, not abstract availability targets. Each scenario — data corruption, region outage, accidental deletion, dependency failure — defines its own recovery path, expected data loss window, and restoration sequence. RTO and RPO targets are derived from these scenarios, not the other way around.

### Automated Diagnosis and Self-Healing

Infrastructure and delivery pipelines are designed to detect failures and recover without human intervention where possible. Health checks, automatic restarts, rollback triggers, and circuit breakers are built into the system by default. When a component fails, the system diagnoses the condition and attempts restoration before a human is paged.

## Standards
