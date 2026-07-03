---
title: Cautious Consideration of Distributed Systems
slug: modular-monolith-first
category: design
source: https://qmu.co.jp/design/modular-monolith-first
---

# Cautious Consideration of Distributed Systems

_Use managed services as development scaffolding while keeping the deployment unit as a single modular monolith; split into separate services only when the boundary is justified and the rationale is documented._

Managed services such as Cloudflare Workers and AWS Lambda serve as useful scaffolding for starting development quickly — we use them. As deployment units, however, the baseline is to design as a single modular monolith first; service splits are limited to cases where the boundaries are worthwhile, and expanding into a microservice-oriented architecture without concrete justification is not our approach.

## Goal (目標)

The state we aim for is one in which the system is maintained as a single modular monolith with clear internal module boundaries, able to absorb new features without incurring the cost of distributed systems. Managed services provide the scaffolding to start development quickly; the deployment unit stays as one; module boundaries are kept clear in the code.

## Responsibility (責務)

The state we work to prevent is one in which the system is split into separate deployment units without documented justification that the boundary is worthwhile.

Splitting, once started, is hard to reverse, and each additional service tends to accumulate communication, consistency, monitoring, and deployment complexity. In development where AI writes much of the implementation, new services can be stood up quickly — making it easy for a distributed configuration to spread without anyone recording why the split was made.

## Practices (実践)

### Use managed services as development scaffolding

Managed services like Cloudflare Workers and AWS Lambda are used as scaffolding to start development quickly. Using these services and splitting the deployment unit into many services are separate questions; the whole remains designed as a single modular monolith.

### Separate by internal module boundaries

Within one deployment unit, draw module and package boundaries by concern. Well-organized internals leave room to later extract a genuinely necessary module into an independent service when the evidence is concrete.

### Split only when boundaries are justified, and document the rationale

Splitting into a separate service is reserved for when a concrete need has become clear — independent scaling, an independent deployment cadence, or fault isolation. When the decision to split is made, record why that module is becoming a separate deployment unit in the PR description or an ADR, so that future readers can reconstruct the rationale for the boundary.

### Related: Conservative Vendor Dependence, Capacity and Recovery Planning, Domain Layer Separation

See [Conservative Vendor Dependence](vendor-neutrality.md), [Capacity and Recovery Planning](../implementation/policies/operational-planning.md), and [Domain Layer Separation](../implementation/policies/domain-layer-separation.md) for related policies.
