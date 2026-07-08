---
title: Policies Distributed as Plugins
slug: policy-as-plugin
category: development
source: https://qmu.co.jp/development/policy-as-plugin
---

# Policies Distributed as Plugins

_Distributing all six policy series — planning, design, implementation, operation, development, and safety — as Claude Code / Codex plugins so that our standards are already in the model's working context when AI writes code._

We distribute all six series of our policies — planning, design, implementation, operation, development, and safety — as plugins for Claude Code and Codex, creating a state in which our policies are already in the model's working context when a developer's AI is running. Leaving policies only as documents weakens their effect on AI-generated code. Documents are a medium for humans to recall at review time, but in a firm where generative AI is the default development tool (see [Active Use of Generative AI](ai-utilization.md)), unless the policy is delivered to the model at the moment code is being written, output conforming to our standards does not emerge from the start. Plugins are the carrier that deliver document content into the model's working context.

## Goal (目標)

We aim for a state in which, at the very moment the model is writing code, assembling a product, and keeping it running, all six series of our policies are already in the model's working context. Documents and plugins are aligned to the same version, and the AI running on a developer's machine builds its output starting from our standards.

## Responsibility (責務)

Our responsibility is to prevent the operation from sliding into one where the plugin's silence is used as evidence that no policy violation occurred.

Even when all six series are synchronized to the model's context, the range that plugins deliver (standards that enter the model's context) and the range that humans, process, and organizational operations protect (developer agreements and ISMS control fulfillment) are not the same. Keeping this distinction and not using plugin silence as grounds for "no policy violations" — this is the state we prevent.

## Practices (実践)

### Plugins cover all six policy series

Our policies are divided into six series — planning, design, implementation, operation, development, and safety — and all six series are synchronized as plugins into the model's working context. Series that directly appear in generation output and series that govern how people and organizations operate are both delivered to make the model operate with awareness of our standards.

Implementation policies govern how code should be structured, and are the series referenced at the very moment the model writes code. Whether type-driven, whether layer separation is drawn, whether external dependencies are considered conservatively, whether WCAG is satisfied — these appear in the code's form itself.

Design policies govern how the product's interactions and experience should behave. When the model produces UI or typed tools, design decisions such as starting from modeless or holding state in the URL appear directly in output.

Operation policies govern how software should be kept running, how changes should be delivered safely, and how to recover from failure. When the model generates CI/CD pipelines, rollback paths, or observation setups, decisions such as whether deploys are routed through automated paths and whether rollback is prepared as code appear in output.

Planning policies establish the premises for what to build — codified terminology, requirement analysis through modeling, accessibility, and the assumed set of users including AI agents. These flow into generation output through naming, structure, screen and markup, and interface design.

Development policies (AI usage guidelines, how to reach agreement with clients, how to manage change history, meeting recordings) are in the domain of agreements and operations between people. They are not what coding AI should fulfil at that moment, but are synchronized so the model can operate with awareness of our development approach.

Safety policies (information security policy, privacy policy, security standards) are tied to ISMS controls and organizational responsibility. Their guarantee is borne by organizational operation and audit, but are synchronized so the model can generate with awareness of our security standards.

Even when all six series are synchronized, the range that plugins deliver (standards that enter the model's context) and the range that humans, process, and organizational operations protect (developer agreements and ISMS control fulfillment) are not the same. Maintaining this distinction and not using plugin silence as grounds for "no policy violations" is the position we maintain.

### Plugins do not substitute for design judgment

Plugins do not automate design judgment. Choices about type-driven design and where to draw layer separations are ultimately the developer's judgment. What plugins provide is this and nothing more: bringing our standards into the starting point of the model's output. Quality responsibility does not decrease either. Even for AI-written code, the quality of what goes into the world is borne by each developer's own QA (consistent with [Code Review as a Non-Default Practice](review.md) and [Active Use of Generative AI](ai-utilization.md)). "The plugin didn't flag it, so it passes" is not a standard — plugins are treated as supplementary lines for the design dialogue.

### Update documents and plugins in the same PR

When any policy is revised, if the plugin side's skill or agent remains at the old version, a divergence arises between the document and the AI's generation tendency. If the document side moves ahead, there is a state of "written but not implemented"; if the plugin side moves ahead, there is a state of "implemented but unexplained" — in either case, it becomes impossible to explain when applying to a project. To avoid this, policy document changes and plugin changes are aligned in the same PR review. What is aligned includes plugins for both Claude Code and Codex; if one agent's plugin is at the new version while the other is left at the old version, the ability to continue running with the alternative agent in case of failure is weakened (see [Maintaining Use of Multiple AIs](multiple-ai-use.md)).

### Standardize the structure of policy articles to a common form

Plugins can deliver documents to the model's context because every article can be read in the same order. Our policy articles share a common section structure regardless of series: a frontmatter description (one-line summary), a short title (H1) condensing the central viewpoint, a lead paragraph showing the policy, Goal (目標), Responsibility (責務), and Practices (実践), in that order.

The title is a short name without a dash continuing to a description; the lead paragraph does not start by repeating the title name but starts from the content of the policy.

The Goal section writes the ideal state to be reached (a Liveness property — "X will eventually hold") in positive prose as "X is holding." The Responsibility section writes the state that must not occur (a Safety property — "bad state never occurs") as the line we prevent. The Practices section expands the individual policies and daily practices that support the two preceding sections, as much as needed.

Goal and Responsibility are written in prose without bullet points, and sentences within those sections are not bolded in the middle of a paragraph (see [Objective Technical Documentation](../../implementation/policies/objective-documentation.md)). A standalone section titled "attitude to avoid" or similar is not set up; what we want to prevent goes in the Responsibility section, and how we view other approaches goes in the Practices prose.

```
---
description: Summarize in one line what this article selects, why, and what it aims for.
---

# Title

Lead paragraph: show the policy this article covers. State what is chosen and why, leading the reader into the following sections.

## Goal (目標)
Write the ideal state to be reached (Liveness) in positive prose.

## Responsibility (責務)
Write the state that must not occur (Safety) as the line we prevent.

## Practices (実践)
Expand the individual policies and daily practices that support the two preceding sections, as much as needed.
```
