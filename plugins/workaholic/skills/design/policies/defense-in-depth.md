---
title: Security Considered in Layers
slug: defense-in-depth
category: design
source: https://qmu.co.jp/design/defense-in-depth
---

# Security Considered in Layers

_Design security as a set of independent layers so that the breach of any single layer does not expose the system; treat each layer's failure as an expected event, not an impossibility._

No single security measure is reliable enough to be treated as the only defense. Passwords are stolen, secrets are leaked, access control rules have edge cases, network boundaries are misconfigured. Defense in depth is the practice of layering independent controls — at the network, application, data, and process levels — so that a breach of one layer still faces resistance from the others. The goal is not to make breach impossible; it is to make the consequence of any individual breach survivable.

## Goal (目標)

The situation this policy aims to achieve is one in which each security control assumes that all other controls may have already failed, and is designed to limit damage on its own.

- Network-level controls (firewalls, VPC boundaries, rate limiting) restrict what can reach the application.
- Application-level controls (input validation, output encoding, authentication, authorization) restrict what authenticated callers can do.
- Data-level controls (encryption at rest, column masking, row-level security, FK constraints) restrict what can be extracted even if application logic is bypassed.
- Process-level controls (least privilege, secret rotation, audit logging, incident response) limit the blast radius of a compromised credential or compromised component.

## Responsibility (責務)

The situation this policy aims to prevent is one in which a single control is relied upon to carry the entire security posture, so that its failure is a total failure.

States we do not tolerate:

- "We have authentication, so we don't need authorization checks on each resource." Authentication establishes identity; it does not enforce what that identity may access.
- "The database is inside the VPC, so it doesn't need access controls." Network isolation reduces the attack surface; it does not substitute for access control at the data level.
- "We use a managed service, so we don't need to audit its access." Managed services extend the attack surface; their access logs and configuration belong in the security model.
- Secrets that are never rotated because "they haven't been leaked." Rotation limits the window of exposure for any credential that has been leaked without detection.

## Practices (実践)

### Define the layers explicitly for this product

For each product, enumerate the active security layers: what network controls exist, what application-level controls are in place, what data-level protections are applied, and what process controls are in the incident-response plan. A defense-in-depth posture that has not been enumerated is not a posture — it is a collection of independent controls whose coverage is unknown.

### Validate at each boundary, not only at the first entry point

Input that arrives at an internal service, a queue worker, or a batch job may have passed through an external-facing layer, but assume it has not. Validate and authorize at each boundary that consumes the input.

### Treat secrets as having a finite safe lifespan

Rotate credentials, API keys, and certificates on a schedule rather than waiting for a known leak. Define the rotation interval as part of the infrastructure-as-code configuration — see [Infrastructure as Code](../../implementation/policies/infrastructure-as-code.md).

### Audit logs are a layer, not an afterthought

Audit logs of who accessed what and when are a security control: they enable incident detection and forensic reconstruction. Log access to sensitive data, privilege escalations, and authentication failures as structured events. Design the logging layer alongside the access control layer, not afterward.

### Apply the principle of least privilege to every component

Every process, service account, and human operator should have the minimum set of permissions needed to perform its function. Permissions are not additive defaults to be trimmed later; they are explicit grants. Review the permission set of each component when it is created, and again whenever its responsibilities change.

### Related: Authentication and Authorization Procurement, Access Control Mechanism Selection, Observability and Self-Healing, Infrastructure as Code

Defense in depth connects authentication procurement — [Authentication and Authorization Procurement Policy](auth-procurement.md) — with access control mechanism selection — [Access Control Mechanism Selection](access-control.md). Audit logs are part of [Observability and Self-Healing](../../implementation/policies/observability.md). Secrets rotation lives in [Infrastructure as Code](../../implementation/policies/infrastructure-as-code.md).
