---
type: Engineering Policy
title: "Standard Directory Structure"
description: "Dividing the repository top-level by role and following the same layout across projects, so that people and AI agents can find files from structure rather than exploration."
resource: https://qmu.co.jp/implementation/directory-structure
tags:
  - implementation
  - directory-structure
---

# Standard Directory Structure

_Dividing the repository top-level by role and following the same layout across projects, so that people and AI agents can find files from structure rather than exploration._

Repositories follow a standard layout where the same kind of file lands in the same place, rather than working it out fresh for each project. The top level is divided by role — `packages/` for code, `scripts/` for common scripts, `workloads/` for execution environment configuration, `databases/` for schemas, `docs/` for documentation, `outputs/` for runtime output — and code is further divided one directory per package, with each package's internal layout following the language coding standards. When placement is readable from structure, both a person opening the repository for the first time and an AI agent working on their behalf can locate a file by navigating structure rather than searching.

## Goal (目標)

The situation this policy aims to achieve is one where the repository layout is consistent across projects and both people and AI agents can predict where things are from the structure itself. Code, scripts, execution environment configuration, schemas, and documentation land in places whose role is readable from the name and hierarchy. The sense of where things belong that someone builds on one project carries to the next. Directory and file names are pronounceable words, so the same name points to the same place in conversation and in instructions to an AI — without decoding abbreviations. The repository explains its own structure through its structure.

## Responsibility (責務)

The situation this policy aims to prevent is one where placement varies from project to project, the same kind of file ends up in a different place each time, and both people and AI must search for where to put things and where to look each time.

With generative AI as the default author, a recurring failure mode is AI placing files based only on local context, so the same kind of file accumulates in different places across projects and directories. When structure is scattered, the next AI cannot use existing placement as a guide and adds to a different location, compounding the scatter.

## Practices (実践)

### Divide the repository top-level by role

The repository is first divided at the top level by role. Code goes under `packages/` as one directory per package, with internal layout — domain layer, entry points, vendor boundaries — delegated to the language coding standards. Repository-wide common scripts are in `scripts/` per [Command Scripts for Development Tasks](/implementation/command-scripts.md). Execution environment and infrastructure configuration is in `workloads/`. Schemas and migrations are in `databases/`, in keeping with [Schema-First Database Design](/implementation/persistence.md). Documentation is in `docs/`, runtime output in `outputs/`. For example:

```
repository/
  packages/          Code. One directory per package. Internal layout follows the language coding standards.
    <package>/
      src/             Domain layer · entry points · vendor boundary (layout defined by the standards)
      scripts/         Scripts for this package
      docs/            Documentation for this package
  scripts/           Repository-wide common scripts ([verb]-****.sh)
  workloads/         Execution environment · infrastructure configuration
    docker/            Container configuration (Compose · image definitions)
    <iac>/             IaC, organized by environment
  databases/         Schemas · migrations (one subdirectory per database)
  docs/              Documentation
    progress-reports/  Progress reports
      01_dev1/
      02_dev2/
      ...
    research-reports/  Research reports
    ...
  outputs/           Runtime output (normally .gitignore'd)
```

How to arrange the inside of `<package>/src/` is defined per language by [Coding Standards (TypeScript)](/implementation/coding-standards.md) and [Golang Coding Standards](/implementation/golang-coding-standards.md). This policy covers the repository-wide layout up to that point — keeping the same role in the same named place across projects.

### Use pronounceable names

Directory and file names are chosen from words that can be spoken aloud. Names like `packages`, `scripts`, `workloads`, `databases` can be used as-is in conversation and in instructions to an AI, pointing to the same place without decoding. Abbreviations that require decoding, vowel-dropped shortenings, and context-dependent acronyms are avoided. The words used follow the domain vocabulary principle from [Codifying Domain Terminology](/planning/terminology.md) — one role, one name, with no second names accruing to the same role. Numeric prefixes (`01_`, `02_`) are used as ordinals added to a pronounceable word, not as replacements for the word itself.

### Related: Coding Standards, Command Scripts for Development Tasks, Schema-First Database Design, Codifying Domain Terminology

How to arrange the inside of packages is defined per language by [Coding Standards (TypeScript)](/implementation/coding-standards.md) and [Golang Coding Standards](/implementation/golang-coding-standards.md). What goes inside the `scripts/` slot is in [Command Scripts for Development Tasks](/implementation/command-scripts.md). How schemas in `databases/` are handled is in [Schema-First Database Design](/implementation/persistence.md). The naming approach follows the pronounceability and domain vocabulary principles in [Codifying Domain Terminology](/planning/terminology.md). This policy supports those by establishing the repository-level layout where their contents land.
