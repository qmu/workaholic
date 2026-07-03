---
name: design
description: The project's design (設計) engineering policies — how the product's interaction and experience are shaped, what data is handled with what access controls and sovereignty guarantees, how external dependencies are chosen, and what users and AI agents can reach without force. English hard copies of the canonical qmu.co.jp articles live in this skill's `policies/` directory; this index links to each. Preloaded as the policy lens wherever UX, security design, or API work is scoped or implemented.
user-invocable: false
---

# Design Policies

This skill is the project's index of **設計 (design)** engineering policies — covering interaction and experience design, security design, data handling and sovereignty, external dependency choices, and API design. The pillar now has 17 policies, on the behavior and structure side rather than the code-implementation side.

Each policy is mirrored from its canonical article at qmu.co.jp as an English hard copy under [`policies/`](policies/). The published article is the source of truth; the local copy is how this platform and our website share the same knowledge. Read a policy's file for its full **Goal (目標)**, **Responsibility (責務)**, and **Practices (実践)**. The `source:` field in each file's frontmatter links back to the canonical article.

## Policies

- **[Modeless Design](policies/modeless-design.md)** (モードレス設計) — Making modelessness the design starting point and introducing modals only where concentration is truly warranted, so users and AI agents can reach any operation without navigating mode state.
- **[Cautious Consideration of Distributed Systems](policies/modular-monolith-first.md)** (分散システムの慎重検討) — Using managed services as development scaffolding while keeping the deployment unit as a single modular monolith; splitting into separate services only when the boundary is justified and the rationale is documented.
- **[Proactive Consideration of Sacrificial Architecture](policies/sacrificial-architecture.md)** (犠牲的アーキテクチャの積極検討) — Designing module boundaries along rebuildable units so that discarding and rebuilding a part is a normal option alongside incremental change, especially in early project stages when requirements are still fluid.
- **[Authentication and Authorization Procurement Policy](policies/auth-procurement.md)** (認証・認可機能の調達方針) — Evaluating existing authentication and authorization solutions before building, because the security surface of a custom implementation is wide and the failure modes are severe.
- **[Access Control Mechanism Selection](policies/access-control.md)** (アクセス制御機構の使い分け) — Choosing the access control mechanism proportionate to the actual authorization requirements, starting simple and escalating only when a simpler model cannot express the needed rules.
- **[Security Considered in Layers](policies/defense-in-depth.md)** (セキュリティの多層的検討) — Designing security as a set of independent controls at the network, application, data, and process layers so that the breach of any single layer does not expose the system.
- **[Respecting User Data Sovereignty](policies/data-sovereignty.md)** (利用者データ主権の尊重) — Building export, deletion, and data-use transparency as first-class features so users retain meaningful control over their own data.
- **[Conservative Vendor Dependence](policies/vendor-neutrality.md)** (外部依存の消極検討) — Evaluating the cost of exit before adopting an external service, keeping the integration boundary thin, and avoiding design decisions that amplify switching costs beyond what the service's value justifies.
- **[UI That Requires No Manual](policies/self-explanatory-ui.md)** (マニュアルを要しないUI) — Designing every interface element so that its purpose and correct usage are apparent from the element itself; if a manual is needed to explain a screen, the screen needs redesign.
- **[Elimination of Dark Patterns](policies/no-dark-patterns.md)** (ダークパターンの排除 ) — Identifying and removing interface patterns that manipulate attention, obscure choices, or make it harder for users to do what they actually want to do.
- **[Recording of Policy Changes and Consent](policies/consent-recording.md)** (規約変更と同意の記録) — Recording the version of terms and policies each user consented to, and re-obtaining consent when material changes occur, as an auditable trail.
- **[Isolation of Administrative Functions](policies/admin-isolation.md)** (管理系機能の隔離) — Keeping administrative functions on a separate surface with a separate authentication path so that a compromised user credential does not expose administrative operations.
- **[Careful Consideration of Email Sending](policies/email-sending-restraint.md)** (メール送信機能の慎重検討) — Evaluating each proposed email trigger deliberately, because unsolicited or unexpected email erodes deliverability and trust, and the operational surface of email is wider than it first appears.
- **[Proactive Consideration of Per-Tenant Databases](policies/per-tenant-database.md)** (テナント別DBの積極検討) — Evaluating the database isolation model for multi-tenant products early in design, since strong tenant isolation is much cheaper to build in than to retrofit after data has accumulated.
- **[Proactive Introduction of History Structures](policies/history-structures.md)** (履歴構造の積極導入) — Designing data structures to preserve state transitions as history from the start, so that audit, re-consent recording, and temporal reasoning questions can be answered from the accumulated data.
- **[REST-Oriented API Design](policies/rest-api-design.md)** (REST基調のAPI設計) — Designing HTTP APIs around resources and standard HTTP semantics so the API is predictable for humans and AI agents without prior knowledge of the system.
- **[Interactive Design Standards](policies/interaction-design-standard.md)** (インタラクティブ・デザイン標準) — Standardizing the interactive behaviors of components — loading, error, empty, and success states — so users learn the product once rather than re-learning each screen.

## Applying this index

Apply these policies when a ticket touches the **UX** layer — alongside the [implementation](../implementation/SKILL.md) policies. The mapping is a starting point, not a fence; a change usually touches more than one category.
