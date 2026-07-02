---
type: Engineering Policy
title: "REST-Oriented API Design"
description: "Designing HTTP APIs around resources and standard HTTP semantics so the API is predictable for humans and AI agents without prior knowledge of the system."
resource: https://qmu.co.jp/design/rest-api-design
tags:
  - design
  - rest-api-design
---

# REST-Oriented API Design

_Design HTTP APIs around resources and the standard HTTP semantics; a well-structured REST API is readable, cacheable, and navigable by both humans and AI agents without prior knowledge of the system._

HTTP's vocabulary — verbs, status codes, headers, and content negotiation — is a widely understood contract. An API that uses this vocabulary correctly is more predictable for human developers, more cacheable for infrastructure, and more navigable for AI agents whose training includes HTTP semantics. We use REST as our default orientation for HTTP APIs: resource-centric URLs, standard verbs mapped to standard operations, appropriate status codes, and a machine-readable description. We deviate from REST conventions when there is a clear benefit, but we document deviations rather than accumulating them silently.

## Goal (目標)

The situation this policy aims to achieve is one in which a developer (or AI agent) encountering the API for the first time can infer the structure of unexplored resources from the structure of familiar ones.

- URLs are nouns that name resources; verbs are HTTP methods.
- HTTP status codes communicate the outcome class, not just success or failure.
- The API has an OpenAPI specification that is kept current with the implementation.
- Clients do not need to know the internal vocabulary of the database or implementation to use the API.

## Responsibility (責務)

The situation this policy aims to prevent is one in which the API's structure depends on knowledge acquired through documentation or word of mouth rather than from HTTP conventions.

States we do not tolerate:

- Verb-in-URL designs: `POST /createUser`, `GET /deletePost?id=1`. HTTP verbs express the operation; URL paths name the resource.
- Using 200 OK for error responses, with error state expressed in a JSON body field. HTTP status codes communicate outcome class; consumers rely on them.
- An OpenAPI specification that is out of date or not present. An API without a current specification places the documentation burden on consumers.
- Breaking changes to a published API version without a deprecation notice and a migration path.

## Practices (実践)

### Resource URLs are nouns; HTTP verbs express the operation

Design URL paths as resource identifiers: `/users/{id}`, `/projects/{id}/tasks`. Use HTTP methods to express the operation: GET to retrieve, POST to create, PUT/PATCH to update, DELETE to remove. Collections are plural nouns: `/users`, not `/getUsers`.

### Use HTTP status codes accurately

Return the appropriate status code for each outcome:
- 200/201/204 for success (200 for retrieval and update, 201 for creation with Location header, 204 for deletion or no-content update)
- 400 for client input errors with a body that identifies what was wrong
- 401 for unauthenticated, 403 for authenticated but unauthorized
- 404 for a resource that does not exist
- 422 for semantically invalid input (correct structure, invalid values)
- 409 for conflicts (duplicate unique constraint)
- 500 for unexpected server errors (with logging, not detail in the response body)

### Maintain an OpenAPI specification

Maintain an OpenAPI 3.x specification for every public API, generated from the implementation or kept in sync with it. The specification is checked in CI to ensure it matches the implementation. Tools for generation from code: Zod to OpenAPI, tsoa, huma (Go).

### Version the API with a major version in the path

For public or consumer-facing APIs, include a major version in the path: `/v1/users`, `/v2/projects`. Breaking changes require a new major version. Deprecate old versions with a sunset date communicated through a `Deprecation` header and release notes.

### Related: Modeless Design, Accessibility Open to AI

A REST API that follows standard conventions is composable — it can be called in any order, by any client, without prior mode state. This supports [Modeless Design](/design/modeless-design.md) at the API layer. Standard, documented APIs are also more navigable by AI agents — see [Accessibility Open to AI](/planning/accessibility-first.md).
