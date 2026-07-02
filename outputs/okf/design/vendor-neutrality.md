---
type: Engineering Policy
title: "Conservative Vendor Dependence"
description: "Evaluating the cost of exit before adopting an external service, keeping the integration boundary thin, and avoiding design decisions that amplify switching costs beyond what the service's value justifies."
resource: https://qmu.co.jp/design/vendor-neutrality
tags:
  - design
  - vendor-neutrality
---

# Conservative Vendor Dependence

_Choose external services, platforms, and APIs in a way that preserves the freedom to change them; evaluate the cost of exit before committing, not after._

Every external service chosen is a dependency on a vendor's continued existence, pricing, and terms. Most dependency choices are worth making — the value of a managed service typically outweighs its lock-in cost. But we evaluate that trade-off deliberately: we understand what we would need to do to move away from a service before we commit to it, and we avoid design decisions that amplify the cost of switching beyond what the service's value justifies.

This policy covers the design level — which services and platforms to adopt, how to interface with them, and how to bound the surface of dependency. The implementation-level stance on vendor dependence is in the implementation pillar's [Conservative Vendor Dependence](/implementation/vendor-neutrality.md) policy.

## Goal (目標)

The situation this policy aims to achieve is one in which the cost of replacing any external service is bounded — not zero, but understood and proportionate to the service's role in the system.

- The interface between the product and each external service is thin and explicit: the product's domain logic does not depend on the vendor's data types or vocabulary.
- The migration path away from each external service is documented, even if it has never been executed.
- Services are chosen on their merit for the current requirements, not on the assumption that they will be used forever.

## Responsibility (責務)

The situation this policy aims to prevent is one in which an external service has spread into the product's core in a way that makes replacement prohibitively expensive.

States we do not tolerate:

- Domain logic that calls a vendor's SDK or API directly, in vocabulary specific to that vendor, rather than through an abstraction layer.
- Choosing a service without considering the exit path. "We can always change later" is not a plan; exit paths become dramatically more expensive after the service is embedded.
- Letting the vendor's data model drive the product's data model. The product's schema is the source of truth; vendor representations are translated at the integration boundary.

## Practices (実践)

### Evaluate exit cost before adopting a service

Before choosing an external service, ask: if this service raised its prices by 10×, or sunset the product, or changed its terms materially, how expensive would replacing it be? The answer should inform the design of the integration boundary — a service with a plausible exit path needs a thinner integration than one that requires deep embedding.

### Wrap vendor interfaces at an explicit boundary

The code that calls a vendor's API or SDK is isolated in a dedicated module or package. That module exposes a domain-vocabulary interface to the rest of the application; vendor-specific types do not cross the boundary. See the implementation pillar's Domain Layer Separation policy for the pattern.

### Prefer services that export to open standards

When comparing services with equivalent capabilities, prefer the one that exports data in an open, portable format. Data portability is part of the exit path.

### Related: Conservative Vendor Dependence (implementation), Cautious Consideration of Distributed Systems, Authentication and Authorization Procurement

This policy covers the design-level choice; the implementation-level practices are in [Conservative Vendor Dependence](/implementation/vendor-neutrality.md). Service proliferation accelerates when moving to distributed systems — see [Cautious Consideration of Distributed Systems](/design/modular-monolith-first.md). Auth service selection is a specific application of this policy — see [Authentication and Authorization Procurement Policy](/design/auth-procurement.md).
