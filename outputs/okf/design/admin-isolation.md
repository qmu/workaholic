---
type: Engineering Policy
title: "Isolation of Administrative Functions"
description: "Keeping administrative functions on a separate surface with a separate authentication path so that a compromised user credential does not expose administrative operations."
resource: https://qmu.co.jp/design/admin-isolation
tags:
  - design
  - admin-isolation
---

# Isolation of Administrative Functions

_Keep administrative functions on a separate surface from the user-facing product, with a separate authentication path, so that a compromised user credential does not expose administrative operations._

Administrative interfaces — those that allow operators to manage users, configure the product, view aggregate data, or perform privileged operations — carry a higher risk profile than user-facing interfaces. Placing them on the same surface and under the same authentication path as user access enlarges the attack surface and means that a compromised user session can be escalated to administrative capability. We separate administrative functions structurally: a different URL namespace, a separate authentication event, and ideally a separate deployment.

## Goal (目標)

The situation this policy aims to achieve is one in which the administrative surface of the product is not reachable through the same path as the user-facing surface.

- The admin interface is reachable only through a path or domain that is not discoverable by ordinary user browsing.
- An administrative session requires a separate authentication event, not merely a role check on the user's session.
- Administrative operations are logged with the operator's identity and timestamp.

## Responsibility (責務)

The situation this policy aims to prevent is one in which a vulnerability in the user-facing surface, or a compromised user credential with administrative role, exposes administrative operations.

States we do not tolerate:

- Administrative functions behind only a role check on a regular user session. A role on a JWT is not a separate authentication; it is authorization that can be bypassed if the session token is stolen.
- Admin routes at predictable paths under the same domain as user-facing routes (`/admin/*`), without additional network-level restriction.
- Administrative operations that are not logged, or logs that are accessible to users who could modify or delete them.

## Practices (実践)

### Place admin on a separate domain or subdomain with restricted access

Use a separate domain or subdomain for the admin interface (`admin.example.com` or `app-admin.internal`). If possible, restrict it to a VPN or IP allowlist at the network level. A path-based split (`/admin/*`) is acceptable but provides weaker isolation than a separate domain.

### Require a separate authentication event for administrative sessions

Administrative access requires a separate login — MFA at minimum, or a separate credential. A user who is already logged into the user-facing product cannot "elevate" to admin without a new authentication event. This limits the blast radius of a stolen user session.

### Log all administrative operations

Every create, update, and delete operation performed through the admin interface is logged with the operator's identity, timestamp, and the before/after state of the changed record. Administrative logs are stored in a location that is not modifiable by admin users, and are retained for at least one year.

### Related: Defense in Depth, Authentication and Authorization Procurement, Observability and Self-Healing

Admin isolation is one layer in the defense-in-depth posture described in [Security Considered in Layers](/design/defense-in-depth.md). The authentication event for the admin surface follows the procurement considerations in [Authentication and Authorization Procurement Policy](/design/auth-procurement.md). Admin operation logs are part of the structured logging posture in [Observability and Self-Healing](/implementation/observability.md).
