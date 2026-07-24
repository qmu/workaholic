---
created_at: 2026-07-24T09:43:04+09:00
author: a@qmu.jp
type: enhancement
layer: [Docs]
effort: 2h
commit_hash:
depends_on:
mission:
---

# Clarify the operation policy on running long-running / "major" servers: container (or isolation boundary) required, with an explicit developer-preview carve-out

## Overview

A consuming repository exposes a `make docs` target that starts a long-running
documentation preview server (a VitePress dev server) **directly as a bare host
process, with no container boundary**. Acting on a "run the docs server" request,
that server was started directly on the host. This surfaced a policy question that
the operation guidance does not currently answer in writing, and that each
consuming repository is otherwise left to guess:

> Is running a long-running / "major" server directly on the host — outside any
> container or equivalent isolation boundary — a violation of our operation /
> runtime policy? If so, what exactly is in scope, and what is the carve-out for a
> local developer preview?

Because the engineering policies are authored here and distributed as a plugin to
the consuming repositories, the ruling (and any mechanical guard) belongs in this
repository rather than being decided ad hoc in each consumer.

## Policy question

1. **Rule.** Does the operation policy require long-running or traffic-serving
   servers to run inside a container (or an equivalent isolation boundary) rather
   than as a bare host process?
2. **Scope.** If yes, which classes are covered? Is a **loopback-only, ephemeral
   developer preview** (e.g. a docs dev server bound to `127.0.0.1`, started by
   hand, torn down after use) an explicit exception, or must even preview servers
   be containerized?
3. **The line.** Where is the boundary between an allowed "dev preview" and a
   "major server" that must be contained? Candidate criteria: bound interface
   (loopback vs. a non-loopback / publicly reachable address), longevity
   (ephemeral vs. persistent), and whether it serves real/external traffic.

## Suggested resolution

- **State the rule in the operation policy in writing**, naming which server
  classes must run in a container and writing the developer-preview carve-out
  (loopback-only, ephemeral) down once, so it is not re-litigated per repository.
- **Optionally add a policy guard** (in the same style as the other guards this
  plugin distributes) that flags a build target or script which starts a
  long-running server bound to a **non-loopback** interface without a container,
  so violations are caught mechanically rather than only in review.

## Considerations

- Consuming repositories currently ship direct `make <server>` targets. A written
  ruling lets each one either add the carve-out note or wrap the server, instead of
  guessing whether the direct form is permitted.
- The higher-risk case is a server made **publicly reachable** (e.g. fronted by a
  tunnel to a public hostname); a purely loopback preview is materially lower risk.
  The policy text should distinguish the two so the guard does not block harmless
  local previews.
- This is a policy-clarification request, not an implementation ask for the
  consuming repo; the consuming repo will follow whatever ruling lands here.
