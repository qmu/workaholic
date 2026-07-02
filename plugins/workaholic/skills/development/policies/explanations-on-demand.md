---
title: Maintaining the Capacity to Generate Explanations
slug: explanations-on-demand
category: development
source: https://qmu.co.jp/development/explanations-on-demand
---

# Maintaining the Capacity to Generate Explanations

_Directing effort toward storing information structurally in the repository rather than polishing finished deliverables, so that explanations tailored to any reader can be generated at any time._

We direct more effort toward storing information comprehensively and structurally in the repository than toward crafting a single finished explanation for a specific audience. A reader's level of understanding and desired resolution differ each time, and the same subject calls for different explanations depending on who is asking. When source information is structurally in place, explanations can be generated from it in as many forms as needed.

Generative AI has reduced the effort required to stand up a single explanation. That is precisely why we want to shift where effort is spent — from polishing a deliverable addressed to one reader toward preparing source information in the repository that can respond to any reader. We treat explanation not as a piece of work to be written once and finished, but as work to create a state from which it can always be generated.

## Goal (目標)

We aim for a state in which information is stored comprehensively and structurally in the repository, and explanations tailored to any reader or level of resolution can be generated at any time in any number of forms. Reports, diagrams, and summaries all arise as things derived from that source information, and when a request for an explanation comes, it can be met through generation rather than through rewriting — explanations exist not as accumulated deliverables but as assets that can be generated.

## Responsibility (責務)

Our responsibility is to prevent a state in which information remains only inside finished deliverables, and the underlying structured record never lands in the repository. When a single polished explanation is created, that deliverable can look like the knowledge itself, and the facts and decisions that underlie it can fail to remain in the repository in a structured form. In a setup where generative AI can quickly polish a deliverable, it is especially easy to fold information into one polished artifact and leave the source information hollow. When source information is hollow, all the AI can draw on when a different reader or a different resolution is needed is one frozen explanation, and there is no way left to reassemble the explanation for a different audience.

## Practices (実践)

### Land source information in the repository before creating a deliverable

When asked for a report or presentation, rather than immediately writing the deliverable, first land the underlying facts, decisions, and background in a structured form in the repository. Then generate the deliverable from that landed source information. When source information is in place first, a request for an explanation aimed at a different audience can be answered through generation rather than through rebuilding.

### Store information in composable form, not fixed narratives

Avoid leaving information locked in a single narrative tailored to a particular reader. Keep terminology consistent, put each fact in one place, and store it in a structure that allows querying and composition. When information is folded into a narrative, only one reading can be extracted; when stored structurally, explanations with different resolutions or angles can be assembled as needed.

### Treat deliverables as derived from source information

Treat reports and diagrams as things derived from the repository's source information, and use the source information as the standard. When the deliverable itself is treated as the standard and maintained by hand, it becomes double-managed alongside source information, and it becomes unclear which is the real record. This extends the idea behind generating diagrams from implementation to explanations in general.

### When in doubt, enrich source information over polishing deliverables

When uncertain about how much to store in the repository, lean toward enriching the source information rather than polishing the current deliverable. Even if only one explanation is needed right now, the more comprehensive the source information, the more room there is to generate explanations for the next different request through generation rather than rework.

### Related: Objective Technical Documentation, Preserving Change History in Files, Diagram Generation

Related: [Objective Technical Documentation](../../implementation/policies/objective-documentation.md), [Preserving Change History in Files](commit-change-history.md), and [Diagram Generation from Code](../../implementation/policies/diagram-generation.md).
