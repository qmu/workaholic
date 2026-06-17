---
title: Authentication and Authorization Procurement Policy
slug: auth-procurement
category: design
source: https://qmu.co.jp/design/auth-procurement
---

# Authentication and Authorization Procurement Policy

_Evaluate existing authentication and authorization solutions before building, because the operational surface of a custom implementation is wide and the failure modes are severe._

Authentication and authorization are security-critical subsystems where implementation errors have outsized consequences — credential theft, account takeover, session hijacking, and privilege escalation. The field has mature, well-audited solutions. Our default is to evaluate existing solutions first, and to build a custom implementation only when a concrete requirement cannot be met otherwise. The cost of evaluation and adoption is reliably lower than the cost of maintaining a secure custom implementation over time.

## Goal (目標)

The situation this policy aims to achieve is one in which authentication and authorization are handled by solutions with known security properties, without requiring our team to maintain the security of their implementation.

- The chosen solution's security model and audit history are understood before adoption.
- The solution handles the credential lifecycle (registration, login, password reset, session expiry, MFA) as a managed concern.
- Authorization rules are expressed in an auditable, reviewable form rather than scattered across application code.

## Responsibility (責務)

The situation this policy aims to prevent is one in which a custom authentication or authorization implementation introduces vulnerabilities that a procured solution would not have.

States we do not tolerate:

- Rolling a custom password hashing scheme, session token implementation, or credential storage mechanism without a security review.
- Choosing to build rather than procure solely on the grounds of "we want full control" or "external services have vendor risk," without evaluating the actual trade-off.
- Procuring an auth solution without understanding what the solution handles and what it does not — particularly for edge cases like concurrent sessions, token revocation, and MFA recovery.

## Practices (実践)

### Evaluate procured solutions before scoping custom implementation

Before designing a custom auth subsystem, evaluate existing solutions against the requirements: Clerk, Auth0, Supabase Auth, Amazon Cognito, WorkOS, and similar. Assess them on security track record, compliance certifications, the operations they handle, and their terms of exit. If none meets the requirements, document why before proceeding with a custom build.

### Separate authentication from authorization

Authentication (who the user is) and authorization (what they may do) are distinct concerns and should be handled separately. Mixing them makes it harder to change either independently. The auth solution typically handles authentication; authorization rules belong in the application layer, expressed as explicit policies rather than ad-hoc conditionals.

### Make authorization rules auditable

Authorization rules — which roles may perform which operations, which conditions gate access to which data — are expressed in a single, reviewable location rather than distributed across handlers, middlewares, and service calls. This makes it possible to audit "can user role X reach resource Y" without tracing through multiple layers of code.

### Document what the solution does not cover

Every auth solution has a boundary. Document what the chosen solution handles and what the application must handle itself — token refresh strategies, per-tenant custom claims, fine-grained row-level permissions, and so on. The documentation of this boundary is the authorization design.

### Related: Access Control Mechanism Selection, Defense in Depth

The choice of auth mechanism interacts with how access control is structured — see [Access Control Mechanism Selection](access-control.md). Auth is one layer in a defense-in-depth posture — see [Security Considered in Layers](defense-in-depth.md).
