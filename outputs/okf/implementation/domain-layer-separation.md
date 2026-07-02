---
type: Engineering Policy
title: "Domain Layer Separation"
description: "Separating business logic from entry points (HTTP routers, CLIs, queue workers) and writing it in standard-language vocabulary, keeping entry points thin so more is verifiable by static checks and unit tests and the domain layer is reusable across entry points."
resource: https://qmu.co.jp/implementation/domain-layer-separation
tags:
  - implementation
  - domain-layer-separation
---

# Domain Layer Separation

Our applications connect to the outside world through entry points such as HTTP routers, CLIs, and queue workers. When business logic is written directly into those entry points, pure computation that could be expressed in the language's standard vocabulary becomes bound to framework-specific vocabulary, and the range that can be verified through static checking and unit testing narrows. Our policy is to keep entry points as thin shells and to write business logic as a domain layer expressed in an independent vocabulary.

## Goal (目標)

The situation this policy aims to achieve is a state in which the domain layer does not depend on the application's entry points and can be reused from a different entry point through the same call. We do not guarantee that this is achieved, but we hold it up as our ideal to move closer toward.

- The entry points (HTTP, CLI, queue) are kept as thin shells that call functions in the domain layer and return the result.
- The domain layer is written in the language's standard vocabulary and is not bound to framework-specific types or signatures.
- The domain model is built with rich types (see The Case for Thick Typing (厚い型付けの推奨)), and both static checking and unit testing support the correctness of the domain's decisions.
- The same domain layer can be reused from different entry points such as HTTP, CLI, and batch, using the same way of calling it.

## Responsibility (責務)

The situation this policy aims to prevent is a state in which entry-point-specific types, vendor-specific types, or framework-specific contexts have leaked into the domain layer's signatures. We do not tolerate the following states.

- A state in which vendor-provided types (an ORM's record type, an HTTP framework's Request type, an SDK's response type, and the like) have leaked into the domain layer's function signatures.
- A state in which business logic is written directly into the entry points (HTTP handlers, CLI commands, queue workers) rather than taking the form of calling the domain layer and returning its result.
- A state in which the domain layer implicitly depends on framework-specific global variables or context objects (such as the resolution result of a DI container).

## Practices (実践)

### Separate the entry point from the domain layer

HTTP routers, CLIs, and queue workers are kept as thin shells that call functions in the domain layer and return the result; they do not have business logic written directly into them. The responsibility of an entry point is narrowed down to interpreting the request or arguments, passing them to the domain function, and formatting the return value.

- TypeScript: Write the handler as a thin function such as `(req, res) => domain.process(input).then(write)`, responsible only for assembling the input and formatting the response.
- Go: Write the handler or `cobra` command as a thin function that calls `domain.Process(input)` and writes the result to `http.ResponseWriter` or standard output.

### Calling vendors from the domain layer is tolerated

Excessive elimination of vendors is not our goal. Calling vendors such as databases, email sending, payments, and AI providers from the domain layer is itself tolerated. However, the public functions of the vendor directory are exposed as an interface that "accepts arguments of primitive types or domain types, and returns primitive types or domain types." This is a boundary that prevents vendor-specific types from leaking into the domain layer, and it is a concept that ties directly into Passive Vendor Dependence (消極的ベンダー依存) and Implement an Anti-Corruption Layer (腐敗防止層を実装する).

### Write the domain layer in the language's standard vocabulary

Domain computation is written starting from the language's own standard features. Side effects, immutability, types, and errors are expressed using the standard vocabulary to the greatest extent possible, and the domain model is assembled with a thick type vocabulary (The Case for Thick Typing (厚い型付けの推奨)). The policy on computation style follows The Case for Declarative Description (宣言的記述の推奨); in the domain layer, pure functions, immutable data, and the expression of failure through return types are the default form.

- TypeScript: Build it primarily around `Readonly`, `ReadonlyArray`, discriminated unions, and a `Result` type (defined yourself).
- Go: Return a new value as the return value, make errors explicit with the two-value `(T, error)` return, and expose domain types at the `package` boundary.

### Keep the domain layer pure rather than adding abstract layers

We do not deny the classifications of onion, hexagonal, or clean architecture, nor DI containers. We leave open the possibility of choosing them depending on the situation. However, we do not make increasing abstraction layers an end in itself; first and foremost, we prioritize keeping the domain layer in a state where it "can be written purely."

### Separate by module and package

We physically separate the domain layer from the entry points, the vendors, and the persistence layer. Following the conventions of the language, we separate by module boundaries (directories plus import constraints) in TypeScript, and by package boundaries in Go. The domain layer does not import external modules/packages; instead, it takes a structure in which values are passed in and out through the arguments and return values of public functions.

### Draw the vendor boundary with primitive types and domain types

The public functions of the vendor directory use, for both arguments and return values, only primitive types or domain types that we have declared. Vendor-specific types (an ORM record, an HTTP framework's Request, an SDK's response type, and the like) are not leaked outside the boundary as they are. Inside the boundary module, they are translated and converted into domain types before being returned (Implement an Anti-Corruption Layer (腐敗防止層を実装する)).

### The domain layer's unit tests stay green with fake implementations

The domain layer's unit tests are kept in a state where they pass green without connecting to an actual vendor. The distinction is that it is the anti-corruption layer's tests that need a vendor, not the domain's tests (for the details of testing, see Testing (テスト)). A structure in which the domain layer does not depend on external state is also a prerequisite for keeping the unit of testing small.

### Reuse across entry points

Being able to invoke the same domain function from an HTTP router and from a CLI using the same way of calling it serves as evidence that the domain layer has been written independently. If the structure has broken down, the moment you try to call it from a different entry point you will discover that it is bound to framework-specific types (this also ties into "Separation of Domain and Persistence" in Persistence Strategy (永続化戦略)).
