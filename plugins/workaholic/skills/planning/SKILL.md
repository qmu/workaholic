---
name: planning
description: The project's planning (企画) engineering policies — how projects are initiated with proper understanding of the business, market, and legal context before design and implementation begin. English hard copies of the canonical qmu.co.jp articles live in this skill's `policies/` directory; this index links to each. Preloaded as the policy lens wherever new features or projects are scoped.
user-invocable: false
---

# Planning Policies

This skill is the project's index of **企画 (planning)** engineering policies — how projects are initiated with proper grounding in business context, market understanding, and legal requirements before design and implementation begin.

Each policy is mirrored from its canonical article at qmu.co.jp as an English hard copy under [`policies/`](policies/). The published article is the source of truth; the local copy is how this platform and our website share the same knowledge. Read a policy's file for its full **Goal (目標)**, **Responsibility (責務)**, and **Practices (実践)**. The `source:` field in each file's frontmatter links back to the canonical article.

## Policies

- **[Industry Research and Market Survey](policies/market-research.md)** (業界研究・市場調査) — Studying the client's industry, market structure, and actual business operations before starting a project, to ground design and implementation in verified understanding rather than assumed requirements.
- **[Requirements Analysis through Modeling](policies/modeling-centric-design.md)** (モデリングを通した要求分析) — Analyzing requirements by abstracting reality into models that capture stakeholders, events, data, demands, pain points, and solutions, placing this shared model as the foundation for all subsequent design and implementation.
- **[Codifying Domain Terminology](policies/terminology.md)** (固有表現の辞書化) — Collecting established project terms into a dictionary with one word per concept, used consistently across code, documents, commits, diagrams, and conversation to keep the codebase self-explanatory for humans and AI agents alike.
- **[Accessibility Open to AI](policies/accessibility-first.md)** (AIにも開くアクセシビリティ) — Placing accessibility at the start of the experience, holding WCAG 2.2 AA as the floor, and opening the product to AI agents as both operators and information consumers alongside human users.
- **[Planning with A2A in Mind](policies/ai-native-future.md)** (A2Aを見据えた構想) — Building in the premise that software users will include AI agents as well as humans, ensuring AI-driven processes remain observable and interruptible by humans.
- **[Proactive PoC Proposals](policies/proactive-poc.md)** (PoCの積極提案) — Actively proposing proof-of-concept work for high-uncertainty areas before full development begins, reducing investment risk by validating early with small, disposable builds.
- **[UX Research through Prototypes](policies/ux-research-prototype.md)** (プロトタイプによるUX調査) — Verifying requirements through working prototypes that clients and users can try, surfacing misalignments between stated requests and actual experience before design solidifies.
- **[Legal Compliance Verification](policies/legal-compliance-check.md)** (法令の確認と順守) — Enumerating applicable laws and regulatory requirements before design begins, so legal constraints are a shared premise rather than a late discovery.
- **[Cost Estimation Methods](policies/cost-estimation.md)** (コスト試算方法の検討) — Building cost estimates on explainable foundations that account for AI productivity variability, state scope boundaries clearly, and present uncertainty as ranges rather than single figures.
- **[Upfront IT Investment Evaluation](policies/it-investment-evaluation.md)** (IT投資評価の事前実施) — Evaluating IT investment from a return-on-investment perspective before proposals, so clients can make informed decisions about scope rather than being pushed toward larger orders.
- **[Demonstrating Capability over Track Record](policies/capability-over-track-record.md)** (実力のアピールに努める) — Demonstrating capability through the real thing at hand — a working PoC, concrete design reasoning, and the service itself — rather than listing past achievements, so that the motivation to build stays aligned with client and user value.

## Applying this index

Apply these policies when beginning a new project or feature — before design and implementation begin. The mapping is a starting point, not a fence; planning work touches domain knowledge that also informs [design](../design/SKILL.md) and [implementation](../implementation/SKILL.md) policies.
