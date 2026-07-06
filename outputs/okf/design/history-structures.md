---
type: Engineering Policy
title: "Proactive Introduction of History Structures"
description: "Designing data structures to preserve state transitions as history from the start, so that audit, re-consent recording, and temporal reasoning questions can be answered from the accumulated data."
resource: https://qmu.co.jp/design/history-structures
tags:
  - design
  - history-structures
---

# Proactive Introduction of History Structures

_Design data structures to preserve state transitions as history; the ability to reconstruct what was true at a given point in time is much cheaper to build in from the start than to add after data has accumulated._

We proactively hold the history of state as a structure in design. Not only what status a record holds now, but when, in what order, and through what it arrived at the present — we place it as a default consideration at the design stage to retain this in a structurally traceable form. The reason for holding history as a structure is that three concerns — audit, re-consent recording, and temporal reasoning — all presuppose the ability to reconstruct "what was true at a given point in time" after the fact. Keeping only the latest state and overwriting the past with each change is light and fast, but when these concerns arise later there are no means left to recover the lost history. At our scale, stage, and structure, these concerns often arise as the business progresses, and we judge it easier to place each judgment on the same foundation if history is held structurally from the start.

## Goal (目標)

The situation this policy aims to achieve is one in which state transitions remain as history, and the state at a given point in time and the history of changes leading to it can be traced structurally after the fact. Not just showing the current status, but a state in which when and through what the present was reached can be read from the records, and the path of consent updates and status changes can be traced back. Reaching a state in which the same history structure can provide answers for audit questions, re-consent records, and reconstruction of past-point states is placed as our destination.

## Responsibility (責務)

The situation this policy aims to prevent is one in which the past is lost by overwriting state, making it impossible to reconstruct what happened and when after the fact.

Implementation that updates status tends to take the form of writing back only the latest value and discarding the previous value and the history leading to it. In development where AI writes most of the implementation, as code that updates status is mass-produced, overwriting without retaining the before and after of changes tends to spread as the default behavior, resulting in history silently being lost. We want to prevent the state in which when audit or re-consent questions arise later, there is no history left to trace.

## Practices (実践)

### Add change history alongside tables that hold status

When a record holds a status or state field, consider alongside it a structure that can retain the history of change — when, from what value to what value, triggered by what — rather than only overwriting the value. Plan from the design stage for a form in which simple queries for the latest status remain straightforward while the history of change accumulates behind them.

### Adopt event-sourcing-style recording according to the concern

Event-sourcing-style recording — recording state transitions themselves rather than the latest state snapshot — is worth considering where concerns of audit, re-consent recording, or temporal reasoning arise. That said, holding history as a structure as a default consideration, and building a heavyweight event store from the start, are separate matters. We do not recommend building a distributed event store in advance; the judgment of whether to adopt it and to what degree is made when the concern becomes concrete. The implementation details of storage format, migration, and adoption conditions are covered in the event sourcing section of [Schema-First Database Design](/implementation/persistence.md).

### Plan for audit, re-consent recording, and temporal reasoning as uses of history

Plan ahead for three concerns as uses of history. For audit: the ability to trace after the fact who changed what, when, as primary material forms the basis for evaluation under Risk Management under ISMS and post-incident verification. For re-consent recording: being able to retain as history when and how terms changed and consent was updated is key — see [Recording of Policy Changes and Consent](/design/consent-recording.md). For temporal reasoning: plan to reconstruct past states and ask what was true at a given point.

### Related: Schema-First Database Design, Respecting User Data Sovereignty, Risk Management under ISMS, Recording of Policy Changes and Consent

Related: [Schema-First Database Design](/implementation/persistence.md), [Respecting User Data Sovereignty](/design/data-sovereignty.md), Risk Management under ISMS, and [Recording of Policy Changes and Consent](/design/consent-recording.md).
