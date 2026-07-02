---
title: Active Use of Generative AI
slug: ai-utilization
category: development
source: https://qmu.co.jp/development/ai-utilization
---

# Active Use of Generative AI

_Treating AI-assisted code generation as the default development approach, with explicit written client agreements on which data may enter which AI services before a project begins._

We actively use generative AI and AI coding tools (GitHub Copilot, Claude Code, Cursor, etc.) in software development. Rather than having humans write all the code first, having AI write it is our default approach. Because feeding information into AI is directly tied to how client data is handled, we establish the conditions and boundaries for use before development begins.

## Goal (目標)

We aim for a state in which every project starts with a documented, client-agreed record of which information may be fed into AI, which services are permitted under what configuration, and where all developers on the project can consult that record. We aim for a state in which the policies governing what AI produces — implementation, design, operation, and planning policies — are in place before development begins, so that AI-generated code can be evaluated against a shared standard from the first commit.

## Responsibility (責務)

Our responsibility is to prevent a state in which AI services are used in a project without an explicit written agreement on which information may be shared, which services are permitted, and under what conditions — leaving no traceable record of what data entered which model. We also prevent a state in which the side effects of heavy AI use (errors going unnoticed, developers adopting code without understanding it, quality varying with the tool's condition) are treated as individual incidents rather than as known failure modes that our standing policies exist to address.

## Practices (実践)

### Reach explicit written agreement before development begins

Before starting a new project, we agree explicitly with the client on the following points, documented as an annex to the contract or agreement rather than left to verbal understanding:

- The types of information handled in the project and their sensitivity (specifications, code, customer data, logs, etc.).
- Which of that information may be fed into generative AI — for example, whether it may be provided to LLMs, AI agents, or AI coding tools for use in specification review or code generation.
- When input is permitted, the range of AI services and models that may be used.

Fixing this agreement in writing before the project begins ensures that on-the-ground decisions do not drift from it later.

### Record the permitted conditions per project

Even when input is permitted, the client's security requirements or industry regulations may constrain which AI services can be used. Common patterns include:

- A requirement to use models isolated in the company's own cloud or a specified infrastructure (Amazon Bedrock, Google Vertex AI / Model Garden, Azure OpenAI Service, etc.).
- A requirement to confirm, before using SaaS APIs such as the OpenAI API or Anthropic API, that input data will not be used for model training (opt-out, zero data retention, etc.).
- A contractual specification of permitted model names or providers.

Because these conditions differ per project, at project setup we record "which AI services may be used, under what configuration" as a list that all developers can consult. Confirmation of settings is turned into a checklist and embedded in the project's setup procedure.

### Prepare for the side effects of heavy AI use through standing policies

Increasing dependence on AI coding tools carries predictable side effects: generated errors are easier to miss, developers adopt code without fully understanding its details, and output quality is affected by the tool's or model's condition. These are unavoidable with a new technology.

Rather than adding ad hoc checks after the fact, we address these side effects by keeping our policies in place in advance:

- Implementation policies (validity, availability, safety, accessibility) exist as a shared evaluation standard before the project starts, so generated code can be assessed against our standards.
- Quality rests on policy before generation and on each developer's own QA — not on after-the-fact code review (see [Code Review as a Non-Default Practice](review.md)). The quality standard does not change depending on whether the author was human or AI.
- The [Codifying Domain Terminology](../../planning/policies/terminology.md) and [Conservative Vendor Dependence](../../design/policies/vendor-neutrality.md) policies function as guardrails against AI-proposed naming and dependency additions.
- Tests are positioned as a verification tool that is at least as important for AI-written code as for human-written code.

Keeping policies in order is the preparatory work that makes it safe to use AI coding actively. Having the organization hold a stable axis — rather than thinking it through project by project — reduces variation in on-the-ground judgment.
