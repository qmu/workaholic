---
name: policies
description: Index of the project's engineering policies — 設計 (design), 実装 (implementation), and 運用 (operations) — mirrored from the canonical articles at qmu.co.jp. Each entry gives the policy's title, a one-line summary of what it chooses and why, and a link to its article. Preloaded as the policy lens wherever work is scoped or implemented.
user-invocable: false
---

# Engineering Policies

This skill is the single index of the project's engineering policies. It replaces the four former `leading-*` lenses with one catalog mirrored from qmu.co.jp, so that a reader — human or agent — reaches every policy from one place, and so the index stays in step with the published articles rather than drifting across separate files.

The engineering policies are organized into three pillars: **設計** (how the product's interaction and experience are shaped), **実装** (how the code is structured), and **運用** (how the running system is kept serving, delivered to safely, and recovered). Security (安全) and working-practice (執務) policies live elsewhere on qmu.co.jp and are outside this index's scope.

Each entry names a policy, summarizes in one line what it chooses and why, and links to its canonical article. Read the full article for the policy's 目標 (the ideal it aims for), 責務 (the state it refuses to allow), and 実践 (concrete practices).

## Applying this index

When scoping or implementing a ticket, read the pillars its `layer` touches and apply the relevant policies. The mapping is a starting point, not a fence — a change usually touches more than one:

- **UX** → 設計, plus the アクセシビリティ viewpoint of 実装
- **Domain**, **DB** → 実装 (妥当性 viewpoint)
- **Infrastructure** → 実装 (可用性 viewpoint), plus 運用
- **Config** → the pillar whose policies the config touches

## 設計 — Design

How the product's interaction and experience are shaped — what users and AI agents can reach, and what they are never forced into. The counterpart to 実装, on the behavior side rather than the code-structure side.

- **[モードレス設計](https://qmu.co.jp/design/modeless-design)** — Keeping every action available without entering a special "mode", placing composability above step-by-step guidance, so users keep the freedom to assemble their own workflow; focus is introduced only where a task genuinely benefits from it.

## 実装 — Implementation

How the code is structured, viewed through three lenses: **妥当性** (logical comprehensiveness), **可用性** (operational continuity), and **アクセシビリティ** (reachability). Each article states which viewpoint it primarily serves.

### 妥当性 — Logical comprehensiveness

Making gaps in domain reasoning machine-checkable as early as possible.

- **[宣言的記述の推奨](https://qmu.co.jp/implementation/functional-programming)** — Writing declaratively wherever it is possible to, so behavior is predictable from a function's signature and preserved under composition; with generative AI as the default author, the compiler is treated as AI's most accurate and cheapest feedback path.
- **[厚い型付けの推奨](https://qmu.co.jp/implementation/type-driven-design)** — Narrowing each type's range of values to the domain's actual shape, introduced selectively where confusion or omission can occur — not over every value — so that expressing a new requirement in the existing type vocabulary doubles as a consistency check on the requirement itself.
- **[積極的な単体テスト活用](https://qmu.co.jp/implementation/test)** — Using unit tests actively in two roles — early scaffolding against real DBs/APIs, and regression tests kept in the domain layer — to widen the ground where AI itself can check completeness, while refusing to mistake "many AI-generated tests pass" for a healthy codebase.
- **[DB スキーマの先行設計](https://qmu.co.jp/implementation/persistence)** — Designing the DB schema before the domain model, with a properly normalized relational database as the first choice, so the schema outlines the space of states a coherent model can occupy.
- **[ドメイン層の分離](https://qmu.co.jp/implementation/domain-layer-separation)** — Separating business logic from entry points (HTTP routers, CLIs, queue workers) and writing it in standard-language vocabulary, keeping entry points thin so more is verifiable by static checks and unit tests and the domain layer is reusable across entry points.

### 可用性 — Operational continuity

Placing the system's ability to keep running, and to recover, in the codebase and its mechanisms rather than in an operator's reliability.

- **[消極的ベンダー依存](https://qmu.co.jp/implementation/vendor-neutrality)** — Managing dependencies on libraries, SDKs, SaaS, and managed infrastructure so no single vendor or project can strand the system; the aim is not to hand-write everything but to keep the freedom and the options to choose dependencies even after choosing them.
- **[コードとしてのインフラ](https://qmu.co.jp/implementation/infrastructure-as-code)** — Defining provisioned resources as version-controlled files reproducible from a clean state, so the current infrastructure can be fully rebuilt from code in the repository, avoiding console-only resources and long-lived drift.
- **[可観測性と自己修復](https://qmu.co.jp/implementation/observability)** — Keeping the running system explainable from outside and recovering without human intervention where possible, treating observation outputs (logs, metrics, traces) and self-healing inputs (health checks, rollback triggers, circuit breakers) as one subject.
- **[容量計画と復旧計画](https://qmu.co.jp/implementation/operational-planning)** — Holding "how much can it handle" and "how do we recover" in a simple form from the build stage, deriving RTO/RPO from concrete failure scenarios rather than abstract availability targets, without importing complexity through over-planning.

### アクセシビリティ — Reachability

Making information and function reachable through multiple paths — beyond the visual channel, and including AI agents.

- **[人間とAIのためのアクセシビリティ](https://qmu.co.jp/implementation/accessibility-first)** — Placing accessibility at the start of the experience and using standards conformance (WCAG 2.2 AA as the floor) as a foundation to raise quality; reachability is opened to AI agents too via tool-first interaction design, where typed tools are consumed by both the SPA and WebMCP under one contract.
- **[創発的な設計システム](https://qmu.co.jp/implementation/emergent-design-system)** — Letting the design system emerge through development rather than fixing a large one upfront; each new UI component introduces one rule for the screen–user interaction, and the engineer is the rule-maker at that boundary, enforcing consistency incrementally.

## 運用 — Operations

How written code is kept serving once it reaches production — delivery paths, runtime behavior, and recovery. The counterpart to 実装; where 実装's 可用性 viewpoint covers how code structure supports continuity, 運用 states the policy of operation itself.

- **[CI/CD 自動化](https://qmu.co.jp/operations/ci-cd)** — Automating the path from commit to deployment away from operators' memory, recording build/test/check/delivery as code in the repository, so the codebase can answer for itself whether a commit is deployable; established first as the ground of operation.
