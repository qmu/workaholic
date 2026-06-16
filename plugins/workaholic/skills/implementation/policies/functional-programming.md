---
title: Preferring Declarative Code
slug: functional-programming
category: implementation
source: https://qmu.co.jp/implementation/functional-programming
---

# Preferring Declarative Code

Not all code can be written declaratively; there are situations where writing imperatively is the more natural choice. With that acknowledged, our policy is to write declaratively wherever it is possible to do so.

A function written declaratively has behavior that can be foreseen from its signature, and it returns the same result for the same input. This property is preserved even when functions are combined. In procedurally written code, the behavior does not fit entirely within the signature, and parts of it tend to remain unknowable until you run it and check.

We treat generative AI as our default author, and the compiler functions as the most accurate and least expensive feedback path available to an agent. The more we write code whose behavior can be foreseen from its signature, the wider the path along which the AI can self-correct. For that reason, our policy prioritizes predictability of behavior and ease of composition over readability for humans.

## Goal (目標)

The situation this policy aims to achieve is a state where runtime errors are close to zero. We push the detection of inconsistencies back to compile time as far as possible, aiming for a state in which the kinds of errors you cannot notice until you run the code are not left in the domain. As with the direction Elm sets out under "No Runtime Exception," we do not guarantee that this is attained, but we hold it up as our ideal to approach.

## Responsibility (責務)

The situation this policy aims to prevent is a state where code that has been verified by neither static checking nor unit tests accumulates as the standard in the domain layer. We want to keep things in a form where inconsistencies that can be pushed back to compile time by writing declaratively, and behavior that can only be caught by unit tests, are divided up and covered by these two means of verification. If we make unit tests stand in for the range that static checking could push back, the execution time of CI/CD keeps ballooning; therefore we want to keep the range that can be pushed back on the static-checking side.

## Practices (実践)

### Make pure functions the default form

When writing a new function, we begin by writing it as a pure function. At the point where a side effect becomes necessary, we decompose it into a thin shell that performs the side effect and the pure computation that sits inside it.

- Gather side effects near the entry points (HTTP handlers, queue workers, CLI commands).
- Place pure computation on the side called by the side-effect layer. Concentrate the unit of testing on the pure-computation side.
- Express the very decision of whether to call a side-effecting function as the return value of pure computation (the command pattern, effect descriptors, the Task type, and so on).

### Make immutable data the default form

We treat data as immutable and express change as "the generation of a new value." How far immutability can be carried to the type level differs by language.

- In TypeScript and Rust, we carry immutability to the type level with `Readonly`, `ReadonlyArray`, immutable references (`&T`), and the like.
- In Go, because `const` does not apply to data structures, immutability is maintained not through types but through how the code is written. We make it the default to return a new value from the return value and to avoid mutating the arguments.

We limit the situations in which we use mutable local variables to loops, accumulators, and performance optimization, and we do not abuse them as an escape hatch.

### Prefer explicit data flow

We express the flow of data through signatures and composition. We avoid structures that carry data around by way of hidden state.

- Use composition primitives such as `map` / `filter` / `reduce` / `pipe` so that "what is happening to the data" can be read linearly.
- When you need to hold intermediate state, put it not in a local variable but on an explicit type (`Result` / `Option` / `Either`, etc.) and return it.

### Express failure through the return type

Our policy is to express the occurrence and propagation of failure through the return type, and not to use exceptions as control flow. Because the whereabouts of failure appear in the signature, the caller is asked to handle it at compile time.

- In TypeScript and Rust, we use `Result<T, E>`, `Option<T>`, and sum types built from discriminated unions, and we have the compiler check exhaustiveness.
- In Go, we ride on the convention of two-valued functions that return an `error`, and we make the branching of errors explicit with `errors.Is` and custom `error` types. Because Go has no sum types, we cannot leave exhaustiveness entirely to the compiler, but the principle of expressing failure through the return value is the same.

For details, see [Thick Typing](/implementation/type-driven-design) (厚い型付け).

### Where imperative code can be written more directly, it may be used

To *prefer* declarative code is not to *forbid* imperative code. There are situations where imperative code is more readable — state-machine transitions, parsers, low-level performance optimization, and so on.

- Leave one or two lines in the PR description explaining the reason for choosing imperative code.
- Even in areas written imperatively, shape the outward-facing interface as pure functions.

### I/O is the shell, computation is the core

We think of the structure of an application in two layers: "the shell (I/O) and the core (pure computation)." The shell is the layer that touches the external world — HTTP handlers, DB access, file I/O, console output, and so on. The core is the computation layer that transforms the values handed to it by the shell and returns a value back to the shell.

- Keep the shell thin and keep the core thick.
- The functions of the core do not touch I/O or the clock directly; they operate only on the values received as arguments.

### Parameterize dependencies

Instead of directly calling side-effecting dependencies (the clock, randomness, I/O clients), we receive them as arguments. This makes them substitutable in tests, and it makes the path of reasoning readable from the signature.

```ts
// before
function expiresAt() {
  return Date.now() + 3600_000;
}
// after
function expiresAt(now: number) {
  return now + 3600_000;
}
```

```go
// before
func expiresAt() time.Time {
  return time.Now().Add(time.Hour)
}
// after
func expiresAt(now time.Time) time.Time {
  return now.Add(time.Hour)
}
```

### Use function composition to make "the intent of sequential processing" readable

For processing that has an order, writing it as composition rather than lining up temporary variables makes the intent more readable.

```ts
const summary = items
  .filter(isVisible)
  .map(toSummary)
  .reduce(merge, emptySummary);
```

When a composition becomes too long, we extract the intermediate steps as named functions so that each stage of the composition can be read as a meaningful unit.

### The reach of declarative code per language

The range that can be expressed in declarative code depends on the vocabulary of the type system the language provides.

- TypeScript and Rust can express many failure patterns and state transitions at compile time by using sum types, exhaustiveness checking, the `Result` type, and generics. Because the thickness that can be stacked declaratively is large, the range that can be covered by static checking widens as well.
- Go has no sum types, and its generics vocabulary is limited, so the reach of declarative code is constrained. Our policy is to use the declarative style within the range Go can express: (a) returning a new value from the return value, (b) making error branching explicit with `errors.Is` and custom `error` types, and (c) injecting dependencies by passing functions as arguments.

When trying to write declaratively, type-level descriptions (conditional types, advanced generics, deep nesting of branded types, and the like) can take a form that is time-consuming to read. The unreadability that surfaces most readily is mainly this "thickness of type-level declaration." Because we treat AI coding agents as our default author, there we make the choice to prioritize the breadth of compile-time detection.
