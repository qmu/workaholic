---
type: Engineering Policy
title: "REST-Oriented API Design"
description: "Designing REST-based Web APIs around business concepts as resources, using RPC-style endpoints only where resource form distorts the meaning, and aligning so the same concept always appears in the same URL path, method, granularity, and type."
resource: https://qmu.co.jp/design/rest-api-design
tags:
  - design
  - rest-api-design
---

# REST-Oriented API Design

_Design REST-based Web APIs treating business concepts as resources; for operations where a resource form distorts the meaning, use RPC-style endpoints alongside; and align so that the same concept always appears in the same URL path, method, granularity, and type._

We design REST-based Web APIs treating business concepts as resources as the baseline. For operations where placing them in resource form distorts the subject or result, we use RPC-style endpoints alongside. We align across the API as a whole so that the same concept appears in the same URL path, method, granularity, and type.

## Goal (目標)

The situation this policy aims to achieve is one in which a user or agent who has checked one endpoint can handle adjacent endpoints without re-learning each endpoint's quirks. Work to confirm actual APIs remains, but because the same concept appears in the same form, the perspectives for confirmation are aligned. The side that adds new endpoints can also use existing forms as a reference, and it is unlikely that a different convention accumulates with each addition.

## Responsibility (責務)

The situation this policy aims to prevent is one in which the same concept or the same-meaning operation fragments into different URL paths, naming, methods, granularity, and types per endpoint.

When names, granularity, and the way state is expressed vary by location, callers must change how they confirm for each operation, and the side that adds loses sight of which precedent to follow. One deviation remains as a precedent that invites the next deviation, and in contexts where generative AI produces endpoints at volume, this variation accumulates in a short period.

## Practices (実践)

### Represent business concepts as resources

Assemble URL paths from business concepts such as customers, applications, invoices, reviews, and submissions — things that hold state, relationships, and history — rather than from screen names or process names. Express each operation as reading, creating, changing, or relating that concept, and keep the concepts defined in the model and the API's resources as the same thing.

### Add operations aligned with existing conventions

Before adding a new endpoint, first confirm the API for nearby business concepts. Decide which of the URL path, method, request, response, and error representation to carry over, then add. If making the form different from the existing, leave a reason that can explain the difference — business concept, lifecycle, permission boundary, synchronicity, and so on — and bring differences that are purely implementation-driven into alignment with the existing.

### Use RPC-style endpoints only for operations where meaning would be distorted

For operations such as bulk processing across multiple resources, executing a calculation, screening, or submitting to an external party — where forcing them into a resource form makes the subject and result hard to read — place them as RPC-style endpoints. Do not create a non-existent intermediate resource or disguise as a semantically weak state update just to match the REST name. Even when using RPC, record in the API definition: which resources are read, what state is changed, what is returned, and how re-execution is handled.

### Same concept in the same URL path and types

Treat the same business concept as the same meaning across URL paths, resource names, field names, and types. Do not funnel different concepts into the same `id` or `status`; do not have the same name carry a different value range or transition. When the model's vocabulary changes, revisit the API's vocabulary to match that change.

### Related: Requirements Analysis through Modeling, Codifying Domain Terminology, Preferring Rich Typing

Related: [Requirements Analysis through Modeling](/planning/modeling-centric-design.md), [Codifying Domain Terminology](/planning/terminology.md), [Preferring Rich Typing](/implementation/type-driven-design.md).
