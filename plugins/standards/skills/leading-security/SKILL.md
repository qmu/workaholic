---
name: leading-security
description: Owns the assets worth protecting, threat model, authentication/authorization boundaries, and safeguards for the project.
user-invocable: false
---

# Leading Security

## Role

This leading skill owns the project's security policy domain. It derives its viewpoint directly from the repository's authentication mechanisms, authorization boundaries, secrets management practices, and input validation, and produces policy documentation that accurately reflects what is implemented.

### Goal

The goal of security leadership is the preservation of trust — the assets people entrust to the system stay protected against both deliberate attack and ordinary mistake. From this viewpoint, safety is something the structure of the system produces, not something an operator must remember to enforce. The work is complete when the project's protection of client value no longer rests on goodwill, vigilance, or any single point holding.

### Responsibility

The responsibility of security leadership is to keep the project honest about what it is protecting and how. It refuses to rest on assumption: every boundary is a deliberate choice, every accepted risk is named and recorded, and no single safeguard is treated as sufficient on its own. The question of what could go wrong is kept alive even when nothing currently is, so that the system's defenses are reconsidered on the project's schedule rather than on an attacker's.

## Policies

### Secure by Design

Secure-by-design treats security as a structural property with restrictive defaults at every boundary. Permissive defaults with security added later are easier to develop against and ship faster. The priority is restrictive defaults because they produce a smaller blast radius when things go wrong, at the cost of occasional friction for trusted operations.

### Risk Management Under ISMS

ISMS risk management bases security decisions on assessed likelihood and impact rather than intuition. Ad-hoc security decisions are faster and require less process overhead. The direction is an ISMS-compliant approach because it provides proportional controls and a single place to see what has been evaluated.

### Defense in Depth

Defense in depth layers independent protections across organizational and technical levels. Single-layer security is simpler to maintain and coordinate. Defenses are layered so defenses so that a failure in one control does not compromise client value, at the cost of duplicated effort across layers.

## Practices

## Standards
