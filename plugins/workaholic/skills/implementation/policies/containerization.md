---
title: Containerization
slug: containerization
category: implementation
source: https://qmu.co.jp/implementation/containerization
---

# Containerization

_Use containers to make the local development environment match production, and to make the deployment unit reproducible; accept the added abstraction layer as the price of reproducibility._

A container bundles a runtime, its dependencies, and its configuration into a single, reproducible unit. The primary value in development is eliminating "works on my machine" — if the container runs locally, it runs in CI, and if it runs in CI, it runs in production. The secondary value is making the deployment unit explicit and versioned, separate from the host it runs on. Both values depend on the container being maintained, not just created: a Dockerfile that drifts from production behavior provides false confidence.

## Goal (目標)

The situation this policy aims to achieve is one in which the local development environment, CI environment, and production environment run the same application code in containers that were built from the same Dockerfile.

- The Dockerfile builds successfully from a clean checkout of the repository.
- The local development environment uses Docker Compose to start all dependencies (database, cache, queue) without manual setup.
- Production images are built from a multi-stage Dockerfile that keeps the production image free of build tooling.

## Responsibility (責務)

The situation this policy aims to prevent is one in which the container configuration has drifted from production behavior, or in which the container is only used in CI and the developer's local environment differs from both.

States we do not tolerate:

- A Dockerfile that uses `latest` tags for base images, causing non-reproducible builds.
- A production image that includes build dependencies (compilers, test frameworks) because a multi-stage build was not used.
- Containers running as root in production without a specific, documented reason.
- Docker Compose for local development that requires manual steps not documented in the README or encapsulated in a script.

## Practices (実践)

### Use multi-stage builds to keep production images lean

Structure the Dockerfile with distinct stages: a build stage that compiles and assembles the application, and a runtime stage that copies only the built artifacts. The runtime stage starts from a minimal base image (distroless, alpine, or equivalent) and contains only what is needed to run the application.

### Pin base image versions

Base images are pinned to specific versions (`node:22.4.0-alpine3.20`, not `node:lts` or `node:latest`). Pin to a digest (`sha256:...`) for production builds in environments where reproducibility is critical.

### Run as a non-root user in production

The runtime stage creates and uses a non-root user. This reduces the blast radius of an application-level vulnerability that achieves code execution. Most base images provide a convention for this (`node` user in Node images, `nonroot` in distroless images).

### Use Docker Compose for local development dependencies

Use `docker-compose.yml` to define the full set of local dependencies: database, cache, queue, and the application itself. A developer can run `docker compose up` to start everything. The Compose file is kept in the repository and is the authoritative description of the local stack.

### Related: Infrastructure as Code, Command Scripts for Development Tasks, CI/CD Automation

Containers are managed as infrastructure — see [Infrastructure as Code](infrastructure-as-code.md). The commands for building and running containers are encapsulated in scripts — [Command Scripts for Development Tasks](command-scripts.md). Container images are built in CI — [CI/CD Automation](../../operation/policies/ci-cd.md).
