---
type: Engineering Policy
title: "Golang Coding Standards"
description: "Defaulting to returning failures as values, defining interfaces small on the consumer side, and using the standard toolchain, so the compiler, `go vet`, and lint can detect as much as possible in AI-produced Go code."
resource: https://qmu.co.jp/implementation/golang-coding-standards
tags:
  - implementation
  - golang-coding-standards
---

# Golang Coding Standards

_Choosing the forms where the compiler, `go vet`, and lint can detect the most — defaulting to returning failures as values, defining interfaces small on the consumer side, and using the standard toolchain._

In Go, the same behavior can often be written in more than one way, and the choice of which forms to default to determines how much the compiler, `go vet`, and lint can detect. The policy defaults to treating failures as values, defining interfaces small on the consumer side, and using the standard toolchain — and steps back from forms that reduce static-analysis coverage. Most of the implementation is written by AI, and the compiler and standard tools are the most accurate and least expensive feedback path an agent can take. Which forms to default to matters because it determines how much static checking applies to the Go code AI produces at scale, so the conventions are made explicit. This policy is paired with [Coding Standards (TypeScript)](/implementation/coding-standards.md), with each policy collecting the language-specific differences.

## Goal (目標)

The situation this policy aims to achieve is one where language feature choices keep the range of what the compiler, `go vet`, and lint can detect wide across the entire codebase. Failure paths are readable from return value types, dependency directions are closed toward the domain layer, and formatting and static checks produce identical results regardless of who runs them.

## Responsibility (責務)

The situation this policy aims to prevent is one where failures hide through `panic` or swallowed errors without appearing in return value types, so that inconsistencies are detected only at the test, review, or operations stage. It also aims to prevent unformatted or statically-unchecked code from accumulating.

In a structure where AI writes most of the implementation, errors discarded to `_`, or large interfaces and excessive abstraction spreading through AI-produced code, are recurring failure modes — each small, but when they recur across many files the range of inconsistencies that could have been detected statically accumulates and slips through to production.

## Practices (実践)

### Return failures as values

The default is to return failures as `error` values and handle them at the call site. Received `error` values are not discarded to `_`; they are either returned with added context or handled at that point. `panic` is reserved for signalling program invariant violations or startup premise failures — not normal control flow.

### Define interfaces small on the consumer side

The default is to declare only the behaviors needed in the consuming package, defined in that package rather than on the provider side. Defining the minimum contract on the consumer side rather than placing large interfaces on the provider side makes it easier to keep dependency directions closed toward the domain layer.

### Design zero values to be meaningful

The default is to design types so that their zero value is a usable initial state. For types where the zero value is an invalid state, constructor functions are used so that only values satisfying invariants can be created.

### Thread context.Context through

Cancellation, deadlines, and cross-cutting values are threaded via `context.Context`, passed from outer entry points inward. Storing `context.Context` in a struct field is avoided; it is passed as the first argument of functions.

### Default to the standard toolchain

`gofmt` (or `goimports`) for formatting, `go vet` for static checking, and lint are run by default, with the same checks in CI. Formatting and checking execution is consolidated in `scripts/` per [Command Scripts for Development Tasks](/implementation/command-scripts.md), so results are the same regardless of who runs them.

### Package internal directory layout

The language-agnostic principles for internal package arrangement are established by [Anti-Corruption Structure](/implementation/anti-corruption-structure.md). Those principles are: dividing by domain into sections, and dividing each section into the three responsibilities of model, service, and dependency implementation. This section shows how to express those three responsibilities using Go's package and file boundaries. In Go, directory names are not necessarily aligned as `model/`, `service/`, and `dependency/`; the aim instead is a state where the same three responsibilities can be traced from how packages and files are divided.

- Model equivalent — Data types and functions on those types. A pure part that depends only on language primitives and the base library, placed in the domain-representing package.
- Service equivalent — Public procedures called from outside. The use-case equivalent that achieves its purpose by working with models while calling dependency implementations. Types in signatures are limited to primitives, base library, and model types; library types used internally by dependency implementations are not propagated into this layer.
- Dependency implementation equivalent — Implementations that use external libraries. Receives primitives, base library, and model types; calls specific libraries internally; and returns results converted to the same vocabulary of types. To keep external library types from going outside the boundary, they are contained in a separate package or file.

Entry points are not placed in the domain package but sit as a thin `main` in `cmd/<binary>/`, containing only startup and wiring; decision logic remains in the domain package. Implementations not meant to be imported from outside are placed in `internal/` to maintain import boundaries. What the domain package exposes to the outside is limited to model and service; dependency implementations are not published. `cmd/` and `internal/` are not the three responsibilities themselves but placement containers for mapping those responsibility boundaries to Go idioms. This separation is continuous with [Domain Layer Separation](/implementation/domain-layer-separation.md), using placement to keep dependency directions closed toward the domain layer.

## Related

The reasoning behind returning failures as values and suppressing mutable state is in [Preferring Declarative Code](/implementation/functional-programming.md) and [Preferring Rich Typing](/implementation/type-driven-design.md). The language-agnostic principles for internal package arrangement are in [Anti-Corruption Structure](/implementation/anti-corruption-structure.md), the repository-wide arrangement across packages is in [Standard Directory Structure](/implementation/directory-structure.md), and the division of domain layer, entry points, and vendor boundaries is in [Domain Layer Separation](/implementation/domain-layer-separation.md). This policy sets out these principles as concrete Go feature choices, showing which defaults to reach for.
