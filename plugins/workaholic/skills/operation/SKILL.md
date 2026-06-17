---
name: operation
description: The project's operation (運用) engineering policies — how written code is kept serving once it reaches production: delivery paths, runtime behavior, and recovery. English hard copies of the canonical qmu.co.jp articles live in this skill's `policies/` directory; this index links to each. Preloaded as the policy lens wherever delivery or runtime work is scoped or implemented.
user-invocable: false
---

# Operation Policies

This skill is the project's index of **運用 (operation)** engineering policies — how written code is kept serving once it reaches production: delivery paths, runtime behavior, and recovery. The counterpart to [implementation](../implementation/SKILL.md); where implementation policies cover how code structure supports continuity, operation states the policy of operation itself.

Each policy is mirrored from its canonical article at qmu.co.jp as an English hard copy under [`policies/`](policies/). The published article is the source of truth; the local copy is how this platform and our website share the same knowledge. Read a policy's file for its full **Goal (目標)**, **Responsibility (責務)**, and **Practices (実践)**. The `source:` field in each file's frontmatter links back to the canonical article.

## Policies

- **[CI/CD Automation](policies/ci-cd.md)** (CI/CD 自動化) — Automating the path from commit to deployment away from operators' memory, recording build/test/check/delivery as code in the repository, so the codebase can answer for itself whether a commit is deployable; established first as the ground of operation.
- **[No Customer Support in the Repository](policies/no-customer-support-in-repo.md)** (リポジトリ内CS対応の禁止) — Routing customer support communication through a dedicated support channel rather than the GitHub issue tracker, keeping the engineering backlog and the support queue separate.
- **[AI-Assisted Production Investigation](policies/ai-production-investigation.md)** (AIによる本番環境調査) — Using AI agents to accelerate production diagnosis under a read-only access constraint, with all agent actions logged and proposed production changes reviewed by a human before execution.

## Applying this index

Apply these policies when a ticket touches the **Infrastructure** layer — alongside the [implementation](../implementation/SKILL.md) policies. The mapping is a starting point, not a fence; a change usually touches more than one category.
