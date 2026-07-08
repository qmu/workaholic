---
title: Anti-Corruption Structure
slug: anti-corruption-structure
category: implementation
source: https://qmu.co.jp/implementation/anti-corruption-structure
---

# Anti-Corruption Structure

_Dividing each package's interior by domain and into three responsibilities — model, service, and dependency implementation — so that external libraries, I/O, and entry point wiring cannot corrupt the domain's own vocabulary._

The inside of a package holds a structure that protects the domain from external concerns. As domain data types and procedures become mixed with external library types, I/O, and entry point wiring, they move away from their original vocabulary and become harder to read. Dividing the inside by domain, then subdividing each section into three responsibilities — model (data types and their functions), service (procedures exposed to the outside), and dependency implementation (implementations that contain external dependencies) — and directing dependencies toward the domain establishes, language-agnostically in one place, a structure that prevents external concerns from corrupting the domain. While [Standard Directory Structure](directory-structure.md) aligns the repository top-level down to `packages/<package>/`, this policy handles one level deeper — the package contents — and how to map the three responsibilities to language-specific file names and package boundaries is handled by [Coding Standards (TypeScript)](coding-standards.md) and [Coding Standards (Golang)](golang-coding-standards.md).

Most implementation is written by AI, and the more consistently the internal arrangement is kept, the more the next person or AI can find the desired declaration or procedure from structure rather than exploration. Aligning the anti-corruption structure across languages is intended to prevent the internal layout from shifting with each contributor or generation.

## Goal (目標)

The situation this policy aims to achieve is one where the domain is separated from external concerns and expressed only in its own vocabulary. The package's inside is consistently divided into the three responsibilities of model, service, and dependency implementation; external dependencies are contained within the dependency implementation layer; and dependency directions are aligned toward the domain. Entry points sit outside as thin shells that call the domain's public procedures, and the surface the package exposes to the outside is narrow. Sections are maintained along units that can be rebuilt as a whole, and the internal arrangement reads under the same principles across languages — so that the map learned in one project carries directly to another project. This is the destination we aim for.

## Responsibility (責務)

The situation this policy aims to prevent is one where external library types, I/O, and entry point wiring invade the domain's sections and corrupt the domain. It also aims to prevent a state where dependency directions flow in reverse and models or services are pulled by the concerns of external dependencies.

In development where AI writes most of the implementation, placement is often decided by immediate context, causing I/O and wiring to mix into domain sections and the exposed surface to expand by degrees. Individual deviations are small, but when they accumulate across many files, the outline of sections that should have been rebuildable domain-by-domain is lost, and the very structure that was supposed to prevent corruption collapses.

## Practices (実践)

### Divide by domain and separate the inside into model, service, and dependency implementation

The inside of a package is first divided into sections per domain (order, inventory, billing, and so on), and each section is divided into three responsibilities. One section is set up per aggregate root, named with a pronounceable word (following the naming convention in [Standard Directory Structure](directory-structure.md)). The aim is for declarations and procedures related to one domain to be concentrated in the same section; processing that spans multiple domains is pushed to the inter-domain procedures side. The three responsibilities within each section are as follows:

```
Domain section (one per aggregate root)
  Model layer                         Data types and functions on those types
  Service layer                       A series of procedures exposed to the outside
  Dependency implementation layer     A boundary containing external dependencies, preventing corruption
```

- **Model layer** — Data type declarations and functions on those types. A pure layer that depends only on language primitives and the project's base library. Functions are shaped to operate on a single model where possible; processing that spans multiple models is pushed to the service layer. The aim is for declarations and operations related to one data type to be concentrated in the same place.
- **Service layer** — The layer that exposes a series of procedures called from outside. The use-case equivalent that achieves its purpose by working with models while calling the dependency implementation layer. Types appearing in signatures are limited to primitives, base library, and model types; library types used internally by the dependency implementation layer are not propagated into this layer.
- **Dependency implementation layer** — The boundary that contains implementations including external dependencies, preventing corruption. It receives primitives, base library, and model types; calls specific libraries internally; and returns results converted back to the same vocabulary of types. By not taking external library types outside the boundary, dependency directions from the model layer and service layer are aligned toward the domain, and external changes do not seep into the domain.

These three responsibilities are the same across languages. Each language's coding standards handle how to map them to that language's idiomatic file names, package boundaries, and module boundaries. The TypeScript specifics are established by [Coding Standards (TypeScript)](coding-standards.md) as `model`, `service`, and `dependency` under `src/<Domain>/`; the Go specifics are established by [Coding Standards (Golang)](golang-coding-standards.md) as package and file boundaries. In Rust, the same three responsibilities would be mapped to `mod` and crate boundaries. Directory names themselves may follow language idioms; what is aligned is not the names but the three responsibilities and dependency directions.

### Separate entry points as thin shells

HTTP routers, CLIs, queue workers, and other entry points are not placed in the package expressing the domain. Instead they are placed outside as thin shells that only call the domain's public procedures and format results. Startup and wiring are contained in this shell; decision logic remains in the domain's sections. Being able to start the same domain procedure from a different entry point in the same way is evidence that the separation has held. The rationale for this separation is handled by [Domain Layer Separation](domain-layer-separation.md).

### Narrow the surface exposed to the outside

What is exposed outside the package is limited to domain types and public procedures; the section containing external dependencies is not published. Main processing is fully expressed within the defined sections; the structure is not broken by adding new sections or broadening a section's interpretation to bring in other concerns.

### Divide along lines that allow rebuilding

When uncertain about how to divide sections, draw boundaries along units that can be rebuilt as a whole, not for the convenience of adding features. This arrangement — dependency implementations coexisting inside domain sections — differs from the widely-known approach of placing implementation details away from the domain. Acknowledging that that separation works well in its context, at our scale and team structure we prioritize being able to rebuild at the domain unit level over purity of separation. Containing dependencies within boundaries and managing them within `packages/` in the same repository supports the replaceability envisioned in [Sacrificial Architecture](../../design/policies/sacrificial-architecture.md).

### Related

The repository-wide arrangement across packages is handled by [Standard Directory Structure](directory-structure.md). The language-specific application of the anti-corruption structure defined in this policy is handled by [Coding Standards (TypeScript)](coding-standards.md) and [Coding Standards (Golang)](golang-coding-standards.md) respectively. The rationale for separating entry points and external dependencies from the domain is handled by [Domain Layer Separation](domain-layer-separation.md), and the rationale for aligning sections to rebuildable units is handled by [Sacrificial Architecture](../../design/policies/sacrificial-architecture.md). This policy gathers these principles together, language-agnostically, as a structure that prevents external concerns from corrupting the domain.
