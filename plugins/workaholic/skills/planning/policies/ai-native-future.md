---
title: Planning with A2A in Mind
slug: ai-native-future
category: planning
source: https://qmu.co.jp/planning/ai-native-future
---

# Planning with A2A in Mind

_Build in the premise that software users will include AI agents as well as humans, ensuring AI-driven processes remain observable and interruptible._

The users of software we build will soon no longer be only human. WebMCP for letting AI on browsers operate screens, MCP tools for AI operating elsewhere to call functions over HTTP, and the A2A (AI-to-AI) protocol for AI to interact directly with each other are all becoming real. AI agents that monitor inboxes and respond while referencing internal information are also built from combinations of these same means. It is for this reason that we weave into the planning stage the premise that the subjects of use are not limited to humans.

## Goal (目標)

We aim for a state in which, even when AI rather than a human is using the system, humans can observe that movement, interpret the contents of the automated processing, and intervene and take over when necessary. We aim for a state in which AI paths and human paths are aligned on top of the same function, and what is happening can be traced from either side.

## Responsibility (責務)

Our responsibility is to prevent a state in which we design with only humans as users and AI-driven processes become unobservable and uninterruptible by humans.

The more automation advances, the faster and further from human sight processing proceeds. If we leave things to AI without the ability to observe or intervene, mistaken judgments tend to reach their results without being stopped. In a firm where generative AI is our default author, there is a tendency for only AI paths to be built out, with the means for humans to take over midway being deferred.

## Practices (実践)

### Count both humans and AI as users

When deciding what to build, we count AI agents as users alongside humans. At the planning stage, we verify once whether "if AI rather than a human were to perform this operation" is a valid frame, and we see early on the prospect of whether the form can be one that AI can handle.

### Include human-in-the-loop in requirements

Even in processing that AI drives, we leave a path (human-in-the-loop) by which humans can observe the process, interpret it, and interrupt and take over manually. This is included from the beginning as a planning requirement, not as a feature added later.

### Do not commit to uncertain formats

A2A and other means with still few examples do not have a settled final form. For parts we cannot see through, we do not fix them to one form, but plan them with a wide margin for human observation and intervention, in a state where they can be rebuilt later.

### Related: Requirements Analysis through Modeling, Accessibility Open to AI

Related: [Requirements Analysis through Modeling](modeling-centric-design.md), [Accessibility Open to AI](accessibility-first.md), and [AI-Assisted Production Investigation](../../operation/policies/ai-production-investigation.md).
