---
title: Using Anti-Corruption Structures
slug: anti-corruption-structure
category: implementation
source: https://qmu.co.jp/implementation/anti-corruption-structure
---

# Using Anti-Corruption Structures

_Keeping an anti-corruption structure inside packages: dividing internals by domain into model, service, and dependency-implementation responsibilities, directing dependencies toward the domain, and structurally preventing external dependencies, I/O, and entry-point wiring from entering and corrupting the domain._

Packages hold a structure that protects domains from external concerns. The more a domain's data types and procedures mix with external libraries, I/O, and entry-point wiring, the farther they move from their own vocabulary and the harder it becomes to read what they represent. We divide package internals into domain units, then divide each unit into three responsibilities: model (data types and functions on them), service (procedures exposed outward), and dependency implementation (implementations that enclose external dependencies). By directing dependencies toward the domain, we define in one place, independent of language, a structure that keeps external concerns from corrupting the domain. [Standard Directory Structure](directory-structure.md) aligns the repository from the top level through `packages/<package>/`; this policy covers the next level inward, the package contents. How the three responsibilities land in each language's filenames and package boundaries is handled by [Coding Standards (TypeScript)](coding-standards.md) and [Coding Standards (Golang)](golang-coding-standards.md).

AI writes much of the implementation, and the more consistent the internal arrangement is, the more both the next person and the next AI can reach the declarations and procedures they need from structure rather than search. We aim to align the structure that prevents corruption across languages, so the internal layout does not waver by implementer or generation.

## Goal (目標)

We aim for a state where the domain is separated from external concerns and expressed only in its own vocabulary. Package internals are consistently divided into the three responsibilities of model, service, and dependency implementation; external dependencies are enclosed inside the dependency-implementation layer; and dependency direction points toward the domain. Entry points sit outside as thin shells that call public domain procedures, and the surface the package exposes outward is narrowed. The units remain aligned with boundaries that can be rebuilt whole, and the internal arrangement can be read by the same principle across languages. We set as our direction a state where the map learned in one project carries directly into another.

## Responsibility (責務)

We prevent a state where external library types, I/O, and entry-point wiring enter domain sections and corrupt the domain. We also avoid a state where dependency direction flows backward and models or services are pulled by the convenience of external dependencies.

In development where AI writes much of the implementation, placement tends to be decided from only the local context. I/O and wiring can slip into domain sections, and the outward-facing surface can widen by erosion. Each deviation may be small, but stacked across many files, it erases the boundary of the sections that were supposed to be rebuildable by domain, and the structure intended to prevent corruption itself collapses.

## Practices (実践)

### Divide by domain, then by model, service, and dependency implementation

Inside a package, first divide sections by domain, such as Order, Inventory, or Billing, then divide each section by the three responsibilities. Create one domain section per aggregate root and name it with a pronounceable word, following the naming policy in [Standard Directory Structure](directory-structure.md). Aim for declarations and procedures concerning one domain's data to be concentrated in the same section, and move processing that crosses multiple domains toward inter-domain procedures. The three responsibilities placed inside each section are as follows.

```
Domain section (one per aggregate root)
  Model layer                 Data types and functions on those types
  Service layer               Procedures exposed outward
  Dependency implementation   Boundary that encloses external dependencies and prevents corruption
```

- Model layer: Holds data type declarations and functions on those types. It is a pure layer depending only on language primitives and the foundation library adopted by the project. Shape functions to handle a single model where possible, and move processing across multiple models toward the service layer. The aim is for declarations and operations concerning one data type to be concentrated in one place.
- Service layer: Exposes the procedures called from outside. It corresponds to a use-case layer, achieving its purpose by handling models and calling the dependency-implementation layer. Types appearing in signatures are limited to primitives, foundation-library types, and model types; library types used internally by the dependency-implementation layer are not propagated into this layer.
- Dependency-implementation layer: The boundary that encloses implementations containing external dependencies and prevents corruption. It receives primitive, foundation-library, and model types; calls concrete libraries internally; and converts results back into the same vocabulary of types. By not taking external-library types outside the boundary, dependency direction aligns from the model and service layers toward the domain, and external changes do not leak into the domain.

These three responsibilities are the same across languages. Each language's standards are the place where they are mapped into that language's idiomatic filenames, package boundaries, and module boundaries. TypeScript specifics are defined by [Coding Standards (TypeScript)](coding-standards.md) as `model`, `service`, and `dependency` under `src/<Domain>/`; Go specifics are defined by [Coding Standards (Golang)](golang-coding-standards.md) as package and file boundaries. In Rust, the same three responsibilities would move into `mod` and crate boundaries. Directory names themselves may follow each language's idiom; what we align is not the names but the three responsibilities and dependency direction.

### Separate entry points as thin shells

Entry points such as HTTP routers, CLIs, and queue workers are not placed in the package that expresses the domain. They sit outside as thin shells that call public domain procedures and format results. Startup and wiring are enclosed in this shell, and decision logic remains in the domain section. The evidence that the separation works is that the same domain procedure can be launched from another entry point in the same way. [Domain Layer Separation](domain-layer-separation.md) covers the reasoning behind this split.

### Narrow the surface exposed outward

Expose only domain types and public procedures outside the package; do not expose the section that encloses external dependencies. Express the main processing completely within the decided sections, and do not break the structure by adding sections or broadening the interpretation of a section to bring in another concern.

### Draw boundaries around units that can be rebuilt

When uncertain where to draw a section boundary, draw it along the unit that can be rebuilt whole rather than along the convenience of adding a feature. This arrangement, where external dependency implementations coexist in the domain section, differs from partitioning that moves implementation details away from the domain. Recognizing that such partitioning works in some contexts, at our scale and team structure we prioritize rebuildability at the domain unit over purity of partitioning. We consider enclosing external dependencies at the boundary and managing them inside repository `packages/` to support the replaceability described in [Proactive Consideration of Sacrificial Architecture](../../design/policies/sacrificial-architecture.md).

### Related

The repository-wide arrangement across packages is handled by [Standard Directory Structure](directory-structure.md). The language-specific form of the anti-corruption structure defined here is handled by [Coding Standards (TypeScript)](coding-standards.md) and [Coding Standards (Golang)](golang-coding-standards.md). The reason for separating entry points and external dependencies from the domain is covered by [Domain Layer Separation](domain-layer-separation.md), and the reason for moving sections toward rebuildable units is covered by [Proactive Consideration of Sacrificial Architecture](../../design/policies/sacrificial-architecture.md). This policy is responsible for gathering those principles as a language-independent structure that keeps external concerns from corrupting the domain.
