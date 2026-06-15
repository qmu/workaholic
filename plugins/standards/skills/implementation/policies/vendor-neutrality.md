---
title: Conservative Vendor Dependence
slug: vendor-neutrality
category: implementation
source: https://qmu.co.jp/implementation/vendor-neutrality
---

# Conservative Vendor Dependence — Keep the Freedom to Choose Your Dependencies, Even After You Have Chosen

Our development environment and the artifacts we build stand on top of a great many pieces of open-source software (OSS). Compilers, runtimes, libraries, databases, CI tools, editors — every one of them is the product of developers around the world who have devoted their time to create them, released them free of charge, and continue to maintain them. The fact that we can deliver software to our customers today is owed entirely to the existence of those projects and their contributors.

At the same time, as social engineering and AI-driven vulnerability scanning grow ever more sophisticated, the risks across the OSS supply chain are becoming more serious year by year. Apart from security, there are also recurring occasions on which we want to switch away from a dependency: version upgrades that come with breaking changes, the cessation of maintenance, migration to a more competitive alternative, and so on.

If we regard these as problems, then it would be fair to say that the fewer dependencies the better — yet writing everything ourselves is not realistic, and we will continue to need to depend on OSS, SaaS, and managed services going forward. This policy therefore aims to **hold on to the freedom and the options for choosing dependencies, without letting them go**. Concretely, this means securing modularity and portability.

There are two kinds of interface with external dependencies. One is the boundary that arises **inside the code** — libraries, SDKs, drivers, and the like — and the other is the boundary that arises **outside the code** — SaaS, delivery destinations, data storage locations, and so on. For the former, we secure **modularity** that partitions off the external dependency through code structure. For the latter, we secure **portability** that leaves room to migrate to another environment.

## Goal (目標)

The situation this policy aims to achieve is not the careful handling of external dependencies in itself, but rather a state in which **sustainable software production holds**. The daily practices (selecting, isolating, and devising exit strategies for dependencies) are positioned as means that support this higher-order goal.

To be sustainable, we believe it is not enough merely to receive from the ecosystem. We want to keep a part of the foundation that forms the core of our products as something we publish and maintain ourselves, securing it as a domain that is not swayed by external decisions. The practice we undertake to that end is **plgg** — a functional-programming toolkit that includes the Result type, the Option type, pipeline composition, brand types, an AI-workflow foundation, and more. We are developing it as a foundation that lets us keep growing the substrate of types and the control-flow vocabulary underpinning our products in line with our own domain, rather than entrusting them to external decisions.

The contours of the goal are as follows.

- The freedom and the options for choosing external dependencies remain intact over time, undiminished.
- We hold a part of the foundation that forms the core of our products in a form that we publish and maintain ourselves.
- We do not merely keep receiving from OSS; we also stand on the side of giving back, in the form of publishing and contributing.
- Domain reasoning can be grown without being bound to the shape of the infrastructure adopted at any given moment.

## Responsibility (責務)

The situations this policy aims to prevent are shown along the following two axes.

- A state in which we are deeply bound to a particular vendor or tool, so that migration or switching is no longer realistic.
- A state in which our coupling to an adopted managed service is too deep, so that we cannot switch over to another option.

Regarding the former: for example, the version upgrade from CakePHP 2 to 3 contained breaking changes, and migrating a system built on version 2 to version 3 was no easy matter. This kind of lock-in has become less frequent in recent years than before, but as something that can happen for as long as we depend deeply on a particular technology, we want to prepare for it from the design stage onward.

Regarding the latter: for example, when a managed service we depend on raises its prices, it is possible to face a situation in which our coupling to the proprietary resources, features, and APIs it provides is too deep for us to leave. Even if a vendor changes its terms of use, operating policy, pricing, or form of provision, we want to keep ourselves in a state where we can switch over to a better service — that is the aim of this responsibility.

## Practices (実践)

### As a rule, implement it ourselves (原則的に自分たちで実装する)

When building a new feature, we make implementing it ourselves the first choice. With the spread of AI coding agents, even ranges that we have hitherto relied on external libraries for have become ones we can foresee writing ourselves, and the motivation to pile on dependencies for the sake of trivial features is fading. Only when we can judge that an in-house implementation is not optimal do we rely on external libraries and services, in accordance with §Practices, *Criteria for relying on external libraries and services*.

### Keep a dependency-decision log (依存判断ログをつける)

When we take on a new dependency, we document the following four points as a **dependency-decision log** and leave it in the repository.

- **Reason (理由):** Why is this dependency necessary? Which of our problems does it solve, and how?
- **Assessment (点検):** The results of examining it from the standpoints of license, reputation, development status, and sustainability (for each standpoint, see §Practices, *Verify the reputation of what you depend on*).
- **Monitoring plan (監視計画):** The standpoints from which we will keep re-asking, after taking it on, whether we can continue to depend on it. Vulnerabilities, the stagnation of bug Issues, the cessation of updates, license changes, and so on.
- **Exit strategy (撤退戦略):** How to switch over if migration becomes necessary. Candidate alternatives, the scope of impact (which layers and modules are affected), and the order of magnitude of the anticipated effort (person-days / person-weeks / person-months / person-years).

We are advancing the automation of producing this dependency-decision log in the workaholic plugin (related ticket).

So that it is easy to refer to within this article, the format of the log is shown below. In actual operation we use this shape as a base, adding or removing items according to the nature of the project and the dependency.

```
## Dependency: <library / SaaS name>
- Adoption commit: [<short hash>](<commit URL>)
- Adoption date: YYYY-MM-DD
### Reason (理由)
<why this dependency is necessary, which of our problems it solves, and how>
### Assessment (点検)
- License: <the license name and the judgment of its compatibility with our use>
- Reputation: <usage track record, community recognition compared with equivalent projects>
- Development status: <update frequency over the past year, release cadence, trend in open Issues, maintainer responsiveness>
- Sustainability: <composition of the principal committers; whether supported by commercial support, sponsorship, donations, etc.>
### Monitoring plan (監視計画)
- Standpoints: <vulnerabilities, stagnation of bug Issues, cessation of updates, license changes, etc.>
- Review frequency: <quarterly / semiannually, etc.>
### Exit strategy (撤退戦略)
- Candidate alternatives: <candidate libraries / services>
- Scope of impact: <affected layers / modules>
- Anticipated effort: <person-days / person-weeks / person-months / person-years>
```

### Criteria for relying on external libraries and services (外部ライブラリやサービスに頼る際の基準)

Under §Practices, *As a rule, implement it ourselves*, the standpoints by which we judge whether or not to rely on an external library or service are listed below. We treat clearly satisfying any one of them as grounds for relying on it.

- **A specialized domain where a mistake is fatal, or one far from our core:** A domain where, even if we have the technical ability to write it ourselves, getting the details wrong is fatal; or a domain where it is unrealistic to maintain knowledge of equivalent depth in-house. Cryptography libraries, timezone databases, Unicode normalization, PDF / video codecs, OS / cross-browser compatibility, and the like fall here, and we let ourselves ride on what a worldwide community of specialists maintains. In many cases this comes down to plainly using the language's standard library or platform-provided features.

- **Interoperability / protocol conformance:** A domain where we want to ride on OSS, together with its verification of conformance to the specification, for the protocol layer needed to communicate accurately with other services. HTTP / TLS clients, OAuth / OIDC libraries, gRPC implementations, and the like fall here, and contributors around the world continuously guarantee conformance to the RFCs / specifications. An in-house implementation would only increase compatibility risk and offers no benefit in the sense of protocol conformance.

- **Cost and time efficiency:** A domain where writing it ourselves is markedly poor in cost and time efficiency. React, Vue, off-the-shelf web server libraries, and the like fall here, and reimplementing them ourselves does not pay off. By riding on off-the-shelf products, we make it possible to spend time on the problems specific to our own domain.

- **A domain that brings in a capability we cannot reach on our own:** A domain where taking it on lets us add to our software a capability that we could not reach on our own. In OSS, the Monaco Editor for code-editor components, React Flow for node-and-edge manipulation UI, and so on. In SaaS / managed services, Stripe, which provides global payment infrastructure, and so on. When there is no foreseeable path to reach an equivalent level ourselves, we let ourselves take in the external work and redirect our time to the problems specific to our own domain.

### Verify the reputation of what you depend on (依存先のレピュテーションを確かめる)

The standpoints we verify in the **Assessment (点検)** of §Practices, *Keep a dependency-decision log*, are as follows. We look at OSS and managed services alike within the same framework.

- **License:** Is it compatible with our use? Has there been any history of license changes in the past?
- **Reputation (評判):** Usage track record; community recognition compared with other projects serving the same role.
- **Development status:** Update frequency over the past year, the cadence of releases, the trend in open Issues, maintainer responsiveness.
- **Sustainability (サステナビリティ):** Is maintenance continuing even if there is only one principal committer? Is it supported by commercial support, sponsorship, or donations?

### Implement an anti-corruption layer (腐敗防止層を実装する)

The implementation for securing **modularity** against external dependencies is the **anti-corruption layer (Anti-Corruption Layer)**. We place a thin layer between the dependency and the domain that translates the vocabulary, types, and exceptions of the outside world into those of the domain. The aim is that even when we swap out a vendor, the **language of the code** on the calling side does not change (see also *Respect for the domain's own expression*).

**Where to draw** the anti-corruption layer is decided on the basis of **whether that dependency may be swapped out in the future**. Dependencies whose lifespan and compatibility are controlled externally — databases, email sending, payments, authentication, AI providers, search engines, external APIs — are highly likely to be targets. Standard libraries, the language runtime, and in-house shared utilities are not usually given a boundary.

The **responsibilities to give to the contents** of the layer are the following three.

- Name and type things in the domain's terms (e.g. `generateReply`, not `fetchOpenAICompletion`).
- Translate vendor-specific exceptions and error codes into domain error types ("a transient failure of an external dependency," not "throw an exception because a 504 came back").
- Place the correspondence between vendor types ↔ domain types together at the head of the layer, so that the boundary between outside and inside can be followed at a glance.

The **discipline to enforce on the outer form** of the layer is the following three.

- Keep it a thin wrapper that holds no domain logic, narrowing its responsibility to **translation and delegation**. When conditional branching starts to grow inside it, read that as a leak of domain logic and return it to the domain side.
- Keep the direction of dependence unidirectional: ours → anti-corruption layer → theirs. If you find a reverse dependency in which the anti-corruption layer depends on the domain's concrete types, invert it.
- Expose it to the domain as an abstraction (a type / interface), and inject the concrete implementation at the assembly stage. Take the manner of placement to match the conventions of the language (in TypeScript, place it under a vendor-dedicated directory and limit the import paths; in Go, declare the interface on the domain side and inject the implementation at the package boundary; and so on).

When the anti-corruption layer is kept in the above shape, the domain's unit tests pass green with fake implementations, and the tests that connect to the actual external service are confined **to the anti-corruption layer side** (see also the relevant section of *Testing*).

### Leave room to leave a managed service (マネージドサービスの離脱余地を残す)

When taking on a managed service or PaaS, we do not glue the business logic tightly to the vendor-specific signatures, payloads, and formats; we receive it in types and formats we have defined ourselves, and place only an adapter on the vendor side.

- **Function hosting (AWS Lambda / Google Cloud Run / Cloud Functions, etc.):** Do not start writing the handler directly from the vendor-specific event signature; implement it as a function that receives our own Request / Response types, and confine the vendor-side adapter to input/output conversion alone. When migrating to another environment, all that needs rewriting is the adapter.
- **Cloudflare Workers:** Receiving with the standard Request / Response is, as far as it goes, a practice common to the web platform. Use proprietary storage such as KV, D1, and R2 across an anti-corruption layer, leaving room to swap in PostgreSQL, S3-compatible storage, and the like at migration time.
- **Queues (Amazon SQS, etc.):** Do not put the message payload onto SQS-specific attributes; pass it as our own domain message. Confine operational details such as long polling and visibility timeout to the queue adapter, and write the worker side as a pure function that "receives one message and returns a result."

### Continuously review whether you can keep depending on it (依存し続けられるかを継続的に見直す)

The **Monitoring plan (監視計画)** of §Practices, *Keep a dependency-decision log*, is the mechanism for re-asking, per dependency, "can we continue to depend on this going forward?"

Starting from automated alerts such as GitHub Dependabot, we receive signs such as the frequency of vulnerabilities, the stagnation of bug Issues, and the cessation of updates. When the signs accumulate, we proceed to a judgment in the direction of reducing the dependency or switching over, and we append the response we took (an update, a workaround, accepting the risk, or triggering the exit strategy) to the dependency-decision log.
