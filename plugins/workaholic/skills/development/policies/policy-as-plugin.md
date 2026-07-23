---
title: Policy as Plugin
slug: policy-as-plugin
category: development
source: https://qmu.co.jp/development/policy-as-plugin
---

# Policy as Plugin

_Distributing planning, design, implementation, and operation policies as Claude Code / Codex plugins so that our standards are already in the model's working context when AI writes code._

We distribute our planning, design, implementation, and operation policies as plugins for Claude Code and Codex, creating a state in which our policies are already in the model's working context when a developer's AI is running. Leaving policies only as documents weakens their effect on AI-generated code. Documents are a medium for humans to recall at review time, but in a firm where generative AI is the default development tool (see [Active Use of Generative AI](ai-utilization.md)), unless the policy is delivered to the model at the moment code is being written, output conforming to our standards does not emerge from the start. Plugins are the carrier that deliver document content into the model's working context.

## Goal (目標)

We aim for a state in which, at the very moment the model is writing code, assembling a product, and keeping it running, our planning, design, implementation, and operation policies are already in the model's working context. Documents and plugins are aligned to the same version, and the AI running on a developer's machine builds its output starting from our standards.

## Responsibility (責務)

Our responsibility is to prevent a state in which the plugin's silence is used as evidence that no policy violation occurred. When everything is packed into plugins without discrimination, the distinction between what plugins can reach and what humans and process must protect becomes blurred. The correct scope of areas where plugins are supposed to be watching gets confused, and the plugin's silence comes to be treated as proof of conformance — we prevent that state.

## Practices (実践)

### Scope plugin content to planning, design, implementation, and operation

Our policies are divided into six series — planning, design, implementation, operation, safety, and development — but we plugin only the four series of planning, design, implementation, and operation. These are the series that directly shape what the model assembles and how it keeps it running, and they appear directly in generation output.

Implementation policies govern how code should be structured, and are the series referenced at the very moment the model writes code. Design policies govern how the product's interactions and experience should behave; when the model produces UI or typed tools, design decisions such as modeless-first or holding state in the URL appear directly in output. Operation policies govern how software should be kept running, how changes should be delivered safely, and how to recover from failure. Planning policies establish the premises for what to build — codified terminology, requirement analysis through modeling, accessibility, and the assumed set of users including AI agents — and these flow into generation output through naming, structure, screen and markup, and interface design respectively.

Development policies (AI usage guidelines, how to reach agreement with clients, how to manage change history, meeting recordings) are in the domain of agreements and operations between people. They are not what coding AI should fulfil; they are what developers read in the documents and reflect in project setup. Safety policies (information security policy, privacy policy, security standards) are documents tied to ISMS controls and organizational responsibility. They are not protected by technical hooks but by organizational operation and audit.

Keeping this scope unambiguous — limiting plugins to planning, design, implementation, and operation — is what keeps the boundary between what plugins can reach and what humans and process must protect visible.

### Plugins do not substitute for design judgment

Plugins do not automate design judgment. Choices about type-driven design and where to draw layer separations are ultimately the developer's judgment. What plugins provide is this and nothing more: bringing our standards into the starting point of the model's output. Quality responsibility does not decrease either. Even for AI-written code, the quality of what goes into the world is borne by each developer's own QA (consistent with [Code Review as a Non-Default Practice](review.md) and [Active Use of Generative AI](ai-utilization.md)). "The plugin didn't flag it, so it passes" is not a standard — plugins are treated as supplementary lines for the design dialogue.

### Update documents and plugins in the same PR

When planning, design, implementation, or operation policies are revised, if the plugin side's skill or agent remains at the old version, a divergence arises between the document and the AI's generation tendency. If the document side moves ahead, there is a state of "written but not implemented"; if the plugin side moves ahead, there is a state of "implemented but unexplained" — in either case, it becomes impossible to explain when applying to a project. To avoid this, policy document changes and plugin changes are aligned in the same PR review.

### Standardize the structure of policy articles to a common form

Plugins can deliver documents to the model's context because every article can be read in the same order. Our policy articles share a common section structure regardless of series: a frontmatter description (one-line summary), a short title (H1) condensing the central viewpoint, a lead paragraph showing the policy, Goal (目標), Responsibility (責務), and Practices (実践), in that order.
