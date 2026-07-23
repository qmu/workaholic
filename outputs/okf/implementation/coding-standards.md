---
type: Engineering Policy
title: "Coding Standards (TypeScript)"
description: "Defaulting to TypeScript language features where type checking and declarative guarantees apply, and avoiding features where those guarantees fall away, so the compiler detects as much as possible in AI-produced code."
resource: https://qmu.co.jp/implementation/coding-standards
tags:
  - implementation
  - coding-standards
---

# Coding Standards (TypeScript)

_Defaulting to language features where type checking and declarative guarantees apply, and avoiding features where those guarantees fall away, so the compiler can detect as much as possible in AI-produced code._

TypeScript offers multiple language features for writing the same behavior, and which to reach for by default determines how much the compiler can detect. The policy defaults to features where type checking and declarative guarantees apply, and steps back from features where those guarantees fall away in this context. Most of the implementation is written by AI, and the compiler is the most accurate and least expensive feedback path an agent can take. Which language features to default to determines how much the compiler can detect in the AI-produced code at scale, so the feature choices are made explicit.

## Goal (目標)

The situation this policy aims to achieve is one where language feature choices maximize the range of what the compiler can detect across the entire codebase. Features where type checking and declarative guarantees apply are used consistently as defaults, so mismatched values, missing cases, and incomplete branching are gathered at compile time before the code runs.

## Responsibility (責務)

The situation this policy aims to prevent is one where the guarantees of types and declarativeness silently fall away through `any`, `as`, non-null assertions, `@ts-ignore`, or `==`. Each is locally convenient, but values passing through them bypass compiler checking and push inconsistencies into tests, reviews, and operations.

In a structure where AI writes most of the implementation, AI-produced code that scatters `any` and type assertions, letting static-analysis gaps accumulate in the domain layer, is a recurring failure mode. Each assertion is small, but when stacked across many files without awareness, the range the compiler could have detected is broadly lost.

## Practices (実践)

### Principal avoidance (avoid in this context as a rule)

These features make it easy for type and declarativeness guarantees to fall away. The default in this context is to avoid them; when used, the reason is documented.

- `any` — Disables type checking at that point. Receive at boundaries with `unknown` and pass through a validation function. See [Preferring Rich Typing](/implementation/type-driven-design.md) for the reasoning.
- `as` (type assertions) — Overrides compiler inference and conceals errors under a declaration. Replace with `satisfies` or validation functions.
- Non-null assertions (`hoge!`) — Causes the compiler to ignore the possibility of `null` or `undefined`. Express absence with `Option` types or branching.
- `@ts-ignore` — Suppresses an error and leaves the cause in place. Consider fixing the type first.
- `null` — Splitting absence representation across `null` and `undefined` increases the chance of missing a case. Keep absence on `undefined` or an `Option` type.
- `==` / `!=` — Introduces implicit type coercion. Use `===` / `!==`. See [Preferring Declarative Code](/implementation/functional-programming.md) for the reasoning.
- `class` — Tends to bring in mutable internal state and inheritance, moving away from the default of pure functions and immutable data. Express data as `type`, behavior as functions.
- `enum` — The runtime-value-to-type correspondence is its own system; literal unions and `as const` express the same thing more directly.
- `switch` — Prone to fall-through and missed exhaustiveness; does not compose well with exhaustiveness checks on discriminated unions. Keep branching on discriminated unions with `never`-based exhaustiveness checks.
- `namespace` — Duplicates the module system's partitioning; keep to ESM module boundaries.
- `var` — Function scope and hoisting widen the reference range. Default to `const`.
- `this` — Binding changes with call context, making behavior hard to read from the signature. Pass values as arguments.

### Use with care (only when the situation clearly calls for it)

These features are not the default within the declarative range, but can be the natural choice in certain situations. Use only when there is a clear reason, and do so carefully.

- `let` — Mutable local variables are limited to loops, accumulators, and optimizations; not used as a general escape hatch. Default is `const`.
- `for` — Most loops read linearly as `map`, `filter`, or `reduce`. Use only where early exit or index manipulation is the natural choice.
- `if` — When branching returns a value, a ternary is more readable as an expression. Use `if` only where branching side effects as a statement.
- Block scope and early `return` — Imperative control flow is limited to cases where it improves readability, such as guard clauses.
- `throw` — The default is to return failures as `Result` types; exceptions are reserved for signalling program invariants or final catches at framework boundaries. See [Preferring Rich Typing](/implementation/type-driven-design.md) for the reasoning.
- `is` (type predicates) — Used to narrow values that have passed through validation. An `is` without real validation behind it is the same as `as` — claiming a guarantee that is not there.
- `interface` — Limited to situations requiring declaration merging or inheritance; the default is `type`.
- `function` declarations — Limited to situations that use hoisting; the default is arrow functions.

### Recommended

These features delegate the most to type and declarativeness guarantees. Use them consistently as defaults.

- `unknown` — Use as the receiving point for values coming from outside, and pass through a validation function before flowing inward. Use instead of `any`.
- Ternary expressions — Write value-returning branches as expressions, letting the compiler align the return type across branches.
- `Readonly` / `ReadonlyArray` by default — Treat data as immutable; represent changes as creation of a new value.
- Arrow functions — No `this` binding, composable as values.
- `type` — The default for declaring data structures; expresses unions, intersections, and nominal types in a consistent vocabulary.
- `===` / `!==` — Use comparisons that do not introduce implicit type coercion.
- `as const` — Fix literals as narrow types, preserving the correspondence between value and type.
- `satisfies` — Check that a value satisfies the target type while preserving the inferred concrete type. Does not override inference the way `as` does.

Usage of the recommended and use-with-care tiers follows the patterns in plgg — the reference implementation for rich typing in this context — specifically its use of `unknown` boundaries, `as const`, `satisfies`, nominal types, and `Readonly`.

### Package internal directory layout

TypeScript packages that express domains divide the inside of `src/` by domain first. While [Standard Directory Structure](/implementation/directory-structure.md) covers the repository-wide layout up to `packages/<package>/`, this section covers how to arrange `<package>/src/` from the TypeScript side. One directory per aggregate root, named with a pronounceable PascalCase word such as `Order` or `Inventory`. Under each domain directory, there are exactly three subdirectories: `model/`, `service/`, and `dependency/`. HTTP routers, CLIs, and other entry points are not placed in this package; they live as thin shells in a separate package that imports and calls the service's exported functions (see [Domain Layer Separation](/implementation/domain-layer-separation.md)).

```
src/
  Order/                 Order domain (one per aggregate root · PascalCase)
    model/               Data type declarations and functions on those types
    service/             Exported procedures
    dependency/          Encapsulated external dependency implementations
  Inventory/             Inventory domain
  Billing/               Billing domain
```

- `model/` — Data type declarations and functions on those data types. A pure layer that depends only on language primitives and the project's base library (plgg in our context). Functions are shaped to operate on a single model where possible; cross-model processing goes in `service/` (though operating on multiple models is not prohibited when needed). The aim is to have the declarations and operations for a single data type concentrated in that model's file.
- `service/` — The place that exports the procedures called from outside. The use-case layer that works with models while calling dependencies to achieve its purpose; primarily defines functions. The types appearing in signatures are limited to language primitives, base library types, and model types — the library types used internally by `dependency/` are not propagated into this layer.
- `dependency/` — The place for implementations that contain external dependencies. For example, an ORM-backed implementation receives arguments in primitive, base library, and model types, executes the concrete ORM query internally, and returns the result converted back to the same vocabulary of types. External library dependencies are encapsulated here, hiding implementation details.

Expose only `service/` and `model/` outside the package; `dependency/` is not published. The priority is to express the main processing completely within these three directories, and not to break the structure by adding new directories or broadening a section's scope to bring in other functions. Where to place tests, package-specific scripts, and documentation follows the package-level layout in [Standard Directory Structure](/implementation/directory-structure.md).

This arrangement — dependency implementations coexisting inside the domain directory — differs from the widely-known domain-driven design approach of placing implementation details away from the domain. With the understanding that such separation works well in its context, at our scale and team structure we prioritize being able to rebuild at the domain unit level over purity of separation. Enclosing dependencies in `dependency/` with strict boundaries through plgg types, managed within `packages/` in the same repository, supports the replaceability envisioned in [Sacrificial Architecture](/design/sacrificial-architecture.md).

### Related

The reasoning behind avoiding `any`, `as`, non-null assertions, and `@ts-ignore`, and the approach of rich typing with `unknown` boundaries, `as const`, `satisfies`, and nominal types, is in [Preferring Rich Typing](/implementation/type-driven-design.md). The reasoning behind avoiding `class`, `throw`, and `==` and defaulting to immutable data, return-type failure expression, and declarative comparison is in [Preferring Declarative Code](/implementation/functional-programming.md). This policy sets out these principles as concrete TypeScript feature choices, showing which defaults to reach for.
