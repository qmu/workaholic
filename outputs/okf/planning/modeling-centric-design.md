---
type: Engineering Policy
title: "Requirements Analysis through Modeling"
description: "Analyzing requirements by abstracting reality into models that capture stakeholders, events, data, demands, pain points, and solutions, placing this shared model as the foundation for all subsequent design and implementation."
resource: https://qmu.co.jp/planning/modeling-centric-design
tags:
  - planning
  - modeling-centric-design
---

# Requirements Analysis through Modeling

_Analyze requirements by abstracting reality into models, and place those models as the foundation for all subsequent design and implementation._

We analyze requirements by abstracting reality into models. Requirements here do not mean only requests as stated by the client. We treat as requirements what rises from multiple sources: what each stakeholder needs, system and data constraints, business goals, and operational and maintenance considerations. We define stakeholders, events, systems, data, demands, pain points, and solutions, and we call the result of structuring their relationships as a diagram a "model." A model is not a copy of reality itself — it is an abstraction that selects and lifts out the aspects necessary for analysis of what is being asked and what problems underlie it. We make this abstracted model the foundation on which subsequent design and implementation stand.

## Goal (目標)

We aim for a state in which requirements rising from multiple sources, together with the structure of the stakeholders, events, data, pain points, and solutions behind them, are shared as a model among everyone involved. Before moving to specifics like requirements, screens, tables, and code, we can see what we are thinking about on top of the abstracted model, and we can return to that model with each change or addition.

## Responsibility (責務)

Our responsibility is to prevent an approach in which we jump directly to implementation structure, screens, and tables without capturing the source of requirements and the structure behind them as a model.

When individual decisions pile up without a model being drawn, it becomes difficult to later reconstruct what problem we were trying to solve. In a firm where generative AI is our default author, if only code is produced in quantity without a shared model, it tends to become impossible for anyone to verify which aspect of reality the completed implementation corresponds to.

## Practices (実践)

### Define the model's constituent elements

When entering analysis, we first put into words the aspects of stakeholders, events, systems, data, demands, pain points, and solutions. Who is involved, what happens, what data moves, what is being asked, where is the pain, and what is returned in response — we name these first rather than leaving them vague.

### Structure as a diagram

The defined elements are placed in a diagram and their relationships connected. Because relationships are hard to see in text alone, we make the diagram the center of the analysis. The diagram is a starting point for discussion, and we redraw it as analysis advances.

### Remember that a model is a "selected aspect" of reality

A model does not copy all of reality — it selects and abstracts only the aspects needed for analysis. Because judgment goes into what is included and what is omitted, we take care not to mistake a model for "reality itself." When premises change, we redraw the selected aspects as well.

### Related: Codifying Domain Terminology, Preferring Rich Typing

Related: [Codifying Domain Terminology](/planning/terminology.md) and [Preferring Rich Typing](/implementation/type-driven-design.md).
