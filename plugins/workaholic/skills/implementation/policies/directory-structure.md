---
title: Directory Structure Conventions
slug: directory-structure
category: implementation
source: https://qmu.co.jp/implementation/directory-structure
---

# Directory Structure Conventions

_Follow the directory structure conventions of the language and framework, keeping the layout flat enough to navigate, and document deviations from convention explicitly._

A directory structure that follows established conventions reduces the time needed to orient in an unfamiliar part of the codebase, for both human developers and AI agents. Conventions exist at two levels: language-level (where Go packages live relative to the module root, where TypeScript source lives relative to the project root) and project-level (where migrations live, where tests live relative to the source they test, where ADRs live). Both levels are worth documenting. A project that deviates from conventions without documentation creates orientation cost each time someone navigates to a directory for the first time.

## Goal (目標)

The situation this policy aims to achieve is one in which a developer who knows the language can navigate the repository without a guided tour, because the layout follows the conventions of the language and the deviations from convention are documented.

- The root of the repository contains a map of the directory structure in the README or a dedicated `STRUCTURE.md`.
- The source layout follows the language's canonical conventions (Go: `cmd/`, `internal/`, `pkg/`; TypeScript: `src/` with colocated tests; Cloudflare Workers: `src/` with `wrangler.toml`).
- Deviations from the canonical layout are documented with a reason.

## Responsibility (責務)

The situation this policy aims to prevent is one in which the directory layout is arbitrary and must be learned by exploration or asking a colleague.

States we do not tolerate:

- A monorepo or multi-package project whose workspace root has no documentation of what is in each directory.
- Source code mixed with generated files, build artifacts, and configuration in the same directory without clear separation.
- Tests scattered at arbitrary depths without a documented relationship to the source files they test.
- A `utils/`, `helpers/`, or `misc/` directory that has become a catch-all for things whose home is unclear.

## Practices (実践)

### Follow the canonical layout for the language

For TypeScript/Node projects: `src/` for source, tests colocated with source (`.test.ts` files next to the source file), `dist/` for build output (gitignored). For Go projects: `cmd/` for entry points, `internal/` for non-exported packages, top-level `pkg/` only if the packages are intended to be imported externally. For Cloudflare Workers projects: `src/` for source, `wrangler.toml` at the root.

### Document the directory structure in the README

The repository README includes a section that maps the top-level directories to their purpose. The level of detail should be "enough to find a file you do not know the path of." For a monorepo, document both the workspace root and the significant top-level packages.

### Keep the tree flat enough to navigate in two levels

Prefer a two-level structure (module/feature) to a deeply nested hierarchy. Deep nesting (five or more levels to reach a source file) increases the cognitive load of navigation and tends to indicate over-modularization. If a module has grown large enough to warrant internal structure, document that structure in a README within the module directory.

### Related: Coding Standards and Conventions, Domain Layer Separation, Command Scripts for Development Tasks

Directory layout is the physical expression of module boundaries — see [Domain Layer Separation](domain-layer-separation.md). File naming and path conventions are part of [Coding Standards and Conventions](coding-standards.md). The commands that operate on the directory structure are in [Command Scripts for Development Tasks](command-scripts.md).
