---
type: Engineering Policy
title: "Proactive Consideration of Per-Tenant Databases"
description: "Evaluating the database isolation model for multi-tenant products early in design, since strong tenant isolation is much cheaper to build in than to retrofit after data has accumulated."
resource: https://qmu.co.jp/design/per-tenant-database
tags:
  - design
  - per-tenant-database
---

# Proactive Consideration of Per-Tenant Databases

_In multi-tenant products, consider per-tenant database isolation early in the design; strong data isolation is much cheaper to build in than to retrofit._

Multi-tenant products face a recurring architectural choice: shared database with tenant isolation by row-level security or foreign key, schema-per-tenant in the same database instance, or a separate database instance per tenant. Each model has a different cost and isolation strength. Shared databases are operationally simpler and cheaper but create data leak risk from misconfigured queries and limit compliance flexibility. Per-tenant databases provide strong isolation but increase provisioning and operational complexity. Our policy is to evaluate this choice deliberately and early, before data structures are embedded, because retrofitting strong isolation is very expensive.

## Goal (目標)

The situation this policy aims to achieve is one in which the chosen isolation model is aligned with the product's compliance requirements, data sensitivity, and operational capacity, and was chosen deliberately rather than by default.

- The isolation model is documented as an architectural decision record at the start of multi-tenant design.
- If stronger isolation is warranted by compliance or data sensitivity, the infrastructure supports it from the first tenant.
- The provisioning and migration path for adding new tenants is automated, regardless of the isolation model.

## Responsibility (責務)

The situation this policy aims to prevent is one in which a shared-database model is adopted by default, without considering whether the product's compliance or data sensitivity requirements warrant stronger isolation, and the cost of migrating to stronger isolation becomes prohibitive after data accumulates.

States we do not tolerate:

- Shared-database, shared-schema multi-tenancy adopted without considering whether the compliance requirements of the customer base warrant stronger isolation.
- Row-level security implemented in application code rather than enforced at the database, leaving direct DB access unprotected.
- A per-tenant isolation model that was decided late, after schema and data had accumulated in a shared model, requiring a complex data migration.

## Practices (実践)

### Choose the isolation model before designing the first tenant-scoped table

The isolation decision — shared schema, schema-per-tenant, or database-per-tenant — is made before the first tenant-scoped table is designed. Record the reasoning in an ADR. The question to answer: what happens if a bug causes one tenant to see another tenant's data, and what does that cost in trust, compliance, and legal exposure?

### Evaluate schema-per-tenant as a middle ground

Schema-per-tenant (a separate Postgres schema per tenant in a shared database instance) is a middle ground: stronger isolation than a shared schema (no cross-tenant query risk from a missing WHERE clause), without the full operational overhead of separate instances. It warrants evaluation before committing to either extreme.

### Automate tenant provisioning regardless of the isolation model

Whether tenants share a database or have their own, the provisioning of a new tenant — creating the schema or database, running migrations, seeding configuration — is automated as a script or IaC template. Manual tenant provisioning that scales with the number of tenants is not a tenable operational model.

### Related: Schema-First Database Design, Access Control Mechanism Selection, Security Considered in Layers

The isolation model decision is a schema design decision — [Schema-First Database Design](/implementation/persistence.md). Row-level security as an access control mechanism is discussed in [Access Control Mechanism Selection](/design/access-control.md). Tenant data isolation is a layer in the defense-in-depth posture — [Security Considered in Layers](/design/defense-in-depth.md).
