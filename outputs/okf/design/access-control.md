---
type: Engineering Policy
title: "Access Control Mechanism Selection"
description: "Choosing the access control mechanism proportionate to the actual authorization requirements, starting simple and escalating only when a simpler model cannot express the needed rules."
resource: https://qmu.co.jp/design/access-control
tags:
  - design
  - access-control
---

# Access Control Mechanism Selection

_Choose the access control mechanism that fits the actual authorization requirements — starting simple, and adding complexity only when the simpler model cannot express the needed rules._

Access control mechanisms range from basic owner-only checks through role-based access control (RBAC), attribute-based access control (ABAC), policy-based access control, and row-level security enforced at the database. More expressive mechanisms are also harder to reason about and audit. Our policy is to start with the simplest mechanism that can express the actual rules, and to migrate to a more expressive mechanism only when a concrete requirement cannot be met otherwise.

## Goal (目標)

The situation this policy aims to achieve is one in which access control rules are legible — a reviewer can answer "can user X reach resource Y under condition Z" by reading a single authoritative definition — and enforced consistently across all paths to the resource.

- Authorization rules are expressed in a single layer rather than scattered across HTTP handlers, service functions, and database queries.
- The mechanism's complexity is proportionate to the rules it must express.
- Row-level security, where used, is declared in the schema and enforced by the database, not replicated in application code.

## Responsibility (責務)

The situation this policy aims to prevent is one in which access control is inconsistently applied, so that some paths to a resource check authorization and others do not.

States we do not tolerate:

- Authorization checks scattered ad-hoc across HTTP handlers, service functions, and ORM queries, with no single place where "who can reach this resource" can be read.
- Choosing ABAC or policy-based access control when RBAC would express the same rules, because the more expressive mechanism sounds more sophisticated.
- Row-level security that is enforced in the application layer but not at the database, leaving direct database access unprotected.
- Privilege escalation paths: a user who should not reach a resource being able to reach it by constructing a request not anticipated by the application logic.

## Practices (実践)

### Start with the simplest sufficient model

For most products, the authorization rules can be expressed as: the owner may always act; members of these roles may act; administrators may always act. Express that first. Add ABAC, policy-based, or row-level mechanisms only when a concrete rule cannot be expressed in RBAC.

### Place the authorization check in a single layer

Define the authorization layer once — as a middleware, a guard, or a policy object — and call it from every entry point. Do not replicate the check in service functions as a secondary defense; a single authoritative check is easier to audit and evolve than multiple scattered ones.

### Enforce row-level rules at the database when possible

For multi-tenant data or per-user data isolation, declare the row-level security policy in the database schema. Postgres row-level security (RLS), for example, enforces the policy regardless of whether the caller is the application, a migration tool, or a direct query — removing a class of application-layer bypass. Reference this in the Persistence policy.

### Document the authorization model alongside the data model

The access control rules are as important to document as the data schema. When a new resource type is added, the authorization rules for it — who may create, read, update, and delete — are specified in the same PR, alongside the schema and handler.

### Related: Authentication and Authorization Procurement, Defense in Depth, Schema-First Database Design

Mechanism selection follows from the auth procurement decision — see [Authentication and Authorization Procurement Policy](/design/auth-procurement.md). Row-level security is a complement to [Schema-First Database Design](/implementation/persistence.md). Both are one layer in a defense-in-depth posture — see [Security Considered in Layers](/design/defense-in-depth.md).
