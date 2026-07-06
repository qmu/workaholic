---
type: Engineering Policy
title: "Preferring Rich Typing"
description: "Narrowing each type's range of values to the domain's actual shape, introduced selectively where confusion or omission can occur — not over every value — so that expressing a new requirement in the existing type vocabulary doubles as a consistency check on the requirement itself."
resource: https://qmu.co.jp/implementation/type-driven-design
tags:
  - implementation
  - type-driven-design
---

# Preferring Rich Typing

When the meaning of a value, the possibility of failure, the absence of a value, and the flow of a computation are all left to the runtime, an ID that travels around as a bare `number`, a failure thrown as an exception, an absence expressed as `null`, and a composition arranged procedurally all slip past the compiler — and their discovery tends to be deferred to testing, review, or operation. Our policy is to lift such things up to the surface of the type system to the extent we can.

Values we want to distinguish, or values that should carry an invariant, are carved out into their own types as value objects (値オブジェクト); failure and absence are expressed as values through types such as the Result type (Result 型) or the Option type (Option 型). Rather than covering every value or every path, we introduce these selectively, narrowed to the places where confusion, oversight, or omission can occur.

With this substitution, mixing up distinct concepts is stopped at compile time, and swallowed failures or dropped `null`s become things you can point out just by looking at the return type. The meaning of a value and the explanation of a failure are no longer scattered across comments, naming conventions, and tests — they gather in the type.

## Goal (目標)

The situation this policy aims to achieve is one in which whether a newly introduced requirement (demand) connects to the existing system of meaning (semantics) without contradiction can be checked mechanically, through the very procedure of assembling the types. We aim for a state in which the type-mediated procedure — whether the requirement can be written down in the existing type vocabulary, and whether that writing-down is free of distortion or strain — works directly as a consistency check on the requirement side.

The outline of the goal is as follows:

- When you try to write a new requirement down in the existing type vocabulary, the places that fail to fit, the assumptions that contradict, and the requirements that cannot be written down at all surface during the process of assembling the types.
- The places where a specification change forces an existing type to be "widened" can be read as clues pointing to a misalignment on the requirement side.
- Design-time discussion can be conducted toward the consistency of the domain vocabulary.

## Responsibility (責務)

The situations this policy aims to prevent are shown along two axes:

- A state in which premises have escaped outside the type.
- A state in which the type itself has become too complex.

The former pulls toward gathering the domain's premises onto the type; the latter pulls toward keeping the type's expression within a readable range. As a paired constraint that pulls against each other, we permit the sacrifice of neither side.

States we do not permit:

- A state in which a premise that could be expressed in the type is instead substituted by a thin type (such as `string`, `any`), a comment, or a unit test, and is not gathered onto the type.
- A state in which distinct concepts are left mixed together in the same representation, or in which information gathered onto the type is leaked away through scattering `@ts-ignore`, `as any`, and the like.
- A state in which the type's expression has been layered beyond a readable range through inheritance, nested objects, multi-stage conditional types, or the mass production of derived types that differ only slightly.

## Practices (実践)

### Use fewer primitive types and more custom types (プリミティブ型の使用を減らし、カスタム型を増やす)

Our policy is, to the extent we can, not to carry around the values and states that appear in the domain as primitive types such as `string` / `number` / `boolean`, but to replace them with custom types we declare ourselves. A value that flows around as a primitive type remains in a state where you cannot read from the type either what concept it carries or what constraints it satisfies. The more custom types we introduce, the more what a value is and is not can be read from the type, and the wider the range becomes in which mixing distinct concepts together and leaking an invariant are stopped at compile time.

### When the type starts to strain, revisit the design (型に無理が出てきたら設計を見直す)

When a type has become cramped relative to the domain it expresses, or conversely has become so complex that it exceeds a reader's understanding, we consider it preferable not to thin or extend the type on the spot, but to return to the design itself and revisit it. We first consider reorganizing the type declarations (splitting into subtypes, dividing by state or responsibility, extracting common parts), and, if necessary, returning to the requirement side as well.

- In situations where it becomes necessary to widen an existing rich type to `unknown`, `any`, `string`, or the like, we first stop. Most reasons for thinning a type are either the discovery of a new case or an error in the existing design, and in both we consider it preferable that "adding a case / fixing the design" be considered ahead of "widening."
- When a type starts to explode, it is often because multiple domain concepts have been crammed into a single type, so we first consider splitting the type by state or responsibility. For example, if `User` carries login state, subscription plan, and permission role all together, we split the type by state. We read the complexity of the type as a gauge of the domain's decomposition granularity.
- In situations where a requirement for a more flexible type arises, rather than loosening the type to fit the requirement, we first consider whether the requirement side can be reshaped to fit snugly within the range the type can permit. If a distortion remains between the type and the requirement, we consider it preferable to resolve that distortion by returning to the requirement side.

### Divide the roles of type checking and unit testing (型検査と単体テストの役割を分ける)

We consider type checking and unit testing to be means of verifying different subjects, not substitutes for each other. Type checking takes on the correctness that is determined by the structure of the code — the range of values a value can take, the distinction between distinct concepts, the exhaustiveness of case analysis, and so on. Unit testing takes on behavior that is hard to express at the type level — the results of external I/O, concurrency, timing dependence, algebraic properties, and so on. By dividing the two by role, the boundary of the responsibility being verified becomes clear between the type and the runtime.

- When a value range is narrowed by the type, unit tests are confined to describing behavior over that narrowed range.
- Property tests (property test) are used for algebraic properties that are hard to express in types, such as associativity and idempotence.
- Contract tests (contract test) are written only for the parts of the promise with external I/O that the signature cannot express.

### Narrow the range of values (値域を狭める)

Languages equipped with dependent types (dependent types), which can handle value ranges at the type level, have limited opportunities for practical use. The type systems of the mainstream imperative languages that are our primary options — TypeScript, Go, and so on — do not have dependent types, but by using refinement types — a mechanism in which only values that have passed through a type predicate or validation function flow as a narrowed type — we can express a narrowed range of values that a single type variable may hold. Our policy is to make use of this refinement framework as a realistic approximation of dependent types.

- At the input boundary, pass values through an `is` type predicate or a validation function of the form `asXxx(unknown) => Result<Xxx, InvalidError>`, taking a structure in which only values that have passed validation flow inward as a narrowed type.
- Treat a brand type and a validation function as a pair. As in `NonEmptyString = string & { readonly __: "NonEmpty" }`, build, through structure, a state in which nothing but what has passed validation can claim that type.
- A type narrowed by refinement is, once it has crossed the boundary and entered the interior, written on the assumption that the invariant holds; treat it differently before and after the boundary.

### Make use of algebraic data types (代数的データ型の活用)

The case analyses and states of the domain are expressed as combinations of sum types (discriminated unions) and product types (records and tuples) — algebraic data types. By writing down the shapes a value can take, unhandled cases are enumerated by the compiler, and unexpected combinations are excluded at the type level.

- A case analysis of "either A, B, or C" is expressed as a discriminated union (sum type) with a `tag` field.
- A "group of fields that hold simultaneously" is expressed as a record type (product type), and an "ordered tuple" as a tuple type.
- The exhaustiveness of pattern matching or `switch` is guaranteed by an exhaustiveness check using the `never` type, so that when a new case is added the branches that were missed are enumerated at compile time.

### Make use of value objects (値オブジェクトの活用)

In situations where we want to give a domain value a guarantee of being validated or normalized, or a representational invariant (non-empty, positive integer, format constraint, and so on), we receive it as its own type.

- For values that have a format or constraint they must satisfy — such as a validated email, a kebab-case string, a non-empty array, an unsigned integer, or a timestamp — we narrow to those values and handle them as a type narrowed through a validation function.
- Value objects used in common across multiple domains are consolidated on the library side and reused.
- At the input boundary, pass through a function of the form `asXxx(unknown) => Result<Xxx, InvalidError>`, keeping the values brought inward already in a narrowed state.

### Distinguish by nominal typing (公称型による区別)

In situations where values with different meanings in the domain share the same primitive representation and can be assigned to each other, and we want to prevent that, we distinguish types by name rather than by structure (nominal typing). The aim is not to give them validation or an invariant, but to structurally forbid the mixing of values whose representation is identical.

- For values whose representation is identical but whose meaning breaks if mixed up — such as a customer ID and an employee ID, an order number and a product number, or a pre-tax amount and a tax-inclusive amount — separate them into distinct types with brand types or tagged types.
- Rather than creating a named type for every field, introduce them narrowed to the situations where confusion leads to real harm.

### Express errors as values (エラーを値として表現)

Throwing an error as an exception produces, in itself, a control flow that does not appear in the type, and information leaks out of the type you took care to write richly. A function in which failure can occur returns the error as a value through a return type such as `Result<T, E>`, `Either<E, T>`, or `[ok, value] | [err, error]`, keeping the path that delegates handling to the caller visible in the type.

We limit the situations in which an exception is thrown to cases such as the following:

- Notification of a program inconsistency (an assertion violation).
- Final capture at a framework boundary (the outermost edge of an HTTP handler or a queue worker).
