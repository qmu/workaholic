---
type: Engineering Policy
title: "Conservative Vendor Dependence"
description: "Preserving the freedom to choose and switch dependencies by implementing by default, logging every dependency decision, securing modularity through anti-corruption layers, and maintaining portability at the managed-service boundary."
resource: https://qmu.co.jp/design/vendor-neutrality
tags:
  - design
  - vendor-neutrality
---

# Conservative Vendor Dependence

_Preserve the freedom to choose and switch dependencies; secure modularity for code-side boundaries and portability for external-side boundaries._

Our development environment and deliverables are built on top of a large number of open-source software (OSS) projects. Compilers, runtimes, libraries, databases, CI tools, editors — each is the product of developers around the world who have donated their time, published it freely, and continued to maintain it. The fact that we are able to deliver software to clients today is because of those projects and their contributors.

At the same time, supply-chain risks on OSS are growing more serious year by year, with the sophistication of social engineering and AI-driven vulnerability scanning. Beyond security, situations arise where we want to switch a dependency — a version upgrade with breaking changes, the end of maintenance, a move to a more competitive option.

If we consider these problems, fewer dependencies are better — but writing everything ourselves is not realistic, and we will continue to need dependencies on OSS, SaaS, and managed services. This policy therefore aims to preserve, without giving up, the freedom and options to choose dependencies. Concretely: ensuring modularity and portability.

There are two interfaces with external dependencies: a boundary that stands up **inside the code** — libraries, SDKs, drivers — and a boundary that stands up **outside the code** — SaaS, delivery targets, data storage. For the former, we secure **modularity** by separating external dependencies through code structure. For the latter, we secure **portability** by leaving room for migration to a different environment.

## Goal (目標)

The situation this policy aims to achieve is one in which sustainable software production is maintained. The freedom and options to choose external dependencies remain undiminished over time, and domain reasoning can continue to be developed independently of the shape of the infrastructure currently in use.

To be sustainable, we think it is not enough to only receive from the ecosystem. We want to publish and maintain part of the foundation that forms the core of our products ourselves, securing it as a domain not subject to external decisions. Standing on the receiving side of OSS — and also standing on the publishing and contributing side as a form of giving back — is what [plgg](https://github.com/qmu/plgg), our functional programming toolkit including Result types, Option types, pipeline composition, brand types, and AI workflow foundations, represents. We develop the type vocabulary and control-flow language underpinning our products as a foundation we can grow in line with our own domain, without handing that decision to others.

## Responsibility (責務)

The situation this policy aims to prevent is one in which we become so deeply bound to a particular vendor or tool that migration and switching become unrealistic, and one in which coupling to an adopted managed service is too deep to switch to another option.

On the first: a CakePHP 2-to-3 version upgrade involved breaking changes, and migrating a system built on version 2 to version 3 was not easy. This kind of lock-in is less frequent now than it once was, but as long as there is deep dependence on a particular technology, it remains something that can happen, and we want to prepare for it at the design stage.

On the second: for example, when a managed service we depend on raises prices, if the coupling to that service's proprietary resources, features, and APIs is too deep to leave, that situation can arise. Staying in a state where we can switch to a better service even when a vendor changes its terms of service, operating policy, pricing, or form of delivery — that is the aim of this responsibility.

## Practices (実践)

### Implement by default; rely on external only when justified

When building a new feature, make our own implementation the first choice. With the spread of AI coding agents, the prospect of writing ourselves what we previously relied on external libraries for has become realistic, and the motivation to add dependencies for minor features is diminishing. Only when our own implementation can be clearly judged as suboptimal do we rely on external libraries or services, following the criteria in the next practice.

### Log dependency decisions

When taking in a new dependency, document the following four points as a **dependency decision log** and leave it in the repository.

1. **Reason**: Why is this dependency needed? Which of our problems does it solve, and how?
2. **Assessment**: The result of examining license, reputation, development status, and sustainability (see the reputation practice below for each perspective).
3. **Monitoring plan**: Perspectives for continuing to ask whether we can keep depending on this after taking it in — vulnerabilities, accumulating bug issues, update stagnation, license changes, etc.
4. **Exit strategy**: How to switch if migration becomes necessary — alternative candidates, scope of impact (which layers and modules are affected), rough estimate of effort (person-days / person-weeks / person-months / person-years).

### Criteria for relying on external libraries or services

Under the principle of implementing by default, the following are the perspectives for deciding whether to rely on an external library or service. Any one of these **clearly** satisfied is the basis for relying on one.

- **Specialized domains where error is fatal, or far from our core**: Domains where even if we have the technical skill to write it ourselves, getting a detail wrong is fatal, or where maintaining equivalent depth of knowledge in-house is not realistic. Cryptographic libraries, timezone databases, Unicode normalization, PDF/video codecs, OS/browser cross-compatibility, and the like — we ride on what is maintained by a world community of specialists. Many of these come down to straightforwardly using the language's standard library or platform-provided features.
- **Interoperability / protocol compliance**: Domains where we want to ride OSS for the protocol layer needed to communicate accurately with other services, including spec-compliance verification. HTTP/TLS clients, OAuth/OIDC libraries, gRPC implementations — these have spec compliance continuously guaranteed by contributors around the world. Self-implementation only increases compatibility risk, with no benefit in terms of protocol compliance.
- **Cost and time efficiency**: Domains where writing it ourselves would be markedly inefficient in cost and time. React, Vue, off-the-shelf web server libraries, and the like fall here — self-reimplementation is not worthwhile. Using off-the-shelf options frees us to spend time on problems unique to our domain.
- **Domains that bring in capabilities we cannot reach alone**: Domains where taking something in adds capabilities to our software that we cannot reach on our own. In OSS: Monaco Editor for code editor components, React Flow for node-edge manipulation UI. In SaaS and managed services: Stripe, which provides global payment infrastructure. Where there is no path to reach the same level ourselves, we take in external results and redirect time toward problems unique to our domain.

### Confirm dependency reputation

The perspectives to confirm in the **Assessment** of the dependency decision log are as follows. We look at the same framework for OSS and managed services alike.

- **License**: Is it compatible with our use? Has there been any history of license changes?
- **Reputation**: Track record, community recognition compared to other projects serving the same role.
- **Development status**: Update frequency over the past year, release intervals, trends in unresolved issues, maintainer responsiveness.
- **Sustainability**: Whether maintenance continues even if the principal committer is one person, whether it is supported by commercial support, sponsorship, or donations.

### Implement an anti-corruption layer

The implementation that secures **modularity** for external dependencies is the **anti-corruption layer**. Place a thin layer that translates the vocabulary, types, and exceptions of the outside world into those of the domain, between the dependency and the domain. The aim is that when a vendor is replaced, **the language of the calling code** does not change (see also [Codifying Domain Terminology](/planning/terminology.md)).

**Where to draw** the anti-corruption layer is based on whether that dependency **might be replaced in the future**. Dependencies where the lifespan and compatibility initiative lies outside — databases, email sending, payments, authentication, AI providers, search engines, external APIs — are high-probability targets. Standard libraries, language runtimes, and in-house common utilities are typically not bounded.

**The responsibilities to put inside** the layer are these three:

- Name and type in domain vocabulary (e.g., `generateReply` rather than `fetchOpenAICompletion`).
- Translate vendor-specific exceptions and error codes into domain error types (not "throw an exception because a 504 was returned," but "a temporary failure of an external dependency").
- Place the correspondence between vendor types ↔ domain types together at the head of the layer, so the boundary between outside and inside can be followed at a glance.

**The disciplines to enforce on the outer form** are these three:

- Keep it as a thin wrapper with no domain logic; limit responsibility to **translation and delegation**. When conditional branching starts to grow inside, read it as domain logic leakage and move it back to the domain side.
- Keep the dependency direction one-way: ours → anti-corruption layer → theirs. When reverse dependencies where the anti-corruption layer depends on domain concrete types are found, invert them.
- Expose to the domain as abstractions (types, interfaces); inject the concrete implementation at the assembly stage. Match the placement approach to language conventions (in TypeScript, place under a vendor-dedicated directory to limit import paths; in Go, declare the interface on the domain side and inject the implementation across the package boundary, etc.).

When the anti-corruption layer is maintained in this form, the domain's unit tests pass with fake implementations alone, and tests that connect to actual external services are confined to the **anti-corruption layer side**.

### Leave room to exit managed services

When taking in a managed service or PaaS, do not bind business logic tightly to vendor-specific signatures, payloads, and formats. Receive in types and formats we define ourselves, keeping only the adapter on the vendor side.

- **Function hosting (AWS Lambda, Google Cloud Run, Cloud Functions, etc.)**: Do not start the handler directly from vendor-specific event signatures; implement as a function that receives our own `Request` / `Response` types, and confine the vendor-side adapter to input-output conversion alone. When migrating to another environment, only the adapter needs to be rewritten.
- **Cloudflare Workers**: Receiving with standard `Request` / `Response` is common Web platform practice. Use Cloudflare-specific storage such as KV, D1, and R2 through an anti-corruption layer, leaving room to swap to PostgreSQL, S3-compatible storage, etc. when migrating.
- **Queues (Amazon SQS, etc.)**: Do not place message payloads on SQS-specific attributes; pass as our domain message. Confine operational details such as long polling and visibility timeout to the queue adapter; write the worker side as a pure function that "receives one message and returns a result."

### Continuously review whether we can keep depending

The **monitoring plan** in the dependency decision log is a mechanism for asking, per dependency, "can we keep depending on this?"

Taking automated alerts such as GitHub Dependabot as a starting point, receive signals of vulnerability occurrence frequency, accumulating bug issues, and update stagnation. When signals accumulate, move toward a decision to reduce or switch the dependency, and append the action taken (update, workaround, risk acceptance, exit strategy activation) to the dependency decision log.

### Related: Testing

Related: [Active Use of Unit Tests](/implementation/test.md).
