---
name: development
description: The project's development (開発) engineering policies — how developers work with generative AI day to day: client agreements for AI data handling, distributing policies as plugins, managing change history, voice input, meeting recordings, overnight AI runs, quota utilization, the non-default code review stance, the generalist model, QA ownership, and the code of conduct. English hard copies of the canonical qmu.co.jp articles live in this skill's `policies/` directory; this index links to each. Referenced when setting up a new project or reviewing how the team works with AI.
user-invocable: false
---

# Development Policies

This skill is the project's index of **開発 (development)** engineering policies — how developers work with generative AI day to day, from client agreements on data handling to overnight autonomous runs, and the conduct that holds the team together.

Each policy is mirrored from its canonical article at qmu.co.jp as an English hard copy under [`policies/`](policies/). The published article is the source of truth; the local copy is how this platform and our website share the same knowledge. Read a policy's file for its full **Goal (目標)**, **Responsibility (責務)**, and **Practices (実践)**. The `source:` field in each file's frontmatter links back to the canonical article.

## Policies

- **[Active Use of Generative AI](policies/ai-utilization.md)** (生成AIの積極活用) — Treating AI-assisted code generation as the default development approach, with explicit written client agreements on which data may enter which AI services before a project begins.
- **[Policies Distributed as Plugins](policies/policy-as-plugin.md)** (ポリシーのプラグイン化) — Distributing planning, design, implementation, and operation policies as Claude Code / Codex plugins so that the model's working context already includes our standards when AI is writing code.
- **[Maintaining the Capacity to Generate Explanations](policies/explanations-on-demand.md)** (説明を生成できる状態を保つ) — Directing effort toward storing information structurally in the repository rather than polishing finished deliverables, so that explanations tailored to any reader can be generated from that foundation at any time.
- **[Preserving Change History in Files](policies/commit-change-history.md)** (変更経緯をファイルで残す) — Storing tickets, stories, and release notes as markdown files in the repository alongside code, so that the rationale behind each change is retrievable from the same clone as the code itself.
- **[Active Use of Voice Input](policies/voice-input.md)** (音声入力の積極活用) — Using voice input in place of keyboard entry when conveying design intent or exploring ideas with AI agents, to keep the speed of thought aligned with the speed of input.
- **[Transcribing Client Meetings](policies/meeting-recording.md)** (お打ち合わせの文字起こし) — Recording client meetings with prior consent and converting them to searchable transcripts, so that the decision-making process is preserved as a shared record for both client and team.
- **[Preparing for Overnight AI Operation](policies/overnight-ai.md)** (終業後の稼働に備える) — Structuring the workday around creating well-specified tickets and pre-answering anticipated judgment calls so AI can run uninterrupted through the night.
- **[Making Full Use of the Weekly Quota](policies/weekly-quota.md)** (定額利用枠を使い切る) — Treating the prepaid weekly AI subscription quota as a fixed cost that should produce value before reset, directing unused capacity toward overnight runs, refactoring, security checks, and research.
- **[Code Review as a Non-Default Practice](policies/review.md)** (レビューの原則非実施) — Removing code review from the default development workflow in favor of policy-grounded generation and each developer's own QA, with mutual awareness maintained through generated stories and commit logs.
- **[One Person Covers All Layers](policies/generalist.md)** (1名で全レイヤーを担う) — Having one implementer carry design, implementation, operation, and QA end-to-end, with AI as a co-pilot, so that cross-layer feedback loops close within a single person without handoff.
- **[Implementers Own Quality Assurance](policies/qa-engineering.md)** (実装者が品質保証を担う) — Having the developer who makes a change also plan, execute, and improve the QA for that change, rather than delegating quality assurance to a separate later stage.
- **[Code of Conduct](policies/code-of-conduct.md)** (行動規範) — The good-faith obligations that developers participating in a project fulfil: client-first decision-making, truthful and objective explanation, confidentiality, respect for diversity, and care for health.

## Applying this index

Apply these policies when onboarding to a project or revisiting how the team works with generative AI. These policies govern the human side of development — agreements, habits, and conduct — rather than what code to produce. They sit alongside the [planning](../planning/SKILL.md), [design](../design/SKILL.md), [implementation](../implementation/SKILL.md), and [operation](../operation/SKILL.md) policies that govern what the AI produces.
